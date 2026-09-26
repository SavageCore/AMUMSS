-- Lint config for linux/lua/ and linux/tests/ only; linux/core/ is vendored
-- upstream source. H and lfs are globals the core expects; io/os are writable
-- because compat.lua and run_pipeline.lua exist to patch them.
std = "lua54"
max_line_length = false
globals = { "H", "lfs", "io", "os" }
exclude_files = { "linux/core/" }
