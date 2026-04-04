-- tests/lua/unit/test_image.lua
-- BDD tests for luna.image compressed texture API.
-- The headless VM has no filesystem, so only function existence and
-- error-handling behaviour are tested here.

describe("luna.image compressed API", function()
    it("luna.image is a table", function()
        expect_type("table", luna.image)
    end)

    it("newCompressedData is a function", function()
        expect_type("function", luna.image.newCompressedData)
    end)

    it("isCompressed is a function", function()
        expect_type("function", luna.image.isCompressed)
    end)

    it("newCompressedData errors on missing file", function()
        expect_error(function()
            luna.image.newCompressedData("nonexistent_file.dds")
        end)
    end)

    it("isCompressed returns false for a missing path", function()
        local result = luna.image.isCompressed("nonexistent_file.dds")
        expect_equal(result, false)
    end)
end)

describe("luna.image existing API still works", function()
    it("newImageData is a function", function()
        expect_type("function", luna.image.newImageData)
    end)

    it("newImageData creates a blank buffer", function()
        local img = luna.image.newImageData(4, 4)
        expect_type("userdata", img)
    end)
end)

test_summary()
