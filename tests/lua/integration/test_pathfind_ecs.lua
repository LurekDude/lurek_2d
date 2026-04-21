-- Lurek2D Integration Test: Pathfinding + Entity
-- Tests pathfinding results driving entity positioning

-- @description Covers suite: pathfinding + entity integration.
describe("pathfinding + entity integration", function()
    -- @covers lurek.pathfind.Grid.findPath
    -- @covers lurek.ecs.Universe.set
    -- @covers lurek.pathfind.newGrid
    -- @covers lurek.ecs.newUniverse
    -- @description Verifies path points produced by pathfinding can be applied directly to an entity's position.
    it("pathfinding result moves entity along path", function()
        local universe = lurek.ecs.newUniverse()
        local entity = universe:spawn()
        universe:set(entity, "x", 0)
        universe:set(entity, "y", 0)

        -- Create pathfinding grid
        local grid = lurek.pathfind.newGrid(10, 10)

        -- Find path from (0,0) to (9,9)
        local path = grid:findPath(0, 0, 9, 9)
        expect_true(path ~= nil, "path found")

        if path then
            local steps = path:getLength()
            expect_true(steps > 0, "path has steps: " .. steps)

            -- Move entity along first step
            local px, py = path:getPoint(0)
            universe:set(entity, "x", px)
            universe:set(entity, "y", py)

            local ex = universe:get(entity, "x")
            expect_equal(px, ex, "entity x matches path point")
        end
    end)

    -- @covers lurek.pathfind.Grid.setWalkable
    -- @covers lurek.ecs
    -- @description Verifies blocked cells force the computed route used by entities to take a longer detour.
    it("blocked cells force path around obstacle", function()
        local grid = lurek.pathfind.newGrid(10, 10)

        -- Block a wall
        for y = 0, 8 do
            grid:setWalkable(5, y, false)
        end

        local path = grid:findPath(0, 5, 9, 5)
        expect_true(path ~= nil, "path found around wall")

        if path then
            local len = path:getLength()
            -- Path around wall should be longer than direct
            expect_true(len > 9, "path is longer due to obstacle: " .. len)
        end
    end)

    -- @covers lurek.pathfind.Grid.findPath
    -- @covers lurek.ecs
    -- @description Verifies an unreachable goal returns no path instead of producing invalid movement data for entities.
    it("no path returns nil for unreachable goal", function()
        local grid = lurek.pathfind.newGrid(10, 10)

        -- Create enclosed area
        for x = 0, 9 do
            grid:setWalkable(x, 5, false)
        end

        local path = grid:findPath(0, 0, 0, 9)
        expect_true(path == nil, "no path to unreachable goal")
    end)

    -- @covers lurek.pathfind.Path.getPoint
    -- @covers lurek.ecs.Universe.set
    -- @description Verifies an entity can follow every waypoint in a multi-step path and end at the destination.
    it("entity follows multi-step path", function()
        local universe = lurek.ecs.newUniverse()
        local entity = universe:spawn()
        universe:set(entity, "x", 0)
        universe:set(entity, "y", 0)

        local grid = lurek.pathfind.newGrid(5, 5)
        local path = grid:findPath(0, 0, 4, 4)

        if path then
            -- Walk entire path
            for i = 0, path:getLength() - 1 do
                local px, py = path:getPoint(i)
                universe:set(entity, "x", px)
                universe:set(entity, "y", py)
            end

            -- Entity should be at destination
            local fx = universe:get(entity, "x")
            local fy = universe:get(entity, "y")
            expect_equal(4, fx, "entity reached x=4")
            expect_equal(4, fy, "entity reached y=4")
        end

        expect_true(universe:isAlive(entity), "entity survived path walk")
    end)
end)
test_summary()
