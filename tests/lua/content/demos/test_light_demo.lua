-- tests/lua/content/demos/test_light_demo.lua
-- Smoke test for content/games/showcase/light_demo/main.lua.

local DEMO_PATH = "content/games/showcase/light_demo/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("light_demo", DEMO_PATH)

describe("light_demo: lighting API usage", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("creates a light source (lurek.light.new)", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find("lurek%.light%.new%s*%(") ~= nil or
            src:find("lurek%.light%.point%s*%(") ~= nil or
            src:find("lurek%.light%.spot%s*%(") ~= nil or
            src:find("lurek%.light%.ambient%s*%(") ~= nil,
            "No light creation call found")
    end)

    it("moves or animates a light in the process loop", function()
        if not src then pending("source missing") return end
        expect_true(
            src:find(":setPosition%s*%(") ~= nil or
            src:find(":moveTo%s*%(") ~= nil or
            src:find("%.x%s*=") ~= nil or
            src:find("%.y%s*=") ~= nil,
            "No light position update found — lights will be static")
    end)

    it("does not use lurek.lighting (old namespace)", function()
        if not src then pending("source missing") return end
        expect_false(
            src:find("lurek%.lighting") ~= nil,
            "Old namespace lurek.lighting found — use lurek.light")
    end)
end)
