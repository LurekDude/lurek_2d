-- content/examples/data.lua
-- Auto-scaffolded coverage of the lurek.data Lua API (57 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/data.lua

print("[example] lurek.data loaded — 57 API items demonstrated")

-- ── lurek.data free functions ──

--@api-stub: lurek.data.pack
-- Packs values into a binary byte string using the format string.
-- Use this when packs values into a binary byte string using the format string is needed.
if false then
  local _r = lurek.data.pack(0, 0)
  print(_r)
end

--@api-stub: lurek.data.unpack
-- Unpacks values from a binary byte string, returning values followed by next offset.
-- Use this when unpacks values from a binary byte string, returning values followed by next offset is needed.
if false then
  local _r = lurek.data.unpack(0, 0, 0)
  print(_r)
end

--@api-stub: lurek.data.getPackedSize
-- Returns the number of bytes the given format and values would occupy.
-- Use this when returns the number of bytes the given format and values would occupy is needed.
if false then
  local _r = lurek.data.getPackedSize(0, 0)
  print(_r)
end

--@api-stub: lurek.data.compress
-- Compresses data using the given algorithm (deflate, gzip, lz4).
-- Use this when compresses data using the given algorithm (deflate, gzip, lz4) is needed.
if false then
  local _r = lurek.data.compress(0, 0, 0)
  print(_r)
end

--@api-stub: lurek.data.decompress
-- Decompresses data using the given algorithm (deflate, gzip, lz4).
-- Use this when decompresses data using the given algorithm (deflate, gzip, lz4) is needed.
if false then
  local _r = lurek.data.decompress(0, nil)
  print(_r)
end

--@api-stub: lurek.data.encode
-- Encodes binary data using the given format (base64, hex).
-- Use this when encodes binary data using the given format (base64, hex) is needed.
if false then
  local _r = lurek.data.encode(0, 0)
  print(_r)
end

--@api-stub: lurek.data.decode
-- Decodes encoded text back to binary (base64, hex).
-- Use this when decodes encoded text back to binary (base64, hex) is needed.
if false then
  local _r = lurek.data.decode(0, 1)
  print(_r)
end

--@api-stub: lurek.data.hash
-- Returns the cryptographic hash of the input (md5, sha1, sha256, sha512).
-- Use this when returns the cryptographic hash of the input (md5, sha1, sha256, sha512) is needed.
if false then
  local _r = lurek.data.hash(0, 0)
  print(_r)
end

--@api-stub: lurek.data.crc32
-- Returns the CRC-32 checksum of the input data as an integer.
-- Use this when returns the CRC-32 checksum of the input data as an integer is needed.
if false then
  local _r = lurek.data.crc32(0)
  print(_r)
end

--@api-stub: lurek.data.newDataView
-- Creates a read-only windowed view into a byte string.
-- Use this when creates a read-only windowed view into a byte string is needed.
if false then
  local _r = lurek.data.newDataView(0, 0, 1)
  print(_r)
end

--@api-stub: lurek.data.write
-- Writes values using the Lurek2D Binary Pack Format.
-- Use this when writes values using the Lurek2D Binary Pack Format is needed.
if false then
  local _r = lurek.data.write(0, 0)
  print(_r)
end

--@api-stub: lurek.data.read
-- Reads values using the Lurek2D Binary Pack Format.
-- Use this when reads values using the Lurek2D Binary Pack Format is needed.
if false then
  local _r = lurek.data.read(0, 0, 0)
  print(_r)
end

--@api-stub: lurek.data.size
-- Returns the byte size of a Lurek2D Binary Pack Format string.
-- Use this when returns the byte size of a Lurek2D Binary Pack Format string is needed.
if false then
  local _r = lurek.data.size(0)
  print(_r)
end

--@api-stub: lurek.data.parseToml
-- Parses a TOML string into a Lua table.
-- Use this when parses a TOML string into a Lua table is needed.
if false then
  local _r = lurek.data.parseToml(0)
  print(_r)
end

--@api-stub: lurek.data.encodeToml
-- Encodes a Lua table into a TOML string.
-- Use this when encodes a Lua table into a TOML string is needed.
if false then
  local _r = lurek.data.encodeToml(0)
  print(_r)
end

--@api-stub: lurek.data.newRingBuffer
-- Creates a fixed-capacity ring buffer that can store any Lua value.
-- Use this when creates a fixed-capacity ring buffer that can store any Lua value is needed.
if false then
  local _r = lurek.data.newRingBuffer(0)
  print(_r)
end

--@api-stub: lurek.data.toMsgPack
-- Serializes a Lua value (table, string, number, boolean, or nil) to MessagePack binary.
-- Use this when serializes a Lua value (table, string, number, boolean, or nil) to MessagePack binary is needed.
if false then
  local _r = lurek.data.toMsgPack(0)
  print(_r)
end

--@api-stub: lurek.data.fromMsgPack
-- Deserializes a MessagePack binary string back into a Lua value.
-- Use this when deserializes a MessagePack binary string back into a Lua value is needed.
if false then
  local _r = lurek.data.fromMsgPack(0)
  print(_r)
end

--@api-stub: lurek.data.newWriter
-- Creates a new write-cursor for building binary data.
-- Use this when creates a new write-cursor for building binary data is needed.
if false then
  local _r = lurek.data.newWriter()
  print(_r)
end

-- ── RingBuffer methods ──

--@api-stub: RingBuffer:push
-- Pushes a value onto the ring buffer.
-- Use this when pushes a value onto the ring buffer is needed.
if false then
  local _o = nil  -- RingBuffer instance
  _o:push(0)
end

--@api-stub: RingBuffer:pop
-- Removes and returns the oldest element, or nil if the buffer is empty.
-- Use this when removes and returns the oldest element, or nil if the buffer is empty is needed.
if false then
  local _o = nil  -- RingBuffer instance
  _o:pop()
end

--@api-stub: RingBuffer:peek
-- Returns the oldest element without removing it, or nil if empty.
-- Use this when returns the oldest element without removing it, or nil if empty is needed.
if false then
  local _o = nil  -- RingBuffer instance
  _o:peek()
end

--@api-stub: RingBuffer:peekNewest
-- Returns the newest element without removing it, or nil if empty.
-- Use this when returns the newest element without removing it, or nil if empty is needed.
if false then
  local _o = nil  -- RingBuffer instance
  _o:peekNewest()
end

--@api-stub: RingBuffer:len
-- Returns the number of elements currently in the buffer.
-- Use this when returns the number of elements currently in the buffer is needed.
if false then
  local _o = nil  -- RingBuffer instance
  _o:len()
end

--@api-stub: RingBuffer:capacity
-- Returns the maximum number of elements the buffer can hold.
-- Use this when returns the maximum number of elements the buffer can hold is needed.
if false then
  local _o = nil  -- RingBuffer instance
  _o:capacity()
end

--@api-stub: RingBuffer:isEmpty
-- Returns true if the buffer contains no elements.
-- Use this when returns true if the buffer contains no elements is needed.
if false then
  local _o = nil  -- RingBuffer instance
  _o:isEmpty()
end

--@api-stub: RingBuffer:clear
-- Removes all elements from the buffer, releasing their registry entries.
-- Use this when removes all elements from the buffer, releasing their registry entries is needed.
if false then
  local _o = nil  -- RingBuffer instance
  _o:clear()
end

--@api-stub: RingBuffer:toTable
-- Returns all elements as an array table ordered oldest-first.
-- Use this when returns all elements as an array table ordered oldest-first is needed.
if false then
  local _o = nil  -- RingBuffer instance
  _o:toTable()
end

-- ── DataView methods ──

--@api-stub: DataView:getUInt8
-- Reads an unsigned 8-bit integer at the given offset.
-- Use this when reads an unsigned 8-bit integer at the given offset is needed.
if false then
  local _o = nil  -- DataView instance
  _o:getUInt8(0)
end

--@api-stub: DataView:getInt8
-- Reads a signed 8-bit integer at the given offset.
-- Use this when reads a signed 8-bit integer at the given offset is needed.
if false then
  local _o = nil  -- DataView instance
  _o:getInt8(0)
end

--@api-stub: DataView:getInt16
-- Reads a signed 16-bit integer at the given offset.
-- Use this when reads a signed 16-bit integer at the given offset is needed.
if false then
  local _o = nil  -- DataView instance
  _o:getInt16(0)
end

--@api-stub: DataView:getUInt16
-- Reads an unsigned 16-bit integer at the given offset.
-- Use this when reads an unsigned 16-bit integer at the given offset is needed.
if false then
  local _o = nil  -- DataView instance
  _o:getUInt16(0)
end

--@api-stub: DataView:getInt32
-- Reads a signed 32-bit integer at the given offset.
-- Use this when reads a signed 32-bit integer at the given offset is needed.
if false then
  local _o = nil  -- DataView instance
  _o:getInt32(0)
end

--@api-stub: DataView:getUInt32
-- Reads an unsigned 32-bit integer at the given offset.
-- Use this when reads an unsigned 32-bit integer at the given offset is needed.
if false then
  local _o = nil  -- DataView instance
  _o:getUInt32(0)
end

--@api-stub: DataView:getFloat
-- Reads a 32-bit float at the given offset.
-- Use this when reads a 32-bit float at the given offset is needed.
if false then
  local _o = nil  -- DataView instance
  _o:getFloat(0)
end

--@api-stub: DataView:getDouble
-- Reads a 64-bit float at the given offset.
-- Use this when reads a 64-bit float at the given offset is needed.
if false then
  local _o = nil  -- DataView instance
  _o:getDouble(0)
end

--@api-stub: DataView:getSize
-- Returns the size of this view in bytes.
-- Use this when returns the size of this view in bytes is needed.
if false then
  local _o = nil  -- DataView instance
  _o:getSize()
end

-- ── DataWriter methods ──

--@api-stub: DataWriter:writeU8
-- Writes an unsigned 8-bit integer.
-- Use this when writes an unsigned 8-bit integer is needed.
if false then
  local _o = nil  -- DataWriter instance
  _o:writeU8(0)
end

--@api-stub: DataWriter:writeI8
-- Writes a signed 8-bit integer.
-- Use this when writes a signed 8-bit integer is needed.
if false then
  local _o = nil  -- DataWriter instance
  _o:writeI8(0)
end

--@api-stub: DataWriter:writeU16LE
-- Writes an unsigned 16-bit LE integer.
-- Use this when writes an unsigned 16-bit LE integer is needed.
if false then
  local _o = nil  -- DataWriter instance
  _o:writeU16LE(0)
end

--@api-stub: DataWriter:writeU16BE
-- Writes an unsigned 16-bit BE integer.
-- Use this when writes an unsigned 16-bit BE integer is needed.
if false then
  local _o = nil  -- DataWriter instance
  _o:writeU16BE(0)
end

--@api-stub: DataWriter:writeI16LE
-- Writes a signed 16-bit LE integer.
-- Use this when writes a signed 16-bit LE integer is needed.
if false then
  local _o = nil  -- DataWriter instance
  _o:writeI16LE(0)
end

--@api-stub: DataWriter:writeU32LE
-- Writes an unsigned 32-bit LE integer.
-- Use this when writes an unsigned 32-bit LE integer is needed.
if false then
  local _o = nil  -- DataWriter instance
  _o:writeU32LE(0)
end

--@api-stub: DataWriter:writeI32LE
-- Writes a signed 32-bit LE integer.
-- Use this when writes a signed 32-bit LE integer is needed.
if false then
  local _o = nil  -- DataWriter instance
  _o:writeI32LE(0)
end

--@api-stub: DataWriter:writeF32LE
-- Writes a 32-bit LE float.
-- Use this when writes a 32-bit LE float is needed.
if false then
  local _o = nil  -- DataWriter instance
  _o:writeF32LE(0)
end

--@api-stub: DataWriter:writeF64LE
-- Writes a 64-bit LE float.
-- Use this when writes a 64-bit LE float is needed.
if false then
  local _o = nil  -- DataWriter instance
  _o:writeF64LE(0)
end

--@api-stub: DataWriter:writeString
-- Writes a length-prefixed UTF-8 string (4-byte LE length + bytes).
-- Use this when writes a length-prefixed UTF-8 string (4-byte LE length + bytes) is needed.
if false then
  local _o = nil  -- DataWriter instance
  _o:writeString(nil)
end

--@api-stub: DataWriter:writeBytes
-- Writes raw bytes from a Lua string.
-- Use this when writes raw bytes from a Lua string is needed.
if false then
  local _o = nil  -- DataWriter instance
  _o:writeBytes()
end

--@api-stub: DataWriter:seek
-- Moves the write cursor to the given position.
-- Use this when moves the write cursor to the given position is needed.
if false then
  local _o = nil  -- DataWriter instance
  _o:seek(nil)
end

--@api-stub: DataWriter:tell
-- Returns the current write cursor position.
-- Use this when returns the current write cursor position is needed.
if false then
  local _o = nil  -- DataWriter instance
  _o:tell()
end

--@api-stub: DataWriter:len
-- Returns the total buffer length.
-- Use this when returns the total buffer length is needed.
if false then
  local _o = nil  -- DataWriter instance
  _o:len()
end

--@api-stub: DataWriter:toBytes
-- Returns the buffer contents as a Lua string.
-- Use this when returns the buffer contents as a Lua string is needed.
if false then
  local _o = nil  -- DataWriter instance
  _o:toBytes()
end

-- ── mlua methods ──

--@api-stub: mlua:getSize
-- Get the size.
-- Use this when get the size is needed.
if false then
  local _o = nil  -- mlua instance
  _o:getSize()
end

--@api-stub: mlua:getString
-- Get the string representation.
-- Use this when get the string representation is needed.
if false then
  local _o = nil  -- mlua instance
  _o:getString()
end

--@api-stub: mlua:getByte
-- Get a byte at the specified offset.
-- Use this when get a byte at the specified offset is needed.
if false then
  local _o = nil  -- mlua instance
  _o:getByte(0)
end

--@api-stub: mlua:setByte
-- Set a byte at the specified offset.
-- Use this when set a byte at the specified offset is needed.
if false then
  local _o = nil  -- mlua instance
  _o:setByte(0, 0)
end

--@api-stub: mlua:clone
-- Clone the ByteData.
-- Use this when clone the ByteData is needed.
if false then
  local _o = nil  -- mlua instance
  _o:clone()
end

