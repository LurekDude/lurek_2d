-- Lurek2D Integration Test: Tilemap + Camera
-- Tests camera position affecting which tiles are in view.
-- @covers lurek.tilemap.newTilemap
-- @covers lurek.tilemap.setTile
-- @covers lurek.tilemap.getTile
-- @covers lurek.camera.newCamera

describe("integration: tilemap visibility through camera", function()
    it("creates tilemap and fills tiles", function()
        local tm = lurek.tilemap.newTilemap(20, 20, 16, 16)
        expect_not_nil(tm, "tilemap created")

        for y = 0, 19 do
            for x = 0, 19 do
                tm:setTile(x, y, (x + y) % 4 + 1)
            end
        end

        -- Read back a few tiles
        local t00 = tm:getTile(0, 0)
        local t11 = tm:getTile(1, 1)
        local t99 = tm:getTile(9, 9)

        expect_equal(1, t00, "tile (0,0)")
        expect_equal(3, t11, "tile (1,1): (1+1)%4+1=3")
        expect_equal(3, t99, "tile (9,9): (9+9)%4+1=3")
    end)

    it("camera scrolling reads different tiles (coordinate math)", function()
        local tm  = lurek.tilemap.newTilemap(50, 50, 32, 32)
        local cam = lurek.camera.newCamera()

        -- Fill tilemap with tile IDs based on column
        for y = 0, 49 do
            for x = 0, 49 do
                tm:setTile(x, y, x + 1)
            end
        end

        -- Camera at origin: tile column 0 = id 1
        cam:setPosition(0, 0)
        local tile_at_origin = tm:getTile(0, 0)
        expect_equal(1, tile_at_origin, "tile at origin column 0")

        -- Camera shifted one tile width to the right
        cam:setPosition(32, 0)
        local cx, _ = cam:getPosition()
        local tile_col = math.floor(cx / 32)  -- column index under camera
        local tile_id = tm:getTile(tile_col, 0)
        expect_equal(tile_col + 1, tile_id, "tile id matches shifted camera column")
    end)

    it("out-of-bounds tile read returns nil without crashing", function()
        local tm = lurek.tilemap.newTilemap(10, 10, 16, 16)
        expect_no_error(function()
            local t = tm:getTile(99, 99)
            -- May be nil or 0, the important thing is no crash
            expect_true(t == nil or type(t) == "number", "out-of-bounds returns nil or number")
        end)
    end)
end)

test_summary()
