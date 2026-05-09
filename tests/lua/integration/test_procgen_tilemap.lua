-- Integration: procedural generation output placed into tilemap layers
describe("procgen + tilemap integration", function()
    -- @integration LTileMap:addLayer
    -- @integration LTileMap:getTile
    -- @integration LTileMap:setTile
    -- @integration lurek.procgen.perlinNoise
    -- @integration lurek.tilemap.newTileMap
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

    -- @integration LTileMap:addLayer
    -- @integration LTileMap:setTile
    -- @integration lurek.procgen.perlinNoise
    -- @integration lurek.tilemap.newTileMap
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

        -- Same seed -> same tiles
        for y = 0, 7 do
            for x = 0, 7 do
                local t1 = map1:getTile(1, x + 1, y + 1)
                local t2 = map2:getTile(1, x + 1, y + 1)
                expect_equal(t1, t2, "tile(" .. x .. "," .. y .. ") matches")
            end
        end
    end)

end)

test_summary()
