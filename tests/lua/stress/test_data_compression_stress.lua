-- Lurek2D Stress Test: Data Compression, Hash, and Encoding Throughput
-- Tests compression output, hashing, and encode/decode at scale
-- @stress lurek.data.compress
-- @stress lurek.data.decode
-- @stress lurek.data.encode
-- @stress lurek.data.hash


describe("data stress: compression creates output", function()
    it("compresses a large string with deflate", function()
        local big_string = string.rep("Lurek2D engine test data with repetition. ", 1000)
        expect_true(#big_string > 30000, "data is large enough: " .. #big_string)

        -- compress returns a table of bytes (Vec<u8>)
        local compressed = lurek.data.compress("deflate", big_string, 6)
        expect_not_nil(compressed, "compression produced output")
        expect_true(#compressed > 0, "compressed data has content")
        expect_true(#compressed < #big_string, "compression reduces size")
    end)

    it("compresses with all supported formats", function()
        local data = string.rep("ABCDEFGHIJ", 1000) -- 10KB
        local formats = {"deflate", "gzip", "zlib", "lz4"}

        for _, fmt in ipairs(formats) do
            local compressed = lurek.data.compress(fmt, data, 6)
            expect_not_nil(compressed, fmt .. " produced output")
            expect_true(#compressed > 0, fmt .. " has content")
        end
    end)

    it("handles all compression levels", function()
        local data = string.rep("Test data for level comparison. ", 500)

        for level = 1, 9 do
            local compressed = lurek.data.compress("deflate", data, level)
            expect_not_nil(compressed, "level " .. level .. " produced output")
        end
    end)
end)

describe("data stress: hashing throughput", function()
    it("hashes 10KB data with all algorithms", function()
        local data = string.rep("Hash benchmark data. ", 500)

        local algos = {"md5", "sha1", "sha256", "sha512"}
        for _, algo in ipairs(algos) do
            local digest = lurek.data.hash(algo, data)
            expect_true(#digest > 0, algo .. " produces digest")
        end
    end)

    it("hash is deterministic across 100 calls", function()
        local data = "Determinism test vector"
        local first = lurek.data.hash("sha256", data)

        for i = 1, 100 do
            local digest = lurek.data.hash("sha256", data)
            expect_equal(first, digest, "call " .. i .. " matches")
        end
    end)

    it("different data produces different hashes", function()
        local h1 = lurek.data.hash("sha256", "data1")
        local h2 = lurek.data.hash("sha256", "data2")
        expect_true(h1 ~= h2, "different data gives different hashes")
    end)
end)

describe("data stress: encoding throughput", function()
    it("base64 encodes 50KB", function()
        local data = string.rep("Base64 benchmark. ", 2778) -- ~50KB
        local encoded = lurek.data.encode("base64", data)
        expect_not_nil(encoded, "base64 encode produced output")
        expect_true(#encoded > #data, "base64 encoding is larger than input")
        -- decode returns Vec<u8> (Lua table), so just verify it returns something
        local decoded = lurek.data.decode("base64", encoded)
        expect_not_nil(decoded, "base64 decode produced output")
        expect_equal(#data, #decoded, "base64 roundtrip preserves length")
    end)

    it("hex encode/decode 10KB", function()
        local data = string.rep("HexData!", 1250) -- 10KB
        local encoded = lurek.data.encode("hex", data)
        expect_equal(#data * 2, #encoded, "hex doubles size")
        -- decode returns Vec<u8> (Lua table), verify length
        local decoded = lurek.data.decode("hex", encoded)
        expect_not_nil(decoded, "hex decode produced output")
        expect_equal(#data, #decoded, "hex roundtrip preserves length")
    end)
end)
