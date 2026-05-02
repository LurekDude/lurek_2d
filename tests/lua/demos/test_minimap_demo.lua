-- tests/lua/content/demos/test_minimap_demo.lua
-- Smoke test for content/games/showcase/minimap_demo/main.lua.

local DEMO_PATH = "content/games/showcase/minimap_demo/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("minimap_demo", DEMO_PATH)

describe("minimap_demo: minimap API usage", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("creates a minimap (lurek.minimap.new)", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("lurek%.minimap%.new%s*%(") ~= nil or
            src:find("lurek%.minimap%.create%s*%(") ~= nil,
            "No minimap creation call found")
    end)

    it("draws the minimap each render frame", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find(":draw%s*%(") ~= nil or
            src:find(":render%s*%(") ~= nil,
            "No minimap draw/render call found")
    end)

    it("updates the minimap or camera rect", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find(":update%s*%(") ~= nil or
            src:find(":setCamera%s*%(") ~= nil or
            src:find(":setViewport%s*%(") ~= nil,
            "No minimap update/setCamera call found")
    end)
end)
test_summary()
