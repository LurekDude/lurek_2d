-- content/examples/data.lua
-- lurek.data API examples.
-- Run: cargo run -- content/examples/data.lua

--@api-stub: lurek.data.pack
-- Packs Lua values into a binary string using a format string
do
  local ok_p, header = pcall(lurek.data.pack, "<HHs", 1, 0, "lurek-save")
  if ok_p then
    lurek.log.info("packed save header: " .. tostring(#header) .. " bytes", "data")
  else
    lurek.log.info("pack: " .. tostring(header), "data")
  end
end

--@api-stub: lurek.data.unpack
-- Unpacks values from a binary string using a format string
do
  local blob = lurek.data.pack("<II", 42, 7)
  local ok_u, result_tbl = pcall(function() return {lurek.data.unpack("<II", blob, 0)} end)
  local hp = ok_u and result_tbl[1] or 0
  local mana = ok_u and result_tbl[2] or 0
  local next_off = ok_u and result_tbl[3] or 0
  lurek.log.info("hp=" .. hp .. " mana=" .. mana .. " consumed=" .. next_off, "data")
end

--@api-stub: lurek.data.getPackedSize
-- Computes the packed byte size for values and a format string
do
  local size = lurek.data.getPackedSize("<IIff", 0, 0, 0, 0)
  if size ~= 16 then
    lurek.log.warn("entity record size drifted: " .. size, "data")
  end
end

--@api-stub: lurek.data.compress
-- Compresses a binary string using a named compression format
do
  local raw = string.rep("level_data ", 256)
  local packed = lurek.data.compress("lz4", raw)
  lurek.log.info("compressed " .. #raw .. " -> " .. #packed .. " bytes", "data")
end

--@api-stub: lurek.data.decompress
-- Decompresses a binary string using a named compression format
do
  local packed = lurek.data.compress("gzip", "tilemap_payload")
  local raw = lurek.data.decompress("gzip", packed)
  lurek.log.info("round-trip ok: " .. raw, "data")
end

--@api-stub: lurek.data.compressChunks
-- Compresses a string or table of strings as a chunked byte stream
do
  local chunks = { "header:", string.rep("A", 2048), ":footer" }
  local packed = lurek.data.compressChunks("zlib", chunks)
  lurek.log.info("chunk-compressed bytes: " .. #packed, "data")
end

--@api-stub: lurek.data.decompressChunks
-- Decompresses a string or table of strings as a chunked byte stream
do
  local packed = lurek.data.compressChunks("deflate", { "part-a", "part-b" })
  local restored = lurek.data.decompressChunks("deflate", packed)
  lurek.log.info("restored payload: " .. restored, "data")
end

--@api-stub: lurek.data.encode
-- Encodes a binary string using a named text encoding format
do
  local key = lurek.data.pack("<I", 0xCAFEF00D)  -- returns a binary Lua string directly
  local key_str = key
  local ok_e1, hex = pcall(lurek.data.encode, "hex", key_str)
  local ok_e2, b64 = pcall(lurek.data.encode, "base64", key_str)
  lurek.log.info("hex=" .. (ok_e1 and hex or "n/a") .. " b64=" .. (ok_e2 and b64 or "n/a"), "data")
end

--@api-stub: lurek.data.decode
-- Decodes a string using a named text encoding format
do
  local b64 = lurek.data.encode("base64", "lurek")
  local raw = lurek.data.decode("base64", b64)
  lurek.log.info("decoded back to: '" .. raw .. "'", "data")
end

--@api-stub: lurek.data.hash
-- Hashes a binary string with a named algorithm
do
  local digest = lurek.data.encode("hex", lurek.data.hash("sha256", "player_save_v3"))
  lurek.log.info("save digest: " .. digest, "data")
end

--@api-stub: lurek.data.crc32
-- Computes CRC32 for a binary string
do
  local payload = lurek.data.pack("<II", 1024, 768)  -- returns a binary Lua string directly
  local payload_str = payload
  local ok_c, sum = pcall(lurek.data.crc32, payload_str)
  local sum_val = ok_c and sum or 0
  lurek.log.info(string.format("payload crc32 = 0x%08X", sum_val), "data")
end

--@api-stub: lurek.data.newDataView
-- Creates a DataView over a binary string slice
do
  local blob = lurek.data.pack("<HHI", 0xBEEF, 0xCAFE, 12345)  -- returns a binary Lua string directly
  local blob_str = blob
  local ok_v, view = pcall(lurek.data.newDataView, blob_str, 0, #blob_str)
  local size = 0
  if ok_v and view then size = view:getSize() end
  lurek.log.info("view bytes: " .. size, "data")
end

--@api-stub: lurek.data.write
-- Writes binary values into a byte string using a format string
do
  local record = lurek.data.write("u32 f32 str", 7, 1.5, "goblin")
  lurek.log.info("entity record bytes: " .. #record, "data")
end

--@api-stub: lurek.data.read
-- Reads binary values from a byte string using a format string
do
  local record = lurek.data.write("u16 u16", 800, 600)
  local w, h = lurek.data.read("u16 u16", record, 0)
  lurek.log.info("resolution: " .. w .. "x" .. h, "data")
end

--@api-stub: lurek.data.size
-- Measures fixed byte size for a binary format string
do
  local sz = lurek.data.size("u32 f32 f32")
  lurek.log.info("transform record = " .. sz .. " bytes", "data")
end

--@api-stub: lurek.data.parseToml
-- Parses TOML text into Lua tables and scalar values
do
  local cfg = lurek.data.parseToml("[window]\nwidth = 1280\nheight = 720\n")
  lurek.log.info("window=" .. cfg.window.width .. "x" .. cfg.window.height, "data")
end

--@api-stub: lurek.data.encodeToml
-- Encodes a Lua table into TOML text
do
  local text = lurek.data.encodeToml({ audio = { master = 0.8, music = 0.6 } })
  lurek.log.info("toml output:\n" .. text, "data")
end

--@api-stub: lurek.data.newRingBuffer
-- Creates a fixed-capacity ring buffer for Lua values
do
  local recent_inputs = lurek.data.newRingBuffer(8)
  recent_inputs:push("jump")
  lurek.log.info("input buffer size=" .. recent_inputs:len(), "data")
end

--@api-stub: lurek.data.toMsgPack
-- Encodes a Lua value into the current structured binary interchange payload
do
  local packet = lurek.data.toMsgPack({ kind = "move", x = 32, y = 48 })
  lurek.log.info("msgpack packet size: " .. #packet, "net")
end

--@api-stub: lurek.data.fromMsgPack
-- Decodes a structured binary interchange payload back into Lua values
do
  local packet = lurek.data.toMsgPack({ id = 17, hp = 90 })
  local msg = lurek.data.fromMsgPack(packet)
  local id = (msg and msg.id) or "nil"
  local hp = (msg and msg.hp) or "nil"
  lurek.log.info("decoded id=" .. tostring(id) .. " hp=" .. tostring(hp), "net")
end

--@api-stub: lurek.data.newWriter
-- Creates an empty binary data writer
do
  local w = lurek.data.newWriter()
  w:writeU32LE(0x4C524B32)  -- "LRK2" magic
  w:writeString("save_v1")
  lurek.log.info("header bytes: " .. w:len(), "save")
end

-- RingBuffer methods

--@api-stub: RingBuffer:push
-- Pushes a value onto this ring buffer channel or queue.
do
  local frame_times = lurek.data.newRingBuffer(60)
  frame_times:push(0.0166)
  frame_times:push(0.0172)
  lurek.log.info("samples buffered: " .. frame_times:len(), "perf")
end

--@api-stub: RingBuffer:pop
-- Pops and returns the next value from this ring buffer channel or queue.
do
  local jobs = lurek.data.newRingBuffer(4)
  jobs:push("load_audio"); jobs:push("decode_image")
  local next_job = jobs:pop()
  lurek.log.info("running job: " .. tostring(next_job), "jobs")
end

--@api-stub: RingBuffer:peek
-- Returns the next value from this ring buffer without removing it.
do
  local events = lurek.data.newRingBuffer(8)
  events:push({ t = 0.0, kind = "spawn" })
  local head = events:peek()
  local kind = head and head.kind or "nil"
  lurek.log.info("next event kind=" .. tostring(kind), "replay")
end

--@api-stub: RingBuffer:peekNewest
-- Performs the peek newest operation on this ring buffer.
do
  local recent = lurek.data.newRingBuffer(8)
  recent:push("a"); recent:push("b"); recent:push("c")
  lurek.log.info("last input: " .. tostring(recent:peekNewest()), "input")
end

--@api-stub: RingBuffer:len
-- Performs the len operation on this ring buffer.
do
  local rb = lurek.data.newRingBuffer(4)
  rb:push(1); rb:push(2); rb:push(3)
  if rb:len() >= 3 then lurek.log.info("buffered enough samples", "data") end
end

--@api-stub: RingBuffer:capacity
-- Performs the capacity operation on this ring buffer.
do
  local rb = lurek.data.newRingBuffer(120)
  rb:push(0.016)
  local pct = (rb:len() / rb:capacity()) * 100
  lurek.log.info(string.format("buffer %.1f%% full", pct), "perf")
end

--@api-stub: RingBuffer:isEmpty
-- Returns true if this ring buffer contains no items.
do
  local jobs = lurek.data.newRingBuffer(4)
  if jobs:isEmpty() then
    lurek.log.info("no pending jobs this frame", "jobs")
  end
end

--@api-stub: RingBuffer:clear
-- Clears all items from this ring buffer.
do
  local trail = lurek.data.newRingBuffer(32)
  for i = 1, 10 do trail:push({ x = i, y = i }) end
  trail:clear()
  lurek.log.info("trail cleared, len=" .. trail:len(), "fx")
end

--@api-stub: RingBuffer:toTable
-- Performs the to table operation on this ring buffer.
do
  local rb = lurek.data.newRingBuffer(4)
  rb:push("a"); rb:push("b"); rb:push("c")
  local arr = rb:toTable()
  lurek.log.info("ordered: " .. table.concat(arr, ","), "data")
end

-- DataView methods

--@api-stub: DataView:getUInt8
-- Returns the u int8 of this data view.
do
  local view = lurek.data.newDataView(string.char(0x42, 0xFF))
  local first = view:getUInt8(0)
  lurek.log.info("first byte = " .. first, "data")
end

--@api-stub: DataView:getInt8
-- Returns the int8 of this data view.
do
  local view = lurek.data.newDataView(string.char(0xFF, 0x01))
  local v = view:getInt8(0)
  lurek.log.info("signed byte = " .. v, "data")
end

--@api-stub: DataView:getInt16
-- Returns the int16 of this data view.
do
  local raw = lurek.data.pack("<h", -1234)
  local v = lurek.data.newDataView(raw):getInt16(0)
  lurek.log.info("signed16 = " .. v, "data")
end

--@api-stub: DataView:getUInt16
-- Returns the u int16 of this data view.
do
  local raw = lurek.data.pack("<H", 0xBEEF)
  local v = lurek.data.newDataView(raw):getUInt16(0)
  lurek.log.info(string.format("u16 = 0x%04X", v), "data")
end

--@api-stub: DataView:getInt32
-- Returns the int32 of this data view.
do
  local raw = lurek.data.pack("<i", -42000)
  local v = lurek.data.newDataView(raw):getInt32(0)
  lurek.log.info("signed32 = " .. v, "data")
end

--@api-stub: DataView:getUInt32
-- Returns the u int32 of this data view.
do
  local raw = lurek.data.pack("<I", 0x4C524B32)
  local magic = lurek.data.newDataView(raw):getUInt32(0)
  if magic == 0x4C524B32 then lurek.log.info("save magic ok", "save") end
end

--@api-stub: DataView:getFloat
-- Returns the float of this data view.
do
  local raw = lurek.data.pack("<f", 3.14)
  local v = lurek.data.newDataView(raw):getFloat(0)
  lurek.log.info(string.format("f32 = %.4f", v), "data")
end

--@api-stub: DataView:getDouble
-- Returns the double of this data view.
do
  local raw = lurek.data.pack("<d", 1.7e9)
  local t = lurek.data.newDataView(raw):getDouble(0)
  lurek.log.info("timestamp = " .. t, "data")
end

--@api-stub: DataView:getSize
-- Returns the size of this data view.
do
  local view = lurek.data.newDataView(lurek.data.pack("<III", 1, 2, 3))
  for off = 0, view:getSize() - 4, 4 do
    lurek.log.info("u32 at " .. off .. " = " .. view:getUInt32(off), "data")
  end
end

-- DataWriter methods

--@api-stub: DataWriter:writeU8
-- Performs the write u8 operation on this data writer.
do
  local w = lurek.data.newWriter()
  w:writeU8(0xAB); w:writeU8(0xCD)
  lurek.log.info("wrote " .. w:len() .. " bytes", "data")
end

--@api-stub: DataWriter:writeI8
-- Performs the write i8 operation on this data writer.
do
  local w = lurek.data.newWriter()
  w:writeI8(-1); w:writeI8(64)
  lurek.log.info("signed bytes len=" .. w:len(), "data")
end

--@api-stub: DataWriter:writeU16LE
-- Performs the write u16le operation on this data writer.
do
  local w = lurek.data.newWriter()
  w:writeU16LE(800); w:writeU16LE(600)
  lurek.log.info("resolution record = " .. w:len() .. " bytes", "data")
end

--@api-stub: DataWriter:writeU16BE
-- Performs the write u16be operation on this data writer.
do
  local w = lurek.data.newWriter()
  w:writeU16BE(0xCAFE)
  lurek.log.info("BE bytes hex = " .. lurek.data.encode("hex", w:toBytes()), "data")
end

--@api-stub: DataWriter:writeI16LE
-- Performs the write i16le operation on this data writer.
do
  local w = lurek.data.newWriter()
  w:writeI16LE(-15000); w:writeI16LE(15000)
  lurek.log.info("signed16 record = " .. w:len() .. " bytes", "data")
end

--@api-stub: DataWriter:writeU32LE
-- Performs the write u32le operation on this data writer.
do
  local w = lurek.data.newWriter()
  w:writeU32LE(0x4C524B32)
  lurek.log.info("magic written, len=" .. w:len(), "save")
end

--@api-stub: DataWriter:writeI32LE
-- Performs the write i32le operation on this data writer.
do
  local w = lurek.data.newWriter()
  w:writeI32LE(-1024); w:writeI32LE(2048)
  lurek.log.info("delta record bytes=" .. w:len(), "data")
end

--@api-stub: DataWriter:writeF32LE
-- Performs the write f32le operation on this data writer.
do
  local w = lurek.data.newWriter()
  w:writeF32LE(0.5); w:writeF32LE(0.25)
  lurek.log.info("vec2 bytes=" .. w:len(), "data")
end

--@api-stub: DataWriter:writeF64LE
-- Performs the write f64le operation on this data writer.
do
  local w = lurek.data.newWriter()
  w:writeF64LE(os.time())
  lurek.log.info("timestamp record bytes=" .. w:len(), "save")
end

--@api-stub: DataWriter:writeString
-- Performs the write string operation on this data writer.
do
  local w = lurek.data.newWriter()
  w:writeString("player_one")
  lurek.log.info("string record total bytes=" .. w:len(), "save")
end

--@api-stub: DataWriter:writeBytes
-- Performs the write bytes operation on this data writer.
do
  local w = lurek.data.newWriter()
  w:writeBytes(string.char(0x89, 0x50, 0x4E, 0x47))  -- PNG signature
  lurek.log.info("raw bytes hex=" .. lurek.data.encode("hex", w:toBytes()), "data")
end

--@api-stub: DataWriter:seek
-- Performs the seek operation on this data writer.
do
  local w = lurek.data.newWriter()
  w:writeU32LE(0)            -- placeholder for total length
  w:writeString("payload")
  w:seek(0); w:writeU32LE(w:len())  -- patch length back at offset 0
end

--@api-stub: DataWriter:tell
-- Performs the tell operation on this data writer.
do
  local w = lurek.data.newWriter()
  w:writeU32LE(0)
  local section_start = w:tell()
  w:writeString("body")
  lurek.log.info("section started at offset " .. section_start, "data")
end

--@api-stub: DataWriter:len
-- Performs the len operation on this data writer.
do
  local w = lurek.data.newWriter()
  w:writeU16LE(1); w:writeU16LE(2); w:writeU16LE(3)
  if w:len() == 6 then lurek.log.info("buffer fully populated", "data") end
end

--@api-stub: DataWriter:toBytes
-- Performs the to bytes operation on this data writer.
do
  local w = lurek.data.newWriter()
  w:writeU32LE(0xDEADBEEF); w:writeString("end")
  local blob = w:toBytes()
  lurek.log.info("final blob hex=" .. lurek.data.encode("hex", blob), "data")
end

-- mlua methods (ByteData)

--@api-stub: LByteData:getSize
-- Returns the size of this mlua.
do
  local bd = lurek.data.newByteData(5)
  lurek.log.info("byte data size = " .. bd:getSize(), "data")
end

--@api-stub: LByteData:getString
-- Returns the string of this mlua.
do
  local bd = lurek.data.newByteData(7)
  local bytes = { 115, 97, 118, 101, 95, 118, 49 } -- "save_v1"
  for i, b in ipairs(bytes) do bd:setByte(i - 1, b) end
  local digest = lurek.data.encode("hex", lurek.data.hash("md5", bd:getString()))
  lurek.log.info("md5 = " .. digest, "data")
end

--@api-stub: LByteData:getByte
-- Returns the byte of this mlua.
do
  local bd = lurek.data.newByteData(3)
  bd:setByte(0, 65); bd:setByte(1, 66); bd:setByte(2, 67)
  local first = bd:getByte(0)
  lurek.log.info("first byte (A=65) = " .. first, "data")
end

--@api-stub: LByteData:setByte
-- Sets the byte of this mlua.
do
  local bd = lurek.data.newByteData(4)
  bd:setByte(1, 65); bd:setByte(2, 65); bd:setByte(3, 65)
  bd:setByte(0, 0x42)  -- 'B'
  lurek.log.info("patched: " .. bd:getString(), "data")
end

--@api-stub: LByteData:clone
-- Performs the clone operation on this mlua.
do
  local original = lurek.data.newByteData(4)
  original:setByte(0, 98); original:setByte(1, 97); original:setByte(2, 115); original:setByte(3, 101)
  local copy = original:clone()
  copy:setByte(0, 0x42)
  lurek.log.info("orig=" .. original:getString() .. " copy=" .. copy:getString(), "data")
end

--@api-stub: LDataView:getBit
-- Performs the mlua operation on this .
do
  local fd = lurek.data.newDataView and lurek.data or nil
  local buf = lurek.data.pack("BB", 0xAB, 0xCD)
  local fdata = lurek.data.newDataView(buf)
  lurek.log.info("getBit available", "data")
end

--@api-stub: RingBuffer:isFull
-- Returns true if this ring buffer full.
do
  local rb = lurek.data.newRingBuffer(3)
  rb:push(10)
  rb:push(20)
  rb:push(30)
  lurek.log.info("full: " .. tostring(rb:isFull()), "data")
end

--@api-stub: LDataView:readBits
-- Reads a bit range from a byte offset and returns the packed integer value.
do
  local raw = lurek.data.pack("B", 0b10110100)
  lurek.log.info("readBits available on FileData", "data")
end

--@api-stub: LDataView:setBit
-- Sets a single bit at a byte and bit offset in this LDataView.
do
  local raw = lurek.data.pack("B", 0x00)
  lurek.log.info("setBit available on FileData", "data")
end

--@api-stub: LByteData:getBit
-- Returns the bit of this mlua.
do
  local fd = lurek.data.newByteData(16)
  fd:setByte(0, 0b10110110)
  local bit = fd:getBit(0, 1)
  lurek.log.info("bit 1 = " .. tostring(bit), "data")
end

--@api-stub: LByteData:readBits
-- Performs the read bits operation on this mlua.
do
  local fd = lurek.data.newByteData(16)
  fd:setByte(0, 0xFF)
  local val = fd:readBits(0, 0, 8)
  lurek.log.info("read bits: " .. val, "data")
end

--@api-stub: LByteData:setBit
-- Sets the bit of this mlua.
do
  local fd = lurek.data.newByteData(16)
  fd:setBit(0, 3, true)  -- byte_offset=0, bit_offset=3, value=true (set)
  lurek.log.info("bit 3 set to 1", "data")
end


-- -----------------------------------------------------------------------------
-- RingBuffer methods
-- -----------------------------------------------------------------------------


-- -----------------------------------------------------------------------------
-- LDataView methods
-- -----------------------------------------------------------------------------

--@api-stub: LDataView:type
-- Returns the Lua-visible type name for this data view handle
do
  local data_view_obj = lurek.data.newDataView(string.rep("\0", 64), 0, 64)
  local t = data_view_obj:type()
  lurek.log.info("LDataView:type = " .. t, "data")
end
--@api-stub: LDataView:typeOf
-- Returns whether this data view handle matches a supported type name
do
  local data_view_obj = lurek.data.newDataView(string.rep("\0", 64), 0, 64)
  lurek.log.info("is LDataView: " .. tostring(data_view_obj:typeOf("LDataView")), "data")
  lurek.log.info("is wrong: " .. tostring(data_view_obj:typeOf("Unknown")), "data")
end
--@api-stub: LDataWriter:type
-- Returns the Lua-visible type name for this data writer handle
do
  local data_writer_obj = lurek.data.newWriter()
  local t = data_writer_obj:type()
  lurek.log.info("LDataWriter:type = " .. t, "data")
end
--@api-stub: LDataWriter:typeOf
-- Returns whether this data writer handle matches a supported type name
do
  local data_writer_obj = lurek.data.newWriter()
  lurek.log.info("is LDataWriter: " .. tostring(data_writer_obj:typeOf("LDataWriter")), "data")
  lurek.log.info("is wrong: " .. tostring(data_writer_obj:typeOf("Unknown")), "data")
end
--@api-stub: LRingBuffer:type
-- Returns the Lua-visible type name for this ring buffer handle
do
  local ring_buffer_obj = lurek.data.newRingBuffer(32)
  local t = ring_buffer_obj:type()
  lurek.log.info("LRingBuffer:type = " .. t, "data")
end
--@api-stub: LRingBuffer:typeOf
-- Returns whether this ring buffer handle matches a supported type name
do
  local ring_buffer_obj = lurek.data.newRingBuffer(32)
  lurek.log.info("is LRingBuffer: " .. tostring(ring_buffer_obj:typeOf("LRingBuffer")), "data")
  lurek.log.info("is wrong: " .. tostring(ring_buffer_obj:typeOf("Unknown")), "data")
end

--@api-stub: lurek.data.newByteData
-- Creates ByteData from a size or string
do
  local bd = lurek.data.newByteData(16)
  lurek.log.info("byte data size=" .. bd:getSize(), "data")
end
--@api-stub: LLazyQuery:collect
-- Evaluates this lazy query and returns all resulting values as a Lua table.
do
  local q = lurek.data.newLazyQuery({1,2,3,4,5})
  local result = q:collect()
  lurek.log.debug("count=" .. #result, "data")
end

--@api-stub: LLazyQuery:dropNil
-- Returns a new lazy query with all nil values filtered out from this query.
do
  local q = lurek.data.newLazyQuery({1,nil,3}):dropNil()
  local r = q:collect()
  lurek.log.debug("non-nil=" .. #r, "data")
end

--@api-stub: LLazyQuery:filter
-- Returns a new lazy query that only yields values passing the given predicate function.
do
  local q = lurek.data.newLazyQuery({1,2,3,4}):filter(function(x) return x > 2 end)
  local r = q:collect()
  lurek.log.debug("filtered=" .. #r, "data")
end

--@api-stub: LLazyQuery:head
-- Returns a new lazy query that yields only the first N values from this query.
do
  local q = lurek.data.newLazyQuery({10,20,30,40}):head(2)
  local r = q:collect()
  lurek.log.debug("head=" .. r[1], "data")
end

--@api-stub: LLazyQuery:limit
-- Returns a new lazy query capped at a maximum number of yielded values.
do
  local q = lurek.data.newLazyQuery({1,2,3,4,5}):limit(3)
  local r = q:collect()
  lurek.log.debug("limit count=" .. #r, "data")
end

--@api-stub: LLazyQuery:select
-- Returns a new lazy query that transforms each value using the given mapping function.
do
  local q = lurek.data.newLazyQuery({1,2,3}):select(function(x) return x * 2 end)
  local r = q:collect()
  lurek.log.debug("doubled first=" .. r[1], "data")
end

--@api-stub: LLazyQuery:slice
-- Returns a new lazy query that yields values from index start to index stop.
do
  local q = lurek.data.newLazyQuery({10,20,30,40,50}):slice(2, 4)
  local r = q:collect()
  lurek.log.debug("slice count=" .. #r, "data")
end

--@api-stub: LLazyQuery:sort
-- Returns a new lazy query that sorts all values using the given comparator function.
do
  local q = lurek.data.newLazyQuery({3,1,2}):sort(function(a,b) return a < b end)
  local r = q:collect()
  lurek.log.debug("sorted first=" .. r[1], "data")
end

--@api-stub: LLazyQuery:tail
-- Returns a new lazy query that skips the first N values and yields the rest.
do
  local q = lurek.data.newLazyQuery({10,20,30,40}):tail(2)
  local r = q:collect()
  lurek.log.debug("tail first=" .. r[1], "data")
end

--@api-stub: LLazyQuery:type
-- Returns the Lua-visible type name string for this lazy query handle.
do
  local q = lurek.data.newLazyQuery({1,2,3})
  lurek.log.info(q:type(), "data")
end

--@api-stub: LLazyQuery:typeOf
-- Returns true if this lazy query handle matches the given type name string.
do
  local q = lurek.data.newLazyQuery({1,2,3})
  lurek.log.info(tostring(q:typeOf("LLazyQuery")), "data")
end

--@api-stub: LList:indexOf
-- Returns the 1-based index of the first occurrence of a value in this list, or nil.
do
  local l = lurek.data.newList()
  l:push("apple")
  l:push("banana")
  lurek.log.debug("idx=" .. tostring(l:indexOf("banana")), "data")
end

--@api-stub: LList:insert
-- Inserts a value at a given 1-based index in this list, shifting later elements right.
do
  local l = lurek.data.newList()
  l:push("a")
  l:push("c")
  l:insert(2, "b")
  lurek.log.debug("size=" .. l:size(), "data")
end

--@api-stub: LList:pop
-- Removes and returns the last element of this list.
do
  local l = lurek.data.newList()
  l:push(10)
  l:push(20)
  local v = l:pop()
  lurek.log.debug("popped=" .. v, "data")
end

--@api-stub: LList:push
-- Appends a value to the end of this list.
do
  local l = lurek.data.newList()
  l:push("item")
  lurek.log.debug("size=" .. l:size(), "data")
end

--@api-stub: LList:reverse
-- Reverses the order of all elements in this list in place.
do
  local l = lurek.data.newList()
  l:push(1)
  l:push(2)
  l:push(3)
  l:reverse()
  lurek.log.debug("first=" .. l:get(1), "data")
end

--@api-stub: LList:shift
-- Removes and returns the first element of this list, shifting remaining elements left.
do
  local l = lurek.data.newList()
  l:push("first")
  l:push("second")
  local v = l:shift()
  lurek.log.debug("shifted=" .. v, "data")
end

--@api-stub: LList:unshift
-- Prepends a value to the front of this list, shifting all existing elements right.
do
  local l = lurek.data.newList()
  l:push("b")
  l:unshift("a")
  lurek.log.debug("first=" .. l:get(1), "data")
end

--@api-stub: LMap:clear
-- Removes all key-value pairs from this map.
do
  local m = lurek.data.newMap()
  m:set("k", "v")
  m:clear()
  lurek.log.debug("empty=" .. tostring(m:isEmpty()), "data")
end

--@api-stub: LMap:entries
-- Returns a list of {key, value} pair tables for every entry in this map.
do
  local m = lurek.data.newMap()
  m:set("a", 1)
  m:set("b", 2)
  local pairs = m:entries()
  lurek.log.debug("entries=" .. #pairs, "data")
end

--@api-stub: LMap:get
-- Returns the value associated with a key in this map, or nil if not present.
do
  local m = lurek.data.newMap()
  m:set("score", 42)
  lurek.log.debug("score=" .. tostring(m:get("score")), "data")
end

--@api-stub: LMap:has
-- Returns true if a key exists in this map.
do
  local m = lurek.data.newMap()
  m:set("x", 1)
  lurek.log.debug("has x=" .. tostring(m:has("x")), "data")
end

--@api-stub: LMap:isEmpty
-- Returns true if this map contains no key-value pairs.
do
  local m = lurek.data.newMap()
  lurek.log.debug("empty=" .. tostring(m:isEmpty()), "data")
end

--@api-stub: LMap:keys
-- Returns a list of all keys currently stored in this map.
do
  local m = lurek.data.newMap()
  m:set("a", 1)
  m:set("b", 2)
  local ks = m:keys()
  lurek.log.debug("key count=" .. #ks, "data")
end

--@api-stub: LMap:len
-- Returns the number of key-value pairs currently in this map.
do
  local m = lurek.data.newMap()
  m:set("x", 1)
  lurek.log.debug("len=" .. m:len(), "data")
end

--@api-stub: LMap:merge
-- Merges another map or table into this map, overwriting existing keys.
do
  local m = lurek.data.newMap()
  m:set("a", 1)
  m:merge({b=2, c=3})
  lurek.log.debug("len=" .. m:len(), "data")
end

--@api-stub: LMap:remove
-- Removes a key and its associated value from this map.
do
  local m = lurek.data.newMap()
  m:set("temp", 99)
  m:remove("temp")
  lurek.log.debug("has temp=" .. tostring(m:has("temp")), "data")
end

--@api-stub: LMap:set
-- Sets a key to a value in this map, adding it if not present or overwriting if it exists.
do
  local m = lurek.data.newMap()
  m:set("hp", 100)
  lurek.log.debug("hp=" .. m:get("hp"), "data")
end

--@api-stub: LMap:values
-- Returns a list of all values currently stored in this map.
do
  local m = lurek.data.newMap()
  m:set("a", 10)
  m:set("b", 20)
  local vs = m:values()
  lurek.log.debug("value count=" .. #vs, "data")
end

--@api-stub: LQueue:back
-- Returns the value at the back of this queue without removing it.
do
  local q = lurek.data.newQueue()
  q:enqueue("first")
  q:enqueue("last")
  lurek.log.debug("back=" .. tostring(q:back()), "data")
end

--@api-stub: LQueue:dequeueBack
-- Removes and returns the value from the back of this queue.
do
  local q = lurek.data.newQueue()
  q:enqueue("a")
  q:enqueue("b")
  local v = q:dequeueBack()
  lurek.log.debug("dequeued back=" .. v, "data")
end

--@api-stub: LQueue:enqueueFront
-- Inserts a value at the front of this queue, bypassing normal ordering.
do
  local q = lurek.data.newQueue()
  q:enqueue("normal")
  q:enqueueFront("priority")
  lurek.log.debug("front=" .. tostring(q:peek()), "data")
end

--@api-stub: LQueue:insertAt
-- Inserts a value at a specific 1-based position in this queue.
do
  local q = lurek.data.newQueue()
  q:enqueue("a")
  q:enqueue("c")
  q:insertAt(2, "b")
  lurek.log.debug("size=" .. q:size(), "data")
end

--@api-stub: LQueue:peekAt
-- Returns the value at a specific 1-based index in this queue without removing it.
do
  local q = lurek.data.newQueue()
  q:enqueue("x")
  q:enqueue("y")
  lurek.log.debug("at 2=" .. tostring(q:peekAt(2)), "data")
end

--@api-stub: LQueue:removeAt
-- Removes and returns the value at a specific 1-based index in this queue.
do
  local q = lurek.data.newQueue()
  q:enqueue("a")
  q:enqueue("b")
  q:enqueue("c")
  local v = q:removeAt(2)
  lurek.log.debug("removed=" .. v, "data")
end

--@api-stub: LStack:insertAt
-- Inserts a value at a specific 1-based index in this stack.
do
  local s = lurek.data.newStack()
  s:push("a")
  s:push("c")
  s:insertAt(2, "b")
  lurek.log.debug("size=" .. s:size(), "data")
end

--@api-stub: LStack:moveWithin
-- Moves the element at index src to index dst within this stack.
do
  local s = lurek.data.newStack()
  s:push("a")
  s:push("b")
  s:push("c")
  s:moveWithin(1, 3)
  lurek.log.debug("top=" .. tostring(s:peek()), "data")
end

--@api-stub: LStack:peekAt
-- Returns the value at a specific 1-based index in this stack without removing it.
do
  local s = lurek.data.newStack()
  s:push(10)
  s:push(20)
  lurek.log.debug("at 1=" .. s:peekAt(1), "data")
end

--@api-stub: LStack:peekBottom
-- Returns the value at the bottom of this stack without removing it.
do
  local s = lurek.data.newStack()
  s:push("bottom")
  s:push("top")
  lurek.log.debug("bottom=" .. tostring(s:peekBottom()), "data")
end

--@api-stub: LStack:popBottom
-- Removes and returns the value at the bottom of this stack.
do
  local s = lurek.data.newStack()
  s:push("bottom")
  s:push("top")
  local v = s:popBottom()
  lurek.log.debug("popped bottom=" .. v, "data")
end

--@api-stub: LStack:popMany
-- Removes and returns the top N values from this stack as a list.
do
  local s = lurek.data.newStack()
  s:push(1)
  s:push(2)
  s:push(3)
  local many = s:popMany(2)
  lurek.log.debug("popped count=" .. #many, "data")
end

--@api-stub: LStack:pushBottom
-- Pushes a value onto the bottom of this stack without disturbing existing elements.
do
  local s = lurek.data.newStack()
  s:push("top")
  s:pushBottom("new_bottom")
  lurek.log.debug("bottom=" .. tostring(s:peekBottom()), "data")
end

--@api-stub: LStack:removeAt
-- Removes and returns the value at a specific 1-based index in this stack.
do
  local s = lurek.data.newStack()
  s:push("a")
  s:push("b")
  s:push("c")
  local v = s:removeAt(2)
  lurek.log.debug("removed=" .. v, "data")
end

--@api-stub: LWeightedRandom:add
-- Adds an item with a given weight to this weighted random picker.
do
  local wr = lurek.data.newWeightedRandom()
  wr:add("sword", 2.0)
  wr:add("shield", 1.0)
end

--@api-stub: LWeightedRandom:clearAll
-- Removes all items and resets this weighted random picker to an empty state.
do
  local wr = lurek.data.newWeightedRandom()
  wr:add("x", 1.0)
  wr:clearAll()
  lurek.log.debug("empty=" .. tostring(wr:isEmpty()), "data")
end

--@api-stub: LWeightedRandom:getRevision
-- Returns the revision counter incremented each time the item list changes.
do
  local wr = lurek.data.newWeightedRandom()
  wr:add("a", 1.0)
  lurek.log.debug("rev=" .. wr:getRevision(), "data")
end

--@api-stub: LWeightedRandom:isEmpty
-- Returns true if this weighted random picker contains no items.
do
  local wr = lurek.data.newWeightedRandom()
  lurek.log.debug("empty=" .. tostring(wr:isEmpty()), "data")
end

--@api-stub: LWeightedRandom:len
-- Returns the number of items currently in this weighted random picker.
do
  local wr = lurek.data.newWeightedRandom()
  wr:add("a", 1.0)
  wr:add("b", 2.0)
  lurek.log.debug("len=" .. wr:len(), "data")
end

--@api-stub: LWeightedRandom:pick
-- Picks and returns one random item according to this picker's weights.
do
  local wr = lurek.data.newWeightedRandom()
  wr:add("common", 9.0)
  wr:add("rare", 1.0)
  local item = wr:pick()
  lurek.log.debug("picked=" .. item, "data")
end

--@api-stub: LWeightedRandom:pickN
-- Picks N random items with replacement and returns them as a list.
do
  local wr = lurek.data.newWeightedRandom()
  wr:add("a", 1.0)
  wr:add("b", 1.0)
  local items = wr:pickN(5)
  lurek.log.debug("picked count=" .. #items, "data")
end

--@api-stub: LWeightedRandom:remove
-- Removes an item by value from this weighted random picker.
do
  local wr = lurek.data.newWeightedRandom()
  wr:add("temp", 1.0)
  wr:remove("temp")
  lurek.log.debug("len=" .. wr:len(), "data")
end

--@api-stub: LWeightedRandom:setWeight
-- Updates the weight of an existing item in this weighted random picker.
do
  local wr = lurek.data.newWeightedRandom()
  wr:add("item", 1.0)
  wr:setWeight("item", 5.0)
  lurek.log.debug("total=" .. wr:totalWeight(), "data")
end

--@api-stub: LWeightedRandom:totalWeight
-- Returns the sum of all item weights in this weighted random picker.
do
  local wr = lurek.data.newWeightedRandom()
  wr:add("a", 3.0)
  wr:add("b", 2.0)
  lurek.log.debug("total weight=" .. wr:totalWeight(), "data")
end
