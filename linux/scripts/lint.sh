#!/usr/bin/env bash
# lint.sh - static checks for the shell and lua this repo owns.
# linux/core/ is vendored upstream source and is intentionally not linted.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

rc=0
have() { command -v "$1" >/dev/null 2>&1; }

if have shellcheck; then
  echo "== shellcheck (shell)"
  shellcheck "$LINUX_DIR/buildmod.sh" "$LINUX_DIR"/scripts/*.sh || rc=1
else
  echo "== shellcheck: SKIPPED (not installed)"
fi

if have luacheck; then
  echo "== luacheck (lua)"
  (cd "$LINUX_DIR/.." && luacheck linux/lua linux/tests) || rc=1
else
  echo "== luacheck: SKIPPED (not installed)"
fi

if have shfmt; then
  echo "== shfmt (formatting)"
  shfmt --diff --indent 2 --case-indent --keep-padding \
    "$LINUX_DIR/buildmod.sh" "$LINUX_DIR"/scripts/*.sh || rc=1
else
  echo "== shfmt: SKIPPED (not installed; go install mvdan.cc/sh/v3/cmd/shfmt@latest)"
fi

exit $rc
