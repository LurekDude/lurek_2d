-- Integration: math utility functions used alongside physics body state
describe("math + physics integration", function()
    -- @integration LBody:getPosition
    -- @integration LBody:setPosition
    -- @integration lurek.math.cos
    -- @integration lurek.math.sin
    -- @integration lurek.physics.destroyWorld
    -- @integration lurek.physics.newBody
    -- @integration lurek.physics.newWorld
    it("Vec2 can be used for body positions", function()
        local world_id = lurek.physics.newWorld(0, 100)
        local body_id = lurek.physics.newBody(world_id, 50, 50, "dynamic")

        -- Get position and verify it's numeric
        local x, y = body_id:getPosition()
        expect_near(50, x, 0.1, "initial x")
        expect_near(50, y, 0.1, "initial y")

        -- Use math functions to compute new position
        local angle = math.rad(45)
        local dx = lurek.math.cos(angle) * 10
        local dy = lurek.math.sin(angle) * 10

        body_id:setPosition(x + dx, y + dy)

        local nx, ny = body_id:getPosition()
        expect_near(50 + dx, nx, 0.1, "moved x")
        expect_near(50 + dy, ny, 0.1, "moved y")

        lurek.physics.destroyWorld(world_id)
    end)

    -- @integration LBody:getPosition
    -- @integration lurek.math.sqrt
    -- @integration lurek.physics.destroyWorld
    -- @integration lurek.physics.newBody
    -- @integration lurek.physics.newWorld
    it("distance formula works with body positions", function()
        local world_id = lurek.physics.newWorld(0, 0)
        local b1 = lurek.physics.newBody(world_id, 0, 0, "static")
        local b2 = lurek.physics.newBody(world_id, 3, 4, "static")

        local x1, y1 = b1:getPosition()
        local x2, y2 = b2:getPosition()

        local dist = lurek.math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
        expect_near(5.0, dist, 0.001, "3-4-5 triangle distance")

        lurek.physics.destroyWorld(world_id)
    end)

end)

test_summary()
