-- Lurek2D Integration Test: Tilemap + Physics
-- Tests using tilemap solid tiles to create physics collision boundaries

describe("integration: tilemap solid tiles as physics boundaries", function()
    it("creates physics bodies from solid tiles", function()
        -- Create a small tilemap with ground
        local map = lurek.tilemap.newTileMap(32, 32, 16)
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        map:addTileSet(ts)
        ts:setSolid(1, true)  -- GID 1 is solid (1-based)

        map:addLayer("ground", 10, 10)

        -- Create a ground row (1-based tile indices: x=1..10, y=10, layer=1)
        for x = 1, 10 do
            map:setTile(1, x, 10, 1) -- solid ground at bottom row
        end

        -- Verify solid tiles
        expect_true(ts:isSolid(1), "tile GID 1 is solid")

        -- Create physics world matching tilemap
        local world_id = lurek.physics.newWorld(0, 200)

        -- Create static bodies for solid tiles
        local solid_count = 0
        for x = 1, 10 do
            local gid = map:getTile(1, x, 10)
            if gid > 0 and ts:isSolid(gid) then
                lurek.physics.newBody(world_id, (x-1) * 32 + 16, 9 * 32 + 16, "static")
                solid_count = solid_count + 1
            end
        end

        expect_equal(10, solid_count, "10 solid bodies created from tilemap")

        -- Drop a dynamic body - it should be stopped by the ground
        local ball = lurek.physics.newBody(world_id, 160, 0, "dynamic")

        -- Step simulation
        for step = 1, 120 do
            lurek.physics.step(world_id, 1.0 / 60.0)
        end

        local _, by = ball:getPosition()
        -- Ball should not have fallen through the ground (y < 320 = 10*32)
        expect_true(by < 350, "ball stopped by ground tiles")

        lurek.physics.destroyWorld(world_id)
    end)
end)

describe("integration: tilemap + pathfinding from solid tiles", function()
    it("creates navgrid from tilemap solids", function()
        local map = lurek.tilemap.newTileMap(32, 32, 16)
        local ts = lurek.tilemap.newTileSet(1, 16, 4, 32, 32)
        map:addTileSet(ts)
        ts:setSolid(1, true)  -- GID 1 is solid (1-based)

        map:addLayer("ground", 20, 20)

        -- Create walls (1-based tile indices: layer=1, x/y=1..20)
        for x = 1, 20 do
            map:setTile(1, x, 1, 1)   -- top wall
            map:setTile(1, x, 20, 1)  -- bottom wall
        end
        for y = 1, 20 do
            map:setTile(1, 1, y, 1)   -- left wall
            map:setTile(1, 20, y, 1)  -- right wall
        end
        -- Interior wall at tile x=11 (0-based x=10 in navgrid)
        for y = 3, 18 do
            map:setTile(1, 11, y, 1)
        end
        -- Gap in wall at tile (11, 11) = navgrid (10, 10)
        map:clearTile(1, 11, 11)

        -- Create navgrid from tilemap (navgrid 1-based, tilemap 1-based)
        local grid = lurek.pathfind.newNavGrid(20, 20)
        for y = 0, 19 do
            for x = 0, 19 do
                local gid = map:getTile(1, x+1, y+1)
                if gid > 0 and ts:isSolid(gid) then
                    grid:setBlocked(x+1, y+1, true)
                end
            end
        end

        -- Path from left to right should go through the gap
        local finder = lurek.pathfind.newPathfinder(grid)
        local path = finder:findPath(5, 10, 15, 10)
        expect_not_nil(path, "path found through gap")
        expect_true(#path > 0, "path has waypoints")
    end)
end)
test_summary()
