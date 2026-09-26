#!/usr/bin/env bash
# install_deps.sh - check/install system dependencies for AMUMSS on Linux.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

fail=0

# check_cmd <cmd> <package> <hint>
check_cmd() {
  if have "$1"; then
    echo "    ok: $1"
    return 0
  fi
  echo "    MISSING: $1 ($3)"
  install_hint "$2"
  fail=1
}

info "Package manager: $(detect_pm)"

info "Core commands ..."
for dep in "${AMUMSS_DEPS[@]}"; do
  IFS='|' read -r cmd pkg hint <<<"$dep"
  check_cmd "$cmd" "$pkg" "$hint"
done
check_cmd sed - "preinstalled on any normal distro"

info "lua lfs module ..."
if lua -e "assert(pcall(require,'lfs'))" 2>/dev/null; then
  echo "    ok: $(lua -v 2>&1) with lfs"
else
  echo "    MISSING: lfs - install liblua5.4-dev / lua-lfs"
  install_hint lua5.4 liblua5.4-dev
  fail=1
fi

info "lanes rock (lua multithreading) ..."
# LUA_PATH/C_PATH mirror `luarocks install --local` output dirs.
if lua -e "package.path=os.getenv('HOME')..'/.luarocks/share/lua/5.4/?.lua;'..package.path; package.cpath=os.getenv('HOME')..'/.luarocks/lib64/lua/5.4/?.so;'..os.getenv('HOME')..'/.luarocks/lib/lua/5.4/?.so;'..package.cpath; assert(pcall(require,'lanes'))" 2>/dev/null; then
  echo "    ok: lanes rock installed"
elif have luarocks; then
  echo "    installing via luarocks (needs gcc + lua headers)..."
  luarocks install --local lanes || fail=1
else
  echo "    MISSING: luarocks"
  install_hint luarocks gcc
  fail=1
fi

info "hgpaktool (NMS pak extract/repack) ..."
if have hgpaktool; then
  echo "    ok: hgpaktool"
else
  echo "    installing via pip..."
  python3 -m pip install --user hgpaktool || fail=1
fi

info ".NET runtime (for MBINCompiler-linux) ..."
if have dotnet && dotnet --list-runtimes 2>/dev/null | grep -qE 'Microsoft.NETCore.App (8|9|10)\.'; then
  dotnet --list-runtimes 2>/dev/null | grep 'Microsoft.NETCore.App' | head -n 3 | sed 's/^/    ok: /'
else
  echo "    MISSING: .NET 8+ runtime (https://dotnet.microsoft.com/download)"
  install_hint dotnet-runtime-8.0
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  echo "RESULT: incomplete - fix the MISSING items above, then re-run." >&2
  exit 1
fi
echo "RESULT: all dependencies present."
