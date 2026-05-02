-- tests/lua/content/demos/test_platformer.lua
-- Smoke test for content/games/action/platformer/main.lua.

local DEMO_PATH = "content/games/action/platformer/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("platformer", DEMO_PATH)

describe("platformer: mechanics checks", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("has left/right movement input", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            (src:find('"left"') ~= nil or src:find('"a"') ~= nil) and
            (src:find('"right"') ~= nil or src:find('"d"') ~= nil),
            "No left/right input bindings found")
    end)

    it("has jump mechanic", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("jump") ~= nil or
            src:find('"space"') ~= nil or
            src:find('"up"') ~= nil,
            "No jump mechanic found")
    end)

    it("has gravity or vertical velocity", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("gravity") ~= nil or
            src:find("vel_y") ~= nil or
            src:find("vy") ~= nil or
            src:find("velocity%.y") ~= nil,
            "No gravity/vertical velocity found     player will float")
    end)

    it("has ground collision or on_ground flag", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("on_ground") ~= nil or
            src:find("grounded") ~= nil or
            src:find("floor") ~= nil or
            src:find("collide") ~= nil,
            "No ground collision found     player will fall forever")
    end)

    it("has level or platform data", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("platform") ~= nil or
            src:find("level") ~= nil or
            src:find("tile") ~= nil or
            src:find("MAP") ~= nil,
            "No level/platform data found")
    end)
end)
test_summary()
