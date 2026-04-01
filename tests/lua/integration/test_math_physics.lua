-- Luna2D Integration Test: Math + Physics
-- Tests that math functions work correctly with physics bodies

describe("math + physics integration", function()
    it("Vec2 can be used for body positions", function()
        local world_id = luna.physics.newWorld(0, 100)
        local body_id = luna.physics.newBody(world_id, 50, 50, "dynamic")

        -- Get position and verify it's numeric
        local x, y = luna.physics.getBodyPosition(body_id)
        expect_near(50, x, 0.1, "initial x")
        expect_near(50, y, 0.1, "initial y")

        -- Use math functions to compute new position
        local angle = luna.math.rad(45)
        local dx = luna.math.cos(angle) * 10
        local dy = luna.math.sin(angle) * 10

        luna.physics.setBodyPosition(body_id, x + dx, y + dy)

        local nx, ny = luna.physics.getBodyPosition(body_id)
        expect_near(50 + dx, nx, 0.1, "moved x")
        expect_near(50 + dy, ny, 0.1, "moved y")

        luna.physics.destroyWorld(world_id)
    end)

    it("distance formula works with body positions", function()
        local world_id = luna.physics.newWorld(0, 0)
        local b1 = luna.physics.newBody(world_id, 0, 0, "static")
        local b2 = luna.physics.newBody(world_id, 3, 4, "static")

        local x1, y1 = luna.physics.getBodyPosition(b1)
        local x2, y2 = luna.physics.getBodyPosition(b2)

        local dist = luna.math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
        expect_near(5.0, dist, 0.001, "3-4-5 triangle distance")

        luna.physics.destroyWorld(world_id)
    end)

    it("physics step uses delta time correctly", function()
        local world_id = luna.physics.newWorld(0, 100)
        local body_id = luna.physics.newBody(world_id, 0, 0, "dynamic")

        -- Step the world a small amount
        luna.physics.step(world_id, 0.016)

        -- Body should have moved down due to gravity
        local _, y = luna.physics.getBodyPosition(body_id)
        expect_true(y > 0, "body moved down by gravity")

        luna.physics.destroyWorld(world_id)
    end)
end)

describe("math + physics collision geometry", function()
    it("AABB overlap check using math", function()
        -- Two rectangles that overlap
        local ax, ay, aw, ah = 0, 0, 10, 10
        local bx, by, bw, bh = 5, 5, 10, 10

        -- Manual AABB overlap check using math
        local overlap_x = luna.math.min(ax + aw, bx + bw) - luna.math.max(ax, bx)
        local overlap_y = luna.math.min(ay + ah, by + bh) - luna.math.max(ay, by)

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

        local angle = luna.math.atan2(y2 - y1, x2 - x1)
        expect_near(luna.math.pi / 4, angle, 0.001, "45 degree angle")
    end)

    it("rotate a velocity vector", function()
        local speed = 10
        local angle = luna.math.rad(90)

        local vx = speed * luna.math.cos(angle)
        local vy = speed * luna.math.sin(angle)

        expect_near(0, vx, 0.001, "vx at 90 degrees")
        expect_near(10, vy, 0.001, "vy at 90 degrees")
    end)
end)
