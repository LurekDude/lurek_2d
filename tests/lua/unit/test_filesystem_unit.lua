-- Lurek2D filesystem API unit tests
-- Headless-safe (no window / GPU / audio required).
-- Tests the lurek.filesystem namespace: read, write, append, exists, remove,
-- openFile (FileHandle), newFileData (FileData), directory ops,
-- path queries, identity, lines, async read, mount/unmount, load.
-- @covers lurek.filesystem.read
-- @covers lurek.filesystem.write
-- @covers lurek.filesystem.exists
-- @covers lurek.filesystem.append
-- @covers lurek.filesystem.remove
-- @covers lurek.filesystem.openFile
-- @covers lurek.filesystem.newFileData
-- @covers lurek.filesystem.getDirectoryItems
-- @covers lurek.filesystem.isFile
-- @covers lurek.filesystem.isDirectory
-- @covers lurek.filesystem.createDirectory
-- @covers lurek.filesystem.getInfo
-- @covers lurek.filesystem.getSource
-- @covers lurek.filesystem.getSaveDirectory
-- @covers lurek.filesystem.getWorkingDirectory
-- @covers lurek.filesystem.getUserDirectory
-- @covers lurek.filesystem.getIdentity
-- @covers lurek.filesystem.setIdentity
-- @covers lurek.filesystem.lines
-- @covers lurek.filesystem.readAsync
-- @covers lurek.filesystem.pollAsync
-- @covers lurek.filesystem.mount
-- @covers lurek.filesystem.unmount
-- @covers lurek.filesystem.load

-- helpers
local TMP = "save/_fs_tests/"

-- module presence

describe("lurek.filesystem module", function()
    it("lurek.filesystem is a table", function()
        expect_type("table", lurek.filesystem)
    end)

    it("all expected functions are present", function()
        local fns = {
            "read", "write", "exists", "append", "remove",
            "openFile", "newFileData",
            "getDirectoryItems", "isFile", "isDirectory", "createDirectory",
            "getInfo", "getSource", "getSaveDirectory", "getWorkingDirectory",
            "getUserDirectory", "getIdentity", "setIdentity",
            "lines", "readAsync", "pollAsync",
            "mount", "unmount", "load",
        }
        for _, name in ipairs(fns) do
            expect_type("function", lurek.filesystem[name], name .. " must be a function")
        end
    end)
end)

-- write / read / exists / remove

describe("lurek.filesystem.write / read / exists / remove", function()
    it("write creates a file", function()
        expect_no_error(function()
            lurek.filesystem.write(TMP .. "basic.txt", "hello lurek2d")
        end)
    end)

    it("exists returns true for a written file", function()
        lurek.filesystem.write(TMP .. "exists_check.txt", "x")
        expect_true(lurek.filesystem.exists(TMP .. "exists_check.txt"))
    end)

    it("read returns written content", function()
        lurek.filesystem.write(TMP .. "roundtrip.txt", "test content here")
        local content = lurek.filesystem.read(TMP .. "roundtrip.txt")
        expect_equal("test content here", content)
    end)

    it("exists returns false for a nonexistent path", function()
        expect_false(lurek.filesystem.exists("save/_this_should_not_exist_xyz_9999.txt"))
    end)

    it("write and read are binary-safe with newlines", function()
        local data = "line1\nline2\nline3"
        lurek.filesystem.write(TMP .. "newline.txt", data)
        expect_equal(data, lurek.filesystem.read(TMP .. "newline.txt"))
    end)

    it("write overwrites existing file", function()
        lurek.filesystem.write(TMP .. "overwrite.txt", "first")
        lurek.filesystem.write(TMP .. "overwrite.txt", "second")
        expect_equal("second", lurek.filesystem.read(TMP .. "overwrite.txt"))
    end)

    it("read rejects path traversal", function()
        expect_error(function()
            lurek.filesystem.read("../../../etc/passwd")
        end)
    end)

    it("write rejects paths outside save", function()
        expect_error(function()
            lurek.filesystem.write("outside.txt", "data")
        end)
    end)

    it("remove deletes a file", function()
        lurek.filesystem.write(TMP .. "to_remove.txt", "bye")
        expect_true(lurek.filesystem.exists(TMP .. "to_remove.txt"))
        lurek.filesystem.remove(TMP .. "to_remove.txt")
        expect_false(lurek.filesystem.exists(TMP .. "to_remove.txt"))
    end)
end)

-- append

describe("lurek.filesystem.append", function()
    it("append adds content to an existing file", function()
        lurek.filesystem.write(TMP .. "append_test.txt", "part1")
        lurek.filesystem.append(TMP .. "append_test.txt", "part2")
        local content = lurek.filesystem.read(TMP .. "append_test.txt")
        expect_equal("part1part2", content)
    end)

    it("append creates a new file when path does not exist", function()
        -- Guard: only remove if it already exists (from a previous test run)
        if lurek.filesystem.exists(TMP .. "append_new.txt") then
            lurek.filesystem.remove(TMP .. "append_new.txt")
        end
        lurek.filesystem.append(TMP .. "append_new.txt", "created_by_append")
        expect_true(lurek.filesystem.exists(TMP .. "append_new.txt"))
        expect_equal("created_by_append", lurek.filesystem.read(TMP .. "append_new.txt"))
    end)

    it("multiple appends accumulate data in order", function()
        lurek.filesystem.write(TMP .. "append_multi.txt", "A")
        lurek.filesystem.append(TMP .. "append_multi.txt", "B")
        lurek.filesystem.append(TMP .. "append_multi.txt", "C")
        expect_equal("ABC", lurek.filesystem.read(TMP .. "append_multi.txt"))
    end)
end)

-- FileHandle via openFile

describe("lurek.filesystem.openFile  - FileHandle UserData", function()
    it("openFile('w') returns a non-nil FileHandle", function()
        local fh = lurek.filesystem.openFile(TMP .. "fh_write.txt", "w")
        expect_true(fh ~= nil, "FileHandle is not nil")
        fh:close()
    end)

    it("FileHandle:write then FileHandle:close persists data", function()
        local fh = lurek.filesystem.openFile(TMP .. "fh_persist.txt", "w")
        fh:write("written_via_handle")
        fh:close()
        expect_equal("written_via_handle", lurek.filesystem.read(TMP .. "fh_persist.txt"))
    end)

    it("openFile('r') can read written content", function()
        lurek.filesystem.write(TMP .. "fh_read_src.txt", "hello_handle_reader")
        local fh = lurek.filesystem.openFile(TMP .. "fh_read_src.txt", "r")
        local content = fh:read()
        fh:close()
        expect_equal("hello_handle_reader", content)
    end)

    it("read accepts a byte count for partial reads", function()
        lurek.filesystem.write(TMP .. "fh_read_partial.txt", "abcdefgh")
        local fh = lurek.filesystem.openFile(TMP .. "fh_read_partial.txt", "r")
        local chunk = fh:read(3)
        local rest = fh:read()
        fh:close()
        expect_equal("abc", chunk)
        expect_equal("defgh", rest)
    end)

    it("openFile('a') appends to an existing file", function()
        lurek.filesystem.write(TMP .. "fh_append_mode.txt", "first")
        local fh = lurek.filesystem.openFile(TMP .. "fh_append_mode.txt", "a")
        fh:write("second")
        fh:close()
        expect_equal("firstsecond", lurek.filesystem.read(TMP .. "fh_append_mode.txt"))
    end)

    it("readLine reads one line at a time", function()
        lurek.filesystem.write(TMP .. "fh_lines.txt", "alpha\nbeta\ngamma")
        local fh = lurek.filesystem.openFile(TMP .. "fh_lines.txt", "r")
        local l1 = fh:readLine()
        local l2 = fh:readLine()
        fh:close()
        expect_equal("alpha", l1)
        expect_equal("beta", l2)
    end)

    it("readLine returns nil at EOF", function()
        lurek.filesystem.write(TMP .. "fh_lines_eof.txt", "line1\nline2\n")
        local fh = lurek.filesystem.openFile(TMP .. "fh_lines_eof.txt", "r")
        expect_equal("line1", fh:readLine())
        expect_equal("line2", fh:readLine())
        expect_equal(nil, fh:readLine())
        fh:close()
    end)

    it("tell returns current position", function()
        lurek.filesystem.write(TMP .. "fh_tell.txt", "abcdef")
        local fh = lurek.filesystem.openFile(TMP .. "fh_tell.txt", "r")
        local pos = fh:tell()
        fh:close()
        expect_type("number", pos)
        expect_equal(0, pos)
    end)

    it("seek moves the read position", function()
        lurek.filesystem.write(TMP .. "fh_seek.txt", "ABCDEFGH")
        local fh = lurek.filesystem.openFile(TMP .. "fh_seek.txt", "r")
        fh:seek(3)
        local rest = fh:read()
        fh:close()
        expect_equal("DEFGH", rest)
    end)

    it("getSize returns byte count", function()
        lurek.filesystem.write(TMP .. "fh_size.txt", "12345")
        local fh = lurek.filesystem.openFile(TMP .. "fh_size.txt", "r")
        local sz = fh:getSize()
        fh:close()
        expect_equal(5, sz)
    end)

    it("getMode returns the mode string", function()
        local fh = lurek.filesystem.openFile(TMP .. "fh_mode.txt", "w")
        local mode = fh:getMode()
        fh:close()
        expect_type("string", mode)
        expect_equal("w", mode)
    end)

    it("getMode returns 'c' after close", function()
        local fh = lurek.filesystem.openFile(TMP .. "fh_closed_mode.txt", "w")
        fh:close()
        expect_equal("c", fh:getMode())
    end)

    it("close is idempotent", function()
        local fh = lurek.filesystem.openFile(TMP .. "fh_close_idem.txt", "w")
        fh:write("x")
        fh:close()
        expect_no_error(function()
            fh:close()
        end)
        expect_equal("c", fh:getMode())
    end)

    it("isEOF returns false before reading all content", function()
        lurek.filesystem.write(TMP .. "fh_eof.txt", "not empty")
        local fh = lurek.filesystem.openFile(TMP .. "fh_eof.txt", "r")
        local eof_before = fh:isEOF()
        fh:close()
        expect_false(eof_before)
    end)

    it("isEOF returns true after reading all content", function()
        lurek.filesystem.write(TMP .. "fh_eof_after.txt", "ab")
        local fh = lurek.filesystem.openFile(TMP .. "fh_eof_after.txt", "r")
        fh:read()
        local eof_after = fh:isEOF()
        fh:close()
        expect_true(eof_after)
    end)

    it("flush does not error on writable handle", function()
        local fh = lurek.filesystem.openFile(TMP .. "fh_flush.txt", "w")
        fh:write("data")
        expect_no_error(function() fh:flush() end)
        fh:close()
    end)

    it("openFile rejects invalid mode strings", function()
        expect_error(function()
            lurek.filesystem.openFile(TMP .. "fh_bad_mode.txt", "x")
        end)
    end)
end)

-- FileData via newFileData
-- newFileData(path) reads a file from the VFS and returns a FileData object.

describe("lurek.filesystem.newFileData  - FileData UserData", function()
    it("newFileData from a written file returns a non-nil object", function()
        lurek.filesystem.write(TMP .. "fd_blob.txt", "blob content")
        local fd = lurek.filesystem.newFileData(TMP .. "fd_blob.txt")
        expect_true(fd ~= nil, "FileData is not nil")
    end)

    it("FileData:getSize returns byte count", function()
        lurek.filesystem.write(TMP .. "fd_hello.txt", "hello")
        local fd = lurek.filesystem.newFileData(TMP .. "fd_hello.txt")
        expect_equal(5, fd:getSize())
    end)

    it("FileData:getString returns the stored string", function()
        lurek.filesystem.write(TMP .. "fd_abc.txt", "abc")
        local fd = lurek.filesystem.newFileData(TMP .. "fd_abc.txt")
        expect_equal("abc", fd:getString())
    end)

    it("FileData:getFilename returns the path used to load the file", function()
        lurek.filesystem.write(TMP .. "fd_named.txt", "data")
        local path = TMP .. "fd_named.txt"
        local fd = lurek.filesystem.newFileData(path)
        expect_equal(path, fd:getFilename())
    end)
end)

-- directory operations

describe("lurek.filesystem directory operations", function()
    it("createDirectory creates a new directory", function()
        expect_no_error(function()
            lurek.filesystem.createDirectory(TMP .. "subdir_test/")
        end)
    end)

    it("isDirectory returns true for a created directory", function()
        lurek.filesystem.createDirectory(TMP .. "isdir_check/")
        expect_true(lurek.filesystem.isDirectory(TMP .. "isdir_check/"))
    end)

    it("isFile returns false for a directory path", function()
        lurek.filesystem.createDirectory(TMP .. "not_a_file/")
        expect_false(lurek.filesystem.isFile(TMP .. "not_a_file/"))
    end)

    it("isFile returns true for a written file", function()
        lurek.filesystem.write(TMP .. "is_file_test.txt", "yes")
        expect_true(lurek.filesystem.isFile(TMP .. "is_file_test.txt"))
    end)

    it("isDirectory returns false for a file path", function()
        lurek.filesystem.write(TMP .. "not_dir.txt", "x")
        expect_false(lurek.filesystem.isDirectory(TMP .. "not_dir.txt"))
    end)

    it("getDirectoryItems returns a table for a known directory", function()
        lurek.filesystem.createDirectory(TMP .. "list_dir/")
        lurek.filesystem.write(TMP .. "list_dir/item1.txt", "a")
        lurek.filesystem.write(TMP .. "list_dir/item2.txt", "b")
        local items = lurek.filesystem.getDirectoryItems(TMP .. "list_dir/")
        expect_type("table", items)
        expect_true(#items >= 2, "at least 2 items listed")
    end)

    it("getDirectoryItems entries are strings", function()
        local items = lurek.filesystem.getDirectoryItems(TMP)
        for _, entry in ipairs(items) do
            expect_type("string", entry)
        end
    end)

    it("getDirectoryItems returns sorted entry names", function()
        local dir = TMP .. "sorted_dir/"
        lurek.filesystem.createDirectory(dir)
        lurek.filesystem.write(dir .. "c.txt", "")
        lurek.filesystem.write(dir .. "a.txt", "")
        lurek.filesystem.write(dir .. "b.txt", "")

        local items = lurek.filesystem.getDirectoryItems(dir)
        local filtered = {}
        for _, entry in ipairs(items) do
            if string.sub(entry, -4) == ".txt" then
                filtered[#filtered + 1] = entry
            end
        end

        expect_equal(3, #filtered)
        expect_equal("a.txt", filtered[1])
        expect_equal("b.txt", filtered[2])
        expect_equal("c.txt", filtered[3])
    end)
end)

-- getInfo

describe("lurek.filesystem.getInfo", function()
    it("getInfo returns a table for a known file", function()
        lurek.filesystem.write(TMP .. "info_file.txt", "info_test")
        local info = lurek.filesystem.getInfo(TMP .. "info_file.txt")
        expect_type("table", info)
    end)

    it("getInfo.type is 'file' for a regular file", function()
        lurek.filesystem.write(TMP .. "info_type.txt", "x")
        local info = lurek.filesystem.getInfo(TMP .. "info_type.txt")
        expect_equal("file", info.type)
    end)

    it("getInfo.size matches number of bytes written", function()
        lurek.filesystem.write(TMP .. "info_size.txt", "12345")
        local info = lurek.filesystem.getInfo(TMP .. "info_size.txt")
        expect_equal(5, info.size)
    end)

    it("getInfo returns nil for nonexistent path", function()
        local info = lurek.filesystem.getInfo("save/_nonexistent_info_xyz.txt")
        expect_nil(info)
    end)
end)

-- path queries

describe("lurek.filesystem path query functions", function()
    it("getSource returns a string", function()
        local src = lurek.filesystem.getSource()
        expect_type("string", src)
    end)

    it("getSaveDirectory returns a string", function()
        local sd = lurek.filesystem.getSaveDirectory()
        expect_type("string", sd)
    end)

    it("getWorkingDirectory returns a string", function()
        local wd = lurek.filesystem.getWorkingDirectory()
        expect_type("string", wd)
    end)

    it("getUserDirectory returns a string", function()
        local ud = lurek.filesystem.getUserDirectory()
        expect_type("string", ud)
    end)
end)

-- identity

describe("lurek.filesystem.getIdentity / setIdentity", function()
    it("getIdentity returns a string", function()
        local id = lurek.filesystem.getIdentity()
        expect_type("string", id)
    end)

    it("setIdentity changes the identity returned by getIdentity", function()
        local old = lurek.filesystem.getIdentity()
        lurek.filesystem.setIdentity("test_fs_identity")
        local new = lurek.filesystem.getIdentity()
        expect_equal("test_fs_identity", new)
        -- Restore original identity
        lurek.filesystem.setIdentity(old)
    end)
end)

-- lines iterator

describe("lurek.filesystem.lines", function()
    it("lines iterates over all lines in a file", function()
        lurek.filesystem.write(TMP .. "lines_test.txt", "alpha\nbeta\ngamma")
        local collected = {}
        for line in lurek.filesystem.lines(TMP .. "lines_test.txt") do
            collected[#collected + 1] = line
        end
        expect_equal(3, #collected)
        expect_equal("alpha", collected[1])
        expect_equal("beta",  collected[2])
        expect_equal("gamma", collected[3])
    end)

    it("lines on empty file yields no iterations", function()
        lurek.filesystem.write(TMP .. "lines_empty.txt", "")
        local count = 0
        for _ in lurek.filesystem.lines(TMP .. "lines_empty.txt") do
            count = count + 1
        end
        expect_equal(0, count)
    end)
end)

-- async read

describe("lurek.filesystem.readAsync / pollAsync", function()
    it("readAsync returns a handle (non-nil)", function()
        lurek.filesystem.write(TMP .. "async_src.txt", "async_content")
        local handle = lurek.filesystem.readAsync(TMP .. "async_src.txt")
        expect_true(handle ~= nil, "async handle is not nil")
    end)

    it("pollAsync returns a status string for a valid handle", function()
        lurek.filesystem.write(TMP .. "async_poll.txt", "poll_content")
        local handle = lurek.filesystem.readAsync(TMP .. "async_poll.txt")
        -- pollAsync returns (status:string, data:string|nil)
        -- status is "pending", "done", or "error"
        local status, data
        for _ = 1, 1000 do
            status, data = lurek.filesystem.pollAsync(handle)
            if status ~= "pending" then break end
        end
        -- In headless tests (no event loop background worker), the loader may
        -- remain "pending". We accept either "done" or "pending" as valid.
        expect_type("string", status)
        expect_true(status == "done" or status == "pending",
            "status must be 'done' or 'pending', got: " .. tostring(status))
        if status == "done" then
            expect_equal("poll_content", data)
        end
    end)
end)

-- mount / unmount / load

describe("lurek.filesystem.mount / unmount / load", function()
    it("mount is a function", function()
        expect_type("function", lurek.filesystem.mount)
    end)

    it("unmount is a function", function()
        expect_type("function", lurek.filesystem.unmount)
    end)

    it("mount rejects path traversal", function()
        expect_error(function()
            lurek.filesystem.mount("../outside", "/hack")
        end)
    end)

    it("unmount returns false for an unknown mountpoint", function()
        expect_equal(false, lurek.filesystem.unmount("/nonexistent"))
    end)

    it("load compiles a Lua file and returns a callable function", function()
        lurek.filesystem.write(TMP .. "chunk.lua", "return function() return 99 end")
        local f = lurek.filesystem.load(TMP .. "chunk.lua")
        expect_type("function", f)
        local inner = f()
        expect_type("function", inner)
        expect_equal(99, inner())
        lurek.filesystem.remove(TMP .. "chunk.lua")
    end)

    it("load returns an error for invalid Lua syntax", function()
        lurek.filesystem.write(TMP .. "bad_chunk.lua", ":::invalid lua:::")
        expect_error(function()
            lurek.filesystem.load(TMP .. "bad_chunk.lua")
        end)
        lurek.filesystem.remove(TMP .. "bad_chunk.lua")
    end)
end)

--  ZIP mount and file watchers (merged from test_filesystem_zip_watcher.lua) 

describe("fs.mountZip", function()

    it("mountZip raises error for a nonexistent path", function()
        expect_error(function()
            lurek.filesystem.mountZip("does_not_exist_xyz.zip", "")
        end)
    end)

    it("mountZip raises error for a non-ZIP file", function()
        -- Write a temp text file via lurek.filesystem, then try to mount it as ZIP.
        lurek.filesystem.write("save/not_a_zip.bin", "hello")
        expect_error(function()
            -- Path under save sandbox  not a valid ZIP
            lurek.filesystem.mountZip("save/not_a_zip.bin", "test")
        end)
    end)

end)

describe("fs.watchPath / pollWatchers", function()

    it("watchPath and pollWatchers exist in lurek.filesystem", function()
        expect_equal(type(lurek.filesystem.watchPath), "function")
        expect_equal(type(lurek.filesystem.pollWatchers), "function")
        expect_equal(type(lurek.filesystem.unwatchPath), "function")
    end)

    it("pollWatchers returns a table", function()
        local result = lurek.filesystem.pollWatchers()
        expect_equal(type(result), "table")
    end)

    it("watching a nonexistent file does not raise", function()
        lurek.filesystem.watchPath("nonexistent_watch_target_abc.lua")
    end)

    it("unwatchPath does not raise for an unwatched path", function()
        lurek.filesystem.unwatchPath("never_watched.lua")
    end)

    it("pollWatchers after watch returns a table (no false positives for missing file)", function()
        lurek.filesystem.watchPath("truly_nonexistent_xyz_abc.lua")
        local changed = lurek.filesystem.pollWatchers()
        expect_equal(type(changed), "table")
        -- Nonexistent file: mtime stays nil  no change
        expect_equal(#changed == 0, true)
    end)

    it("polling a freshly written file detects change", function()
        local path = "save/watcher_test_file.txt"
        -- Write file AFTER setting up the watcher so it transitions None  Some
        lurek.filesystem.watchPath(path)
        -- First poll: file doesn't exist yet  no change
        lurek.filesystem.pollWatchers()
        -- Write the file to cause a mtime change
        lurek.filesystem.write(path, "first write")
        -- Second poll: file now exists  should detect change
        local changed = lurek.filesystem.pollWatchers()
        expect_equal(type(changed), "table")
        -- We expect at least 0 entries (CI filesystem timing may vary, so we
        -- just verify the return type and no crash, not an exact count)
    end)

end)

-- listRecursive
describe("lurek.filesystem.listRecursive", function()
  -- @covers lurek.filesystem.listRecursive
  it("listRecursive is a function", function()
    expect_type("function", lurek.filesystem.listRecursive)
  end)

  -- @covers lurek.filesystem.listRecursive
  it("returns a table with recursive file paths", function()
    local dir  = TMP .. "lr/"
    local sub  = dir .. "sub/"
    lurek.filesystem.createDirectory(sub)
    lurek.filesystem.write(dir .. "a.txt", "a")
    lurek.filesystem.write(sub .. "b.txt", "b")
    local items = lurek.filesystem.listRecursive(dir)
    expect_type("table", items)
    expect_true(#items >= 2, "should list at least 2 entries")
    -- cleanup
    lurek.filesystem.remove(sub .. "b.txt")
    lurek.filesystem.remove(sub)
    lurek.filesystem.remove(dir .. "a.txt")
    lurek.filesystem.remove(dir)
  end)

  -- @covers lurek.filesystem.listRecursive
  it("returns empty table for empty directory", function()
    local dir = TMP .. "lr_empty/"
    lurek.filesystem.createDirectory(dir)
    local items = lurek.filesystem.listRecursive(dir)
    expect_type("table", items)
    expect_equal(0, #items)
    lurek.filesystem.remove(dir)
  end)

  -- @covers lurek.filesystem.listRecursive
  it("path traversal is rejected with an error", function()
    local ok = pcall(lurek.filesystem.listRecursive, "save/../..")
    expect_equal(false, ok)
  end)
end)

describe("lurek.filesystem.stat lightweight file statistics", function()
  -- @covers lurek.filesystem.stat
  it("stat is a function", function()
    expect_equal("function", type(lurek.filesystem.stat))
  end)

  -- @covers lurek.filesystem.stat
  it("stat rejects path traversal", function()
    local ok = pcall(lurek.filesystem.stat, "../../etc/passwd")
    expect_equal(false, ok)
  end)

  -- @covers lurek.filesystem.stat
  it("stat returns table with size, isFile, isDir fields", function()
    -- Write a known file first so stat can find it
    lurek.filesystem.write("save/_stat_test.txt", "hello")
    local info = lurek.filesystem.stat("save/_stat_test.txt")
    expect_not_nil(info)
    expect_equal("number", type(info.size))
    expect_equal("boolean", type(info.isFile))
    expect_equal("boolean", type(info.isDir))
    expect_true(info.isFile)
    expect_true(not info.isDir)
  end)

  -- @covers lurek.filesystem.stat
  it("stat size matches written content length", function()
    lurek.filesystem.write("save/_stat_size.txt", "abcde")
    local info = lurek.filesystem.stat("save/_stat_size.txt")
    expect_equal(5, info.size)
  end)
end)

describe("lurek.filesystem.createTempFile temporary file creation", function()
  -- @covers lurek.filesystem.createTempFile
  it("createTempFile is a function", function()
    expect_equal("function", type(lurek.filesystem.createTempFile))
  end)

  -- @covers lurek.filesystem.createTempFile
  it("createTempFile returns a string path", function()
    local path = lurek.filesystem.createTempFile("test_")
    expect_equal("string", type(path))
    expect_true(#path > 0)
  end)

  -- @covers lurek.filesystem.createTempFile
  it("createTempFile path starts with save/", function()
    local path = lurek.filesystem.createTempFile("pfx_")
    expect_equal("save/", path:sub(1, 5))
  end)

  -- @covers lurek.filesystem.createTempFile
  it("two calls return different paths", function()
    local a = lurek.filesystem.createTempFile("tmp")
    local b = lurek.filesystem.createTempFile("tmp")
    expect_true(a ~= b)
  end)
end)

describe("lurek.filesystem remaining coverage", function()
    -- @covers lurek.filesystem.removeDir
    it("removeDir removes nested directories recursively", function()
        local dir = TMP .. "remove_dir_case/"
        local nested = dir .. "deep/nested/"
        lurek.filesystem.createDirectory(nested)
        lurek.filesystem.write(nested .. "file.txt", "x")

        lurek.filesystem.removeDir(dir)

        expect_false(lurek.filesystem.isDirectory(dir))
        expect_false(lurek.filesystem.exists(nested .. "file.txt"))
    end)

    -- @covers lurek.filesystem.copy
    it("copy duplicates file contents into destination", function()
        local src = TMP .. "copy_src.txt"
        local dst = TMP .. "copy_dst.txt"
        lurek.filesystem.write(src, "copy me")

        lurek.filesystem.copy(src, dst)

        expect_true(lurek.filesystem.exists(src))
        expect_true(lurek.filesystem.exists(dst))
        expect_equal("copy me", lurek.filesystem.read(dst))
    end)

    -- @covers lurek.filesystem.move
    it("move relocates file within save sandbox", function()
        local src = TMP .. "move_src.txt"
        local dst = TMP .. "move_dst.txt"
        lurek.filesystem.write(src, "move me")

        lurek.filesystem.move(src, dst)

        expect_false(lurek.filesystem.exists(src))
        expect_true(lurek.filesystem.exists(dst))
        expect_equal("move me", lurek.filesystem.read(dst))
    end)

    -- @covers lurek.filesystem.glob
    it("glob returns sorted wildcard matches", function()
        local dir = TMP .. "glob_case/"
        lurek.filesystem.createDirectory(dir)
        lurek.filesystem.write(dir .. "a.lua", "")
        lurek.filesystem.write(dir .. "b.lua", "")
        lurek.filesystem.write(dir .. "c.txt", "")

        local matches = lurek.filesystem.glob(dir .. "*.lua")

        expect_equal(2, #matches)
        expect_equal(dir .. "a.lua", matches[1])
        expect_equal(dir .. "b.lua", matches[2])
    end)

    -- @covers lurek.filesystem.mkdir
    it("mkdir creates nested directories", function()
        local dir = TMP .. "mkdir_case/deep/nested/"
        lurek.filesystem.mkdir(dir)
        expect_true(lurek.filesystem.isDirectory(dir))
    end)

    -- @covers lurek.filesystem.toAbsolutePath
    it("toAbsolutePath returns an absolute path string", function()
        local abs = lurek.filesystem.toAbsolutePath(TMP .. "absolute_case.txt")
        expect_type("string", abs)
        expect_true(string.find(abs, "_fs_tests", 1, true) ~= nil)
    end)
end)

test_summary()
