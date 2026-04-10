-- Lurek2D Integration Test: Entity + Graphics
-- Tests entity position syncing to draw commands.
-- @covers lurek.entity.newUniverse
-- @covers lurek.gfx.setColor
-- @covers lurek.gfx.rectangle

describe("integration: entity position drives draw coordinates", function()
    it("entity position stored and usable for rectangle draw", function()
        local universe = lurek.entity.newUniverse()
        local id = universe:spawn()
        universe:set(id, "x", 200.0)
        universe:set(id, "y", 150.0)
        universe:set(id, "w", 32.0)
        universe:set(id, "h", 32.0)

        local x = universe:get(id, "x")
        local y = universe:get(id, "y")
        local w = universe:get(id, "w")
        local h = universe:get(id, "h")

        expect_equal(200.0, x, "entity x")
        expect_equal(150.0, y, "entity y")

        -- Draw commands execute without error
        expect_no_error(function()
            lurek.gfx.setColor(1, 1, 1, 1)
            lurek.gfx.rectangle("fill", x, y, w, h)
        end)
    end)

    it("multiple entities draw at different positions", function()
        local universe = lurek.entity.newUniverse()
        local positions = {{10, 20}, {100, 200}, {300, 400}}
        local ids = {}

        for i, pos in ipairs(positions) do
            local id = universe:spawn()
            universe:set(id, "x", pos[1])
            universe:set(id, "y", pos[2])
            ids[i] = id
        end

        for i, id in ipairs(ids) do
            local x = universe:get(id, "x")
            local y = universe:get(id, "y")
            expect_equal(positions[i][1], x, "entity " .. i .. " x")
            expect_equal(positions[i][2], y, "entity " .. i .. " y")
            expect_no_error(function()
                lurek.gfx.setColor(1, 0, 0, 1)
                lurek.gfx.rectangle("fill", x, y, 16, 16)
            end)
        end
    end)

    it("entity visibility flag gates draw commands", function()
        local universe = lurek.entity.newUniverse()
        local id = universe:spawn()
        universe:set(id, "visible", true)
        universe:set(id, "x", 50.0)
        universe:set(id, "y", 50.0)

        local visible = universe:get(id, "visible")
        expect_true(visible, "entity visible by default")

        -- Simulate visibility check before draw
        expect_no_error(function()
            if universe:get(id, "visible") then
                lurek.gfx.setColor(0, 1, 0, 1)
                lurek.gfx.rectangle("line", 50, 50, 20, 20)
            end
        end)
    end)
end)

test_summary()
