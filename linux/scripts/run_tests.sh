#!/usr/bin/env bash
# run_tests.sh - run the linux port's tests.
#
#   ./linux/scripts/run_tests.sh
#
# test_path and test_copier are hermetic (linux/core/ in a throwaway sandbox,
# needs only lua + lfs). test_env needs a real install and reports SKIP without
# one. Exit: 0 pass, 1 fail.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

for arg in "$@"; do
  case "$arg" in
    -h | --help)
      usage_from_header "$0"
      exit 0
      ;;
    *) die "unknown argument: $arg" ;;
  esac
done

have lua || die "lua not installed (run scripts/install_deps.sh)"
lua -e "assert(pcall(require,'lfs'))" 2>/dev/null || die "lua lfs module missing (run scripts/install_deps.sh)"

SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/amumss-tests.XXXXXX")"
trap 'rm -rf "$SANDBOX"' EXIT
mkdir -p "$SANDBOX/MODBUILDER" "$SANDBOX/CONFIG"
# LoadHelpers reads this at load time; content is irrelevant for these tests.
: >"$SANDBOX/CONFIG/NMS_FOLDER.txt"

resolve_amumss_home
export AMUMSS_CORE_DIR="$LINUX_DIR/core/MODBUILDER"
export AMUMSS_TMP_DIR="$SANDBOX/work"
export LUA_PATH="$LINUX_DIR/lua/?.lua;$LINUX_DIR/core/thirdparty/?.lua;;"

failed=0
skipped=()

run_hermetic() { # <test.lua> - cwd is a sandbox, not an install
  echo "== $1"
  if ! (cd "$SANDBOX/MODBUILDER" && lua "$LINUX_DIR/tests/$1"); then
    failed=1
  fi
}

run_in_install() { # <test.lua>
  echo "== $1"
  if [[ ! -d "$AMUMSS_HOME/MODBUILDER" ]]; then
    echo "  skip $1  (no AMUMSS install; set AMUMSS_HOME)"
    skipped+=("$1")
    return
  fi
  # MODBUILDER on PATH: the *.exe shims created by buildmod.sh --setup live there.
  if ! (cd "$AMUMSS_HOME/MODBUILDER" && PATH="$AMUMSS_HOME/MODBUILDER:$PATH" lua "$LINUX_DIR/tests/$1"); then
    failed=1
  fi
}

run_hermetic test_path.lua
run_hermetic test_copier.lua
run_in_install test_env.lua

if [[ $failed -ne 0 ]]; then
  echo "RESULT: FAILURES" >&2
  exit 1
fi
echo "RESULT: ok${skipped[0]:+ (skipped: ${skipped[*]})}"
