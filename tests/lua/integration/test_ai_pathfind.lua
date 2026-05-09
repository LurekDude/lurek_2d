-- Integration: AI state machine + pathfinding A*
describe("integration: AI agent uses pathfinding to navigate", function()
    -- @integration LStateMachine:addState
    -- @integration LStateMachine:addTransition
    -- @integration LStateMachine:forceState
    -- @integration LStateMachine:getCurrentState
    -- @integration LUnitPathfinder:findPath
    -- @integration lurek.ai.newStateMachine
    -- @integration lurek.pathfind.newNavGrid
    -- @integration lurek.pathfind.newPathfinder
    it("AI state machine requests path and transitions to moving state", function()
        local grid = lurek.pathfind.newNavGrid(20, 20)
        local pf   = lurek.pathfind.newPathfinder(grid)

        -- Find path from (1,1) to (6,6) on open grid (1-based coords)
        local path = pf:findPath(1, 1, 6, 6)
        expect_not_nil(path, "pathfinder returned a path")

        local path_len = #path
        expect_true(path_len > 0, "path has at least one step")

        -- Simulate AI state machine: IDLE -> MOVING
        local sm = lurek.ai.newStateMachine()
        sm:addState("IDLE",   { onUpdate = function() end })
        sm:addState("MOVING", { onUpdate = function() end })
        sm:addTransition("IDLE", "MOVING")
        sm:forceState("IDLE")
        expect_equal("IDLE", sm:getCurrentState(), "started in IDLE")

        -- Simulate: found path -> transition to MOVING
        if path_len > 0 then
            sm:forceState("MOVING")
        end
        expect_equal("MOVING", sm:getCurrentState(), "transitioned to MOVING after path found")
    end)

    -- @integration LUnitPathfinder:findPath
    -- @integration lurek.pathfind.newNavGrid
    -- @integration lurek.pathfind.newPathfinder
    it("AI agent follows path waypoints step by step", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf   = lurek.pathfind.newPathfinder(grid)

        local path = pf:findPath(1, 1, 10, 1)   -- straight line across top row
        expect_not_nil(path, "straight line path found")

        local len = #path
        expect_true(len >= 8, "straight-line path length >= 8 steps")

        -- Walk along path
        local prev_x = 1
        for step = 1, len do
            local wx, wy = path[step].x, path[step].y
            expect_not_nil(wx, "waypoint x at step " .. step)
            expect_not_nil(wy, "waypoint y at step " .. step)
            expect_true(wx >= prev_x, "x is non-decreasing on straight path")
            prev_x = wx
        end
    end)

    -- @integration LNavGrid:setBlocked
    -- @integration LUnitPathfinder:findPath
    -- @integration lurek.pathfind.newNavGrid
    -- @integration lurek.pathfind.newPathfinder
    it("AI requests path around wall, gets detour", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        -- Place vertical wall at column 5, rows 2..8
        for y = 2, 8 do
            grid:setBlocked(5, y, true)
        end
        local pf   = lurek.pathfind.newPathfinder(grid)
        local path = pf:findPath(1, 5, 10, 5)

        expect_not_nil(path, "path exists around wall")
        local len = #path
        expect_true(len > 8, "detour path is longer than straight line")
    end)
end)
test_summary()
