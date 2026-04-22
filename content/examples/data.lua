-- content/examples/data.lua
-- Practical usage examples for the lurek.data API (57 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.data.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/data.lua

print("[example] lurek.data — 57 API entries")

-- ── lurek.data.* free functions ──

--@api-stub: lurek.data.pack
-- Packs values into a binary byte string using the format string.
-- Call when you need to invoke pack.
local ok, result = pcall(function() return lurek.data.pack("fmt value", nil) end)
if ok then print("lurek.data.pack ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.data.unpack
-- Unpacks values from a binary byte string, returning values followed by next offset.
-- Call when you need to invoke unpack.
local ok, result = pcall(function() return lurek.data.unpack("fmt value", nil, nil) end)
if ok then print("lurek.data.unpack ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.data.getPackedSize
-- Returns the number of bytes the given format and values would occupy.
-- Call when you need to read packed size.
local ok, value = pcall(function() return lurek.data.getPackedSize("fmt value", nil) end)
local v = ok and value or "(unavailable)"
print("lurek.data.getPackedSize ->", v)

--@api-stub: lurek.data.compress
-- Compresses data using the given algorithm (deflate, gzip, lz4).
-- Call when you need to invoke compress.
local ok, result = pcall(function() return lurek.data.compress("format_str value", {}, nil) end)
if ok then print("lurek.data.compress ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.data.decompress
-- Decompresses data using the given algorithm (deflate, gzip, lz4).
-- Call when you need to invoke decompress.
local ok, result = pcall(function() return lurek.data.decompress("format_str value", nil) end)
if ok then print("lurek.data.decompress ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.data.encode
-- Encodes binary data using the given format (base64, hex).
-- Call when you need to invoke encode.
local ok, result = pcall(function() return lurek.data.encode("format_str value", {}) end)
if ok then print("lurek.data.encode ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.data.decode
-- Decodes encoded text back to binary (base64, hex).
-- Call when you need to invoke decode.
local ok, result = pcall(function() return lurek.data.decode("format_str value", nil) end)
if ok then print("lurek.data.decode ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.data.hash
-- Returns the cryptographic hash of the input (md5, sha1, sha256, sha512).
-- Call when you need to invoke hash.
local ok, result = pcall(function() return lurek.data.hash("algo_str value", {}) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.data.hash ok=", ok)

--@api-stub: lurek.data.crc32
-- Returns the CRC-32 checksum of the input data as an integer.
-- Call when you need to invoke crc32.
local ok, result = pcall(function() return lurek.data.crc32({}) end)
if ok then print("lurek.data.crc32 ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.data.newDataView
-- Creates a read-only windowed view into a byte string.
-- Call when you need to create a new data view.
local ok, obj = pcall(function() return lurek.data.newDataView(nil, nil, 10) end)
if ok and obj then print("created:", obj) end
print("lurek.data.newDataView ok=", ok)

--@api-stub: lurek.data.write
-- Writes values using the Lurek2D Binary Pack Format.
-- Call when you need to invoke write.
local ok, result = pcall(function() return lurek.data.write("fmt value", nil) end)
if ok then print("lurek.data.write ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.data.read
-- Reads values using the Lurek2D Binary Pack Format.
-- Call when you need to invoke read.
local ok, value = pcall(function() return lurek.data.read("fmt value", nil, nil) end)
local v = ok and value or "(unavailable)"
print("lurek.data.read ->", v)

--@api-stub: lurek.data.size
-- Returns the byte size of a Lurek2D Binary Pack Format string.
-- Call when you need to invoke size.
local ok, result = pcall(function() return lurek.data.size("fmt value") end)
if ok then print("lurek.data.size ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.data.parseToml
-- Parses a TOML string into a Lua table.
-- Call when you need to invoke parse toml.
local ok, result = pcall(function() return lurek.data.parseToml("text value") end)
if ok then print("lurek.data.parseToml ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.data.encodeToml
-- Encodes a Lua table into a TOML string.
-- Call when you need to invoke encode toml.
local ok, result = pcall(function() return lurek.data.encodeToml(nil) end)
if ok then print("lurek.data.encodeToml ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.data.newRingBuffer
-- Creates a fixed-capacity ring buffer that can store any Lua value.
-- Call when you need to create a new ring buffer.
local ok, obj = pcall(function() return lurek.data.newRingBuffer(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.data.newRingBuffer ok=", ok)

--@api-stub: lurek.data.toMsgPack
-- Serializes a Lua value (table, string, number, boolean, or nil) to MessagePack binary.
-- Call when you need to invoke to msg pack.
local ok, result = pcall(function() return lurek.data.toMsgPack(nil) end)
if ok then print("lurek.data.toMsgPack ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.data.fromMsgPack
-- Deserializes a MessagePack binary string back into a Lua value.
-- Call when you need to invoke from msg pack.
local ok, obj = pcall(function() return lurek.data.fromMsgPack(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.data.fromMsgPack ok=", ok)

--@api-stub: lurek.data.newWriter
-- Creates a new write-cursor for building binary data.
-- Call when you need to create a new writer.
local ok, obj = pcall(function() return lurek.data.newWriter() end)
if ok and obj then print("created:", obj) end
print("lurek.data.newWriter ok=", ok)

-- ── RingBuffer methods ──

--@api-stub: RingBuffer:push
-- Pushes a value onto the ring buffer.
-- Call when you need to invoke push.
-- Build a RingBuffer via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newRingBuffer(...)
if instance then
  local ok, result = pcall(function() return instance:push(nil) end)
  print("RingBuffer:push ->", ok, result)
end

--@api-stub: RingBuffer:pop
-- Removes and returns the oldest element, or nil if the buffer is empty.
-- Call when you need to invoke pop.
-- Build a RingBuffer via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newRingBuffer(...)
if instance then
  local ok, result = pcall(function() return instance:pop() end)
  print("RingBuffer:pop ->", ok, result)
end

--@api-stub: RingBuffer:peek
-- Returns the oldest element without removing it, or nil if empty.
-- Call when you need to invoke peek.
-- Build a RingBuffer via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newRingBuffer(...)
if instance then
  local ok, result = pcall(function() return instance:peek() end)
  print("RingBuffer:peek ->", ok, result)
end

--@api-stub: RingBuffer:peekNewest
-- Returns the newest element without removing it, or nil if empty.
-- Call when you need to invoke peek newest.
-- Build a RingBuffer via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newRingBuffer(...)
if instance then
  local ok, result = pcall(function() return instance:peekNewest() end)
  print("RingBuffer:peekNewest ->", ok, result)
end

--@api-stub: RingBuffer:len
-- Returns the number of elements currently in the buffer.
-- Call when you need to invoke len.
-- Build a RingBuffer via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newRingBuffer(...)
if instance then
  local ok, result = pcall(function() return instance:len() end)
  print("RingBuffer:len ->", ok, result)
end

--@api-stub: RingBuffer:capacity
-- Returns the maximum number of elements the buffer can hold.
-- Call when you need to invoke capacity.
-- Build a RingBuffer via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newRingBuffer(...)
if instance then
  local ok, result = pcall(function() return instance:capacity() end)
  print("RingBuffer:capacity ->", ok, result)
end

--@api-stub: RingBuffer:isEmpty
-- Returns true if the buffer contains no elements.
-- Call when you need to check is empty.
-- Build a RingBuffer via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newRingBuffer(...)
if instance then
  local ok, result = pcall(function() return instance:isEmpty() end)
  print("RingBuffer:isEmpty ->", ok, result)
end

--@api-stub: RingBuffer:clear
-- Removes all elements from the buffer, releasing their registry entries.
-- Call when you need to invoke clear.
-- Build a RingBuffer via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newRingBuffer(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("RingBuffer:clear ->", ok, result)
end

--@api-stub: RingBuffer:toTable
-- Returns all elements as an array table ordered oldest-first.
-- Call when you need to invoke to table.
-- Build a RingBuffer via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newRingBuffer(...)
if instance then
  local ok, result = pcall(function() return instance:toTable() end)
  print("RingBuffer:toTable ->", ok, result)
end

-- ── DataView methods ──

--@api-stub: DataView:getUInt8
-- Reads an unsigned 8-bit integer at the given offset.
-- Call when you need to read u int8.
-- Build a DataView via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataView(...)
if instance then
  local ok, result = pcall(function() return instance:getUInt8(nil) end)
  print("DataView:getUInt8 ->", ok, result)
end

--@api-stub: DataView:getInt8
-- Reads a signed 8-bit integer at the given offset.
-- Call when you need to read int8.
-- Build a DataView via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataView(...)
if instance then
  local ok, result = pcall(function() return instance:getInt8(nil) end)
  print("DataView:getInt8 ->", ok, result)
end

--@api-stub: DataView:getInt16
-- Reads a signed 16-bit integer at the given offset.
-- Call when you need to read int16.
-- Build a DataView via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataView(...)
if instance then
  local ok, result = pcall(function() return instance:getInt16(nil) end)
  print("DataView:getInt16 ->", ok, result)
end

--@api-stub: DataView:getUInt16
-- Reads an unsigned 16-bit integer at the given offset.
-- Call when you need to read u int16.
-- Build a DataView via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataView(...)
if instance then
  local ok, result = pcall(function() return instance:getUInt16(nil) end)
  print("DataView:getUInt16 ->", ok, result)
end

--@api-stub: DataView:getInt32
-- Reads a signed 32-bit integer at the given offset.
-- Call when you need to read int32.
-- Build a DataView via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataView(...)
if instance then
  local ok, result = pcall(function() return instance:getInt32(nil) end)
  print("DataView:getInt32 ->", ok, result)
end

--@api-stub: DataView:getUInt32
-- Reads an unsigned 32-bit integer at the given offset.
-- Call when you need to read u int32.
-- Build a DataView via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataView(...)
if instance then
  local ok, result = pcall(function() return instance:getUInt32(nil) end)
  print("DataView:getUInt32 ->", ok, result)
end

--@api-stub: DataView:getFloat
-- Reads a 32-bit float at the given offset.
-- Call when you need to read float.
-- Build a DataView via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataView(...)
if instance then
  local ok, result = pcall(function() return instance:getFloat(nil) end)
  print("DataView:getFloat ->", ok, result)
end

--@api-stub: DataView:getDouble
-- Reads a 64-bit float at the given offset.
-- Call when you need to read double.
-- Build a DataView via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataView(...)
if instance then
  local ok, result = pcall(function() return instance:getDouble(nil) end)
  print("DataView:getDouble ->", ok, result)
end

--@api-stub: DataView:getSize
-- Returns the size of this view in bytes.
-- Call when you need to read size.
-- Build a DataView via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataView(...)
if instance then
  local ok, result = pcall(function() return instance:getSize() end)
  print("DataView:getSize ->", ok, result)
end

-- ── DataWriter methods ──

--@api-stub: DataWriter:writeU8
-- Writes an unsigned 8-bit integer.
-- Call when you need to invoke write u8.
-- Build a DataWriter via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataWriter(...)
if instance then
  local ok, result = pcall(function() return instance:writeU8(nil) end)
  print("DataWriter:writeU8 ->", ok, result)
end

--@api-stub: DataWriter:writeI8
-- Writes a signed 8-bit integer.
-- Call when you need to invoke write i8.
-- Build a DataWriter via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataWriter(...)
if instance then
  local ok, result = pcall(function() return instance:writeI8(nil) end)
  print("DataWriter:writeI8 ->", ok, result)
end

--@api-stub: DataWriter:writeU16LE
-- Writes an unsigned 16-bit LE integer.
-- Call when you need to invoke write u16 l e.
-- Build a DataWriter via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataWriter(...)
if instance then
  local ok, result = pcall(function() return instance:writeU16LE(nil) end)
  print("DataWriter:writeU16LE ->", ok, result)
end

--@api-stub: DataWriter:writeU16BE
-- Writes an unsigned 16-bit BE integer.
-- Call when you need to invoke write u16 b e.
-- Build a DataWriter via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataWriter(...)
if instance then
  local ok, result = pcall(function() return instance:writeU16BE(nil) end)
  print("DataWriter:writeU16BE ->", ok, result)
end

--@api-stub: DataWriter:writeI16LE
-- Writes a signed 16-bit LE integer.
-- Call when you need to invoke write i16 l e.
-- Build a DataWriter via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataWriter(...)
if instance then
  local ok, result = pcall(function() return instance:writeI16LE(nil) end)
  print("DataWriter:writeI16LE ->", ok, result)
end

--@api-stub: DataWriter:writeU32LE
-- Writes an unsigned 32-bit LE integer.
-- Call when you need to invoke write u32 l e.
-- Build a DataWriter via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataWriter(...)
if instance then
  local ok, result = pcall(function() return instance:writeU32LE(nil) end)
  print("DataWriter:writeU32LE ->", ok, result)
end

--@api-stub: DataWriter:writeI32LE
-- Writes a signed 32-bit LE integer.
-- Call when you need to invoke write i32 l e.
-- Build a DataWriter via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataWriter(...)
if instance then
  local ok, result = pcall(function() return instance:writeI32LE(nil) end)
  print("DataWriter:writeI32LE ->", ok, result)
end

--@api-stub: DataWriter:writeF32LE
-- Writes a 32-bit LE float.
-- Call when you need to invoke write f32 l e.
-- Build a DataWriter via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataWriter(...)
if instance then
  local ok, result = pcall(function() return instance:writeF32LE(nil) end)
  print("DataWriter:writeF32LE ->", ok, result)
end

--@api-stub: DataWriter:writeF64LE
-- Writes a 64-bit LE float.
-- Call when you need to invoke write f64 l e.
-- Build a DataWriter via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataWriter(...)
if instance then
  local ok, result = pcall(function() return instance:writeF64LE(nil) end)
  print("DataWriter:writeF64LE ->", ok, result)
end

--@api-stub: DataWriter:writeString
-- Writes a length-prefixed UTF-8 string (4-byte LE length + bytes).
-- Call when you need to invoke write string.
-- Build a DataWriter via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataWriter(...)
if instance then
  local ok, result = pcall(function() return instance:writeString(nil) end)
  print("DataWriter:writeString ->", ok, result)
end

--@api-stub: DataWriter:writeBytes
-- Writes raw bytes from a Lua string.
-- Call when you need to invoke write bytes.
-- Build a DataWriter via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataWriter(...)
if instance then
  local ok, result = pcall(function() return instance:writeBytes() end)
  print("DataWriter:writeBytes ->", ok, result)
end

--@api-stub: DataWriter:seek
-- Moves the write cursor to the given position.
-- Call when you need to invoke seek.
-- Build a DataWriter via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataWriter(...)
if instance then
  local ok, result = pcall(function() return instance:seek(nil) end)
  print("DataWriter:seek ->", ok, result)
end

--@api-stub: DataWriter:tell
-- Returns the current write cursor position.
-- Call when you need to invoke tell.
-- Build a DataWriter via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataWriter(...)
if instance then
  local ok, result = pcall(function() return instance:tell() end)
  print("DataWriter:tell ->", ok, result)
end

--@api-stub: DataWriter:len
-- Returns the total buffer length.
-- Call when you need to invoke len.
-- Build a DataWriter via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataWriter(...)
if instance then
  local ok, result = pcall(function() return instance:len() end)
  print("DataWriter:len ->", ok, result)
end

--@api-stub: DataWriter:toBytes
-- Returns the buffer contents as a Lua string.
-- Call when you need to invoke to bytes.
-- Build a DataWriter via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newDataWriter(...)
if instance then
  local ok, result = pcall(function() return instance:toBytes() end)
  print("DataWriter:toBytes ->", ok, result)
end

-- ── mlua methods ──

--@api-stub: mlua:getSize
-- Get the size.
-- Call when you need to read size.
-- Build a mlua via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:getSize() end)
  print("mlua:getSize ->", ok, result)
end

--@api-stub: mlua:getString
-- Get the string representation.
-- Call when you need to read string.
-- Build a mlua via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:getString() end)
  print("mlua:getString ->", ok, result)
end

--@api-stub: mlua:getByte
-- Get a byte at the specified offset.
-- Call when you need to read byte.
-- Build a mlua via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:getByte(nil) end)
  print("mlua:getByte ->", ok, result)
end

--@api-stub: mlua:setByte
-- Set a byte at the specified offset.
-- Call when you need to assign byte.
-- Build a mlua via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:setByte(nil, nil) end)
  print("mlua:setByte ->", ok, result)
end

--@api-stub: mlua:clone
-- Clone the ByteData.
-- Call when you need to invoke clone.
-- Build a mlua via the appropriate lurek.data.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.data.newmlua(...)
if instance then
  local ok, result = pcall(function() return instance:clone() end)
  print("mlua:clone ->", ok, result)
end

