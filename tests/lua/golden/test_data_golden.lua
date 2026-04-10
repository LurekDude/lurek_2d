-- Lurek2D Golden Test: Data Serialization
-- Verifies JSON and TOML round-trip produces deterministic output
-- @golden data serialization round-trip

describe("golden: data JSON round-trip", function()
    it("simple table to JSON is deterministic", function()
        local input = { a = 1, b = "hello", c = true }
        local json1 = lurek.data.encode("json", input)
        local json2 = lurek.data.encode("json", input)
        expect_equal(json1, json2, "same input → same JSON output")
    end)

    it("nested table to JSON preserves structure", function()
        local input = {
            player = { name = "Alice", hp = 100, pos = { x = 1.5, y = 2.5 } },
            level = 3
        }
        local encoded = lurek.data.encode("json", input)
        local decoded = lurek.data.decode("json", encoded)

        expect_equal("Alice", decoded.player.name, "name preserved")
        expect_equal(100, decoded.player.hp, "hp preserved")
        expect_near(1.5, decoded.player.pos.x, 0.001, "pos.x preserved")
        expect_near(2.5, decoded.player.pos.y, 0.001, "pos.y preserved")
        expect_equal(3, decoded.level, "level preserved")
    end)

    it("empty table round-trip", function()
        local encoded = lurek.data.encode("json", {})
        local decoded = lurek.data.decode("json", encoded)
        expect_type("table", decoded)
    end)
end)

describe("golden: data TOML round-trip", function()
    it("flat TOML table deterministic", function()
        local input = { title = "test", version = 1, debug = false }
        local toml1 = lurek.data.encode("toml", input)
        local toml2 = lurek.data.encode("toml", input)
        expect_equal(toml1, toml2, "same input → same TOML output")
    end)

    it("nested TOML section preserves values", function()
        local input = {
            window = { width = 800, height = 600, title = "Game" },
            audio = { volume = 0.8, muted = false }
        }
        local encoded = lurek.data.encode("toml", input)
        local decoded = lurek.data.decode("toml", encoded)

        expect_equal(800, decoded.window.width, "window width")
        expect_equal(600, decoded.window.height, "window height")
        expect_equal("Game", decoded.window.title, "window title")
        expect_near(0.8, decoded.audio.volume, 0.001, "audio volume")
    end)
end)

describe("golden: data compression round-trip", function()
    it("compress-decompress is identity", function()
        local original = "Hello, Lurek2D! This is a golden test for deterministic compression."
        local compressed = lurek.data.compress(original)
        local decompressed = lurek.data.decompress(compressed)
        expect_equal(original, decompressed, "lossless round-trip")
    end)

    it("repeated content compresses well", function()
        local original = string.rep("PATTERN_", 500)  -- 4000 bytes
        local compressed = lurek.data.compress(original)
        expect_true(#compressed < #original, "compressed < original")

        local decompressed = lurek.data.decompress(compressed)
        expect_equal(original, decompressed, "lossless after compression")
    end)
end)

test_summary()
