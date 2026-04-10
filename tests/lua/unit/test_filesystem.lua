-- @covers lurek.fs.exists
-- @covers lurek.fs.load
-- @covers lurek.fs.mount
-- @covers lurek.fs.newFileData
-- @covers lurek.fs.read
-- @covers lurek.fs.remove
-- @covers lurek.fs.unmount
-- @covers lurek.fs.write

﻿-- Lurek2D Filesystem API Tests

describe("lurek.fs module exists", function()
    it("lurek.fs is a table", function()
        expect_type("table", lurek.fs)
    end)
end)

describe("lurek.fs basic operations", function()
    it("read is a function", function()
        expect_type("function", lurek.fs.read)
    end)

    it("write is a function", function()
        expect_type("function", lurek.fs.write)
    end)

    it("exists is a function", function()
        expect_type("function", lurek.fs.exists)
    end)
end)

describe("lurek.fs write and read", function()
    it("write creates a file", function()
        expect_no_error(function()
            lurek.fs.write("save/_test_temp.txt", "hello lurek2d")
        end)
    end)

    it("exists returns true for written file", function()
        lurek.fs.write("save/_test_temp2.txt", "test")
        expect_true(lurek.fs.exists("save/_test_temp2.txt"))
    end)

    it("read returns written content", function()
        lurek.fs.write("save/_test_temp3.txt", "test content here")
        local content = lurek.fs.read("save/_test_temp3.txt")
        expect_equal("test content here", content)
    end)

    it("exists returns false for non-existent file", function()
        expect_false(lurek.fs.exists("save/_this_file_should_not_exist_xyz.txt"))
    end)

    it("write and read binary-safe", function()
        local data = "line1\nline2\nline3"
        lurek.fs.write("save/_test_temp4.txt", data)
        local content = lurek.fs.read("save/_test_temp4.txt")
        expect_equal(data, content)
    end)

    it("write overwrites existing file", function()
        lurek.fs.write("save/_test_temp5.txt", "first")
        lurek.fs.write("save/_test_temp5.txt", "second")
        local content = lurek.fs.read("save/_test_temp5.txt")
        expect_equal("second", content)
    end)
end)

describe("filesystem.mount", function()
    it("mount() is a function", function()
        expect_type("function", lurek.fs.mount)
    end)
    it("unmount() is a function", function()
        expect_type("function", lurek.fs.unmount)
    end)
    it("load() is a function", function()
        expect_type("function", lurek.fs.load)
    end)
    it("newFileData() is a function", function()
        expect_type("function", lurek.fs.newFileData)
    end)
    it("load() compiles an existing Lua file", function()
        lurek.fs.write("save/_test_chunk.lua", "return function() return 99 end")
        local f = lurek.fs.load("save/_test_chunk.lua")
        expect_type("function", f)
        local inner = f()
        expect_type("function", inner)
        expect_equal(99, inner())
        lurek.fs.remove("save/_test_chunk.lua")
    end)
end)

test_summary()
