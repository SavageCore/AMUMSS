# AMUMSS on Linux

Native (no Wine) Linux support for AMUMSS, targeting Steam on Linux with
NMS >= v5.5 (folder mods under `GAMEDATA/MODS`).

## Setup

The Windows core ships in the full AMUMSS release (Nexus #957), not in this
repo. Install it somewhere, e.g. `~/AMUMSS`, then:

```sh
./linux/scripts/install_deps.sh
AMUMSS_HOME=~/AMUMSS ./linux/buildmod.sh --setup
AMUMSS_HOME=~/AMUMSS ./linux/scripts/fetch_mbincompiler.sh
AMUMSS_HOME=~/AMUMSS ./linux/buildmod.sh --run-pipeline
```

Add `--copy-to-game=all` to install the built mods into `GAMEDATA/MODS`. Other
options: `--copy-to-game=none|some`, `--combine`, `--dev-mode=F|L`,
`--refresh-pak-list`.

## Layout

- `buildmod.sh` - entry point (`--setup`, `--check`, `--run-pipeline`)
- `core/` - the `.lua` core, ported for posix (see `core/README.md`)
- `scripts/sync_core.sh` - copy `core/` into an install; `--verify`, `--revert`
- `scripts/` - deps, MBINCompiler fetch, pak list, tests, lint
- `lua/` - `compat.lua` shim for system lua, `run_pipeline.lua` entry
- `tests/` - 48 checks, run by `scripts/run_tests.sh`

## Development

```sh
./linux/scripts/run_tests.sh    # exit 0 pass, 1 fail
./linux/scripts/lint.sh         # shellcheck, luacheck, shfmt
```

`core/` is vendored upstream source: it is not linted or reformatted, so the
port stays re-basable. After an AMUMSS update `sync_core.sh --verify` reports
drift.

## Limitations

- `XLST` script commands need `powershell.exe`; warned and skipped.
- Legacy `.pak` packing (`psarc.exe`) is unsupported; NMS >= v5.5 emits
  loose-folder mods, so nothing needs it.
- `RunThisJob.exe` / `tasklist` multithreading is Windows-only; `lanes` is
  stubbed in `lua/compat.lua`.
- `-IncludeTagsInEXML_MXML=N`: `!#` marker tags are stripped from output. The
  Windows default `Y` keeps them.
- Map file tree is off by default (`-MAPFILETREE=N`).
- Prompts are non-interactive; `--copy-to-game=some` still asks per mod.
