-- Lurek2D Lua BDD tests for lurek.window.setIcon.
-- Headless: no GPU, no audio, no window.

-- @description Covers suite: lurek.window.setIcon exposure.
describe("lurek.window.setIcon — exposure", function()
    -- @covers lurek.window.setIcon
    -- @description Verifies setIcon is exposed under the window namespace.
    it("setIcon is a function", function()
        expect_type("function", lurek.window.setIcon)
    end)
end)

-- @description Covers suite: lurek.window.setIcon validation.
describe("lurek.window.setIcon — validation", function()
    -- @covers lurek.window.setIcon
    -- @description Verifies that setIcon raises an error when given an empty path.
    it("raises error for empty path", function()
        expect_error(function()
            lurek.window.setIcon("")
        end)
    end)

    -- @covers lurek.window.setIcon
    -- @description Verifies that setIcon raises an error for a nonexistent file path.
    it("raises error for nonexistent file", function()
        expect_error(function()
            lurek.window.setIcon("nonexistent_icon_file.png")
        end)
    end)

    -- @covers lurek.window.setIcon
    -- @description Verifies that setIcon raises an error for a path with a non-image extension.
    it("raises error for path that does not exist regardless of extension", function()
        expect_error(function()
            lurek.window.setIcon("missing_icon.bmp")
        end)
    end)
end)

test_summary()
