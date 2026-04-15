-- tests/lua/unit/test_serial_msgpack.lua
-- BDD tests for lurek.codec.encodeMsgPack / decodeMsgPack

describe("lurek.codec.encodeMsgPack", function()
  it("returns a non-empty string for a simple table", function()
    local bytes = lurek.codec.encodeMsgPack({ name = "hero", level = 5 })
    expect_equal(type(bytes), "string")
    expect_equal(#bytes > 0, true)
  end)

  it("errors on nil input", function()
    expect_error(function() lurek.codec.encodeMsgPack(nil) end)
  end)

  it("errors on string input", function()
    expect_error(function() lurek.codec.encodeMsgPack("not a table") end)
  end)

  it("errors on number input", function()
    expect_error(function() lurek.codec.encodeMsgPack(42) end)
  end)
end)

describe("lurek.codec.decodeMsgPack", function()
  it("round-trips string and number fields", function()
    local tbl = { name = "hero", level = 5 }
    local bytes = lurek.codec.encodeMsgPack(tbl)
    local decoded = lurek.codec.decodeMsgPack(bytes)
    expect_equal(decoded.name, "hero")
    expect_equal(decoded.level, 5)
  end)

  it("round-trips nested tables", function()
    local tbl = { pos = { x = 10, y = 20 } }
    local bytes = lurek.codec.encodeMsgPack(tbl)
    local decoded = lurek.codec.decodeMsgPack(bytes)
    expect_equal(decoded.pos.x, 10)
    expect_equal(decoded.pos.y, 20)
  end)

  it("round-trips a boolean field", function()
    local tbl = { alive = true, dead = false }
    local bytes = lurek.codec.encodeMsgPack(tbl)
    local decoded = lurek.codec.decodeMsgPack(bytes)
    expect_equal(decoded.alive, true)
    expect_equal(decoded.dead, false)
  end)

  it("round-trips an array-style table", function()
    local tbl = { items = { "sword", "shield", "potion" } }
    local bytes = lurek.codec.encodeMsgPack(tbl)
    local decoded = lurek.codec.decodeMsgPack(bytes)
    expect_equal(decoded.items[1], "sword")
    expect_equal(decoded.items[2], "shield")
    expect_equal(decoded.items[3], "potion")
  end)

  it("errors on invalid bytes", function()
    expect_error(function() lurek.codec.decodeMsgPack("\xc1\xc1\xc1") end)
  end)
end)

test_summary()
