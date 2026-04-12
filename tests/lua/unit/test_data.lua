-- tests/lua/unit/test_data.lua
-- BDD tests for the lurek.data module
-- @covers lurek.data.pack
-- @covers lurek.data.unpack
-- @covers lurek.data.getPackedSize
-- @covers lurek.data.newDataView
-- @covers lurek.data.compress
-- @covers lurek.data.decompress
-- @covers lurek.data.encode
-- @covers lurek.data.decode
-- @covers lurek.data.hash
-- @covers lurek.data.newByteData
-- @covers lurek.data.parseToml
-- @covers lurek.data.encodeToml
-- @covers lurek.data.write
-- @covers lurek.data.read
-- @covers lurek.data.size


describe("data.pack + data.unpack", function()
  it("round-trips f32", function()
    local b = lurek.data.pack("<f", 3.14)
    local v = lurek.data.unpack("<f", b)
    expect_near(v, 3.14, 0.01)
  end)

  it("round-trips u8 max", function()
    local b = lurek.data.pack("B", 255)
    local v = lurek.data.unpack("B", b)
    expect_equal(v, 255)
  end)

  it("round-trips u8 zero", function()
    local b = lurek.data.pack("B", 0)
    local v = lurek.data.unpack("B", b)
    expect_equal(v, 0)
  end)

  it("round-trips i8 negative", function()
    local b = lurek.data.pack("b", -1)
    local v = lurek.data.unpack("b", b)
    expect_equal(v, -1)
  end)

  it("round-trips u16", function()
    local b = lurek.data.pack("<H", 1000)
    local v = lurek.data.unpack("<H", b)
    expect_equal(v, 1000)
  end)

  it("round-trips i32", function()
    local b = lurek.data.pack("<i", -123456)
    local v = lurek.data.unpack("<i", b)
    expect_equal(v, -123456)
  end)

  it("round-trips u32", function()
    local b = lurek.data.pack("<I", 123456)
    local v = lurek.data.unpack("<I", b)
    expect_equal(v, 123456)
  end)

  it("round-trips f64 (double)", function()
    local b = lurek.data.pack("<d", 1.23456789)
    local v = lurek.data.unpack("<d", b)
    expect_near(v, 1.23456789, 1e-9)
  end)

  it("round-trips length-prefixed string", function()
    local b = lurek.data.pack("s", "hello")
    local v = lurek.data.unpack("s", b)
    expect_equal(v, "hello")
  end)

  it("round-trips null-terminated string", function()
    local b = lurek.data.pack("z", "world")
    local v = lurek.data.unpack("z", b)
    expect_equal(v, "world")
  end)

  it("returns next byte position", function()
    local b = lurek.data.pack("BB", 10, 20)
    local v1, v2, pos = lurek.data.unpack("BB", b)
    expect_equal(v1, 10)
    expect_equal(v2, 20)
    expect_equal(pos, 2)
  end)

  it("respects big-endian prefix", function()
    local b = lurek.data.pack(">H", 0x0102)
    expect_equal(string.byte(b, 1), 0x01)
    expect_equal(string.byte(b, 2), 0x02)
  end)

  it("respects little-endian prefix", function()
    local b = lurek.data.pack("<H", 0x0102)
    expect_equal(string.byte(b, 1), 0x02)
    expect_equal(string.byte(b, 2), 0x01)
  end)

  it("padding byte is zero", function()
    local b = lurek.data.pack("xB", 42)
    expect_equal(string.len(b), 2)
    expect_equal(string.byte(b, 1), 0)
    expect_equal(string.byte(b, 2), 42)
  end)

  it("unpack with offset skips bytes", function()
    local b = lurek.data.pack("BB", 11, 22)
    local v, pos = lurek.data.unpack("B", b, 1)
    expect_equal(v, 22)
    expect_equal(pos, 2)
  end)
end)

describe("data.getPackedSize", function()
  it("returns 1 for B", function()
    expect_equal(lurek.data.getPackedSize("B"), 1)
  end)

  it("returns 4 for f", function()
    expect_equal(lurek.data.getPackedSize("f"), 4)
  end)

  it("returns 5 for Bf (1 + 4)", function()
    expect_equal(lurek.data.getPackedSize("Bf"), 5)
  end)

  it("returns 8 for d (f64)", function()
    expect_equal(lurek.data.getPackedSize("d"), 8)
  end)

  it("returns 2 for H", function()
    expect_equal(lurek.data.getPackedSize("H"), 2)
  end)

  it("returns 4 for I", function()
    expect_equal(lurek.data.getPackedSize("I"), 4)
  end)

  it("returns 8 for L (u64)", function()
    expect_equal(lurek.data.getPackedSize("L"), 8)
  end)

  it("counts x padding byte", function()
    expect_equal(lurek.data.getPackedSize("xB"), 2)
  end)
end)

describe("data.newDataView", function()
  it("DataView reads u8 written by pack", function()
    local b = lurek.data.pack("B", 255)
    local dv = lurek.data.newDataView(b)
    expect_equal(dv:getUInt8(0), 255)
  end)

  it("DataView getSize returns correct size", function()
    local b = lurek.data.pack("BH", 1, 2)
    local dv = lurek.data.newDataView(b)
    expect_equal(dv:getSize(), 3)
  end)

  it("DataView reads u16 from little-endian pack", function()
    local b = lurek.data.pack("<H", 1000)
    local dv = lurek.data.newDataView(b)
    expect_equal(dv:getUInt16(0), 1000)
  end)

  it("DataView reads f32 (getFloat)", function()
    local b = lurek.data.pack("<f", 1.5)
    local dv = lurek.data.newDataView(b)
    expect_near(dv:getFloat(0), 1.5, 0.0001)
  end)

  it("DataView reads f64 (getDouble)", function()
    local b = lurek.data.pack("<d", 2.718281828)
    local dv = lurek.data.newDataView(b)
    expect_near(dv:getDouble(0), 2.718281828, 1e-9)
  end)

  it("DataView reads u32", function()
    local b = lurek.data.pack("<I", 100000)
    local dv = lurek.data.newDataView(b)
    expect_equal(dv:getUInt32(0), 100000)
  end)

  it("DataView with offset reads sub-buffer", function()
    local b = lurek.data.pack("BH", 99, 512)
    local dv = lurek.data.newDataView(b, 1, 2)
    expect_equal(dv:getUInt16(0), 512)
    expect_equal(dv:getSize(), 2)
  end)

  it("DataView out-of-bounds access raises error", function()
    local b = lurek.data.pack("B", 1)
    local dv = lurek.data.newDataView(b)
    expect_error(function() dv:getUInt16(0) end)
  end)
end)

-- ── compress / decompress ────────────────────────────────────────────────────
-- @covers lurek.data.compress
-- @covers lurek.data.decompress

describe("data.compress + data.decompress", function()
  it("round-trips deflate", function()
    local original = "Hello, Lurek2D! Deflate compression test."
    local compressed = lurek.data.compress("deflate", original)
    local decompressed = lurek.data.decompress("deflate", compressed)
    expect_equal(decompressed, original)
  end)

  it("deflate actually compresses (smaller output)", function()
    local original = string.rep("AAAA", 100)
    local compressed = lurek.data.compress("deflate", original)
    expect_true(#compressed < #original)
  end)

  it("round-trips gzip", function()
    local original = "Hello, Lurek2D! Gzip compression test."
    local compressed = lurek.data.compress("gzip", original)
    local decompressed = lurek.data.decompress("gzip", compressed)
    expect_equal(decompressed, original)
  end)

  it("round-trips lz4", function()
    local original = "Hello, Lurek2D! LZ4 compression test."
    local compressed = lurek.data.compress("lz4", original)
    local decompressed = lurek.data.decompress("lz4", compressed)
    expect_equal(decompressed, original)
  end)

  it("handles empty data", function()
    local compressed = lurek.data.compress("deflate", "")
    local decompressed = lurek.data.decompress("deflate", compressed)
    expect_equal(decompressed, "")
  end)
end)

-- ── encode / decode ──────────────────────────────────────────────────────────
-- @covers lurek.data.encode
-- @covers lurek.data.decode

describe("data.encode + data.decode", function()
  it("round-trips base64", function()
    local original = "Hello, Lurek2D!"
    local encoded = lurek.data.encode("base64", original)
    expect_equal(encoded, "SGVsbG8sIEx1cmVrMkQh")
    local decoded = lurek.data.decode("base64", encoded)
    expect_equal(decoded, original)
  end)

  it("round-trips hex", function()
    local original = "Hello"
    local encoded = lurek.data.encode("hex", original)
    expect_equal(encoded, "48656c6c6f")
    local decoded = lurek.data.decode("hex", encoded)
    expect_equal(decoded, original)
  end)

  it("base64 encodes empty string", function()
    local encoded = lurek.data.encode("base64", "")
    expect_equal(encoded, "")
  end)

  it("hex encodes single byte", function()
    local encoded = lurek.data.encode("hex", "\x00")
    expect_equal(encoded, "00")
  end)
end)

-- ── hash ─────────────────────────────────────────────────────────────────────
-- @covers lurek.data.hash

describe("data.hash", function()
  it("md5 produces known digest", function()
    expect_equal(lurek.data.hash("md5", "hello"), "5d41402abc4b2a76b9719d911017c592")
  end)

  it("sha1 produces known digest", function()
    expect_equal(lurek.data.hash("sha1", "hello"), "aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d")
  end)

  it("sha256 produces known digest", function()
    expect_equal(lurek.data.hash("sha256", "hello"),
      "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
  end)

  it("sha512 produces known digest", function()
    expect_equal(lurek.data.hash("sha512", "hello"),
      "9b71d224bd62f3785d96d46ad3ea3d73319bfbc2890caadae2dff72519673ca72323c3d99ba5c11d7c7acc6e14b8c5da0c4663475c2e5c3adef46f73bcdec043")
  end)

  it("different input produces different hash", function()
    local h1 = lurek.data.hash("sha256", "hello")
    local h2 = lurek.data.hash("sha256", "world")
    expect_not_equal(h1, h2)
  end)

  it("same input produces same hash", function()
    local h1 = lurek.data.hash("sha256", "test")
    local h2 = lurek.data.hash("sha256", "test")
    expect_equal(h1, h2)
  end)
end)

-- ── newByteData ──────────────────────────────────────────────────────────────
-- @covers lurek.data.newByteData

describe("data.newByteData", function()
  it("creates zeroed buffer from size", function()
    local bd = lurek.data.newByteData(10)
    expect_equal(bd:getSize(), 10)
    expect_equal(bd:getByte(0), 0)
  end)

  it("creates buffer from string", function()
    local bd = lurek.data.newByteData("hello")
    expect_equal(bd:getSize(), 5)
    expect_equal(bd:getString(), "hello")
  end)

  it("setByte and getByte round-trip", function()
    local bd = lurek.data.newByteData(4)
    bd:setByte(0, 65)
    bd:setByte(1, 66)
    expect_equal(bd:getByte(0), 65)
    expect_equal(bd:getByte(1), 66)
  end)

  it("clone produces independent copy", function()
    local original = lurek.data.newByteData("test")
    local cloned = original:clone()
    expect_equal(cloned:getString(), "test")
    expect_equal(cloned:getSize(), 4)
  end)
end)

-- ── parseToml / encodeToml ───────────────────────────────────────────────────
-- @covers lurek.data.parseToml
-- @covers lurek.data.encodeToml

describe("data.parseToml + data.encodeToml", function()
  it("parses basic types", function()
    local t = lurek.data.parseToml('name = "hello"\ncount = 42\nactive = true')
    expect_equal(t.name, "hello")
    expect_equal(t.count, 42)
    expect_equal(t.active, true)
  end)

  it("parses nested table", function()
    local t = lurek.data.parseToml('[window]\nwidth = 800\nheight = 600\ntitle = "Lurek2D"')
    expect_equal(t.window.width, 800)
    expect_equal(t.window.height, 600)
    expect_equal(t.window.title, "Lurek2D")
  end)

  it("parses array", function()
    local t = lurek.data.parseToml('items = [1, 2, 3]')
    expect_equal(#t.items, 3)
    expect_equal(t.items[1], 1)
    expect_equal(t.items[3], 3)
  end)

  it("encodes basic table to TOML string", function()
    local result = lurek.data.encodeToml({ name = "test", count = 5 })
    expect_type("string", result)
    expect_match(result, 'name = "test"')
    expect_match(result, "count = 5")
  end)

  it("round-trips table through TOML", function()
    local original = { title = "game", debug = true }
    local encoded = lurek.data.encodeToml(original)
    local decoded = lurek.data.parseToml(encoded)
    expect_equal(decoded.title, "game")
    expect_equal(decoded.debug, true)
  end)

  it("parseToml errors on invalid TOML", function()
    expect_error(function()
      lurek.data.parseToml("invalid = [")
    end)
  end)
end)

-- ── write / read (Binary Pack Format) ────────────────────────────────────────
-- @covers lurek.data.write
-- @covers lurek.data.read
-- @covers lurek.data.size

describe("data.write + data.read (Binary Pack Format)", function()
  it("round-trips u32 and f32", function()
    local b = lurek.data.write("u32 f32", 42, 3.14)
    local v1, v2 = lurek.data.read("u32 f32", b)
    expect_equal(v1, 42)
    expect_near(v2, 3.14, 0.01)
  end)

  it("round-trips str", function()
    local b = lurek.data.write("str", "hello")
    local v = lurek.data.read("str", b)
    expect_equal(v, "hello")
  end)

  it("round-trips cstr (null-terminated)", function()
    local b = lurek.data.write("cstr", "world")
    local v = lurek.data.read("cstr", b)
    expect_equal(v, "world")
  end)

  it("round-trips bool", function()
    local b = lurek.data.write("bool bool", true, false)
    local v1, v2 = lurek.data.read("bool bool", b)
    expect_equal(v1, true)
    expect_equal(v2, false)
  end)

  it("data.size returns correct byte count", function()
    expect_equal(lurek.data.size("u8 u16 u32 u64 i8 i16 i32 i64"), 30)
    expect_equal(lurek.data.size("f32 f64 bool pad"), 14)
  end)

  it("big-endian u16 has correct byte order", function()
    local b = lurek.data.write("be u16", 0x0102)
    expect_equal(string.byte(b, 1), 0x01)
    expect_equal(string.byte(b, 2), 0x02)
  end)

  it("little-endian u16 has correct byte order", function()
    local b = lurek.data.write("le u16", 0x0102)
    expect_equal(string.byte(b, 1), 0x02)
    expect_equal(string.byte(b, 2), 0x01)
  end)
end)

test_summary()
