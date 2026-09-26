-- test_path.lua - path helpers in linux/core/MODBUILDER/LoadHelpers.lua.
-- Run via linux/scripts/run_tests.sh, which builds the sandbox and LUA_PATH.

local T = require("testlib")
require("compat")
lfs = require("lfs")
dofile(os.getenv("AMUMSS_CORE_DIR") .. "/LoadHelpers.lua")

T.eq("gPS is the native separator", H.gPS, "/")
T.eq("gIsWindows is false", H.gIsWindows, false)

T.eq("NormalizePath mixed seps",
  H.NormalizePath([[..\MODBUILDER/_TEMP\\DECOMPILED\]], nil, false), "../MODBUILDER/_TEMP/DECOMPILED/")
T.eq("NormalizePath posix passthrough", H.NormalizePath("/a/b/c", nil, false), "/a/b/c")
T.eq("NormalizePath collapses //", H.NormalizePath("/a//b///c", nil, false), "/a/b/c")
T.eq("NormalizePath uppercases by default", H.NormalizePath("mod/file.mbin"), "MOD/FILE.MBIN")
T.eq("NormalizePath nil", H.NormalizePath(nil), nil)

T.eq("getPath posix", H.getPath("/a/b/file.txt"), "/a/b/")
T.eq("getPath backslash input", H.getPath([[C:\a\b\file.txt]]), "C:/a/b/")

T.eq("filename posix", H.GetFilenameFromFilePath("/a/b/FILE.MBIN", false), "FILE.MBIN")
T.eq("filename backslash input", H.GetFilenameFromFilePath([[..\MOD\FILE.MBIN]], false), "FILE.MBIN")

T.eq("folder posix", H.GetFolderPathFromFilePath("/a/b/c/file.txt"), "/a/b/c")
T.eq("folder backslash input", H.GetFolderPathFromFilePath([[C:\a\b\file.txt]]), "C:/a/b")
T.eq("folder no dir", H.GetFolderPathFromFilePath("file.txt"), "")
T.eq("folder nil", H.GetFolderPathFromFilePath(nil), nil)

T.eq("extension through the patched helpers", H.GetExtensionFromFilePath("/a/b/FILE.MBIN", false), ".MBIN")
T.ok("g_TEMP_DECOMPILED_PATH has no backslash",
  not string.find(H.g_TEMP_DECOMPILED_PATH, "\\", 1, true), H.g_TEMP_DECOMPILED_PATH)

T.done("test_path")
