-- Lurek2D Integration Test: Pathfinding + Entity
-- Tests pathfinding results driving entity positioning

describe("pathfinding + entity integration", function()
    it("pathfinding result moves entity along path", function()
        local universe = lurek.ecs.newUniverse()
        local entity = universe:spawn()
        universe:set(entity, "x", 0)
        universe:set(entity, "y", 0)

        -- Create pathfinding grid
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf   = lurek.pathfind.newPathfinder(grid)

        -- Find path from (1,1) to (10,10) in 1-based coords
        local path = pf:findPath(1, 1, 10, 10)
        expect_true(path ~= nil, "path found")

        if path then
            local steps = #path
            expect_true(steps > 0, "path has steps: " .. steps)

            -- Move entity along first step
            local px, py = path[1].x, path[1].y
            universe:set(entity, "x", px)
            universe:set(entity, "y", py)

            local ex = universe:get(entity, "x")
            expect_equal(px, ex, "entity x matches path point")
        end
    end)

    it("blocked cells force path around obstacle", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf   = lurek.pathfind.newPathfinder(grid)

        -- Block a wall at column 6 (1-based), rows 1-9
        for y = 1, 9 do
            grid:setBlocked(6, y, true)
        end

        local path = pf:findPath(1, 6, 10, 6)
        expect_true(path ~= nil, "path found around wall")

        if path then
            local len = #path
            -- Path around wall should be longer than direct
            expect_true(len > 9, "path is longer due to obstacle: " .. len)
        end
    end)

    it("no path returns nil for unreachable goal", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf   = lurek.pathfind.newPathfinder(grid)

        -- Block all of row 2 so (1,1) is trapped in row 1 and cannot reach (1,10)
        for x = 1, 10 do
            grid:setBlocked(x, 2, true)
        end

        local path = pf:findPath(1, 1, 1, 10)
        expect_true(path == nil, "no path to unreachable goal (got " .. tostring(path) .. ")")
    end)

    it("entity follows multi-step path", function()
        local universe = lurek.ecs.newUniverse()
        local entity = universe:spawn()
        universe:set(entity, "x", 0)
        universe:set(entity, "y", 0)

        local grid = lurek.pathfind.newNavGrid(5, 5)
        local pf   = lurek.pathfind.newPathfinder(grid)
        local path = pf:findPath(1, 1, 5, 5)

        if path then
            -- Walk entire path
            for i = 1, #path do
                local px, py = path[i].x, path[i].y
                universe:set(entity, "x", px)
                universe:set(entity, "y", py)
            end

            -- Entity should be at destination
            local fx = universe:get(entity, "x")
            local fy = universe:get(entity, "y")
            expect_equal(5, fx, "entity reached x=5")
            expect_equal(5, fy, "entity reached y=5")
        end

        expect_true(universe:isAlive(entity), "entity survived path walk")
    end)
end)
test_summary()
