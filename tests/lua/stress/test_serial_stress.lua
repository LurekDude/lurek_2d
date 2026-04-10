-- Lurek2D Stress Test: Serial Module
-- Tests encode/decode throughput under high volume
-- @stress serial throughput

describe("serial stress: base64 throughput", function()
    it("1000 base64 encode-decode cycles", function()
        -- @stress lurek.serial.base64Encode lurek.serial.base64Decode
        local input = string.rep("Stress test payload for serialization. ", 10)

        for i = 1, 1000 do
            local encoded = lurek.serial.base64Encode(input)
            local decoded = lurek.serial.base64Decode(encoded)
        end
        expect_true(true, "1000 base64 cycles completed")
    end)

    it("increasing payload sizes", function()
        for size = 1, 10 do
            local payload = string.rep("X", size * 100)
            local encoded = lurek.serial.base64Encode(payload)
            local decoded = lurek.serial.base64Decode(encoded)
            expect_equal(payload, decoded, "size " .. (size * 100) .. " round-trip")
        end
    end)
end)

describe("serial stress: data encode throughput", function()
    it("1000 JSON encode-decode cycles", function()
        local input = { x = 1.5, y = 2.5, name = "stress", items = { 1, 2, 3 } }

        for i = 1, 1000 do
            local json = lurek.data.encode("json", input)
            local out = lurek.data.decode("json", json)
        end
        expect_true(true, "1000 JSON cycles completed")
    end)

    it("100 compression cycles on 10KB data", function()
        local input = string.rep("ABCDEFGHIJ", 1000)  -- 10KB
        for i = 1, 100 do
            local compressed = lurek.data.compress(input)
            local decompressed = lurek.data.decompress(compressed)
        end
        expect_true(true, "100 compress cycles completed")
    end)
end)

test_summary()
