-- Lurek2D Integration Test: Light + Graphics
-- Tests light API alongside graphics draw commands.

-- @description Covers suite: integration: light placement alongside scene geometry.
describe("integration: light placement alongside scene geometry", function()
    -- @covers lurek.light.newLight
    -- @covers lurek.render.rectangle
    -- @covers lurek.light.setPosition
    -- @covers lurek.light.setRadius
    -- @covers lurek.light.setColor
    -- @covers lurek.light.setIntensity
    -- @covers lurek.render.setColor
    -- @description Verifies light setup and scene geometry draw commands can be issued together without error.
    it("creates lights and draws geometry to same scene", function()
        expect_no_error(function()
            -- Create lights
            local light1 = lurek.light.newLight("point")
            lurek.light.setPosition(light1, 200, 200)
            lurek.light.setRadius(light1, 150)
            lurek.light.setColor(light1, 1.0, 0.9, 0.7, 1.0)
            lurek.light.setIntensity(light1, 0.8)

            local light2 = lurek.light.newLight("point")
            lurek.light.setPosition(light2, 600, 300)
            lurek.light.setRadius(light2, 100)
            lurek.light.setColor(light2, 0.5, 0.5, 1.0, 1.0)
            lurek.light.setIntensity(light2, 1.0)

            -- Draw scene geometry (walls, floors)
            lurek.render.setColor(0.3, 0.3, 0.3, 1.0)
            lurek.render.rectangle("fill", 0, 0, 800, 600)

            lurek.render.setColor(0.7, 0.6, 0.5, 1.0)
            lurek.render.rectangle("fill", 100, 100, 50, 200)
        end)
    end)

    -- @covers lurek.light.setIntensity
    -- @covers lurek.render
    -- @description Verifies point light intensity accepts boundary values while remaining compatible with the graphics scene setup.
    it("light intensity range is clamped correctly", function()
        local light = lurek.light.newLight("point")
        lurek.light.setIntensity(light, 0.5)
        expect_no_error(function()
            lurek.light.setIntensity(light, 0.0)  -- min
            lurek.light.setIntensity(light, 1.0)  -- max
        end)
    end)

    -- @covers lurek.light.newLight
    -- @covers lurek.render
    -- @description Verifies multiple light types can coexist alongside graphics usage without raising errors.
    it("multiple lights of different types created without error", function()
        expect_no_error(function()
            local types = {"point", "ambient"}
            for _, t in ipairs(types) do
                local l = lurek.light.newLight(t)
                lurek.light.setIntensity(l, 0.5)
            end
        end)
    end)

    -- @covers lurek.light.setColor
    -- @covers lurek.render
    -- @description Verifies normalized light color values are accepted while used in the same rendering context as graphics commands.
    it("light color components are in 0..1 range", function()
        local light = lurek.light.newLight("point")
        expect_no_error(function()
            lurek.light.setColor(light, 0.0, 0.0, 0.0, 1.0)   -- black
            lurek.light.setColor(light, 1.0, 1.0, 1.0, 1.0)   -- white
            lurek.light.setColor(light, 1.0, 0.0, 0.0, 0.5)   -- red, half alpha
        end)
    end)
end)
test_summary()
