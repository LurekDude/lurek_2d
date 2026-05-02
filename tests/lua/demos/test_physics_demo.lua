-- tests/lua/content/demos/test_physics_demo.lua
-- Smoke test for content/games/simulation/physics_demo/main.lua.

local DEMO_PATH = "content/games/simulation/physics_demo/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("physics_demo", DEMO_PATH)

describe("physics_demo: physics API usage", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("creates physics bodies (lurek.physics.body)", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("lurek%.physics%.body") ~= nil or
            src:find("lurek%.physics%.new") ~= nil or
            src:find("lurek%.physics%.create") ~= nil or
            src:find("lurek%.physics%.rect") ~= nil or
            src:find("lurek%.physics%.circle") ~= nil,
            "No physics body creation found")
    end)

    it("uses a physics world (lurek.physics.world)", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("lurek%.physics%.world") ~= nil or
            src:find("lurek%.physics%.setGravity") ~= nil or
            src:find("lurek%.physics") ~= nil,
            "No physics world/gravity reference found")
    end)

    it("has a process_physics or physics update call", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("lurek%.process_physics") ~= nil or
            src:find("function%s+lurek%.process_physics") ~= nil or
            src:find("lurek%.physics%.step") ~= nil or
            src:find(":step%s*%(") ~= nil,
            "No physics step/update call found     physics won't simulate")
    end)

    it("does not call lurek.physics.update (wrong method)", function()
        expect_not_nil(src, 'source missing')
        expect_false(
            src:find("lurek%.physics%.update%s*%(") ~= nil,
            "lurek.physics.update() is invalid     use the process_physics callback or :step()")
    end)
end)
test_summary()
