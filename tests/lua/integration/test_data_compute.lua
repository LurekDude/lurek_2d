-- Integration: serial encoding/decoding with compute array processing
describe("data + compute integration", function()
    -- @integration lurek.serial.fromJson
    -- @integration lurek.compute.fromTable
    -- @integration LArray:sum
    -- @integration lurek.serial.toJson
    it("JSON round-trip preserves data for compute", function()
        local original = {
            values = { 1.5, 2.7, 3.14, 4.0 },
            label = "test_buffer"
        }

        local encoded = lurek.serial.toJson(original)
        expect_type("string", encoded)

        local decoded = lurek.serial.fromJson(encoded)
        expect_type("table", decoded)
        expect_equal("test_buffer", decoded.label, "label preserved")
        expect_equal(4, #decoded.values, "4 values preserved")
        expect_near(3.14, decoded.values[3], 0.01, "pi value preserved")

        -- Real integration: feed decoded values into compute and verify math.
        local arr = lurek.compute.fromTable(decoded.values)
        expect_near(11.34, arr:sum(), 0.01, "sum preserved through serial + compute")
    end)

    -- @integration lurek.serial.fromToml
    -- @integration LArray:getSize
    -- @integration lurek.compute.zeros
    -- @integration lurek.serial.toToml
    it("TOML round-trip preserves typed data", function()
        local config = {
            compute = {
                buffer_size = 1024,
                precision = "float32",
                enabled = true
            }
        }

        local encoded = lurek.serial.toToml(config)
        expect_type("string", encoded)

        local decoded = lurek.serial.fromToml(encoded)
        expect_type("table", decoded)
        expect_equal(1024, decoded.compute.buffer_size, "buffer_size preserved")
        expect_equal("float32", decoded.compute.precision, "precision preserved")
        expect_equal(true, decoded.compute.enabled, "enabled preserved")

        -- Real integration: use decoded config to build compute buffer.
        local buf = lurek.compute.zeros({ decoded.compute.buffer_size })
        expect_equal(1024, buf:getSize(), "decoded buffer_size used by compute")
    end)

    -- @integration lurek.serial.fromJson
    -- @integration lurek.compute.fromTable
    -- @integration LArray:sum
    -- @integration lurek.serial.toJson
    it("serial round-trip preserves compute config", function()
        -- lurek.data.compress is not available headless; test serial round-trip instead
        local payload = {
            buffers  = { { name = "positions", size = 1024 }, { name = "normals", size = 1024 } },
            dispatch = { x = 64, y = 1, z = 1 },
            precision = "float32",
        }
        local encoded   = lurek.serial.toJson(payload)
        expect_type("string", encoded)
        local decoded = lurek.serial.fromJson(encoded)
        expect_not_nil(decoded, "decoded is non-nil")
        expect_equal("float32", decoded.precision, "precision preserved")
        expect_equal(64, decoded.dispatch.x, "dispatch.x preserved")
        expect_equal(2, #decoded.buffers, "two buffers preserved")

        -- Real integration: aggregate decoded buffer sizes in compute.
        local sizes = { decoded.buffers[1].size, decoded.buffers[2].size }
        local arr = lurek.compute.fromTable(sizes)
        expect_equal(2048, arr:sum(), "decoded buffer sizes usable by compute")
    end)

    -- @integration lurek.serial.fromJson
    -- @integration lurek.compute.fromTable
    -- @integration LArray:mean
    -- @integration lurek.serial.toJson
    it("large table serialization stress", function()
        local big = {}
        for i = 1, 1000 do
            big[i] = { x = i * 0.1, y = i * 0.2, name = "item_" .. i }
        end

        local encoded = lurek.serial.toJson(big)
        expect_true(#encoded > 1000, "encoded has content")

        local decoded = lurek.serial.fromJson(encoded)
        expect_equal(1000, #decoded, "1000 items decoded")
        expect_near(100.0, decoded[1000].x, 0.01, "last item x correct")

        -- Real integration: compute over decoded numeric data.
        local sample = {}
        for i = 1, 1000 do
            sample[i] = decoded[i].x
        end
        local arr = lurek.compute.fromTable(sample)
        expect_near(50.05, arr:mean(), 0.01, "mean(x) preserved after serial round-trip")
    end)
end)
test_summary()
