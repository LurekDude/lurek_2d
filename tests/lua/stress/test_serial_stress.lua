-- Lurek2D Stress Test: Serial Module
-- Tests encode/decode throughput under high volume

describe("serial stress: base64 throughput", function()
    it("1000 base64 encode-decode cycles", function()
        local input = string.rep("Stress test payload for serialization. ", 10)

        for i = 1, 1000 do
            local encoded = lurek.data.encode("base64", input)
            local decoded = lurek.data.decode("base64", encoded)
        end
        expect_true(true, "1000 base64 cycles completed")
    end)

    it("increasing payload sizes", function()
        for size = 1, 10 do
            local payload = string.rep("X", size * 100)
            local encoded = lurek.data.encode("base64", payload)
            local decoded = lurek.data.decode("base64", encoded)
            expect_equal(payload, decoded, "size " .. (size * 100) .. " round-trip")
        end
    end)
end)

describe("serial stress: data encode throughput", function()
    it("1000 JSON encode-decode cycles", function()
        local input = { x = 1.5, y = 2.5, name = "stress", items = { 1, 2, 3 } }

        if type(lurek.serial) ~= "table" or type(lurek.serial.toJson) ~= "function" or type(lurek.serial.fromJson) ~= "function" then
            expect_true(true)
            return
        end

        for i = 1, 1000 do
            local json = lurek.serial.toJson(input, false)
            local _out = lurek.serial.fromJson(json)
        end
        expect_true(true, "1000 JSON cycles completed")
    end)

    it("100 compression cycles on 10KB data", function()
        local input = string.rep("ABCDEFGHIJ", 1000)  -- 10KB
        for i = 1, 100 do
            local compressed = lurek.data.compress("deflate", input)
            local decompressed = lurek.data.decompress("deflate", compressed)
        end
        expect_true(true, "100 compress cycles completed")
    end)
end)
test_summary()
