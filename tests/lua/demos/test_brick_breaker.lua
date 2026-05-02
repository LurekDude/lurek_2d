-- tests/lua/content/demos/test_brick_breaker.lua
-- Smoke test for content/games/action/brick_breaker/main.lua.

local DEMO_PATH = "content/games/action/brick_breaker/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("brick_breaker", DEMO_PATH)

describe("brick_breaker: mechanics checks", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("has paddle that follows mouse or left/right input", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("getMousePosition%s*%(") ~= nil or
            src:find("isActionDown%s*%(") ~= nil,
            "No paddle control input found")
    end)

    it("has ball with velocity", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("ball") ~= nil and
            (src:find("vel") ~= nil or src:find("speed") ~= nil or src:find("dx") ~= nil),
            "No ball with velocity found")
    end)

    it("has brick grid data", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("brick") ~= nil or
            src:find("block") ~= nil or
            src:find("tile") ~= nil,
            "No brick/block data found")
    end)

    it("has collision detection between ball and bricks", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("collide") ~= nil or
            src:find("hit") ~= nil or
            src:find("intersect") ~= nil or
            src:find("overlap") ~= nil,
            "No collision detection found     ball passes through bricks")
    end)

    it("has lives or fail condition", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("lives") ~= nil or
            src:find("life") ~= nil or
            src:find("game_over") ~= nil or
            src:find("SCREEN_H") ~= nil,
            "No failure condition found     ball falling below screen is unhandled")
    end)
end)
test_summary()
