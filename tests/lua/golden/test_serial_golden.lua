-- Lurek2D Golden Test: Serial Module
-- Verifies hash and encoding functions produce deterministic output
-- @golden serial determinism

describe("golden: serial base64 encoding", function()
    it("base64 encode is deterministic", function()
        local input = "Hello, Lurek2D!"
        local b64_1 = lurek.serial.base64Encode(input)
        local b64_2 = lurek.serial.base64Encode(input)
        expect_equal(b64_1, b64_2, "same input → same base64")
    end)

    it("base64 round-trip preserves data", function()
        local input = "The quick brown fox jumps over the lazy dog."
        local encoded = lurek.serial.base64Encode(input)
        local decoded = lurek.serial.base64Decode(encoded)
        expect_equal(input, decoded, "base64 round-trip")
    end)

    it("empty string base64 round-trip", function()
        local encoded = lurek.serial.base64Encode("")
        local decoded = lurek.serial.base64Decode(encoded)
        expect_equal("", decoded, "empty base64 round-trip")
    end)

    it("binary-like data base64 round-trip", function()
        -- String with bytes 0-255
        local parts = {}
        for i = 1, 128 do
            parts[i] = string.char(i)
        end
        local input = table.concat(parts)
        local encoded = lurek.serial.base64Encode(input)
        local decoded = lurek.serial.base64Decode(encoded)
        expect_equal(input, decoded, "binary base64 round-trip")
    end)
end)

describe("golden: serial hashing", function()
    it("sha256 is deterministic", function()
        if not lurek.serial.sha256 then
            pending("sha256 not available")
            return
        end
        local hash1 = lurek.serial.sha256("test data")
        local hash2 = lurek.serial.sha256("test data")
        expect_equal(hash1, hash2, "same input → same hash")
    end)

    it("different inputs produce different hashes", function()
        if not lurek.serial.sha256 then
            pending("sha256 not available")
            return
        end
        local h1 = lurek.serial.sha256("input_a")
        local h2 = lurek.serial.sha256("input_b")
        expect_true(h1 ~= h2, "different inputs → different hashes")
    end)

    it("crc32 is deterministic", function()
        if not lurek.serial.crc32 then
            pending("crc32 not available")
            return
        end
        local c1 = lurek.serial.crc32("hello world")
        local c2 = lurek.serial.crc32("hello world")
        expect_equal(c1, c2, "crc32 deterministic")
    end)
end)

describe("golden: serial hex encoding", function()
    it("hex round-trip preserves data", function()
        if not lurek.serial.hexEncode then
            pending("hexEncode not available")
            return
        end
        local input = "Lurek2D Engine"
        local hex = lurek.serial.hexEncode(input)
        local decoded = lurek.serial.hexDecode(hex)
        expect_equal(input, decoded, "hex round-trip")
    end)
end)

test_summary()
