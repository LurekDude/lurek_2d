-- tests/lua/unit/test_serial_schema.lua
-- BDD tests for lurek.codec.validate

describe("lurek.codec.validate – type checks", function()
  it("passes when type matches string", function()
    local ok, err = lurek.codec.validate("hello", { type = "string" })
    expect_equal(ok, true)
    expect_equal(err, nil)
  end)

  it("passes when type matches number", function()
    local ok, err = lurek.codec.validate(42, { type = "number" })
    expect_equal(ok, true)
    expect_equal(err, nil)
  end)

  it("passes when type matches boolean", function()
    local ok, err = lurek.codec.validate(true, { type = "boolean" })
    expect_equal(ok, true)
    expect_equal(err, nil)
  end)

  it("fails when type mismatches", function()
    local ok, err = lurek.codec.validate(42, { type = "string" })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  it("passes for any type with type='any'", function()
    local ok = lurek.codec.validate("anything", { type = "any" })
    expect_equal(ok, true)
  end)
end)

describe("lurek.codec.validate – required field", function()
  it("passes when non-nil value and required=true", function()
    local ok = lurek.codec.validate("value", { type = "string", required = true })
    expect_equal(ok, true)
  end)

  it("fails when nil value and required=true", function()
    local ok, err = lurek.codec.validate(nil, { type = "string", required = true })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  it("passes when nil value and required not set", function()
    local ok = lurek.codec.validate(nil, { type = "string" })
    expect_equal(ok, true)
  end)
end)

describe("lurek.codec.validate – numeric range", function()
  it("passes when value is within min/max", function()
    local ok = lurek.codec.validate(50, { type = "number", min = 1, max = 100 })
    expect_equal(ok, true)
  end)

  it("fails when value is below min", function()
    local ok, err = lurek.codec.validate(0, { type = "number", min = 1, max = 100 })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  it("fails when value exceeds max", function()
    local ok, err = lurek.codec.validate(101, { type = "number", min = 1, max = 100 })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  it("passes at exactly min", function()
    local ok = lurek.codec.validate(1, { type = "number", min = 1, max = 100 })
    expect_equal(ok, true)
  end)

  it("passes at exactly max", function()
    local ok = lurek.codec.validate(100, { type = "number", min = 1, max = 100 })
    expect_equal(ok, true)
  end)
end)

describe("lurek.codec.validate – string length", function()
  it("passes when string length is within minlen/maxlen", function()
    local ok = lurek.codec.validate("abc", { type = "string", minlen = 1, maxlen = 10 })
    expect_equal(ok, true)
  end)

  it("fails when string is shorter than minlen", function()
    local ok, err = lurek.codec.validate("", { type = "string", minlen = 1 })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  it("fails when string exceeds maxlen", function()
    local ok, err = lurek.codec.validate("toolong", { type = "string", maxlen = 3 })
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)
end)

describe("lurek.codec.validate – table fields", function()
  local schema = {
    type = "table",
    fields = {
      name  = { type = "string", required = true },
      level = { type = "number", min = 1, max = 100 },
    }
  }

  it("passes a valid table", function()
    local ok = lurek.codec.validate({ name = "hero", level = 5 }, schema)
    expect_equal(ok, true)
  end)

  it("fails when required field is missing", function()
    local ok, err = lurek.codec.validate({ level = 5 }, schema)
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  it("fails when field type is wrong", function()
    local ok, err = lurek.codec.validate({ name = 42, level = 5 }, schema)
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  it("fails when numeric field is out of range", function()
    local ok, err = lurek.codec.validate({ name = "hero", level = 200 }, schema)
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)
end)

describe("lurek.codec.validate – sequence items", function()
  local schema = {
    type  = "table",
    items = { type = "string" }
  }

  it("passes when all items match type", function()
    local ok = lurek.codec.validate({ "a", "b", "c" }, schema)
    expect_equal(ok, true)
  end)

  it("fails when an item has the wrong type", function()
    local ok, err = lurek.codec.validate({ "a", 2, "c" }, schema)
    expect_equal(ok, false)
    expect_equal(type(err), "string")
  end)

  it("passes an empty sequence", function()
    local ok = lurek.codec.validate({}, schema)
    expect_equal(ok, true)
  end)
end)

test_summary()
