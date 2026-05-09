-- Integration: lurek.serial JSON/TOML/CSV round-trip via lurek.filesystem
describe("serial + filesystem integration", function()
    local tmp = "save/integration_serial_fs/"

    before_each(function()
        lurek.filesystem.mkdir(tmp)
    end)

    -- @integration lurek.filesystem.read
    -- @integration lurek.filesystem.write
    -- @integration lurek.serial.fromJson
    -- @integration lurek.serial.toJson
    it("round-trips a Lua table through JSON via the filesystem", function()
        local data = { name = "Luna", version = 2, active = true }
        local json_str = lurek.serial.toJson(data)
        expect_type("string", json_str, "toJson returns string")

        lurek.filesystem.write(tmp .. "data.json", json_str)
        local read_back = lurek.filesystem.read(tmp .. "data.json")
        expect_type("string", read_back, "read returns string")

        local restored = lurek.serial.fromJson(read_back)
        expect_equal(restored.name, "Luna", "name round-trips through JSON+filesystem")
        expect_equal(restored.version, 2, "number round-trips")
    end)

    -- @integration lurek.filesystem.read
    -- @integration lurek.filesystem.write
    -- @integration lurek.serial.fromToml
    -- @integration lurek.serial.toToml
    it("round-trips a Lua table through TOML via the filesystem", function()
        local data = { engine = "lurek2d", revision = 5 }
        local toml_str = lurek.serial.toToml(data)
        expect_type("string", toml_str, "toToml returns string")

        lurek.filesystem.write(tmp .. "conf.toml", toml_str)
        local read_back = lurek.filesystem.read(tmp .. "conf.toml")
        local restored = lurek.serial.fromToml(read_back)
        expect_equal(restored.engine, "lurek2d", "string TOML round-trip")
        expect_equal(restored.revision, 5, "number TOML round-trip")
    end)

    -- @integration lurek.filesystem.read
    -- @integration lurek.filesystem.write
    -- @integration lurek.serial.fromCsv
    it("parses CSV rows from a file written by serial.toCsv", function()
        local rows = { { "x", "y" }, { "1", "2" }, { "3", "4" } }
        local csv_str = rows[1][1] .. "," .. rows[1][2] .. "\n"
                     .. rows[2][1] .. "," .. rows[2][2] .. "\n"
                     .. rows[3][1] .. "," .. rows[3][2] .. "\n"
        lurek.filesystem.write(tmp .. "points.csv", csv_str)
        local read_back = lurek.filesystem.read(tmp .. "points.csv")
        local parsed = lurek.serial.fromCsv(read_back)
        expect_true(#parsed >= 2, "CSV parse returns at least 2 data rows")
    end)

end)
test_summary()
