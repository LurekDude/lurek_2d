-- tests/lua/unit/test_data.lua
-- BDD tests for the lurek.data module

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

  it("round-trips big-endian i16", function()
    local b = lurek.data.pack(">h", 256)
    local v = lurek.data.unpack(">h", b)
    expect_equal(v, 256)
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

  it("counts length-prefixed string payload bytes", function()
    expect_equal(lurek.data.getPackedSize("<s", "hi"), 6)
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

-- compress / decompress

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

  it("round-trips zlib", function()
    local original = "Hello, Lurek2D! Zlib compression test."
    local compressed = lurek.data.compress("zlib", original)
    local decompressed = lurek.data.decompress("zlib", compressed)
    expect_equal(decompressed, original)
  end)

  it("accepts case-insensitive compression format names", function()
    local original = "Mixed-case gzip format parse"
    local compressed = lurek.data.compress("GZip", original)
    local decompressed = lurek.data.decompress("GZip", compressed)
    expect_equal(decompressed, original)
  end)

  it("handles empty data", function()
    local compressed = lurek.data.compress("deflate", "")
    local decompressed = lurek.data.decompress("deflate", compressed)
    expect_equal(decompressed, "")
  end)

  it("clamps oversized compression levels", function()
    local original = "compression level clamp"
    local compressed = lurek.data.compress("deflate", original, 99)
    local decompressed = lurek.data.decompress("deflate", compressed)
    expect_equal(decompressed, original)
  end)

  it("unknown compression format errors", function()
    expect_error(function()
      lurek.data.compress("brotli", "test")
    end)
  end)
end)

-- encode / decode

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

  it("unknown encoding format errors", function()
    expect_error(function()
      lurek.data.encode("binary", "abc")
    end)
  end)
end)

-- hash

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

  it("unknown hash algorithm errors", function()
    expect_error(function()
      lurek.data.hash("blake2", "hello")
    end)
  end)
end)


-- newByteData

describe("data.newByteData", function()
  it("creates zeroed buffer from size", function()
    local bd = lurek.data.newByteData(10)
    expect_equal(bd:getSize(), 10)
    expect_equal(bd:getByte(0), 0)
  end)

  it("creates buffer from string", function()
    local new_byte_data = lurek.data.newByteData
    ---@cast new_byte_data fun(data: string): LByteData
    local bd = new_byte_data("hello")
    expect_equal(bd:getSize(), 5)
    expect_equal(bd:getString(), "hello")
  end)

  it("creates empty buffer from size 0", function()
    local bd = lurek.data.newByteData(0)
    expect_equal(bd:getSize(), 0)
    expect_equal(bd:getString(), "")
  end)

  it("setByte and getByte round-trip", function()
    local bd = lurek.data.newByteData(4)
    bd:setByte(0, 65)
    bd:setByte(1, 66)
    expect_equal(bd:getByte(0), 65)
    expect_equal(bd:getByte(1), 66)
  end)


  it("getByte out of bounds raises an error", function()
    local bd = lurek.data.newByteData(4)
    expect_error(function()
      bd:getByte(99)
    end)
  end)

  it("setByte out of bounds raises an error", function()
    local bd = lurek.data.newByteData(4)
    expect_error(function()
      bd:setByte(99, 1)
    end)
  end)

  it("clone produces independent copy", function()
    local new_byte_data = lurek.data.newByteData
    ---@cast new_byte_data fun(data: string): LByteData
    local original = new_byte_data("test")
    local cloned = original:clone()
    expect_equal(cloned:getString(), "test")
    expect_equal(cloned:getSize(), 4)
  end)
end)

-- parseToml / encodeToml

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

  it("parses empty document as an empty table", function()
    local t = lurek.data.parseToml("")
    expect_type("table", t)
    expect_equal(next(t), nil)
  end)

  it("parses arrays of tables", function()
    local t = lurek.data.parseToml('[[items]]\nname = "one"\n\n[[items]]\nname = "two"\n')
    expect_equal(#t.items, 2)
    expect_equal(t.items[1].name, "one")
    expect_equal(t.items[2].name, "two")
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

  it("encodes an empty table to an empty document", function()
    local encoded = lurek.data.encodeToml({})
    expect_type("string", encoded)
    expect_true(encoded == "" or encoded:match("^%s*$") ~= nil)
  end)

  it("parseToml errors on invalid TOML", function()
    expect_error(function()
      lurek.data.parseToml("invalid = [")
    end)
  end)

  it("encodeToml errors on non-table input", function()
    local encode_toml = lurek.data.encodeToml
    ---@cast encode_toml fun(value: any): string
    expect_error(function()
      encode_toml("not a table")
    end)
  end)
end)

-- write / read (Binary Pack Format)

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

  it("data.size errors on variable-length string tokens", function()
    expect_error(function() lurek.data.size("str") end)
    expect_error(function() lurek.data.size("cstr") end)
  end)

  it("data.write errors on unknown token", function()
    expect_error(function() lurek.data.write("float128", 1) end)
  end)

  it("data.read errors on buffer underflow", function()
    expect_error(function() lurek.data.read("u32", "\x01\x02") end)
  end)
end)

-- ByteData bit operations

describe("data.newByteData bit operations", function()
  it("bytedata_setBit_and_getBit_round_trip", function()
    local bd = lurek.data.newByteData(2)
    bd:setBit(0, 3, true)
    expect_true(bd:getBit(0, 3), "bit 3 should be true after setBit")
    expect_false(bd:getBit(0, 2), "bit 2 should remain false")
  end)

  it("bytedata_setBit_clear_sets_false", function()
    local bd = lurek.data.newByteData(2)
    bd:setBit(0, 3, true)
    bd:setBit(0, 3, false)
    expect_false(bd:getBit(0, 3), "bit should be false after clearing")
  end)

  it("bytedata_readBits_single_byte", function()
    local bd = lurek.data.newByteData(2)
    bd:setByte(0, 0xFF)
    local val = bd:readBits(0, 0, 8)
    expect_equal(val, 255, "reading all 8 bits of 0xFF should give 255")
  end)

  it("bytedata_readBits_spanning_bytes", function()
    local bd = lurek.data.newByteData(2)
    bd:setByte(0, 0xFF)
    bd:setByte(1, 0x01)
    local val = bd:readBits(0, 4, 8)
    expect_equal(val, 31, "spanning read of 0xFF / 0x01 from bit 4 should yield 0x1F = 31")
  end)

  it("bytedata_setBit_out_of_range_raises_error", function()
    local bd = lurek.data.newByteData(2)
    expect_error(function()
      bd:setBit(0, 8, true)
    end)
  end)
end)

-- msgpack (merged from test_data_msgpack.lua)

describe("data.msgpack", function()

    it("roundtrips a boolean", function()
        local bytes = lurek.data.toMsgPack(true)
        expect_equal(type(bytes), "string")
        local val = lurek.data.fromMsgPack(bytes)
        expect_equal(val, true)
    end)

    it("roundtrips an integer", function()
        local bytes = lurek.data.toMsgPack(42)
        local val = lurek.data.fromMsgPack(bytes)
        expect_equal(val, 42)
    end)

    it("roundtrips a float", function()
        local bytes = lurek.data.toMsgPack(3.14)
        local val = lurek.data.fromMsgPack(bytes)
        expect_near(val, 3.14, 1e-10)
    end)

    it("roundtrips a string", function()
        local bytes = lurek.data.toMsgPack("hello msgpack")
        local val = lurek.data.fromMsgPack(bytes)
        expect_equal(val, "hello msgpack")
    end)

    it("roundtrips nil", function()
        local bytes = lurek.data.toMsgPack(nil)
        local val = lurek.data.fromMsgPack(bytes)
        expect_equal(val, nil)
    end)

    it("roundtrips a flat table (object)", function()
        local tbl = { x = 1, y = 2, name = "test" }
        local bytes = lurek.data.toMsgPack(tbl)
        local val = lurek.data.fromMsgPack(bytes)
      expect_type("table", val)
      ---@cast val table
        expect_equal(val.x, 1)
        expect_equal(val.y, 2)
        expect_equal(val.name, "test")
    end)

    it("roundtrips a sequence table (array)", function()
        local arr = { 10, 20, 30 }
        local bytes = lurek.data.toMsgPack(arr)
        local val = lurek.data.fromMsgPack(bytes)
      expect_type("table", val)
      ---@cast val table
        expect_equal(val[1], 10)
        expect_equal(val[2], 20)
        expect_equal(val[3], 30)
    end)

    it("roundtrips a nested table", function()
        local data = { player = { name = "hero", hp = 100 }, level = 5 }
        local bytes = lurek.data.toMsgPack(data)
        local val = lurek.data.fromMsgPack(bytes)
      expect_type("table", val)
      ---@cast val table
        expect_equal(val.level, 5)
        expect_equal(val.player.name, "hero")
        expect_equal(val.player.hp, 100)
    end)


    it("produces a binary string shorter than JSON for integers", function()
        local data = { a = 1, b = 2, c = 3 }
        local bytes = lurek.data.toMsgPack(data)
        local json  = lurek.serial.toJson(data, false)
        -- MessagePack should be more compact than JSON for this payload
        expect_equal(#bytes <= #json, true)
    end)

    it("raises an error when fromMsgPack receives invalid bytes", function()
        expect_error(function()
            -- 0xFF 0xFF is not valid MessagePack
            lurek.data.fromMsgPack("\xFF\xFF")
        end)
    end)

    it("raises an error when fromMsgPack receives empty bytes", function()
      expect_error(function()
        lurek.data.fromMsgPack("")
      end)
    end)

end)

-- ring buffer (merged from test_data_ring_buffer.lua)

describe("lurek.data.newRingBuffer factory", function()
  it("newRingBuffer is a function", function()
    expect_type("function", lurek.data.newRingBuffer)
  end)

  it("returns a userdata", function()
    local rb = lurek.data.newRingBuffer(4)
    expect_type("userdata", rb)
  end)

  it("capacity matches constructor argument", function()
    local rb = lurek.data.newRingBuffer(8)
    expect_equal(rb:capacity(), 8)
  end)

  it("new buffer has len 0", function()
    local rb = lurek.data.newRingBuffer(4)
    expect_equal(rb:len(), 0)
  end)

  it("new buffer isEmpty is true", function()
    local rb = lurek.data.newRingBuffer(4)
    expect_equal(rb:isEmpty(), true)
  end)

  it("new buffer isFull is false", function()
    local rb = lurek.data.newRingBuffer(4)
    expect_equal(rb:isFull(), false)
  end)

  it("capacity 0 raises an error", function()
    expect_error(function() lurek.data.newRingBuffer(0) end)
  end)
end)

describe("RingBuffer push/pop", function()
  it("push returns false when space available", function()
    local rb = lurek.data.newRingBuffer(4)
    local overwrote = rb:push(42)
    expect_equal(overwrote, false)
  end)

  it("push returns true when buffer is full", function()
    local rb = lurek.data.newRingBuffer(2)
    rb:push(1)
    rb:push(2)
    local overwrote = rb:push(3)
    expect_equal(overwrote, true)
  end)

  it("len increments after push", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push("hello")
    expect_equal(rb:len(), 1)
  end)

  it("pop on empty returns nil", function()
    local rb = lurek.data.newRingBuffer(4)
    expect_equal(rb:pop(), nil)
  end)

  it("pop returns the pushed value", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push(99)
    expect_equal(rb:pop(), 99)
  end)

  it("len decrements after pop", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push(1)
    rb:pop()
    expect_equal(rb:len(), 0)
  end)

  it("pop follows FIFO order", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push(10)
    rb:push(20)
    rb:push(30)
    expect_equal(rb:pop(), 10)
    expect_equal(rb:pop(), 20)
    expect_equal(rb:pop(), 30)
  end)

  it("overwrite preserves FIFO after wrap", function()
    local rb = lurek.data.newRingBuffer(3)
    rb:push("a")
    rb:push("b")
    rb:push("c")  -- full
    rb:push("d")  -- overwrites "a"
    expect_equal(rb:pop(), "b")
    expect_equal(rb:pop(), "c")
    expect_equal(rb:pop(), "d")
    expect_equal(rb:pop(), nil)
  end)
end)

describe("RingBuffer peek / peekNewest", function()
  it("peek on empty returns nil", function()
    local rb = lurek.data.newRingBuffer(4)
    expect_equal(rb:peek(), nil)
  end)

  it("peekNewest on empty returns nil", function()
    local rb = lurek.data.newRingBuffer(4)
    expect_equal(rb:peekNewest(), nil)
  end)

  it("peek returns oldest without removing", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push(1)
    rb:push(2)
    expect_equal(rb:peek(), 1)
    expect_equal(rb:len(), 2) -- unchanged
  end)

  it("peekNewest returns newest", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push(1)
    rb:push(2)
    rb:push(3)
    expect_equal(rb:peekNewest(), 3)
    expect_equal(rb:len(), 3) -- unchanged
  end)
end)

describe("RingBuffer isFull / isEmpty", function()
  it("isFull true when capacity reached", function()
    local rb = lurek.data.newRingBuffer(3)
    rb:push(1); rb:push(2); rb:push(3)
    expect_equal(rb:isFull(), true)
  end)

  it("isEmpty false after one push", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push("x")
    expect_equal(rb:isEmpty(), false)
  end)

  it("isEmpty true after all elements popped", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push("x")
    rb:pop()
    expect_equal(rb:isEmpty(), true)
  end)
end)

describe("RingBuffer clear", function()
  it("clear resets len to 0", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push(1); rb:push(2); rb:push(3)
    rb:clear()
    expect_equal(rb:len(), 0)
    expect_equal(rb:isEmpty(), true)
  end)

  it("pop after clear returns nil", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push("a")
    rb:clear()
    expect_equal(rb:pop(), nil)
  end)
end)

describe("RingBuffer toTable", function()
  it("toTable on empty returns empty table", function()
    local rb = lurek.data.newRingBuffer(4)
    local t = rb:toTable()
    expect_type("table", t)
    expect_equal(#t, 0)
  end)

  it("toTable returns oldest-first", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push("x"); rb:push("y"); rb:push("z")
    local t = rb:toTable()
    expect_equal(#t, 3)
    expect_equal(t[1], "x")
    expect_equal(t[2], "y")
    expect_equal(t[3], "z")
  end)

  it("toTable correct after wrap", function()
    local rb = lurek.data.newRingBuffer(3)
    rb:push(1); rb:push(2); rb:push(3); rb:push(4) -- overwrites 1
    local t = rb:toTable()
    expect_equal(#t, 3)
    expect_equal(t[1], 2)
    expect_equal(t[2], 3)
    expect_equal(t[3], 4)
  end)
end)

describe("RingBuffer mixed value types", function()
  it("stores and retrieves different Lua types", function()
    local rb = lurek.data.newRingBuffer(8)
    rb:push(42)
    rb:push("hello")
    rb:push(true)
    rb:push({key = "value"})
    expect_equal(rb:len(), 4)
    local n = rb:pop()
    expect_equal(n, 42)
    local s = rb:pop()
    expect_equal(s, "hello")
    local b = rb:pop()
    expect_equal(b, true)
    local tbl = rb:pop()
    expect_type("table", tbl)
    ---@cast tbl table
    expect_equal(tbl.key, "value")
  end)
end)

-- DataWriter
describe("lurek.data.newWriter DataWriter", function()
  it("newWriter returns a userdata", function()
    local w = lurek.data.newWriter()
    expect_not_nil(w)
    expect_type("userdata", w)
  end)

  it("fresh writer has len 0", function()
    local w = lurek.data.newWriter()
    expect_equal(0, w:len())
  end)

  it("writeU8 increments len by 1", function()
    local w = lurek.data.newWriter()
    w:writeU8(42)
    expect_equal(1, w:len())
  end)

  it("toBytes returns correct byte value", function()
    local w = lurek.data.newWriter()
    w:writeU8(0x41) -- ASCII 'A'
    local b = w:toBytes()
    expect_type("string", b)
    expect_equal("A", b)
  end)

  it("writeU32LE writes 4 bytes", function()
    local w = lurek.data.newWriter()
    w:writeU32LE(0)
    expect_equal(4, w:len())
  end)

  it("writeString adds 4-byte length prefix plus content", function()
    local w = lurek.data.newWriter()
    w:writeString("hi")
    -- 4 bytes (u32 LE length) + 2 bytes ("hi") = 6
    expect_equal(6, w:len())
  end)

  it("writeString content survives toBytes round-trip", function()
    local w = lurek.data.newWriter()
    w:writeString("AB")
    local b = w:toBytes()
    -- bytes 5-6 should be 'A' and 'B'
    expect_equal(string.byte("A"), string.byte(b, 5))
    expect_equal(string.byte("B"), string.byte(b, 6))
  end)

  it("tell advances after writes", function()
    local w = lurek.data.newWriter()
    expect_equal(0, w:tell())
    w:writeU8(1)
    expect_equal(1, w:tell())
    w:writeU8(2)
    expect_equal(2, w:tell())
  end)

  it("seek repositions the cursor", function()
    local w = lurek.data.newWriter()
    w:writeU8(1)
    w:writeU8(2)
    w:writeU8(3)
    w:seek(1)
    expect_equal(1, w:tell())
  end)

  it("seek past end extends buffer with zeros", function()
    local w = lurek.data.newWriter()
    w:seek(4)
    expect_equal(4, w:len())
  end)

  it("seek + writeU8 overwrites at cursor", function()
    local w = lurek.data.newWriter()
    w:writeU8(0x00)
    w:writeU8(0x00)
    w:seek(0)
    w:writeU8(0xFF)
    local b = w:toBytes()
    expect_equal(2, #b)
    expect_equal(0xFF, string.byte(b, 1))
    expect_equal(0x00, string.byte(b, 2))
  end)

  it("multiple writeU8 calls accumulate in order", function()
    local w = lurek.data.newWriter()
    w:writeU8(10)
    w:writeU8(20)
    w:writeU8(30)
    expect_equal(3, w:len())
    local b = w:toBytes()
    expect_equal(10, string.byte(b, 1))
    expect_equal(20, string.byte(b, 2))
    expect_equal(30, string.byte(b, 3))
  end)
end)

describe("lurek.data crc32 checksum", function()
  it("crc32 is a function", function()
    expect_equal("function", type(lurek.data.crc32))
  end)

  it("crc32 of empty string is known constant", function()
    local v = lurek.data.crc32("")
    -- CRC-32 of empty bytes is 0x00000000 = 0
    expect_equal(0, v)
  end)

  it("crc32 of '123456789' is known constant 0xCBF43926", function()
    local v = lurek.data.crc32("123456789")
    -- 0xCBF43926 = 3421780262
    expect_equal(3421780262, v)
  end)

  it("crc32 is deterministic", function()
    local a = lurek.data.crc32("hello")
    local b = lurek.data.crc32("hello")
    expect_equal(a, b)
  end)

  it("crc32 differs for different inputs", function()
    local a = lurek.data.crc32("hello")
    local b = lurek.data.crc32("world")
    expect_true(a ~= b)
  end)

  it("crc32 returns an integer type", function()
    local v = lurek.data.crc32("test")
    expect_equal("number", type(v))
  end)
end)

-- =========================================================================

describe("RingBuffer:pop and RingBuffer:len ", function()
    it("pop returns the oldest pushed value", function()
        local rb = lurek.data.newRingBuffer(8)
        rb:push(42)
        rb:push(99)
        local v = rb:pop()
        expect_not_nil(v)
        expect_equal(42, v)
    end)

    it("len returns the current item count", function()
        local rb = lurek.data.newRingBuffer(8)
        rb:push(1)
        rb:push(2)
        rb:push(3)
        expect_equal(3, rb:len())
    end)
end)

describe("DataWriter:len ", function()
    it("len returns the number of bytes written", function()
        local w = lurek.data.newWriter()
        w:writeU8(0x41)
        w:writeU8(0x42)
        local n = w:len()
        expect_type("number", n)
        expect_true(n >= 2)
    end)
end)
test_summary()
