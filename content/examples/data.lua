-- content/examples/data.lua
-- Lurek2D lurek.data API Reference
-- Run with: cargo run -- content/examples/data
--
-- Scenario: A save-game system that serializes player state into binary format,
-- compresses it for storage, uses ring buffers for undo history, and parses
-- TOML configuration files for mod settings.

print("=== lurek.data — Binary Data & Serialization ===\n")

-- =============================================================================
-- Pack / Unpack — binary struct encoding
-- =============================================================================

--@api-stub: lurek.data.pack
-- Pack player position + health into binary for network or save.
local packed = lurek.data.pack("ffH", 123.5, 456.7, 100)
print("packed size: " .. #packed)

--@api-stub: lurek.data.unpack
local x, y, hp = lurek.data.unpack("ffH", packed)
print("unpacked: " .. x .. "," .. y .. " hp=" .. hp)

--@api-stub: lurek.data.getPackedSize
print("format 'ffH' size: " .. lurek.data.getPackedSize("ffH"))

-- =============================================================================
-- Compression
-- =============================================================================

--@api-stub: lurek.data.compress
local blob = string.rep("hello world ", 1000)
local compressed = lurek.data.compress(blob)
print("compressed: " .. #blob .. " -> " .. #compressed)

--@api-stub: lurek.data.decompress
local restored = lurek.data.decompress(compressed)
print("decompressed matches: " .. tostring(restored == blob))

-- =============================================================================
-- Encoding (base64, hex)
-- =============================================================================

--@api-stub: lurek.data.encode
local b64 = lurek.data.encode("base64", "save data here")
print("base64: " .. b64)

--@api-stub: lurek.data.decode
local decoded = lurek.data.decode("base64", b64)
print("decoded: " .. decoded)

-- =============================================================================
-- Hashing
-- =============================================================================

--@api-stub: lurek.data.hash
local checksum = lurek.data.hash("sha256", "player_save_v1")
print("sha256: " .. checksum)

-- =============================================================================
-- MessagePack
-- =============================================================================

--@api-stub: lurek.data.toMsgPack
local msg = lurek.data.toMsgPack({name = "Hero", level = 10, items = {"sword", "shield"}})
print("msgpack size: " .. #msg)

--@api-stub: lurek.data.fromMsgPack
local obj = lurek.data.fromMsgPack(msg)
print("from msgpack: " .. obj.name .. " level " .. obj.level)

-- =============================================================================
-- TOML Parsing — mod configuration
-- =============================================================================

--@api-stub: lurek.data.parseToml
local cfg = lurek.data.parseToml([[
[mod]
name = "extended_combat"
version = "1.2.0"
enabled = true
]])
print("mod name: " .. cfg.mod.name)

--@api-stub: lurek.data.encodeToml
local toml_str = lurek.data.encodeToml({settings = {volume = 0.8, fullscreen = true}})
print("encoded toml:\n" .. toml_str)

-- =============================================================================
-- ByteData — raw byte buffers
-- =============================================================================

--@api-stub: lurek.data.newByteData
local bytes = lurek.data.newByteData(256)

--@api-stub: mlua:getSize
print("byte data size: " .. bytes:getSize())

--@api-stub: mlua:getString
local str = bytes:getString()

--@api-stub: mlua:getByte
local b = bytes:getByte(0)
print("byte 0: " .. b)

--@api-stub: mlua:setByte
bytes:setByte(0, 42)

--@api-stub: mlua:clone
local bytes_copy = bytes:clone()

-- =============================================================================
-- DataView — typed access to binary data
-- =============================================================================

--@api-stub: lurek.data.newDataView
local view = lurek.data.newDataView(packed)

--@api-stub: DataView:getSize
print("view size: " .. view:getSize())

--@api-stub: DataView:getFloat
print("float at 0: " .. view:getFloat(0))

--@api-stub: DataView:getDouble
print("double at 0: " .. view:getDouble(0))

--@api-stub: DataView:getUInt8
print("u8 at 0: " .. view:getUInt8(0))

--@api-stub: DataView:getInt8
print("i8 at 0: " .. view:getInt8(0))

--@api-stub: DataView:getInt16
print("i16 at 0: " .. view:getInt16(0))

--@api-stub: DataView:getUInt16
print("u16 at 0: " .. view:getUInt16(0))

--@api-stub: DataView:getInt32
print("i32 at 0: " .. view:getInt32(0))

--@api-stub: DataView:getUInt32
print("u32 at 0: " .. view:getUInt32(0))

-- =============================================================================
-- File I/O shortcuts
-- =============================================================================

--@api-stub: lurek.data.write
lurek.data.write("save/player.dat", packed)

--@api-stub: lurek.data.read
local loaded = lurek.data.read("save/player.dat")
print("loaded save: " .. #loaded .. " bytes")

--@api-stub: lurek.data.size
print("file size: " .. lurek.data.size("save/player.dat"))

-- =============================================================================
-- RingBuffer — undo/redo history
-- =============================================================================

--@api-stub: lurek.data.newRingBuffer
local undo = lurek.data.newRingBuffer(20)

--@api-stub: RingBuffer:push
undo:push({action = "move", x = 100, y = 200})
undo:push({action = "attack", target = "goblin"})
undo:push({action = "move", x = 150, y = 210})

--@api-stub: RingBuffer:len
print("undo stack: " .. undo:len())

--@api-stub: RingBuffer:capacity
print("capacity: " .. undo:capacity())

--@api-stub: RingBuffer:isEmpty
print("empty: " .. tostring(undo:isEmpty()))

--@api-stub: RingBuffer:isFull
print("full: " .. tostring(undo:isFull()))

--@api-stub: RingBuffer:peek
local oldest = undo:peek()
print("oldest action: " .. oldest.action)

--@api-stub: RingBuffer:peekNewest
local newest = undo:peekNewest()
print("newest action: " .. newest.action)

--@api-stub: RingBuffer:pop
local undone = undo:pop()
print("undone: " .. undone.action)

--@api-stub: RingBuffer:toTable
local history = undo:toTable()
print("remaining history: " .. #history)

--@api-stub: RingBuffer:clear
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
-- STUBS: 8 uncovered lurek.data API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- DataWriter methods
-- -----------------------------------------------------------------------------

-- ---- Stub: DataWriter:writeI8 --------------------------------------------
--@api-stub: DataWriter:writeI8
-- Writes a signed 8-bit integer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- dataWriter_stub:writeI8(1.0)
-- (replace dataWriter_stub with your real DataWriter instance above)

-- ---- Stub: DataWriter:writeU16LE -----------------------------------------
--@api-stub: DataWriter:writeU16LE
-- Writes an unsigned 16-bit LE integer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- dataWriter_stub:writeU16LE(1.0)
-- (replace dataWriter_stub with your real DataWriter instance above)

-- ---- Stub: DataWriter:writeU16BE -----------------------------------------
--@api-stub: DataWriter:writeU16BE
-- Writes an unsigned 16-bit BE integer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- dataWriter_stub:writeU16BE(1.0)
-- (replace dataWriter_stub with your real DataWriter instance above)

-- ---- Stub: DataWriter:writeI16LE -----------------------------------------
--@api-stub: DataWriter:writeI16LE
-- Writes a signed 16-bit LE integer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- dataWriter_stub:writeI16LE(1.0)
-- (replace dataWriter_stub with your real DataWriter instance above)

-- ---- Stub: DataWriter:writeI32LE -----------------------------------------
--@api-stub: DataWriter:writeI32LE
-- Writes a signed 32-bit LE integer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- dataWriter_stub:writeI32LE(1.0)
-- (replace dataWriter_stub with your real DataWriter instance above)

-- ---- Stub: DataWriter:writeF32LE -----------------------------------------
--@api-stub: DataWriter:writeF32LE
-- Writes a 32-bit LE float.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- dataWriter_stub:writeF32LE(1.0)
-- (replace dataWriter_stub with your real DataWriter instance above)

-- ---- Stub: DataWriter:writeF64LE -----------------------------------------
--@api-stub: DataWriter:writeF64LE
-- Writes a 64-bit LE float.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- dataWriter_stub:writeF64LE(1.0)
-- (replace dataWriter_stub with your real DataWriter instance above)

-- ---- Stub: DataWriter:writeBytes -----------------------------------------
--@api-stub: DataWriter:writeBytes
-- Writes raw bytes from a Lua string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- dataWriter_stub:writeBytes()
-- (replace dataWriter_stub with your real DataWriter instance above)
