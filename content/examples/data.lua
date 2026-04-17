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

print("\n-- data.lua example complete --")
