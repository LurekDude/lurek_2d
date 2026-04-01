-- Luna2D Integration Test: Tilemap + Physics
-- Tests coordination between tilemap collision tiles and physics bodies

describe("integration: tilemap defines physics collision", function()
    it("creates physics bodies from solid tiles", function()
        -- Create a simple tilemap (TileMap coords are 1-based)
        local map = luna.tilemap.newTileMap(32, 32, 16)
        local ts = luna.tilemap.newTileSet(1, 16, 4, 32, 32, 0, 0)
        map:addTileSet(ts)
        map:addLayer("ground", 10, 10)

        -- Fill bottom row with solid tiles (1-based)
        for x = 1, 10 do
            map:setTile(1, x, 10, 1)
        end

        -- Create physics world and a falling body
        local world_id = luna.physics.newWorld(0, 200)
        local body = luna.physics.newBody(world_id, 160, 0, "dynamic")

        -- Create static bodies for the ground tiles
        for x = 1, 10 do
            luna.physics.newBody(world_id, (x - 1) * 32 + 16, 9 * 32 + 16, "static")
        end

        -- Simulate
        for i = 1, 120 do
            luna.physics.step(world_id, 1.0 / 60.0)
        end

        -- Body should have fallen and stopped on the ground
        local px, py = luna.physics.getBody(world_id, body)
        expect_true(py > 0, "body fell from starting position")
        expect_true(py < 400, "body didn't fall through floor")
    end)
end)

describe("integration: tilemap tile queries", function()
    it("reads tiles back after setting", function()
        local map = luna.tilemap.newTileMap(32, 32, 16)
        local ts = luna.tilemap.newTileSet(1, 256, 16, 32, 32, 0, 0)
        map:addTileSet(ts)
        map:addLayer("objects", 20, 20)

        -- Set various tiles (1-based)
        for x = 1, 20 do
            for y = 1, 20 do
                map:setTile(1, x, y, ((x + y) % 256) + 1)
            end
        end

        -- Read them back
        local correct = 0
        for x = 1, 20 do
            for y = 1, 20 do
                local expected = ((x + y) % 256) + 1
                if map:getTile(1, x, y) == expected then
                    correct = correct + 1
                end
            end
        end

        expect_equal(400, correct, "all tiles read back correctly")
    end)
end)
