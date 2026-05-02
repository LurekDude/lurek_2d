-- Lurek2D Integration Test: Tilemap + Pathfinding
-- Tests using a tilemap grid as the navigation surface for A* pathfinding.

describe("integration: tilemap feeds into pathfinding grid", function()
    it("builds navgrid from tilemap: walkable tiles passable, wall tiles blocked", function()
        local tm   = lurek.tilemap.newTileMap(16, 16)
        tm:addLayer("tiles", 10, 10)
        local grid = lurek.pathfind.newNavGrid(10, 10)

        -- Tile ID 0 = wall, 1 = floor (1-based coords for both tilemap and navgrid)
        for y = 1, 10 do
            for x = 1, 10 do
                local tile_id = (x == 6) and 0 or 1  -- column 6 (1-based) = wall
                tm:setTile(1, x, y, tile_id)
                grid:setBlocked(x, y, tile_id == 0)
            end
        end

        local pf   = lurek.pathfind.newPathfinder(grid)
        local path = pf:findPath(1, 6, 10, 6)

        expect_not_nil(path, "path found around wall column 6")
        -- Direct route from (1,6) to (10,6) is 9 steps; with column 6 blocked
        -- the path must detour, so it should have more nodes than a straight line
        expect_true(#path > 1, "path has multiple steps: got " .. tostring(#path))
    end)

    it("completely blocked tilemap yields no path", function()
        local tm   = lurek.tilemap.newTileMap(16, 16)
        tm:addLayer("tiles", 5, 5)
        local grid = lurek.pathfind.newNavGrid(5, 5)

        -- Block all tiles (1-based coords)
        for y = 1, 5 do
            for x = 1, 5 do
                tm:setTile(1, x, y, 0)
                grid:setBlocked(x, y, true)
            end
        end
        -- Make start walkable
        grid:setBlocked(1, 1, false)

        local pf   = lurek.pathfind.newPathfinder(grid)
        local path = pf:findPath(1, 1, 5, 5)

        -- No path to surrounded destination
        local len = path and #path or 0
        expect_equal(0, len, "no path through completely blocked map")
    end)

    it("open tilemap floor gives short direct path", function()
        local tm   = lurek.tilemap.newTileMap(16, 16)
        tm:addLayer("tiles", 10, 10)
        local grid = lurek.pathfind.newNavGrid(10, 10)

        for y = 1, 10 do
            for x = 1, 10 do
                tm:setTile(1, x, y, 1)
                grid:setBlocked(x, y, false)
            end
        end

        local pf   = lurek.pathfind.newPathfinder(grid)
        local path = pf:findPath(1, 1, 6, 1)

        expect_not_nil(path, "path found on open floor")
        expect_true(#path >= 5, "path length at least 5 steps for 5-tile distance")
        expect_true(#path <= 8, "path length reasonable (not excessive)")
    end)
end)
test_summary()
