-- Lurek2D Integration Test: Data + Filesystem
-- Tests saving JSON data to a file and reading it back.
-- Uses lurek.serial.toJson/fromJson (not lurek.data.encode which is binary-only).

describe("integration: data serialization with filesystem I/O", function()
    local TMP_PATH = "save/test_data_fs_tmp.json"

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

    it("round-trips nested data correctly", function()
        local nested = {
            meta = { version = 2, engine = "lurek" },
            data = { {x=1, y=2}, {x=3, y=4} },
        }

        local encoded = lurek.serial.toJson(nested)
        local decoded = lurek.serial.fromJson(encoded)

        expect_equal(2, decoded.meta.version, "nested version")
        expect_equal("lurek", decoded.meta.engine, "nested engine")
    end)

    it("large table serialization stress", function()
        local big = {}
        for i = 1, 200 do
            big[i] = { x = i * 0.1, y = i * 0.2, name = "item_" .. i }
        end

        local encoded = lurek.serial.toJson(big)
        expect_true(#encoded > 100, "encoded has content")

        local decoded = lurek.serial.fromJson(encoded)
        expect_equal(200, #decoded, "200 items decoded")
        expect_near(20.0, decoded[200].x, 0.1, "last item x correct")
    end)
end)
test_summary()
