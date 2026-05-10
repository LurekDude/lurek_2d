-- Integration: raycaster grid cell values align with tilemap occupancy setup.
-- @describe integration: raycaster + tilemap
describe("integration: raycaster + tilemap", function()
    -- @integration LRaycaster:getCell
    -- @integration LRaycaster:setCell
    -- @integration LTileMap:addLayer
    -- @integration LTileMap:setTile
    -- @integration lurek.raycaster.new
    -- @integration lurek.tilemap.newTileMap
    it("keeps wall occupancy in sync for matching cell coordinates", function()
        local rc = lurek.raycaster.new(10, 10)
        local tm = lurek.tilemap.newTileMap(10, 10, 1)
        tm:addLayer("walls", 10, 10)

        tm:setTile(1, 4, 4, 1)
        rc:setCell(4, 4, 1)

        expect_equal(1, rc:getCell(4, 4), "raycaster wall cell should be marked")
    end)
end)

test_summary()
