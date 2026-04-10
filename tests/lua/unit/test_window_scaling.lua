-- Lurek2D Window Scaling API Tests
-- Tests for lurek.window scale mode, game dimensions, and viewport info.
-- @covers lurek.window.getGameHeight
-- @covers lurek.window.getGameWidth
-- @covers lurek.window.getScaleInfo
-- @covers lurek.window.getScaleMode
-- @covers lurek.window.setScaleMode


describe("lurek.window scaling API exists", function()
    it("setScaleMode is a function", function()
        expect_type("function", lurek.window.setScaleMode)
    end)

    it("getScaleMode is a function", function()
        expect_type("function", lurek.window.getScaleMode)
    end)

    it("getScaleInfo is a function", function()
        expect_type("function", lurek.window.getScaleInfo)
    end)

    it("getGameWidth is a function", function()
        expect_type("function", lurek.window.getGameWidth)
    end)

    it("getGameHeight is a function", function()
        expect_type("function", lurek.window.getGameHeight)
    end)
end)

describe("lurek.window.getScaleMode defaults", function()
    it("returns a string", function()
        local mode = lurek.window.getScaleMode()
        expect_type("string", mode)
    end)

    it("default scale mode is none", function()
        local mode = lurek.window.getScaleMode()
        expect_equal("none", mode)
    end)
end)

describe("lurek.window.setScaleMode", function()
    it("accepts letterbox mode", function()
        expect_no_error(function()
            lurek.window.setScaleMode("letterbox")
        end)
    end)

    it("accepts stretch mode", function()
        expect_no_error(function()
            lurek.window.setScaleMode("stretch")
        end)
    end)

    it("accepts pixel mode", function()
        expect_no_error(function()
            lurek.window.setScaleMode("pixel")
        end)
    end)

    it("accepts none mode", function()
        expect_no_error(function()
            lurek.window.setScaleMode("none")
        end)
    end)

    it("silently ignores an invalid mode without error", function()
        -- Mode before invalid call
        local before = lurek.window.getScaleMode()
        -- This should not throw
        expect_no_error(function()
            lurek.window.setScaleMode("invalid_mode")
        end)
        -- Mode must remain unchanged
        local after = lurek.window.getScaleMode()
        expect_equal(before, after)
    end)

    it("silently ignores an empty string without error", function()
        local before = lurek.window.getScaleMode()
        expect_no_error(function()
            lurek.window.setScaleMode("")
        end)
        local after = lurek.window.getScaleMode()
        expect_equal(before, after)
    end)
end)

describe("lurek.window.getGameWidth", function()
    it("returns a number", function()
        local w = lurek.window.getGameWidth()
        expect_type("number", w)
    end)

    it("returns a positive value", function()
        local w = lurek.window.getGameWidth()
        expect_true(w > 0, "game_width must be positive, got " .. tostring(w))
    end)
end)

describe("lurek.window.getGameHeight", function()
    it("returns a number", function()
        local h = lurek.window.getGameHeight()
        expect_type("number", h)
    end)

    it("returns a positive value", function()
        local h = lurek.window.getGameHeight()
        expect_true(h > 0, "game_height must be positive, got " .. tostring(h))
    end)
end)

describe("lurek.window.getScaleInfo", function()
    it("returns a table", function()
        local info = lurek.window.getScaleInfo()
        expect_type("table", info)
    end)

    it("table contains scale_x field", function()
        local info = lurek.window.getScaleInfo()
        expect_not_nil(info.scale_x)
    end)

    it("table contains scale_y field", function()
        local info = lurek.window.getScaleInfo()
        expect_not_nil(info.scale_y)
    end)

    it("table contains offset_x field", function()
        local info = lurek.window.getScaleInfo()
        expect_not_nil(info.offset_x)
    end)

    it("table contains offset_y field", function()
        local info = lurek.window.getScaleInfo()
        expect_not_nil(info.offset_y)
    end)

    it("table contains game_width field", function()
        local info = lurek.window.getScaleInfo()
        expect_not_nil(info.game_width)
    end)

    it("table contains game_height field", function()
        local info = lurek.window.getScaleInfo()
        expect_not_nil(info.game_height)
    end)

    it("scale_x is a number", function()
        local info = lurek.window.getScaleInfo()
        expect_type("number", info.scale_x)
    end)

    it("scale_y is a number", function()
        local info = lurek.window.getScaleInfo()
        expect_type("number", info.scale_y)
    end)

    it("offset_x is a number", function()
        local info = lurek.window.getScaleInfo()
        expect_type("number", info.offset_x)
    end)

    it("offset_y is a number", function()
        local info = lurek.window.getScaleInfo()
        expect_type("number", info.offset_y)
    end)

    it("game_width matches getGameWidth()", function()
        local info = lurek.window.getScaleInfo()
        local w = lurek.window.getGameWidth()
        expect_near(w, info.game_width, 0.001)
    end)

    it("game_height matches getGameHeight()", function()
        local info = lurek.window.getScaleInfo()
        local h = lurek.window.getGameHeight()
        expect_near(h, info.game_height, 0.001)
    end)

    it("default scale_x is 1.0 with none mode", function()
        local info = lurek.window.getScaleInfo()
        -- In headless test VM, scale mode is "none" so scale should be 1.0
        if lurek.window.getScaleMode() == "none" then
            expect_near(1.0, info.scale_x, 0.001)
        end
    end)

    it("default scale_y is 1.0 with none mode", function()
        local info = lurek.window.getScaleInfo()
        if lurek.window.getScaleMode() == "none" then
            expect_near(1.0, info.scale_y, 0.001)
        end
    end)
end)

test_summary()
