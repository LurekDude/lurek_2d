-- Lurek2D Integration Test: AI + Pathfinding
-- Tests AI agents requesting and following A* paths.
-- @covers lurek.ai.newStateMachine
-- @covers lurek.pathfinding.newNavGrid
-- @covers lurek.pathfinding.newPathfinder

describe("integration: AI agent uses pathfinding to navigate", function()
    it("AI state machine requests path and transitions to moving state", function()
        local grid = lurek.pathfinding.newNavGrid(20, 20)
        local pf   = lurek.pathfinding.newPathfinder(grid)

        -- Find path from (0,0) to (5,5) on open grid
        local path = pf:findPath(0, 0, 5, 5)
        expect_not_nil(path, "pathfinder returned a path")

        local path_len = path:getLength()
        expect_true(path_len > 0, "path has at least one step")

        -- Simulate AI state machine: IDLE → MOVING
        local sm = lurek.ai.newStateMachine()
        sm:addState("IDLE",   { onUpdate = function() end })
        sm:addState("MOVING", { onUpdate = function() end })
        sm:addTransition("IDLE", "MOVING")
        sm:forceState("IDLE")
        expect_equal("IDLE", sm:getCurrentState(), "started in IDLE")

        -- Simulate: found path → transition to MOVING
        if path_len > 0 then
            sm:forceState("MOVING")
        end
        expect_equal("MOVING", sm:getCurrentState(), "transitioned to MOVING after path found")
    end)

    it("AI agent follows path waypoints step by step", function()
        local grid = lurek.pathfinding.newNavGrid(10, 10)
        local pf   = lurek.pathfinding.newPathfinder(grid)

        local path = pf:findPath(0, 0, 9, 0)   -- straight line across top row
        expect_not_nil(path, "straight line path found")

        local len = path:getLength()
        expect_true(len >= 9, "straight-line path length >= 9 steps")

        -- Walk along path
        local prev_x = 0
        for step = 1, len do
            local wx, wy = path:getPoint(step)
            expect_not_nil(wx, "waypoint x at step " .. step)
            expect_not_nil(wy, "waypoint y at step " .. step)
            expect_true(wx >= prev_x, "x is non-decreasing on straight path")
            prev_x = wx
        end
    end)

    it("AI requests path around wall, gets detour", function()
        local grid = lurek.pathfinding.newNavGrid(10, 10)
        -- Place vertical wall at column 5 (except top and bottom row)
        for y = 1, 8 do
            grid:setWalkable(5, y, false)
        end
        local pf   = lurek.pathfinding.newPathfinder(grid)
        local path = pf:findPath(0, 5, 9, 5)

        expect_not_nil(path, "path exists around wall")
        local len = path:getLength()
        expect_true(len > 9, "detour path is longer than straight line (10)")
    end)
end)

test_summary()
