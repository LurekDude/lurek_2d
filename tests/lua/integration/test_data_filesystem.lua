-- Lurek2D Integration Test: Data + Filesystem
-- Tests saving JSON data to a file and reading it back.
-- @covers lurek.data.encode
-- @covers lurek.data.decode
-- @covers lurek.filesystem.write
-- @covers lurek.filesystem.read
-- @covers lurek.filesystem.exists
-- @covers lurek.filesystem.remove

describe("integration: data serialization with filesystem I/O", function()
    local TMP_PATH = "test_data_fs_tmp.json"

    it("encodes table to JSON and writes to file", function()
        local record = {
            name  = "player1",
            score = 9999,
            level = 7,
            tags  = {"fast", "bold"},
        }

        local json_str = lurek.data.encode("json", record)
        expect_type("string", json_str, "encoded to JSON string")
        expect_true(#json_str > 0, "JSON string is non-empty")

        expect_no_error(function()
            lurek.filesystem.write(TMP_PATH, json_str)
        end)
    end)

    it("reads file back and decodes JSON to original table", function()
        local exists = lurek.filesystem.exists(TMP_PATH)
        expect_true(exists, "temp file exists after write")

        local content = lurek.filesystem.read(TMP_PATH)
        expect_type("string", content, "file content is string")

        local decoded = lurek.data.decode("json", content)
        expect_equal("player1", decoded.name,  "name round-tripped")
        expect_equal(9999,      decoded.score, "score round-tripped")
        expect_equal(7,         decoded.level, "level round-tripped")
    end)

    it("cleans up temporary file", function()
        if lurek.filesystem.exists(TMP_PATH) then
            expect_no_error(function()
                lurek.filesystem.remove(TMP_PATH)
            end)
        end
        expect_true(true, "cleanup done")
    end)

    it("round-trips nested data correctly", function()
        local nested = {
            meta = { version = 2, engine = "lurek" },
            data = { {x=1,y=2}, {x=3,y=4} },
        }

        local encoded = lurek.data.encode("json", nested)
        local decoded = lurek.data.decode("json", encoded)

        expect_equal(2, decoded.meta.version, "nested version")
        expect_equal("lurek", decoded.meta.engine, "nested engine")
    end)
end)

test_summary()
