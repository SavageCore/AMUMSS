-- compat.lua - preload for running the AMUMSS lua core with system lua.
-- Put linux/lua on LUA_PATH and require("compat") before dofile()ing a core
-- script; linux/lua/run_pipeline.lua does that for you.
--
-- Bridges three gaps with the shipped Windows lua.exe:
--   1. lfs - the core uses a bare global; the shipped build links it statically.
--   2. lanes - configure() is called and the result never used, and the
--      vendored lanes.lua wants the obsolete 'lanes_core' C module. Stub it,
--      and error if a real lanes function is ever called.
--   3. io.read "f"/"h"/"g" keypress modes, which system lua lacks. Unreachable
--      with _mNoGUIFWait set, so just a safety net.
--
-- Path separators are not handled here; see linux/core/.

-- bint lives next to the core scripts; make it importable.
package.path = "./MODBUILDER/?.lua;?.lua;" .. package.path

lfs = require("lfs")

do
  local lanes = {}
  function lanes.configure(_opt) return lanes end
  setmetatable(lanes, {
    __index = function(_t, k)
      error("compat.lua lanes stub: unexpected use of lanes." .. tostring(k)
        .. " - the Linux port needs a real lanes binding here", 2)
    end,
  })
  package.loaded["lanes"] = lanes
end

do
  local orig_read = io.read
  io.read = function(fmt, ...)
    if fmt == "f" then return "" end   -- nothing pending
    if fmt == "h" then return nil end -- no key hit
    if fmt == "g" then return orig_read("*l") end
    return orig_read(fmt, ...)
  end
end
