-- tests/lua/content/demos/test_snake.lua
-- Smoke test for content/games/arcade/snake/main.lua.

local DEMO_PATH = "content/games/arcade/snake/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("snake", DEMO_PATH)

describe("snake: game mechanics", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("uses direction input (up/down/left/right)", function()
        if not src then pending("source missing") return end
        expect_true(
            (src:find('"up"') ~= nil or src:find('"w"') ~= nil) and
            (src:find('"down"') ~= nil or src:find('"s"') ~= nil),
            "No direction key bindings found")
    end)

    it("has a snake body table or segment list", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("body") ~= nil or
            src:find("segments") ~= nil or
            src:find("snake") ~= nil,
            "No snake body structure found")
    end)

    it("has food or item spawning", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("food") ~= nil or
            src:find("apple") ~= nil or
            src:find("item") ~= nil,
            "No food/item found — snake has nothing to eat")
    end)

    it("draws grid cells or snake segments", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("drawRect%s*%(") ~= nil,
            "No drawRect call found — snake segments will not render")
    end)
end)
