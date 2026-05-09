-- Integration: pathfinding results driving entity positioning via ECS
describe("pathfinding + entity integration", function()
    -- @integration LUnitPathfinder:findPath
    -- @integration LUniverse:get
    -- @integration LUniverse:set
    -- @integration LUniverse:spawn
    -- @integration lurek.ecs.newUniverse
    -- @integration lurek.pathfind.newNavGrid
    -- @integration lurek.pathfind.newPathfinder
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
        expect_not_nil(path, "path found")
        expect_true(#path > 0, "path has at least one step")

        -- Move entity along first step
        local px, py = path[1].x, path[1].y
        universe:set(entity, "x", px)
        universe:set(entity, "y", py)

        local ex = universe:get(entity, "x")
        expect_equal(px, ex, "entity x matches path point")
    end)

    -- @integration LUnitPathfinder:findPath
    -- @integration LUniverse:get
    -- @integration LUniverse:isAlive
    -- @integration LUniverse:set
    -- @integration LUniverse:spawn
    -- @integration lurek.ecs.newUniverse
    -- @integration lurek.pathfind.newNavGrid
    -- @integration lurek.pathfind.newPathfinder
    it("entity follows multi-step path", function()
        local universe = lurek.ecs.newUniverse()
        local entity = universe:spawn()
        universe:set(entity, "x", 0)
        universe:set(entity, "y", 0)

        local grid = lurek.pathfind.newNavGrid(5, 5)
        local pf   = lurek.pathfind.newPathfinder(grid)
        local path = pf:findPath(1, 1, 5, 5)
        expect_not_nil(path, "path should exist on open 5x5 grid")
        expect_true(#path > 0, "path should include at least one step")

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

        expect_true(universe:isAlive(entity), "entity survived path walk")
    end)
end)
test_summary()
