-- Lurek2D Integration Test: Math + Physics
-- Tests that math functions work correctly with physics bodies
-- @covers lurek.math.atan2
-- @covers lurek.math.cos
-- @covers lurek.math.max
-- @covers lurek.math.min
-- @covers lurek.math.pi
-- @covers lurek.math.sin
-- @covers lurek.math.sqrt
-- @covers lurek.physics.destroyWorld
-- @covers lurek.physics.newBody
-- @covers lurek.physics.newWorld
-- @covers lurek.physics.step


describe("math + physics integration", function()
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

    it("physics step uses delta time correctly", function()
        local world_id = lurek.physics.newWorld(0, 100)
        local body_id = lurek.physics.newBody(world_id, 0, 0, "dynamic")

        -- Step the world a small amount
        lurek.physics.step(world_id, 0.016)

        -- Body should have moved down due to gravity
        local _, y = body_id:getPosition()
        expect_true(y > 0, "body moved down by gravity")

        lurek.physics.destroyWorld(world_id)
    end)
end)

describe("math + physics collision geometry", function()
    it("AABB overlap check using math", function()
        -- Two rectangles that overlap
        local ax, ay, aw, ah = 0, 0, 10, 10
        local bx, by, bw, bh = 5, 5, 10, 10

        -- Manual AABB overlap check using math
        local overlap_x = lurek.math.min(ax + aw, bx + bw) - lurek.math.max(ax, bx)
        local overlap_y = lurek.math.min(ay + ah, by + bh) - lurek.math.max(ay, by)

        expect_true(overlap_x > 0, "x overlap exists")
        expect_true(overlap_y > 0, "y overlap exists")
        expect_near(5, overlap_x, 0.001, "x overlap = 5")
        expect_near(5, overlap_y, 0.001, "y overlap = 5")
    end)
end)

describe("math trigonometry for physics angles", function()
    it("angle between two points", function()
        local x1, y1 = 0, 0
        local x2, y2 = 1, 1

        local angle = lurek.math.atan2(y2 - y1, x2 - x1)
        expect_near(lurek.math.pi / 4, angle, 0.001, "45 degree angle")
    end)

    it("rotate a velocity vector", function()
        local speed = 10
        local angle = math.rad(90)

        local vx = speed * lurek.math.cos(angle)
        local vy = speed * lurek.math.sin(angle)

        expect_near(0, vx, 0.001, "vx at 90 degrees")
        expect_near(10, vy, 0.001, "vy at 90 degrees")
    end)
end)
