-- lurek.serial API unit tests.
-- Covers JSON, TOML, and CSV encode/decode helpers, error paths, and headless-safe data-format round-trips.

-- Headless-safe (no window / GPU / audio required).

-- @describe lurek.serial module exists
describe("lurek.serial module exists", function()
    -- @covers lurek.serial
    it("lurek.serial is a table", function()
        expect_type("table", lurek.serial)
    end)
end)

-- @describe JSON round-trip
describe("JSON round-trip", function()
    -- @covers lurek.serial.fromJson
    it("fromJson is a function", function()
        expect_type("function", lurek.serial.fromJson)
    end)

    -- @covers lurek.serial.toJson
    it("toJson is a function", function()
        expect_type("function", lurek.serial.toJson)
    end)

    -- @covers lurek.serial.fromJson
    it("fromJson parses a simple object", function()
        local t = lurek.serial.fromJson('{"name":"luna","version":1}')
        expect_type("table", t)
        expect_equal("luna", t.name)
        expect_equal(1, t.version)
    end)

    -- @covers lurek.serial.fromJson
    it("fromJson parses an array", function()
        local t = lurek.serial.fromJson('[1,2,3]')
        expect_type("table", t)
        expect_equal(1, t[1])
        expect_equal(3, t[3])
    end)

    -- @covers lurek.serial.toJson
    it("toJson serializes a table to a string", function()
        local s = lurek.serial.toJson({ x = 10, y = 20 })
        expect_type("string", s)
        expect_true(#s > 0, "json string is non-empty")
    end)

    -- @covers lurek.serial.fromJson
    -- @covers lurek.serial.toJson
    it("JSON round-trip preserves string values", function()
        local orig = { greeting = "hello" }
        local json = lurek.serial.toJson(orig)
        local back = lurek.serial.fromJson(json)
        expect_equal("hello", back.greeting)
    end)

    -- @covers lurek.serial.fromJson
    -- @covers lurek.serial.toJson
    it("JSON round-trip preserves numbers", function()
        local orig = { val = 42 }
        local json = lurek.serial.toJson(orig)
        local back = lurek.serial.fromJson(json)
        expect_equal(42, back.val)
    end)

    -- @covers lurek.serial.toJson
    it("toJson with pretty=true produces longer output", function()
        local t = { a = 1, b = 2 }
        local compact = lurek.serial.toJson(t, false)
        local pretty  = lurek.serial.toJson(t, true)
        expect_true(#pretty >= #compact, "pretty >= compact length")
    end)

    -- @covers lurek.serial.fromJson
    it("fromJson returns error on invalid JSON", function()
        expect_error(function()
            lurek.serial.fromJson("not json {{{")
        end)
    end)
end)

-- @describe TOML round-trip
describe("TOML round-trip", function()
    -- @covers lurek.serial.fromToml
    it("fromToml is a function", function()
        expect_type("function", lurek.serial.fromToml)
    end)

    -- @covers lurek.serial.toToml
    it("toToml is a function", function()
        expect_type("function", lurek.serial.toToml)
    end)

    -- @covers lurek.serial.fromToml
    it("fromToml parses a simple table", function()
        local t = lurek.serial.fromToml('[window]\ntitle = "Lurek2D"\nwidth = 800\n')
        expect_type("table", t)
        expect_type("table", t.window)
        expect_equal("Lurek2D", t.window.title)
        expect_equal(800, t.window.width)
    end)

    -- @covers lurek.serial.toToml
    it("toToml serializes a table", function()
        local s = lurek.serial.toToml({ game = { fps = 60 } })
        expect_type("string", s)
        expect_true(#s > 0, "toml string is non-empty")
    end)

    -- @covers lurek.serial.fromToml
    -- @covers lurek.serial.toToml
    it("TOML round-trip preserves scalar values", function()
        local orig = { score = 100 }
        local toml = lurek.serial.toToml(orig)
        local back = lurek.serial.fromToml(toml)
        expect_equal(100, back.score)
    end)

    -- @covers lurek.serial.fromToml
    it("fromToml returns error on invalid TOML", function()
        expect_error(function()
            lurek.serial.fromToml("[[broken = = ]]")
        end)
    end)
end)

  -- @describe INI decode
describe("INI decode", function()
  -- @covers lurek.serial.fromIni
  it("fromIni parses sectioned ini text", function()
    local cfg = lurek.serial.fromIni("[player]\nname=hero\n")
    expect_equal("hero", cfg.player.name)
  end)
end)

-- @describe CSV round-trip
describe("CSV round-trip", function()
    -- @covers lurek.serial.fromCsv
    it("fromCsv is a function", function()
        expect_type("function", lurek.serial.fromCsv)
    end)

    -- @covers lurek.serial.toCsv
    it("toCsv is a function", function()
        expect_type("function", lurek.serial.toCsv)
    end)

    -- @covers lurek.serial.fromCsv
    it("fromCsv parses rows", function()
        local csv = "name,score\nalice,10\nbob,20\n"
        local rows = lurek.serial.fromCsv(csv)
        expect_type("table", rows)
        expect_true(#rows >= 1, "has at least one row")
    end)

    -- @covers lurek.serial.toCsv
    it("toCsv produces a non-empty string", function()
        local data = { { name = "a", score = "1" }, { name = "b", score = "2" } }
        local s = lurek.serial.toCsv(data)
        expect_type("string", s)
        expect_true(#s > 0, "csv string is non-empty")
    end)
end)

-- CSV options

-- @describe CSV advanced options
describe("CSV advanced options", function()
    -- @covers lurek.serial.fromCsv
    it("fromCsv with headers creates object-keyed rows", function()
        local csv = "name,score\nalice,10\nbob,20\n"
        local rows = lurek.serial.fromCsv(csv, nil, true)
        expect_true(#rows >= 2)
        expect_equal("alice", rows[1].name)
        expect_equal("10", rows[1].score)
    end)

    -- @covers lurek.serial.fromCsv
    it("fromCsv without headers creates numeric keys", function()
        local csv = "alice,10\nbob,20\n"
        local rows = lurek.serial.fromCsv(csv, nil, false)
        expect_true(#rows >= 2)
        expect_not_nil(rows[1][1])
    end)

    -- @covers lurek.serial.fromCsv
    it("fromCsv with custom delimiter", function()
        local csv = "name\tscore\nalice\t10\nbob\t20\n"
        local rows = lurek.serial.fromCsv(csv, "\t", true)
        expect_true(#rows >= 2)
        expect_equal("alice", rows[1].name)
    end)

    -- @covers lurek.serial.fromCsv
    -- @covers lurek.serial.toCsv
    it("CSV round-trip preserves data", function()
        local data = { { name = "test", value = "42" } }
        local csv = lurek.serial.toCsv(data)
        local back = lurek.serial.fromCsv(csv)
        expect_equal("test", back[1].name)
        expect_equal("42", back[1].value)
    end)
end)

-- error handling

-- @describe codec error handling
describe("codec error handling", function()
    -- @covers lurek.serial.fromJson
    it("fromJson error on malformed input", function()
        expect_error(function()
            lurek.serial.fromJson("{bad: json}")
        end)
    end)

    -- @covers lurek.serial.fromToml
    it("fromToml error on malformed input", function()
        expect_error(function()
            lurek.serial.fromToml("invalid = [")
        end)
    end)

    -- @covers lurek.serial.fromJson
    it("fromJson on empty string errors", function()
        expect_error(function()
            lurek.serial.fromJson("")
        end)
    end)
end)

-- YAML removed: design-assumption B-05 (TOML is the human-authored config format; serde_yml dependency dropped)

--  Serial MsgPack (merged from test_serial_msgpack.lua)

-- @describe lurek.serial.encodeMsgPack
describe("lurek.serial.encodeMsgPack", function()
  -- @covers lurek.serial.encodeMsgPack
  it("returns a non-empty string for a simple table", function()
    local bytes = lurek.serial.encodeMsgPack({ name = "hero", level = 5 })
    expect_equal(type(bytes), "string")
    expect_equal(#bytes > 0, true)
  end)

  -- @covers lurek.serial.encodeMsgPack
  it("errors on nil input", function()
    ---@type any
    local invalid = nil
    expect_error(function() lurek.serial.encodeMsgPack(invalid) end)
  end)

  -- @covers lurek.serial.encodeMsgPack
  it("errors on string input", function()
    ---@type any
    local invalid = "not a table"
    expect_error(function() lurek.serial.encodeMsgPack(invalid) end)
  end)

  -- @covers lurek.serial.encodeMsgPack
  it("errors on number input", function()
    ---@type any
    local invalid = 42
    expect_error(function() lurek.serial.encodeMsgPack(invalid) end)
  end)
end)

-- @describe lurek.serial.decodeMsgPack
describe("lurek.serial.decodeMsgPack", function()
  -- @covers lurek.serial.decodeMsgPack
  -- @covers lurek.serial.encodeMsgPack
  it("round-trips string and number fields", function()
    local tbl = { name = "hero", level = 5 }
    local bytes = lurek.serial.encodeMsgPack(tbl)
    local decoded = lurek.serial.decodeMsgPack(bytes)
    expect_equal(decoded.name, "hero")
    expect_equal(decoded.level, 5)
  end)

  -- @covers lurek.serial.decodeMsgPack
  -- @covers lurek.serial.encodeMsgPack
  it("round-trips nested tables", function()
    local tbl = { pos = { x = 10, y = 20 } }
    local bytes = lurek.serial.encodeMsgPack(tbl)
    local decoded = lurek.serial.decodeMsgPack(bytes)
    expect_equal(decoded.pos.x, 10)
    expect_equal(decoded.pos.y, 20)
  end)

  -- @covers lurek.serial.decodeMsgPack
  -- @covers lurek.serial.encodeMsgPack
  it("round-trips a boolean field", function()
    local tbl = { alive = true, dead = false }
    local bytes = lurek.serial.encodeMsgPack(tbl)
    local decoded = lurek.serial.decodeMsgPack(bytes)
    expect_equal(decoded.alive, true)
    expect_equal(decoded.dead, false)
  end)

  -- @covers lurek.serial.decodeMsgPack
  -- @covers lurek.serial.encodeMsgPack
  it("round-trips an array-style table", function()
    local tbl = { items = { "sword", "shield", "potion" } }
    local bytes = lurek.serial.encodeMsgPack(tbl)
    local decoded = lurek.serial.decodeMsgPack(bytes)
    expect_equal(decoded.items[1], "sword")
    expect_equal(decoded.items[2], "shield")
    expect_equal(decoded.items[3], "potion")
  end)

  -- @covers lurek.serial.decodeMsgPack
  it("errors on invalid bytes", function()
    expect_error(function() lurek.serial.decodeMsgPack("\xc1\xc1\xc1") end)
  end)
end)

--  Serial Schema (merged from test_serial_schema.lua)

-- @describe lurek.serial.validate  type checks
describe("lurek.serial.validate  type checks", function()
  -- @covers lurek.serial.validate
  it("passes when type matches string", function()
    local ok, err = lurek.serial.validate("hello", { type = "string" })
    expect_equal(ok, true)
    expect_equal(err, nil)
  end)

  -- @covers lurek.serial.validate
  it("passes when type matches number", function()
    local ok, err = lurek.serial.validate(42, { type = "number" })
    expect_equal(ok, true)
    expect_equal(err, nil)
  end)

  -- @covers lurek.serial.validate
  it("passes when type matches boolean", function()
    local ok, err = lurek.serial.validate(true, { type = "boolean" })
    expect_equal(ok, true)
    expect_equal(err, nil)
  end)

  -- @covers lurek.serial.validate
  it("fails when type mismatches", function()
    local ok, err = lurek.serial.validate(42, { type = "string" })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  -- @covers lurek.serial.validate
  it("passes for any type with type='any'", function()
    local ok = lurek.serial.validate("anything", { type = "any" })
    expect_equal(ok, true)
  end)
end)

-- @describe lurek.serial.validate  required field
describe("lurek.serial.validate  required field", function()
  -- @covers lurek.serial.validate
  it("passes when non-nil value and required=true", function()
    local ok = lurek.serial.validate("value", { type = "string", required = true })
    expect_equal(ok, true)
  end)

  -- @covers lurek.serial.validate
  it("fails when nil value and required=true", function()
    local ok, err = lurek.serial.validate(nil, { type = "string", required = true })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  -- @covers lurek.serial.validate
  it("passes when nil value and required not set", function()
    local ok = lurek.serial.validate(nil, { type = "string" })
    expect_equal(ok, true)
  end)
end)

-- @describe lurek.serial.validate  numeric range
describe("lurek.serial.validate  numeric range", function()
  -- @covers lurek.serial.validate
  it("passes when value is within min/max", function()
    local ok = lurek.serial.validate(50, { type = "number", min = 1, max = 100 })
    expect_equal(ok, true)
  end)

  -- @covers lurek.serial.validate
  it("fails when value is below min", function()
    local ok, err = lurek.serial.validate(0, { type = "number", min = 1, max = 100 })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  -- @covers lurek.serial.validate
  it("fails when value exceeds max", function()
    local ok, err = lurek.serial.validate(101, { type = "number", min = 1, max = 100 })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  -- @covers lurek.serial.validate
  it("passes at exactly min", function()
    local ok = lurek.serial.validate(1, { type = "number", min = 1, max = 100 })
    expect_equal(ok, true)
  end)

  -- @covers lurek.serial.validate
  it("passes at exactly max", function()
    local ok = lurek.serial.validate(100, { type = "number", min = 1, max = 100 })
    expect_equal(ok, true)
  end)
end)

-- @describe lurek.serial.validate  string length
describe("lurek.serial.validate  string length", function()
  -- @covers lurek.serial.validate
  it("passes when string length is within minlen/maxlen", function()
    local ok = lurek.serial.validate("abc", { type = "string", minlen = 1, maxlen = 10 })
    expect_equal(ok, true)
  end)

  -- @covers lurek.serial.validate
  it("fails when string is shorter than minlen", function()
    local ok, err = lurek.serial.validate("", { type = "string", minlen = 1 })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  -- @covers lurek.serial.validate
  it("fails when string exceeds maxlen", function()
    local ok, err = lurek.serial.validate("toolong", { type = "string", maxlen = 3 })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)
end)

-- @describe lurek.serial.validate  table fields
describe("lurek.serial.validate  table fields", function()
  local schema = {
    type = "table",
    fields = {
      name  = { type = "string", required = true },
      level = { type = "number", min = 1, max = 100 },
    }
  }

  -- @covers lurek.serial.validate
  it("passes a valid table", function()
    local ok = lurek.serial.validate({ name = "hero", level = 5 }, schema)
    expect_equal(ok, true)
  end)

  -- @covers lurek.serial.validate
  it("fails when required field is missing", function()
    local ok, err = lurek.serial.validate({ level = 5 }, schema)
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  -- @covers lurek.serial.validate
  it("fails when field type is wrong", function()
    local ok, err = lurek.serial.validate({ name = 42, level = 5 }, schema)
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  -- @covers lurek.serial.validate
  it("fails when numeric field is out of range", function()
    local ok, err = lurek.serial.validate({ name = "hero", level = 200 }, schema)
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)
end)

-- @describe lurek.serial.validate  sequence items
describe("lurek.serial.validate  sequence items", function()
  local schema = {
    type  = "table",
    items = { type = "string" }
  }

  -- @covers lurek.serial.validate
  it("passes when all items match type", function()
    local ok = lurek.serial.validate({ "a", "b", "c" }, schema)
    expect_equal(ok, true)
  end)

  -- @covers lurek.serial.validate
  it("fails when an item has the wrong type", function()
    local ok, err = lurek.serial.validate({ "a", 2, "c" }, schema)
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  -- @covers lurek.serial.validate
  it("passes an empty sequence", function()
    local ok = lurek.serial.validate({}, schema)
    expect_equal(ok, true)
  end)
end)

--  Serial XML (merged from test_serial_xml.lua)

-- @describe lurek.serial.decodeXml
describe("lurek.serial.decodeXml", function()
  -- @covers lurek.serial.decodeXml
  it("parses a simple element", function()
    local xml = "<root/>"
    local tbl = lurek.serial.decodeXml(xml)
    expect_equal(tbl.tag, "root")
  end)

  -- @covers lurek.serial.decodeXml
  it("captures text content", function()
    local xml = "<greeting>Hello World</greeting>"
    local tbl = lurek.serial.decodeXml(xml)
    expect_equal(tbl.tag, "greeting")
    expect_equal(tbl.text, "Hello World")
  end)

  -- @covers lurek.serial.decodeXml
  it("captures attributes", function()
    local xml = '<player id="1" name="hero"/>'
    local tbl = lurek.serial.decodeXml(xml)
    expect_equal(tbl.tag, "player")
    expect_equal(tbl.attrs.id, "1")
    expect_equal(tbl.attrs.name, "hero")
  end)

  -- @covers lurek.serial.decodeXml
  it("captures child elements", function()
    local xml = "<items><item>sword</item><item>shield</item></items>"
    local tbl = lurek.serial.decodeXml(xml)
    expect_equal(tbl.tag, "items")
    expect_equal(#tbl.children, 2)
    expect_equal(tbl.children[1].tag, "item")
    expect_equal(tbl.children[1].text, "sword")
    expect_equal(tbl.children[2].text, "shield")
  end)

  -- @covers lurek.serial.decodeXml
  it("omits attrs table when element has no attributes", function()
    local xml = "<root><child/></root>"
    local tbl = lurek.serial.decodeXml(xml)
    expect_equal(tbl.attrs, nil)
    expect_equal(tbl.children[1].attrs, nil)
  end)

  -- @covers lurek.serial.decodeXml
  it("omits children table when element has no child elements", function()
    local xml = "<leaf>text</leaf>"
    local tbl = lurek.serial.decodeXml(xml)
    expect_equal(tbl.children, nil)
  end)

  -- @covers lurek.serial.decodeXml
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

  -- @covers lurek.serial.decodeXml
  it("errors on malformed XML", function()
    expect_error(function() lurek.serial.decodeXml("<unclosed") end)
  end)

  -- @covers lurek.serial.decodeXml
  it("errors on mismatched tags", function()
    expect_error(function() lurek.serial.decodeXml("<a></b>") end)
  end)
end)

-- @describe lurek.serial regression coverage
describe("lurek.serial regression coverage", function()
  -- @covers lurek.serial.decodeMsgPack
  -- @covers lurek.serial.encodeMsgPack
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

  -- @covers lurek.serial.decodeMsgPack
  -- @covers lurek.serial.encodeMsgPack
  it("decodeMsgPack preserves sequential arrays", function()
    local decoded = lurek.serial.decodeMsgPack(lurek.serial.encodeMsgPack({ 10, 20, 30 }))
    expect_equal(3, #decoded)
    expect_equal(20, decoded[2])
  end)

  -- @covers lurek.serial.decodeXml
  it("decodeXml returns root tag text and attributes", function()
    local decoded = lurek.serial.decodeXml("<root version=\"1\">hello</root>")
    expect_equal("root", decoded.tag)
    expect_equal("1", decoded.attrs.version)
    expect_equal("hello", decoded.text)
  end)

  -- @covers lurek.serial.validate
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

-- @describe lurek.serial unified codec API
describe("lurek.serial unified codec API", function()
  -- @covers lurek.serial.detectFormat
  it("detectFormat identifies json", function()
    expect_equal("json", lurek.serial.detectFormat('{"name":"hero"}'))
  end)

  -- @covers lurek.serial.detectFormat
  it("detectFormat returns nil for unknown text", function()
    expect_equal(nil, lurek.serial.detectFormat("hello world"))
  end)

  -- @covers lurek.serial.decode
  it("decode auto-detect parses toml", function()
    local tbl = lurek.serial.decode("title = \"demo\"")
    expect_equal("demo", tbl.title)
  end)

  -- @covers lurek.serial.decode
  it("decode explicit ini parses ini text", function()
    local tbl = lurek.serial.decode("[player]\nname=hero\n", "ini")
    expect_equal("hero", tbl.player.name)
  end)

  -- @covers lurek.serial.decode
  it("decode explicit msgpack parses binary bytes", function()
    local bytes = lurek.serial.encodeMsgPack({ hp = 10 })
    local tbl = lurek.serial.decode(bytes, "msgpack")
    expect_equal(10, tbl.hp)
  end)

  -- @covers lurek.serial.encode
  it("encode supports json pretty option", function()
    local s = lurek.serial.encode({ a = 1 }, "json", { pretty = true })
    expect_equal("string", type(s))
    expect_true(#s > 0)
  end)

  -- @covers lurek.serial.encode
  it("encode supports csv options", function()
    local rows = {
      { name = "ada", score = "10" },
      { name = "lin", score = "20" },
    }
    local csv = lurek.serial.encode(rows, "csv", { delimiter = ";", has_headers = true })
    expect_true(string.find(csv, ";") ~= nil)
  end)

  -- @covers lurek.serial.applyDefaults
  it("applyDefaults fills missing fields", function()
    local schema = {
      type = "table",
      fields = {
        hp = { type = "number", default = 100 },
        name = { type = "string", default = "hero" },
      },
    }
    local patched = lurek.serial.applyDefaults({}, schema)
    expect_equal(100, patched.hp)
    expect_equal("hero", patched.name)
  end)
end)

-- @describe unit: migrated from integration/test_data_filesystem.lua
describe("unit: migrated from integration/test_data_filesystem.lua", function()
        -- @covers lurek.serial.fromJson
        -- @covers lurek.serial.toJson
        it("round-trips nested data correctly", function()
            local nested = {
                meta = { version = 2, engine = "lurek" },
                data = { {x=1, y=2}, {x=3, y=4} },
            }

            local encoded = lurek.serial.toJson(nested)
            local decoded = lurek.serial.fromJson(encoded)

            expect_equal(2, decoded.meta.version, "nested version")
            expect_equal("lurek", decoded.meta.engine, "nested engine")
        end)

        -- @covers lurek.serial.fromJson
        -- @covers lurek.serial.toJson
        it("large table serialization stress", function()
            local big = {}
            for i = 1, 200 do
                big[i] = { x = i * 0.1, y = i * 0.2, name = "item_" .. i }
            end

            local encoded = lurek.serial.toJson(big)
            expect_true(#encoded > 100, "encoded has content")

            local decoded = lurek.serial.fromJson(encoded)
            expect_equal(200, #decoded, "200 items decoded")
            expect_near(20.0, decoded[200].x, 0.1, "last item x correct")
        end)

end)

-- @describe unit: migrated from integration/test_inventory_save_integration.lua
describe("unit: migrated from integration/test_inventory_save_integration.lua", function()
        local inventory = rawget(_G, "inventory")
        if inventory == nil then
            -- @covers inventory
            it("inventory module unavailable in this runtime", function()
                expect_nil(inventory)
            end)
            return
        end

        local function snapshot(inv)
            local out = { containers = {} }
            local names = inv:listContainers()
            for _, name in ipairs(names) do
                local c = inv:getContainer(name)
                local entry = {
                    name = name,
                    items = {},
                }
                local items = c:listItems()
                for _, item in ipairs(items) do
                    table.insert(entry.items, {
                        type = item:getType(),
                        qty = item:getQuantity(),
                    })
                end
                table.insert(out.containers, entry)
            end
            return out
        end
        -- @covers lurek.serial.fromJson
        -- @covers lurek.serial.toJson
        it("snapshot round-trips through codec.toJson/fromJson", function()
            local inv = inventory.newInventory()
            local bag = inventory.newContainer("bag", "fixed", 8, 8)
            inv:addContainer("bag", bag)
            local item = inventory.newItem("potion")
            bag:addItem(item, 3)

            local snap = snapshot(inv)
            local json = lurek.serial.toJson(snap)
            expect_type("string", json)
            local decoded = lurek.serial.fromJson(json)

            expect_type("table", decoded)
            expect_type("table", decoded.containers)
            expect_equal(1, #decoded.containers)
            expect_equal("bag", decoded.containers[1].name)
            expect_equal("potion", decoded.containers[1].items[1].type)
            expect_equal(3, decoded.containers[1].items[1].qty)
        end)

        -- @covers lurek.serial.fromJson
        -- @covers lurek.serial.toJson
        it("stack counts survive round-trip", function()
            local inv = inventory.newInventory()
            local box = inventory.newContainer("box", "fixed", 4, 4)
            inv:addContainer("box", box)
            local arrow = inventory.newItem("arrow")
            arrow:setStackLimit(99)
            box:addItem(arrow, 12)

            local json = lurek.serial.toJson(snapshot(inv))
            local back = lurek.serial.fromJson(json)
            expect_equal(12, back.containers[1].items[1].qty)
        end)

        -- @covers lurek.serial.fromJson
        -- @covers lurek.serial.toJson
        it("container order is preserved across round-trip", function()
            local inv = inventory.newInventory()
            for _, name in ipairs({ "alpha", "bravo", "charlie" }) do
                inv:addContainer(name, inventory.newContainer(name, "fixed", 1, 1))
            end
            local back = lurek.serial.fromJson(lurek.serial.toJson(snapshot(inv)))
            expect_equal("alpha", back.containers[1].name)
            expect_equal("bravo", back.containers[2].name)
            expect_equal("charlie", back.containers[3].name)
        end)

        -- @covers lurek.serial.fromJson
        it("missing containers field decodes to empty list with sensible default", function()
            local back = lurek.serial.fromJson("{}")
            expect_type("table", back)
            local containers = back.containers or {}
            expect_equal(0, #containers)
        end)

        -- @covers lurek.serial.fromJson
        it("corrupt JSON raises an error when decoded", function()
            expect_error(function()
                lurek.serial.fromJson("{not valid json")
            end)
        end)

        -- @covers lurek.serial.fromJson
        -- @covers lurek.serial.toJson
        it("empty inventory round-trips without loss", function()
            local inv = inventory.newInventory()
            local json = lurek.serial.toJson(snapshot(inv))
            local back = lurek.serial.fromJson(json)
            expect_type("table", back)
            expect_equal(0, #(back.containers or {}))
        end)

        -- @covers lurek.serial.fromJson
        -- @covers lurek.serial.toJson
        it("snapshot round-trips through codec.toJson/fromJson", function()
            local inv = inventory.newInventory()
            local bag = inventory.newContainer("bag", "fixed", 8, 8)
            inv:addContainer("bag", bag)
            local item = inventory.newItem("potion")
            bag:addItem(item, 3)

            local snap = snapshot(inv)
            local json = lurek.serial.toJson(snap)
            expect_type("string", json)
            local decoded = lurek.serial.fromJson(json)

            expect_type("table", decoded)
            expect_type("table", decoded.containers)
            expect_equal(1, #decoded.containers)
            expect_equal("bag", decoded.containers[1].name)
            expect_equal("potion", decoded.containers[1].items[1].type)
            expect_equal(3, decoded.containers[1].items[1].qty)
        end)

        -- @covers lurek.serial.fromJson
        -- @covers lurek.serial.toJson
        it("stack counts survive round-trip", function()
            local inv = inventory.newInventory()
            local box = inventory.newContainer("box", "fixed", 4, 4)
            inv:addContainer("box", box)
            local arrow = inventory.newItem("arrow")
            arrow:setStackLimit(99)
            box:addItem(arrow, 12)

            local json = lurek.serial.toJson(snapshot(inv))
            local back = lurek.serial.fromJson(json)
            expect_equal(12, back.containers[1].items[1].qty)
        end)

        -- @covers lurek.serial.fromJson
        -- @covers lurek.serial.toJson
        it("container order is preserved across round-trip", function()
            local inv = inventory.newInventory()
            for _, name in ipairs({ "alpha", "bravo", "charlie" }) do
                inv:addContainer(name, inventory.newContainer(name, "fixed", 1, 1))
            end
            local back = lurek.serial.fromJson(lurek.serial.toJson(snapshot(inv)))
            expect_equal("alpha", back.containers[1].name)
            expect_equal("bravo", back.containers[2].name)
            expect_equal("charlie", back.containers[3].name)
        end)

        -- @covers lurek.serial.fromJson
        it("missing containers field decodes to empty list with sensible default", function()
            local back = lurek.serial.fromJson("{}")
            expect_type("table", back)
            local containers = back.containers or {}
            expect_equal(0, #containers)
        end)

        -- @covers lurek.serial.fromJson
        it("corrupt JSON raises an error when decoded", function()
            expect_error(function()
                lurek.serial.fromJson("{not valid json")
            end)
        end)

        -- @covers lurek.serial.fromJson
        -- @covers lurek.serial.toJson
        it("empty inventory round-trips without loss", function()
            local inv = inventory.newInventory()
            local json = lurek.serial.toJson(snapshot(inv))
            local back = lurek.serial.fromJson(json)
            expect_type("table", back)
            expect_equal(0, #(back.containers or {}))
        end)

end)

-- @describe property: serial json invariants
describe("property: serial json invariants", function()
        -- @covers lurek.serial.fromJson
        -- @covers lurek.serial.toJson
        it("json roundtrip keeps deterministic records", function()
            for i = 1, 25 do
                local record = {
                    id = i,
                    name = "n" .. tostring(i),
                    active = (i % 2 == 0),
                    score = i * 3,
                }
                local encoded = lurek.serial.toJson(record)
                local decoded = lurek.serial.fromJson(encoded)
                expect_equal(record.id, decoded.id)
                expect_equal(record.name, decoded.name)
                expect_equal(record.active, decoded.active)
                expect_equal(record.score, decoded.score)
            end
        end)
end)

test_summary()
