# AMUMSS `.lua` core - posix port

The core ships in the full AMUMSS release (Nexus #957), not in this repo, so
the ported core lives here as source. `scripts/sync_core.sh` copies it into an
install.

Baseline is AMUMSS 5.6.2.0w, so `git diff HEAD~1 HEAD -- linux/core/MODBUILDER`
is the whole port. `sync_core.sh --revert` restores the install's originals
from `MODBUILDER/.orig-upstream/`.

`thirdparty/bint.lua` is lua-bint v0.5.2 (MIT), needed by `LoadHelpers` and by
the tests.

## Notes

- `H.gPS` / `H.gIsWindows` gate the posix branches.
- `LoadAndExecuteModScript.lua` is **Linux-only**: its literals and raw
  `strgsub`/`strfind` calls were rewritten in place rather than branched. The
  other three stay valid on a Windows build. Never copy it to a Windows install.
- `gsub(..., -1)`: stock PUC lua 5.4.8 does zero substitutions for negative `n`
  while the shipped `lua.exe` tolerates it, which broke edit targeting. Count
  sites on the Linux path use portable idioms.
- Content paths stay backslash inside EXML/sed flows, filesystem paths are
  posix, and tables touched by both (`gFastPAKlist`, `linkedFiles`) carry twin
  keys so either form hits.
- hgpaktool 1.1.3: no `-A`, `-L` ignores `-O` and writes `./filenames.txt`, and
  some paks list flat names (re-placed into subdirs after extraction).
- `H.DeleteDir` is guarded because `lfs.dir` errors on a missing directory.

## Not ported

`CreateMapFileTree*.lua`, `CheckOUTDATED.lua`, `CheckMODS.lua` (map-tree flow
defaults off, the rest are not in the build flow); legacy `psarc.exe` pak
packing; `RunThisJob.exe` / `tasklist` multithreading; `XLST` commands.
