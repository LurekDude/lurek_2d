-- tests/lua/content/demos/test_demo_game.lua
-- Smoke test for content/games/showcase/demo_game/main.lua.

local DEMO_PATH = "content/games/showcase/demo_game/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("demo_game", DEMO_PATH)

describe("demo_game: shooting gallery API usage", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("binds shoot action to mouse button", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find('lurek%.input%.bind%s*%(%s*"shoot"') ~= nil or
            src:find("lurek%.input%.bind.*mouse") ~= nil,
            "No shoot action binding found")
    end)

    it("queries mouse position for crosshair", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("getMousePosition%s*%(") ~= nil,
            "getMousePosition() not called     crosshair will not track mouse")
    end)

    it("uses wasActionPressed to detect shots", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("wasActionPressed%s*%(") ~= nil,
            "wasActionPressed() not found     shooting input is unregistered")
    end)

    it("renders text score or game state", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("lurek%.render%.print%s*%(") ~= nil or
            src:find("lurek%.render%.drawText%s*%(") ~= nil,
            "No text rendering found     score HUD will not display")
    end)

    it("has lurek.render_ui callback for UI overlay", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("function%s+lurek%.render_ui%s*%(") ~= nil,
            "lurek.render_ui callback not found     UI HUD will not render")
    end)
end)
test_summary()
