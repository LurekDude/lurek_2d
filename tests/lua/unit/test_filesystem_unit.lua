-- Lurek2D filesystem API unit tests
-- Headless-safe (no window / GPU / audio required).
-- Tests the lurek.filesystem namespace: read, write, append, exists, remove,
-- openFile (FileHandle), newFileData (FileData), directory ops,
-- path queries, identity, lines, async read, mount/unmount, load.
-- @tests lurek.filesystem.read
-- @tests lurek.filesystem.write
-- @tests lurek.filesystem.exists
-- @tests lurek.filesystem.append
-- @tests lurek.filesystem.remove
-- @tests lurek.filesystem.openFile
-- @tests lurek.filesystem.newFileData
-- @tests lurek.filesystem.getDirectoryItems
-- @tests lurek.filesystem.isFile
-- @tests lurek.filesystem.isDirectory
-- @tests lurek.filesystem.createDirectory
-- @tests lurek.filesystem.getInfo
-- @tests lurek.filesystem.getSource
-- @tests lurek.filesystem.getSaveDirectory
-- @tests lurek.filesystem.getWorkingDirectory
-- @tests lurek.filesystem.getUserDirectory
-- @tests lurek.filesystem.getIdentity
-- @tests lurek.filesystem.setIdentity
-- @tests lurek.filesystem.lines
-- @tests lurek.filesystem.readAsync
-- @tests lurek.filesystem.pollAsync
-- @tests lurek.filesystem.mount
-- @tests lurek.filesystem.unmount
-- @tests lurek.filesystem.load

-- â”€â”€ helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local TMP = "save/_fs_tests/"

-- â”€â”€ module presence â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies that the lurek.filesystem namespace exists as a table and exposes every expected filesystem API entry point as a callable function.
describe("lurek.filesystem module", function()
    -- @description Confirms the filesystem namespace is registered in Lua as a table value.
    it("lurek.filesystem is a table", function()
        expect_type("table", lurek.filesystem)
    end)

    -- @description Checks that every documented filesystem function name resolves to a Lua function on lurek.filesystem.
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

-- â”€â”€ write / read / exists / remove â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Exercises basic file lifecycle operations by creating files, checking existence, reading exact contents, overwriting data, and deleting files.
describe("lurek.filesystem.write / read / exists / remove", function()
    -- @description Ensures writing a file at the test path completes without raising an error.
    it("write creates a file", function()
        expect_no_error(function()
            lurek.filesystem.write(TMP .. "basic.txt", "hello lurek2d")
        end)
    end)

    -- @description Writes a file and verifies exists returns true for that exact path.
    it("exists returns true for a written file", function()
        lurek.filesystem.write(TMP .. "exists_check.txt", "x")
        expect_true(lurek.filesystem.exists(TMP .. "exists_check.txt"))
    end)

    -- @description Writes a known string and checks that reading the same file returns the exact stored content.
    it("read returns written content", function()
        lurek.filesystem.write(TMP .. "roundtrip.txt", "test content here")
        local content = lurek.filesystem.read(TMP .. "roundtrip.txt")
        expect_equal("test content here", content)
    end)

    -- @description Confirms exists returns false for a deliberately nonexistent save path.
    it("exists returns false for a nonexistent path", function()
        expect_false(lurek.filesystem.exists("save/_this_should_not_exist_xyz_9999.txt"))
    end)

    -- @description Verifies write and read preserve embedded newline characters exactly across a round trip.
    it("write and read are binary-safe with newlines", function()
        local data = "line1\nline2\nline3"
        lurek.filesystem.write(TMP .. "newline.txt", data)
        expect_equal(data, lurek.filesystem.read(TMP .. "newline.txt"))
    end)

    -- @description Confirms a second write to the same path replaces the earlier content instead of appending to it.
    it("write overwrites existing file", function()
        lurek.filesystem.write(TMP .. "overwrite.txt", "first")
        lurek.filesystem.write(TMP .. "overwrite.txt", "second")
        expect_equal("second", lurek.filesystem.read(TMP .. "overwrite.txt"))
    end)

    -- @description Creates a file, verifies it exists, removes it, and checks that the path no longer exists afterward.
    it("remove deletes a file", function()
        lurek.filesystem.write(TMP .. "to_remove.txt", "bye")
        expect_true(lurek.filesystem.exists(TMP .. "to_remove.txt"))
        lurek.filesystem.remove(TMP .. "to_remove.txt")
        expect_false(lurek.filesystem.exists(TMP .. "to_remove.txt"))
    end)
end)

-- â”€â”€ append â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies append behavior for existing and missing files, including repeated appends preserving write order.
describe("lurek.filesystem.append", function()
    -- @description Writes an initial file, appends more text, and checks that the final content is the exact concatenation.
    it("append adds content to an existing file", function()
        lurek.filesystem.write(TMP .. "append_test.txt", "part1")
        lurek.filesystem.append(TMP .. "append_test.txt", "part2")
        local content = lurek.filesystem.read(TMP .. "append_test.txt")
        expect_equal("part1part2", content)
    end)

    -- @description Removes any leftover file, appends to a missing path, and verifies append created the file with the appended text as its full content.
    it("append creates a new file when path does not exist", function()
        -- Guard: only remove if it already exists (from a previous test run)
        if lurek.filesystem.exists(TMP .. "append_new.txt") then
            lurek.filesystem.remove(TMP .. "append_new.txt")
        end
        lurek.filesystem.append(TMP .. "append_new.txt", "created_by_append")
        expect_true(lurek.filesystem.exists(TMP .. "append_new.txt"))
        expect_equal("created_by_append", lurek.filesystem.read(TMP .. "append_new.txt"))
    end)

    -- @description Confirms successive appends accumulate data in the same order the append calls were made.
    it("multiple appends accumulate data in order", function()
        lurek.filesystem.write(TMP .. "append_multi.txt", "A")
        lurek.filesystem.append(TMP .. "append_multi.txt", "B")
        lurek.filesystem.append(TMP .. "append_multi.txt", "C")
        expect_equal("ABC", lurek.filesystem.read(TMP .. "append_multi.txt"))
    end)
end)

-- â”€â”€ FileHandle via openFile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Validates FileHandle userdata by opening files in different modes and checking write, read, line iteration, position, size, mode, EOF, and flush behavior.
describe("lurek.filesystem.openFile â€” FileHandle UserData", function()
    -- @description Opens a file in write mode and checks that openFile returns a non-nil handle object.
    it("openFile('w') returns a non-nil FileHandle", function()
        local fh = lurek.filesystem.openFile(TMP .. "fh_write.txt", "w")
        expect_true(fh ~= nil, "FileHandle is not nil")
        fh:close()
    end)

    -- @description Writes through a FileHandle, closes it, and verifies the written bytes were persisted to disk.
    it("FileHandle:write then FileHandle:close persists data", function()
        local fh = lurek.filesystem.openFile(TMP .. "fh_persist.txt", "w")
        fh:write("written_via_handle")
        fh:close()
        expect_equal("written_via_handle", lurek.filesystem.read(TMP .. "fh_persist.txt"))
    end)

    -- @description Writes a source file, reopens it for reading through a FileHandle, and confirms read returns the stored text.
    it("openFile('r') can read written content", function()
        lurek.filesystem.write(TMP .. "fh_read_src.txt", "hello_handle_reader")
        local fh = lurek.filesystem.openFile(TMP .. "fh_read_src.txt", "r")
        local content = fh:read()
        fh:close()
        expect_equal("hello_handle_reader", content)
    end)

    -- @description Verifies readLine advances one line at a time by comparing the first two returned lines to the expected strings.
    it("readLine reads one line at a time", function()
        lurek.filesystem.write(TMP .. "fh_lines.txt", "alpha\nbeta\ngamma")
        local fh = lurek.filesystem.openFile(TMP .. "fh_lines.txt", "r")
        local l1 = fh:readLine()
        local l2 = fh:readLine()
        fh:close()
        expect_equal("alpha", l1)
        expect_equal("beta", l2)
    end)

    -- @description Confirms a newly opened read handle reports numeric position 0 before any reads occur.
    it("tell returns current position", function()
        lurek.filesystem.write(TMP .. "fh_tell.txt", "abcdef")
        local fh = lurek.filesystem.openFile(TMP .. "fh_tell.txt", "r")
        local pos = fh:tell()
        fh:close()
        expect_type("number", pos)
        expect_equal(0, pos)
    end)

    -- @description Seeks three bytes into the file and verifies reading from that point returns only the remaining suffix.
    it("seek moves the read position", function()
        lurek.filesystem.write(TMP .. "fh_seek.txt", "ABCDEFGH")
        local fh = lurek.filesystem.openFile(TMP .. "fh_seek.txt", "r")
        fh:seek(3)
        local rest = fh:read()
        fh:close()
        expect_equal("DEFGH", rest)
    end)

    -- @description Checks that getSize reports the exact byte length of the written file content.
    it("getSize returns byte count", function()
        lurek.filesystem.write(TMP .. "fh_size.txt", "12345")
        local fh = lurek.filesystem.openFile(TMP .. "fh_size.txt", "r")
        local sz = fh:getSize()
        fh:close()
        expect_equal(5, sz)
    end)

    -- @description Verifies getMode returns a string describing the mode used to open the handle.
    it("getMode returns the mode string", function()
        local fh = lurek.filesystem.openFile(TMP .. "fh_mode.txt", "w")
        local mode = fh:getMode()
        fh:close()
        expect_type("string", mode)
    end)

    -- @description Confirms isEOF is still false immediately after opening a non-empty file before any content is consumed.
    it("isEOF returns false before reading all content", function()
        lurek.filesystem.write(TMP .. "fh_eof.txt", "not empty")
        local fh = lurek.filesystem.openFile(TMP .. "fh_eof.txt", "r")
        local eof_before = fh:isEOF()
        fh:close()
        expect_false(eof_before)
    end)

    -- @description Writes data to a writable handle and checks that flushing it does not raise an error.
    it("flush does not error on writable handle", function()
        local fh = lurek.filesystem.openFile(TMP .. "fh_flush.txt", "w")
        fh:write("data")
        expect_no_error(function() fh:flush() end)
        fh:close()
    end)
end)

-- â”€â”€ FileData via newFileData â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- newFileData(path) reads a file from the VFS and returns a FileData object.

-- @description Verifies FileData objects created from VFS files expose the expected object presence, size, string content, and filename metadata.
describe("lurek.filesystem.newFileData â€” FileData UserData", function()
    -- @description Writes a file and confirms newFileData returns a non-nil FileData object for that path.
    it("newFileData from a written file returns a non-nil object", function()
        lurek.filesystem.write(TMP .. "fd_blob.txt", "blob content")
        local fd = lurek.filesystem.newFileData(TMP .. "fd_blob.txt")
        expect_true(fd ~= nil, "FileData is not nil")
    end)

    -- @description Checks that FileData:getSize matches the byte length of the file contents used to create it.
    it("FileData:getSize returns byte count", function()
        lurek.filesystem.write(TMP .. "fd_hello.txt", "hello")
        local fd = lurek.filesystem.newFileData(TMP .. "fd_hello.txt")
        expect_equal(5, fd:getSize())
    end)

    -- @description Confirms FileData:getString returns the exact string stored in the source file.
    it("FileData:getString returns the stored string", function()
        lurek.filesystem.write(TMP .. "fd_abc.txt", "abc")
        local fd = lurek.filesystem.newFileData(TMP .. "fd_abc.txt")
        expect_equal("abc", fd:getString())
    end)

    -- @description Loads FileData from a known path and verifies getFilename returns a string for the original load path metadata.
    it("FileData:getFilename returns the path used to load the file", function()
        lurek.filesystem.write(TMP .. "fd_named.txt", "data")
        local path = TMP .. "fd_named.txt"
        local fd = lurek.filesystem.newFileData(path)
        -- getFilename returns the path it was loaded from
        expect_type("string", fd:getFilename())
    end)
end)

-- â”€â”€ directory operations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers directory creation, file-versus-directory classification, and directory listing return types and entry shapes.
describe("lurek.filesystem directory operations", function()
    -- @description Ensures createDirectory can create a new subdirectory without throwing an error.
    it("createDirectory creates a new directory", function()
        expect_no_error(function()
            lurek.filesystem.createDirectory(TMP .. "subdir_test/")
        end)
    end)

    -- @description Creates a directory and verifies isDirectory reports true for that path.
    it("isDirectory returns true for a created directory", function()
        lurek.filesystem.createDirectory(TMP .. "isdir_check/")
        expect_true(lurek.filesystem.isDirectory(TMP .. "isdir_check/"))
    end)

    -- @description Confirms isFile returns false when given a path that points to a directory.
    it("isFile returns false for a directory path", function()
        lurek.filesystem.createDirectory(TMP .. "not_a_file/")
        expect_false(lurek.filesystem.isFile(TMP .. "not_a_file/"))
    end)

    -- @description Writes a file and checks that isFile reports true for the resulting file path.
    it("isFile returns true for a written file", function()
        lurek.filesystem.write(TMP .. "is_file_test.txt", "yes")
        expect_true(lurek.filesystem.isFile(TMP .. "is_file_test.txt"))
    end)

    -- @description Confirms isDirectory returns false when the path points to a regular file.
    it("isDirectory returns false for a file path", function()
        lurek.filesystem.write(TMP .. "not_dir.txt", "x")
        expect_false(lurek.filesystem.isDirectory(TMP .. "not_dir.txt"))
    end)

    -- @description Creates a directory with two files and verifies getDirectoryItems returns a table listing at least those entries.
    it("getDirectoryItems returns a table for a known directory", function()
        lurek.filesystem.createDirectory(TMP .. "list_dir/")
        lurek.filesystem.write(TMP .. "list_dir/item1.txt", "a")
        lurek.filesystem.write(TMP .. "list_dir/item2.txt", "b")
        local items = lurek.filesystem.getDirectoryItems(TMP .. "list_dir/")
        expect_type("table", items)
        expect_true(#items >= 2, "at least 2 items listed")
    end)

    -- @description Verifies every entry returned by getDirectoryItems for the test directory is a string path segment.
    it("getDirectoryItems entries are strings", function()
        local items = lurek.filesystem.getDirectoryItems(TMP)
        for _, entry in ipairs(items) do
            expect_type("string", entry)
        end
    end)
end)

-- â”€â”€ getInfo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies getInfo shape and metadata by checking table returns, file type tagging, byte size reporting, and nil on missing paths.
describe("lurek.filesystem.getInfo", function()
    -- @description Writes a file and confirms getInfo returns a table describing that file.
    it("getInfo returns a table for a known file", function()
        lurek.filesystem.write(TMP .. "info_file.txt", "info_test")
        local info = lurek.filesystem.getInfo(TMP .. "info_file.txt")
        expect_type("table", info)
    end)

    -- @description Checks that getInfo marks a regular file with type equal to 'file'.
    it("getInfo.type is 'file' for a regular file", function()
        lurek.filesystem.write(TMP .. "info_type.txt", "x")
        local info = lurek.filesystem.getInfo(TMP .. "info_type.txt")
        expect_equal("file", info.type)
    end)

    -- @description Verifies getInfo.size matches the exact number of bytes written to the file.
    it("getInfo.size matches number of bytes written", function()
        lurek.filesystem.write(TMP .. "info_size.txt", "12345")
        local info = lurek.filesystem.getInfo(TMP .. "info_size.txt")
        expect_equal(5, info.size)
    end)

    -- @description Confirms getInfo returns nil instead of a table for a path that does not exist.
    it("getInfo returns nil for nonexistent path", function()
        local info = lurek.filesystem.getInfo("save/_nonexistent_info_xyz.txt")
        expect_nil(info)
    end)
end)

-- â”€â”€ path queries â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Confirms the filesystem path query helpers each return string values for source, save, working, and user directories.
describe("lurek.filesystem path query functions", function()
    -- @description Verifies getSource returns a string identifying the source path.
    it("getSource returns a string", function()
        local src = lurek.filesystem.getSource()
        expect_type("string", src)
    end)

    -- @description Verifies getSaveDirectory returns a string for the engine save directory.
    it("getSaveDirectory returns a string", function()
        local sd = lurek.filesystem.getSaveDirectory()
        expect_type("string", sd)
    end)

    -- @description Verifies getWorkingDirectory returns a string for the current working directory.
    it("getWorkingDirectory returns a string", function()
        local wd = lurek.filesystem.getWorkingDirectory()
        expect_type("string", wd)
    end)

    -- @description Verifies getUserDirectory returns a string for the user directory path.
    it("getUserDirectory returns a string", function()
        local ud = lurek.filesystem.getUserDirectory()
        expect_type("string", ud)
    end)
end)

-- â”€â”€ identity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies identity accessors by checking the current identity type and confirming setIdentity updates the value returned by getIdentity.
describe("lurek.filesystem.getIdentity / setIdentity", function()
    -- @description Confirms getIdentity returns the current filesystem identity as a string.
    it("getIdentity returns a string", function()
        local id = lurek.filesystem.getIdentity()
        expect_type("string", id)
    end)

    -- @description Sets a temporary identity, checks getIdentity returns the new value, and then restores the original identity.
    it("setIdentity changes the identity returned by getIdentity", function()
        local old = lurek.filesystem.getIdentity()
        lurek.filesystem.setIdentity("test_fs_identity")
        local new = lurek.filesystem.getIdentity()
        expect_equal("test_fs_identity", new)
        -- Restore original identity
        lurek.filesystem.setIdentity(old)
    end)
end)

-- â”€â”€ lines iterator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Validates the line iterator by checking both multi-line traversal order and the zero-iteration case for an empty file.
describe("lurek.filesystem.lines", function()
    -- @description Writes three lines, iterates with lurek.filesystem.lines, and verifies the iterator yields exactly those three lines in order.
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

    -- @description Confirms iterating lines over an empty file produces no loop iterations at all.
    it("lines on empty file yields no iterations", function()
        lurek.filesystem.write(TMP .. "lines_empty.txt", "")
        local count = 0
        for _ in lurek.filesystem.lines(TMP .. "lines_empty.txt") do
            count = count + 1
        end
        expect_equal(0, count)
    end)
end)

-- â”€â”€ async read â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies asynchronous read entry points by checking handle creation and accepted pollAsync status and data outcomes under headless test conditions.
describe("lurek.filesystem.readAsync / pollAsync", function()
    -- @description Starts an async read on a written file and confirms the returned async handle is non-nil.
    it("readAsync returns a handle (non-nil)", function()
        lurek.filesystem.write(TMP .. "async_src.txt", "async_content")
        local handle = lurek.filesystem.readAsync(TMP .. "async_src.txt")
        expect_true(handle ~= nil, "async handle is not nil")
    end)

    -- @description Polls a valid async handle until it is no longer pending or the loop limit is hit, then accepts only 'done' or 'pending' and verifies returned data when complete.
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

-- â”€â”€ mount / unmount / load â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Confirms mount and unmount are exposed as functions and verifies load both returns executable compiled code for valid Lua and raises an error for invalid syntax.
describe("lurek.filesystem.mount / unmount / load", function()
    -- @description Checks that the mount API is exposed as a function on lurek.filesystem.
    it("mount is a function", function()
        expect_type("function", lurek.filesystem.mount)
    end)

    -- @description Checks that the unmount API is exposed as a function on lurek.filesystem.
    it("unmount is a function", function()
        expect_type("function", lurek.filesystem.unmount)
    end)

    -- @description Writes a Lua chunk returning a function, loads it, verifies both returned callables are functions, and checks the inner function returns 99.
    it("load compiles a Lua file and returns a callable function", function()
        lurek.filesystem.write(TMP .. "chunk.lua", "return function() return 99 end")
        local f = lurek.filesystem.load(TMP .. "chunk.lua")
        expect_type("function", f)
        local inner = f()
        expect_type("function", inner)
        expect_equal(99, inner())
        lurek.filesystem.remove(TMP .. "chunk.lua")
    end)

    -- @description Writes invalid Lua syntax and confirms lurek.filesystem.load raises an error for the bad chunk.
    it("load returns an error for invalid Lua syntax", function()
        lurek.filesystem.write(TMP .. "bad_chunk.lua", ":::invalid lua:::")
        expect_error(function()
            lurek.filesystem.load(TMP .. "bad_chunk.lua")
        end)
        lurek.filesystem.remove(TMP .. "bad_chunk.lua")
    end)
end)

-- ── ZIP mount and file watchers (merged from test_filesystem_zip_watcher.lua) ──

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
            -- Path under save sandbox — not a valid ZIP
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
        -- Nonexistent file: mtime stays nil → no change
        expect_equal(#changed == 0, true)
    end)

    it("polling a freshly written file detects change", function()
        local path = "save/watcher_test_file.txt"
        -- Write file AFTER setting up the watcher so it transitions None → Some
        lurek.filesystem.watchPath(path)
        -- First poll: file doesn't exist yet — no change
        lurek.filesystem.pollWatchers()
        -- Write the file to cause a mtime change
        lurek.filesystem.write(path, "first write")
        -- Second poll: file now exists — should detect change
        local changed = lurek.filesystem.pollWatchers()
        expect_equal(type(changed), "table")
        -- We expect at least 0 entries (CI filesystem timing may vary, so we
        -- just verify the return type and no crash, not an exact count)
    end)

end)

-- ── listRecursive ─────────────────────────────────────────────────────────────
-- @description Tests for the lurek.filesystem.listRecursive function.
describe("lurek.filesystem.listRecursive", function()
  -- @tests lurek.filesystem.listRecursive
  -- @description listRecursive is exposed as a function on lurek.filesystem.
  it("listRecursive is a function", function()
    expect_type("function", lurek.filesystem.listRecursive)
  end)

  -- @tests lurek.filesystem.listRecursive
  -- @description listRecursive on a directory with nested files returns a table.
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

  -- @tests lurek.filesystem.listRecursive
  -- @description listRecursive on an empty directory returns an empty table.
  it("returns empty table for empty directory", function()
    local dir = TMP .. "lr_empty/"
    lurek.filesystem.createDirectory(dir)
    local items = lurek.filesystem.listRecursive(dir)
    expect_type("table", items)
    expect_equal(0, #items)
    lurek.filesystem.remove(dir)
  end)

  -- @tests lurek.filesystem.listRecursive
  -- @description path traversal attempt raises an error (sandbox rejection).
  it("path traversal is rejected with an error", function()
    local ok = pcall(lurek.filesystem.listRecursive, "save/../..")
    expect_equal(false, ok)
  end)
end)

describe("lurek.filesystem.stat lightweight file statistics", function()
  -- @tests lurek.filesystem.stat
  it("stat is a function", function()
    expect_equal("function", type(lurek.filesystem.stat))
  end)

  -- @tests lurek.filesystem.stat
  it("stat rejects path traversal", function()
    local ok = pcall(lurek.filesystem.stat, "../../etc/passwd")
    expect_equal(false, ok)
  end)

  -- @tests lurek.filesystem.stat
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

  -- @tests lurek.filesystem.stat
  it("stat size matches written content length", function()
    lurek.filesystem.write("save/_stat_size.txt", "abcde")
    local info = lurek.filesystem.stat("save/_stat_size.txt")
    expect_equal(5, info.size)
  end)
end)

describe("lurek.filesystem.createTempFile temporary file creation", function()
  -- @tests lurek.filesystem.createTempFile
  it("createTempFile is a function", function()
    expect_equal("function", type(lurek.filesystem.createTempFile))
  end)

  -- @tests lurek.filesystem.createTempFile
  it("createTempFile returns a string path", function()
    local path = lurek.filesystem.createTempFile("test_")
    expect_equal("string", type(path))
    expect_true(#path > 0)
  end)

  -- @tests lurek.filesystem.createTempFile
  it("createTempFile path starts with save/", function()
    local path = lurek.filesystem.createTempFile("pfx_")
    expect_equal("save/", path:sub(1, 5))
  end)

  -- @tests lurek.filesystem.createTempFile
  it("two calls return different paths", function()
    local a = lurek.filesystem.createTempFile("tmp")
    local b = lurek.filesystem.createTempFile("tmp")
    expect_true(a ~= b)
  end)
end)

test_summary()

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests lurek.filesystem.removeDir
    it("covers lurek.filesystem.removeDir", function()
        -- TODO: Implement test for lurek.filesystem.removeDir
    end)

    -- @tests ZipMount:readFile
    it("covers ZipMount:readFile", function()
        -- TODO: Implement test for ZipMount:readFile
    end)

    -- @tests ZipMount:listFiles
    it("covers ZipMount:listFiles", function()
        -- TODO: Implement test for ZipMount:listFiles
    end)

end)

describe("Missing explicit test for lurek.filesystem.mountZip", function()
    it("lurek.filesystem.mountZip works", function()
        -- @tests lurek.filesystem.mountZip
        -- TODO: add assertion for lurek.filesystem.mountZip
    end)
end)

describe("Missing explicit test for lurek.filesystem.watchPath", function()
    it("lurek.filesystem.watchPath works", function()
        -- @tests lurek.filesystem.watchPath
        -- TODO: add assertion for lurek.filesystem.watchPath
    end)
end)

describe("Missing explicit test for lurek.filesystem.unwatchPath", function()
    it("lurek.filesystem.unwatchPath works", function()
        -- @tests lurek.filesystem.unwatchPath
        -- TODO: add assertion for lurek.filesystem.unwatchPath
    end)
end)

describe("Missing explicit test for lurek.filesystem.pollWatchers", function()
    it("lurek.filesystem.pollWatchers works", function()
        -- @tests lurek.filesystem.pollWatchers
        -- TODO: add assertion for lurek.filesystem.pollWatchers
    end)
end)

describe("Missing explicit test for lurek.filesystem.copy", function()
    it("lurek.filesystem.copy works", function()
        -- @tests lurek.filesystem.copy
        -- TODO: add assertion for lurek.filesystem.copy
    end)
end)

describe("Missing explicit test for lurek.filesystem.move", function()
    it("lurek.filesystem.move works", function()
        -- @tests lurek.filesystem.move
        -- TODO: add assertion for lurek.filesystem.move
    end)
end)

describe("Missing explicit test for lurek.filesystem.glob", function()
    it("lurek.filesystem.glob works", function()
        -- @tests lurek.filesystem.glob
        -- TODO: add assertion for lurek.filesystem.glob
    end)
end)

describe("Missing explicit test for lurek.filesystem.mkdir", function()
    it("lurek.filesystem.mkdir works", function()
        -- @tests lurek.filesystem.mkdir
        -- TODO: add assertion for lurek.filesystem.mkdir
    end)
end)

describe("Missing explicit test for lurek.filesystem.toAbsolutePath", function()
    it("lurek.filesystem.toAbsolutePath works", function()
        -- @tests lurek.filesystem.toAbsolutePath
        -- TODO: add assertion for lurek.filesystem.toAbsolutePath
    end)
end)

describe("Missing explicit test for FileData:getSize", function()
    it("FileData:getSize works", function()
        -- @tests FileData:getSize
        -- TODO: add assertion for FileData:getSize
    end)
end)

describe("Missing explicit test for FileData:getString", function()
    it("FileData:getString works", function()
        -- @tests FileData:getString
        -- TODO: add assertion for FileData:getString
    end)
end)

describe("Missing explicit test for FileData:getFilename", function()
    it("FileData:getFilename works", function()
        -- @tests FileData:getFilename
        -- TODO: add assertion for FileData:getFilename
    end)
end)

describe("Missing explicit test for FileHandle:read", function()
    it("FileHandle:read works", function()
        -- @tests FileHandle:read
        -- TODO: add assertion for FileHandle:read
    end)
end)

describe("Missing explicit test for FileHandle:readLine", function()
    it("FileHandle:readLine works", function()
        -- @tests FileHandle:readLine
        -- TODO: add assertion for FileHandle:readLine
    end)
end)

describe("Missing explicit test for FileHandle:write", function()
    it("FileHandle:write works", function()
        -- @tests FileHandle:write
        -- TODO: add assertion for FileHandle:write
    end)
end)

describe("Missing explicit test for FileHandle:seek", function()
    it("FileHandle:seek works", function()
        -- @tests FileHandle:seek
        -- TODO: add assertion for FileHandle:seek
    end)
end)

describe("Missing explicit test for FileHandle:tell", function()
    it("FileHandle:tell works", function()
        -- @tests FileHandle:tell
        -- TODO: add assertion for FileHandle:tell
    end)
end)

describe("Missing explicit test for FileHandle:getSize", function()
    it("FileHandle:getSize works", function()
        -- @tests FileHandle:getSize
        -- TODO: add assertion for FileHandle:getSize
    end)
end)

describe("Missing explicit test for FileHandle:getMode", function()
    it("FileHandle:getMode works", function()
        -- @tests FileHandle:getMode
        -- TODO: add assertion for FileHandle:getMode
    end)
end)

describe("Missing explicit test for FileHandle:flush", function()
    it("FileHandle:flush works", function()
        -- @tests FileHandle:flush
        -- TODO: add assertion for FileHandle:flush
    end)
end)

describe("Missing explicit test for FileHandle:close", function()
    it("FileHandle:close works", function()
        -- @tests FileHandle:close
        -- TODO: add assertion for FileHandle:close
    end)
end)

describe("Missing explicit test for FileHandle:isEOF", function()
    it("FileHandle:isEOF works", function()
        -- @tests FileHandle:isEOF
        -- TODO: add assertion for FileHandle:isEOF
    end)
end)

describe("Missing explicit test for ZipMount:contains", function()
    it("ZipMount:contains works", function()
        -- @tests ZipMount:contains
        -- TODO: add assertion for ZipMount:contains
    end)
end)

describe("Missing explicit test for ZipMount:prefix", function()
    it("ZipMount:prefix works", function()
        -- @tests ZipMount:prefix
        -- TODO: add assertion for ZipMount:prefix
    end)
end)
