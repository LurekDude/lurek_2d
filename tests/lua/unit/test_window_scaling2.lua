-- Luna2D Window Scaling API Tests
-- Tests for luna.window scale mode, game dimensions, and viewport info.

describe("luna.window scaling API exists", function()
    it("setScaleMode is a function", function()
        expect_type("function", luna.window.setScaleMode)
    end)

    it("getScaleMode is a function", function()
        expect_type("function", luna.window.getScaleMode)
    end)

    it("getScaleInfo is a function", function()
        expect_type("function", luna.window.getScaleInfo)
    end)

    it("getGameWidth is a function", function()
        expect_type("function", luna.window.getGameWidth)
    end)

    it("getGameHeight is a function", function()
        expect_type("function", luna.window.getGameHeight)
    end)
end)

describe("luna.window.getScaleMode defaults", function()
    it("returns a string", function()
        local mode = luna.window.getScaleMode()
        expect_type("string", mode)
    end)

    it("default scale mode is none", function()
        local mode = luna.window.getScaleMode()
        expect_equal("none", mode)
    end)
end)

describe("luna.window.setScaleMode", function()
    it("accepts letterbox mode", function()
        expect_no_error(function()
            luna.window.setScaleMode("letterbox")
        end)
    end)

    it("accepts stretch mode", function()
        expect_no_error(function()
            luna.window.setScaleMode("stretch")
        end)
    end)

    it("accepts pixel mode", function()
        expect_no_error(function()
            luna.window.setScaleMode("pixel")
        end)
    end)

    it("accepts none mode", function()
        expect_no_error(function()
            luna.window.setScaleMode("none")
        end)
    end)

    it("silently ignores an invalid mode without error", function()
        -- Mode before invalid call
        local before = luna.window.getScaleMode()
        -- This should not throw
        expect_no_error(function()
            luna.window.setScaleMode("invalid_mode")
        end)
        -- Mode must remain unchanged
        local after = luna.window.getScaleMode()
        expect_equal(before, after)
    end)

    it("silently ignores an empty string without error", function()
        local before = luna.window.getScaleMode()
        expect_no_error(function()
            luna.window.setScaleMode("")
        end)
        local after = luna.window.getScaleMode()
        expect_equal(before, after)
    end)
end)

describe("luna.window.getGameWidth", function()
    it("returns a number", function()
        local w = luna.window.getGameWidth()
        expect_type("number", w)
    end)

    it("returns a positive value", function()
        local w = luna.window.getGameWidth()
        expect_true(w > 0, "game_width must be positive, got " .. tostring(w))
    end)
end)

describe("luna.window.getGameHeight", function()
    it("returns a number", function()
        local h = luna.window.getGameHeight()
        expect_type("number", h)
    end)

    it("returns a positive value", function()
        local h = luna.window.getGameHeight()
        expect_true(h > 0, "game_height must be positive, got " .. tostring(h))
    end)
end)

describe("luna.window.getScaleInfo", function()
    it("returns a table", function()
        local info = luna.window.getScaleInfo()
        expect_type("table", info)
    end)

    it("table contains scale_x field", function()
        local info = luna.window.getScaleInfo()
        expect_not_nil(info.scale_x)
    end)

    it("table contains scale_y field", function()
        local info = luna.window.getScaleInfo()
        expect_not_nil(info.scale_y)
    end)

    it("table contains offset_x field", function()
        local info = luna.window.getScaleInfo()
        expect_not_nil(info.offset_x)
    end)

    it("table contains offset_y field", function()
        local info = luna.window.getScaleInfo()
        expect_not_nil(info.offset_y)
    end)

    it("table contains game_width field", function()
        local info = luna.window.getScaleInfo()
        expect_not_nil(info.game_width)
    end)

    it("table contains game_height field", function()
        local info = luna.window.getScaleInfo()
        expect_not_nil(info.game_height)
    end)

    it("scale_x is a number", function()
        local info = luna.window.getScaleInfo()
        expect_type("number", info.scale_x)
    end)

    it("scale_y is a number", function()
        local info = luna.window.getScaleInfo()
        expect_type("number", info.scale_y)
    end)

    it("offset_x is a number", function()
        local info = luna.window.getScaleInfo()
        expect_type("number", info.offset_x)
    end)

    it("offset_y is a number", function()
        local info = luna.window.getScaleInfo()
        expect_type("number", info.offset_y)
    end)

    it("game_width matches getGameWidth()", function()
        local info = luna.window.getScaleInfo()
        local w = luna.window.getGameWidth()
        expect_near(w, info.game_width, 0.001)
    end)

    it("game_height matches getGameHeight()", function()
        local info = luna.window.getScaleInfo()
        local h = luna.window.getGameHeight()
        expect_near(h, info.game_height, 0.001)
    end)

    it("default scale_x is 1.0 with none mode", function()
        local info = luna.window.getScaleInfo()
        -- In headless test VM, scale mode is "none" so scale should be 1.0
        if luna.window.getScaleMode() == "none" then
            expect_near(1.0, info.scale_x, 0.001)
        end
    end)

    it("default scale_y is 1.0 with none mode", function()
        local info = luna.window.getScaleInfo()
        if luna.window.getScaleMode() == "none" then
            expect_near(1.0, info.scale_y, 0.001)
        end
    end)
end)

test_summary()
