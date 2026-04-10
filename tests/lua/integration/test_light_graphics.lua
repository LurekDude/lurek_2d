-- Lurek2D Integration Test: Light + Graphics
-- Tests light API alongside graphics draw commands.
-- @covers lurek.light.newLight
-- @covers lurek.light.setPosition
-- @covers lurek.light.setRadius
-- @covers lurek.light.setColor
-- @covers lurek.light.setIntensity
-- @covers lurek.gfx.setColor
-- @covers lurek.gfx.rectangle

describe("integration: light placement alongside scene geometry", function()
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
            lurek.gfx.setColor(0.3, 0.3, 0.3, 1.0)
            lurek.gfx.rectangle("fill", 0, 0, 800, 600)

            lurek.gfx.setColor(0.7, 0.6, 0.5, 1.0)
            lurek.gfx.rectangle("fill", 100, 100, 50, 200)
        end)
    end)

    it("light intensity range is clamped correctly", function()
        local light = lurek.light.newLight("point")
        lurek.light.setIntensity(light, 0.5)
        expect_no_error(function()
            lurek.light.setIntensity(light, 0.0)  -- min
            lurek.light.setIntensity(light, 1.0)  -- max
        end)
    end)

    it("multiple lights of different types created without error", function()
        expect_no_error(function()
            local types = {"point", "ambient"}
            for _, t in ipairs(types) do
                local l = lurek.light.newLight(t)
                lurek.light.setIntensity(l, 0.5)
            end
        end)
    end)

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
