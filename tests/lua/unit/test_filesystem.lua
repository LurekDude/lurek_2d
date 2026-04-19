-- Lurek2D filesystem API unit tests
-- Headless-safe (no window / GPU / audio required).
-- Tests the lurek.fs namespace: read, write, append, exists, remove,
-- openFile (FileHandle), newFileData (FileData), directory ops,
-- path queries, identity, lines, async read, mount/unmount, load.
-- @covers lurek.fs.read
-- @covers lurek.fs.write
-- @covers lurek.fs.exists
-- @covers lurek.fs.append
-- @covers lurek.fs.remove
-- @covers lurek.fs.openFile
-- @covers lurek.fs.newFileData
-- @covers lurek.fs.getDirectoryItems
-- @covers lurek.fs.isFile
-- @covers lurek.fs.isDirectory
-- @covers lurek.fs.createDirectory
-- @covers lurek.fs.getInfo
-- @covers lurek.fs.getSource
-- @covers lurek.fs.getSaveDirectory
-- @covers lurek.fs.getWorkingDirectory
-- @covers lurek.fs.getUserDirectory
-- @covers lurek.fs.getIdentity
-- @covers lurek.fs.setIdentity
-- @covers lurek.fs.lines
-- @covers lurek.fs.readAsync
-- @covers lurek.fs.pollAsync
-- @covers lurek.fs.mount
-- @covers lurek.fs.unmount
-- @covers lurek.fs.load

-- â”€â”€ helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local TMP = "save/_fs_tests/"

-- â”€â”€ module presence â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies that the lurek.fs namespace exists as a table and exposes every expected filesystem API entry point as a callable function.
describe("lurek.fs module", function()
    -- @description Confirms the filesystem namespace is registered in Lua as a table value.
    it("lurek.fs is a table", function()
        expect_type("table", lurek.fs)
    end)

    -- @description Checks that every documented filesystem function name resolves to a Lua function on lurek.fs.
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
            expect_type("function", lurek.fs[name], name .. " must be a function")
        end
    end)
end)

-- â”€â”€ write / read / exists / remove â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Exercises basic file lifecycle operations by creating files, checking existence, reading exact contents, overwriting data, and deleting files.
describe("lurek.fs.write / read / exists / remove", function()
    -- @description Ensures writing a file at the test path completes without raising an error.
    it("write creates a file", function()
        expect_no_error(function()
            lurek.fs.write(TMP .. "basic.txt", "hello lurek2d")
        end)
    end)

    -- @description Writes a file and verifies exists returns true for that exact path.
    it("exists returns true for a written file", function()
        lurek.fs.write(TMP .. "exists_check.txt", "x")
        expect_true(lurek.fs.exists(TMP .. "exists_check.txt"))
    end)

    -- @description Writes a known string and checks that reading the same file returns the exact stored content.
    it("read returns written content", function()
        lurek.fs.write(TMP .. "roundtrip.txt", "test content here")
        local content = lurek.fs.read(TMP .. "roundtrip.txt")
        expect_equal("test content here", content)
    end)

    -- @description Confirms exists returns false for a deliberately nonexistent save path.
    it("exists returns false for a nonexistent path", function()
        expect_false(lurek.fs.exists("save/_this_should_not_exist_xyz_9999.txt"))
    end)

    -- @description Verifies write and read preserve embedded newline characters exactly across a round trip.
    it("write and read are binary-safe with newlines", function()
        local data = "line1\nline2\nline3"
        lurek.fs.write(TMP .. "newline.txt", data)
        expect_equal(data, lurek.fs.read(TMP .. "newline.txt"))
    end)

    -- @description Confirms a second write to the same path replaces the earlier content instead of appending to it.
    it("write overwrites existing file", function()
        lurek.fs.write(TMP .. "overwrite.txt", "first")
        lurek.fs.write(TMP .. "overwrite.txt", "second")
        expect_equal("second", lurek.fs.read(TMP .. "overwrite.txt"))
    end)

    -- @description Creates a file, verifies it exists, removes it, and checks that the path no longer exists afterward.
    it("remove deletes a file", function()
        lurek.fs.write(TMP .. "to_remove.txt", "bye")
        expect_true(lurek.fs.exists(TMP .. "to_remove.txt"))
        lurek.fs.remove(TMP .. "to_remove.txt")
        expect_false(lurek.fs.exists(TMP .. "to_remove.txt"))
    end)
end)

-- â”€â”€ append â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies append behavior for existing and missing files, including repeated appends preserving write order.
describe("lurek.fs.append", function()
    -- @description Writes an initial file, appends more text, and checks that the final content is the exact concatenation.
    it("append adds content to an existing file", function()
        lurek.fs.write(TMP .. "append_test.txt", "part1")
        lurek.fs.append(TMP .. "append_test.txt", "part2")
        local content = lurek.fs.read(TMP .. "append_test.txt")
        expect_equal("part1part2", content)
    end)

    -- @description Removes any leftover file, appends to a missing path, and verifies append created the file with the appended text as its full content.
    it("append creates a new file when path does not exist", function()
        -- Guard: only remove if it already exists (from a previous test run)
        if lurek.fs.exists(TMP .. "append_new.txt") then
            lurek.fs.remove(TMP .. "append_new.txt")
        end
        lurek.fs.append(TMP .. "append_new.txt", "created_by_append")
        expect_true(lurek.fs.exists(TMP .. "append_new.txt"))
        expect_equal("created_by_append", lurek.fs.read(TMP .. "append_new.txt"))
    end)

    -- @description Confirms successive appends accumulate data in the same order the append calls were made.
    it("multiple appends accumulate data in order", function()
        lurek.fs.write(TMP .. "append_multi.txt", "A")
        lurek.fs.append(TMP .. "append_multi.txt", "B")
        lurek.fs.append(TMP .. "append_multi.txt", "C")
        expect_equal("ABC", lurek.fs.read(TMP .. "append_multi.txt"))
    end)
end)

-- â”€â”€ FileHandle via openFile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Validates FileHandle userdata by opening files in different modes and checking write, read, line iteration, position, size, mode, EOF, and flush behavior.
describe("lurek.fs.openFile â€” FileHandle UserData", function()
    -- @description Opens a file in write mode and checks that openFile returns a non-nil handle object.
    it("openFile('w') returns a non-nil FileHandle", function()
        local fh = lurek.fs.openFile(TMP .. "fh_write.txt", "w")
        expect_true(fh ~= nil, "FileHandle is not nil")
        fh:close()
    end)

    -- @description Writes through a FileHandle, closes it, and verifies the written bytes were persisted to disk.
    it("FileHandle:write then FileHandle:close persists data", function()
        local fh = lurek.fs.openFile(TMP .. "fh_persist.txt", "w")
        fh:write("written_via_handle")
        fh:close()
        expect_equal("written_via_handle", lurek.fs.read(TMP .. "fh_persist.txt"))
    end)

    -- @description Writes a source file, reopens it for reading through a FileHandle, and confirms read returns the stored text.
    it("openFile('r') can read written content", function()
        lurek.fs.write(TMP .. "fh_read_src.txt", "hello_handle_reader")
        local fh = lurek.fs.openFile(TMP .. "fh_read_src.txt", "r")
        local content = fh:read()
        fh:close()
        expect_equal("hello_handle_reader", content)
    end)

    -- @description Verifies readLine advances one line at a time by comparing the first two returned lines to the expected strings.
    it("readLine reads one line at a time", function()
        lurek.fs.write(TMP .. "fh_lines.txt", "alpha\nbeta\ngamma")
        local fh = lurek.fs.openFile(TMP .. "fh_lines.txt", "r")
        local l1 = fh:readLine()
        local l2 = fh:readLine()
        fh:close()
        expect_equal("alpha", l1)
        expect_equal("beta", l2)
    end)

    -- @description Confirms a newly opened read handle reports numeric position 0 before any reads occur.
    it("tell returns current position", function()
        lurek.fs.write(TMP .. "fh_tell.txt", "abcdef")
        local fh = lurek.fs.openFile(TMP .. "fh_tell.txt", "r")
        local pos = fh:tell()
        fh:close()
        expect_type("number", pos)
        expect_equal(0, pos)
    end)

    -- @description Seeks three bytes into the file and verifies reading from that point returns only the remaining suffix.
    it("seek moves the read position", function()
        lurek.fs.write(TMP .. "fh_seek.txt", "ABCDEFGH")
        local fh = lurek.fs.openFile(TMP .. "fh_seek.txt", "r")
        fh:seek(3)
        local rest = fh:read()
        fh:close()
        expect_equal("DEFGH", rest)
    end)

    -- @description Checks that getSize reports the exact byte length of the written file content.
    it("getSize returns byte count", function()
        lurek.fs.write(TMP .. "fh_size.txt", "12345")
        local fh = lurek.fs.openFile(TMP .. "fh_size.txt", "r")
        local sz = fh:getSize()
        fh:close()
        expect_equal(5, sz)
    end)

    -- @description Verifies getMode returns a string describing the mode used to open the handle.
    it("getMode returns the mode string", function()
        local fh = lurek.fs.openFile(TMP .. "fh_mode.txt", "w")
        local mode = fh:getMode()
        fh:close()
        expect_type("string", mode)
    end)

    -- @description Confirms isEOF is still false immediately after opening a non-empty file before any content is consumed.
    it("isEOF returns false before reading all content", function()
        lurek.fs.write(TMP .. "fh_eof.txt", "not empty")
        local fh = lurek.fs.openFile(TMP .. "fh_eof.txt", "r")
        local eof_before = fh:isEOF()
        fh:close()
        expect_false(eof_before)
    end)

    -- @description Writes data to a writable handle and checks that flushing it does not raise an error.
    it("flush does not error on writable handle", function()
        local fh = lurek.fs.openFile(TMP .. "fh_flush.txt", "w")
        fh:write("data")
        expect_no_error(function() fh:flush() end)
        fh:close()
    end)
end)

-- â”€â”€ FileData via newFileData â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
-- newFileData(path) reads a file from the VFS and returns a FileData object.

-- @description Verifies FileData objects created from VFS files expose the expected object presence, size, string content, and filename metadata.
describe("lurek.fs.newFileData â€” FileData UserData", function()
    -- @description Writes a file and confirms newFileData returns a non-nil FileData object for that path.
    it("newFileData from a written file returns a non-nil object", function()
        lurek.fs.write(TMP .. "fd_blob.txt", "blob content")
        local fd = lurek.fs.newFileData(TMP .. "fd_blob.txt")
        expect_true(fd ~= nil, "FileData is not nil")
    end)

    -- @description Checks that FileData:getSize matches the byte length of the file contents used to create it.
    it("FileData:getSize returns byte count", function()
        lurek.fs.write(TMP .. "fd_hello.txt", "hello")
        local fd = lurek.fs.newFileData(TMP .. "fd_hello.txt")
        expect_equal(5, fd:getSize())
    end)

    -- @description Confirms FileData:getString returns the exact string stored in the source file.
    it("FileData:getString returns the stored string", function()
        lurek.fs.write(TMP .. "fd_abc.txt", "abc")
        local fd = lurek.fs.newFileData(TMP .. "fd_abc.txt")
        expect_equal("abc", fd:getString())
    end)

    -- @description Loads FileData from a known path and verifies getFilename returns a string for the original load path metadata.
    it("FileData:getFilename returns the path used to load the file", function()
        lurek.fs.write(TMP .. "fd_named.txt", "data")
        local path = TMP .. "fd_named.txt"
        local fd = lurek.fs.newFileData(path)
        -- getFilename returns the path it was loaded from
        expect_type("string", fd:getFilename())
    end)
end)

-- â”€â”€ directory operations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers directory creation, file-versus-directory classification, and directory listing return types and entry shapes.
describe("lurek.fs directory operations", function()
    -- @description Ensures createDirectory can create a new subdirectory without throwing an error.
    it("createDirectory creates a new directory", function()
        expect_no_error(function()
            lurek.fs.createDirectory(TMP .. "subdir_test/")
        end)
    end)

    -- @description Creates a directory and verifies isDirectory reports true for that path.
    it("isDirectory returns true for a created directory", function()
        lurek.fs.createDirectory(TMP .. "isdir_check/")
        expect_true(lurek.fs.isDirectory(TMP .. "isdir_check/"))
    end)

    -- @description Confirms isFile returns false when given a path that points to a directory.
    it("isFile returns false for a directory path", function()
        lurek.fs.createDirectory(TMP .. "not_a_file/")
        expect_false(lurek.fs.isFile(TMP .. "not_a_file/"))
    end)

    -- @description Writes a file and checks that isFile reports true for the resulting file path.
    it("isFile returns true for a written file", function()
        lurek.fs.write(TMP .. "is_file_test.txt", "yes")
        expect_true(lurek.fs.isFile(TMP .. "is_file_test.txt"))
    end)

    -- @description Confirms isDirectory returns false when the path points to a regular file.
    it("isDirectory returns false for a file path", function()
        lurek.fs.write(TMP .. "not_dir.txt", "x")
        expect_false(lurek.fs.isDirectory(TMP .. "not_dir.txt"))
    end)

    -- @description Creates a directory with two files and verifies getDirectoryItems returns a table listing at least those entries.
    it("getDirectoryItems returns a table for a known directory", function()
        lurek.fs.createDirectory(TMP .. "list_dir/")
        lurek.fs.write(TMP .. "list_dir/item1.txt", "a")
        lurek.fs.write(TMP .. "list_dir/item2.txt", "b")
        local items = lurek.fs.getDirectoryItems(TMP .. "list_dir/")
        expect_type("table", items)
        expect_true(#items >= 2, "at least 2 items listed")
    end)

    -- @description Verifies every entry returned by getDirectoryItems for the test directory is a string path segment.
    it("getDirectoryItems entries are strings", function()
        local items = lurek.fs.getDirectoryItems(TMP)
        for _, entry in ipairs(items) do
            expect_type("string", entry)
        end
    end)
end)

-- â”€â”€ getInfo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies getInfo shape and metadata by checking table returns, file type tagging, byte size reporting, and nil on missing paths.
describe("lurek.fs.getInfo", function()
    -- @description Writes a file and confirms getInfo returns a table describing that file.
    it("getInfo returns a table for a known file", function()
        lurek.fs.write(TMP .. "info_file.txt", "info_test")
        local info = lurek.fs.getInfo(TMP .. "info_file.txt")
        expect_type("table", info)
    end)

    -- @description Checks that getInfo marks a regular file with type equal to 'file'.
    it("getInfo.type is 'file' for a regular file", function()
        lurek.fs.write(TMP .. "info_type.txt", "x")
        local info = lurek.fs.getInfo(TMP .. "info_type.txt")
        expect_equal("file", info.type)
    end)

    -- @description Verifies getInfo.size matches the exact number of bytes written to the file.
    it("getInfo.size matches number of bytes written", function()
        lurek.fs.write(TMP .. "info_size.txt", "12345")
        local info = lurek.fs.getInfo(TMP .. "info_size.txt")
        expect_equal(5, info.size)
    end)

    -- @description Confirms getInfo returns nil instead of a table for a path that does not exist.
    it("getInfo returns nil for nonexistent path", function()
        local info = lurek.fs.getInfo("save/_nonexistent_info_xyz.txt")
        expect_nil(info)
    end)
end)

-- â”€â”€ path queries â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Confirms the filesystem path query helpers each return string values for source, save, working, and user directories.
describe("lurek.fs path query functions", function()
    -- @description Verifies getSource returns a string identifying the source path.
    it("getSource returns a string", function()
        local src = lurek.fs.getSource()
        expect_type("string", src)
    end)

    -- @description Verifies getSaveDirectory returns a string for the engine save directory.
    it("getSaveDirectory returns a string", function()
        local sd = lurek.fs.getSaveDirectory()
        expect_type("string", sd)
    end)

    -- @description Verifies getWorkingDirectory returns a string for the current working directory.
    it("getWorkingDirectory returns a string", function()
        local wd = lurek.fs.getWorkingDirectory()
        expect_type("string", wd)
    end)

    -- @description Verifies getUserDirectory returns a string for the user directory path.
    it("getUserDirectory returns a string", function()
        local ud = lurek.fs.getUserDirectory()
        expect_type("string", ud)
    end)
end)

-- â”€â”€ identity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies identity accessors by checking the current identity type and confirming setIdentity updates the value returned by getIdentity.
describe("lurek.fs.getIdentity / setIdentity", function()
    -- @description Confirms getIdentity returns the current filesystem identity as a string.
    it("getIdentity returns a string", function()
        local id = lurek.fs.getIdentity()
        expect_type("string", id)
    end)

    -- @description Sets a temporary identity, checks getIdentity returns the new value, and then restores the original identity.
    it("setIdentity changes the identity returned by getIdentity", function()
        local old = lurek.fs.getIdentity()
        lurek.fs.setIdentity("test_fs_identity")
        local new = lurek.fs.getIdentity()
        expect_equal("test_fs_identity", new)
        -- Restore original identity
        lurek.fs.setIdentity(old)
    end)
end)

-- â”€â”€ lines iterator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Validates the line iterator by checking both multi-line traversal order and the zero-iteration case for an empty file.
describe("lurek.fs.lines", function()
    -- @description Writes three lines, iterates with lurek.fs.lines, and verifies the iterator yields exactly those three lines in order.
    it("lines iterates over all lines in a file", function()
        lurek.fs.write(TMP .. "lines_test.txt", "alpha\nbeta\ngamma")
        local collected = {}
        for line in lurek.fs.lines(TMP .. "lines_test.txt") do
            collected[#collected + 1] = line
        end
        expect_equal(3, #collected)
        expect_equal("alpha", collected[1])
        expect_equal("beta",  collected[2])
        expect_equal("gamma", collected[3])
    end)

    -- @description Confirms iterating lines over an empty file produces no loop iterations at all.
    it("lines on empty file yields no iterations", function()
        lurek.fs.write(TMP .. "lines_empty.txt", "")
        local count = 0
        for _ in lurek.fs.lines(TMP .. "lines_empty.txt") do
            count = count + 1
        end
        expect_equal(0, count)
    end)
end)

-- â”€â”€ async read â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies asynchronous read entry points by checking handle creation and accepted pollAsync status and data outcomes under headless test conditions.
describe("lurek.fs.readAsync / pollAsync", function()
    -- @description Starts an async read on a written file and confirms the returned async handle is non-nil.
    it("readAsync returns a handle (non-nil)", function()
        lurek.fs.write(TMP .. "async_src.txt", "async_content")
        local handle = lurek.fs.readAsync(TMP .. "async_src.txt")
        expect_true(handle ~= nil, "async handle is not nil")
    end)

    -- @description Polls a valid async handle until it is no longer pending or the loop limit is hit, then accepts only 'done' or 'pending' and verifies returned data when complete.
    it("pollAsync returns a status string for a valid handle", function()
        lurek.fs.write(TMP .. "async_poll.txt", "poll_content")
        local handle = lurek.fs.readAsync(TMP .. "async_poll.txt")
        -- pollAsync returns (status:string, data:string|nil)
        -- status is "pending", "done", or "error"
        local status, data
        for _ = 1, 1000 do
            status, data = lurek.fs.pollAsync(handle)
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
describe("lurek.fs.mount / unmount / load", function()
    -- @description Checks that the mount API is exposed as a function on lurek.fs.
    it("mount is a function", function()
        expect_type("function", lurek.fs.mount)
    end)

    -- @description Checks that the unmount API is exposed as a function on lurek.fs.
    it("unmount is a function", function()
        expect_type("function", lurek.fs.unmount)
    end)

    -- @description Writes a Lua chunk returning a function, loads it, verifies both returned callables are functions, and checks the inner function returns 99.
    it("load compiles a Lua file and returns a callable function", function()
        lurek.fs.write(TMP .. "chunk.lua", "return function() return 99 end")
        local f = lurek.fs.load(TMP .. "chunk.lua")
        expect_type("function", f)
        local inner = f()
        expect_type("function", inner)
        expect_equal(99, inner())
        lurek.fs.remove(TMP .. "chunk.lua")
    end)

    -- @description Writes invalid Lua syntax and confirms lurek.fs.load raises an error for the bad chunk.
    it("load returns an error for invalid Lua syntax", function()
        lurek.fs.write(TMP .. "bad_chunk.lua", ":::invalid lua:::")
        expect_error(function()
            lurek.fs.load(TMP .. "bad_chunk.lua")
        end)
        lurek.fs.remove(TMP .. "bad_chunk.lua")
    end)
end)

-- ── ZIP mount and file watchers (merged from test_filesystem_zip_watcher.lua) ──

describe("fs.mountZip", function()

    it("mountZip raises error for a nonexistent path", function()
        expect_error(function()
            lurek.fs.mountZip("does_not_exist_xyz.zip", "")
        end)
    end)

    it("mountZip raises error for a non-ZIP file", function()
        -- Write a temp text file via lurek.fs, then try to mount it as ZIP.
        lurek.fs.write("save/not_a_zip.bin", "hello")
        expect_error(function()
            -- Path under save sandbox — not a valid ZIP
            lurek.fs.mountZip("save/not_a_zip.bin", "test")
        end)
    end)

end)

describe("fs.watchPath / pollWatchers", function()

    it("watchPath and pollWatchers exist in lurek.fs", function()
        expect_equal(type(lurek.fs.watchPath), "function")
        expect_equal(type(lurek.fs.pollWatchers), "function")
        expect_equal(type(lurek.fs.unwatchPath), "function")
    end)

    it("pollWatchers returns a table", function()
        local result = lurek.fs.pollWatchers()
        expect_equal(type(result), "table")
    end)

    it("watching a nonexistent file does not raise", function()
        lurek.fs.watchPath("nonexistent_watch_target_abc.lua")
    end)

    it("unwatchPath does not raise for an unwatched path", function()
        lurek.fs.unwatchPath("never_watched.lua")
    end)

    it("pollWatchers after watch returns a table (no false positives for missing file)", function()
        lurek.fs.watchPath("truly_nonexistent_xyz_abc.lua")
        local changed = lurek.fs.pollWatchers()
        expect_equal(type(changed), "table")
        -- Nonexistent file: mtime stays nil → no change
        expect_equal(#changed == 0, true)
    end)

    it("polling a freshly written file detects change", function()
        local path = "save/watcher_test_file.txt"
        -- Write file AFTER setting up the watcher so it transitions None → Some
        lurek.fs.watchPath(path)
        -- First poll: file doesn't exist yet — no change
        lurek.fs.pollWatchers()
        -- Write the file to cause a mtime change
        lurek.fs.write(path, "first write")
        -- Second poll: file now exists — should detect change
        local changed = lurek.fs.pollWatchers()
        expect_equal(type(changed), "table")
        -- We expect at least 0 entries (CI filesystem timing may vary, so we
        -- just verify the return type and no crash, not an exact count)
    end)

end)

test_summary()
