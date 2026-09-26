-- test_env.lua - checks needing a real AMUMSS install and NMS on disk; exits 77
-- when either is missing. Run via linux/scripts/run_tests.sh.

local T = require("testlib")
require("compat")
lfs = require("lfs")

local home = os.getenv("AMUMSS_HOME")
if not home or lfs.attributes(home .. "/MODBUILDER", "mode") ~= "directory" then
  T.skip("test_env", "no AMUMSS install (set AMUMSS_HOME)")
  T.done("test_env")
end

dofile("LoadHelpers.lua")

T.ok("PCBANKS folder detected", H.gNMS_PCBANKS_FOLDER_PATH:find("PCBANKS", 1, true) ~= nil,
  H.gNMS_PCBANKS_FOLDER_PATH)
T.ok("MODS folder detected", H.gNMS_MODS_FOLDER:find("MODS", 1, true) ~= nil, H.gNMS_MODS_FOLDER)
T.ok("globals.pak present", H.IsFileExist(H.gNMS_PCBANKS_FOLDER_PATH .. "NMSARC.globals.pak"))
T.ok("gMASTER_FOLDER_PATH has no backslash",
  not string.find(H.gMASTER_FOLDER_PATH, "\\", 1, true), H.gMASTER_FOLDER_PATH)

if not H.IsFileExist("MBINCompiler-linux") then
  T.skip("mbincompiler version", "MODBUILDER/MBINCompiler-linux not installed")
else
  local str, num = H.GetMBINCompilerVersion(H.gCurrentMBINCompilerPath)
  T.ok("mbincompiler version parses", str ~= nil and str ~= "" and num ~= nil and num > 6, str)
end

T.done("test_env")
