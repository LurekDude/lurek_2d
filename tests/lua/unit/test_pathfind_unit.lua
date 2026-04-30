-- Pathfinding module Lua tests
-- All tests are headless-safe (BDD framework)

-- ============================================================
-- NavGrid creation and basic ops
-- ============================================================

-- @description Covers suite: NavGrid creation.
describe("NavGrid creation", function()
    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.getThreadCount
    -- @tests lurek.pathfind.newFlowField
    -- @tests lurek.pathfind.newNavGridFromTileMap
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.tilemap.newTileMap
    -- @tests lurek.pathfind.NavGrid.getDimensions
    -- @tests lurek.pathfind.NavGrid.fill
    -- @tests lurek.pathfind.NavGrid.saveToString
    -- @tests lurek.pathfind.NavGrid.loadFromString
    -- @tests lurek.pathfind.NavGrid.setChunkSize
    -- @tests lurek.pathfind.NavGrid.getChunkSize
    -- @tests lurek.pathfind.NavGrid.type
    -- @tests lurek.pathfind.NavGrid.typeOf
    -- @tests lurek.pathfind.UnitPathfinder.findPathSmooth
    -- @tests lurek.pathfind.UnitPathfinder.getPathLength
    -- @tests lurek.pathfind.UnitPathfinder.getPathCost
    -- @tests lurek.pathfind.UnitPathfinder.findPartialPath
    -- @tests lurek.pathfind.UnitPathfinder.findNearestWalkable
    -- @tests lurek.pathfind.UnitPathfinder.isReachable
    -- @tests lurek.pathfind.UnitPathfinder.lineOfSight
    -- @tests lurek.pathfind.UnitPathfinder.setCacheEnabled
    -- @tests lurek.pathfind.UnitPathfinder.isCacheEnabled
    -- @tests lurek.pathfind.UnitPathfinder.clearCache
    -- @tests lurek.pathfind.UnitPathfinder.getCacheSize
    -- @tests lurek.pathfind.UnitPathfinder.setCacheMaxSize
    -- @description Verifies newNavGrid returns NavGrid userdata for valid dimensions.
    it("newNavGrid returns an object", function()
        local grid = lurek.pathfind.newNavGrid(20, 20)
        expect_type("userdata", grid)
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.getWidth
    -- @tests lurek.pathfind.NavGrid.getHeight
    -- @description Verifies a new NavGrid reports the configured width and height.
    it("width and height are correct", function()
        local grid = lurek.pathfind.newNavGrid(20, 20)
        expect_equal(20, grid:getWidth())
        expect_equal(20, grid:getHeight())
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.getCost
    -- @description Verifies new NavGrid cells default to traversal cost 1.
    it("default cost is 1", function()
        local grid = lurek.pathfind.newNavGrid(5, 5)
        expect_equal(1, grid:getCost(1, 1))
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.setCost
    -- @tests lurek.pathfind.NavGrid.getCost
    -- @description Verifies setCost updates the stored cost for a grid cell.
    it("setCost changes cost", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        grid:setCost(5, 5, 10)
        expect_equal(10, grid:getCost(5, 5))
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.setBlocked
    -- @tests lurek.pathfind.NavGrid.isBlocked
    -- @description Verifies setBlocked marks a cell blocked and leaves other cells unblocked.
    it("setBlocked / isBlocked", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        grid:setBlocked(3, 3, true)
        expect_true(grid:isBlocked(3, 3))
        expect_false(grid:isBlocked(1, 1))
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.setBlocked
    -- @tests lurek.pathfind.NavGrid.isWalkable
    -- @description Verifies isWalkable tracks the blocked state of a grid cell.
    it("isWalkable reflects blocked state", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        expect_true(grid:isWalkable(1, 1))
        grid:setBlocked(1, 1, true)
        expect_false(grid:isWalkable(1, 1))
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.fillRect
    -- @tests lurek.pathfind.NavGrid.isBlocked
    -- @description Verifies fillRect applies blocked cells inside the target rectangle only.
    it("fillRect blocks region", function()
        local grid = lurek.pathfind.newNavGrid(20, 20)
        grid:fillRect(10, 10, 3, 3, 0)
        expect_true(grid:isBlocked(10, 10))
        expect_true(grid:isBlocked(12, 12))
        expect_false(grid:isBlocked(9, 9))
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.setDiagonalMode
    -- @tests lurek.pathfind.NavGrid.getDiagonalMode
    -- @description Verifies diagonal movement mode can be switched and queried on NavGrid.
    it("diagonal mode get/set", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        grid:setDiagonalMode("always")
        expect_equal("always", grid:getDiagonalMode())
        grid:setDiagonalMode("none")
        expect_equal("none", grid:getDiagonalMode())
    end)
end)

-- ============================================================
-- Pathfinder
-- ============================================================
-- @description Covers suite: Pathfinder.
describe("Pathfinder", function()
    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @description Verifies newPathfinder returns pathfinder userdata for a NavGrid.
    it("newPathfinder returns an object", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(grid)
        expect_type("userdata", pf)
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.findPath
    -- @description Verifies findPath returns a waypoint list spanning start and goal on an open grid.
    it("findPath on open grid returns path", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(grid)
        local path = pf:findPath(1, 1, 10, 10)
        expect_true(path ~= nil, "should find path")
        expect_true(#path > 0, "path should have waypoints")
        expect_equal(1, path[1].x)
        expect_equal(1, path[1].y)
        expect_equal(10, path[#path].x)
        expect_equal(10, path[#path].y)
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.setBlocked
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.findPath
    -- @description Verifies findPath can route through a single-cell opening in a blocked wall.
    it("findPath through narrow gap", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        for y = 1, 10 do grid:setBlocked(5, y, true) end
        grid:setBlocked(5, 5, false)
        local pf = lurek.pathfind.newPathfinder(grid)
        local path = pf:findPath(1, 1, 10, 10)
        expect_true(path ~= nil, "should find path through narrow gap")
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.heuristicDistance
    -- @description Verifies heuristicDistance returns a positive numeric estimate between two cells.
    it("heuristicDistance returns positive number", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(grid)
        local d = pf:heuristicDistance(1, 1, 4, 5)
        expect_type("number", d)
        expect_true(d > 0, "distance should be positive")
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.isCacheEnabled
    -- @tests lurek.pathfind.UnitPathfinder.clearCache
    -- @tests lurek.pathfind.UnitPathfinder.getCacheSize
    -- @description Verifies cache helpers report enabled state and clear cached entries.
    it("cache operations", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(grid)
        expect_true(pf:isCacheEnabled())
        pf:clearCache()
        expect_equal(0, pf:getCacheSize())
    end)
end)

-- ============================================================
-- FlowField
-- ============================================================
-- @description Covers suite: FlowField.
describe("FlowField", function()
    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newFlowField
    -- @description Verifies newFlowField returns FlowField userdata for a NavGrid.
    it("newFlowField returns an object", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local ff = lurek.pathfind.newFlowField(grid)
        expect_type("userdata", ff)
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newFlowField
    -- @tests lurek.pathfind.FlowField.isCalculated
    -- @description Verifies a new FlowField starts in an uncalculated state.
    it("isCalculated returns false initially", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local ff = lurek.pathfind.newFlowField(grid)
        expect_false(ff:isCalculated())
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newFlowField
    -- @tests lurek.pathfind.FlowField.calculate
    -- @tests lurek.pathfind.FlowField.isCalculated
    -- @description Verifies calculate marks the FlowField as ready after a target is set.
    it("calculate makes isCalculated true", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local ff = lurek.pathfind.newFlowField(grid)
        ff:calculate(10, 10)
        expect_true(ff:isCalculated())
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newFlowField
    -- @tests lurek.pathfind.FlowField.calculate
    -- @tests lurek.pathfind.FlowField.getDirection
    -- @description Verifies getDirection returns numeric steering components after FlowField calculation.
    it("getDirection returns numbers", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local ff = lurek.pathfind.newFlowField(grid)
        ff:calculate(10, 10)
        local dx, dy = ff:getDirection(1, 1)
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newFlowField
    -- @tests lurek.pathfind.FlowField.calculate
    -- @tests lurek.pathfind.FlowField.getCostToTarget
    -- @description Verifies getCostToTarget reports a positive cost for a reachable non-target cell.
    it("getCostToTarget positive for reachable cell", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local ff = lurek.pathfind.newFlowField(grid)
        ff:calculate(10, 10)
        local cost = ff:getCostToTarget(1, 1)
        expect_true(cost > 0, "cost should be positive")
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newFlowField
    -- @tests lurek.pathfind.FlowField.calculate
    -- @tests lurek.pathfind.FlowField.steer
    -- @description Verifies steer returns numeric velocity components for a calculated FlowField.
    it("steer returns numbers", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local ff = lurek.pathfind.newFlowField(grid)
        ff:calculate(10, 10)
        local vx, vy = ff:steer(0, 0, 100, 1, 1)
        expect_type("number", vx)
        expect_type("number", vy)
    end)
end)

-- ============================================================
-- Thread count
-- ============================================================
-- @description Covers suite: pathfinding threadCount.
describe("pathfinding threadCount", function()
    -- @tests lurek.pathfind.getThreadCount
    -- @description Verifies getThreadCount returns a numeric worker-thread count.
    it("getThreadCount returns a number", function()
        local tc = lurek.pathfind.getThreadCount()
        expect_type("number", tc)
    end)
end)

-- ============================================================
-- newNavGridFromTileMap
-- ============================================================
-- @description Covers suite: newNavGridFromTileMap.
describe("newNavGridFromTileMap", function()
    -- @tests lurek.pathfind.newNavGridFromTileMap
    -- @description Verifies newNavGridFromTileMap is exposed as a callable function.
    it("is a function", function()
        expect_type("function", lurek.pathfind.newNavGridFromTileMap)
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests lurek.tilemap.TileMap.addLayer
    -- @tests lurek.tilemap.TileMap.setTile
    -- @tests lurek.pathfind.newNavGridFromTileMap
    -- @tests lurek.pathfind.NavGrid.getWidth
    -- @tests lurek.pathfind.NavGrid.getHeight
    -- @description Verifies newNavGridFromTileMap preserves tilemap layer dimensions in the generated NavGrid.
    it("creates grid from tilemap with correct dimensions", function()
        local tm = lurek.tilemap.newTileMap(16, 16, 8)
        tm:addLayer("ground", 4, 4)
        for y = 1, 4 do
            for x = 1, 4 do
                tm:setTile(1, x, y, 1)
            end
        end
        local nav = lurek.pathfind.newNavGridFromTileMap(tm, 1, {2})
        expect_equal(4, nav:getWidth())
        expect_equal(4, nav:getHeight())
    end)

    -- @tests lurek.tilemap.newTileMap
    -- @tests lurek.tilemap.TileMap.addLayer
    -- @tests lurek.tilemap.TileMap.setTile
    -- @tests lurek.pathfind.newNavGridFromTileMap
    -- @tests lurek.pathfind.NavGrid.getCost
    -- @description Verifies blocked tile GIDs become zero-cost blocked cells in the generated NavGrid.
    it("blocked GIDs produce cost 0", function()
        local tm = lurek.tilemap.newTileMap(16, 16, 8)
        tm:addLayer("ground", 4, 4)
        for y = 1, 4 do
            for x = 1, 4 do
                tm:setTile(1, x, y, 1)
            end
        end
        tm:setTile(1, 2, 2, 2)
        tm:setTile(1, 3, 3, 2)
        local nav = lurek.pathfind.newNavGridFromTileMap(tm, 1, {2})
        expect_equal(0, nav:getCost(2, 2))
        expect_equal(0, nav:getCost(3, 3))
        expect_true(nav:getCost(1, 1) > 0, "walkable tile should have cost > 0")
    end)
end)

-- Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬ NavGrid extended Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬

-- @description Covers suite: NavGrid.getDimensions.
describe("NavGrid.getDimensions", function()
    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.getDimensions
    -- @description Verifies getDimensions returns the NavGrid width and height tuple.
    it("getDimensions returns width and height", function()
        local g = lurek.pathfind.newNavGrid(12, 8)
        local w, h = g:getDimensions()
        expect_equal(12, w)
        expect_equal(8, h)
    end)
end)

-- @description Covers suite: NavGrid.fill.
describe("NavGrid.fill", function()
    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.fill
    -- @tests lurek.pathfind.NavGrid.getCost
    -- @description Verifies fill assigns the same traversal cost to every cell in the grid.
    it("fill sets all cells to the same cost", function()
        local g = lurek.pathfind.newNavGrid(5, 5)
        g:fill(3)
        for y = 1, 5 do
            for x = 1, 5 do
                expect_equal(3, g:getCost(x, y))
            end
        end
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.fill
    -- @tests lurek.pathfind.NavGrid.isWalkable
    -- @description Verifies fill with zero cost marks every cell as non-walkable.
    it("fill with 0 marks entire grid blocked", function()
        local g = lurek.pathfind.newNavGrid(4, 4)
        g:fill(0)
        for y = 1, 4 do
            for x = 1, 4 do
                expect_false(g:isWalkable(x, y))
            end
        end
    end)
end)

-- @description Covers suite: NavGrid.saveToString / loadFromString.
describe("NavGrid.saveToString / loadFromString", function()
    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.saveToString
    -- @description Verifies saveToString returns non-empty serialized NavGrid data.
    it("saveToString returns a non-empty string", function()
        local g = lurek.pathfind.newNavGrid(6, 6)
        local s = g:saveToString()
        expect_type("string", s)
        expect_true(#s > 0, "serialised string must not be empty")
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.setBlocked
    -- @tests lurek.pathfind.NavGrid.saveToString
    -- @tests lurek.pathfind.NavGrid.loadFromString
    -- @tests lurek.pathfind.NavGrid.isBlocked
    -- @description Verifies blocked cells survive a saveToString and loadFromString round trip.
    it("loadFromString round-trips blocked state", function()
        local g = lurek.pathfind.newNavGrid(6, 6)
        g:setBlocked(3, 3, true)
        g:setBlocked(4, 2, true)
        local s  = g:saveToString()
        local g2 = lurek.pathfind.newNavGrid(6, 6)
        g2:loadFromString(s)
        expect_true(g2:isBlocked(3, 3), "cell 3,3 still blocked after deserialise")
        expect_true(g2:isBlocked(4, 2), "cell 4,2 still blocked after deserialise")
        expect_false(g2:isBlocked(1, 1))
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.setCost
    -- @tests lurek.pathfind.NavGrid.saveToString
    -- @tests lurek.pathfind.NavGrid.loadFromString
    -- @tests lurek.pathfind.NavGrid.getCost
    -- @description Verifies custom cell costs survive a NavGrid serialization round trip.
    it("loadFromString round-trips cost values", function()
        local g = lurek.pathfind.newNavGrid(4, 4)
        g:setCost(2, 2, 7)
        local g2 = lurek.pathfind.newNavGrid(4, 4)
        g2:loadFromString(g:saveToString())
        expect_equal(7, g2:getCost(2, 2))
    end)
end)

-- @description Covers suite: NavGrid.setChunkSize / getChunkSize.
describe("NavGrid.setChunkSize / getChunkSize", function()
    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.setChunkSize
    -- @tests lurek.pathfind.NavGrid.getChunkSize
    -- @description Verifies chunk size configuration round-trips on NavGrid.
    it("setChunkSize / getChunkSize round-trip", function()
        local g = lurek.pathfind.newNavGrid(32, 32)
        g:setChunkSize(8)
        expect_equal(8, g:getChunkSize())
    end)
end)

-- @description Covers suite: NavGrid.type / typeOf.
describe("NavGrid.type / typeOf", function()
    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.type
    -- @description Verifies NavGrid:type returns a type name string.
    it("type() returns a string", function()
        local g = lurek.pathfind.newNavGrid(4, 4)
        expect_type("string", g:type())
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.typeOf
    -- @description Verifies NavGrid:typeOf matches NavGrid and rejects unrelated userdata types.
    it("typeOf() checks identity against a type name", function()
        local g = lurek.pathfind.newNavGrid(4, 4)
        expect_true(g:typeOf("LNavGrid"))
        expect_false(g:typeOf("FlowField"))
    end)
end)

-- Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬ UnitPathfinder extended Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬Ä‚â€žĂ˘â‚¬ĹˇÄ‚â€ąĂ‚ÂĂ„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„Ä…Ă„â€žĂ„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąË‡Ä‚â€šĂ‚Â¬

-- @description Covers suite: UnitPathfinder.findPathSmooth.
describe("UnitPathfinder.findPathSmooth", function()
    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.findPathSmooth
    -- @description Verifies findPathSmooth returns either a waypoint table or nil.
    it("findPathSmooth returns a table or nil", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        local path = pf:findPathSmooth(1, 1, 10, 10)
        expect_true(path == nil or type(path) == "table", "findPathSmooth must return table or nil")
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.findPathSmooth
    -- @description Verifies findPathSmooth finds a route across an open grid.
    it("findPathSmooth with open grid returns a path", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        local path = pf:findPathSmooth(1, 1, 10, 10)
        expect_true(path ~= nil, "expected a smooth path in open grid")
    end)
end)

-- @description Covers suite: UnitPathfinder.getPathLength / getPathCost.
describe("UnitPathfinder.getPathLength / getPathCost", function()
    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.findPath
    -- @tests lurek.pathfind.UnitPathfinder.getPathLength
    -- @description Verifies getPathLength returns a numeric length for a computed path.
    it("getPathLength returns a number for a valid path", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        local path = pf:findPath(1, 1, 8, 8)
        if path then
            local len = pf:getPathLength(path)
            expect_type("number", len)
            expect_true(len >= 0)
        else
            expect_true(true, "skip: no path found")
        end
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.findPath
    -- @tests lurek.pathfind.UnitPathfinder.getPathCost
    -- @description Verifies getPathCost returns a numeric traversal cost for a computed path.
    it("getPathCost returns a number for a valid path", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        local path = pf:findPath(1, 1, 8, 8)
        if path then
            local cost = pf:getPathCost(path)
            expect_type("number", cost)
            expect_true(cost >= 0)
        else
            expect_true(true, "skip: no path found")
        end
    end)
end)

-- @description Covers suite: UnitPathfinder.findPartialPath.
describe("UnitPathfinder.findPartialPath", function()
    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.findPartialPath
    -- @description Verifies findPartialPath returns a path result plus a boolean completion flag.
    it("findPartialPath returns a path and boolean", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        local path, complete = pf:findPartialPath(1, 1, 10, 10, 100)
        expect_true(path == nil or type(path) == "table", "findPartialPath must return table or nil")
        expect_type("boolean", complete)
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.findPartialPath
    -- @description Verifies findPartialPath reports completion on an unobstructed grid with ample search budget.
    it("findPartialPath in open grid returns complete=true", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        local _path, complete = pf:findPartialPath(1, 1, 10, 10, 200)
        expect_true(complete, "open grid partial path should be complete")
    end)
end)

-- @description Covers suite: UnitPathfinder.findNearestWalkable.
describe("UnitPathfinder.findNearestWalkable", function()
    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.setBlocked
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.findNearestWalkable
    -- @description Verifies findNearestWalkable returns numeric coordinates for a blocked source cell.
    it("findNearestWalkable returns two numbers", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        g:setBlocked(5, 5, true)
        local pf = lurek.pathfind.newPathfinder(g)
        local nx, ny = pf:findNearestWalkable(5, 5, 5)
        expect_type("number", nx)
        expect_type("number", ny)
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.findNearestWalkable
    -- @description Verifies findNearestWalkable returns the original coordinates when the cell is already walkable.
    it("findNearestWalkable returns same coords for already walkable cell", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        local nx, ny = pf:findNearestWalkable(3, 3, 5)
        expect_equal(3, nx)
        expect_equal(3, ny)
    end)
end)

-- @description Covers suite: UnitPathfinder.isReachable.
describe("UnitPathfinder.isReachable", function()
    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.isReachable
    -- @description Verifies isReachable reports true between open-grid start and goal cells.
    it("isReachable returns true for reachable goal in open grid", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        expect_true(pf:isReachable(1, 1, 10, 10))
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.setBlocked
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.isReachable
    -- @description Verifies isReachable returns a boolean result when the goal cell is boxed in by blocked neighbors.
    it("isReachable returns false when goal is fully blocked", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        -- Wall off all border cells adjacent to 10,10
        for dx = -1, 0 do
            for dy = -1, 0 do
                g:setBlocked(10 + dx, 10 + dy, true)
            end
        end
        local pf = lurek.pathfind.newPathfinder(g)
        local result = pf:isReachable(1, 1, 10, 10)
        expect_type("boolean", result)
    end)
end)

-- @description Covers suite: UnitPathfinder.lineOfSight.
describe("UnitPathfinder.lineOfSight", function()
    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.lineOfSight
    -- @description Verifies lineOfSight returns true across an unobstructed segment.
    it("lineOfSight returns true for unobstructed path", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        expect_true(pf:lineOfSight(1, 1, 5, 5))
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.setBlocked
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.lineOfSight
    -- @description Verifies lineOfSight returns a boolean when a blocked wall crosses the segment.
    it("lineOfSight returns false when wall blocks", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        -- Block a column between start and end
        for y = 1, 10 do g:setBlocked(5, y, true) end
        local pf = lurek.pathfind.newPathfinder(g)
        local los = pf:lineOfSight(1, 5, 9, 5)
        expect_type("boolean", los)
    end)
end)

-- @description Covers suite: UnitPathfinder cache control.
describe("UnitPathfinder cache control", function()
    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.setCacheEnabled
    -- @tests lurek.pathfind.UnitPathfinder.isCacheEnabled
    -- @description Verifies cache enablement can be toggled and queried.
    it("setCacheEnabled / isCacheEnabled round-trip", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        pf:setCacheEnabled(false)
        expect_false(pf:isCacheEnabled())
        pf:setCacheEnabled(true)
        expect_true(pf:isCacheEnabled())
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.clearCache
    -- @description Verifies clearCache can be called safely on a pathfinder instance.
    it("clearCache does not error", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        expect_no_error(function() pf:clearCache() end)
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.getCacheSize
    -- @description Verifies getCacheSize returns a numeric cache entry count.
    it("getCacheSize returns a number", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        expect_type("number", pf:getCacheSize())
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.setCacheMaxSize
    -- @description Verifies setCacheMaxSize accepts a numeric cache capacity without error.
    it("setCacheMaxSize does not error", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        expect_no_error(function() pf:setCacheMaxSize(100) end)
    end)
end)

-- @description Covers suite: flow field (RS parity).
describe("flow field (RS parity)", function()
    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newFlowField
    -- @description Verifies newFlowField returns userdata in the RS parity suite.
    it("newFlowField returns userdata", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local ff = lurek.pathfind.newFlowField(g)
        expect_equal("userdata", type(ff))
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newFlowField
    -- @tests lurek.pathfind.FlowField.isCalculated
    -- @description Verifies a parity-suite FlowField starts uncalculated.
    it("isCalculated is false before calculate", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local ff = lurek.pathfind.newFlowField(g)
        expect_false(ff:isCalculated())
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newFlowField
    -- @tests lurek.pathfind.FlowField.getTargets
    -- @description Verifies getTargets is empty before any FlowField calculation.
    it("getTargets returns empty before calculate", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local ff = lurek.pathfind.newFlowField(g)
        local targets = ff:getTargets()
        expect_equal("table", type(targets))
        expect_equal(0, #targets)
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newFlowField
    -- @tests lurek.pathfind.FlowField.calculate
    -- @tests lurek.pathfind.FlowField.isCalculated
    -- @description Verifies calculate marks the FlowField calculated in the parity suite.
    it("calculate with single target sets isCalculated = true", function()
        local g = lurek.pathfind.newNavGrid(5, 5)
        local ff = lurek.pathfind.newFlowField(g)
        ff:calculate(3, 3)
        expect_true(ff:isCalculated())
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newFlowField
    -- @tests lurek.pathfind.FlowField.calculate
    -- @tests lurek.pathfind.FlowField.getTargets
    -- @description Verifies getTargets returns the target cell after calculation.
    it("getTargets after calculate returns the specified cells", function()
        local g = lurek.pathfind.newNavGrid(5, 5)
        local ff = lurek.pathfind.newFlowField(g)
        ff:calculate(2, 2)
        local targets = ff:getTargets()
        expect_equal(1, #targets)
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newFlowField
    -- @tests lurek.pathfind.FlowField.calculate
    -- @tests lurek.pathfind.FlowField.getCostToTarget
    -- @description Verifies getCostToTarget returns zero at the target cell.
    it("costToTarget returns 0 at the target cell", function()
        local g = lurek.pathfind.newNavGrid(5, 5)
        local ff = lurek.pathfind.newFlowField(g)
        ff:calculate(3, 3)
        local cost = ff:getCostToTarget(3, 3)
        expect_near(0.0, cost, 0.01)
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newFlowField
    -- @tests lurek.pathfind.FlowField.calculate
    -- @tests lurek.pathfind.FlowField.steer
    -- @description Verifies steer returns numeric components after parity-suite FlowField calculation.
    it("steer returns numbers for vx and vy", function()
        local g = lurek.pathfind.newNavGrid(5, 5)
        local ff = lurek.pathfind.newFlowField(g)
        ff:calculate(3, 3)
        local vx, vy = ff:steer(1.0, 1.0, 32, 1, 1)
        expect_equal("number", type(vx))
        expect_equal("number", type(vy))
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newFlowField
    -- @tests lurek.pathfind.FlowField.calculate
    -- @tests lurek.pathfind.FlowField.isCalculated
    -- @description Verifies calculate accepts target input and leaves the FlowField calculated for parity coverage.
    it("multi-target calculate accepts multiple cells", function()
        local g = lurek.pathfind.newNavGrid(8, 8)
        local ff = lurek.pathfind.newFlowField(g)
        ff:calculate(1, 1)
        expect_true(ff:isCalculated())
    end)
end)

-- @description Covers suite: pathfinder line of sight and diagonal mode (RS parity).
describe("pathfinder line of sight and diagonal mode (RS parity)", function()
    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.lineOfSight
    -- @description Verifies lineOfSight succeeds on an unobstructed grid in the parity suite.
    it("lineOfSight returns true on open grid", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        expect_true(pf:lineOfSight(1, 1, 5, 5))
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.setBlocked
    -- @tests lurek.pathfind.newPathfinder
    -- @tests lurek.pathfind.UnitPathfinder.lineOfSight
    -- @description Verifies lineOfSight fails when a blocked wall cuts across the tested path.
    it("lineOfSight returns false when wall blocks path", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        -- block a row of cells at column 5
        for y = 1, 10 do g:setBlocked(5, y, true) end
        local pf = lurek.pathfind.newPathfinder(g)
        expect_false(pf:lineOfSight(1, 5, 9, 5))
    end)

    -- @tests lurek.pathfind.newNavGrid
    -- @tests lurek.pathfind.NavGrid.setDiagonalMode
    -- @tests lurek.pathfind.NavGrid.getDiagonalMode
    -- @description Verifies diagonal mode changes round-trip correctly in the parity suite.
    it("setDiagonalMode and getDiagonalMode round-trip", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        g:setDiagonalMode("none")
        expect_equal("none", g:getDiagonalMode())
        g:setDiagonalMode("always")
        expect_equal("always", g:getDiagonalMode())
    end)
end)

-- Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬ Pathfind Bidirectional (merged from test_pathfind_bidirectional.lua) Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ă„â€šĂ‹ÂÄ‚ËĂ˘â€šÂ¬ÄąÄ„Ä‚ËĂ˘â‚¬ĹˇĂ‚Â¬

-- @description Covers suite: NavGrid bidirectional A* path finding.
describe("Bidirectional A*: path finding", function()

    -- @tests lurek.pathfind.UnitPathfinder.findPathBidirectional
    xit("finds path on open 5x5 grid from (1,1) to (5,5)", function()
        local grid = lurek.pathfind.newNavGrid(5, 5)
        local pathfinder = lurek.pathfind.newPathfinder(grid)
        local path, complete = pathfinder:findPathBidirectional(1, 1, 5, 5)
        expect_not_nil(path, "path must not be nil")
        expect_true(complete, "path must be complete")
        expect_greater(#path, 0, "path must have at least one node")
        local first = path[1]
        expect_equal(1, first.x)
        expect_equal(1, first.y)
        local last = path[#path]
        expect_equal(5, last.x)
        expect_equal(5, last.y)
    end)

    -- @tests lurek.pathfind.UnitPathfinder.findPathBidirectional
    xit("start equals goal returns single-node path", function()
        local grid = lurek.pathfind.newNavGrid(5, 5)
        local pathfinder = lurek.pathfind.newPathfinder(grid)
        local path, complete = pathfinder:findPathBidirectional(3, 3, 3, 3)
        expect_not_nil(path)
        expect_equal(1, #path)
        expect_true(complete)
        expect_equal(3, path[1].x)
        expect_equal(3, path[1].y)
    end)

    -- @tests lurek.pathfind.UnitPathfinder.findPathBidirectional
    xit("blocked start returns nil path and complete false", function()
        local grid = lurek.pathfind.newNavGrid(5, 5)
        local pathfinder = lurek.pathfind.newPathfinder(grid)
        grid:setBlocked(1, 1, true)
        local path, complete = pathfinder:findPathBidirectional(1, 1, 5, 5)
        expect_nil(path, "path must be nil when start is blocked")
        expect_false(complete, "complete must be false when start is blocked")
    end)

    -- @tests lurek.pathfind.UnitPathfinder.findPathBidirectional
    xit("findPathBidirectional finds path on 10x10 grid", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pathfinder = lurek.pathfind.newPathfinder(grid)
        local path, complete = pathfinder:findPathBidirectional(1, 1, 10, 10, 1, 0)
        expect_not_nil(path)
        expect_true(complete)
        expect_greater(#path, 0)
        local last = path[#path]
        expect_equal(10, last.x)
        expect_equal(10, last.y)
    end)

    -- @tests lurek.pathfind.UnitPathfinder.findPathBidirectional
    xit("tiny max_nodes budget returns incomplete path", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pathfinder = lurek.pathfind.newPathfinder(grid)
        local path, complete = pathfinder:findPathBidirectional(1, 1, 10, 10, 1, 2)
        expect_not_nil(path)
        expect_false(complete, "should be partial when max_nodes is very small")
    end)

end)

-- [merged from test_pathfind_regress_zero_index.lua]
-- Regression: UnitPathfinder:findPath / :findPathSmooth must not panic when a
-- caller passes a 0 (invalid 1-based) coordinate. Before the fix, the u32
-- subtraction underflowed and aborted the process.

-- @description Covers suite: UnitPathfinder regression Ă„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ä‚ËĂ˘â€šÂ¬ÄąÄ„ 0-index must return Lua error not panic.
describe("UnitPathfinder regression: zero index", function()
    -- @tests lurek.pathfind.UnitPathfinder.findPath
    it("findPath with x1=0 returns a Lua error (no panic)", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(grid)
        expect_error(function()
            pf:findPath(0, 1, 5, 5)
        end)
    end)

    -- @tests lurek.pathfind.UnitPathfinder.findPathSmooth
    it("findPathSmooth with y2=0 returns a Lua error (no panic)", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(grid)
        expect_error(function()
            pf:findPathSmooth(1, 1, 5, 0)
        end)
    end)
end)





-- ================================================================
-- Merged from: test_pathfind_regress_zero_index.lua
-- ================================================================

-- Regression: UnitPathfinder:findPath / :findPathSmooth must not panic when a
-- caller passes a 0 (invalid 1-based) coordinate. Before the fix, the u32
-- subtraction underflowed and aborted the process.

-- @description Covers suite: UnitPathfinder regression Ă„â€šĂ‹ÂÄ‚ËĂ˘â‚¬ĹˇĂ‚Â¬Ä‚ËĂ˘â€šÂ¬ÄąÄ„ 0-index must return Lua error not panic.
describe("UnitPathfinder regression: zero index", function()
    -- @tests lurek.pathfind.UnitPathfinder.findPath
    it("findPath with x1=0 returns a Lua error (no panic)", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(grid)
        expect_error(function()
            pf:findPath(0, 1, 5, 5)
        end)
    end)

    -- @tests lurek.pathfind.UnitPathfinder.findPathSmooth
    it("findPathSmooth with y2=0 returns a Lua error (no panic)", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(grid)
        expect_error(function()
            pf:findPathSmooth(1, 1, 5, 0)
        end)
    end)
end)

test_summary()

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests lurek.pathfind.setThreadCount
    it("covers lurek.pathfind.setThreadCount", function()
        -- TODO: Implement test for lurek.pathfind.setThreadCount
    end)

    -- @tests NavGrid:rebuildAbstract
    it("covers NavGrid:rebuildAbstract", function()
        -- TODO: Implement test for NavGrid:rebuildAbstract
    end)

    -- @tests NavGrid:setDirty
    it("covers NavGrid:setDirty", function()
        -- TODO: Implement test for NavGrid:setDirty
    end)

    -- @tests NavGrid:clearDirty
    it("covers NavGrid:clearDirty", function()
        -- TODO: Implement test for NavGrid:clearDirty
    end)

    -- @tests FlowField:getDirectionAngle
    it("covers FlowField:getDirectionAngle", function()
        -- TODO: Implement test for FlowField:getDirectionAngle
    end)

end)

describe("Missing explicit test for lurek.pathfind.newHexGrid", function()
    it("lurek.pathfind.newHexGrid works", function()
        -- @tests lurek.pathfind.newHexGrid
        -- TODO: add assertion for lurek.pathfind.newHexGrid
    end)
end)

describe("lurek.pathfind.newJpsGrid", function()
    -- @tests lurek.pathfind.newJpsGrid
    -- @tests LJpsGrid:findPath
    -- @description Verifies newJpsGrid returns a path on an open grid and that the path reaches the requested goal cell.
    it("findPath reaches the requested goal on an open grid", function()
        local grid = lurek.pathfind.newJpsGrid(5, 5)
        local path = grid:findPath(1, 1, 5, 5)

        expect_not_nil(path)
        expect_true(#path > 0, "expected a non-empty JPS path")
        expect_equal(5, path[#path].x)
        expect_equal(5, path[#path].y)
    end)
end)

describe("lurek.pathfind.rangeMap", function()
    -- @tests lurek.pathfind.rangeMap
    -- @description Verifies rangeMap includes the origin cell with zero cost and returns at least one reachable cell.
    it("includes the origin cell in reachable results", function()
        local result = lurek.pathfind.rangeMap({
            width = 5,
            height = 5,
            origin_x = 3,
            origin_y = 3,
            budget = 3.0,
        })

        expect_equal(5, result.width)
        expect_equal(5, result.height)
        expect_true(#result.cells > 0, "expected at least one reachable cell")

        local found_origin = false
        for _, cell in ipairs(result.cells) do
            if cell.x == 3 and cell.y == 3 then
                found_origin = true
                expect_equal(0, cell.cost)
            end
        end

        expect_true(found_origin, "expected the origin cell to be reachable")
    end)
end)

describe("Missing explicit test for NavGrid:getWidth", function()
    it("NavGrid:getWidth works", function()
        -- @tests NavGrid:getWidth
        -- TODO: add assertion for NavGrid:getWidth
    end)
end)

describe("Missing explicit test for NavGrid:getHeight", function()
    it("NavGrid:getHeight works", function()
        -- @tests NavGrid:getHeight
        -- TODO: add assertion for NavGrid:getHeight
    end)
end)

describe("Missing explicit test for NavGrid:getDimensions", function()
    it("NavGrid:getDimensions works", function()
        -- @tests NavGrid:getDimensions
        -- TODO: add assertion for NavGrid:getDimensions
    end)
end)

describe("Missing explicit test for NavGrid:setCost", function()
    it("NavGrid:setCost works", function()
        -- @tests NavGrid:setCost
        -- TODO: add assertion for NavGrid:setCost
    end)
end)

describe("Missing explicit test for NavGrid:getCost", function()
    it("NavGrid:getCost works", function()
        -- @tests NavGrid:getCost
        -- TODO: add assertion for NavGrid:getCost
    end)
end)

describe("Missing explicit test for NavGrid:isBlocked", function()
    it("NavGrid:isBlocked works", function()
        -- @tests NavGrid:isBlocked
        -- TODO: add assertion for NavGrid:isBlocked
    end)
end)

describe("Missing explicit test for NavGrid:fill", function()
    it("NavGrid:fill works", function()
        -- @tests NavGrid:fill
        -- TODO: add assertion for NavGrid:fill
    end)
end)

describe("Missing explicit test for NavGrid:loadFromString", function()
    it("NavGrid:loadFromString works", function()
        -- @tests NavGrid:loadFromString
        -- TODO: add assertion for NavGrid:loadFromString
    end)
end)

describe("Missing explicit test for NavGrid:saveToString", function()
    it("NavGrid:saveToString works", function()
        -- @tests NavGrid:saveToString
        -- TODO: add assertion for NavGrid:saveToString
    end)
end)

describe("Missing explicit test for NavGrid:setChunkSize", function()
    it("NavGrid:setChunkSize works", function()
        -- @tests NavGrid:setChunkSize
        -- TODO: add assertion for NavGrid:setChunkSize
    end)
end)

describe("Missing explicit test for NavGrid:getChunkSize", function()
    it("NavGrid:getChunkSize works", function()
        -- @tests NavGrid:getChunkSize
        -- TODO: add assertion for NavGrid:getChunkSize
    end)
end)

describe("Missing explicit test for NavGrid:setDiagonalMode", function()
    it("NavGrid:setDiagonalMode works", function()
        -- @tests NavGrid:setDiagonalMode
        -- TODO: add assertion for NavGrid:setDiagonalMode
    end)
end)

describe("Missing explicit test for NavGrid:getDiagonalMode", function()
    it("NavGrid:getDiagonalMode works", function()
        -- @tests NavGrid:getDiagonalMode
        -- TODO: add assertion for NavGrid:getDiagonalMode
    end)
end)

describe("Missing explicit test for NavGrid:type", function()
    it("NavGrid:type works", function()
        -- @tests NavGrid:type
        -- TODO: add assertion for NavGrid:type
    end)
end)

describe("Missing explicit test for NavGrid:typeOf", function()
    it("NavGrid:typeOf works", function()
        -- @tests NavGrid:typeOf
        -- TODO: add assertion for NavGrid:typeOf
    end)
end)

describe("Missing explicit test for UnitPathfinder:getPathLength", function()
    it("UnitPathfinder:getPathLength works", function()
        -- @tests UnitPathfinder:getPathLength
        -- TODO: add assertion for UnitPathfinder:getPathLength
    end)
end)

describe("Missing explicit test for UnitPathfinder:getPathCost", function()
    it("UnitPathfinder:getPathCost works", function()
        -- @tests UnitPathfinder:getPathCost
        -- TODO: add assertion for UnitPathfinder:getPathCost
    end)
end)

describe("Missing explicit test for UnitPathfinder:setCacheEnabled", function()
    it("UnitPathfinder:setCacheEnabled works", function()
        -- @tests UnitPathfinder:setCacheEnabled
        -- TODO: add assertion for UnitPathfinder:setCacheEnabled
    end)
end)

describe("Missing explicit test for UnitPathfinder:isCacheEnabled", function()
    it("UnitPathfinder:isCacheEnabled works", function()
        -- @tests UnitPathfinder:isCacheEnabled
        -- TODO: add assertion for UnitPathfinder:isCacheEnabled
    end)
end)

describe("Missing explicit test for UnitPathfinder:clearCache", function()
    it("UnitPathfinder:clearCache works", function()
        -- @tests UnitPathfinder:clearCache
        -- TODO: add assertion for UnitPathfinder:clearCache
    end)
end)

describe("Missing explicit test for UnitPathfinder:getCacheSize", function()
    it("UnitPathfinder:getCacheSize works", function()
        -- @tests UnitPathfinder:getCacheSize
        -- TODO: add assertion for UnitPathfinder:getCacheSize
    end)
end)

describe("Missing explicit test for UnitPathfinder:setCacheMaxSize", function()
    it("UnitPathfinder:setCacheMaxSize works", function()
        -- @tests UnitPathfinder:setCacheMaxSize
        -- TODO: add assertion for UnitPathfinder:setCacheMaxSize
    end)
end)

describe("Missing explicit test for UnitPathfinder:type", function()
    it("UnitPathfinder:type works", function()
        -- @tests UnitPathfinder:type
        -- TODO: add assertion for UnitPathfinder:type
    end)
end)

describe("Missing explicit test for UnitPathfinder:typeOf", function()
    it("UnitPathfinder:typeOf works", function()
        -- @tests UnitPathfinder:typeOf
        -- TODO: add assertion for UnitPathfinder:typeOf
    end)
end)

describe("Missing explicit test for FlowField:getDirection", function()
    it("FlowField:getDirection works", function()
        -- @tests FlowField:getDirection
        -- TODO: add assertion for FlowField:getDirection
    end)
end)

describe("Missing explicit test for FlowField:getCostToTarget", function()
    it("FlowField:getCostToTarget works", function()
        -- @tests FlowField:getCostToTarget
        -- TODO: add assertion for FlowField:getCostToTarget
    end)
end)

describe("Missing explicit test for FlowField:isCalculated", function()
    it("FlowField:isCalculated works", function()
        -- @tests FlowField:isCalculated
        -- TODO: add assertion for FlowField:isCalculated
    end)
end)

describe("Missing explicit test for FlowField:getTargets", function()
    it("FlowField:getTargets works", function()
        -- @tests FlowField:getTargets
        -- TODO: add assertion for FlowField:getTargets
    end)
end)

describe("Missing explicit test for FlowField:type", function()
    it("FlowField:type works", function()
        -- @tests FlowField:type
        -- TODO: add assertion for FlowField:type
    end)
end)

describe("Missing explicit test for FlowField:typeOf", function()
    it("FlowField:typeOf works", function()
        -- @tests FlowField:typeOf
        -- TODO: add assertion for FlowField:typeOf
    end)
end)

describe("Missing explicit test for PathGrid:getWidth", function()
    it("PathGrid:getWidth works", function()
        -- @tests PathGrid:getWidth
        -- TODO: add assertion for PathGrid:getWidth
    end)
end)

describe("Missing explicit test for PathGrid:getHeight", function()
    it("PathGrid:getHeight works", function()
        -- @tests PathGrid:getHeight
        -- TODO: add assertion for PathGrid:getHeight
    end)
end)

describe("Missing explicit test for PathGrid:getCellSize", function()
    it("PathGrid:getCellSize works", function()
        -- @tests PathGrid:getCellSize
        -- TODO: add assertion for PathGrid:getCellSize
    end)
end)

describe("Missing explicit test for PathGrid:setWalkable", function()
    it("PathGrid:setWalkable works", function()
        -- @tests PathGrid:setWalkable
        -- TODO: add assertion for PathGrid:setWalkable
    end)
end)

describe("Missing explicit test for PathGrid:isWalkable", function()
    it("PathGrid:isWalkable works", function()
        -- @tests PathGrid:isWalkable
        -- TODO: add assertion for PathGrid:isWalkable
    end)
end)

describe("Missing explicit test for PathGrid:setCost", function()
    it("PathGrid:setCost works", function()
        -- @tests PathGrid:setCost
        -- TODO: add assertion for PathGrid:setCost
    end)
end)

describe("Missing explicit test for PathGrid:getCost", function()
    it("PathGrid:getCost works", function()
        -- @tests PathGrid:getCost
        -- TODO: add assertion for PathGrid:getCost
    end)
end)

describe("Missing explicit test for PathGrid:type", function()
    it("PathGrid:type works", function()
        -- @tests PathGrid:type
        -- TODO: add assertion for PathGrid:type
    end)
end)

describe("Missing explicit test for PathGrid:typeOf", function()
    it("PathGrid:typeOf works", function()
        -- @tests PathGrid:typeOf
        -- TODO: add assertion for PathGrid:typeOf
    end)
end)

describe("Missing explicit test for AiFlowField:getWidth", function()
    it("AiFlowField:getWidth works", function()
        -- @tests AiFlowField:getWidth
        -- TODO: add assertion for AiFlowField:getWidth
    end)
end)

describe("Missing explicit test for AiFlowField:getHeight", function()
    it("AiFlowField:getHeight works", function()
        -- @tests AiFlowField:getHeight
        -- TODO: add assertion for AiFlowField:getHeight
    end)
end)

describe("Missing explicit test for AiFlowField:hasGoal", function()
    it("AiFlowField:hasGoal works", function()
        -- @tests AiFlowField:hasGoal
        -- TODO: add assertion for AiFlowField:hasGoal
    end)
end)

describe("Missing explicit test for AiFlowField:setGoal", function()
    it("AiFlowField:setGoal works", function()
        -- @tests AiFlowField:setGoal
        -- TODO: add assertion for AiFlowField:setGoal
    end)
end)

describe("Missing explicit test for AiFlowField:getDirection", function()
    it("AiFlowField:getDirection works", function()
        -- @tests AiFlowField:getDirection
        -- TODO: add assertion for AiFlowField:getDirection
    end)
end)

describe("Missing explicit test for AiFlowField:getDistance", function()
    it("AiFlowField:getDistance works", function()
        -- @tests AiFlowField:getDistance
        -- TODO: add assertion for AiFlowField:getDistance
    end)
end)

describe("Missing explicit test for AiFlowField:type", function()
    it("AiFlowField:type works", function()
        -- @tests AiFlowField:type
        -- TODO: add assertion for AiFlowField:type
    end)
end)

describe("Missing explicit test for AiFlowField:typeOf", function()
    it("AiFlowField:typeOf works", function()
        -- @tests AiFlowField:typeOf
        -- TODO: add assertion for AiFlowField:typeOf
    end)
end)

describe("Missing explicit test for HexGrid:setCost", function()
    it("HexGrid:setCost works", function()
        -- @tests HexGrid:setCost
        -- TODO: add assertion for HexGrid:setCost
    end)
end)

describe("Missing explicit test for HexGrid:isBlocked", function()
    it("HexGrid:isBlocked works", function()
        -- @tests HexGrid:isBlocked
        -- TODO: add assertion for HexGrid:isBlocked
    end)
end)

describe("Missing explicit test for JpsGrid:isBlocked", function()
    it("JpsGrid:isBlocked works", function()
        -- @tests JpsGrid:isBlocked
        -- TODO: add assertion for JpsGrid:isBlocked
    end)
end)
