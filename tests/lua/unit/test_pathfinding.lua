-- Pathfinding module Lua tests
-- All tests are headless-safe (BDD framework)

-- ============================================================
-- NavGrid creation and basic ops
-- ============================================================
describe("NavGrid creation", function()
    it("newNavGrid returns an object", function()
        local grid = luna.pathfinding.newNavGrid(20, 20)
        expect_type("userdata", grid)
    end)

    it("width and height are correct", function()
        local grid = luna.pathfinding.newNavGrid(20, 20)
        expect_equal(20, grid:getWidth())
        expect_equal(20, grid:getHeight())
    end)

    it("default cost is 1", function()
        local grid = luna.pathfinding.newNavGrid(5, 5)
        expect_equal(1, grid:getCost(1, 1))
    end)

    it("setCost changes cost", function()
        local grid = luna.pathfinding.newNavGrid(10, 10)
        grid:setCost(5, 5, 10)
        expect_equal(10, grid:getCost(5, 5))
    end)

    it("setBlocked / isBlocked", function()
        local grid = luna.pathfinding.newNavGrid(10, 10)
        grid:setBlocked(3, 3, true)
        expect_true(grid:isBlocked(3, 3))
        expect_false(grid:isBlocked(1, 1))
    end)

    it("isWalkable reflects blocked state", function()
        local grid = luna.pathfinding.newNavGrid(10, 10)
        expect_true(grid:isWalkable(1, 1))
        grid:setBlocked(1, 1, true)
        expect_false(grid:isWalkable(1, 1))
    end)

    it("fillRect blocks region", function()
        local grid = luna.pathfinding.newNavGrid(20, 20)
        grid:fillRect(10, 10, 3, 3, 0)
        expect_true(grid:isBlocked(10, 10))
        expect_true(grid:isBlocked(12, 12))
        expect_false(grid:isBlocked(9, 9))
    end)

    it("diagonal mode get/set", function()
        local grid = luna.pathfinding.newNavGrid(10, 10)
        grid:setDiagonalMode("always")
        expect_equal("always", grid:getDiagonalMode())
        grid:setDiagonalMode("none")
        expect_equal("none", grid:getDiagonalMode())
    end)
end)

-- ============================================================
-- Pathfinder
-- ============================================================
describe("Pathfinder", function()
    it("newPathfinder returns an object", function()
        local grid = luna.pathfinding.newNavGrid(10, 10)
        local pf = luna.pathfinding.newPathfinder(grid)
        expect_type("userdata", pf)
    end)

    it("findPath on open grid returns path", function()
        local grid = luna.pathfinding.newNavGrid(10, 10)
        local pf = luna.pathfinding.newPathfinder(grid)
        local path = pf:findPath(1, 1, 10, 10)
        expect_true(path ~= nil, "should find path")
        expect_true(#path > 0, "path should have waypoints")
        expect_equal(1, path[1].x)
        expect_equal(1, path[1].y)
        expect_equal(10, path[#path].x)
        expect_equal(10, path[#path].y)
    end)

    it("findPath through narrow gap", function()
        local grid = luna.pathfinding.newNavGrid(10, 10)
        for y = 1, 10 do grid:setBlocked(5, y, true) end
        grid:setBlocked(5, 5, false)
        local pf = luna.pathfinding.newPathfinder(grid)
        local path = pf:findPath(1, 1, 10, 10)
        expect_true(path ~= nil, "should find path through narrow gap")
    end)

    it("heuristicDistance returns positive number", function()
        local grid = luna.pathfinding.newNavGrid(10, 10)
        local pf = luna.pathfinding.newPathfinder(grid)
        local d = pf:heuristicDistance(1, 1, 4, 5)
        expect_type("number", d)
        expect_true(d > 0, "distance should be positive")
    end)

    it("cache operations", function()
        local grid = luna.pathfinding.newNavGrid(10, 10)
        local pf = luna.pathfinding.newPathfinder(grid)
        expect_true(pf:isCacheEnabled())
        pf:clearCache()
        expect_equal(0, pf:getCacheSize())
    end)
end)

-- ============================================================
-- FlowField
-- ============================================================
describe("FlowField", function()
    it("newFlowField returns an object", function()
        local grid = luna.pathfinding.newNavGrid(10, 10)
        local ff = luna.pathfinding.newFlowField(grid)
        expect_type("userdata", ff)
    end)

    it("isCalculated returns false initially", function()
        local grid = luna.pathfinding.newNavGrid(10, 10)
        local ff = luna.pathfinding.newFlowField(grid)
        expect_false(ff:isCalculated())
    end)

    it("calculate makes isCalculated true", function()
        local grid = luna.pathfinding.newNavGrid(10, 10)
        local ff = luna.pathfinding.newFlowField(grid)
        ff:calculate(10, 10)
        expect_true(ff:isCalculated())
    end)

    it("getDirection returns numbers", function()
        local grid = luna.pathfinding.newNavGrid(10, 10)
        local ff = luna.pathfinding.newFlowField(grid)
        ff:calculate(10, 10)
        local dx, dy = ff:getDirection(1, 1)
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    it("getCostToTarget positive for reachable cell", function()
        local grid = luna.pathfinding.newNavGrid(10, 10)
        local ff = luna.pathfinding.newFlowField(grid)
        ff:calculate(10, 10)
        local cost = ff:getCostToTarget(1, 1)
        expect_true(cost > 0, "cost should be positive")
    end)

    it("steer returns numbers", function()
        local grid = luna.pathfinding.newNavGrid(10, 10)
        local ff = luna.pathfinding.newFlowField(grid)
        ff:calculate(10, 10)
        local vx, vy = ff:steer(0, 0, 100, 1, 1)
        expect_type("number", vx)
        expect_type("number", vy)
    end)
end)

-- ============================================================
-- Thread count
-- ============================================================
describe("pathfinding threadCount", function()
    it("getThreadCount returns a number", function()
        local tc = luna.pathfinding.getThreadCount()
        expect_type("number", tc)
    end)
end)

-- ============================================================
-- newNavGridFromTileMap
-- ============================================================
describe("newNavGridFromTileMap", function()
    it("is a function", function()
        expect_type("function", luna.pathfinding.newNavGridFromTileMap)
    end)

    it("creates grid from tilemap with correct dimensions", function()
        local tm = luna.tilemap.newTileMap(16, 16, 8)
        tm:addLayer("ground", 4, 4)
        for y = 1, 4 do
            for x = 1, 4 do
                tm:setTile(1, x, y, 1)
            end
        end
        local nav = luna.pathfinding.newNavGridFromTileMap(tm, 1, {2})
        expect_equal(4, nav:getWidth())
        expect_equal(4, nav:getHeight())
    end)

    it("blocked GIDs produce cost 0", function()
        local tm = luna.tilemap.newTileMap(16, 16, 8)
        tm:addLayer("ground", 4, 4)
        for y = 1, 4 do
            for x = 1, 4 do
                tm:setTile(1, x, y, 1)
            end
        end
        tm:setTile(1, 2, 2, 2)
        tm:setTile(1, 3, 3, 2)
        local nav = luna.pathfinding.newNavGridFromTileMap(tm, 1, {2})
        expect_equal(0, nav:getCost(2, 2))
        expect_equal(0, nav:getCost(3, 3))
        expect_true(nav:getCost(1, 1) > 0, "walkable tile should have cost > 0")
    end)
end)

test_summary()
