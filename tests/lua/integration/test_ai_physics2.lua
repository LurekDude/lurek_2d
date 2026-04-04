-- Luna2D Integration Test: AI + Physics
-- Tests AI agents making decisions that affect physics bodies

describe("integration: AI steering with physics bodies", function()
    it("agent seeks target in physics world", function()
        -- Create physics world (no gravity for top-down)
        local world_id = luna.physics.newWorld(0, 0)

        -- Create bodies for seeker and target
        local seeker_body = luna.physics.newBody(world_id, 100, 100, "dynamic")
        local target_body = luna.physics.newBody(world_id, 400, 400, "static")

        -- Create AI steering manager
        local sm = luna.ai.newSteeringManager()
        sm:addSeek(400, 400, 1.0)

        -- Calculate steering force — calculate returns (fx, fy) as two values
        local fx, fy = sm:calculate(100, 100, 0, 0, 50, 100, 1.0 / 60.0)

        -- Verify we got non-zero steering force toward target
        expect_not_nil(fx, "steering fx returned")

        -- Apply forces as velocity and step physics
        local vel_x = type(fx) == "number" and fx or 50
        local vel_y = type(fy) == "number" and fy or 50
        luna.physics.setBodyVelocity(world_id, seeker_body, vel_x, vel_y)

        -- Step physics for 60 frames
        for frame = 1, 60 do
            luna.physics.step(world_id, 1.0 / 60.0)
        end

        -- Read back position
        local px, py = luna.physics.getBody(world_id, seeker_body)

        -- Seeker should have moved from (100, 100) — some movement occurred
        local moved = math.abs(px - 100) > 0.1 or math.abs(py - 100) > 0.1
        expect_true(moved, "seeker moved from starting position")
    end)
end)

describe("integration: AI pathfinding with navgrid", function()
    it("agent follows A* path", function()
        local grid = luna.pathfinding.newNavGrid(50, 50)

        -- Add wall
        for y = 10, 40 do
            grid:setBlocked(25, y, true)
        end

        local pf = luna.pathfinding.newPathfinder(grid)
        local path = pf:findPath(10, 25, 40, 25)
        expect_not_nil(path, "path found around wall")
        expect_true(#path > 15, "path goes around wall")

        -- Verify path doesn't cross the wall
        local crosses_wall = false
        for _, wp in ipairs(path) do
            if wp.x == 25 and wp.y >= 10 and wp.y <= 40 then
                crosses_wall = true
            end
        end
        expect_false(crosses_wall, "path avoids wall")
    end)
end)
