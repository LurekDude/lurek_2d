-- lurek.codec API unit tests
-- Headless-safe (no window / GPU / audio required).

describe("lurek.codec module exists", function()
    it("lurek.codec is a table", function()
        expect_type("table", lurek.codec)
    end)
end)

describe("JSON round-trip", function()
    it("fromJson is a function", function()
        expect_type("function", lurek.codec.fromJson)
    end)

    it("toJson is a function", function()
        expect_type("function", lurek.codec.toJson)
    end)

    it("fromJson parses a simple object", function()
        local t = lurek.codec.fromJson('{"name":"luna","version":1}')
        expect_type("table", t)
        expect_equal("luna", t.name)
        expect_equal(1, t.version)
    end)

    it("fromJson parses an array", function()
        local t = lurek.codec.fromJson('[1,2,3]')
        expect_type("table", t)
        expect_equal(1, t[1])
        expect_equal(3, t[3])
    end)

    it("toJson serializes a table to a string", function()
        local s = lurek.codec.toJson({ x = 10, y = 20 })
        expect_type("string", s)
        expect_true(#s > 0, "json string is non-empty")
    end)

    it("JSON round-trip preserves string values", function()
        local orig = { greeting = "hello" }
        local json = lurek.codec.toJson(orig)
        local back = lurek.codec.fromJson(json)
        expect_equal("hello", back.greeting)
    end)

    it("JSON round-trip preserves numbers", function()
        local orig = { val = 42 }
        local json = lurek.codec.toJson(orig)
        local back = lurek.codec.fromJson(json)
        expect_equal(42, back.val)
    end)

    it("toJson with pretty=true produces longer output", function()
        local t = { a = 1, b = 2 }
        local compact = lurek.codec.toJson(t, false)
        local pretty  = lurek.codec.toJson(t, true)
        expect_true(#pretty >= #compact, "pretty >= compact length")
    end)

    it("fromJson returns error on invalid JSON", function()
        expect_error(function()
            lurek.codec.fromJson("not json {{{")
        end)
    end)
end)

describe("TOML round-trip", function()
    it("fromToml is a function", function()
        expect_type("function", lurek.codec.fromToml)
    end)

    it("toToml is a function", function()
        expect_type("function", lurek.codec.toToml)
    end)

    it("fromToml parses a simple table", function()
        local t = lurek.codec.fromToml('[window]\ntitle = "Lurek2D"\nwidth = 800\n')
        expect_type("table", t)
        expect_type("table", t.window)
        expect_equal("Lurek2D", t.window.title)
        expect_equal(800, t.window.width)
    end)

    it("toToml serializes a table", function()
        local s = lurek.codec.toToml({ game = { fps = 60 } })
        expect_type("string", s)
        expect_true(#s > 0, "toml string is non-empty")
    end)

    it("TOML round-trip preserves scalar values", function()
        local orig = { score = 100 }
        local toml = lurek.codec.toToml(orig)
        local back = lurek.codec.fromToml(toml)
        expect_equal(100, back.score)
    end)

    it("fromToml returns error on invalid TOML", function()
        expect_error(function()
            lurek.codec.fromToml("[[broken = = ]]")
        end)
    end)
end)

describe("CSV round-trip", function()
    it("fromCsv is a function", function()
        expect_type("function", lurek.codec.fromCsv)
    end)

    it("toCsv is a function", function()
        expect_type("function", lurek.codec.toCsv)
    end)

    it("fromCsv parses rows", function()
        local csv = "name,score\nalice,10\nbob,20\n"
        local rows = lurek.codec.fromCsv(csv)
        expect_type("table", rows)
        expect_true(#rows >= 1, "has at least one row")
    end)

    it("toCsv produces a non-empty string", function()
        local data = { { name = "a", score = "1" }, { name = "b", score = "2" } }
        local s = lurek.codec.toCsv(data)
        expect_type("string", s)
        expect_true(#s > 0, "csv string is non-empty")
    end)
end)

-- YAML removed: design-assumption B-05 (TOML is the human-authored config format; serde_yml dependency dropped)

test_summary()
