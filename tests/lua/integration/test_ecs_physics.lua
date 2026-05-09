-- Integration: ECS entity positions synced with physics body state
describe("integration: entity + physics body lifecycle", function()
    -- @integration LUniverse:get
    -- @integration LUniverse:set
    -- @integration LUniverse:spawn
    -- @integration lurek.ecs.newUniverse
    -- @integration lurek.physics.destroyWorld
    -- @integration lurek.physics.newBody
    -- @integration lurek.physics.newWorld
    it("creates entity and attaches physics body in same world", function()
        local universe = lurek.ecs.newUniverse()
        local world    = lurek.physics.newWorld(0, 9.8)

        local id = universe:spawn()
        universe:set(id, "x", 100.0)
        universe:set(id, "y", 0.0)

        local body = lurek.physics.newBody(world, 100, 0, "dynamic")
        expect_not_nil(body, "physics body created")
        universe:set(id, "body_id", body)

        -- Verify body is stored AND retrieved correctly
        local stored_body = universe:get(id, "body_id")
        expect_equal(body, stored_body, "body stored and retrieved from entity")

        -- Verify entity position was set correctly
        local x = universe:get(id, "x")
        local y = universe:get(id, "y")
        expect_equal(100.0, x, "entity x position set correctly")
        expect_equal(0.0, y, "entity y position set correctly")

        lurek.physics.destroyWorld(world)
    end)

    -- @integration LUniverse:set
    -- @integration LUniverse:spawn
    -- @integration lurek.ecs.newUniverse
    -- @integration lurek.physics.destroyWorld
    -- @integration lurek.physics.getBody
    -- @integration lurek.physics.newBody
    -- @integration lurek.physics.newWorld
    -- @integration lurek.physics.step
    it("physics step moves dynamic body, entity position updated manually", function()
        local universe = lurek.ecs.newUniverse()
        local world    = lurek.physics.newWorld(0, 9.8)

        local id   = universe:spawn()
        local body = lurek.physics.newBody(world, 0, 0, "dynamic")

        -- Record initial position
        local init_x, init_y = lurek.physics.getBody(world, body)
        expect_equal(0, init_x, "body starts at x=0")
        expect_equal(0, init_y, "body starts at y=0")

        -- Step physics for 30 frames (0.5 seconds at 60fps)
        for _ = 1, 30 do
            lurek.physics.step(world, 1 / 60)
        end

        -- Read position back and verify gravity moved body down
        local px, py = lurek.physics.getBody(world, body)
        universe:set(id, "x", px)
        universe:set(id, "y", py)

        -- With gravity 9.8, body should have fallen down (y should be > 0)
        expect_true(py > 0, "body moved down under gravity (y > 0)")

        -- Verify entity position was synced
        local synced_y = universe:get(id, "y")
        expect_equal(py, synced_y, "physics position synced to entity")

        lurek.physics.destroyWorld(world)
    end)

    -- @integration LUniverse:kill
    -- @integration LUniverse:set
    -- @integration LUniverse:spawn
    -- @integration lurek.ecs.newUniverse
    -- @integration lurek.physics.destroyWorld
    -- @integration lurek.physics.newBody
    -- @integration lurek.physics.newWorld
    it("killing entity while physics body exists handles cleanup correctly", function()
        local universe = lurek.ecs.newUniverse()
        local world    = lurek.physics.newWorld(0, 0)

        local id   = universe:spawn()
        local body = lurek.physics.newBody(world, 50, 50, "static")
        universe:set(id, "body", body)

        -- Verify body was stored on entity
        local stored = universe:get(id, "body")
        expect_equal(body, stored, "body was stored on entity")

        -- Kill the entity
        universe:kill(id)

        -- Try to get the dead entity's data — should fail or return nil
        local dead_body = universe:get(id, "body")
        expect_equal(nil, dead_body, "dead entity returns nil for body")

        -- Cleanup physics world
        lurek.physics.destroyWorld(world)
    end)
end)
test_summary()
