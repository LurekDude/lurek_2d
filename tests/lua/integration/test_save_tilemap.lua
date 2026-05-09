-- Integration: save manager collecting and restoring tilemap tile data
describe("integration: savegame collects and restores tilemap state", function()
    -- @integration LSaveManager:collect
    -- @integration LSaveManager:register
    -- @integration LTileMap:addLayer
    -- @integration LTileMap:getTile
    -- @integration LTileMap:setTile
    -- @integration lurek.save.newSaveManager
    -- @integration lurek.tilemap.newTileMap
    it("registers tilemap handler and collects tile data", function()
        local sm = lurek.save.newSaveManager()
        local tm = lurek.tilemap.newTileMap(16, 16)
        tm:addLayer("tiles", 5, 5)

        -- Set some tiles
        tm:setTile(1, 1, 1, 1)
        tm:setTile(1, 2, 1, 2)
        tm:setTile(1, 3, 3, 3)

        local saved_tiles = nil

        sm:register("tilemap", function()
            -- Collect: snapshot the relevant tiles
            local tiles = {}
            for y = 1, 5 do
                for x = 1, 5 do
                    local id = tm:getTile(1, x, y)
                    if id and id ~= 0 then
                        tiles[#tiles + 1] = {x = x, y = y, id = id}
                    end
                end
            end
            saved_tiles = tiles
            return tiles
        end, function(data)
            -- Restore: apply tiles back
            if data then
                for _, entry in ipairs(data) do
                    tm:setTile(1, entry.x, entry.y, entry.id)
                end
            end
        end)

        -- Trigger collect
        sm:collect()
        expect_not_nil(saved_tiles, "tilemap state was collected")
        expect_true(#saved_tiles >= 3, "at least 3 non-zero tiles collected")
    end)

end)
test_summary()
