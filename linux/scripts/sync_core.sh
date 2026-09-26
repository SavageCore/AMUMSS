#!/usr/bin/env bash
# sync_core.sh - copy the ported core (linux/core/) into an AMUMSS install.
#
#   AMUMSS_HOME=~/AMUMSS ./linux/scripts/sync_core.sh [--apply|--verify|--revert] [--force]
#
# Originals are backed up once to MODBUILDER/.orig-upstream/. The port targets
# one upstream version, so a mismatch is a hard stop unless --force.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CORE_DIR="$LINUX_DIR/core/MODBUILDER"
CORE_BASE_VERSION="5.6.2.0w"
BACKUP_DIR="$AMUMSS_HOME/MODBUILDER/.orig-upstream"
MODE="--apply"
FORCE=0

for arg in "$@"; do
  case "$arg" in
    --apply | --verify | --revert) MODE="$arg" ;;
    --force) FORCE=1 ;;
    -h | --help)
      usage_from_header "$0"
      exit 0
      ;;
    *) die "unknown argument: $arg" ;;
  esac
done

resolve_amumss_home
need_modbuilder

CORE_FILES=()
for f in "$CORE_DIR"/*.lua; do CORE_FILES+=("MODBUILDER/$(basename "$f")"); done
[[ ${#CORE_FILES[@]} -gt 0 ]] || die "no core files found in $CORE_DIR"

install_version="$(cat "$AMUMSS_HOME/MODBUILDER/AMUMSSVersion.txt" 2>/dev/null || echo unknown)"
if [[ "$install_version" != "$CORE_BASE_VERSION" && $FORCE -eq 0 ]]; then
  if [[ "$MODE" == "--verify" ]]; then
    warn "install is AMUMSS $install_version, this port targets $CORE_BASE_VERSION"
  else
    die "install is AMUMSS $install_version but this port targets $CORE_BASE_VERSION.
Re-port linux/core/ against $install_version, or pass --force to overwrite anyway."
  fi
fi

case "$MODE" in
  --apply)
    if [[ -d "$BACKUP_DIR" ]]; then
      echo "--> core already synced (backup in MODBUILDER/.orig-upstream), refreshing"
    else
      mkdir -p "$BACKUP_DIR/MODBUILDER"
      for f in "${CORE_FILES[@]}"; do
        [[ -f "$AMUMSS_HOME/$f" ]] || die "install is missing $f - not a full AMUMSS 5.6.2.0w install?"
        cp "$AMUMSS_HOME/$f" "$BACKUP_DIR/$f"
      done
      echo "--> backed up ${#CORE_FILES[@]} core files"
    fi
    for f in "${CORE_FILES[@]}"; do
      cp "$LINUX_DIR/core/$f" "$AMUMSS_HOME/$f"
      echo "    synced $f"
    done
    echo "--> core synced."
    ;;

  --verify)
    [[ -d "$BACKUP_DIR" ]] || die "core not synced yet (no MODBUILDER/.orig-upstream)"
    drift=0
    for f in "${CORE_FILES[@]}"; do
      if diff -q "$LINUX_DIR/core/$f" "$AMUMSS_HOME/$f" >/dev/null 2>&1; then
        echo "    ok: $f"
      else
        echo "    DRIFT: $f differs from linux/core/$f" >&2
        drift=1
      fi
    done
    [[ $drift -eq 0 ]] || die "core drift: re-run --apply, or re-port against AMUMSS $install_version"
    echo "--> core matches linux/core (AMUMSS $install_version)."
    ;;

  --revert)
    [[ -d "$BACKUP_DIR" ]] || die "nothing to revert (no MODBUILDER/.orig-upstream)"
    for f in "${CORE_FILES[@]}"; do
      [[ -f "$BACKUP_DIR/$f" ]] || continue
      cp "$BACKUP_DIR/$f" "$AMUMSS_HOME/$f"
      echo "    restored $f"
    done
    rm -rf "$BACKUP_DIR"
    echo "--> reverted to upstream core."
    ;;
esac
