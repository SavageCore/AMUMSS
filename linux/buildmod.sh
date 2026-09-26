#!/usr/bin/env bash
# buildmod.sh - Linux entry point for AMUMSS (replaces BUILDMOD.bat).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/scripts/common.sh"

usage() {
  cat <<EOF
Usage: buildmod.sh [--setup|--check|--run-pipeline] [AMUMSS_HOME]
       [--copy-to-game=none|some|all] [--combine] [--dev-mode=F|L]

  --setup          create native shims, detect NMS, prepare workspace dirs
  --check          verify environment only (default)
  --run-pipeline   run the full lua mod-build pipeline natively

Pipeline options (env override in parens):
  --copy-to-game=none|some|all   copy built mods to GAMEDATA/MODS
                                 (COPY_TO_GAME, default: none)
  --combine                      allow ___COMBINE.txt composite combined mods
                                 (default: individual mods)
  --dev-mode=F|L                 FULL or LEAN verbosity (DEV_MODE, default: F)

AMUMSS_HOME defaults to: \$AMUMSS_HOME, cwd if it contains MODBUILDER/, else ~/AMUMSS
EOF
}

MODE="--check"
COPY_TO_GAME="${COPY_TO_GAME:-none}"
REFRESH_PAK_LIST="${REFRESH_PAK_LIST:-0}"
ALLOW_COMBINE="${ALLOW_COMBINE:-0}"
DEV_MODE="${DEV_MODE:-F}"
for arg in "$@"; do
  case "$arg" in
    --setup | --check | --run-pipeline) MODE="$arg" ;;
    --copy-to-game=*) COPY_TO_GAME="${arg#*=}" ;;
    --refresh-pak-list) REFRESH_PAK_LIST="1" ;;
    --combine) ALLOW_COMBINE="1" ;;
    --dev-mode=*) DEV_MODE="${arg#*=}" ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) AMUMSS_HOME="$arg" ;;
  esac
done

resolve_amumss_home "${AMUMSS_HOME:-}"
need_modbuilder

check_dep() {
  local name="$1" hint="$2"
  if command -v "$name" >/dev/null 2>&1; then
    echo "  ok: $name ($(command -v "$name"))"
  else
    echo "  MISSING: $name -- $hint"
    return 1
  fi
}

do_check() {
  local fail=0
  info "Checking dependencies..."
  for dep in "${AMUMSS_DEPS[@]}"; do
    IFS='|' read -r cmd _pkg hint <<<"$dep"
    check_dep "$cmd" "$hint" || fail=1
  done
  if lua -e "assert(pcall(require,'lfs'))" 2>/dev/null; then
    echo "  ok: lua lfs"
  else
    echo "  MISSING: lua lfs module"
    fail=1
  fi

  info "Checking MBINCompiler-linux..."
  if [[ -x "$AMUMSS_HOME/MODBUILDER/MBINCompiler-linux" ]]; then
    "$AMUMSS_HOME/MODBUILDER/MBINCompiler-linux" version 2>/dev/null | head -n 1
  else
    echo "  MISSING: MODBUILDER/MBINCompiler-linux -- run linux/scripts/fetch_mbincompiler.sh"
    fail=1
  fi

  info "Checking NMS install..."
  if [[ -f "$AMUMSS_HOME/CONFIG/NMS_FOLDER.txt" ]]; then
    echo "  ok: CONFIG/NMS_FOLDER.txt = $(cat "$AMUMSS_HOME/CONFIG/NMS_FOLDER.txt")"
  else
    echo "  MISSING: CONFIG/NMS_FOLDER.txt -- run buildmod.sh --setup"
    fail=1
  fi

  info "Checking ported core..."
  if [[ -d "$AMUMSS_HOME/MODBUILDER/.orig-upstream" ]]; then
    "$LINUX_DIR/scripts/sync_core.sh" --verify || fail=1
  else
    echo "  MISSING: core not synced -- run linux/scripts/sync_core.sh"
    fail=1
  fi

  return "$fail"
}

detect_nms() {
  local roots=(
    "$HOME/.steam/steam"
    "$HOME/.local/share/Steam"
  )
  local lib line candidate
  local -a libs=()
  for root in "${roots[@]}"; do
    local vdf="$root/steamapps/libraryfolders.vdf"
    [[ -f "$vdf" ]] || continue
    while IFS= read -r line; do
      if [[ "$line" =~ \"path\"[[:space:]]+\"([^\"]+)\" ]]; then
        libs+=("${BASH_REMATCH[1]}")
      fi
    done <"$vdf"
    libs+=("$root")
  done
  # Deduplicate while preserving order.
  local -a uniq_libs=()
  for lib in "${libs[@]}"; do
    [[ " ${uniq_libs[*]} " == *" $lib "* ]] || uniq_libs+=("$lib")
  done
  for lib in "${uniq_libs[@]}"; do
    candidate="$lib/steamapps/common/No Man's Sky"
    if [[ -f "$candidate/GAMEDATA/PCBANKS/BankSignatures.bin" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

make_shim() {
  # make_shim <name-in-MODBUILDER> <target-command...>
  local name="$1"
  shift
  local shim="$AMUMSS_HOME/MODBUILDER/$name"
  if [[ -L "$shim" ]]; then
    rm -f "$shim"
  elif [[ -e "$shim" ]]; then
    # Real (Windows) binary: keep it aside so the tree still works on Windows.
    [[ -e "$shim.win32" ]] || mv "$shim" "$shim.win32"
    echo "  keep-windows-binary: $name -> $name.win32"
  fi
  printf '#!/usr/bin/env bash\nexec %s "$@"\n' "$*" >"$shim"
  chmod +x "$shim"
  echo "  shim: $name -> $*"
}

do_setup() {
  info "AMUMSS_HOME=$AMUMSS_HOME"

  info "Detecting NMS Steam install..."
  local nms
  if nms="$(detect_nms)"; then
    mkdir -p "$AMUMSS_HOME/CONFIG"
    printf '%s' "$nms" >"$AMUMSS_HOME/CONFIG/NMS_FOLDER.txt"
    echo "  ok: NMS_FOLDER=$nms"
  else
    die "NMS install not found under Steam libraries. Set CONFIG/NMS_FOLDER.txt manually."
  fi

  info "Creating workspace dirs..."
  mkdir -p "$AMUMSS_HOME/ModScript" "$AMUMSS_HOME/CreatedMODS" \
    "$AMUMSS_HOME/MODBUILDER/_TEMP" "$AMUMSS_HOME/CONFIG"

  info "Creating native shims in MODBUILDER..."
  local mbin="$AMUMSS_HOME/MODBUILDER/MBINCompiler-linux"
  [[ -x "$mbin" ]] || warn "MBINCompiler-linux not present yet (run scripts/fetch_mbincompiler.sh); the shim will point at it anyway"
  make_shim "MBINCompiler.exe" "$mbin"
  make_shim "hgpaktool.exe" "hgpaktool"
  make_shim "sed-4.7-x64.exe" "sed"
  make_shim "curl.exe" "curl"
  make_shim "tee.exe" "tee"
  make_shim "wtee.exe" "tee"
  make_shim "7z.exe" "7z"
  if [[ ! -e "$AMUMSS_HOME/MODBUILDER/psarc.exe" ]]; then
    cat >"$AMUMSS_HOME/MODBUILDER/psarc.exe"  <<'SHIM'
#!/usr/bin/env bash
echo "psarc.exe shim: legacy .pak packing is not supported on Linux." >&2
echo "NMS >= 5.5 uses loose-folder mods (GAMEDATA/MODS/<mod>/...), no packing needed." >&2
exit 1
SHIM
    chmod +x "$AMUMSS_HOME/MODBUILDER/psarc.exe"
    echo "  shim: psarc.exe -> legacy blocker notice (see linux/README.md)"
  fi

  info "Setup done. Run './linux/buildmod.sh --check' (or with AMUMSS_HOME) to verify."
}

do_pipeline() {
  case "$COPY_TO_GAME" in
    none | some | all) ;;
    *) die "--copy-to-game must be none|some|all" ;;
  esac
  [[ "$DEV_MODE" == "F" || "$DEV_MODE" == "L" ]] || die "--dev-mode must be F|L"

  if [[ ! -d "$AMUMSS_HOME/MODBUILDER/.orig-upstream" ]]; then
    info "Syncing ported core..."
    "$LINUX_DIR/scripts/sync_core.sh" || die "core sync failed"
  fi

  # idempotent
  do_setup

  if [[ ! -x "$AMUMSS_HOME/MODBUILDER/MBINCompiler-linux" ]]; then
    die "MBINCompiler-linux missing: run linux/scripts/fetch_mbincompiler.sh"
  fi

  # NMS pak listing for MBIN->pak lookups; mirrors -RecreatePAKList=Y.
  if [[ "$REFRESH_PAK_LIST" == "1" || ! -f "$AMUMSS_HOME/MODBUILDER/pak_list.txt" ]]; then
    info "Building NMS PAK file list..."
    if ! AMUMSS_HOME="$AMUMSS_HOME" "$LINUX_DIR/scripts/refresh_pak_list.sh"; then
      die "pak list refresh failed"
    fi
  fi

  info "Preparing pipeline workspace..."
  # do_setup already made ModScript/CreatedMODS/CONFIG/_TEMP.
  mkdir -p "$AMUMSS_HOME/ModBackups/________________IncrementalBuilds" \
    "$AMUMSS_HOME/ModBackups/________________BuildHistory" \
    "$AMUMSS_HOME/TOOLS/REPORTS_BACKUP" "$AMUMSS_HOME/TOOLS/MODDER_Helper" \
    "$AMUMSS_HOME/MODBUILDER/MOD" "$AMUMSS_HOME/MODBUILDER/_TEMP/DECOMPILED" \
    "$AMUMSS_HOME/MODBUILDER/_TEMP/EXTRACTED"
  # Mirror BUILDMOD.bat: force scripts active (no ___DONOTUSE handling on Linux).
  [[ -f "$AMUMSS_HOME/ModScript/___USE.txt" ]] || : >"$AMUMSS_HOME/ModScript/___USE.txt"
  if [[ "$ALLOW_COMBINE" == "0" && -f "$AMUMSS_HOME/ModScript/___COMBINE.txt" ]]; then
    info "Renaming ___COMBINE.txt (individual mods; pass --combine to allow)"
    mv "$AMUMSS_HOME/ModScript/___COMBINE.txt" "$AMUMSS_HOME/ModScript/___COMBINEx.txt"
  fi
  rm -f "$AMUMSS_HOME/MODBUILDER/exitCode.txt" "$AMUMSS_HOME/MODBUILDER/LuaEndedOK.txt"

  local copyflag="$COPY_TO_GAME"
  local copyenv="NONE"
  case "$copyflag" in
    some) copyenv="SOME" ;;
    all) copyenv="ALL" ;;
  esac

  info "Starting pipeline (copy-to-game=$copyflag, dev-mode=$DEV_MODE)..."
  # NOTE: option names contain dashes, which bash cannot export. They are
  # passed through env(1) (with -- so -C etc. are not parsed as env flags).
  local -a opts=(
    "_mLUA=lua" "_mLUAM=lua" "_mLUAS=lua" "_mLUAC=luac"
    "_mNoGUIFWait=1" "_SOUND=N" "_DEV_MODE=$DEV_MODE"
    "_bCOMBINE_MOD_TYPE=0" "_bCOPYtoNMS=$copyenv" "_bMaxPakNameLength=55"
    "-AutoUpdateAMUMSS=N" "-AutoUpdateMBinCompiler=N"
    "-BackupReports=10" "-BackupType=NONE" "-CheckForModConflicts=M"
    "-CLEANLOG=Y" "-CombineModPak=N" "-CopyToGamefolder=ASK"
    "-CreateUsefulUtilityScripts=N" "-DEV_MODE=$DEV_MODE"
    "-EXPORTED=N" "-EXT_FUNC_Helper=N" "-GUIF_AllowRequests=N"
    "-GUIF_DelayMult=1.0" "-FileStructureLevel=1" "-GameVersion=P"
    "-IncludeLuaScriptInPak=Y" "-IncludeTagsInEXML_MXML=N"
    "-IncrementalBuilds=3" "-MAPFILETREE=N" "-MAPFILETREEFORCE=N"
    "-MODSfolderNameScript=N" "-NMSreStart=N" "-ReCreateMapFileTree=N"
    "-RecreatePAKList=N" "-SerializeScript=N" "-SHOWEXTRASECTIONS=N"
    "-SHOWOPTIONS=N" "-SHOWSECTIONS=N" "-SHOWSimpleContainer=N"
    "-SOUND=N" "-TABtoSPACES=2" "-TestScript=Y" "-UseColors=Y"
    "-UseColorConfig=N" "-UseExtraFilesInPAK=N" "-UseLastCompiler=Y"
    "-UseLuaScriptInPak=Y" "-CombinedModType=0"
  )
  ( 
    cd "$AMUMSS_HOME/MODBUILDER" || exit 1
    export PATH="$AMUMSS_HOME/MODBUILDER:$PATH"
    export LUA_PATH="$LINUX_DIR/lua/?.lua;;"
    # shellcheck disable=SC2086
    env -- "${opts[@]}" lua "$LINUX_DIR/lua/run_pipeline.lua"
  )
  local rc=$?
  if [[ -f "$AMUMSS_HOME/MODBUILDER/exitCode.txt" ]]; then
    info "exitCode.txt: $(cat "$AMUMSS_HOME/MODBUILDER/exitCode.txt")"
  fi
  info "Pipeline finished (lua exit=$rc)."
  return "$rc"
}

case "$MODE" in
  --setup) do_setup ;;
  --check)
    if do_check; then
      info "Environment OK."
    else
      die "Environment incomplete. Run buildmod.sh --setup and scripts/install_deps.sh."
    fi
    ;;
  --run-pipeline)
    do_pipeline
    ;;
esac
