-- Lurek2D Stress Test: Large Tilemap Operations
-- Tests creating and manipulating large tilemaps at scale

describe("tilemap stress: large map creation", function()
    it("creates a 500x500 tilemap and fills it", function()
        local map = lurek.tilemap.newTileMap(32, 32, 16)
        local ts = lurek.tilemap.newTileSet(1, 256, 16, 32, 32, 0, 0)
        map:addTileSet(ts)
        map:addLayer("ground", 500, 500)

        -- TileMap coords are 1-based
        for y = 1, 500 do
            for x = 1, 500 do
                map:setTile(1, x, y, 1)
            end
        end

        -- Verify corners (1-based)
        expect_equal(1, map:getTile(1, 1, 1), "top-left tile")
        expect_equal(1, map:getTile(1, 500, 500), "bottom-right tile")
        expect_equal(1, map:getTile(1, 250, 250), "center tile")
    end)

    it("reads back all tiles from a 200x200 map", function()
        local map = lurek.tilemap.newTileMap(32, 32, 16)
        local ts = lurek.tilemap.newTileSet(1, 256, 16, 32, 32, 0, 0)
        map:addTileSet(ts)
        map:addLayer("ground", 200, 200)

        -- Fill with pattern: tile ID = ((x + y) % 255) + 1 (1-based coords)
        for y = 1, 200 do
            for x = 1, 200 do
                local gid = ((x + y) % 255) + 1
                map:setTile(1, x, y, gid)
            end
        end

        -- Verify pattern
        local mismatches = 0
        for y = 1, 200 do
            for x = 1, 200 do
                local expected = ((x + y) % 255) + 1
                if map:getTile(1, x, y) ~= expected then
                    mismatches = mismatches + 1
                end
            end
        end
        expect_equal(0, mismatches, "all tiles match expected pattern")
    end)

    it("handles multiple layers on a 100x100 map", function()
        local map = lurek.tilemap.newTileMap(32, 32, 16)
        local ts = lurek.tilemap.newTileSet(1, 256, 16, 32, 32, 0, 0)
        map:addTileSet(ts)

        -- Create 5 layers (1-based indices)
        for i = 1, 5 do
            map:addLayer("layer_" .. i, 100, 100)
        end

        -- Fill each layer (1-based layer and coords)
        for layer = 1, 5 do
            for y = 1, 100 do
                for x = 1, 100 do
                    map:setTile(layer, x, y, layer)
                end
            end
        end

        -- Verify each layer independently
        for layer = 1, 5 do
            expect_equal(layer, map:getTile(layer, 50, 50), "layer " .. layer .. " center tile")
        end
    end)
end)

describe("tilemap stress: fill operations", function()
    it("fills entire layer with one GID", function()
        local map = lurek.tilemap.newTileMap(32, 32, 16)
        local ts = lurek.tilemap.newTileSet(1, 256, 16, 32, 32, 0, 0)
        map:addTileSet(ts)
        map:addLayer("ground", 100, 100)

        map:fill(1, 42)

        expect_equal(42, map:getTile(1, 1, 1), "fill top-left")
        expect_equal(42, map:getTile(1, 100, 100), "fill bottom-right")
        expect_equal(42, map:getTile(1, 50, 50), "fill center")
    end)

    it("setTile overwrites filled area", function()
        local map = lurek.tilemap.newTileMap(32, 32, 16)
        local ts = lurek.tilemap.newTileSet(1, 256, 16, 32, 32, 0, 0)
        map:addTileSet(ts)
        map:addLayer("ground", 100, 100)

        map:fill(1, 42)
        map:setTile(1, 50, 50, 99)
        expect_equal(99, map:getTile(1, 50, 50), "overwritten tile")
        expect_equal(42, map:getTile(1, 49, 49), "untouched tile")
    end)

    it("ChunkMap setTile/getTile roundtrip", function()
        -- ChunkMap: no layer param, 0-based coords
        local cm = lurek.tilemap.newChunkMap(16)
        cm:setTile(5, 5, 42)
        expect_equal(42, cm:getTile(5, 5), "chunk tile preserved")
    end)
end)
