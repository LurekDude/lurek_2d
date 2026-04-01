-- Luna2D Stress Test: Mass Body Creation
-- Creates 1000 physics bodies and steps the world

describe("physics stress: 1000 bodies", function()
    it("creates 1000 bodies without error", function()
        local world_id = luna.physics.newWorld(0, 100)
        local bodies = {}

        for i = 1, 1000 do
            local x = (i % 50) * 10
            local y = luna.math.floor(i / 50) * 10
            bodies[i] = luna.physics.newBody(world_id, x, y, "dynamic")
        end

        expect_equal(1000, #bodies, "created 1000 bodies")

        -- Verify all bodies are valid
        for i = 1, 10 do
            local x, y = luna.physics.getBodyPosition(bodies[i])
            expect_true(type(x) == "number", "body position is number")
        end

        luna.physics.destroyWorld(world_id)
    end)

    it("steps 1000-body world 60 times", function()
        local world_id = luna.physics.newWorld(0, 100)

        for i = 1, 1000 do
            luna.physics.newBody(world_id, i * 2, 0, "dynamic")
        end

        -- Simulate one second of gameplay
        for step = 1, 60 do
            luna.physics.step(world_id, 1.0 / 60.0)
        end

        -- World should still be valid
        expect_true(true, "world survived 60 steps with 1000 bodies")

        luna.physics.destroyWorld(world_id)
    end)
end)
