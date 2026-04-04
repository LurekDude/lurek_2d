-- Luna2D Integration Test: Tilemap + Physics
-- Tests using tilemap solid tiles to create physics collision boundaries

describe("integration: tilemap solid tiles as physics boundaries", function()
    it("creates physics bodies from solid tiles", function()
        -- Create a small tilemap with ground
        local map = luna.tilemap.newTileMap(32, 32, 16)
        map:addTileSet(1, 16, 4, 32, 32, 0, 0)
        -- Mark tile 0 (GID 1) as solid
        local ts = map:getTileSet(0)
        ts:setSolid(0, true)

        map:addLayer("ground", 10, 10)

        -- Create a ground row
        for x = 0, 9 do
            map:setTile(0, x, 9, 1) -- solid ground at bottom
        end

        -- Verify solid tiles
        expect_true(ts:isSolid(0), "tile 0 is solid")

        -- Create physics world matching tilemap
        local world_id = luna.physics.newWorld(0, 200)

        -- Create static bodies for solid tiles
        local solid_count = 0
        for x = 0, 9 do
            local gid = map:getTile(0, x, 9)
            if gid > 0 and ts:isSolid(gid - 1) then
                luna.physics.newBody(world_id, x * 32 + 16, 9 * 32 + 16, "static")
                solid_count = solid_count + 1
            end
        end

        expect_equal(10, solid_count, "10 solid bodies created from tilemap")

        -- Drop a dynamic body - it should be stopped by the ground
        local ball = luna.physics.newBody(world_id, 160, 0, "dynamic")

        -- Step simulation
        for step = 1, 120 do
            luna.physics.step(world_id, 1.0 / 60.0)
        end

        local _, by = luna.physics.getBodyPosition(ball)
        -- Ball should not have fallen through the ground (y < 320 = 10*32)
        expect_true(by < 350, "ball stopped by ground tiles")

        luna.physics.destroyWorld(world_id)
    end)
end)

describe("integration: tilemap + pathfinding from solid tiles", function()
    it("creates navgrid from tilemap solids", function()
        local map = luna.tilemap.newTileMap(32, 32, 16)
        map:addTileSet(1, 16, 4, 32, 32, 0, 0)
        local ts = map:getTileSet(0)
        ts:setSolid(0, true)  -- GID 1 is solid

        map:addLayer("ground", 20, 20)

        -- Create walls
        for x = 0, 19 do
            map:setTile(0, x, 0, 1)
            map:setTile(0, x, 19, 1)
        end
        for y = 0, 19 do
            map:setTile(0, 0, y, 1)
            map:setTile(0, 19, y, 1)
        end
        -- Interior wall
        for y = 2, 17 do
            map:setTile(0, 10, y, 1)
        end
        -- Gap in wall
        map:clearTile(0, 10, 10)

        -- Create navgrid from tilemap
        local grid = luna.pathfinding.newNavGrid(20, 20)
        for y = 0, 19 do
            for x = 0, 19 do
                local gid = map:getTile(0, x, y)
                if gid > 0 and ts:isSolid(gid - 1) then
                    grid:setBlocked(x, y, true)
                end
            end
        end

        -- Path from left to right should go through the gap
        local path = grid:findPath(5, 10, 15, 10)
        expect_not_nil(path, "path found through gap")
        expect_true(#path > 0, "path has waypoints")
    end)
end)
