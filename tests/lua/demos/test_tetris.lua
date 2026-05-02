-- tests/lua/content/demos/test_tetris.lua
-- Smoke test for content/games/arcade/tetris/main.lua.

local DEMO_PATH = "content/games/arcade/tetris/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("tetris", DEMO_PATH)

describe("tetris: game mechanics", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("defines tetromino shapes", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("tetromino") ~= nil or
            src:find("piece") ~= nil or
            src:find("shape") ~= nil or
            src:find("PIECES") ~= nil,
            "No tetromino/piece definition found")
    end)

    it("has grid or board data structure", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("grid") ~= nil or
            src:find("board") ~= nil or
            src:find("field") ~= nil,
            "No grid/board structure found")
    end)

    it("uses gravity timer for piece fall", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("gravity") ~= nil or
            src:find("fall") ~= nil or
            src:find("timer") ~= nil or
            src:find("drop") ~= nil,
            "No fall timer found     pieces won't drop automatically")
    end)

    it("has rotate action binding or logic", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("rotat") ~= nil or
            src:find('"up"') ~= nil or
            src:find('"z"') ~= nil or
            src:find('"x"') ~= nil,
            "No rotation found     tetris pieces cannot be rotated")
    end)

    it("has line clear logic", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("clear") ~= nil or
            src:find("line") ~= nil or
            src:find("full") ~= nil,
            "No line clear logic found")
    end)
end)
test_summary()
