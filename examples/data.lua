-- examples/data.lua
-- luna.data — Binary data manipulation: pack/unpack, compress, hash, encode,
-- TOML parsing, ByteData, and DataView.
-- All luna.data API methods demonstrated with code and comments.
-- This file is documentation code, not a runnable game.

-- ── Binary Pack / Unpack ──────────────────────────────────────────────────────
-- Format string characters (same as Python struct):
--   b/B — int8/uint8    h/H — int16/uint16    i/I — int32/uint32    f — float32
--   d — float64    s — null-terminated string    z4 — fixed-width 4-byte string
--   < — little-endian (default)    > — big-endian

-- pack(format, ...) → string (binary bytes)
local bytes = luna.data.pack("<BHi", 255, 1000, -12345)

-- unpack(format, data, offset?) → ..., next_offset
local b8, u16, i32, next_pos = luna.data.unpack("<BHi", bytes)
-- next_pos is the byte position after all read values (useful for streaming)

-- getPackedSize(format, ...) → integer — preview packed byte count without allocating
local sz = luna.data.getPackedSize("<BHi", 255, 1000, -12345)

-- ── Luna2D Binary Format (write / read / size) ────────────────────────────────
-- Luna2D has its own typed binary serialisation layer with named types.
-- Format characters: i8 i16 i32 i64  u8 u16 u32 u64  f32 f64  bool  str  bytes
-- Use spaces to separate multi-type format strings.

-- write(format, ...) → string
local packed = luna.data.write("u8 u16 f32 str", 200, 50000, 3.14, "hello")

-- read(format, data, offset?) → ...
local v1, v2, v3, v4 = luna.data.read("u8 u16 f32 str", packed)

-- size(format) → integer — byte size of a fixed-width format (no str/bytes)
local fixed_size = luna.data.size("u8 u16 f32")  -- 1+2+4 = 7

-- ── Compression ───────────────────────────────────────────────────────────────
-- Formats: "deflate" | "gzip" | "lz4" | "zlib"

local raw_text = "Luna2D is a lightweight Lua game engine built with Rust."
local compressed   = luna.data.compress("lz4", raw_text)
local decompressed = luna.data.decompress("lz4", compressed)
-- decompressed == raw_text

-- compress with explicit level (1 = fastest, 9 = smallest, default 6)
local tight = luna.data.compress("deflate", raw_text, 9)

-- ── Encoding / Decoding ───────────────────────────────────────────────────────
-- Formats: "base64" | "hex"

-- encode(format, data) → string
local b64 = luna.data.encode("base64", raw_text)
local hex = luna.data.encode("hex", "\xDE\xAD\xBE\xEF")

-- decode(format, encoded) → string (binary)
local decoded_b64 = luna.data.decode("base64", b64)
local decoded_hex = luna.data.decode("hex", "DEADBEEF")

-- ── Hashing ───────────────────────────────────────────────────────────────────
-- Algorithms: "md5" | "sha1" | "sha256" | "sha512"

-- hash(algorithm, data) → hex string
local md5    = luna.data.hash("md5",    "Luna2D")  -- 32-char hex
local sha256 = luna.data.hash("sha256", "Luna2D")  -- 64-char hex

-- ── ByteData (mutable byte buffer) ────────────────────────────────────────────

-- newByteData(size | string) → ByteData
local buf = luna.data.newByteData(16)        -- 16 zero bytes
local buf2 = luna.data.newByteData("ABC\0")  -- from a string

-- ByteData methods (standard lua.data.ByteData UserData)
local size = buf:getSize()          -- 16

-- getByte(offset) → integer (0-255)  [offset is 0-based]
local byte0 = buf:getByte(0)

-- setByte(offset, value)
buf:setByte(0, 0xFF)

-- getString() → string  — raw bytes as a Lua string
local str_view = buf:getString()

-- getPointer() — low-level pointer (not typically needed from Lua)

-- ── DataView (read-only windowed view) ────────────────────────────────────────

-- newDataView(data_string, offset?, size?) → DataView
local dv = luna.data.newDataView("\x01\x02\x00\x2A\x40\x48\xF5\xC3", 0, 8)

-- Typed reads (offset is 0-based byte index)
local u8   = dv:getUInt8(0)    -- 1
local i8   = dv:getInt8(0)     -- 1
local u16  = dv:getUInt16(0)   -- 513  (little-endian 01 02)
local i16  = dv:getInt16(0)    -- 513
local u32  = dv:getUInt32(2)   -- 0x0000002A = 42
local i32  = dv:getInt32(2)    -- 42
local f32  = dv:getFloat(4)    -- approximately 3.14
local f64  = dv:getDouble(0)   -- full 64-bit double (all 8 bytes)

local dv_size = dv:getSize()   -- 8

-- ── TOML Parsing / Encoding ───────────────────────────────────────────────────

-- parseToml(string) → table
local config = luna.data.parseToml([[
[window]
title  = "My Game"
width  = 1280
height = 720

[modules]
physics = true
]])

local title = config.window.title   -- "My Game"
local w     = config.window.width   -- 1280

-- encodeToml(table) → string
local toml_out = luna.data.encodeToml({
    game = { name = "Starfall", version = "1.0" },
    player = { speed = 200, health = 100 },
})
