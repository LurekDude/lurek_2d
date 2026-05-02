-- Lurek2D Integration Test: Entity + Physics
-- Tests physics bodies attached to entities and position sync.

describe("integration: entity + physics body lifecycle", function()
    it("creates entity and attaches physics body in same world", function()
        local universe = lurek.ecs.newUniverse()
        local world    = lurek.physics.newWorld(0, 9.8)

        local id = universe:spawn()
        universe:set(id, "x", 100.0)
        universe:set(id, "y", 0.0)

        local body = lurek.physics.newBody(world, 100, 0, "dynamic")
        expect_not_nil(body, "physics body created")
        universe:set(id, "body_id", body)

        expect_equal(body, universe:get(id, "body_id"), "body stored on entity")
        lurek.physics.destroyWorld(world)
    end)

    it("physics step moves dynamic body, entity position updated manually", function()
        local universe = lurek.ecs.newUniverse()
        local world    = lurek.physics.newWorld(0, 9.8)

        local id   = universe:spawn()
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")

        -- Step physics for 30 frames
        for _ = 1, 30 do
            lurek.physics.step(world, 1 / 60)
        end

        -- Read position back and sync to entity
        local px, py = lurek.physics.getBody(world, body)
        universe:set(id, "x", px)
        universe:set(id, "y", py)

        -- With gravity 9.8, body should have fallen down
        expect_true(py > 0 or py < 0, "body moved under gravity")
        lurek.physics.destroyWorld(world)
    end)

    it("killing entity while physics body exists does not crash", function()
        local universe = lurek.ecs.newUniverse()
        local world    = lurek.physics.newWorld(0, 0)

        local id   = universe:spawn()
        local body = lurek.physics.newBody(world, 50, 50, "static")
        universe:set(id, "body", body)

        universe:kill(id)
        lurek.physics.destroyWorld(world)
        -- Reaching here means no crash
        expect_true(true, "kill + destroy did not crash")
    end)
end)
test_summary()
