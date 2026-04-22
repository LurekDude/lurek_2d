-- content/examples/data.lua
-- Scaffolded coverage of the lurek.data API (57 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/data_api.rs   (Lua binding, arg types, return shape)
--   * src/data/                 (semantics, side effects)
--   * docs/specs/data.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/data.lua

-- ── lurek.data.* functions ──

--@api-stub: lurek.data.pack
-- Packs values into a binary byte string using the format string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.pack
  local _todo = "TODO: write a real lurek.data.pack usage example"
  print(_todo)
end

--@api-stub: lurek.data.unpack
-- Unpacks values from a binary byte string, returning values followed by next offset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.unpack
  local _todo = "TODO: write a real lurek.data.unpack usage example"
  print(_todo)
end

--@api-stub: lurek.data.getPackedSize
-- Returns the number of bytes the given format and values would occupy.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.getPackedSize
  local _todo = "TODO: write a real lurek.data.getPackedSize usage example"
  print(_todo)
end

--@api-stub: lurek.data.compress
-- Compresses data using the given algorithm (deflate, gzip, lz4).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.compress
  local _todo = "TODO: write a real lurek.data.compress usage example"
  print(_todo)
end

--@api-stub: lurek.data.decompress
-- Decompresses data using the given algorithm (deflate, gzip, lz4).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.decompress
  local _todo = "TODO: write a real lurek.data.decompress usage example"
  print(_todo)
end

--@api-stub: lurek.data.encode
-- Encodes binary data using the given format (base64, hex).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.encode
  local _todo = "TODO: write a real lurek.data.encode usage example"
  print(_todo)
end

--@api-stub: lurek.data.decode
-- Decodes encoded text back to binary (base64, hex).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.decode
  local _todo = "TODO: write a real lurek.data.decode usage example"
  print(_todo)
end

--@api-stub: lurek.data.hash
-- Returns the cryptographic hash of the input (md5, sha1, sha256, sha512).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.hash
  local _todo = "TODO: write a real lurek.data.hash usage example"
  print(_todo)
end

--@api-stub: lurek.data.crc32
-- Returns the CRC-32 checksum of the input data as an integer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.crc32
  local _todo = "TODO: write a real lurek.data.crc32 usage example"
  print(_todo)
end

--@api-stub: lurek.data.newDataView
-- Creates a read-only windowed view into a byte string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.newDataView
  local _todo = "TODO: write a real lurek.data.newDataView usage example"
  print(_todo)
end

--@api-stub: lurek.data.write
-- Writes values using the Lurek2D Binary Pack Format.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.write
  local _todo = "TODO: write a real lurek.data.write usage example"
  print(_todo)
end

--@api-stub: lurek.data.read
-- Reads values using the Lurek2D Binary Pack Format.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.read
  local _todo = "TODO: write a real lurek.data.read usage example"
  print(_todo)
end

--@api-stub: lurek.data.size
-- Returns the byte size of a Lurek2D Binary Pack Format string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.size
  local _todo = "TODO: write a real lurek.data.size usage example"
  print(_todo)
end

--@api-stub: lurek.data.parseToml
-- Parses a TOML string into a Lua table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.parseToml
  local _todo = "TODO: write a real lurek.data.parseToml usage example"
  print(_todo)
end

--@api-stub: lurek.data.encodeToml
-- Encodes a Lua table into a TOML string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.encodeToml
  local _todo = "TODO: write a real lurek.data.encodeToml usage example"
  print(_todo)
end

--@api-stub: lurek.data.newRingBuffer
-- Creates a fixed-capacity ring buffer that can store any Lua value.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.newRingBuffer
  local _todo = "TODO: write a real lurek.data.newRingBuffer usage example"
  print(_todo)
end

--@api-stub: lurek.data.toMsgPack
-- Serializes a Lua value (table, string, number, boolean, or nil) to MessagePack binary.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.toMsgPack
  local _todo = "TODO: write a real lurek.data.toMsgPack usage example"
  print(_todo)
end

--@api-stub: lurek.data.fromMsgPack
-- Deserializes a MessagePack binary string back into a Lua value.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.fromMsgPack
  local _todo = "TODO: write a real lurek.data.fromMsgPack usage example"
  print(_todo)
end

--@api-stub: lurek.data.newWriter
-- Creates a new write-cursor for building binary data.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: lurek.data.newWriter
  local _todo = "TODO: write a real lurek.data.newWriter usage example"
  print(_todo)
end

-- ── RingBuffer methods ──

--@api-stub: RingBuffer:push
-- Pushes a value onto the ring buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: RingBuffer:push
  local _todo = "TODO: write a real RingBuffer:push usage example"
  print(_todo)
end

--@api-stub: RingBuffer:pop
-- Removes and returns the oldest element, or nil if the buffer is empty.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: RingBuffer:pop
  local _todo = "TODO: write a real RingBuffer:pop usage example"
  print(_todo)
end

--@api-stub: RingBuffer:peek
-- Returns the oldest element without removing it, or nil if empty.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: RingBuffer:peek
  local _todo = "TODO: write a real RingBuffer:peek usage example"
  print(_todo)
end

--@api-stub: RingBuffer:peekNewest
-- Returns the newest element without removing it, or nil if empty.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: RingBuffer:peekNewest
  local _todo = "TODO: write a real RingBuffer:peekNewest usage example"
  print(_todo)
end

--@api-stub: RingBuffer:len
-- Returns the number of elements currently in the buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: RingBuffer:len
  local _todo = "TODO: write a real RingBuffer:len usage example"
  print(_todo)
end

--@api-stub: RingBuffer:capacity
-- Returns the maximum number of elements the buffer can hold.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: RingBuffer:capacity
  local _todo = "TODO: write a real RingBuffer:capacity usage example"
  print(_todo)
end

--@api-stub: RingBuffer:isEmpty
-- Returns true if the buffer contains no elements.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: RingBuffer:isEmpty
  local _todo = "TODO: write a real RingBuffer:isEmpty usage example"
  print(_todo)
end

--@api-stub: RingBuffer:clear
-- Removes all elements from the buffer, releasing their registry entries.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: RingBuffer:clear
  local _todo = "TODO: write a real RingBuffer:clear usage example"
  print(_todo)
end

--@api-stub: RingBuffer:toTable
-- Returns all elements as an array table ordered oldest-first.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: RingBuffer:toTable
  local _todo = "TODO: write a real RingBuffer:toTable usage example"
  print(_todo)
end

-- ── DataView methods ──

--@api-stub: DataView:getUInt8
-- Reads an unsigned 8-bit integer at the given offset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataView:getUInt8
  local _todo = "TODO: write a real DataView:getUInt8 usage example"
  print(_todo)
end

--@api-stub: DataView:getInt8
-- Reads a signed 8-bit integer at the given offset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataView:getInt8
  local _todo = "TODO: write a real DataView:getInt8 usage example"
  print(_todo)
end

--@api-stub: DataView:getInt16
-- Reads a signed 16-bit integer at the given offset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataView:getInt16
  local _todo = "TODO: write a real DataView:getInt16 usage example"
  print(_todo)
end

--@api-stub: DataView:getUInt16
-- Reads an unsigned 16-bit integer at the given offset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataView:getUInt16
  local _todo = "TODO: write a real DataView:getUInt16 usage example"
  print(_todo)
end

--@api-stub: DataView:getInt32
-- Reads a signed 32-bit integer at the given offset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataView:getInt32
  local _todo = "TODO: write a real DataView:getInt32 usage example"
  print(_todo)
end

--@api-stub: DataView:getUInt32
-- Reads an unsigned 32-bit integer at the given offset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataView:getUInt32
  local _todo = "TODO: write a real DataView:getUInt32 usage example"
  print(_todo)
end

--@api-stub: DataView:getFloat
-- Reads a 32-bit float at the given offset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataView:getFloat
  local _todo = "TODO: write a real DataView:getFloat usage example"
  print(_todo)
end

--@api-stub: DataView:getDouble
-- Reads a 64-bit float at the given offset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataView:getDouble
  local _todo = "TODO: write a real DataView:getDouble usage example"
  print(_todo)
end

--@api-stub: DataView:getSize
-- Returns the size of this view in bytes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataView:getSize
  local _todo = "TODO: write a real DataView:getSize usage example"
  print(_todo)
end

-- ── DataWriter methods ──

--@api-stub: DataWriter:writeU8
-- Writes an unsigned 8-bit integer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataWriter:writeU8
  local _todo = "TODO: write a real DataWriter:writeU8 usage example"
  print(_todo)
end

--@api-stub: DataWriter:writeI8
-- Writes a signed 8-bit integer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataWriter:writeI8
  local _todo = "TODO: write a real DataWriter:writeI8 usage example"
  print(_todo)
end

--@api-stub: DataWriter:writeU16LE
-- Writes an unsigned 16-bit LE integer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataWriter:writeU16LE
  local _todo = "TODO: write a real DataWriter:writeU16LE usage example"
  print(_todo)
end

--@api-stub: DataWriter:writeU16BE
-- Writes an unsigned 16-bit BE integer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataWriter:writeU16BE
  local _todo = "TODO: write a real DataWriter:writeU16BE usage example"
  print(_todo)
end

--@api-stub: DataWriter:writeI16LE
-- Writes a signed 16-bit LE integer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataWriter:writeI16LE
  local _todo = "TODO: write a real DataWriter:writeI16LE usage example"
  print(_todo)
end

--@api-stub: DataWriter:writeU32LE
-- Writes an unsigned 32-bit LE integer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataWriter:writeU32LE
  local _todo = "TODO: write a real DataWriter:writeU32LE usage example"
  print(_todo)
end

--@api-stub: DataWriter:writeI32LE
-- Writes a signed 32-bit LE integer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataWriter:writeI32LE
  local _todo = "TODO: write a real DataWriter:writeI32LE usage example"
  print(_todo)
end

--@api-stub: DataWriter:writeF32LE
-- Writes a 32-bit LE float.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataWriter:writeF32LE
  local _todo = "TODO: write a real DataWriter:writeF32LE usage example"
  print(_todo)
end

--@api-stub: DataWriter:writeF64LE
-- Writes a 64-bit LE float.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataWriter:writeF64LE
  local _todo = "TODO: write a real DataWriter:writeF64LE usage example"
  print(_todo)
end

--@api-stub: DataWriter:writeString
-- Writes a length-prefixed UTF-8 string (4-byte LE length + bytes).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataWriter:writeString
  local _todo = "TODO: write a real DataWriter:writeString usage example"
  print(_todo)
end

--@api-stub: DataWriter:writeBytes
-- Writes raw bytes from a Lua string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataWriter:writeBytes
  local _todo = "TODO: write a real DataWriter:writeBytes usage example"
  print(_todo)
end

--@api-stub: DataWriter:seek
-- Moves the write cursor to the given position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataWriter:seek
  local _todo = "TODO: write a real DataWriter:seek usage example"
  print(_todo)
end

--@api-stub: DataWriter:tell
-- Returns the current write cursor position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataWriter:tell
  local _todo = "TODO: write a real DataWriter:tell usage example"
  print(_todo)
end

--@api-stub: DataWriter:len
-- Returns the total buffer length.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataWriter:len
  local _todo = "TODO: write a real DataWriter:len usage example"
  print(_todo)
end

--@api-stub: DataWriter:toBytes
-- Returns the buffer contents as a Lua string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: DataWriter:toBytes
  local _todo = "TODO: write a real DataWriter:toBytes usage example"
  print(_todo)
end

-- ── mlua methods ──

--@api-stub: mlua:getSize
-- Get the size.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: mlua:getSize
  local _todo = "TODO: write a real mlua:getSize usage example"
  print(_todo)
end

--@api-stub: mlua:getString
-- Get the string representation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: mlua:getString
  local _todo = "TODO: write a real mlua:getString usage example"
  print(_todo)
end

--@api-stub: mlua:getByte
-- Get a byte at the specified offset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: mlua:getByte
  local _todo = "TODO: write a real mlua:getByte usage example"
  print(_todo)
end

--@api-stub: mlua:setByte
-- Set a byte at the specified offset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: mlua:setByte
  local _todo = "TODO: write a real mlua:setByte usage example"
  print(_todo)
end

--@api-stub: mlua:clone
-- Clone the ByteData.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/data_api.rs and docs/specs/data.md).
do  -- TODO: mlua:clone
  local _todo = "TODO: write a real mlua:clone usage example"
  print(_todo)
end

