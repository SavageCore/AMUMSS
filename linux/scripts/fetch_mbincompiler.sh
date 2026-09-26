#!/usr/bin/env bash
# fetch_mbincompiler.sh - download MBINCompiler-linux + libMBIN-linux.so
# from monkeyman192/MBINCompiler releases into MODBUILDER/.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Or pin, e.g. MBINCOMPILER_TAG=v7.04.0-pre1
TAG="${MBINCOMPILER_TAG:-latest}"

resolve_amumss_home
need_modbuilder
DEST="$AMUMSS_HOME/MODBUILDER"

if [[ "$TAG" == "latest" ]]; then
  info "resolving latest MBINCompiler release..."
  TAG="$(gh api repos/monkeyman192/MBINCompiler/releases/latest --jq .tag_name)"
  info "latest tag: $TAG"
fi

for asset in MBINCompiler-linux libMBIN-linux.so; do
  info "downloading $asset ($TAG)..."
  curl -sSL -o "$DEST/$asset" \
    "https://github.com/monkeyman192/MBINCompiler/releases/download/${TAG}/${asset}"
done
chmod +x "$DEST/MBINCompiler-linux"
"$DEST/MBINCompiler-linux" version | head -n 2
info "installed into $DEST"
