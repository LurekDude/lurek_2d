-- lurek.serial API unit tests.
-- Covers JSON, TOML, and CSV encode/decode helpers, error paths, and headless-safe data-format round-trips.

-- Headless-safe (no window / GPU / audio required).

describe("lurek.serial module exists", function()
    it("lurek.serial is a table", function()
        expect_type("table", lurek.serial)
    end)
end)

describe("JSON round-trip", function()
    it("fromJson is a function", function()
        expect_type("function", lurek.serial.fromJson)
    end)

    it("toJson is a function", function()
        expect_type("function", lurek.serial.toJson)
    end)

    it("fromJson parses a simple object", function()
        local t = lurek.serial.fromJson('{"name":"luna","version":1}')
        expect_type("table", t)
        expect_equal("luna", t.name)
        expect_equal(1, t.version)
    end)

    it("fromJson parses an array", function()
        local t = lurek.serial.fromJson('[1,2,3]')
        expect_type("table", t)
        expect_equal(1, t[1])
        expect_equal(3, t[3])
    end)

    it("toJson serializes a table to a string", function()
        local s = lurek.serial.toJson({ x = 10, y = 20 })
        expect_type("string", s)
        expect_true(#s > 0, "json string is non-empty")
    end)

    it("JSON round-trip preserves string values", function()
        local orig = { greeting = "hello" }
        local json = lurek.serial.toJson(orig)
        local back = lurek.serial.fromJson(json)
        expect_equal("hello", back.greeting)
    end)

    it("JSON round-trip preserves numbers", function()
        local orig = { val = 42 }
        local json = lurek.serial.toJson(orig)
        local back = lurek.serial.fromJson(json)
        expect_equal(42, back.val)
    end)

    it("toJson with pretty=true produces longer output", function()
        local t = { a = 1, b = 2 }
        local compact = lurek.serial.toJson(t, false)
        local pretty  = lurek.serial.toJson(t, true)
        expect_true(#pretty >= #compact, "pretty >= compact length")
    end)

    it("fromJson returns error on invalid JSON", function()
        expect_error(function()
            lurek.serial.fromJson("not json {{{")
        end)
    end)
end)

describe("TOML round-trip", function()
    it("fromToml is a function", function()
        expect_type("function", lurek.serial.fromToml)
    end)

    it("toToml is a function", function()
        expect_type("function", lurek.serial.toToml)
    end)

    it("fromToml parses a simple table", function()
        local t = lurek.serial.fromToml('[window]\ntitle = "Lurek2D"\nwidth = 800\n')
        expect_type("table", t)
        expect_type("table", t.window)
        expect_equal("Lurek2D", t.window.title)
        expect_equal(800, t.window.width)
    end)

    it("toToml serializes a table", function()
        local s = lurek.serial.toToml({ game = { fps = 60 } })
        expect_type("string", s)
        expect_true(#s > 0, "toml string is non-empty")
    end)

    it("TOML round-trip preserves scalar values", function()
        local orig = { score = 100 }
        local toml = lurek.serial.toToml(orig)
        local back = lurek.serial.fromToml(toml)
        expect_equal(100, back.score)
    end)

    it("fromToml returns error on invalid TOML", function()
        expect_error(function()
            lurek.serial.fromToml("[[broken = = ]]")
        end)
    end)
end)

describe("CSV round-trip", function()
    it("fromCsv is a function", function()
        expect_type("function", lurek.serial.fromCsv)
    end)

    it("toCsv is a function", function()
        expect_type("function", lurek.serial.toCsv)
    end)

    it("fromCsv parses rows", function()
        local csv = "name,score\nalice,10\nbob,20\n"
        local rows = lurek.serial.fromCsv(csv)
        expect_type("table", rows)
        expect_true(#rows >= 1, "has at least one row")
    end)

    it("toCsv produces a non-empty string", function()
        local data = { { name = "a", score = "1" }, { name = "b", score = "2" } }
        local s = lurek.serial.toCsv(data)
        expect_type("string", s)
        expect_true(#s > 0, "csv string is non-empty")
    end)
end)

-- CSV options

describe("CSV advanced options", function()
    it("fromCsv with headers creates object-keyed rows", function()
        local csv = "name,score\nalice,10\nbob,20\n"
        local rows = lurek.serial.fromCsv(csv, nil, true)
        expect_true(#rows >= 2)
        expect_equal("alice", rows[1].name)
        expect_equal("10", rows[1].score)
    end)

    it("fromCsv without headers creates numeric keys", function()
        local csv = "alice,10\nbob,20\n"
        local rows = lurek.serial.fromCsv(csv, nil, false)
        expect_true(#rows >= 2)
        expect_not_nil(rows[1][1])
    end)

    it("fromCsv with custom delimiter", function()
        local csv = "name\tscore\nalice\t10\nbob\t20\n"
        local rows = lurek.serial.fromCsv(csv, "\t", true)
        expect_true(#rows >= 2)
        expect_equal("alice", rows[1].name)
    end)

    it("CSV round-trip preserves data", function()
        local data = { { name = "test", value = "42" } }
        local csv = lurek.serial.toCsv(data)
        local back = lurek.serial.fromCsv(csv)
        expect_equal("test", back[1].name)
        expect_equal("42", back[1].value)
    end)
end)

-- error handling

describe("codec error handling", function()
    it("fromJson error on malformed input", function()
        expect_error(function()
            lurek.serial.fromJson("{bad: json}")
        end)
    end)

    it("fromToml error on malformed input", function()
        expect_error(function()
            lurek.serial.fromToml("invalid = [")
        end)
    end)

    it("fromJson on empty string errors", function()
        expect_error(function()
            lurek.serial.fromJson("")
        end)
    end)
end)

-- YAML removed: design-assumption B-05 (TOML is the human-authored config format; serde_yml dependency dropped)

--  Serial MsgPack (merged from test_serial_msgpack.lua) 

describe("lurek.serial.encodeMsgPack", function()
  it("returns a non-empty string for a simple table", function()
    local bytes = lurek.serial.encodeMsgPack({ name = "hero", level = 5 })
    expect_equal(type(bytes), "string")
    expect_equal(#bytes > 0, true)
  end)

  it("errors on nil input", function()
    ---@type any
    local invalid = nil
    expect_error(function() lurek.serial.encodeMsgPack(invalid) end)
  end)

  it("errors on string input", function()
    ---@type any
    local invalid = "not a table"
    expect_error(function() lurek.serial.encodeMsgPack(invalid) end)
  end)

  it("errors on number input", function()
    ---@type any
    local invalid = 42
    expect_error(function() lurek.serial.encodeMsgPack(invalid) end)
  end)
end)

describe("lurek.serial.decodeMsgPack", function()
  it("round-trips string and number fields", function()
    local tbl = { name = "hero", level = 5 }
    local bytes = lurek.serial.encodeMsgPack(tbl)
    local decoded = lurek.serial.decodeMsgPack(bytes)
    expect_equal(decoded.name, "hero")
    expect_equal(decoded.level, 5)
  end)

  it("round-trips nested tables", function()
    local tbl = { pos = { x = 10, y = 20 } }
    local bytes = lurek.serial.encodeMsgPack(tbl)
    local decoded = lurek.serial.decodeMsgPack(bytes)
    expect_equal(decoded.pos.x, 10)
    expect_equal(decoded.pos.y, 20)
  end)

  it("round-trips a boolean field", function()
    local tbl = { alive = true, dead = false }
    local bytes = lurek.serial.encodeMsgPack(tbl)
    local decoded = lurek.serial.decodeMsgPack(bytes)
    expect_equal(decoded.alive, true)
    expect_equal(decoded.dead, false)
  end)

  it("round-trips an array-style table", function()
    local tbl = { items = { "sword", "shield", "potion" } }
    local bytes = lurek.serial.encodeMsgPack(tbl)
    local decoded = lurek.serial.decodeMsgPack(bytes)
    expect_equal(decoded.items[1], "sword")
    expect_equal(decoded.items[2], "shield")
    expect_equal(decoded.items[3], "potion")
  end)

  it("errors on invalid bytes", function()
    expect_error(function() lurek.serial.decodeMsgPack("\xc1\xc1\xc1") end)
  end)
end)

--  Serial Schema (merged from test_serial_schema.lua) 

describe("lurek.serial.validate  type checks", function()
  it("passes when type matches string", function()
    local ok, err = lurek.serial.validate("hello", { type = "string" })
    expect_equal(ok, true)
    expect_equal(err, nil)
  end)

  it("passes when type matches number", function()
    local ok, err = lurek.serial.validate(42, { type = "number" })
    expect_equal(ok, true)
    expect_equal(err, nil)
  end)

  it("passes when type matches boolean", function()
    local ok, err = lurek.serial.validate(true, { type = "boolean" })
    expect_equal(ok, true)
    expect_equal(err, nil)
  end)

  it("fails when type mismatches", function()
    local ok, err = lurek.serial.validate(42, { type = "string" })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  it("passes for any type with type='any'", function()
    local ok = lurek.serial.validate("anything", { type = "any" })
    expect_equal(ok, true)
  end)
end)

describe("lurek.serial.validate  required field", function()
  it("passes when non-nil value and required=true", function()
    local ok = lurek.serial.validate("value", { type = "string", required = true })
    expect_equal(ok, true)
  end)

  it("fails when nil value and required=true", function()
    local ok, err = lurek.serial.validate(nil, { type = "string", required = true })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  it("passes when nil value and required not set", function()
    local ok = lurek.serial.validate(nil, { type = "string" })
    expect_equal(ok, true)
  end)
end)

describe("lurek.serial.validate  numeric range", function()
  it("passes when value is within min/max", function()
    local ok = lurek.serial.validate(50, { type = "number", min = 1, max = 100 })
    expect_equal(ok, true)
  end)

  it("fails when value is below min", function()
    local ok, err = lurek.serial.validate(0, { type = "number", min = 1, max = 100 })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  it("fails when value exceeds max", function()
    local ok, err = lurek.serial.validate(101, { type = "number", min = 1, max = 100 })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  it("passes at exactly min", function()
    local ok = lurek.serial.validate(1, { type = "number", min = 1, max = 100 })
    expect_equal(ok, true)
  end)

  it("passes at exactly max", function()
    local ok = lurek.serial.validate(100, { type = "number", min = 1, max = 100 })
    expect_equal(ok, true)
  end)
end)

describe("lurek.serial.validate  string length", function()
  it("passes when string length is within minlen/maxlen", function()
    local ok = lurek.serial.validate("abc", { type = "string", minlen = 1, maxlen = 10 })
    expect_equal(ok, true)
  end)

  it("fails when string is shorter than minlen", function()
    local ok, err = lurek.serial.validate("", { type = "string", minlen = 1 })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  it("fails when string exceeds maxlen", function()
    local ok, err = lurek.serial.validate("toolong", { type = "string", maxlen = 3 })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)
end)

describe("lurek.serial.validate  table fields", function()
  local schema = {
    type = "table",
    fields = {
      name  = { type = "string", required = true },
      level = { type = "number", min = 1, max = 100 },
    }
  }

  it("passes a valid table", function()
    local ok = lurek.serial.validate({ name = "hero", level = 5 }, schema)
    expect_equal(ok, true)
  end)

  it("fails when required field is missing", function()
    local ok, err = lurek.serial.validate({ level = 5 }, schema)
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  it("fails when field type is wrong", function()
    local ok, err = lurek.serial.validate({ name = 42, level = 5 }, schema)
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  it("fails when numeric field is out of range", function()
    local ok, err = lurek.serial.validate({ name = "hero", level = 200 }, schema)
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)
end)

describe("lurek.serial.validate  sequence items", function()
  local schema = {
    type  = "table",
    items = { type = "string" }
  }

  it("passes when all items match type", function()
    local ok = lurek.serial.validate({ "a", "b", "c" }, schema)
    expect_equal(ok, true)
  end)

  it("fails when an item has the wrong type", function()
    local ok, err = lurek.serial.validate({ "a", 2, "c" }, schema)
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  it("passes an empty sequence", function()
    local ok = lurek.serial.validate({}, schema)
    expect_equal(ok, true)
  end)
end)

--  Serial XML (merged from test_serial_xml.lua) 

describe("lurek.serial.decodeXml", function()
  it("parses a simple element", function()
    local xml = "<root/>"
    local tbl = lurek.serial.decodeXml(xml)
    expect_equal(tbl.tag, "root")
  end)

  it("captures text content", function()
    local xml = "<greeting>Hello World</greeting>"
    local tbl = lurek.serial.decodeXml(xml)
    expect_equal(tbl.tag, "greeting")
    expect_equal(tbl.text, "Hello World")
  end)

  it("captures attributes", function()
    local xml = '<player id="1" name="hero"/>'
    local tbl = lurek.serial.decodeXml(xml)
    expect_equal(tbl.tag, "player")
    expect_equal(tbl.attrs.id, "1")
    expect_equal(tbl.attrs.name, "hero")
  end)

  it("captures child elements", function()
    local xml = "<items><item>sword</item><item>shield</item></items>"
    local tbl = lurek.serial.decodeXml(xml)
    expect_equal(tbl.tag, "items")
    expect_equal(#tbl.children, 2)
    expect_equal(tbl.children[1].tag, "item")
    expect_equal(tbl.children[1].text, "sword")
    expect_equal(tbl.children[2].text, "shield")
  end)

  it("omits attrs table when element has no attributes", function()
    local xml = "<root><child/></root>"
    local tbl = lurek.serial.decodeXml(xml)
    expect_equal(tbl.attrs, nil)
    expect_equal(tbl.children[1].attrs, nil)
  end)

  it("omits children table when element has no child elements", function()
    local xml = "<leaf>text</leaf>"
    local tbl = lurek.serial.decodeXml(xml)
    expect_equal(tbl.children, nil)
  end)

  it("handles a nested document", function()
    local xml = [[<map version="1"><layer name="ground"><tile id="3"/></layer></map>]]
    local tbl = lurek.serial.decodeXml(xml)
    expect_equal(tbl.tag, "map")
    expect_equal(tbl.attrs.version, "1")
    local layer = tbl.children[1]
    expect_equal(layer.tag, "layer")
    expect_equal(layer.attrs.name, "ground")
    expect_equal(layer.children[1].tag, "tile")
    expect_equal(layer.children[1].attrs.id, "3")
  end)

  it("errors on malformed XML", function()
    expect_error(function() lurek.serial.decodeXml("<unclosed") end)
  end)

  it("errors on mismatched tags", function()
    expect_error(function() lurek.serial.decodeXml("<a></b>") end)
  end)
end)

describe("lurek.serial regression coverage", function()
  it("encodeMsgPack round-trips a nested table", function()
    local source = {
      name = "hero",
      stats = { hp = 10, mp = 3 },
      tags = { "warrior", "starter" },
    }
    local bytes = lurek.serial.encodeMsgPack(source)
    expect_equal("string", type(bytes))
    local decoded = lurek.serial.decodeMsgPack(bytes)
    expect_equal("hero", decoded.name)
    expect_equal(10, decoded.stats.hp)
    expect_equal("warrior", decoded.tags[1])
  end)

  it("decodeMsgPack preserves sequential arrays", function()
    local decoded = lurek.serial.decodeMsgPack(lurek.serial.encodeMsgPack({ 10, 20, 30 }))
    expect_equal(3, #decoded)
    expect_equal(20, decoded[2])
  end)

  it("decodeXml returns root tag text and attributes", function()
    local decoded = lurek.serial.decodeXml("<root version=\"1\">hello</root>")
    expect_equal("root", decoded.tag)
    expect_equal("1", decoded.attrs.version)
    expect_equal("hello", decoded.text)
  end)

  it("validate rejects a missing required field", function()
    local ok, err = lurek.serial.validate({ name = "hero" }, {
      type = "table",
      fields = {
        name = { type = "string", required = true },
        level = { type = "number", required = true },
      },
    })
    expect_equal(false, ok)
    expect_not_nil(err)
  end)
end)
test_summary()
