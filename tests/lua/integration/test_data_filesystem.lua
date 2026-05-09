-- Integration: JSON serialization round-trip via filesystem I/O
describe("integration: data serialization with filesystem I/O", function()
    local TMP_PATH = "save/test_data_fs_tmp.json"

    -- @integration lurek.filesystem.exists
    -- @integration lurek.filesystem.read
    -- @integration lurek.filesystem.remove
    -- @integration lurek.filesystem.write
    -- @integration lurek.serial.fromJson
    -- @integration lurek.serial.toJson
    it("encodes table to JSON, writes, and reads back", function()
        local record = {
            name  = "player1",
            score = 9999,
            level = 7,
        }

        local json_str = lurek.serial.toJson(record)
        expect_type("string", json_str, "encoded to JSON string")
        expect_true(#json_str > 0, "JSON string is non-empty")

        -- Write, read back, and decode in the same it-block so the file persists
        expect_no_error(function()
            lurek.filesystem.write(TMP_PATH, json_str)
        end)

        local exists = lurek.filesystem.exists(TMP_PATH)
        expect_true(exists, "temp file exists after write")

        local content = lurek.filesystem.read(TMP_PATH)
        expect_type("string", content, "file content is string")

        local decoded = lurek.serial.fromJson(content)
        expect_equal("player1", decoded.name,  "name round-tripped")
        expect_equal(9999,      decoded.score, "score round-tripped")
        expect_equal(7,         decoded.level, "level round-tripped")

        -- Cleanup
        if lurek.filesystem.exists(TMP_PATH) then
            pcall(lurek.filesystem.remove, TMP_PATH)
        end
    end)

end)
test_summary()
