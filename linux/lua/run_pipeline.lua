-- run_pipeline.lua - pipeline entry point. Invoke with cwd=MODBUILDER and
-- linux/lua on LUA_PATH (buildmod.sh does both). A real file rather than
-- `lua -e` keeps #arg == 0, as BUILDMOD.bat does.
--
-- AMUMSS_TRACE_EXEC=<log> appends every os.execute command.
require("compat")

do
  local tracePath = os.getenv("AMUMSS_TRACE_EXEC")
  if tracePath and tracePath ~= "" then
    local orig_execute = os.execute
    os.execute = function(cmd, ...)
      local f = io.open(tracePath, "a")
      if f then f:write("EXEC>>> " .. tostring(cmd) .. "\n"); f:close() end
      return orig_execute(cmd, ...)
    end
  end
end

dofile("LoadAndExecuteModScript.lua")
