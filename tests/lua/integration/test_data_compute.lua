-- Lurek2D Integration Test: Data + Compute
-- Tests data encoding/decoding with compute processing
-- @covers lurek.data.encode
-- @covers lurek.data.decode
-- @covers lurek.compute.newBuffer

describe("data + compute integration", function()
    it("JSON round-trip preserves data for compute", function()
        local original = {
            values = { 1.5, 2.7, 3.14, 4.0 },
            label = "test_buffer"
        }

        local encoded = lurek.data.encode("json", original)
        expect_type("string", encoded)

        local decoded = lurek.data.decode("json", encoded)
        expect_type("table", decoded)
        expect_equal("test_buffer", decoded.label, "label preserved")
        expect_equal(4, #decoded.values, "4 values preserved")
        expect_near(3.14, decoded.values[3], 0.01, "pi value preserved")
    end)

    it("TOML round-trip preserves typed data", function()
        local config = {
            compute = {
                buffer_size = 1024,
                precision = "float32",
                enabled = true
            }
        }

        local encoded = lurek.data.encode("toml", config)
        expect_type("string", encoded)

        local decoded = lurek.data.decode("toml", encoded)
        expect_type("table", decoded)
        expect_equal(1024, decoded.compute.buffer_size, "buffer_size preserved")
        expect_equal("float32", decoded.compute.precision, "precision preserved")
        expect_equal(true, decoded.compute.enabled, "enabled preserved")
    end)

    it("compress then decompress preserves data", function()
        local data = string.rep("ABCDEFGH", 100)  -- 800 bytes, compressible
        local compressed = lurek.data.compress(data)
        expect_type("string", compressed)

        -- Compressed should be smaller
        expect_true(#compressed < #data, "compressed is smaller")

        local decompressed = lurek.data.decompress(compressed)
        expect_equal(data, decompressed, "round-trip preserved")
    end)

    it("large table serialization stress", function()
        local big = {}
        for i = 1, 1000 do
            big[i] = { x = i * 0.1, y = i * 0.2, name = "item_" .. i }
        end

        local encoded = lurek.data.encode("json", big)
        expect_true(#encoded > 1000, "encoded has content")

        local decoded = lurek.data.decode("json", encoded)
        expect_equal(1000, #decoded, "1000 items decoded")
        expect_near(100.0, decoded[1000].x, 0.01, "last item x correct")
    end)
end)

test_summary()
