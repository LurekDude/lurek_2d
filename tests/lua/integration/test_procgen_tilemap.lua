-- Lurek2D Integration Test: Procgen + Tilemap
-- Tests procedural generation feeding tilemap placement

describe("procgen + tilemap integration", function()
    it("noise2d generates tile terrain", function()
        local map = lurek.tilemap.newTileMap(32, 32)
        map:addLayer("tiles", 16, 16)

        -- Use procgen noise to assign tile types
        for y = 0, 15 do
            for x = 0, 15 do
                local n = lurek.procgen.perlinNoise(x * 0.1, y * 0.1, 1, 1)
                local tile_id
                if n < -0.2 then
                    tile_id = 0  -- water
                elseif n < 0.3 then
                    tile_id = 1  -- grass
                else
                    tile_id = 2  -- mountain
                end
                map:setTile(1, x + 1, y + 1, tile_id)
            end
        end

        -- Verify tiles were set
        local center_tile = map:getTile(1, 9, 9)
        expect_type("number", center_tile)
        expect_true(center_tile >= 0 and center_tile <= 2, "tile in valid range")
    end)

    it("seeded noise produces same tilemap", function()
        local function generate_map(seed)
            local map = lurek.tilemap.newTileMap(32, 32)
            map:addLayer("tiles", 8, 8)
            for y = 0, 7 do
                for x = 0, 7 do
                    local n = lurek.procgen.perlinNoise(x * 0.1 + seed, y * 0.1 + seed, 1, 1)
                    local tile_id = n < 0 and 0 or 1
                    map:setTile(1, x + 1, y + 1, tile_id)
                end
            end
            return map
        end

        local map1 = generate_map(42.0)
        local map2 = generate_map(42.0)

        -- Same seed                     same tiles
        for y = 0, 7 do
            for x = 0, 7 do
                local t1 = map1:getTile(1, x + 1, y + 1)
                local t2 = map2:getTile(1, x + 1, y + 1)
                expect_equal(t1, t2, "tile(" .. x .. "," .. y .. ") matches")
            end
        end
    end)

    it("different seeds produce different tilemaps", function()
        local map1_tiles = {}
        local map2_tiles = {}

        for y = 0, 3 do
            for x = 0, 3 do
                local n1 = lurek.procgen.perlinNoise(x * 0.1, y * 0.1, 1, 1)
                local n2 = lurek.procgen.perlinNoise(x * 0.1 + 3.7, y * 0.1 + 5.3, 1, 1)
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

--                                                                                                                                                                                                                                                                                                                                                                         
-- BSP Dungeon          Tilemap passability
--                                                                                                                                                                                                                                                                                                                                                                         
describe("bspDungeon          tilemap grid passability", function()

    it("BSP rooms can map to walkable tile IDs", function()
        local d = lurek.procgen.bspDungeon({ width = 40, height = 30, seed = 42 })
        -- Mark room cells as tile 1 (walkable), rest as tile 0 (wall)
        local grid = {}
        for i = 1, 40 * 30 do grid[i] = 0 end
        for _, r in ipairs(d.rooms) do
            for dy = 0, r.h - 1 do
                for dx = 0, r.w - 1 do
                    local idx = (r.y + dy) * 40 + (r.x + dx) + 1
                    if idx >= 1 and idx <= #grid then
                        grid[idx] = 1
                    end
                end
            end
        end
        expect_equal(40 * 30, #grid)
        -- At least one walkable cell
        local has_walkable = false
        for _, v in ipairs(grid) do
            if v == 1 then has_walkable = true break end
        end
        expect_true(has_walkable, "expected at least one walkable cell from rooms")
    end)

    it("roomsDungeon grid matches dimensions", function()
        local d = lurek.procgen.roomsDungeon({ width = 24, height = 16, max_rooms = 6, seed = 11 })
        expect_equal(24 * 16, #d.grid)
    end)

    it("WFC grid stays within tile ID set", function()
        local tiles = { { id = 0, weight = 1 }, { id = 1, weight = 1 }, { id = 2, weight = 0.5 } }
        local adj = { [0] = { 0, 1 }, [1] = { 0, 1, 2 }, [2] = { 1, 2 } }
        local g = lurek.procgen.wfcGenerate({ width = 10, height = 10, tiles = tiles, adjacencies = adj, seed = 3 })
        for _, c in ipairs(g.cells) do
            expect_true(c >= 0 and c <= 2, "unexpected tile id: " .. c)
        end
    end)

    it("heightmap drives biome layer assignment", function()
        local hm = lurek.procgen.heightmap({ width = 12, height = 12, seed = 77 })
        local biomes = { "deep_water", "water", "sand", "grass", "forest", "mountain", "snow" }
        local layer = {}
        for _, v in ipairs(hm.cells) do
            local idx = math.max(1, math.min(#biomes, math.floor(v * #biomes) + 1))
            table.insert(layer, biomes[idx])
        end
        expect_equal(12 * 12, #layer)
        expect_true(type(layer[1]) == "string", "biome should be a string")
    end)
end)
test_summary()
