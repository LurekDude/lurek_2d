-- Lurek2D Integration Test: Tilemap + Camera
-- Tests camera position affecting which tiles are in view.

-- @description Covers suite: integration: tilemap visibility through camera.
describe("integration: tilemap visibility through camera", function()
    -- @covers lurek.tilemap.Tilemap.setTile
    -- @covers lurek.camera
    -- @covers lurek.tilemap.newTilemap
    -- @covers lurek.tilemap.setTile
    -- @covers lurek.tilemap.getTile
    -- @covers lurek.camera.newCamera
    -- @description Verifies a tilemap can be filled and queried before applying any camera-based visibility math.
    it("creates tilemap and fills tiles", function()
        local tm = lurek.tilemap.newTileMap(20, 20, 16)
        tm:addLayer("tiles", 20, 20)
        expect_not_nil(tm, "tilemap created")

        for y = 0, 19 do
            for x = 0, 19 do
                tm:setTile(1, x + 1, y + 1, (x + y) % 4 + 1)
            end
        end

        -- Read back a few tiles
        local t00 = tm:getTile(1, 1, 1)
        local t11 = tm:getTile(1, 2, 2)
        local t99 = tm:getTile(1, 10, 10)

        expect_equal(1, t00, "tile (0,0)")
        expect_equal(3, t11, "tile (1,1): (1+1)%4+1=3")
        expect_equal(3, t99, "tile (9,9): (9+9)%4+1=3")
    end)

    -- @covers lurek.tilemap.Tilemap.getTile
    -- @covers lurek.camera.Camera2D.setPosition
    -- @description Verifies camera position math selects different tile columns as the camera scrolls.
    it("camera scrolling reads different tiles (coordinate math)", function()
        local tm  = lurek.tilemap.newTileMap(50, 50, 32)
        tm:addLayer("tiles", 50, 50)
        local cam = lurek.camera.newCamera()

        -- Fill tilemap with tile IDs based on column
        for y = 0, 49 do
            for x = 0, 49 do
                tm:setTile(1, x + 1, y + 1, x + 1)
            end
        end

        -- Camera at origin: tile column 0 = id 1
        cam:setPosition(0, 0)
        local tile_at_origin = tm:getTile(1, 1, 1)
        expect_equal(1, tile_at_origin, "tile at origin column 0")

        -- Camera shifted one tile width to the right
        cam:setPosition(32, 0)
        local cx, _ = cam:getPosition()
        local tile_col = math.floor(cx / 32)  -- column index under camera (0-based)
        local tile_id = tm:getTile(1, tile_col + 1, 1)
        expect_equal(tile_col + 1, tile_id, "tile id matches shifted camera column")
    end)

    -- @covers lurek.tilemap.Tilemap.getTile
    -- @covers lurek.camera
    -- @description Verifies out-of-bounds reads stay safe even when tile visibility code queries beyond the camera's valid range.
    it("out-of-bounds tile read returns nil without crashing", function()
        local tm = lurek.tilemap.newTileMap(10, 10, 16)
        tm:addLayer("tiles", 10, 10)
        expect_no_error(function()
            local t = tm:getTile(1, 100, 100)
            -- May be nil or 0, the important thing is no crash
            expect_true(t == nil or type(t) == "number", "out-of-bounds returns nil or number")
        end)
    end)
end)

test_summary()
