-- tests/lua/content/demos/test_pac_man.lua
-- Smoke test for content/games/arcade/pac_man/main.lua.

local DEMO_PATH = "content/games/arcade/pac_man/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("pac_man", DEMO_PATH)

describe("pac_man: game mechanics", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("has maze or level data", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("maze") ~= nil or
            src:find("level") ~= nil or
            src:find("MAP") ~= nil or
            src:find("map") ~= nil,
            "No maze/level data found")
    end)

    it("has ghost entities", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("ghost") ~= nil or
            src:find("enemy") ~= nil,
            "No ghost/enemy found     there is no challenge")
    end)

    it("has dot or pellet collection", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("dot") ~= nil or
            src:find("pellet") ~= nil or
            src:find("food") ~= nil or
            src:find("coin") ~= nil,
            "No dots/pellets found     nothing to collect")
    end)

    it("has score system", function()
        expect_not_nil(src, 'source missing')
        expect_true(src:find("score") ~= nil, "No score variable found")
    end)

    it("has lives tracking", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("lives") ~= nil or
            src:find("life") ~= nil or
            src:find("lives") ~= nil,
            "No lives counter found")
    end)
end)
test_summary()
