#!/usr/bin/env bash
# shellcheck shell=bash
# common.sh - shared helpers for linux/*.sh. Source, do not execute.
#
#   source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

LINUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

die() {
  echo "ERROR: $*" >&2
  exit 1
}
info() { echo "--> $*"; }
warn() { echo "  warn: $*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

# resolve_amumss_home [candidate] - $AMUMSS_HOME, else cwd if it looks like an
# install, else ~/AMUMSS.
resolve_amumss_home() {
  AMUMSS_HOME="${1:-${AMUMSS_HOME:-}}"
  if [[ -z "$AMUMSS_HOME" ]]; then
    if [[ -d "./MODBUILDER" ]]; then AMUMSS_HOME="$PWD"; else AMUMSS_HOME="$HOME/AMUMSS"; fi
  fi
  export AMUMSS_HOME
}

need_modbuilder() {
  [[ -d "$AMUMSS_HOME/MODBUILDER" ]] || die "MODBUILDER/ missing under $AMUMSS_HOME - is this a full AMUMSS install?"
}

# Dependency table, shared by scripts/install_deps.sh (install) and
# buildmod.sh --check (verify) so the two can't drift: cmd|package|check hint
# shellcheck disable=SC2034  # read by the scripts that source this file
AMUMSS_DEPS=(
  "lua|lua5.4 liblua5.4-dev|install lua 5.4 (system package)"
  "luarocks|luarocks|install luarocks (for the lanes rock)"
  "hgpaktool|python3-pip|python3 -m pip install --user hgpaktool"
  "dotnet|dotnet-runtime-8.0|install .NET 8+ runtime"
  "curl|curl|install curl"
  "7z|p7zip-full|install p7zip/7zip"
)

# detect_pm - name of the first supported package manager, or a notice.
detect_pm() {
  local pm
  for pm in apt-get dnf pacman zypper; do
    if have "$pm"; then
      echo "$pm"
      return
    fi
  done
  echo "none detected (install manually)"
}

# install_hint <package-name> - command to run for the detected package manager.
install_hint() {
  case "$(detect_pm)" in
    apt-get) echo "sudo apt-get install -y $*" ;;
    dnf) echo "sudo dnf install -y $*" ;;
    pacman) echo "sudo pacman -S --needed $*" ;;
    zypper) echo "sudo zypper install -y $*" ;;
    *) echo "(no supported package manager; install by hand: $*)" ;;
  esac
}

# run_lua <file.lua> - run a core helper that dofile()s relatively.
# Must be called with cwd=$AMUMSS_HOME/MODBUILDER.
run_lua() {
  LUA_PATH="$LINUX_DIR/lua/?.lua;;" lua -e "require('compat'); dofile('$1')"
}

# usage_from_header <script> - print the leading comment block of a script as
# usage text, so --help needs no duplicated string.
usage_from_header() {
  sed -n '2,/^$/p' "$1" | sed 's/^#\{1,\} \{0,1\}//'
}
