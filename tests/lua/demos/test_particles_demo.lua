-- tests/lua/content/demos/test_particles_demo.lua
-- Smoke test for content/games/showcase/particles_demo/main.lua.

local DEMO_PATH = "content/games/showcase/particles_demo/main.lua"

dofile("tests/lua/content/demos/_common_checks.lua")
demo_common_checks("particles_demo", DEMO_PATH)

describe("particles_demo: particle API usage", function()
    local src

    before_each(function()
        local f = io.open(DEMO_PATH, "r")
        if f then src = f:read("*all"); f:close() end
    end)

    it("creates a particle system (lurek.particle.new)", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find("lurek%.particle%.new") ~= nil or
            src:find("lurek%.particle%.system") ~= nil,
            "No particle system creation call found")
    end)

    it("emits or updates particles each frame", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find(":emit%s*%(") ~= nil or
            src:find(":update%s*%(") ~= nil or
            src:find(":burst%s*%(") ~= nil,
            "No particle emit/update call found")
    end)

    it("draws particles each frame", function()
        expect_not_nil(src, 'source missing')
        expect_true(
            src:find(":draw%s*%(") ~= nil or
            src:find("lurek%.particle%.draw") ~= nil,
            "No particle draw call found")
    end)

    it("does not use lurek.particle.create (wrong factory)", function()
        expect_not_nil(src, 'source missing')
        expect_false(
            src:find("lurek%.particle%.create%s*%(") ~= nil,
            "lurek.particle.create() is invalid     use lurek.particle.new()")
    end)
end)
test_summary()
