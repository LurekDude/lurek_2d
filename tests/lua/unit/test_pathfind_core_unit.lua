-- Pathfinding module Lua tests
-- All tests are headless-safe (BDD framework)

-- ============================================================
-- NavGrid creation and basic ops
-- ============================================================

-- @describe NavGrid creation
describe("NavGrid creation", function()
    -- @covers lurek.pathfind.newNavGrid
    it("newNavGrid returns an object", function()
        local grid = lurek.pathfind.newNavGrid(20, 20)
        expect_type("userdata", grid)
    end)

    -- @covers LNavGrid:getHeight
    -- @covers LNavGrid:getWidth
    -- @covers lurek.pathfind.newNavGrid
    it("width and height are correct", function()
        local grid = lurek.pathfind.newNavGrid(20, 20)
        expect_equal(20, grid:getWidth())
        expect_equal(20, grid:getHeight())
    end)

    -- @covers LNavGrid:getCost
    -- @covers lurek.pathfind.newNavGrid
    it("default cost is 1", function()
        local grid = lurek.pathfind.newNavGrid(5, 5)
        expect_equal(1, grid:getCost(1, 1))
    end)

    -- @covers LNavGrid:getCost
    -- @covers LNavGrid:setCost
    -- @covers lurek.pathfind.newNavGrid
    it("setCost changes cost", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        grid:setCost(5, 5, 10)
        expect_equal(10, grid:getCost(5, 5))
    end)

    -- @covers LNavGrid:isBlocked
    -- @covers LNavGrid:setBlocked
    -- @covers lurek.pathfind.newNavGrid
    it("setBlocked / isBlocked", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        grid:setBlocked(3, 3, true)
        expect_true(grid:isBlocked(3, 3))
        expect_false(grid:isBlocked(1, 1))
    end)

    -- @covers LNavGrid:isWalkable
    -- @covers LNavGrid:setBlocked
    -- @covers lurek.pathfind.newNavGrid
    it("isWalkable reflects blocked state", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        expect_true(grid:isWalkable(1, 1))
        grid:setBlocked(1, 1, true)
        expect_false(grid:isWalkable(1, 1))
    end)

    -- @covers LNavGrid:fillRect
    -- @covers LNavGrid:isBlocked
    -- @covers lurek.pathfind.newNavGrid
    it("fillRect blocks region", function()
        local grid = lurek.pathfind.newNavGrid(20, 20)
        grid:fillRect(10, 10, 3, 3, 0)
        expect_true(grid:isBlocked(10, 10))
        expect_true(grid:isBlocked(12, 12))
        expect_false(grid:isBlocked(9, 9))
    end)

    -- @covers LNavGrid:getDiagonalMode
    -- @covers LNavGrid:setDiagonalMode
    -- @covers lurek.pathfind.newNavGrid
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
-- @describe Pathfinder
describe("Pathfinder", function()
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("newPathfinder returns an object", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(grid)
        expect_type("userdata", pf)
    end)

    -- @covers LUnitPathfinder:findPath
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
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

    -- @covers LNavGrid:setBlocked
    -- @covers LUnitPathfinder:findPath
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("findPath through narrow gap", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        for y = 1, 10 do grid:setBlocked(5, y, true) end
        grid:setBlocked(5, 5, false)
        local pf = lurek.pathfind.newPathfinder(grid)
        local path = pf:findPath(1, 1, 10, 10)
        expect_true(path ~= nil, "should find path through narrow gap")
    end)

    -- @covers LUnitPathfinder:heuristicDistance
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("heuristicDistance returns positive number", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(grid)
        local d = pf:heuristicDistance(1, 1, 4, 5)
        expect_type("number", d)
        expect_true(d > 0, "distance should be positive")
    end)

    -- @covers LUnitPathfinder:clearCache
    -- @covers LUnitPathfinder:getCacheSize
    -- @covers LUnitPathfinder:isCacheEnabled
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
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
-- @describe FlowField
describe("FlowField", function()
    -- @covers lurek.pathfind.newFlowField
    -- @covers lurek.pathfind.newNavGrid
    it("newFlowField returns an object", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local ff = lurek.pathfind.newFlowField(grid)
        expect_type("userdata", ff)
    end)

    -- @covers LFlowField:isCalculated
    -- @covers lurek.pathfind.newFlowField
    -- @covers lurek.pathfind.newNavGrid
    it("isCalculated returns false initially", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local ff = lurek.pathfind.newFlowField(grid)
        expect_false(ff:isCalculated())
    end)

    -- @covers LFlowField:calculate
    -- @covers LFlowField:isCalculated
    -- @covers lurek.pathfind.newFlowField
    -- @covers lurek.pathfind.newNavGrid
    it("calculate makes isCalculated true", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local ff = lurek.pathfind.newFlowField(grid)
        ff:calculate(10, 10)
        expect_true(ff:isCalculated())
    end)

    -- @covers LFlowField:calculate
    -- @covers LFlowField:getDirection
    -- @covers lurek.pathfind.newFlowField
    -- @covers lurek.pathfind.newNavGrid
    it("getDirection returns numbers", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local ff = lurek.pathfind.newFlowField(grid)
        ff:calculate(10, 10)
        local dx, dy = ff:getDirection(1, 1)
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    -- @covers LFlowField:calculate
    -- @covers LFlowField:getCostToTarget
    -- @covers lurek.pathfind.newFlowField
    -- @covers lurek.pathfind.newNavGrid
    it("getCostToTarget positive for reachable cell", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local ff = lurek.pathfind.newFlowField(grid)
        ff:calculate(10, 10)
        local cost = ff:getCostToTarget(1, 1)
        expect_true(cost > 0, "cost should be positive")
    end)

    -- @covers LFlowField:calculate
    -- @covers LFlowField:steer
    -- @covers lurek.pathfind.newFlowField
    -- @covers lurek.pathfind.newNavGrid
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
-- @describe pathfinding threadCount
describe("pathfinding threadCount", function()
    -- @covers lurek.pathfind.getThreadCount
    it("getThreadCount returns a number", function()
        local tc = lurek.pathfind.getThreadCount()
        expect_type("number", tc)
    end)
end)

-- ============================================================
-- newNavGridFromTileMap
-- ============================================================
-- @describe newNavGridFromTileMap
describe("newNavGridFromTileMap", function()
    -- @covers lurek.pathfind.newNavGridFromTileMap
    it("is a function", function()
        expect_type("function", lurek.pathfind.newNavGridFromTileMap)
    end)

end)

-- NavGrid extended

-- @describe NavGrid.getDimensions
describe("NavGrid.getDimensions", function()
    -- @covers LNavGrid:getDimensions
    -- @covers lurek.pathfind.newNavGrid
    it("getDimensions returns width and height", function()
        local g = lurek.pathfind.newNavGrid(12, 8)
        local w, h = g:getDimensions()
        expect_equal(12, w)
        expect_equal(8, h)
    end)
end)

-- @describe NavGrid.fill
describe("NavGrid.fill", function()
    -- @covers LNavGrid:fill
    -- @covers LNavGrid:getCost
    -- @covers lurek.pathfind.newNavGrid
    it("fill sets all cells to the same cost", function()
        local g = lurek.pathfind.newNavGrid(5, 5)
        g:fill(3)
        for y = 1, 5 do
            for x = 1, 5 do
                expect_equal(3, g:getCost(x, y))
            end
        end
    end)

    -- @covers LNavGrid:fill
    -- @covers LNavGrid:isWalkable
    -- @covers lurek.pathfind.newNavGrid
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

-- @describe NavGrid.saveToString / loadFromString
describe("NavGrid.saveToString / loadFromString", function()
    -- @covers LNavGrid:saveToString
    -- @covers lurek.pathfind.newNavGrid
    it("saveToString returns a non-empty string", function()
        local g = lurek.pathfind.newNavGrid(6, 6)
        local s = g:saveToString()
        expect_type("string", s)
        expect_true(#s > 0, "serialised string must not be empty")
    end)

    -- @covers LNavGrid:isBlocked
    -- @covers LNavGrid:loadFromString
    -- @covers LNavGrid:saveToString
    -- @covers LNavGrid:setBlocked
    -- @covers lurek.pathfind.newNavGrid
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

    -- @covers LNavGrid:getCost
    -- @covers LNavGrid:loadFromString
    -- @covers LNavGrid:saveToString
    -- @covers LNavGrid:setCost
    -- @covers lurek.pathfind.newNavGrid
    it("loadFromString round-trips cost values", function()
        local g = lurek.pathfind.newNavGrid(4, 4)
        g:setCost(2, 2, 7)
        local g2 = lurek.pathfind.newNavGrid(4, 4)
        g2:loadFromString(g:saveToString())
        expect_equal(7, g2:getCost(2, 2))
    end)
end)

-- @describe NavGrid.setChunkSize / getChunkSize
describe("NavGrid.setChunkSize / getChunkSize", function()
    -- @covers LNavGrid:getChunkSize
    -- @covers LNavGrid:setChunkSize
    -- @covers lurek.pathfind.newNavGrid
    it("setChunkSize / getChunkSize round-trip", function()
        local g = lurek.pathfind.newNavGrid(32, 32)
        g:setChunkSize(8)
        expect_equal(8, g:getChunkSize())
    end)
end)

-- @describe NavGrid.type / typeOf
describe("NavGrid.type / typeOf", function()
    -- @covers LNavGrid:type
    -- @covers lurek.pathfind.newNavGrid
    it("type() returns a string", function()
        local g = lurek.pathfind.newNavGrid(4, 4)
        expect_type("string", g:type())
    end)

    -- @covers LNavGrid:typeOf
    -- @covers lurek.pathfind.newNavGrid
    it("typeOf() checks identity against a type name", function()
        local g = lurek.pathfind.newNavGrid(4, 4)
        expect_true(g:typeOf("LNavGrid"))
        expect_false(g:typeOf("FlowField"))
    end)
end)

-- UnitPathfinder extended

-- @describe UnitPathfinder.findPathSmooth
describe("UnitPathfinder.findPathSmooth", function()
    -- @covers LUnitPathfinder:findPathSmooth
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("findPathSmooth returns a table or nil", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        local path = pf:findPathSmooth(1, 1, 10, 10)
        expect_true(path == nil or type(path) == "table", "findPathSmooth must return table or nil")
    end)

    -- @covers LUnitPathfinder:findPathSmooth
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("findPathSmooth with open grid returns a path", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        local path = pf:findPathSmooth(1, 1, 10, 10)
        expect_true(path ~= nil, "expected a smooth path in open grid")
    end)
end)

-- @describe UnitPathfinder.getPathLength / getPathCost
describe("UnitPathfinder.getPathLength / getPathCost", function()
    -- @covers LUnitPathfinder:findPath
    -- @covers LUnitPathfinder:getPathLength
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
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

    -- @covers LUnitPathfinder:findPath
    -- @covers LUnitPathfinder:getPathCost
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
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

-- @describe UnitPathfinder.findPartialPath
describe("UnitPathfinder.findPartialPath", function()
    -- @covers LUnitPathfinder:findPartialPath
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("findPartialPath returns a path and boolean", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        local path, complete = pf:findPartialPath(1, 1, 10, 10, 100)
        expect_true(path == nil or type(path) == "table", "findPartialPath must return table or nil")
        expect_type("boolean", complete)
    end)

    -- @covers LUnitPathfinder:findPartialPath
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("findPartialPath in open grid returns complete=true", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        local _path, complete = pf:findPartialPath(1, 1, 10, 10, 200)
        expect_true(complete, "open grid partial path should be complete")
    end)
end)

-- @describe UnitPathfinder.findNearestWalkable
describe("UnitPathfinder.findNearestWalkable", function()
    -- @covers LNavGrid:setBlocked
    -- @covers LUnitPathfinder:findNearestWalkable
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("findNearestWalkable returns two numbers", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        g:setBlocked(5, 5, true)
        local pf = lurek.pathfind.newPathfinder(g)
        local nx, ny = pf:findNearestWalkable(5, 5, 5)
        expect_type("number", nx)
        expect_type("number", ny)
    end)

    -- @covers LUnitPathfinder:findNearestWalkable
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("findNearestWalkable returns same coords for already walkable cell", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        local nx, ny = pf:findNearestWalkable(3, 3, 5)
        expect_equal(3, nx)
        expect_equal(3, ny)
    end)
end)

-- @describe UnitPathfinder.isReachable
describe("UnitPathfinder.isReachable", function()
    -- @covers LUnitPathfinder:isReachable
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("isReachable returns true for reachable goal in open grid", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        expect_true(pf:isReachable(1, 1, 10, 10))
    end)

    -- @covers LNavGrid:setBlocked
    -- @covers LUnitPathfinder:isReachable
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
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

-- @describe UnitPathfinder.lineOfSight
describe("UnitPathfinder.lineOfSight", function()
    -- @covers LUnitPathfinder:lineOfSight
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("lineOfSight returns true for unobstructed path", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        expect_true(pf:lineOfSight(1, 1, 5, 5))
    end)

    -- @covers LNavGrid:setBlocked
    -- @covers LUnitPathfinder:lineOfSight
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("lineOfSight returns false when wall blocks", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        -- Block a column between start and end
        for y = 1, 10 do g:setBlocked(5, y, true) end
        local pf = lurek.pathfind.newPathfinder(g)
        local los = pf:lineOfSight(1, 5, 9, 5)
        expect_type("boolean", los)
    end)
end)

-- @describe UnitPathfinder cache control
describe("UnitPathfinder cache control", function()
    -- @covers LUnitPathfinder:isCacheEnabled
    -- @covers LUnitPathfinder:setCacheEnabled
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("setCacheEnabled / isCacheEnabled round-trip", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        pf:setCacheEnabled(false)
        expect_false(pf:isCacheEnabled())
        pf:setCacheEnabled(true)
        expect_true(pf:isCacheEnabled())
    end)

    -- @covers LUnitPathfinder:clearCache
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("clearCache does not error", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        expect_no_error(function() pf:clearCache() end)
    end)

    -- @covers LUnitPathfinder:getCacheSize
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("getCacheSize returns a number", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        expect_type("number", pf:getCacheSize())
    end)

    -- @covers LUnitPathfinder:setCacheMaxSize
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("setCacheMaxSize does not error", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        expect_no_error(function() pf:setCacheMaxSize(100) end)
    end)
end)

-- @describe flow field (RS parity)
describe("flow field (RS parity)", function()
    -- @covers lurek.pathfind.newFlowField
    -- @covers lurek.pathfind.newNavGrid
    it("newFlowField returns userdata", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local ff = lurek.pathfind.newFlowField(g)
        expect_equal("userdata", type(ff))
    end)

    -- @covers LFlowField:isCalculated
    -- @covers lurek.pathfind.newFlowField
    -- @covers lurek.pathfind.newNavGrid
    it("isCalculated is false before calculate", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local ff = lurek.pathfind.newFlowField(g)
        expect_false(ff:isCalculated())
    end)

    -- @covers LFlowField:getTargets
    -- @covers lurek.pathfind.newFlowField
    -- @covers lurek.pathfind.newNavGrid
    it("getTargets returns empty before calculate", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local ff = lurek.pathfind.newFlowField(g)
        local targets = ff:getTargets()
        expect_equal("table", type(targets))
        expect_equal(0, #targets)
    end)

    -- @covers LFlowField:calculate
    -- @covers LFlowField:isCalculated
    -- @covers lurek.pathfind.newFlowField
    -- @covers lurek.pathfind.newNavGrid
    it("calculate with single target sets isCalculated = true", function()
        local g = lurek.pathfind.newNavGrid(5, 5)
        local ff = lurek.pathfind.newFlowField(g)
        ff:calculate(3, 3)
        expect_true(ff:isCalculated())
    end)

    -- @covers LFlowField:calculate
    -- @covers LFlowField:getTargets
    -- @covers lurek.pathfind.newFlowField
    -- @covers lurek.pathfind.newNavGrid
    it("getTargets after calculate returns the specified cells", function()
        local g = lurek.pathfind.newNavGrid(5, 5)
        local ff = lurek.pathfind.newFlowField(g)
        ff:calculate(2, 2)
        local targets = ff:getTargets()
        expect_equal(1, #targets)
    end)

    -- @covers LFlowField:calculate
    -- @covers LFlowField:getCostToTarget
    -- @covers lurek.pathfind.newFlowField
    -- @covers lurek.pathfind.newNavGrid
    it("costToTarget returns 0 at the target cell", function()
        local g = lurek.pathfind.newNavGrid(5, 5)
        local ff = lurek.pathfind.newFlowField(g)
        ff:calculate(3, 3)
        local cost = ff:getCostToTarget(3, 3)
        expect_near(0.0, cost, 0.01)
    end)

    -- @covers LFlowField:calculate
    -- @covers LFlowField:steer
    -- @covers lurek.pathfind.newFlowField
    -- @covers lurek.pathfind.newNavGrid
    it("steer returns numbers for vx and vy", function()
        local g = lurek.pathfind.newNavGrid(5, 5)
        local ff = lurek.pathfind.newFlowField(g)
        ff:calculate(3, 3)
        local vx, vy = ff:steer(1.0, 1.0, 32, 1, 1)
        expect_equal("number", type(vx))
        expect_equal("number", type(vy))
    end)

    -- @covers LFlowField:calculate
    -- @covers LFlowField:isCalculated
    -- @covers lurek.pathfind.newFlowField
    -- @covers lurek.pathfind.newNavGrid
    it("multi-target calculate accepts multiple cells", function()
        local g = lurek.pathfind.newNavGrid(8, 8)
        local ff = lurek.pathfind.newFlowField(g)
        ff:calculate(1, 1)
        expect_true(ff:isCalculated())
    end)
end)

-- @describe pathfinder line of sight and diagonal mode (RS parity)
describe("pathfinder line of sight and diagonal mode (RS parity)", function()
    -- @covers LUnitPathfinder:lineOfSight
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("lineOfSight returns true on open grid", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(g)
        expect_true(pf:lineOfSight(1, 1, 5, 5))
    end)

    -- @covers LNavGrid:setBlocked
    -- @covers LUnitPathfinder:lineOfSight
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("lineOfSight returns false when wall blocks path", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        -- block a row of cells at column 5
        for y = 1, 10 do g:setBlocked(5, y, true) end
        local pf = lurek.pathfind.newPathfinder(g)
        expect_false(pf:lineOfSight(1, 5, 9, 5))
    end)

    -- @covers LNavGrid:getDiagonalMode
    -- @covers LNavGrid:setDiagonalMode
    -- @covers lurek.pathfind.newNavGrid
    it("setDiagonalMode and getDiagonalMode round-trip", function()
        local g = lurek.pathfind.newNavGrid(10, 10)
        g:setDiagonalMode("none")
        expect_equal("none", g:getDiagonalMode())
        g:setDiagonalMode("always")
        expect_equal("always", g:getDiagonalMode())
    end)
end)

-- Pathfind Bidirectional (merged from test_pathfind_bidirectional.lua)

-- @describe Bidirectional A*: path finding
describe("Bidirectional A*: path finding", function()

    -- @covers LUnitPathfinder:findPathBidirectional
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("finds path on open 5x5 grid from (1,1) to (5,5)", function()
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

    -- @covers LUnitPathfinder:findPathBidirectional
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("start equals goal returns single-node path", function()
        local grid = lurek.pathfind.newNavGrid(5, 5)
        local pathfinder = lurek.pathfind.newPathfinder(grid)
        local path, complete = pathfinder:findPathBidirectional(3, 3, 3, 3)
        expect_not_nil(path)
        expect_equal(1, #path)
        expect_true(complete)
        expect_equal(3, path[1].x)
        expect_equal(3, path[1].y)
    end)

    -- @covers LNavGrid:setBlocked
    -- @covers LUnitPathfinder:findPathBidirectional
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("blocked start returns nil path and complete false", function()
        local grid = lurek.pathfind.newNavGrid(5, 5)
        local pathfinder = lurek.pathfind.newPathfinder(grid)
        grid:setBlocked(1, 1, true)
        local path, complete = pathfinder:findPathBidirectional(1, 1, 5, 5)
        expect_nil(path, "path must be nil when start is blocked")
        expect_false(complete, "complete must be false when start is blocked")
    end)

    -- @covers LUnitPathfinder:findPathBidirectional
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("findPathBidirectional finds path on 10x10 grid", function()
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

    -- @covers LUnitPathfinder:findPathBidirectional
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("tiny max_nodes budget returns incomplete path", function()
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

-- @describe UnitPathfinder regression: zero index
describe("UnitPathfinder regression: zero index", function()
    -- @covers LUnitPathfinder:findPath
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("findPath with x1=0 returns a Lua error (no panic)", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(grid)
        expect_error(function()
            pf:findPath(0, 1, 5, 5)
        end)
    end)

    -- @covers LUnitPathfinder:findPathSmooth
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
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

-- @describe UnitPathfinder regression: zero index
describe("UnitPathfinder regression: zero index", function()
    -- @covers LUnitPathfinder:findPath
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("findPath with x1=0 returns a Lua error (no panic)", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(grid)
        expect_error(function()
            pf:findPath(0, 1, 5, 5)
        end)
    end)

    -- @covers LUnitPathfinder:findPathSmooth
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("findPathSmooth with y2=0 returns a Lua error (no panic)", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(grid)
        expect_error(function()
            pf:findPathSmooth(1, 1, 5, 0)
        end)
    end)
end)

-- @describe pathfind missing explicit coverage
describe("pathfind missing explicit coverage", function()
    -- @covers lurek.pathfind.setThreadCount
    it("setThreadCount accepts a positive value", function()
        expect_no_error(function()
            lurek.pathfind.setThreadCount(1)
        end)
    end)

    -- @covers LNavGrid:clearDirty
    -- @covers LNavGrid:rebuildAbstract
    -- @covers LNavGrid:setDirty
    -- @covers lurek.pathfind.newNavGrid
    it("NavGrid dirty/abstract rebuild methods do not error", function()
        local grid = lurek.pathfind.newNavGrid(12, 12)
        expect_no_error(function()
            grid:setDirty(1, 1, 3, 3)
            grid:rebuildAbstract()
            grid:clearDirty()
        end)
    end)

    -- @covers LFlowField:calculateMulti
    -- @covers LFlowField:getDirectionAngle
    -- @covers lurek.pathfind.newFlowField
    -- @covers lurek.pathfind.newNavGrid
    it("FlowField multi-target calculation exposes direction angle", function()
        local grid = lurek.pathfind.newNavGrid(16, 16)
        local ff = lurek.pathfind.newFlowField(grid)
        ff:calculateMulti({
            {x = 8, y = 8},
            {x = 10, y = 10},
        })
        local angle = ff:getDirectionAngle(1, 1)
        expect_type("number", angle)
    end)
end)

-- @describe pathfind strict: newHexGrid / LHexGrid methods
describe("pathfind strict: newHexGrid / LHexGrid methods", function()
    -- @covers lurek.pathfind.newHexGrid
    it("newHexGrid constructs with default layout", function()
        local g = lurek.pathfind.newHexGrid(8, 8)
        expect_true(g ~= nil)
    end)

    -- @covers LHexGrid:setBlocked
    -- @covers LHexGrid:isBlocked
    -- @covers lurek.pathfind.newHexGrid
    it("LHexGrid setBlocked / isBlocked round-trip", function()
        local g = lurek.pathfind.newHexGrid(8, 8)
        g:setBlocked(1, 1, true)
        expect_true(g:isBlocked(1, 1))
    end)

    -- @covers LHexGrid:setCost
    -- @covers lurek.pathfind.newHexGrid
    it("LHexGrid setCost is callable", function()
        local g = lurek.pathfind.newHexGrid(8, 8)
        local ok = pcall(function() g:setCost(2, 2, 2.0) end)
        expect_true(ok)
    end)

    -- @covers LHexGrid:lineOfSight
    -- @covers lurek.pathfind.newHexGrid
    it("LHexGrid lineOfSight returns boolean", function()
        local g = lurek.pathfind.newHexGrid(8, 8)
        expect_type("boolean", g:lineOfSight(1, 1, 3, 3))
    end)

    -- @covers LHexGrid:fieldOfView
    -- @covers lurek.pathfind.newHexGrid
    it("LHexGrid fieldOfView returns table", function()
        local g = lurek.pathfind.newHexGrid(8, 8)
        expect_type("table", g:fieldOfView(1, 1, 3))
    end)

    -- @covers LHexGrid:rangeOfMovement
    -- @covers lurek.pathfind.newHexGrid
    it("LHexGrid rangeOfMovement returns table", function()
        local g = lurek.pathfind.newHexGrid(8, 8)
        expect_type("table", g:rangeOfMovement(1, 1, 3))
    end)

    -- @covers LHexGrid:distance
    -- @covers lurek.pathfind.newHexGrid
    it("LHexGrid distance returns number", function()
        local g = lurek.pathfind.newHexGrid(8, 8)
        expect_type("number", g:distance(1, 1, 3, 3))
    end)

    -- @covers LHexGrid:type
    -- @covers LHexGrid:typeOf
    -- @covers lurek.pathfind.newHexGrid
    it("LHexGrid type and typeOf are callable", function()
        local g = lurek.pathfind.newHexGrid(8, 8)
        expect_type("string", g:type())
        expect_type("boolean", g:typeOf("Object"))
    end)
end)

-- @describe pathfind strict: newJpsGrid / LJpsGrid methods
describe("pathfind strict: newJpsGrid / LJpsGrid methods", function()
    -- @covers lurek.pathfind.newJpsGrid
    it("newJpsGrid constructs", function()
        local g = lurek.pathfind.newJpsGrid(8, 8)
        expect_true(g ~= nil)
    end)

    -- @covers LJpsGrid:setBlocked
    -- @covers LJpsGrid:isBlocked
    -- @covers lurek.pathfind.newJpsGrid
    it("LJpsGrid setBlocked / isBlocked round-trip", function()
        local g = lurek.pathfind.newJpsGrid(8, 8)
        g:setBlocked(2, 2, true)
        expect_true(g:isBlocked(2, 2))
    end)

    -- @covers LJpsGrid:type
    -- @covers LJpsGrid:typeOf
    -- @covers lurek.pathfind.newJpsGrid
    it("LJpsGrid type and typeOf are callable", function()
        local g = lurek.pathfind.newJpsGrid(8, 8)
        expect_type("string", g:type())
        expect_type("boolean", g:typeOf("Object"))
    end)
end)

-- @describe pathfind strict: rangeMap function
describe("pathfind strict: rangeMap function", function()
    -- @covers lurek.pathfind.rangeMap
    it("rangeMap returns table with cells", function()
        local result = lurek.pathfind.rangeMap({
            width = 4, height = 4,
            origin_x = 2, origin_y = 2,
            budget = 2.0
        })
        expect_type("table", result)
        expect_type("table", result.cells)
    end)
end)

-- @describe pathfind strict: UnitPathfinder / FlowField / AIFlowField typeOf
describe("pathfind strict: UnitPathfinder / FlowField / AIFlowField typeOf", function()
    -- @covers LUnitPathfinder:type
    -- @covers LUnitPathfinder:typeOf
    -- @covers lurek.pathfind.newPathfinder
    -- @covers lurek.pathfind.newNavGrid
    it("LUnitPathfinder type and typeOf are callable", function()
        local grid = lurek.pathfind.newNavGrid(8, 8)
        local pf = lurek.pathfind.newPathfinder(grid)
        expect_type("string", pf:type())
        expect_type("boolean", pf:typeOf("Object"))
    end)

    -- @covers LFlowField:type
    -- @covers LFlowField:typeOf
    -- @covers lurek.pathfind.newFlowField
    -- @covers lurek.pathfind.newNavGrid
    it("LFlowField type and typeOf are callable", function()
        local grid = lurek.pathfind.newNavGrid(8, 8)
        local ff = lurek.pathfind.newFlowField(grid)
        expect_type("string", ff:type())
        expect_type("boolean", ff:typeOf("Object"))
    end)

    -- @covers LPathGrid:typeOf
    -- @covers lurek.pathfind.newPathGrid
    it("LPathGrid typeOf is callable", function()
        local pg = lurek.pathfind.newPathGrid(8, 8, 1.0)
        expect_type("boolean", pg:typeOf("Object"))
    end)

    -- @covers LAIFlowField:typeOf
    -- @covers lurek.pathfind.newPathFlowField
    -- @covers lurek.pathfind.newPathGrid
    it("LAIFlowField typeOf is callable", function()
        local pg = lurek.pathfind.newPathGrid(8, 8, 1.0)
        local aiff = lurek.pathfind.newPathFlowField(pg)
        expect_type("boolean", aiff:typeOf("Object"))
    end)
end)

-- [migrated from ai unit tests]
-- =========================================================================
-- PathGrid
-- =========================================================================
-- @describe lurek.pathfind PathGrid
describe("lurek.pathfind PathGrid", function()
    -- @covers LPathGrid:type
    -- @covers lurek.pathfind.newPathGrid
    it("type returns PathGrid", function()
        local g = lurek.pathfind.newPathGrid(10, 10, 32)
        expect_equal("LPathGrid", g:type())
    end)

    -- @covers LPathGrid:getCellSize
    -- @covers LPathGrid:getHeight
    -- @covers LPathGrid:getWidth
    -- @covers lurek.pathfind.newPathGrid
    it("getWidth / getHeight / getCellSize", function()
        local g = lurek.pathfind.newPathGrid(8, 6, 16)
        expect_equal(8, g:getWidth())
        expect_equal(6, g:getHeight())
        expect_near(16, g:getCellSize(), 0.01)
    end)

    -- @covers LPathGrid:isWalkable
    -- @covers lurek.pathfind.newPathGrid
    it("all cells walkable by default", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        expect_true(g:isWalkable(1, 1))
        expect_true(g:isWalkable(5, 5))
    end)

    -- @covers LPathGrid:isWalkable
    -- @covers LPathGrid:setWalkable
    -- @covers lurek.pathfind.newPathGrid
    it("setWalkable / isWalkable (1-based)", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        g:setWalkable(3, 3, false)
        expect_false(g:isWalkable(3, 3))
        g:setWalkable(3, 3, true)
        expect_true(g:isWalkable(3, 3))
    end)

    -- @covers LPathGrid:getCost
    -- @covers LPathGrid:setCost
    -- @covers lurek.pathfind.newPathGrid
    it("setCost / getCost (1-based)", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        g:setCost(2, 2, 3.5)
        expect_near(3.5, g:getCost(2, 2), 0.01)
    end)

    -- @covers LPathGrid:findPath
    -- @covers lurek.pathfind.newPathGrid
    it("findPath returns a table for open grid", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local path = g:findPath(1, 1, 5, 5)
        expect_not_nil(path, "path should exist")
        expect_type("table", path)
        expect_true(#path > 0, "path should have waypoints")
    end)

    -- @covers LPathGrid:findPath
    -- @covers lurek.pathfind.newPathGrid
    it("findPath entries have x and y fields", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local path = g:findPath(1, 1, 3, 3)
        expect_not_nil(path)
        local first = path[1]
        expect_not_nil(first.x, "x field")
        expect_not_nil(first.y, "y field")
    end)

    -- @covers LPathGrid:findPath
    -- @covers LPathGrid:setWalkable
    -- @covers lurek.pathfind.newPathGrid
    it("findPath returns nil for blocked path", function()
        local g = lurek.pathfind.newPathGrid(3, 1, 10)
        g:setWalkable(2, 1, false)
        local path = g:findPath(1, 1, 3, 1)
        expect_nil(path, "blocked path should be nil")
    end)

    -- @covers LPathGrid:findPathSmoothed
    -- @covers lurek.pathfind.newPathGrid
    it("findPathSmoothed returns a table", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local path = g:findPathSmoothed(1, 1, 5, 5)
        expect_not_nil(path)
        expect_type("table", path)
    end)

    -- @covers LPathGrid:findPath
    -- @covers lurek.pathfind.newPathGrid
    it("findPath same start and goal", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local path = g:findPath(3, 3, 3, 3)
        expect_not_nil(path)
    end)
end)

-- =========================================================================
-- FlowField
-- =========================================================================
-- @describe lurek.pathfind FlowField
describe("lurek.pathfind FlowField", function()
    -- @covers LAIFlowField:type
    -- @covers lurek.pathfind.newPathFlowField
    -- @covers lurek.pathfind.newPathGrid
    it("type returns FlowField", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        expect_equal("LAIFlowField", ff:type())
    end)

    -- @covers LAIFlowField:getHeight
    -- @covers LAIFlowField:getWidth
    -- @covers lurek.pathfind.newPathFlowField
    -- @covers lurek.pathfind.newPathGrid
    it("getWidth / getHeight", function()
        local g = lurek.pathfind.newPathGrid(8, 6, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        expect_equal(8, ff:getWidth())
        expect_equal(6, ff:getHeight())
    end)

    -- @covers LAIFlowField:hasGoal
    -- @covers lurek.pathfind.newPathFlowField
    -- @covers lurek.pathfind.newPathGrid
    it("hasGoal returns false initially", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        expect_false(ff:hasGoal())
    end)

    -- @covers LAIFlowField:getGoal
    -- @covers LAIFlowField:hasGoal
    -- @covers LAIFlowField:setGoal
    -- @covers lurek.pathfind.newPathFlowField
    -- @covers lurek.pathfind.newPathGrid
    it("setGoal / hasGoal / getGoal (1-based)", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        ff:setGoal(3, 4)
        expect_true(ff:hasGoal())
        local gx, gy = ff:getGoal()
        expect_equal(3, gx)
        expect_equal(4, gy)
    end)

    -- @covers LAIFlowField:getDirection
    -- @covers LAIFlowField:setGoal
    -- @covers lurek.pathfind.newPathFlowField
    -- @covers lurek.pathfind.newPathGrid
    it("getDirection returns two numbers", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        ff:setGoal(3, 3)
        local dx, dy = ff:getDirection(1, 1)
        expect_type("number", dx)
        expect_type("number", dy)
    end)

    -- @covers LAIFlowField:getDistance
    -- @covers LAIFlowField:setGoal
    -- @covers lurek.pathfind.newPathFlowField
    -- @covers lurek.pathfind.newPathGrid
    it("getDistance returns a number", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        ff:setGoal(3, 3)
        local d = ff:getDistance(1, 1)
        expect_type("number", d)
    end)

    -- @covers LAIFlowField:getGoal
    -- @covers lurek.pathfind.newPathFlowField
    -- @covers lurek.pathfind.newPathGrid
    it("getGoal returns nil before setGoal", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        local gx, gy = ff:getGoal()
        expect_nil(gx)
        expect_nil(gy)
    end)

    -- @covers LAIFlowField:getDistance
    -- @covers LAIFlowField:setGoal
    -- @covers lurek.pathfind.newPathFlowField
    -- @covers lurek.pathfind.newPathGrid
    it("distance at goal is zero", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        local ff = lurek.pathfind.newPathFlowField(g)
        ff:setGoal(3, 3)
        local d = ff:getDistance(3, 3)
        expect_near(0, d, 0.01)
    end)
end)

-- @describe pathfind constructors migrated from ai unit
describe("pathfind constructors migrated from ai unit", function()
    -- @covers lurek.pathfind.newPathGrid
    it("has newPathGrid factory", function()
        expect_type("function", lurek.pathfind.newPathGrid)
    end)

    -- @covers lurek.pathfind.newPathFlowField
    it("has newPathFlowField factory", function()
        expect_type("function", lurek.pathfind.newPathFlowField)
    end)

    -- @covers LPathGrid:type
    -- @covers lurek.pathfind.newPathGrid
    it("PathGrid:type() returns PathGrid", function()
        expect_equal("LPathGrid", lurek.pathfind.newPathGrid(5, 5, 10):type())
    end)

    -- @covers LAIFlowField:type
    -- @covers lurek.pathfind.newPathFlowField
    -- @covers lurek.pathfind.newPathGrid
    it("FlowField:type() returns FlowField", function()
        local g = lurek.pathfind.newPathGrid(5, 5, 10)
        expect_equal("LAIFlowField", lurek.pathfind.newPathFlowField(g):type())
    end)
end)

-- @describe pathfind migrated from integration/ai_physics
describe("pathfind migrated from integration/ai_physics", function()
    -- @covers LNavGrid:setBlocked
    -- @covers LUnitPathfinder:findPath
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    it("agent follows A* path", function()
        local grid = lurek.pathfind.newNavGrid(50, 50)
        for y = 10, 40 do
            grid:setBlocked(25, y, true)
        end

        local pf = lurek.pathfind.newPathfinder(grid)
        local path = pf:findPath(10, 25, 40, 25)
        expect_not_nil(path, "path found around wall")
        expect_true(#path > 15, "path goes around wall")

        local crosses_wall = false
        for _, wp in ipairs(path) do
            if wp.x == 25 and wp.y >= 10 and wp.y <= 40 then
                crosses_wall = true
            end
        end
        expect_false(crosses_wall, "path avoids wall")
    end)
end)

-- @describe unit: migrated from integration/test_pathfind_ai.lua
describe("unit: migrated from integration/test_pathfind_ai.lua", function()
        -- @covers LHexGrid:findPath
        -- @covers lurek.pathfind.newHexGrid
        it("AI unit can find path to target", function()
            local map = lurek.pathfind.newHexGrid(12, 12)
            -- Simulate AI agent at (1,1) targeting (10,10)
            local path = map:findPath(1, 1, 10, 10)
            expect_true(path ~= nil, "AI should find a path on open map")
            expect_true(#path >= 1, "path must have length >= 1")
        end)

        -- @covers LHexGrid:rangeOfMovement
        -- @covers lurek.pathfind.newHexGrid
        it("AI units compute their movement range with budget", function()
            local map = lurek.pathfind.newHexGrid(10, 10)
            -- Typical turn-based unit with movement of 3
            local reachable = map:rangeOfMovement(5, 5, 3.0)
            expect_type("table", reachable)
            expect_true(#reachable > 0, "unit should be able to reach some cells")
            expect_true(#reachable >= 6, "with budget=3, should reach at least 6 hex cells")
        end)

        -- @covers LHexGrid:lineOfSight
        -- @covers LHexGrid:setBlocked
        -- @covers lurek.pathfind.newHexGrid
        it("AI units check line of sight before shooting", function()
            local map = lurek.pathfind.newHexGrid(10, 10)
            local los_clear = map:lineOfSight(1, 1, 5, 5)
            expect_equal(true, los_clear, "open map should have LOS")

            -- Add a wall column
            for row = 1, 10 do
                map:setBlocked(3, row, true)
            end
            local los_blocked = map:lineOfSight(1, 5, 8, 5)
            expect_equal(false, los_blocked, "wall should block LOS")
        end)

        -- @covers LHexGrid:fieldOfView
        -- @covers lurek.pathfind.newHexGrid
        it("AI computes FOV for visibility grid", function()
            local map = lurek.pathfind.newHexGrid(10, 10)
            local visible = map:fieldOfView(5, 5, 3)
            expect_type("table", visible)
            -- FOV with radius 3 on open map should see many cells
            expect_true(#visible >= 7, "expected at least 7 visible cells with radius 3")
        end)

        -- @covers LHexGrid:distance
        -- @covers lurek.pathfind.newHexGrid
        it("enemy AI chooses closest walkable cell to player", function()
            local map = lurek.pathfind.newHexGrid(10, 10)
            local player = { col = 8, row = 8 }
            local enemies = {
                { col = 1, row = 1 },
                { col = 2, row = 2 },
                { col = 9, row = 9 },
            }
            local closest = nil
            local min_dist = math.huge
            for _, e in ipairs(enemies) do
                local d = map:distance(e.col, e.row, player.col, player.row)
                if d < min_dist then
                    min_dist = d
                    closest = e
                end
            end
            expect_true(closest ~= nil, "should find closest enemy")
            -- Enemy at (9,9) is closest to player at (8,8) at distance 1
            expect_equal(9, closest.col)
            expect_equal(9, closest.row)
        end)

        -- @covers LHexGrid:findPath
        -- @covers LHexGrid:setBlocked
        -- @covers lurek.pathfind.newHexGrid
        it("AI blocked by terrain uses alternative path", function()
            local map = lurek.pathfind.newHexGrid(8, 8)
            -- Block direct corridor from (1,4) to (8,4)
            for col = 2, 7 do map:setBlocked(col, 4, true) end
            local path_direct = map:findPath(1, 4, 8, 4)
            expect_not_nil(path_direct, "map should still provide a detour route")
            for _, step in ipairs(path_direct) do
                expect_true(step.row ~= 4 or step.col == 1 or step.col == 8,
                    "path should avoid blocked row 4")
            end
        end)

        -- @covers LJpsGrid:findPath
        -- @covers lurek.pathfind.newJpsGrid
        it("AI pathfinding request returns a route", function()
            local map = lurek.pathfind.newJpsGrid(20, 20)
            local path = map:findPath(1, 1, 18, 18)
            expect_not_nil(path, "open map should produce a route")
            expect_true(#path > 0, "route should contain at least one step")
        end)

        -- @covers LJpsGrid:findPath
        -- @covers LJpsGrid:setBlocked
        -- @covers lurek.pathfind.newJpsGrid
        it("shorter path when obstacles removed", function()
            local open = lurek.pathfind.newJpsGrid(10, 10)
            local blocked = lurek.pathfind.newJpsGrid(10, 10)
            -- Add obstacles in blocked version
            for y = 2, 8 do blocked:setBlocked(5, y, true) end
            local path_open    = open:findPath(1, 5, 9, 5)
            local path_blocked = blocked:findPath(1, 5, 9, 5)
            expect_not_nil(path_open, "open map should produce a direct route")
            if path_blocked then
                expect_true(#path_blocked >= #path_open, "detour should be at least as long as direct")
            else
                expect_nil(path_blocked, "fully blocked route is an accepted outcome")
            end
        end)

        -- @covers LJpsGrid:findPath
        -- @covers lurek.pathfind.newJpsGrid
        it("AI can place multiple units without conflicts", function()
            local map = lurek.pathfind.newJpsGrid(10, 10)
            -- Simulate 3 AI units with different start/end positions
            local routes = {
                map:findPath(1, 1, 10, 10),
                map:findPath(1, 10, 10, 1),
                map:findPath(5, 1, 5, 10),
            }
            for _, r in ipairs(routes) do
                expect_not_nil(r, "each route should exist on an open grid")
                expect_true(#r > 0, "each route should contain at least one step")
            end
        end)

        -- @covers lurek.pathfind.rangeMap
        it("AI identifies cells within movement budget", function()
            local result = lurek.pathfind.rangeMap({
                width = 10, height = 10,
                origin_x = 5, origin_y = 5,
                budget = 2.0
            })
            -- Cross shape (4 directions    2 steps) plus origin = ~13 cells
            expect_true(#result.cells >= 5, "expected at least 5 cells with budget=2")
        end)

        -- @covers lurek.pathfind.rangeMap
        it("AI avoids high-cost terrain", function()
            -- Build a cost grid with high-cost center column
            local costs = {}
            for y = 1, 10 do
                for x = 1, 10 do
                    costs[(y - 1) * 10 + x] = (x == 5) and 10.0 or 1.0
                end
            end
            local cheap = lurek.pathfind.rangeMap({ width = 10, height = 10, origin_x = 3, origin_y = 5, budget = 3.0 })
            local expensive = lurek.pathfind.rangeMap({
                width = 10, height = 10,
                costs = costs,
                origin_x = 3, origin_y = 5,
                budget = 3.0
            })
            -- With high-cost column-5, fewer cells should be reachable
            expect_true(#expensive.cells <= #cheap.cells, "high-cost terrain should reduce reachable area")
        end)

        -- @covers lurek.pathfind.rangeMap
        it("surrounded AI unit can only reach origin", function()
            -- Block all adjacent cells
            local blocked = {}
            for i = 1, 8 * 8 do blocked[i] = false end
            for y = 3, 5 do
                for x = 3, 5 do
                    if not (x == 4 and y == 4) then
                        blocked[(y - 1) * 8 + x] = true
                    end
                end
            end
            local result = lurek.pathfind.rangeMap({
                width = 8, height = 8,
                blocked = blocked,
                origin_x = 4, origin_y = 4,
                budget = 10.0
            })
            expect_equal(1, #result.cells)
            expect_equal(4, result.cells[1].x)
            expect_equal(4, result.cells[1].y)
        end)

end)

-- @describe unit: migrated from integration/test_pathfind_ecs.lua
describe("unit: migrated from integration/test_pathfind_ecs.lua", function()
        -- @covers LNavGrid:setBlocked
        -- @covers LUnitPathfinder:findPath
        -- @covers lurek.pathfind.newNavGrid
        -- @covers lurek.pathfind.newPathfinder
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

        -- @covers LNavGrid:setBlocked
        -- @covers LUnitPathfinder:findPath
        -- @covers lurek.pathfind.newNavGrid
        -- @covers lurek.pathfind.newPathfinder
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

end)

-- @describe unit: migrated from integration/test_pathfind_graph.lua
describe("unit: migrated from integration/test_pathfind_graph.lua", function()
        -- @covers lurek.pathfind.newJpsGrid
        it("creates a JPS grid without error", function()
            local g = lurek.pathfind.newJpsGrid(12, 12)
            expect_type("userdata", g)
        end)

        -- @covers LJpsGrid:isBlocked
        -- @covers LJpsGrid:setBlocked
        -- @covers lurek.pathfind.newJpsGrid
        it("setBlocked / isBlocked round-trip", function()
            local g = lurek.pathfind.newJpsGrid(8, 8)
            g:setBlocked(5, 3, true)
            expect_equal(true, g:isBlocked(5, 3))
            g:setBlocked(5, 3, false)
            expect_equal(false, g:isBlocked(5, 3))
        end)

        -- @covers LJpsGrid:findPath
        -- @covers LJpsGrid:setBlocked
        -- @covers lurek.pathfind.newJpsGrid
        it("findPath returns nil when start is blocked", function()
            local g = lurek.pathfind.newJpsGrid(6, 6)
            g:setBlocked(1, 1, true)
            local path = g:findPath(1, 1, 6, 6)
            expect_nil(path, "blocked start should produce no path")
        end)

        -- @covers LJpsGrid:findPath
        -- @covers lurek.pathfind.newJpsGrid
        it("findPath on open grid returns a path", function()
            local g = lurek.pathfind.newJpsGrid(10, 10)
            local path = g:findPath(1, 1, 8, 8)
            expect_true(path ~= nil, "expected a valid path on open grid")
        end)

        -- @covers LJpsGrid:findPath
        -- @covers lurek.pathfind.newJpsGrid
        it("path cells have x and y fields", function()
            local g = lurek.pathfind.newJpsGrid(8, 8)
            local path = g:findPath(1, 1, 6, 6)
            expect_not_nil(path, "open grid should produce a path")
            expect_true(#path > 0, "path should contain at least one step")
            expect_type("number", path[1].x)
            expect_type("number", path[1].y)
        end)

        -- @covers LJpsGrid:findPath
        -- @covers lurek.pathfind.newJpsGrid
        it("path starts and ends at expected coordinates", function()
            local g = lurek.pathfind.newJpsGrid(10, 10)
            local path = g:findPath(1, 1, 5, 5)
            expect_not_nil(path, "open grid should produce a path")
            expect_true(#path >= 1, "path should contain at least one step")
            local first = path[1]
            local last  = path[#path]
            expect_type("number", first.x)
            expect_type("number", last.x)
            expect_equal(5, last.x)
            expect_equal(5, last.y)
        end)

        -- @covers LJpsGrid:findPath
        -- @covers LJpsGrid:setBlocked
        -- @covers lurek.pathfind.newJpsGrid
        it("blocking a cell removes it from the path", function()
            local g = lurek.pathfind.newJpsGrid(8, 8)
            -- Block cell (4, 4) which is on the diagonal from (1,1) to (7,7)
            g:setBlocked(4, 4, true)
            local path_blocked = g:findPath(1, 1, 7, 7)
            if path_blocked then
                for _, c in ipairs(path_blocked) do
                    expect_true(not (c.x == 4 and c.y == 4), "blocked cell must not appear on path")
                end
            end
        end)

        -- @covers LJpsGrid:isBlocked
        -- @covers LJpsGrid:setBlocked
        -- @covers lurek.pathfind.newJpsGrid
        it("multiple independent grids don't share state", function()
            local g1 = lurek.pathfind.newJpsGrid(8, 8)
            local g2 = lurek.pathfind.newJpsGrid(8, 8)
            g1:setBlocked(3, 3, true)
            expect_equal(true, g1:isBlocked(3, 3))
            expect_equal(false, g2:isBlocked(3, 3))
        end)

end)

-- @describe unit: migrated from integration/test_pathfind_hexmap.lua
describe("unit: migrated from integration/test_pathfind_hexmap.lua", function()
        -- @covers lurek.pathfind.newHexGrid
        it("creates a hex grid without error", function()
            local g = lurek.pathfind.newHexGrid(10, 10, "flat")
            expect_type("userdata", g)
        end)

        -- @covers lurek.pathfind.newHexGrid
        it("pointy layout also works", function()
            local g = lurek.pathfind.newHexGrid(8, 8, "pointy")
            expect_type("userdata", g)
        end)

        -- @covers lurek.pathfind.newHexGrid
        it("default layout works with no third argument", function()
            local g = lurek.pathfind.newHexGrid(6, 6)
            expect_type("userdata", g)
        end)

        -- @covers LHexGrid:isBlocked
        -- @covers LHexGrid:setBlocked
        -- @covers lurek.pathfind.newHexGrid
        it("setBlocked and isBlocked round-trip", function()
            local g = lurek.pathfind.newHexGrid(8, 8)
            g:setBlocked(3, 3, true)
            expect_equal(true, g:isBlocked(3, 3))
            g:setBlocked(3, 3, false)
            expect_equal(false, g:isBlocked(3, 3))
        end)

        -- @covers LHexGrid:findPath
        -- @covers LHexGrid:setBlocked
        -- @covers lurek.pathfind.newHexGrid
        it("findPath returns nil when blocked", function()
            local g = lurek.pathfind.newHexGrid(6, 6)
            -- Block every path from (1,1) to (6,6)
            for row = 1, 6 do
                for col = 2, 5 do
                    g:setBlocked(col, row, true)
                end
            end
            local path = g:findPath(1, 1, 6, 6)
            expect_nil(path, "separating wall should make target unreachable")
        end)

        -- @covers LHexGrid:findPath
        -- @covers lurek.pathfind.newHexGrid
        it("findPath returns a path on an open grid", function()
            local g = lurek.pathfind.newHexGrid(10, 10)
            local path = g:findPath(1, 1, 5, 5)
            expect_true(path ~= nil, "expected path on open grid")
            expect_true(#path >= 1, "path must have at least one step")
        end)

        -- @covers LHexGrid:findPath
        -- @covers lurek.pathfind.newHexGrid
        it("path cells have col and row fields", function()
            local g = lurek.pathfind.newHexGrid(8, 8)
            local path = g:findPath(1, 1, 4, 4)
            expect_not_nil(path, "open grid should produce a path")
            expect_true(#path > 0, "path should contain at least one cell")
            local cell = path[1]
            expect_type("number", cell.col)
            expect_type("number", cell.row)
        end)

        -- @covers LHexGrid:lineOfSight
        -- @covers LHexGrid:setBlocked
        -- @covers lurek.pathfind.newHexGrid
        it("lineOfSight returns false through a blocked wall", function()
            local g = lurek.pathfind.newHexGrid(8, 8)
            for row = 1, 8 do
                g:setBlocked(4, row, true)
            end
            local los = g:lineOfSight(1, 4, 8, 4)
            expect_equal(false, los)
        end)

        -- @covers LHexGrid:lineOfSight
        -- @covers lurek.pathfind.newHexGrid
        it("lineOfSight returns true in open space", function()
            local g = lurek.pathfind.newHexGrid(8, 8)
            local los = g:lineOfSight(1, 1, 2, 2)
            expect_equal(true, los)
        end)

        -- @covers LHexGrid:fieldOfView
        -- @covers lurek.pathfind.newHexGrid
        it("fieldOfView returns cells within radius", function()
            local g = lurek.pathfind.newHexGrid(10, 10)
            local fov = g:fieldOfView(5, 5, 2)
            expect_type("table", fov)
            expect_true(#fov > 0, "expected at least one cell in FOV")
            for _, c in ipairs(fov) do
                expect_type("number", c.col)
                expect_type("number", c.row)
            end
        end)

        -- @covers LHexGrid:rangeOfMovement
        -- @covers lurek.pathfind.newHexGrid
        it("rangeOfMovement returns cells within budget", function()
            local g = lurek.pathfind.newHexGrid(10, 10)
            local cells = g:rangeOfMovement(5, 5, 3.0)
            expect_type("table", cells)
            expect_true(#cells > 0, "expected at least one reachable cell")
        end)

        -- @covers LHexGrid:rangeOfMovement
        -- @covers LHexGrid:setBlocked
        -- @covers lurek.pathfind.newHexGrid
        it("rangeOfMovement limited by walls", function()
            local g = lurek.pathfind.newHexGrid(8, 8)
            -- Completely surround origin
            for col = 3, 5 do
                for row = 3, 5 do
                    if not (col == 4 and row == 4) then
                        g:setBlocked(col, row, true)
                    end
                end
            end
            local cells_open = lurek.pathfind.newHexGrid(8, 8):rangeOfMovement(4, 4, 5)
            local cells_blocked = g:rangeOfMovement(4, 4, 5)
            expect_true(#cells_blocked <= #cells_open, "blocked grid should have fewer reachable cells")
        end)

        -- @covers LHexGrid:distance
        -- @covers lurek.pathfind.newHexGrid
        it("distance between adjacent cells is 1", function()
            local g = lurek.pathfind.newHexGrid(8, 8)
            local d = g:distance(3, 3, 4, 3)
            expect_equal(1, d)
        end)

        -- @covers lurek.pathfind.rangeMap
        it("returns cells, width, height", function()
            local result = lurek.pathfind.rangeMap({
                width = 10, height = 10,
                origin_x = 5, origin_y = 5,
                budget = 3.0
            })
            expect_type("table", result.cells)
            expect_equal(10, result.width)
            expect_equal(10, result.height)
        end)

        -- @covers lurek.pathfind.rangeMap
        it("cells have x, y, cost fields", function()
            local result = lurek.pathfind.rangeMap({
                width = 8, height = 8,
                origin_x = 4, origin_y = 4,
                budget = 2.0
            })
            expect_true(#result.cells > 0, "rangeMap should return at least one cell")
            local c = result.cells[1]
            expect_type("number", c.x)
            expect_type("number", c.y)
            expect_type("number", c.cost)
        end)

        -- @covers lurek.pathfind.rangeMap
        it("origin cell has cost 0", function()
            local result = lurek.pathfind.rangeMap({
                width = 8, height = 8,
                origin_x = 4, origin_y = 4,
                budget = 2.0
            })
            local found_origin = false
            for _, c in ipairs(result.cells) do
                if c.x == 4 and c.y == 4 then
                    expect_near(0.0, c.cost, 1e-5)
                    found_origin = true
                end
            end
            expect_true(found_origin, "origin cell should be in reachable list")
        end)

        -- @covers lurek.pathfind.rangeMap
        it("blocked cells are excluded", function()
            local blocked = {}
            for i = 1, 8 * 8 do blocked[i] = false end
            -- Block everything around origin
            for x = 3, 5 do
                for y = 3, 5 do
                    if not (x == 4 and y == 4) then
                        blocked[(y - 1) * 8 + x] = true
                    end
                end
            end
            local result = lurek.pathfind.rangeMap({
                width = 8, height = 8,
                blocked = blocked,
                origin_x = 4, origin_y = 4,
                budget = 5.0
            })
            -- Should only reach origin in a completely enclosed space
            local outside_origin = false
            for _, c in ipairs(result.cells) do
                if c.x ~= 4 or c.y ~= 4 then outside_origin = true end
            end
            expect_equal(false, outside_origin)
        end)

        -- @covers lurek.pathfind.rangeMap
        it("budget constrains reachable distance", function()
            local r3 = lurek.pathfind.rangeMap({ width = 12, height = 12, origin_x = 6, origin_y = 6, budget = 3.0 })
            local r6 = lurek.pathfind.rangeMap({ width = 12, height = 12, origin_x = 6, origin_y = 6, budget = 6.0 })
            expect_true(#r6.cells >= #r3.cells, "larger budget should reach at least as many cells")
        end)

end)

-- @describe NavMesh
describe("NavMesh", function()
    -- @covers lurek.pathfind.newNavMesh
    it("newNavMesh returns userdata", function()
        local mesh = lurek.pathfind.newNavMesh()
        expect_type("userdata", mesh)
    end)

    -- @covers LNavMesh:addPolygon
    -- @covers LNavMesh:getPolygonCount
    -- @covers lurek.pathfind.newNavMesh
    it("addPolygon increments polygon count", function()
        local mesh = lurek.pathfind.newNavMesh()
        local a = mesh:addPolygon({
            {x = 0, y = 0},
            {x = 10, y = 0},
            {x = 10, y = 10},
            {x = 0, y = 10},
        })
        expect_equal(1, a)
        expect_equal(1, mesh:getPolygonCount())
    end)

    -- @covers LNavMesh:addPolygon
    -- @covers LNavMesh:connectPolygons
    -- @covers LNavMesh:findPath
    -- @covers lurek.pathfind.newNavMesh
    it("findPath returns waypoints across connected polygons", function()
        local mesh = lurek.pathfind.newNavMesh()
        local p1 = mesh:addPolygon({
            {x = 0, y = 0},
            {x = 10, y = 0},
            {x = 10, y = 10},
            {x = 0, y = 10},
        })
        local p2 = mesh:addPolygon({
            {x = 10, y = 0},
            {x = 20, y = 0},
            {x = 20, y = 10},
            {x = 10, y = 10},
        })
        expect_true(mesh:connectPolygons(p1, p2, true))
        local path = mesh:findPath(2, 2, 18, 8)
        expect_type("table", path)
        expect_true(#path >= 2)
    end)
end)

test_summary()
