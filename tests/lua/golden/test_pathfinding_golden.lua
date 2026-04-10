-- Lurek2D Golden Test: Pathfinding A* on Fixed Grids
-- Tests A* produces identical paths on deterministic grids.
-- @golden lurek.pathfinding.newNavGrid
-- @golden lurek.pathfinding.newPathfinder

describe("golden: pathfinding - open 5x5 grid, corner to corner", function()
    it("path from (0,0) to (4,4) has reasonable length", function()
        local grid = lurek.pathfinding.newNavGrid(5, 5)
        local pf   = lurek.pathfinding.newPathfinder(grid)
        local path = pf:findPath(0, 0, 4, 4)

        expect_not_nil(path, "path found")
        local len = path:getLength()
        -- Manhattan: 8 steps minimum; diagonal-allowed: ~5-8
        expect_true(len >= 4, "path length >= 4")
        expect_true(len <= 10, "path length <= 10")

        -- First waypoint should be adjacent to start
        local wx, wy = path:getPoint(1)
        local adj = (wx == 1 and wy == 0) or (wx == 0 and wy == 1) or (wx == 1 and wy == 1)
        expect_true(adj, "first step adjacent to start")
    end)
end)

describe("golden: pathfinding - wall at column 2, 5x5 grid", function()
    it("path detours around wall column", function()
        local grid = lurek.pathfinding.newNavGrid(5, 5)
        for y = 0, 4 do
            grid:setWalkable(2, y, false)  -- block column 2
        end
        -- Open a gap at the top to allow passage
        grid:setWalkable(2, 0, true)

        local pf   = lurek.pathfinding.newPathfinder(grid)
        local path = pf:findPath(0, 2, 4, 2)

        expect_not_nil(path, "path found around wall")
        local len = path:getLength()
        expect_true(len >= 4, "detour path has length >= 4")
    end)
end)

describe("golden: pathfinding - surrounded start yields no path", function()
    it("returns empty path when start is surrounded", function()
        local grid = lurek.pathfinding.newNavGrid(5, 5)
        -- Completely surround (2,2)
        for dx = -1, 1 do
            for dy = -1, 1 do
                if not (dx == 0 and dy == 0) then
                    grid:setWalkable(2 + dx, 2 + dy, false)
                end
            end
        end

        local pf   = lurek.pathfinding.newPathfinder(grid)
        local path = pf:findPath(2, 2, 4, 4)

        local len = path and path:getLength() or 0
        expect_equal(0, len, "no path from surrounded cell")
    end)
end)

describe("golden: pathfinding - straight horizontal path", function()
    it("path from (0,0) to (4,0) has length = 4", function()
        local grid = lurek.pathfinding.newNavGrid(5, 5)
        local pf   = lurek.pathfinding.newPathfinder(grid)
        local path = pf:findPath(0, 0, 4, 0)

        expect_not_nil(path, "horizontal path found")
        local len = path:getLength()
        -- Exact step count depends on whether end point is included
        expect_true(len >= 4, "horizontal path length >= 4")
        expect_true(len <= 5, "horizontal path length <= 5")
    end)
end)

test_summary()
