-- test_copier.lua - H.copy_posix and file helpers in core/MODBUILDER/LoadHelpers.lua.
-- Run via linux/scripts/run_tests.sh, which provides the sandbox and AMUMSS_TMP_DIR.

local T = require("testlib")
require("compat")
lfs = require("lfs")
dofile(os.getenv("AMUMSS_CORE_DIR") .. "/LoadHelpers.lua")

local root = os.getenv("AMUMSS_TMP_DIR")
local function path(...) return root .. "/" .. table.concat({...}, "/") end
local function write(p, data) H.WriteToFile(data, p) end

-- WriteToFile does not mkdir (same as upstream), so build the tree explicitly.
os.execute("rm -rf " .. string.format("%q", root))
H.mkdir(root .. "/")
H.mkdir(path("src") .. "/")
H.mkdir(path("src", "sub") .. "/")
H.mkdir(path("src", "sub2") .. "/")
write(path("src", "a.EXML"), "keep")
write(path("src", "b.MXML"), "skipme")
write(path("src", "sub", "c.EXML"), "keep2")
write(path("src", "sub2", "d.EXML"), "keep3")
write(path("loose.txt"), "hello")

T.ok("IsDirExist posix", H.IsDirExist(root))
T.ok("IsDirExist trailing slash", H.IsDirExist(root .. "/"))
T.ok("IsDirExist missing", not H.IsDirExist(path("no-such-dir-xyz")))

-- file -> file
T.ok("copy file->file", H.CopyFile(path("loose.txt"), path("copied.txt")))
T.eq("content intact", H.LoadFileData(path("copied.txt")), "hello")

-- file -> dir, both dest spellings
H.mkdir(path("d1") .. "/")
H.mkdir(path("d2") .. "/")
T.ok("copy file->dir with trailing slash", H.CopyFile(path("loose.txt"), path("d1") .. "/"))
T.ok("copy file->dir without trailing slash", H.CopyFile(path("loose.txt"), path("d2")))
T.ok("landed in d1", H.IsFileExist(path("d1", "loose.txt")))
T.ok("landed in d2", H.IsFileExist(path("d2", "loose.txt")))

-- EXCLUDE: param reads its patterns from <param file> in cwd. The real install
-- ships these next to the core; the sandbox provides its own.
H.WriteToFile(".MXML\n", "xcopy_excludeMXML.txt")
H.mkdir(path("out-exc") .. "/")
T.ok("copy dir->dir with EXCLUDE", H.CopyFile(path("src"), path("out-exc") .. "/", H.paramExcMXML))
T.ok("kept a.EXML", H.IsFileExist(path("out-exc", "a.EXML")))
T.ok("kept nested c.EXML", H.IsFileExist(path("out-exc", "sub", "c.EXML")))
T.ok("excluded b.MXML", not H.IsFileExist(path("out-exc", "b.MXML")))

-- /s is what separates H.paramFiles (files only) from H.paramFilesDir
-- (recursive). Same source, different param, different result.
H.mkdir(path("out-nos") .. "/")
H.mkdir(path("out-s") .. "/")
T.ok("copy dir->dir without /s", H.CopyFile(path("src"), path("out-nos") .. "/", H.paramFiles))
T.ok("copy dir->dir with /s", H.CopyFile(path("src"), path("out-s") .. "/", H.paramFilesDir))
T.ok("no-/s kept top-level file", H.IsFileExist(path("out-nos", "a.EXML")))
T.ok("no-/s skipped sub-folder", not H.IsDirExist(path("out-nos", "sub")))
T.ok("/s recursed into sub", H.IsFileExist(path("out-s", "sub", "c.EXML")))

-- wildcard src + trailing * dest (xcopy conventions)
H.mkdir(path("wild") .. "/")
write(path("wild", "x1.txt"), "w1")
write(path("wild", "x2.txt"), "w2")
T.ok("copy wildcard -> dir", H.CopyFile(path("wild") .. "/*.*", path("wildout") .. "/"))
T.ok("wildcard landed x1", H.IsFileExist(path("wildout", "x1.txt")))
T.ok("wildcard landed x2", H.IsFileExist(path("wildout", "x2.txt")))

-- delete / move
write(path("todel.txt"), "bye")
H.DeleteFile(path("todel.txt"))
T.ok("DeleteFile", not H.IsFileExist(path("todel.txt")))
T.ok("MoveFileDirectory", H.MoveFileDirectory(path("copied.txt"), path("moved.txt")))
T.ok("moved", H.IsFileExist(path("moved.txt")))

H.DeleteDir(path("out-s"))
T.ok("DeleteDir removes the tree", not H.IsDirExist(path("out-s")))

local listed = H.ListDir({}, path("src"), false, true)
T.eq("ListDir recursive count", #listed, 4)

os.execute("rm -rf " .. string.format("%q", root))
T.done("test_copier")
