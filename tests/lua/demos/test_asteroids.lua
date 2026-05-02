-- tests/lua/content/demos/test_asteroids.lua
-- Smoke test for content/games/arcade/asteroids/main.lua.

local DEMO_PATH = "content/games/arcade/asteroids/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("asteroids", DEMO_PATH)

describe("asteroids: game mechanics", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("has asteroid entities", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("asteroid") ~= nil or
            src:find("rock") ~= nil,
            "No asteroid entity found")
    end)

    it("has bullet or projectile system", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("bullet") ~= nil or
            src:find("projectile") ~= nil or
            src:find("shot") ~= nil,
            "No bullet/projectile found     player cannot shoot")
    end)

    it("has thrust and rotation controls", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("thrust") ~= nil or
            src:find("accelerat") ~= nil or
            src:find("rotat") ~= nil,
            "No thrust/rotation control found")
    end)

    it("has screen wrap-around logic", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("wrap") ~= nil or
            src:find("SCREEN_W") ~= nil or
            src:find("width") ~= nil,
            "No screen wrap-around found     objects will fly off screen")
    end)

    it("uses circle drawing for asteroids or ship", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("drawCircle%s*%(") ~= nil or
            src:find("drawPoly") ~= nil or
            src:find("drawLine") ~= nil,
            "No asteroid/ship geometry draw calls found")
    end)
end)
test_summary()
