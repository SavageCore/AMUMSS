#!/usr/bin/env bash
# refresh_pak_list.sh - Linux equivalent of PSARC_LIST_PAKS.BAT: rebuilds
# MODBUILDER/pak_list.txt (used for MBIN->pak lookups) and the TOOLS lists.
# buildmod.sh runs this when pak_list.txt is missing; --refresh-pak-list forces it.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

resolve_amumss_home
need_modbuilder
[[ -f "$AMUMSS_HOME/CONFIG/NMS_FOLDER.txt" ]] || die "CONFIG/NMS_FOLDER.txt missing (run buildmod.sh --setup)"
have hgpaktool || die "hgpaktool not installed (run scripts/install_deps.sh)"

PCBANKS="$(cat "$AMUMSS_HOME/CONFIG/NMS_FOLDER.txt")/GAMEDATA/PCBANKS"
[[ -d "$PCBANKS" ]] || die "PCBANKS not found: $PCBANKS"

# The core helpers dofile() LoadHelpers relatively, so cwd must be MODBUILDER.
cd "$AMUMSS_HOME/MODBUILDER" || exit 1

info "Listing NMS PCBANKS content (fast, headers only)..."
rm -f pak_list.txt filenames.txt
hgpaktool --upper -L -p "$PCBANKS"
# hgpaktool 1.1.3 ignores -O and always writes ./filenames.txt
[[ -f filenames.txt ]] || die "hgpaktool produced no listing"
mv filenames.txt pak_list.txt
: >PAK_LIST_CREATED.txt

info "Formatting lists..."
run_lua FormatPAKlist.lua
mkdir -p ../TOOLS
# Names mirror PSARC_LIST_PAKS.BAT (_pPAK_LIST=pak_list.txt): source file ->
# TOOLS destination. Linux also refreshes pak_UniqueDir.txt, which the .bat
# leaves alone.
while IFS='|' read -r src dest; do
  [[ -f "$src" ]] && cp -f "$src" "../TOOLS/$dest"
done <<'EOF'
pak_list.txtPretty.lua|NMS_pak_listPretty.lua
pak_Dir.txtPretty.lua|NMS_pak_DirPretty.lua
Full_pak_list.txt|NMS_FULL_pak_list.txt
pak_UniqueDir.txt|NMS_pak_UniqueDir.txt
EOF
run_lua CleanPAKlist.lua
run_lua GetNMSMainFolders.lua

info "Clearing stale decompile cache..."
rm -rf _TEMP
mkdir -p _TEMP/DECOMPILED _TEMP/EXTRACTED

info "pak_list.txt ready ($(wc -l <pak_list.txt ) lines)."
