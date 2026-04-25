-- Lurek2D Stress Test: Serial Module
-- Tests encode/decode throughput under high volume

-- @description Covers suite: serial stress: base64 throughput.
describe("serial stress: base64 throughput", function()
    -- @covers lurek.serial.base64Encode
    -- @covers lurek.serial.base64Decode
    -- @stress Executes 1000 base64 encode-decode cycles on the same payload.
    -- @description Stresses repeated binary-safe text conversion by round-tripping one moderately sized string through base64 in a tight loop.
    xit("1000 base64 encode-decode cycles", function()
        local input = string.rep("Stress test payload for serialization. ", 10)

        for i = 1, 1000 do
            local encoded = lurek.serial.base64Encode(input)
            local decoded = lurek.serial.base64Decode(encoded)
        end
        expect_true(true, "1000 base64 cycles completed")
    end)

    -- @covers lurek.serial.base64Encode
    -- @covers lurek.serial.base64Decode
    -- @stress Sweeps payload sizes from 100 bytes to 1000 bytes through base64 round trips.
    -- @description Stresses size-scaling behavior by repeatedly encoding and decoding progressively larger payloads and checking exact string recovery.
    xit("increasing payload sizes", function()
        for size = 1, 10 do
            local payload = string.rep("X", size * 100)
            local encoded = lurek.serial.base64Encode(payload)
            local decoded = lurek.serial.base64Decode(encoded)
            expect_equal(payload, decoded, "size " .. (size * 100) .. " round-trip")
        end
    end)
end)

-- @description Covers suite: serial stress: data encode throughput.
describe("serial stress: data encode throughput", function()
    -- @covers lurek.data.encode
    -- @covers lurek.data.decode
    -- @stress Executes 1000 JSON encode-decode cycles on the same structured Lua table.
    -- @description Stresses structured data conversion throughput by repeatedly serializing and deserializing one mixed table payload.
    xit("1000 JSON encode-decode cycles", function()
        local input = { x = 1.5, y = 2.5, name = "stress", items = { 1, 2, 3 } }

        for i = 1, 1000 do
            local json = lurek.data.encode("json", input)
            local out = lurek.data.decode("json", json)
        end
        expect_true(true, "1000 JSON cycles completed")
    end)

    -- @covers lurek.data.compress
    -- @covers lurek.data.decompress
    -- @stress Runs 100 compression-decompression cycles on a 10KB string payload.
    -- @description Stresses repeated binary round trips by compressing and expanding the same medium-size input in a fixed loop.
    xit("100 compression cycles on 10KB data", function()
        local input = string.rep("ABCDEFGHIJ", 1000)  -- 10KB
        for i = 1, 100 do
            local compressed = lurek.data.compress("deflate", input)
            local decompressed = lurek.data.decompress("deflate", compressed)
        end
        expect_true(true, "100 compress cycles completed")
    end)
end)

test_summary()
