-- content/examples/data.lua
-- Lurek2D lurek.data API Reference
-- Run with: cargo run -- content/examples/data
--
Scenario: A save-game system that serializes player state into binary format,
-- compresses it for storage, uses ring buffers for undo history, and parses
-- TOML configuration files for mod settings.

print("=== lurek.data — Binary Data & Serialization ===\n")

-- =============================================================================
-- Pack / Unpack — binary struct encoding
-- =============================================================================

-- Pack player position + health into binary for network or save.
local packed = lurek.data.pack("ffH", 123.5, 456.7, 100)
print("packed size: " .. #packed)

local x, y, hp = lurek.data.unpack("ffH", packed)
print("unpacked: " .. x .. "," .. y .. " hp=" .. hp)

print("format 'ffH' size: " .. lurek.data.getPackedSize("ffH"))

-- =============================================================================
-- Compression
-- =============================================================================

local blob = string.rep("hello world ", 1000)
local compressed = lurek.data.compress(blob)
print("compressed: " .. #blob .. " -> " .. #compressed)

local restored = lurek.data.decompress(compressed)
print("decompressed matches: " .. tostring(restored == blob))

-- =============================================================================
-- Encoding (base64, hex)
-- =============================================================================

local b64 = lurek.data.encode("base64", "save data here")
print("base64: " .. b64)

local decoded = lurek.data.decode("base64", b64)
print("decoded: " .. decoded)

-- =============================================================================
-- Hashing
-- =============================================================================

local checksum = lurek.data.hash("sha256", "player_save_v1")
print("sha256: " .. checksum)

-- =============================================================================
-- MessagePack
-- =============================================================================

local msg = lurek.data.toMsgPack({name = "Hero", level = 10, items = {"sword", "shield"}})
print("msgpack size: " .. #msg)

local obj = lurek.data.fromMsgPack(msg)
print("from msgpack: " .. obj.name .. " level " .. obj.level)

-- =============================================================================
-- TOML Parsing — mod configuration
-- =============================================================================

local cfg = lurek.data.parseToml([[
[mod]
name = "extended_combat"
version = "1.2.0"
enabled = true
]])
print("mod name: " .. cfg.mod.name)

local toml_str = lurek.data.encodeToml({settings = {volume = 0.8, fullscreen = true}})
print("encoded toml:\n" .. toml_str)

-- =============================================================================
-- ByteData — raw byte buffers
-- =============================================================================

local bytes = lurek.data.newByteData(256)

print("byte data size: " .. bytes:getSize())

local str = bytes:getString()

local b = bytes:getByte(0)
print("byte 0: " .. b)

bytes:setByte(0, 42)

local bytes_copy = bytes:clone()

-- =============================================================================
-- DataView — typed access to binary data
-- =============================================================================

local view = lurek.data.newDataView(packed)

print("view size: " .. view:getSize())

print("float at 0: " .. view:getFloat(0))

print("double at 0: " .. view:getDouble(0))

print("u8 at 0: " .. view:getUInt8(0))

print("i8 at 0: " .. view:getInt8(0))

print("i16 at 0: " .. view:getInt16(0))

print("u16 at 0: " .. view:getUInt16(0))

print("i32 at 0: " .. view:getInt32(0))

print("u32 at 0: " .. view:getUInt32(0))

-- =============================================================================
-- File I/O shortcuts
-- =============================================================================

lurek.data.write("save/player.dat", packed)

local loaded = lurek.data.read("save/player.dat")
print("loaded save: " .. #loaded .. " bytes")

print("file size: " .. lurek.data.size("save/player.dat"))

-- =============================================================================
-- RingBuffer — undo/redo history
-- =============================================================================

local undo = lurek.data.newRingBuffer(20)

undo:push({action = "move", x = 100, y = 200})
undo:push({action = "attack", target = "goblin"})
undo:push({action = "move", x = 150, y = 210})

print("undo stack: " .. undo:len())

print("capacity: " .. undo:capacity())

print("empty: " .. tostring(undo:isEmpty()))

print("full: " .. tostring(undo:isFull()))

local oldest = undo:peek()
print("oldest action: " .. oldest.action)

local newest = undo:peekNewest()
print("newest action: " .. newest.action)

local undone = undo:pop()
print("undone: " .. undone.action)

local history = undo:toTable()
print("remaining history: " .. #history)

undo:clear()

-- =============================================================================
-- New in 0.15.0: DataWriter — binary write buffer
-- =============================================================================

local w = lurek.data.newWriter()

-- Write individual fields.
w:writeU8(0x01)
w:writeU32LE(0xDEADBEEF)
w:writeString("hello")
print(string.format("DataWriter len after writes: %d", w:len()))

-- Seek to position 0 and overwrite the first byte.
w:seek(0)
w:writeU8(0xFF)
print(string.format("cursor after seek+write: %d", w:tell()))

-- Export the raw bytes as a Lua string.
local bytes = w:toBytes()
print(string.format("toBytes length: %d, first byte: 0x%02X", #bytes, string.byte(bytes, 1)))

-- =============================================================================
-- New in 0.15.0: lurek.data.crc32
-- =============================================================================

-- CRC-32 is a fast, non-cryptographic checksum — ideal for asset validation.
local checksum = lurek.data.crc32("123456789")
-- ISO/IEC 3309 check value: 0xCBF43926 = 3421780262
print(string.format("crc32('123456789') = 0x%08X (%d)", checksum, checksum))

local ck_hello = lurek.data.crc32("hello")
local ck_world = lurek.data.crc32("world")
print(string.format("crc32('hello')=%d  crc32('world')=%d  equal=%s",
  ck_hello, ck_world, tostring(ck_hello == ck_world)))

print("\n-- data.lua example complete --")

-- =============================================================================
-- Advanced Edge Cases and Extra API Demonstrations
-- =============================================================================

-- -----------------------------------------------------------------------------
-- DataWriter methods
-- -----------------------------------------------------------------------------

-- Writes a signed 8-bit integer.
dataWriter_stub:writeI8(1.0)
-- Writes an unsigned 16-bit LE integer.
dataWriter_stub:writeU16LE(1.0)
-- Writes an unsigned 16-bit BE integer.
dataWriter_stub:writeU16BE(1.0)
-- Writes a signed 16-bit LE integer.
dataWriter_stub:writeI16LE(1.0)
-- Writes a signed 32-bit LE integer.
dataWriter_stub:writeI32LE(1.0)
-- Writes a 32-bit LE float.
dataWriter_stub:writeF32LE(1.0)
-- Writes a 64-bit LE float.
dataWriter_stub:writeF64LE(1.0)
-- Writes raw bytes from a Lua string.
dataWriter_stub:writeBytes()
