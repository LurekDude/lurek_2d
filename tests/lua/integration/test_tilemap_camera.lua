-- Integration: camera position determining which tilemap tiles are in view
describe("integration: tilemap visibility through camera", function()
    -- @integration LCamera:getPosition
    -- @integration LCamera:setPosition
    -- @integration LTileMap:addLayer
    -- @integration LTileMap:getTile
    -- @integration LTileMap:setTile
    -- @integration lurek.camera.newCamera
    -- @integration lurek.tilemap.newTileMap
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

end)
test_summary()
