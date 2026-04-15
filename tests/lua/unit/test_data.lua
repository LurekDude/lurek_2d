-- tests/lua/unit/test_data.lua
-- BDD tests for the lurek.data module

-- @description Verifies binary packing and unpacking across floats, signed and unsigned integers, strings, endianness, padding, and offset-based reads.
describe("data.pack + data.unpack", function()
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
  -- @description Packs 3.14 as a little-endian f32, unpacks it, and accepts the expected 0.01 floating-point tolerance.
  it("round-trips f32", function()
    local b = lurek.data.pack("<f", 3.14)
    local v = lurek.data.unpack("<f", b)
    expect_near(v, 3.14, 0.01)
  end)

  -- @description Confirms that the maximum unsigned byte value 255 survives a pack/unpack round-trip unchanged.
  it("round-trips u8 max", function()
    local b = lurek.data.pack("B", 255)
    local v = lurek.data.unpack("B", b)
    expect_equal(v, 255)
  end)

  -- @description Confirms that the minimum unsigned byte value 0 survives a pack/unpack round-trip unchanged.
  it("round-trips u8 zero", function()
    local b = lurek.data.pack("B", 0)
    local v = lurek.data.unpack("B", b)
    expect_equal(v, 0)
  end)

  -- @description Confirms that a signed byte preserves the negative value -1 through packing and unpacking.
  it("round-trips i8 negative", function()
    local b = lurek.data.pack("b", -1)
    local v = lurek.data.unpack("b", b)
    expect_equal(v, -1)
  end)

  -- @description Confirms that a little-endian unsigned 16-bit integer round-trips with the exact value 1000.
  it("round-trips u16", function()
    local b = lurek.data.pack("<H", 1000)
    local v = lurek.data.unpack("<H", b)
    expect_equal(v, 1000)
  end)

  -- @description Confirms that a little-endian signed 32-bit integer round-trips with the exact value -123456.
  it("round-trips i32", function()
    local b = lurek.data.pack("<i", -123456)
    local v = lurek.data.unpack("<i", b)
    expect_equal(v, -123456)
  end)

  -- @description Confirms that a little-endian unsigned 32-bit integer round-trips with the exact value 123456.
  it("round-trips u32", function()
    local b = lurek.data.pack("<I", 123456)
    local v = lurek.data.unpack("<I", b)
    expect_equal(v, 123456)
  end)

  -- @description Packs and unpacks a little-endian f64 and checks the result against 1.23456789 within 1e-9 tolerance.
  it("round-trips f64 (double)", function()
    local b = lurek.data.pack("<d", 1.23456789)
    local v = lurek.data.unpack("<d", b)
    expect_near(v, 1.23456789, 1e-9)
  end)

  -- @description Verifies that a length-prefixed string preserves the exact text "hello" after unpacking.
  it("round-trips length-prefixed string", function()
    local b = lurek.data.pack("s", "hello")
    local v = lurek.data.unpack("s", b)
    expect_equal(v, "hello")
  end)

  -- @description Verifies that a null-terminated string preserves the exact text "world" after unpacking.
  it("round-trips null-terminated string", function()
    local b = lurek.data.pack("z", "world")
    local v = lurek.data.unpack("z", b)
    expect_equal(v, "world")
  end)

  -- @description Unpacks two bytes from one buffer and asserts both values plus the returned final byte position of 2.
  it("returns next byte position", function()
    local b = lurek.data.pack("BB", 10, 20)
    local v1, v2, pos = lurek.data.unpack("BB", b)
    expect_equal(v1, 10)
    expect_equal(v2, 20)
    expect_equal(pos, 2)
  end)

  -- @description Verifies that big-endian packing of 0x0102 stores the high byte first and the low byte second.
  it("respects big-endian prefix", function()
    local b = lurek.data.pack(">H", 0x0102)
    expect_equal(string.byte(b, 1), 0x01)
    expect_equal(string.byte(b, 2), 0x02)
  end)

  -- @description Verifies that little-endian packing of 0x0102 stores the low byte first and the high byte second.
  it("respects little-endian prefix", function()
    local b = lurek.data.pack("<H", 0x0102)
    expect_equal(string.byte(b, 1), 0x02)
    expect_equal(string.byte(b, 2), 0x01)
  end)

  -- @description Verifies that the x format inserts a zero padding byte ahead of the packed value 42 and yields a two-byte buffer.
  it("padding byte is zero", function()
    local b = lurek.data.pack("xB", 42)
    expect_equal(string.len(b), 2)
    expect_equal(string.byte(b, 1), 0)
    expect_equal(string.byte(b, 2), 42)
  end)

  -- @description Starts unpacking at byte offset 1 in a two-byte buffer and confirms it returns the second value 22 with final position 2.
  it("unpack with offset skips bytes", function()
    local b = lurek.data.pack("BB", 11, 22)
    local v, pos = lurek.data.unpack("B", b, 1)
    expect_equal(v, 22)
    expect_equal(pos, 2)
  end)
end)

-- @description Verifies fixed packed-size calculations for scalar formats, combined formats, 64-bit values, and explicit padding bytes.
describe("data.getPackedSize", function()
  -- @description Confirms that the unsigned byte format B reports a packed size of exactly 1 byte.
  it("returns 1 for B", function()
    expect_equal(lurek.data.getPackedSize("B"), 1)
  end)

  -- @description Confirms that the float format f reports a packed size of exactly 4 bytes.
  it("returns 4 for f", function()
    expect_equal(lurek.data.getPackedSize("f"), 4)
  end)

  -- @description Confirms that the combined format Bf reports 5 bytes, counting 1 byte for B and 4 bytes for f.
  it("returns 5 for Bf (1 + 4)", function()
    expect_equal(lurek.data.getPackedSize("Bf"), 5)
  end)

  -- @description Confirms that the double format d reports a packed size of exactly 8 bytes.
  it("returns 8 for d (f64)", function()
    expect_equal(lurek.data.getPackedSize("d"), 8)
  end)

  -- @description Confirms that the unsigned 16-bit format H reports a packed size of exactly 2 bytes.
  it("returns 2 for H", function()
    expect_equal(lurek.data.getPackedSize("H"), 2)
  end)

  -- @description Confirms that the unsigned 32-bit format I reports a packed size of exactly 4 bytes.
  it("returns 4 for I", function()
    expect_equal(lurek.data.getPackedSize("I"), 4)
  end)

  -- @description Confirms that the unsigned 64-bit format L reports a packed size of exactly 8 bytes.
  it("returns 8 for L (u64)", function()
    expect_equal(lurek.data.getPackedSize("L"), 8)
  end)

  -- @description Confirms that the size calculator counts the explicit x padding byte along with the following B byte for a total of 2.
  it("counts x padding byte", function()
    expect_equal(lurek.data.getPackedSize("xB"), 2)
  end)
end)

-- @description Verifies that DataView reads packed bytes back as typed values, reports view length correctly, supports subranges, and rejects out-of-bounds access.
describe("data.newDataView", function()
  -- @description Packs the byte 255, creates a DataView over it, and confirms getUInt8(0) reads the same value.
  it("DataView reads u8 written by pack", function()
    local b = lurek.data.pack("B", 255)
    local dv = lurek.data.newDataView(b)
    expect_equal(dv:getUInt8(0), 255)
  end)

  -- @description Creates a view over packed BH data and confirms getSize returns the expected total byte length of 3.
  it("DataView getSize returns correct size", function()
    local b = lurek.data.pack("BH", 1, 2)
    local dv = lurek.data.newDataView(b)
    expect_equal(dv:getSize(), 3)
  end)

  -- @description Packs the unsigned 16-bit value 1000 in little-endian form and confirms getUInt16(0) reads the same value.
  it("DataView reads u16 from little-endian pack", function()
    local b = lurek.data.pack("<H", 1000)
    local dv = lurek.data.newDataView(b)
    expect_equal(dv:getUInt16(0), 1000)
  end)

  -- @description Packs 1.5 as a little-endian f32 and confirms getFloat(0) reads it back within 0.0001 tolerance.
  it("DataView reads f32 (getFloat)", function()
    local b = lurek.data.pack("<f", 1.5)
    local dv = lurek.data.newDataView(b)
    expect_near(dv:getFloat(0), 1.5, 0.0001)
  end)

  -- @description Packs 2.718281828 as a little-endian f64 and confirms getDouble(0) reads it back within 1e-9 tolerance.
  it("DataView reads f64 (getDouble)", function()
    local b = lurek.data.pack("<d", 2.718281828)
    local dv = lurek.data.newDataView(b)
    expect_near(dv:getDouble(0), 2.718281828, 1e-9)
  end)

  -- @description Packs the unsigned 32-bit value 100000 and confirms getUInt32(0) reads the exact same number.
  it("DataView reads u32", function()
    local b = lurek.data.pack("<I", 100000)
    local dv = lurek.data.newDataView(b)
    expect_equal(dv:getUInt32(0), 100000)
  end)

  -- @description Creates a DataView over the H portion of packed BH data and confirms the sub-buffer reads 512 and reports size 2.
  it("DataView with offset reads sub-buffer", function()
    local b = lurek.data.pack("BH", 99, 512)
    local dv = lurek.data.newDataView(b, 1, 2)
    expect_equal(dv:getUInt16(0), 512)
    expect_equal(dv:getSize(), 2)
  end)

  -- @description Confirms that reading a 16-bit value from a one-byte view raises an out-of-bounds error instead of returning data.
  it("DataView out-of-bounds access raises error", function()
    local b = lurek.data.pack("B", 1)
    local dv = lurek.data.newDataView(b)
    expect_error(function() dv:getUInt16(0) end)
  end)
end)

-- â”€â”€ compress / decompress â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies lossless compression and decompression for deflate, gzip, and lz4, including empty input and a size reduction check for repetitive deflate data.
describe("data.compress + data.decompress", function()
  -- @covers lurek.data.compress
  -- @covers lurek.data.decompress
  -- @description Compresses and decompresses a deflate payload and confirms the restored string matches the original exactly.
  it("round-trips deflate", function()
    local original = "Hello, Lurek2D! Deflate compression test."
    local compressed = lurek.data.compress("deflate", original)
    local decompressed = lurek.data.decompress("deflate", compressed)
    expect_equal(decompressed, original)
  end)

  -- @description Compresses 400 repeated A characters with deflate and confirms the compressed byte string is shorter than the source.
  it("deflate actually compresses (smaller output)", function()
    local original = string.rep("AAAA", 100)
    local compressed = lurek.data.compress("deflate", original)
    expect_true(#compressed < #original)
  end)

  -- @description Compresses and decompresses a gzip payload and confirms the restored string matches the original exactly.
  it("round-trips gzip", function()
    local original = "Hello, Lurek2D! Gzip compression test."
    local compressed = lurek.data.compress("gzip", original)
    local decompressed = lurek.data.decompress("gzip", compressed)
    expect_equal(decompressed, original)
  end)

  -- @description Compresses and decompresses an lz4 payload and confirms the restored string matches the original exactly.
  it("round-trips lz4", function()
    local original = "Hello, Lurek2D! LZ4 compression test."
    local compressed = lurek.data.compress("lz4", original)
    local decompressed = lurek.data.decompress("lz4", compressed)
    expect_equal(decompressed, original)
  end)

  -- @description Confirms that compressing and then decompressing an empty string with deflate still yields an empty string.
  it("handles empty data", function()
    local compressed = lurek.data.compress("deflate", "")
    local decompressed = lurek.data.decompress("deflate", compressed)
    expect_equal(decompressed, "")
  end)
end)

-- â”€â”€ encode / decode â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies deterministic base64 and hex encodings, correct decode round-trips, and edge cases for empty and single-byte inputs.
describe("data.encode + data.decode", function()
  -- @covers lurek.data.encode
  -- @covers lurek.data.decode
  -- @description Confirms that base64 encoding "Hello, Lurek2D!" produces the exact expected literal and decodes back to the original string.
  it("round-trips base64", function()
    local original = "Hello, Lurek2D!"
    local encoded = lurek.data.encode("base64", original)
    expect_equal(encoded, "SGVsbG8sIEx1cmVrMkQh")
    local decoded = lurek.data.decode("base64", encoded)
    expect_equal(decoded, original)
  end)

  -- @description Confirms that hex encoding "Hello" produces the exact lowercase hex literal and decodes back to the original string.
  it("round-trips hex", function()
    local original = "Hello"
    local encoded = lurek.data.encode("hex", original)
    expect_equal(encoded, "48656c6c6f")
    local decoded = lurek.data.decode("hex", encoded)
    expect_equal(decoded, original)
  end)

  -- @description Confirms that base64 encoding an empty string returns an empty encoded string rather than padding or errors.
  it("base64 encodes empty string", function()
    local encoded = lurek.data.encode("base64", "")
    expect_equal(encoded, "")
  end)

  -- @description Confirms that hex encoding a single null byte produces the exact two-character string "00".
  it("hex encodes single byte", function()
    local encoded = lurek.data.encode("hex", "\x00")
    expect_equal(encoded, "00")
  end)
end)

-- â”€â”€ hash â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies known digests for md5, sha1, sha256, and sha512, plus determinism for identical input and divergence for different input.
describe("data.hash", function()
  -- @covers lurek.data.hash
  -- @description Confirms that hashing "hello" with md5 matches the known digest 5d41402abc4b2a76b9719d911017c592.
  it("md5 produces known digest", function()
    expect_equal(lurek.data.hash("md5", "hello"), "5d41402abc4b2a76b9719d911017c592")
  end)

  -- @description Confirms that hashing "hello" with sha1 matches the known digest aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d.
  it("sha1 produces known digest", function()
    expect_equal(lurek.data.hash("sha1", "hello"), "aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d")
  end)

  -- @description Confirms that hashing "hello" with sha256 matches the known digest 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824.
  it("sha256 produces known digest", function()
    expect_equal(lurek.data.hash("sha256", "hello"),
      "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
  end)

  -- @description Confirms that hashing "hello" with sha512 matches the full known 128-character digest.
  it("sha512 produces known digest", function()
    expect_equal(lurek.data.hash("sha512", "hello"),
      "9b71d224bd62f3785d96d46ad3ea3d73319bfbc2890caadae2dff72519673ca72323c3d99ba5c11d7c7acc6e14b8c5da0c4663475c2e5c3adef46f73bcdec043")
  end)

  -- @description Confirms that sha256 produces different digests for the different inputs "hello" and "world".
  it("different input produces different hash", function()
    local h1 = lurek.data.hash("sha256", "hello")
    local h2 = lurek.data.hash("sha256", "world")
    expect_not_equal(h1, h2)
  end)

  -- @description Confirms that sha256 is deterministic by hashing "test" twice and expecting identical digests.
  it("same input produces same hash", function()
    local h1 = lurek.data.hash("sha256", "test")
    local h2 = lurek.data.hash("sha256", "test")
    expect_equal(h1, h2)
  end)
end)

-- â”€â”€ newByteData â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies ByteData creation from sizes and strings, byte mutation and retrieval, and cloning behavior.
describe("data.newByteData", function()
  -- @covers lurek.data.newByteData
  -- @description Creates a 10-byte buffer and confirms its size is 10 and its first byte is zero-initialized.
  it("creates zeroed buffer from size", function()
    local bd = lurek.data.newByteData(10)
    expect_equal(bd:getSize(), 10)
    expect_equal(bd:getByte(0), 0)
  end)

  -- @description Creates ByteData from the string "hello" and confirms it reports length 5 and reproduces the same string content.
  it("creates buffer from string", function()
    local bd = lurek.data.newByteData("hello")
    expect_equal(bd:getSize(), 5)
    expect_equal(bd:getString(), "hello")
  end)

  -- @description Writes ASCII bytes 65 and 66 into a four-byte buffer and confirms getByte reads the same values back from indices 0 and 1.
  it("setByte and getByte round-trip", function()
    local bd = lurek.data.newByteData(4)
    bd:setByte(0, 65)
    bd:setByte(1, 66)
    expect_equal(bd:getByte(0), 65)
    expect_equal(bd:getByte(1), 66)
  end)

  -- @description Clones ByteData created from "test" and confirms the clone preserves both the string content and the size of 4 bytes.
  it("clone produces independent copy", function()
    local original = lurek.data.newByteData("test")
    local cloned = original:clone()
    expect_equal(cloned:getString(), "test")
    expect_equal(cloned:getSize(), 4)
  end)
end)

-- â”€â”€ parseToml / encodeToml â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies TOML parsing for scalar values, nested tables, and arrays, TOML encoding of Lua tables, round-trip behavior, and invalid-input errors.
describe("data.parseToml + data.encodeToml", function()
  -- @covers lurek.data.parseToml
  -- @covers lurek.data.encodeToml
  -- @description Parses TOML containing a string, integer, and boolean and confirms the resulting table fields are "hello", 42, and true.
  it("parses basic types", function()
    local t = lurek.data.parseToml('name = "hello"\ncount = 42\nactive = true')
    expect_equal(t.name, "hello")
    expect_equal(t.count, 42)
    expect_equal(t.active, true)
  end)

  -- @description Parses a [window] table and confirms the nested width, height, and title fields are 800, 600, and "Lurek2D".
  it("parses nested table", function()
    local t = lurek.data.parseToml('[window]\nwidth = 800\nheight = 600\ntitle = "Lurek2D"')
    expect_equal(t.window.width, 800)
    expect_equal(t.window.height, 600)
    expect_equal(t.window.title, "Lurek2D")
  end)

  -- @description Parses an integer array and confirms it has length 3 with first and third elements equal to 1 and 3.
  it("parses array", function()
    local t = lurek.data.parseToml('items = [1, 2, 3]')
    expect_equal(#t.items, 3)
    expect_equal(t.items[1], 1)
    expect_equal(t.items[3], 3)
  end)

  -- @description Encodes a basic Lua table to TOML and confirms the result is a string containing both the expected name and count assignments.
  it("encodes basic table to TOML string", function()
    local result = lurek.data.encodeToml({ name = "test", count = 5 })
    expect_type("string", result)
    expect_match(result, 'name = "test"')
    expect_match(result, "count = 5")
  end)

  -- @description Encodes a table with title and debug fields to TOML, parses it back, and confirms both fields survive the round-trip unchanged.
  it("round-trips table through TOML", function()
    local original = { title = "game", debug = true }
    local encoded = lurek.data.encodeToml(original)
    local decoded = lurek.data.parseToml(encoded)
    expect_equal(decoded.title, "game")
    expect_equal(decoded.debug, true)
  end)

  -- @description Confirms that parsing malformed TOML with an unterminated array raises an error instead of returning a partial table.
  it("parseToml errors on invalid TOML", function()
    expect_error(function()
      lurek.data.parseToml("invalid = [")
    end)
  end)
end)

-- â”€â”€ write / read (Binary Pack Format) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies binary write/read helpers for numeric, string, boolean, and endian-sensitive formats, plus exact size calculations for composite schemas.
describe("data.write + data.read (Binary Pack Format)", function()
  -- @covers lurek.data.write
  -- @covers lurek.data.read
  -- @covers lurek.data.size
  -- @description Writes a u32 and f32, reads them back, and confirms the integer is exactly 42 while the float remains within 0.01 of 3.14.
  it("round-trips u32 and f32", function()
    local b = lurek.data.write("u32 f32", 42, 3.14)
    local v1, v2 = lurek.data.read("u32 f32", b)
    expect_equal(v1, 42)
    expect_near(v2, 3.14, 0.01)
  end)

  -- @description Writes the length-prefixed string "hello" and confirms reading the same schema returns exactly "hello".
  it("round-trips str", function()
    local b = lurek.data.write("str", "hello")
    local v = lurek.data.read("str", b)
    expect_equal(v, "hello")
  end)

  -- @description Writes the null-terminated string "world" and confirms reading the cstr schema returns exactly "world".
  it("round-trips cstr (null-terminated)", function()
    local b = lurek.data.write("cstr", "world")
    local v = lurek.data.read("cstr", b)
    expect_equal(v, "world")
  end)

  -- @description Writes two boolean values true and false and confirms they are read back in the same order without coercion.
  it("round-trips bool", function()
    local b = lurek.data.write("bool bool", true, false)
    local v1, v2 = lurek.data.read("bool bool", b)
    expect_equal(v1, true)
    expect_equal(v2, false)
  end)

  -- @description Confirms that data.size reports exact byte totals of 30 for the mixed integer schema and 14 for the float-bool-pad schema.
  it("data.size returns correct byte count", function()
    expect_equal(lurek.data.size("u8 u16 u32 u64 i8 i16 i32 i64"), 30)
    expect_equal(lurek.data.size("f32 f64 bool pad"), 14)
  end)

  -- @description Verifies that writing a big-endian u16 value 0x0102 stores bytes in the order 0x01 then 0x02.
  it("big-endian u16 has correct byte order", function()
    local b = lurek.data.write("be u16", 0x0102)
    expect_equal(string.byte(b, 1), 0x01)
    expect_equal(string.byte(b, 2), 0x02)
  end)

  -- @description Writes the little-endian u16 value 0x0102 and confirms bytes are 0x02 then 0x01.
  it("little-endian u16 has correct byte order", function()
    local b = lurek.data.write("le u16", 0x0102)
    expect_equal(string.byte(b, 1), 0x02)
    expect_equal(string.byte(b, 2), 0x01)
  end)
end)

-- ── ByteData bit operations ──────────────────────────────────────────────────

-- @description Verifies individual bit set/get round-trips, bit clearing, single-byte and cross-byte readBits, and out-of-range error handling.
describe("data.newByteData bit operations", function()
  -- @covers lurek.data.newByteData
  -- @description Creates a 2-byte buffer, sets bit 3 of byte 0, reads it back as true; confirms adjacent bit 2 is still false.
  it("bytedata_setBit_and_getBit_round_trip", function()
    local bd = lurek.data.newByteData(2)
    bd:setBit(0, 3, true)
    expect_true(bd:getBit(0, 3), "bit 3 should be true after setBit")
    expect_false(bd:getBit(0, 2), "bit 2 should remain false")
  end)

  -- @covers lurek.data.newByteData
  -- @description Sets bit 3, then clears it with setBit(false); confirms getBit returns false.
  it("bytedata_setBit_clear_sets_false", function()
    local bd = lurek.data.newByteData(2)
    bd:setBit(0, 3, true)
    bd:setBit(0, 3, false)
    expect_false(bd:getBit(0, 3), "bit should be false after clearing")
  end)

  -- @covers lurek.data.newByteData
  -- @description Writes 0xFF into byte 0; readBits(0, 0, 8) must return 255.
  it("bytedata_readBits_single_byte", function()
    local bd = lurek.data.newByteData(2)
    bd:setByte(0, 0xFF)
    local val = bd:readBits(0, 0, 8)
    expect_equal(val, 255, "reading all 8 bits of 0xFF should give 255")
  end)

  -- @covers lurek.data.newByteData
  -- @description Writes 0xFF into byte 0 and 0x01 into byte 1; readBits(0, 4, 8) reads 4 high bits from byte 0 (0xF) then 4 low bits from byte 1 (0x1) → 0x1F = 31.
  it("bytedata_readBits_spanning_bytes", function()
    local bd = lurek.data.newByteData(2)
    bd:setByte(0, 0xFF)
    bd:setByte(1, 0x01)
    local val = bd:readBits(0, 4, 8)
    expect_equal(val, 31, "spanning read of 0xFF / 0x01 from bit 4 should yield 0x1F = 31")
  end)

  -- @covers lurek.data.newByteData
  -- @description Calls setBit with bit_offset=8 (out of valid 0..7 range); expects an error.
  it("bytedata_setBit_out_of_range_raises_error", function()
    local bd = lurek.data.newByteData(2)
    expect_error(function()
      bd:setBit(0, 8, true)
    end)
  end)
end)

test_summary()
