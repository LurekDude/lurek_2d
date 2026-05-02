-- tests/lua/content/demos/test_tower_defense.lua
-- Smoke test for content/games/strategy/tower_defense/main.lua.

local DEMO_PATH = "content/games/strategy/tower_defense/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("tower_defense", DEMO_PATH)

describe("tower_defense: mechanics checks", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("has tower placement mechanic", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("tower") ~= nil,
            "No tower reference found")
    end)

    it("has enemy wave or path system", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("enemy") ~= nil or
            src:find("wave") ~= nil or
            src:find("path") ~= nil,
            "No enemy/wave/path system found")
    end)

    it("has health or lives system", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("health") ~= nil or
            src:find("hp") ~= nil or
            src:find("lives") ~= nil,
            "No health/lives system found")
    end)

    it("has currency or resource system", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("gold") ~= nil or
            src:find("money") ~= nil or
            src:find("coin") ~= nil or
            src:find("resource") ~= nil or
            src:find("cost") ~= nil,
            "No currency/resource system found     towers can always be placed for free")
    end)

    it("has HUD rendering for game state", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("lurek%.render%.print%s*%(") ~= nil or
            src:find("lurek%.render%.drawText%s*%(") ~= nil,
            "No HUD text rendering found")
    end)
end)
test_summary()
