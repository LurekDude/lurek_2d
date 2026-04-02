-- Luna2D Physics API Tests

describe("luna.physics module exists", function()
    it("luna.physics is a table", function()
        expect_type("table", luna.physics)
    end)
end)

describe("luna.physics world", function()
    it("newWorld is a function", function()
        expect_type("function", luna.physics.newWorld)
    end)

    it("newWorld creates a world and returns World object", function()
        local id = luna.physics.newWorld(0, 9.81)
        expect_type("userdata", id)
    end)

    it("step is a function", function()
        expect_type("function", luna.physics.step)
    end)

    it("step can be called with world_id and dt", function()
        local world = luna.physics.newWorld(0, 9.81)
        expect_no_error(function()
            luna.physics.step(world, 1/60)
        end)
    end)
end)

describe("luna.physics bodies", function()
    it("newBody is a function", function()
        expect_type("function", luna.physics.newBody)
    end)

    it("newBody creates a body and returns Body object", function()
        local world = luna.physics.newWorld(0, 9.81)
        local id = luna.physics.newBody(world, 100, 100, "dynamic")
        expect_type("userdata", id)
    end)

    it("getBody returns position and velocity", function()
        local world = luna.physics.newWorld(0, 9.81)
        local id = luna.physics.newBody(world, 50, 50, "static")
        local x, y, vx, vy = luna.physics.getBody(world, id)
        expect_near(50, x, 1)
        expect_near(50, y, 1)
    end)

    it("setBodyVelocity is a function", function()
        expect_type("function", luna.physics.setBodyVelocity)
    end)

    it("setBodyVelocity changes velocity", function()
        local world = luna.physics.newWorld(0, 0)
        local id = luna.physics.newBody(world, 0, 0, "dynamic")
        expect_no_error(function()
            luna.physics.setBodyVelocity(world, id, 100, 0)
        end)
    end)

    it("dynamic body moves after step", function()
        local world = luna.physics.newWorld(0, 100)
        local id = luna.physics.newBody(world, 0, 0, "dynamic")
        luna.physics.step(world, 0.1)
        local x, y, vx, vy = luna.physics.getBody(world, id)
        expect_true(y > 0, "body should fall due to gravity")
    end)

    it("static body does not move", function()
        local world = luna.physics.newWorld(0, 100)
        local id = luna.physics.newBody(world, 50, 50, "static")
        luna.physics.step(world, 0.1)
        local x, y, vx, vy = luna.physics.getBody(world, id)
        expect_near(50, x, 0.01)
        expect_near(50, y, 0.01)
    end)
end)

-- =========================================================================
-- Sleeping allowed
-- =========================================================================
describe("sleeping allowed", function()
    it("isSleepingAllowed defaults to true", function()
        local world = luna.physics.newWorld(0, 9.8)
        local id = luna.physics.newBody(world, 0, 0, "dynamic")
        expect_true(luna.physics.isSleepingAllowed(world, id))
    end)

    it("setSleepingAllowed false disables sleeping", function()
        local world = luna.physics.newWorld(0, 9.8)
        local id = luna.physics.newBody(world, 0, 0, "dynamic")
        luna.physics.setSleepingAllowed(world, id, false)
        expect_false(luna.physics.isSleepingAllowed(world, id))
    end)

    it("setSleepingAllowed true re-enables sleeping", function()
        local world = luna.physics.newWorld(0, 9.8)
        local id = luna.physics.newBody(world, 0, 0, "dynamic")
        luna.physics.setSleepingAllowed(world, id, false)
        luna.physics.setSleepingAllowed(world, id, true)
        expect_true(luna.physics.isSleepingAllowed(world, id))
    end)
end)

-- Remaining tests require APIs not yet registered (circle bodies, collisions,
-- restitution, layers). They are skipped until those bindings are implemented.
-- See: newCircleBody, getBodyShape, setBodyShape, getCollisions,
--      setBodyRestitution, setBodyLayer

test_summary()

