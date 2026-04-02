-- Luna2D Filesystem API Tests

describe("luna.filesystem module exists", function()
    it("luna.filesystem is a table", function()
        expect_type("table", luna.filesystem)
    end)
end)

describe("luna.filesystem basic operations", function()
    it("read is a function", function()
        expect_type("function", luna.filesystem.read)
    end)

    it("write is a function", function()
        expect_type("function", luna.filesystem.write)
    end)

    it("exists is a function", function()
        expect_type("function", luna.filesystem.exists)
    end)
end)

describe("luna.filesystem write and read", function()
    it("write creates a file", function()
        expect_no_error(function()
            luna.filesystem.write("save/_test_temp.txt", "hello luna2d")
        end)
    end)

    it("exists returns true for written file", function()
        luna.filesystem.write("save/_test_temp2.txt", "test")
        expect_true(luna.filesystem.exists("save/_test_temp2.txt"))
    end)

    it("read returns written content", function()
        luna.filesystem.write("save/_test_temp3.txt", "test content here")
        local content = luna.filesystem.read("save/_test_temp3.txt")
        expect_equal("test content here", content)
    end)

    it("exists returns false for non-existent file", function()
        expect_false(luna.filesystem.exists("save/_this_file_should_not_exist_xyz.txt"))
    end)

    it("write and read binary-safe", function()
        local data = "line1\nline2\nline3"
        luna.filesystem.write("save/_test_temp4.txt", data)
        local content = luna.filesystem.read("save/_test_temp4.txt")
        expect_equal(data, content)
    end)

    it("write overwrites existing file", function()
        luna.filesystem.write("save/_test_temp5.txt", "first")
        luna.filesystem.write("save/_test_temp5.txt", "second")
        local content = luna.filesystem.read("save/_test_temp5.txt")
        expect_equal("second", content)
    end)
end)

test_summary()
