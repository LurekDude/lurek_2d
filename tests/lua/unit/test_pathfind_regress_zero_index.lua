-- Regression: UnitPathfinder:findPath / :findPathSmooth must not panic when a
-- caller passes a 0 (invalid 1-based) coordinate. Before the fix, the u32
-- subtraction underflowed and aborted the process.

-- @description Covers suite: UnitPathfinder regression — 0-index must return Lua error not panic.
describe("UnitPathfinder regression: zero index", function()
    -- @covers lurek.pathfind.UnitPathfinder.findPath
    it("findPath with x1=0 returns a Lua error (no panic)", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(grid)
        expect_error(function()
            pf:findPath(0, 1, 5, 5)
        end)
    end)

    -- @covers lurek.pathfind.UnitPathfinder.findPathSmooth
    it("findPathSmooth with y2=0 returns a Lua error (no panic)", function()
        local grid = lurek.pathfind.newNavGrid(10, 10)
        local pf = lurek.pathfind.newPathfinder(grid)
        expect_error(function()
            pf:findPathSmooth(1, 1, 5, 0)
        end)
    end)
end)

test_summary()
