-- tests/lua/content/demos/test_sprites.lua
-- Smoke test for content/games/showcase/sprites/main.lua.

local DEMO_PATH = "content/games/showcase/sprites/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("sprites", DEMO_PATH)

describe("sprites: sprite API usage", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("loads a sprite image (lurek.sprite.new or loadImage)", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("lurek%.sprite%.new") ~= nil or
            src:find("loadImage") ~= nil or
            src:find("lurek%.image%.load") ~= nil,
            "No sprite or image loading call found")
    end)

    it("draws sprites each frame", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find(":draw%s*%(") ~= nil or
            src:find("drawSprite") ~= nil or
            src:find("lurek%.render%.drawImage") ~= nil,
            "No draw call found for sprite rendering")
    end)

    it("does not use lurek.sprite.create (wrong factory)", function()
        expect_not_nil(src, 'source missing')
        expect_false(
            src:find("lurek%.sprite%.create%s*%(") ~= nil,
            "lurek.sprite.create() is invalid     use lurek.sprite.new()")
    end)
end)
test_summary()
