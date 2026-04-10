-- Lurek2D Integration Test: Procgen + Tilemap
-- Tests procedural generation feeding tilemap placement
-- @covers lurek.procgen.noise2d
-- @covers lurek.tilemap.newTilemap

describe("procgen + tilemap integration", function()
    it("noise2d generates tile terrain", function()
        local map = lurek.tilemap.newTilemap(16, 16, 32, 32)

        -- Use procgen noise to assign tile types
        for y = 0, 15 do
            for x = 0, 15 do
                local n = lurek.procgen.noise2d(x * 0.1, y * 0.1)
                local tile_id
                if n < -0.2 then
                    tile_id = 0  -- water
                elseif n < 0.3 then
                    tile_id = 1  -- grass
                else
                    tile_id = 2  -- mountain
                end
                map:setTile(x, y, tile_id)
            end
        end

        -- Verify tiles were set
        local center_tile = map:getTile(8, 8)
        expect_type("number", center_tile)
        expect_true(center_tile >= 0 and center_tile <= 2, "tile in valid range")
    end)

    it("seeded noise produces same tilemap", function()
        local function generate_map(seed)
            local map = lurek.tilemap.newTilemap(8, 8, 32, 32)
            for y = 0, 7 do
                for x = 0, 7 do
                    local n = lurek.procgen.noise2d(x * 0.1 + seed, y * 0.1 + seed)
                    local tile_id = n < 0 and 0 or 1
                    map:setTile(x, y, tile_id)
                end
            end
            return map
        end

        local map1 = generate_map(42.0)
        local map2 = generate_map(42.0)

        -- Same seed → same tiles
        for y = 0, 7 do
            for x = 0, 7 do
                local t1 = map1:getTile(x, y)
                local t2 = map2:getTile(x, y)
                expect_equal(t1, t2, "tile(" .. x .. "," .. y .. ") matches")
            end
        end
    end)

    it("different seeds produce different tilemaps", function()
        local map1_tiles = {}
        local map2_tiles = {}

        for y = 0, 3 do
            for x = 0, 3 do
                local n1 = lurek.procgen.noise2d(x * 0.1, y * 0.1)
                local n2 = lurek.procgen.noise2d(x * 0.1 + 1000, y * 0.1 + 1000)
                table.insert(map1_tiles, n1)
                table.insert(map2_tiles, n2)
            end
        end

        -- At least one tile should differ
        local any_different = false
        for i = 1, #map1_tiles do
            if math.abs(map1_tiles[i] - map2_tiles[i]) > 0.001 then
                any_different = true
                break
            end
        end
        expect_true(any_different, "different offsets produce different noise")
    end)
end)

test_summary()
