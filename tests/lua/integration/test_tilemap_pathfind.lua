-- Lurek2D Integration Test: Tilemap + Pathfinding
-- Tests using a tilemap grid as the navigation surface for A* pathfinding.

-- @description Covers suite: integration: tilemap feeds into pathfinding grid.
describe("integration: tilemap feeds into pathfinding grid", function()
    -- @covers lurek.tilemap.Tilemap.setTile
    -- @covers lurek.pathfind.Pathfinder.findPath
    -- @covers lurek.tilemap.newTilemap
    -- @covers lurek.tilemap.setTile
    -- @covers lurek.tilemap.getTile
    -- @covers lurek.pathfind.newNavGrid
    -- @covers lurek.pathfind.newPathfinder
    -- @description Verifies tile solidity can be copied into a navgrid so pathfinding detours around blocked tilemap cells.
    it("builds navgrid from tilemap: walkable tiles passable, wall tiles blocked", function()
        local tm   = lurek.tilemap.newTilemap(10, 10, 16, 16)
        local grid = lurek.pathfind.newNavGrid(10, 10)

        -- Tile ID 0 = wall, 1 = floor
        for y = 0, 9 do
            for x = 0, 9 do
                local tile_id = (x == 5) and 0 or 1
                tm:setTile(x, y, tile_id)
                grid:setWalkable(x, y, tile_id ~= 0)
            end
        end

        local pf   = lurek.pathfind.newPathfinder(grid)
        local path = pf:findPath(0, 5, 9, 5)

        expect_not_nil(path, "path found around wall column 5")
        local len = path:getLength()
        expect_true(len > 9, "path detours around wall (longer than direct route)")
    end)

    -- @covers lurek.tilemap.Tilemap.setTile
    -- @covers lurek.pathfind.Pathfinder.findPath
    -- @description Verifies a fully blocked tilemap produces no usable route in the derived navgrid.
    it("completely blocked tilemap yields no path", function()
        local tm   = lurek.tilemap.newTilemap(5, 5, 16, 16)
        local grid = lurek.pathfind.newNavGrid(5, 5)

        -- Block all tiles except start
        for y = 0, 4 do
            for x = 0, 4 do
                tm:setTile(x, y, 0)
                grid:setWalkable(x, y, false)
            end
        end
        -- Make start walkable
        grid:setWalkable(0, 0, true)

        local pf   = lurek.pathfind.newPathfinder(grid)
        local path = pf:findPath(0, 0, 4, 4)

        -- No path to surrounded destination
        local len = path and path:getLength() or 0
        expect_equal(0, len, "no path through completely blocked map")
    end)

    -- @covers lurek.tilemap.Tilemap.setTile
    -- @covers lurek.pathfind.Pathfinder.findPath
    -- @description Verifies an open tilemap floor yields a short direct path in the generated navgrid.
    it("open tilemap floor gives short direct path", function()
        local tm   = lurek.tilemap.newTilemap(10, 10, 16, 16)
        local grid = lurek.pathfind.newNavGrid(10, 10)

        for y = 0, 9 do
            for x = 0, 9 do
                tm:setTile(x, y, 1)
                grid:setWalkable(x, y, true)
            end
        end

        local pf   = lurek.pathfind.newPathfinder(grid)
        local path = pf:findPath(0, 0, 5, 0)

        expect_not_nil(path, "path found on open floor")
        local len = path:getLength()
        expect_true(len >= 5, "path length at least 5 steps for 5-tile distance")
        expect_true(len <= 8, "path length reasonable (not excessive)")
    end)
end)
test_summary()
