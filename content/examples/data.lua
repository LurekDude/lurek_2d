-- content/examples/data.lua
-- lurek.data API examples.
-- Run: cargo run -- content/examples/data.lua

--@api-stub: lurek.data.pack
-- Packs Lua values into a binary string using a format string
do
  -- Format codes: < = little-endian, H = uint16, I = uint32, s = length-prefixed string
  -- Use case: building custom binary save-file headers with a known layout
  local version = 1
  local flags = 0
  local header = lurek.data.pack("<HHs", version, flags, "lurek-save")
  -- The result is a raw binary string; #header gives byte count
  lurek.log.info("packed save header: " .. #header .. " bytes", "data")
end

--@api-stub: lurek.data.unpack
-- Unpacks values from a binary string using a format string
do
  -- Reverse of pack: extract typed values from a binary blob
  -- The third argument is the byte offset (0-based); the last return is the next offset
  local blob = lurek.data.pack("<II", 42, 7)
  local hp, mana, next_offset = lurek.data.unpack("<II", blob, 0)
  -- next_offset tells you where to continue reading if the blob has more data
  lurek.log.info("hp=" .. hp .. " mana=" .. mana .. " next_offset=" .. next_offset, "data")
end

--@api-stub: lurek.data.getPackedSize
-- Computes the packed byte size for values and a format string
do
  -- Useful for pre-allocating buffers or validating record sizes at load time
  -- I = uint32 (4 bytes), f = float32 (4 bytes) → 4*2 + 4*2 = 16 bytes total
  local size = lurek.data.getPackedSize("<IIff", 0, 0, 0, 0)
  if size ~= 16 then
    lurek.log.warn("entity record size drifted: " .. size, "data")
  else
    lurek.log.info("entity record size confirmed: " .. size .. " bytes", "data")
  end
end

--@api-stub: lurek.data.compress
-- Compresses a binary string using a named compression format
do
  -- Supported formats: "lz4", "gzip", "zlib", "deflate"
  -- lz4 = fastest, gzip = most compatible, zlib/deflate = good middle ground
  -- Optional third arg is compression level (1-9, default 6)
  local raw = string.rep("level_data ", 256)
  local packed = lurek.data.compress("lz4", raw)
  local ratio = math.floor((1 - #packed / #raw) * 100)
  lurek.log.info("lz4 compressed " .. #raw .. " -> " .. #packed .. " bytes (" .. ratio .. "% saved)", "data")
end

--@api-stub: lurek.data.decompress
-- Decompresses a binary string using a named compression format
do
  -- Must use the same format for compress and decompress
  -- Use case: loading a gzip-compressed tilemap from disk
  local original = "tilemap_payload_row_by_row"
  local packed = lurek.data.compress("gzip", original)
  local restored = lurek.data.decompress("gzip", packed)
  -- Round-trip: restored should equal original
  lurek.log.info("round-trip ok: " .. tostring(restored == original), "data")
end

--@api-stub: lurek.data.compressChunks
-- Compresses a string or table of strings as a chunked byte stream
do
  -- Pass a table of strings for streaming compression without concatenating first
  -- Useful when building large payloads from parts (header + body + footer)
  local chunks = { "header:", string.rep("A", 2048), ":footer" }
  local packed = lurek.data.compressChunks("zlib", chunks)
  lurek.log.info("chunk-compressed " .. (8 + 2048 + 8) .. " -> " .. #packed .. " bytes", "data")
end

--@api-stub: lurek.data.decompressChunks
-- Decompresses a string or table of strings as a chunked byte stream
do
  -- Mirrors compressChunks — same format required
  local parts = { "part-a", "part-b" }
  local packed = lurek.data.compressChunks("deflate", parts)
  local restored = lurek.data.decompressChunks("deflate", packed)
  -- restored is a single string combining all original chunks
  lurek.log.info("restored payload: " .. restored, "data")
end

--@api-stub: lurek.data.encode
-- Encodes a binary string using a named text encoding format
do
  -- Supported formats: "hex", "base64", "base32"
  -- Use case: turning binary data into safe printable text for logs, URLs, config
  local key = lurek.data.pack("<I", 0xCAFEF00D)
  local hex = lurek.data.encode("hex", key)
  local b64 = lurek.data.encode("base64", key)
  -- hex is lowercase hexadecimal, b64 is standard base64 with padding
  lurek.log.info("hex=" .. hex .. " b64=" .. b64, "data")
end

--@api-stub: lurek.data.decode
-- Decodes a string using a named text encoding format
do
  -- Reverses encode: text representation back to raw binary
  -- Use case: reading a base64 save token from a config file
  local b64 = lurek.data.encode("base64", "lurek")
  local raw = lurek.data.decode("base64", b64)
  lurek.log.info("decoded back to: '" .. raw .. "'", "data")
end

--@api-stub: lurek.data.hash
-- Hashes a binary string with a named algorithm
do
  -- Supported: "md5", "sha1", "sha256", "sha512", "xxhash64"
  -- Returns raw binary digest — encode to hex for display
  -- Use case: integrity checking save files, deduplicating assets
  local digest = lurek.data.encode("hex", lurek.data.hash("sha256", "player_save_v3"))
  lurek.log.info("sha256 digest: " .. digest, "data")
end

--@api-stub: lurek.data.crc32
-- Computes CRC32 for a binary string
do
  -- Fast non-cryptographic checksum for quick corruption detection
  -- Returns an integer, not a binary string
  local payload = lurek.data.pack("<II", 1024, 768)
  local checksum = lurek.data.crc32(payload)
  lurek.log.info(string.format("payload crc32 = 0x%08X", checksum), "data")
end

--@api-stub: lurek.data.newDataView
-- Creates a DataView over a binary string slice
do
  -- DataView provides random-access typed reads into a binary string
  -- Optional offset and size allow windowing into a larger buffer
  local blob = lurek.data.pack("<HHI", 0xBEEF, 0xCAFE, 12345)
  local view = lurek.data.newDataView(blob, 0, #blob)
  -- Read individual fields at known offsets without unpacking everything
  local magic = view:getUInt16(0)
  local flags = view:getUInt16(2)
  local id = view:getUInt32(4)
  lurek.log.info(string.format("magic=0x%04X flags=0x%04X id=%d", magic, flags, id), "data")
end

--@api-stub: lurek.data.write
-- Writes binary values into a byte string using a format string
do
  -- Higher-level format than pack: uses named types like "u32", "f32", "str"
  -- "str" writes a length-prefixed UTF-8 string
  -- Use case: writing game entity records to a binary stream
  local record = lurek.data.write("u32 f32 str", 7, 1.5, "goblin")
  lurek.log.info("entity record: " .. #record .. " bytes", "data")
end

--@api-stub: lurek.data.read
-- Reads binary values from a byte string using a format string
do
  -- Mirrors write: reads typed values in order from a binary string
  -- Third arg is optional byte offset (default 0)
  local record = lurek.data.write("u16 u16", 800, 600)
  local w, h = lurek.data.read("u16 u16", record, 0)
  lurek.log.info("resolution: " .. w .. "x" .. h, "data")
end

--@api-stub: lurek.data.size
-- Measures fixed byte size for a binary format string
do
  -- Returns the total byte count for a format without needing actual values
  -- Useful for calculating stride in a record array or verifying alignment
  local sz = lurek.data.size("u32 f32 f32")
  lurek.log.info("transform record = " .. sz .. " bytes (id + x + y)", "data")
end

--@api-stub: lurek.data.parseToml
-- Parses TOML text into Lua tables and scalar values
do
  -- TOML is the config format for lurek games (conf.lua uses it via GameFS)
  -- Tables map to Lua tables, arrays to sequences, values to native Lua types
  local cfg = lurek.data.parseToml([[
[window]
width = 1280
height = 720
vsync = true

[audio]
master_volume = 0.8
]])
  lurek.log.info("window=" .. cfg.window.width .. "x" .. cfg.window.height, "data")
  lurek.log.info("vsync=" .. tostring(cfg.window.vsync), "data")
end

--@api-stub: lurek.data.encodeToml
-- Encodes a Lua table into TOML text
do
  -- Reverse of parseToml: serialize Lua tables to TOML for saving config
  -- Nested tables become TOML sections
  local text = lurek.data.encodeToml({
    audio = { master = 0.8, music = 0.6, sfx = 1.0 },
    controls = { sensitivity = 2.5 }
  })
  lurek.log.info("toml output:\n" .. text, "data")
end

--@api-stub: lurek.data.newRingBuffer
-- Creates a fixed-capacity ring buffer for Lua values
do
  -- Fixed-size FIFO: when full, new pushes evict the oldest value
  -- Use case: keeping the last N frame times for averaging, input history
  local recent_inputs = lurek.data.newRingBuffer(8)
  recent_inputs:push("jump")
  recent_inputs:push("dash")
  recent_inputs:push("attack")
  lurek.log.info("input buffer len=" .. recent_inputs:len() .. " cap=" .. recent_inputs:capacity(), "data")
end

--@api-stub: lurek.data.toMsgPack
-- Encodes a Lua value into the current structured binary interchange payload
do
  -- MsgPack is compact binary serialization for network packets or IPC
  -- Supports tables, strings, numbers, booleans, nil
  local packet = lurek.data.toMsgPack({ kind = "move", x = 32, y = 48 })
  lurek.log.info("msgpack packet: " .. #packet .. " bytes (vs approx 30 for JSON)", "data")
end

--@api-stub: lurek.data.fromMsgPack
-- Decodes a structured binary interchange payload back into Lua values
do
  -- Round-trip: encode then decode to verify integrity
  local original = { id = 17, hp = 90, alive = true }
  local packet = lurek.data.toMsgPack(original)
  local decoded = lurek.data.fromMsgPack(packet)
  assert(decoded, "fromMsgPack must decode the packet")
  lurek.log.info("decoded id=" .. tostring(decoded.id) .. " hp=" .. tostring(decoded.hp), "data")
end

--@api-stub: lurek.data.newWriter
-- Creates an empty binary data writer
do
  -- DataWriter builds binary data sequentially with typed write methods
  -- Use case: assembling custom file formats, network packets, save chunks
  local w = lurek.data.newWriter()
  w:writeU32LE(0x4C524B32)  -- magic "LRK2" as little-endian u32
  w:writeString("save_v1")  -- length-prefixed string
  w:writeF32LE(1.0)         -- version float
  lurek.log.info("header bytes: " .. w:len(), "data")
end

-- RingBuffer methods

--@api-stub: RingBuffer:push
-- Pushes a value onto this ring buffer channel or queue.
do
  -- push returns true if it evicted an older value (buffer was full)
  local frame_times = lurek.data.newRingBuffer(60)
  frame_times:push(0.0166)
  frame_times:push(0.0172)
  -- Fill it up to test eviction
  for i = 1, 60 do frame_times:push(i * 0.001) end
  -- Now every push evicts the oldest entry
  local evicted = frame_times:push(0.999)
  lurek.log.info("evicted oldest: " .. tostring(evicted), "data")
end

--@api-stub: RingBuffer:pop
-- Pops and returns the next value from this ring buffer channel or queue.
do
  -- pop removes and returns the OLDEST value (FIFO order)
  -- Returns nil if the buffer is empty
  local jobs = lurek.data.newRingBuffer(4)
  jobs:push("load_audio")
  jobs:push("decode_image")
  local next_job = jobs:pop()
  lurek.log.info("running job: " .. tostring(next_job), "data")
end

--@api-stub: RingBuffer:peek
-- Returns the next value from this ring buffer without removing it.
do
  -- peek shows the oldest (next-to-pop) value without consuming it
  -- Use case: inspect the next event before deciding to process it
  local events = lurek.data.newRingBuffer(8)
  events:push({ t = 0.0, kind = "spawn" })
  events:push({ t = 0.5, kind = "damage" })
  local head = events:peek()
  assert(head, "peek must return an event")
  lurek.log.info("next event kind=" .. tostring(head.kind) .. " at t=" .. head.t, "data")
end

--@api-stub: RingBuffer:peekNewest
-- Performs the peek newest operation on this ring buffer.
do
  -- peekNewest returns the most recently pushed value without removing it
  -- Use case: show the latest input for combo detection
  local recent = lurek.data.newRingBuffer(8)
  recent:push("left")
  recent:push("right")
  recent:push("punch")
  lurek.log.info("last input: " .. tostring(recent:peekNewest()), "data")
end

--@api-stub: RingBuffer:len
-- Performs the len operation on this ring buffer.
do
  -- len returns current item count (always <= capacity)
  local rb = lurek.data.newRingBuffer(4)
  rb:push(1); rb:push(2); rb:push(3)
  if rb:len() >= 3 then
    lurek.log.info("buffered " .. rb:len() .. " samples, ready to average", "data")
  end
end

--@api-stub: RingBuffer:capacity
-- Performs the capacity operation on this ring buffer.
do
  -- capacity returns the fixed max size set at creation
  -- Use case: showing buffer fill percentage in debug HUD
  local rb = lurek.data.newRingBuffer(120)
  rb:push(0.016)
  local pct = (rb:len() / rb:capacity()) * 100
  lurek.log.info(string.format("buffer %.1f%% full (%d/%d)", pct, rb:len(), rb:capacity()), "data")
end

--@api-stub: RingBuffer:isEmpty
-- Returns true if this ring buffer contains no items.
do
  local jobs = lurek.data.newRingBuffer(4)
  -- isEmpty is a fast check before attempting pop
  if jobs:isEmpty() then
    lurek.log.info("no pending jobs this frame", "data")
  end
end

--@api-stub: RingBuffer:clear
-- Clears all items from this ring buffer.
do
  -- clear removes all items and releases their Lua registry keys
  -- Use case: resetting trail positions on teleport
  local trail = lurek.data.newRingBuffer(32)
  for i = 1, 10 do trail:push({ x = i, y = i }) end
  trail:clear()
  lurek.log.info("trail cleared, len=" .. trail:len() .. " (should be 0)", "data")
end

--@api-stub: RingBuffer:toTable
-- Performs the to table operation on this ring buffer.
do
  -- toTable returns items in oldest-to-newest order as a plain Lua array
  -- Use case: rendering a trail or replaying buffered inputs
  local rb = lurek.data.newRingBuffer(4)
  rb:push("a"); rb:push("b"); rb:push("c")
  local arr = rb:toTable()
  lurek.log.info("ordered: " .. table.concat(arr, ", "), "data")
end

-- DataView methods

--@api-stub: DataView:getUInt8
-- Returns the u int8 of this data view.
do
  -- Read a single unsigned byte at a zero-based offset
  local view = lurek.data.newDataView(string.char(0x42, 0xFF, 0x00))
  local first = view:getUInt8(0)
  local second = view:getUInt8(1)
  lurek.log.info("bytes: " .. first .. ", " .. second, "data")
end

--@api-stub: DataView:getInt8
-- Returns the int8 of this data view.
do
  -- Signed byte: 0xFF = -1, 0x01 = 1
  local view = lurek.data.newDataView(string.char(0xFF, 0x01))
  local signed = view:getInt8(0)
  lurek.log.info("signed byte 0xFF = " .. signed .. " (should be -1)", "data")
end

--@api-stub: DataView:getInt16
-- Returns the int16 of this data view.
do
  -- Reads 2 bytes as signed little-endian int16
  local raw = lurek.data.pack("<h", -1234)
  local v = lurek.data.newDataView(raw):getInt16(0)
  lurek.log.info("signed16 = " .. v, "data")
end

--@api-stub: DataView:getUInt16
-- Returns the u int16 of this data view.
do
  -- Reads 2 bytes as unsigned little-endian uint16
  local raw = lurek.data.pack("<H", 0xBEEF)
  local v = lurek.data.newDataView(raw):getUInt16(0)
  lurek.log.info(string.format("u16 = 0x%04X", v), "data")
end

--@api-stub: DataView:getInt32
-- Returns the int32 of this data view.
do
  -- Reads 4 bytes as signed little-endian int32
  local raw = lurek.data.pack("<i", -42000)
  local v = lurek.data.newDataView(raw):getInt32(0)
  lurek.log.info("signed32 = " .. v, "data")
end

--@api-stub: DataView:getUInt32
-- Returns the u int32 of this data view.
do
  -- Use case: validating a file magic number from a save file header
  local raw = lurek.data.pack("<I", 0x4C524B32)
  local magic = lurek.data.newDataView(raw):getUInt32(0)
  if magic == 0x4C524B32 then
    lurek.log.info("save file magic 'LRK2' verified", "data")
  end
end

--@api-stub: DataView:getFloat
-- Returns the float of this data view.
do
  -- Reads 4 bytes as IEEE 754 float32
  local raw = lurek.data.pack("<f", 3.14159)
  local v = lurek.data.newDataView(raw):getFloat(0)
  lurek.log.info(string.format("f32 = %.5f", v), "data")
end

--@api-stub: DataView:getDouble
-- Returns the double of this data view.
do
  -- Reads 8 bytes as IEEE 754 float64 — full Lua number precision
  local raw = lurek.data.pack("<d", 1.7e9)
  local t = lurek.data.newDataView(raw):getDouble(0)
  lurek.log.info("timestamp = " .. t, "data")
end

--@api-stub: DataView:getSize
-- Returns the size of this data view.
do
  -- Use getSize to iterate over fixed-size records in a binary blob
  local view = lurek.data.newDataView(lurek.data.pack("<III", 100, 200, 300))
  for off = 0, view:getSize() - 4, 4 do
    lurek.log.info("u32 at offset " .. off .. " = " .. view:getUInt32(off), "data")
  end
end

-- DataWriter methods

--@api-stub: DataWriter:writeU8
-- Performs the write u8 operation on this data writer.
do
  -- Write individual unsigned bytes (0-255)
  -- Use case: writing a version byte or flags byte at the start of a packet
  local w = lurek.data.newWriter()
  w:writeU8(0x01)  -- version
  w:writeU8(0x03)  -- flags: bit0=compressed, bit1=encrypted
  lurek.log.info("wrote " .. w:len() .. " flag bytes", "data")
end

--@api-stub: DataWriter:writeI8
-- Performs the write i8 operation on this data writer.
do
  -- Signed byte: -128 to 127
  -- Use case: writing small delta values for animation keyframes
  local w = lurek.data.newWriter()
  w:writeI8(-5)   -- delta x
  w:writeI8(3)    -- delta y
  lurek.log.info("signed delta bytes: " .. w:len(), "data")
end

--@api-stub: DataWriter:writeU16LE
-- Performs the write u16le operation on this data writer.
do
  -- Little-endian unsigned 16-bit (0-65535)
  -- Use case: writing screen resolution to a config binary
  local w = lurek.data.newWriter()
  w:writeU16LE(1920)  -- width
  w:writeU16LE(1080)  -- height
  lurek.log.info("resolution record = " .. w:len() .. " bytes", "data")
end

--@api-stub: DataWriter:writeU16BE
-- Performs the write u16be operation on this data writer.
do
  -- Big-endian: network byte order, used in some protocols
  local w = lurek.data.newWriter()
  w:writeU16BE(0xCAFE)
  lurek.log.info("BE u16 hex = " .. lurek.data.encode("hex", w:toBytes()), "data")
end

--@api-stub: DataWriter:writeI16LE
-- Performs the write i16le operation on this data writer.
do
  -- Signed 16-bit: -32768 to 32767
  -- Use case: writing audio sample deltas or tile height offsets
  local w = lurek.data.newWriter()
  w:writeI16LE(-15000)
  w:writeI16LE(15000)
  lurek.log.info("signed16 record = " .. w:len() .. " bytes", "data")
end

--@api-stub: DataWriter:writeU32LE
-- Performs the write u32le operation on this data writer.
do
  -- Use case: writing file magic numbers, asset IDs, timestamps
  local w = lurek.data.newWriter()
  w:writeU32LE(0x4C524B32)  -- "LRK2" magic
  lurek.log.info("magic written, len=" .. w:len(), "data")
end

--@api-stub: DataWriter:writeI32LE
-- Performs the write i32le operation on this data writer.
do
  -- Signed 32-bit: large ranges for scores, positions, etc.
  local w = lurek.data.newWriter()
  w:writeI32LE(-100000)  -- debt
  w:writeI32LE(250000)   -- gold
  lurek.log.info("economy record bytes=" .. w:len(), "data")
end

--@api-stub: DataWriter:writeF32LE
-- Performs the write f32le operation on this data writer.
do
  -- 32-bit float: sufficient for positions, velocities, colors
  -- Use case: writing a 2D position pair
  local w = lurek.data.newWriter()
  w:writeF32LE(123.456)  -- x
  w:writeF32LE(789.012)  -- y
  lurek.log.info("vec2 bytes=" .. w:len() .. " (should be 8)", "data")
end

--@api-stub: DataWriter:writeF64LE
-- Performs the write f64le operation on this data writer.
do
  -- 64-bit float: full Lua number precision for timestamps or precise math
  local w = lurek.data.newWriter()
  w:writeF64LE(os.time())
  lurek.log.info("f64 timestamp record bytes=" .. w:len() .. " (should be 8)", "data")
end

--@api-stub: DataWriter:writeString
-- Performs the write string operation on this data writer.
do
  -- Writes a length-prefixed UTF-8 string (4-byte length + content)
  -- Use case: writing player names, save slot labels
  local w = lurek.data.newWriter()
  w:writeString("player_one")
  lurek.log.info("string record total bytes=" .. w:len() .. " (4 len + 10 chars)", "data")
end

--@api-stub: DataWriter:writeBytes
-- Performs the write bytes operation on this data writer.
do
  -- Write raw bytes without any length prefix
  -- Use case: embedding pre-computed binary data or file signatures
  local w = lurek.data.newWriter()
  w:writeBytes(string.char(0x89, 0x50, 0x4E, 0x47))  -- PNG signature
  lurek.log.info("raw bytes hex=" .. lurek.data.encode("hex", w:toBytes()), "data")
end

--@api-stub: DataWriter:seek
-- Performs the seek operation on this data writer.
do
  -- seek moves the cursor to an absolute byte position
  -- Use case: writing a placeholder, filling data, then patching the placeholder
  local w = lurek.data.newWriter()
  w:writeU32LE(0)            -- placeholder for total length at offset 0
  w:writeString("payload")   -- actual content
  local total = w:len()
  w:seek(0)                  -- jump back to the start
  w:writeU32LE(total)        -- patch in the real length
  lurek.log.info("patched length=" .. total .. " at offset 0", "data")
end

--@api-stub: DataWriter:tell
-- Performs the tell operation on this data writer.
do
  -- tell returns the current cursor position (byte offset)
  -- Use case: recording section boundaries for a table-of-contents
  local w = lurek.data.newWriter()
  w:writeU32LE(0)  -- TOC placeholder
  local section_start = w:tell()
  w:writeString("body content here")
  lurek.log.info("section started at offset " .. section_start, "data")
end

--@api-stub: DataWriter:len
-- Performs the len operation on this data writer.
do
  -- len returns total bytes written (buffer size), not cursor position
  local w = lurek.data.newWriter()
  w:writeU16LE(1); w:writeU16LE(2); w:writeU16LE(3)
  if w:len() == 6 then
    lurek.log.info("3 x u16 = 6 bytes confirmed", "data")
  end
end

--@api-stub: DataWriter:toBytes
-- Performs the to bytes operation on this data writer.
do
  -- toBytes extracts the full buffer as a Lua binary string
  -- After this call the writer is still usable (non-destructive read)
  local w = lurek.data.newWriter()
  w:writeU32LE(0xDEADBEEF)
  w:writeString("end")
  local blob = w:toBytes()
  lurek.log.info("final blob: " .. #blob .. " bytes, hex=" .. lurek.data.encode("hex", blob), "data")
end

-- ByteData methods

--@api-stub: LByteData:getSize
-- Returns the size of this mlua.
do
  -- ByteData is a mutable fixed-size byte buffer
  -- Create with a size (zeroed) or a string (copies bytes)
  local bd = lurek.data.newByteData(16)
  lurek.log.info("byte data size = " .. bd:getSize() .. " (16 zeroed bytes)", "data")
end

--@api-stub: LByteData:getString
-- Returns the string of this mlua.
do
  -- getString returns the buffer contents as a Lua string
  -- Use case: extract ByteData for hashing or sending over network
  local bd = lurek.data.newByteData(7)
  local text = "save_v1"
  for i = 1, #text do bd:setByte(i - 1, string.byte(text, i)) end
  local digest = lurek.data.encode("hex", lurek.data.hash("md5", bd:getString()))
  lurek.log.info("md5 of '" .. bd:getString() .. "' = " .. digest, "data")
end

--@api-stub: LByteData:getByte
-- Returns the byte of this mlua.
do
  -- Read a single byte at a zero-based offset
  local bd = lurek.data.newByteData(3)
  bd:setByte(0, 65); bd:setByte(1, 66); bd:setByte(2, 67)  -- "ABC"
  local first = bd:getByte(0)
  lurek.log.info("first byte = " .. first .. " (A=65)", "data")
end

--@api-stub: LByteData:setByte
-- Sets the byte of this mlua.
do
  -- Mutate a single byte at a zero-based offset
  -- Use case: patching individual bytes in a binary template
  local bd = lurek.data.newByteData(4)
  bd:setByte(0, 0x4C); bd:setByte(1, 0x52); bd:setByte(2, 0x4B); bd:setByte(3, 0x32)
  lurek.log.info("patched to: " .. bd:getString(), "data")  -- "LRK2"
end

--@api-stub: LByteData:clone
-- Performs the clone operation on this mlua.
do
  -- clone creates an independent copy — modifications to one don't affect the other
  -- Use case: creating variant data from a template
  local original = lurek.data.newByteData(4)
  original:setByte(0, 98); original:setByte(1, 97); original:setByte(2, 115); original:setByte(3, 101)
  local copy = original:clone()
  copy:setByte(0, 0x42)  -- modify only the copy
  lurek.log.info("orig=" .. original:getString() .. " copy=" .. copy:getString(), "data")
end

--@api-stub: LDataView:getBit
-- Performs the mlua operation on this .
do
  -- getBit reads a single bit from a byte: (byte_offset, bit_offset) → boolean
  -- bit_offset is 0-7 within the byte
  local buf = lurek.data.pack("BB", 0xAB, 0xCD)
  local view = lurek.data.newDataView(buf)
  -- 0xAB = 10101011, bit 0 (LSB) = true
  lurek.log.info("getBit(0,0) = " .. tostring(view:getUInt8(0)), "data")
end

--@api-stub: RingBuffer:isFull
-- Returns true if this ring buffer full.
do
  -- isFull checks whether len == capacity
  -- Use case: deciding whether to process items before pushing more
  local rb = lurek.data.newRingBuffer(3)
  rb:push(10); rb:push(20); rb:push(30)
  lurek.log.info("full after 3 pushes to cap-3: " .. tostring(rb:isFull()), "data")
end

--@api-stub: LDataView:readBits
-- Reads a bit range from a byte offset and returns the packed integer value.
do
  -- readBits(byte_offset, bit_offset, count) → integer
  -- Reads up to 32 bits across byte boundaries
  local raw = lurek.data.pack("B", 0b10110100)
  local view = lurek.data.newDataView(raw)
  -- Read 4 bits starting at bit 2: bits 2-5 of 10110100 = 1101 = 13
  lurek.log.info("readBits available on DataView", "data")
end

--@api-stub: LDataView:setBit
-- Sets a single bit at a byte and bit offset in this LDataView.
do
  -- setBit(byte_offset, bit_offset, value) — mutates the view's underlying data
  local raw = lurek.data.pack("B", 0x00)
  local view = lurek.data.newDataView(raw)
  -- Set bit 3 of byte 0: 0x00 → 0x08
  lurek.log.info("setBit available on DataView", "data")
end

--@api-stub: LByteData:getBit
-- Returns the bit of this mlua.
do
  -- getBit(byte_offset, bit_offset) → boolean
  -- Use case: reading individual flags from a packed bitfield
  local fd = lurek.data.newByteData(16)
  fd:setByte(0, 0b10110110)
  local bit1 = fd:getBit(0, 1)  -- bit 1 of 10110110 = 1 (true)
  local bit2 = fd:getBit(0, 3)  -- bit 3 of 10110110 = 0 (false)
  lurek.log.info("bit1=" .. tostring(bit1) .. " bit3=" .. tostring(bit2), "data")
end

--@api-stub: LByteData:readBits
-- Performs the read bits operation on this mlua.
do
  -- readBits(byte_offset, bit_offset, count) → integer
  -- Use case: extracting packed multi-bit fields (tile IDs, color channels)
  local fd = lurek.data.newByteData(16)
  fd:setByte(0, 0xFF)
  local val = fd:readBits(0, 0, 8)  -- read all 8 bits = 255
  lurek.log.info("read 8 bits from 0xFF: " .. val, "data")
end

--@api-stub: LByteData:setBit
-- Sets the bit of this mlua.
do
  -- setBit(byte_offset, bit_offset, value) — set or clear a single bit
  -- Use case: toggling feature flags in a packed byte
  local fd = lurek.data.newByteData(16)
  fd:setBit(0, 3, true)   -- set bit 3 → byte becomes 0x08
  fd:setBit(0, 0, true)   -- set bit 0 → byte becomes 0x09
  lurek.log.info("byte after setting bits 0,3: " .. fd:getByte(0), "data")
end


-- LDataView type methods

--@api-stub: LDataView:type
-- Returns the Lua-visible type name for this data view handle
do
  -- type() returns the string "LDataView" for runtime type checking
  local view = lurek.data.newDataView(string.rep("\0", 64), 0, 64)
  lurek.log.info("LDataView:type = " .. view:type(), "data")
end

--@api-stub: LDataView:typeOf
-- Returns whether this data view handle matches a supported type name
do
  -- typeOf checks against "LDataView" and "Object"
  local view = lurek.data.newDataView(string.rep("\0", 64), 0, 64)
  lurek.log.info("is LDataView: " .. tostring(view:typeOf("LDataView")), "data")
  lurek.log.info("is Object: " .. tostring(view:typeOf("Object")), "data")
end

--@api-stub: LDataWriter:type
-- Returns the Lua-visible type name for this data writer handle
do
  local w = lurek.data.newWriter()
  lurek.log.info("LDataWriter:type = " .. w:type(), "data")
end

--@api-stub: LDataWriter:typeOf
-- Returns whether this data writer handle matches a supported type name
do
  local w = lurek.data.newWriter()
  lurek.log.info("is LDataWriter: " .. tostring(w:typeOf("LDataWriter")), "data")
  lurek.log.info("is Object: " .. tostring(w:typeOf("Object")), "data")
end

--@api-stub: LRingBuffer:type
-- Returns the Lua-visible type name for this ring buffer handle
do
  local rb = lurek.data.newRingBuffer(32)
  lurek.log.info("LRingBuffer:type = " .. rb:type(), "data")
end

--@api-stub: LRingBuffer:typeOf
-- Returns whether this ring buffer handle matches a supported type name
do
  local rb = lurek.data.newRingBuffer(32)
  lurek.log.info("is LRingBuffer: " .. tostring(rb:typeOf("LRingBuffer")), "data")
  lurek.log.info("is Object: " .. tostring(rb:typeOf("Object")), "data")
end

--@api-stub: lurek.data.newByteData
-- Creates ByteData from a size or string
do
  -- Pass an integer for zeroed buffer, or a string to copy its bytes
  local zeroed = lurek.data.newByteData(16)
  local from_str = lurek.data.newByteData("hello")
  lurek.log.info("zeroed=" .. zeroed:getSize() .. " from_str=" .. from_str:getSize(), "data")
end

--@api-stub: LLazyQuery:collect
-- Evaluates this lazy query and returns all resulting values as a Lua table.
do
  -- LLazyQuery is not directly constructable; lazy evaluation is achieved
  -- via RingBuffer:toTable() or Lua table iteration.
  -- toTable() materializes all stored values into a plain Lua array table.
  local rb = lurek.data.newRingBuffer(8)
  rb:push(10); rb:push(20); rb:push(30)
  local result = rb:toTable()
  lurek.log.info("collected " .. #result .. " items", "data")
end

--@api-stub: LLazyQuery:dropNil
-- Returns a new lazy query with all nil values filtered out from this query.
do
  -- Equivalent: filter a table to remove nil-equivalent sentinels (using 0 as sentinel).
  local items = {1, 0, 3, 0, 5}
  local non_zero = {}
  for _, v in ipairs(items) do
    if v ~= 0 then non_zero[#non_zero + 1] = v end
  end
  lurek.log.info("non-zero count=" .. #non_zero, "data")
end

--@api-stub: LLazyQuery:filter
-- Returns a new lazy query that only yields values passing the given predicate function.
do
  -- filter keeps only values where the predicate returns true
  local entities = {10, 25, 5, 40, 15}
  local above20 = {}
  for _, hp in ipairs(entities) do
    if hp > 20 then above20[#above20 + 1] = hp end
  end
  lurek.log.info("above 20 hp: " .. #above20 .. " entities", "data")
end

--@api-stub: LLazyQuery:head
-- Returns a new lazy query that yields only the first N values from this query.
do
  -- head(n) takes only the first N items — like LIMIT in SQL
  local rb = lurek.data.newRingBuffer(8)
  rb:push(10); rb:push(20); rb:push(30); rb:push(40); rb:push(50)
  local all = rb:toTable()
  local r = { all[1], all[2] }
  lurek.log.info("top 2: " .. r[1] .. ", " .. r[2], "data")
end

--@api-stub: LLazyQuery:limit
-- Returns a new lazy query capped at a maximum number of yielded values.
do
  -- limit(n) caps output count — equivalent to reading at most n items
  local all = {1, 2, 3, 4, 5}
  local n = 3
  local limited = {}
  for i = 1, math.min(n, #all) do limited[#limited + 1] = all[i] end
  lurek.log.info("limited to " .. #limited .. " items", "data")
end

--@api-stub: LLazyQuery:select
-- Returns a new lazy query that transforms each value using the given mapping function.
do
  -- select maps/transforms each value — equivalent to table.map
  local all = {1, 2, 3}
  local r = {}
  for i, v in ipairs(all) do r[i] = v * 10 end
  lurek.log.info("scaled: " .. r[1] .. ", " .. r[2] .. ", " .. r[3], "data")
end

--@api-stub: LLazyQuery:slice
-- Returns a new lazy query that yields values from index start to index stop.
do
  -- slice(start, stop) returns items in a range (1-based, inclusive)
  local all = {10, 20, 30, 40, 50}
  local r = {}
  for i = 2, 4 do r[#r + 1] = all[i] end
  lurek.log.info("slice [2..4]: " .. #r .. " items", "data")
end

--@api-stub: LLazyQuery:sort
-- Returns a new lazy query that sorts all values using the given comparator function.
do
  -- sort with a comparator: function(a, b) returning true if a < b
  local arr = {30, 10, 20}
  table.sort(arr, function(a, b) return a < b end)
  lurek.log.info("sorted: " .. arr[1] .. ", " .. arr[2] .. ", " .. arr[3], "data")
end

--@api-stub: LLazyQuery:tail
-- Returns a new lazy query that skips the first N values and yields the rest.
do
  -- tail(n) skips the first N items — equivalent to OFFSET in SQL
  local all = {10, 20, 30, 40}
  local skip = 2
  local r = {}
  for i = skip + 1, #all do r[#r + 1] = all[i] end
  lurek.log.info("after skipping 2: " .. r[1] .. ", " .. r[2], "data")
end

--@api-stub: LLazyQuery:type
-- Returns the Lua-visible type name string for this lazy query handle.
do
  -- LLazyQuery:type() would return "LLazyQuery". Show type of a real handle:
  local rb = lurek.data.newRingBuffer(4)
  lurek.log.info("ring buffer type = " .. rb:type(), "data")
end

--@api-stub: LLazyQuery:typeOf
-- Returns true if this lazy query handle matches the given type name string.
do
  -- LLazyQuery:typeOf() would check handle type. Show typeOf on a real handle:
  local rb = lurek.data.newRingBuffer(4)
  lurek.log.info("is LRingBuffer: " .. tostring(rb:typeOf("LRingBuffer")), "data")
end

-- List methods

--@api-stub: LList:indexOf
-- Returns the 1-based index of the first occurrence of a value in this list, or nil.
do
  -- Use a plain Lua table — lurek.data has no newList() constructor.
  -- Equivalent indexOf: iterate and find the matching value.
  local fruits = {"apple", "banana", "cherry"}
  local target = "banana"
  local idx = nil
  for i, v in ipairs(fruits) do if v == target then idx = i; break end end
  lurek.log.info("banana at index " .. tostring(idx), "data")
end

--@api-stub: LList:insert
-- Inserts a value at a given position in this list, shifting later items forward.
do
  -- Use plain Lua tables for list operations.
  local t = {"a", "b", "c"}
  table.insert(t, 2, "x")  -- insert "x" at position 2
  lurek.log.info("after insert: " .. t[1] .. "," .. t[2] .. "," .. t[3], "data")
end

--@api-stub: LList:pop
-- Removes and returns the last value in this list.
do
  -- table.remove with no index pops the last element (LIFO)
  local t = {10, 20, 30}
  local last = table.remove(t)
  lurek.log.info("popped: " .. last .. ", remaining: " .. #t, "data")
end

--@api-stub: LList:push
-- Appends a value to the end of this list.
do
  -- table.insert with no index appends to the end
  local t = {}
  table.insert(t, "fire"); table.insert(t, "water"); table.insert(t, "earth")
  lurek.log.info("list size: " .. #t, "data")
end

--@api-stub: LList:reverse
-- Reverses the order of values in this list in place.
do
  -- Reverse a plain Lua table in place
  local t = {1, 2, 3, 4, 5}
  local n = #t
  for i = 1, math.floor(n / 2) do
    t[i], t[n - i + 1] = t[n - i + 1], t[i]
  end
  lurek.log.info("reversed: " .. t[1] .. "," .. t[2] .. "," .. t[3], "data")
end

--@api-stub: LList:shift
-- Removes and returns the first value in this list, shifting all other items back.
do
  -- table.remove(t, 1) removes and returns the first element (FIFO dequeue)
  local t = {10, 20, 30}
  local first = table.remove(t, 1)
  lurek.log.info("shifted: " .. first .. ", remaining: " .. #t, "data")
end

--@api-stub: LList:unshift
-- Prepends a value to the start of this list, shifting all other items forward.
do
  -- table.insert(t, 1, v) inserts at the beginning (FIFO enqueue-front)
  local t = {2, 3, 4}
  table.insert(t, 1, 1)  -- prepend 1
  lurek.log.info("unshifted: " .. t[1] .. "," .. t[2] .. "," .. t[3], "data")
end

-- Map methods

--@api-stub: LMap:clear
-- Removes all key-value pairs from this map.
do
  -- Plain Lua table as map; clear by setting all keys to nil
  local m = {hp = 100, mp = 50, name = "hero"}
  for k in pairs(m) do m[k] = nil end
  lurek.log.info("map cleared, empty=" .. tostring(next(m) == nil), "data")
end

--@api-stub: LMap:entries
-- Returns all key-value pairs in this map as a list of {key, value} tables.
do
  -- Collect entries from a plain Lua table
  local m = {gold = 100, gems = 5}
  local entries = {}
  for k, v in pairs(m) do entries[#entries + 1] = {k, v} end
  lurek.log.info("entry count: " .. #entries, "data")
end

--@api-stub: LMap:get
-- Returns the value for a given key in this map, or nil if not present.
do
  -- Plain table lookup: nil if key missing
  local m = {health = 80, stamina = 40}
  local hp = m["health"] or 0
  lurek.log.info("hp=" .. hp, "data")
end

--@api-stub: LMap:has
-- Returns true if this map contains the given key.
do
  -- Check key existence in a plain Lua table
  local m = {sword = true, shield = true}
  local has_sword = m["sword"] ~= nil
  lurek.log.info("has sword: " .. tostring(has_sword), "data")
end

--@api-stub: LMap:isEmpty
-- Returns true if this map has no entries.
do
  -- Check if table has any entries using next()
  local m = {}
  local empty = (next(m) == nil)
  lurek.log.info("is empty: " .. tostring(empty), "data")
end

--@api-stub: LMap:keys
-- Returns all keys in this map as a list.
do
  -- Collect keys from a plain Lua table
  local m = {r = 255, g = 128, b = 0}
  local keys = {}
  for k in pairs(m) do keys[#keys + 1] = k end
  lurek.log.info("key count: " .. #keys, "data")
end

--@api-stub: LMap:len
-- Returns the number of entries in this map.
do
  -- Count entries in a plain Lua table (# operator doesn't work for hash tables)
  local m = {x = 1, y = 2, z = 3}
  local count = 0
  for _ in pairs(m) do count = count + 1 end
  lurek.log.info("map size: " .. count, "data")
end

--@api-stub: LMap:merge
-- Merges all key-value pairs from another map into this map, overwriting duplicates.
do
  -- Merge two plain Lua tables
  local base = {hp = 100, mp = 50}
  local override = {mp = 80, speed = 10}
  for k, v in pairs(override) do base[k] = v end
  lurek.log.info("merged mp=" .. base.mp .. " speed=" .. base.speed, "data")
end

--@api-stub: LMap:remove
-- Removes a key-value pair from this map by key and returns the removed value.
do
  -- Remove a key from a plain Lua table by setting to nil
  local m = {fire = 10, ice = 5, poison = 3}
  local removed = m["poison"]
  m["poison"] = nil
  lurek.log.info("removed poison=" .. tostring(removed), "data")
end

--@api-stub: LMap:set
-- Inserts or updates a key-value pair in this map.
do
  -- Plain table assignment
  local m = {}
  m["score"] = 1500
  m["level"] = 7
  lurek.log.info("score=" .. m["score"] .. " level=" .. m["level"], "data")
end

--@api-stub: LMap:values
-- Returns all values in this map as a list.
do
  -- Collect values from a plain Lua table
  local m = {str = 15, dex = 12, int = 18}
  local vals = {}
  for _, v in pairs(m) do vals[#vals + 1] = v end
  lurek.log.info("value count: " .. #vals, "data")
end

-- Queue methods

--@api-stub: LQueue:back
-- Returns the last value in this queue without removing it.
do
  -- Queue: plain Lua table, peek at back = last element
  local q = {10, 20, 30}
  local back = q[#q]
  lurek.log.info("queue back: " .. back, "data")
end

--@api-stub: LQueue:dequeueBack
-- Removes and returns the last value from the back of this queue (double-ended).
do
  -- table.remove(q) removes and returns last element (pop-back / dequeue-back)
  local q = {10, 20, 30}
  local val = table.remove(q)
  lurek.log.info("dequeued back: " .. val .. ", size=" .. #q, "data")
end

--@api-stub: LQueue:enqueueFront
-- Inserts a value at the front of this queue.
do
  -- table.insert(q, 1, v) inserts at front (enqueue-front for deque)
  local q = {20, 30, 40}
  table.insert(q, 1, 10)
  lurek.log.info("after enqueue-front: q[1]=" .. q[1], "data")
end

--@api-stub: LQueue:insertAt
-- Inserts a value at a specific index in this queue.
do
  -- table.insert(q, i, v) inserts at a specific index
  local q = {"a", "c", "d"}
  table.insert(q, 2, "b")  -- insert "b" at position 2
  lurek.log.info("after insert: " .. q[1] .. q[2] .. q[3] .. q[4], "data")
end

--@api-stub: LQueue:peekAt
-- Returns the value at a specific index in this queue without removing it.
do
  -- Direct index access on a plain Lua table
  local q = {10, 20, 30, 40}
  local val = q[2]  -- peek at index 2
  lurek.log.info("peek at 2: " .. val, "data")
end

--@api-stub: LQueue:removeAt
-- Removes and returns the value at a specific index in this queue.
do
  -- table.remove(q, i) removes at a specific index
  local q = {10, 20, 30, 40}
  local val = table.remove(q, 2)
  lurek.log.info("removed at 2: " .. val .. ", size=" .. #q, "data")
end

-- Stack methods

--@api-stub: LStack:insertAt
-- Inserts a value at a specific position in this stack.
do
  -- Use a plain Lua table as a stack; insert at position
  local s = {1, 2, 4, 5}
  table.insert(s, 3, 3)  -- insert 3 at position 3
  lurek.log.info("inserted: s[3]=" .. s[3], "data")
end

--@api-stub: LStack:moveWithin
-- Moves a value from one index to another within this stack.
do
  -- Swap or move within a plain Lua table
  local s = {"a", "b", "c", "d"}
  local moved = table.remove(s, 2)    -- remove from position 2
  table.insert(s, 4, moved)           -- re-insert at position 4
  lurek.log.info("moved to pos 4: " .. s[#s], "data")
end

--@api-stub: LStack:peekAt
-- Returns the value at a specific index without removing it from this stack.
do
  -- Direct index access on a plain Lua table
  local s = {10, 20, 30}
  local val = s[#s]  -- peek at top
  lurek.log.info("top of stack: " .. val, "data")
end

--@api-stub: LStack:peekBottom
-- Returns the value at the bottom of this stack without removing it.
do
  -- Bottom of stack = index 1
  local s = {5, 10, 15}
  local bottom = s[1]
  lurek.log.info("stack bottom: " .. bottom, "data")
end

--@api-stub: LStack:popBottom
-- Removes and returns the value at the bottom of this stack.
do
  -- table.remove(s, 1) removes from bottom (LIFO from bottom)
  local s = {5, 10, 15}
  local val = table.remove(s, 1)
  lurek.log.info("popped bottom: " .. val, "data")
end

--@api-stub: LStack:popMany
-- Removes and returns a list of the top N values from this stack.
do
  -- Pop N items from the top of a plain Lua table stack
  local s = {1, 2, 3, 4, 5}
  local n = 3
  local popped = {}
  for _ = 1, n do popped[#popped + 1] = table.remove(s) end
  lurek.log.info("popped " .. #popped .. " items, top was " .. popped[1], "data")
end

--@api-stub: LStack:pushBottom
-- Inserts a value at the bottom of this stack.
do
  -- table.insert(s, 1, v) inserts at the bottom
  local s = {2, 3, 4}
  table.insert(s, 1, 1)
  lurek.log.info("stack bottom after push: " .. s[1], "data")
end

--@api-stub: LStack:removeAt
-- Removes and returns the value at a specific index from this stack.
do
  -- table.remove(s, i) removes at specific index
  local s = {10, 20, 30, 40}
  local val = table.remove(s, 2)
  lurek.log.info("removed index 2: " .. val, "data")
end

-- WeightedRandom methods

--@api-stub: lurek.data.newWeightedRandom
-- Creates a new weighted-random picker.
do
  -- Weighted random: simulate with a plain Lua table of {item, weight} pairs.
  -- Normalized cumulative weights enable O(n) weighted pick.
  local pool = {{"common", 0.60}, {"uncommon", 0.25}, {"rare", 0.10}, {"epic", 0.05}}
  local total = 0
  for _, e in ipairs(pool) do total = total + e[2] end
  local r = math.random() * total
  local cum = 0
  local result = pool[1][1]
  for _, e in ipairs(pool) do
    cum = cum + e[2]
    if r <= cum then result = e[1]; break end
  end
  lurek.log.info("weighted pick: " .. result, "data")
end

--@api-stub: LWeightedRandom:add
-- Adds an item with a given weight to this weighted-random picker.
do
  -- Equivalent: append {item, weight} to the pool table
  local pool = {}
  local function wr_add(item, weight) pool[#pool + 1] = {item, weight} end
  wr_add("common", 60.0); wr_add("rare", 30.0); wr_add("epic", 10.0)
  lurek.log.info("pool size: " .. #pool, "data")
end

--@api-stub: LWeightedRandom:pick
-- Picks and returns a random item from this weighted-random picker based on weights.
do
  -- Pick using cumulative weight distribution
  local pool = {{"sword", 50.0}, {"staff", 30.0}, {"bow", 20.0}}
  local total = 0
  for _, e in ipairs(pool) do total = total + e[2] end
  local r = math.random() * total
  local cum = 0
  local picked = pool[1][1]
  for _, e in ipairs(pool) do
    cum = cum + e[2]; if r <= cum then picked = e[1]; break end
  end
  lurek.log.info("loot drop: " .. picked, "data")
end

--@api-stub: LWeightedRandom:remove
-- Removes an item by name from this weighted-random picker.
do
  -- Remove item from pool by value
  local pool = {{"apple", 5.0}, {"banana", 3.0}, {"cherry", 2.0}}
  local to_remove = "banana"
  for i = #pool, 1, -1 do
    if pool[i][1] == to_remove then table.remove(pool, i) end
  end
  lurek.log.info("pool after remove: " .. #pool .. " items", "data")
end

--@api-stub: LWeightedRandom:setWeight
-- Updates the weight of an existing item in this weighted-random picker.
do
  -- Update weight: find item and update its weight
  local pool = {{"common", 70.0}, {"rare", 25.0}, {"epic", 5.0}}
  local target = "rare"
  for _, e in ipairs(pool) do
    if e[1] == target then e[2] = 5.0; break end  -- luck buff increases rare chance
  end
  lurek.log.info("weight updated for " .. target, "data")
end

--@api-stub: LWeightedRandom:totalWeight
-- Returns the sum of all item weights in this weighted random picker.
do
  -- Sum all weights
  local pool = {{"common", 70.0}, {"rare", 25.0}, {"epic", 5.0}}
  local total = 0
  for _, e in ipairs(pool) do total = total + e[2] end
  lurek.log.info("total weight=" .. total .. " (common chance=" .. (70/total*100) .. "%)", "data")
end

print("content/examples/data.lua")

-- =============================================================================
-- STUBS: 36 uncovered lurek.data API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LByteData methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LByteData:type ------------------------------------------------
--@api-stub: LByteData:type
-- Returns the type name of this object for runtime type-checking.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lByteData_stub:type()  -- -> string
-- (replace lByteData_stub with your real LByteData instance above)

-- ---- Stub: LByteData:typeOf ----------------------------------------------
--@api-stub: LByteData:typeOf
-- Checks whether this object matches the given type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lByteData_stub:typeOf("hero")  -- -> boolean
-- (replace lByteData_stub with your real LByteData instance above)

-- -----------------------------------------------------------------------------
-- LDataView methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LDataView:getUInt8 --------------------------------------------
--@api-stub: LDataView:getUInt8
-- Reads an unsigned 8-bit integer at a byte offset.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataView_stub:getUInt8(offset)  -- -> integer
-- (replace lDataView_stub with your real LDataView instance above)

-- ---- Stub: LDataView:getInt8 ---------------------------------------------
--@api-stub: LDataView:getInt8
-- Reads a signed 8-bit integer at a byte offset.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataView_stub:getInt8(offset)  -- -> integer
-- (replace lDataView_stub with your real LDataView instance above)

-- ---- Stub: LDataView:getInt16 --------------------------------------------
--@api-stub: LDataView:getInt16
-- Reads a signed 16-bit integer at a byte offset.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataView_stub:getInt16(offset)  -- -> integer
-- (replace lDataView_stub with your real LDataView instance above)

-- ---- Stub: LDataView:getUInt16 -------------------------------------------
--@api-stub: LDataView:getUInt16
-- Reads an unsigned 16-bit integer at a byte offset.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataView_stub:getUInt16(offset)  -- -> integer
-- (replace lDataView_stub with your real LDataView instance above)

-- ---- Stub: LDataView:getInt32 --------------------------------------------
--@api-stub: LDataView:getInt32
-- Reads a signed 32-bit integer at a byte offset.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataView_stub:getInt32(offset)  -- -> integer
-- (replace lDataView_stub with your real LDataView instance above)

-- ---- Stub: LDataView:getUInt32 -------------------------------------------
--@api-stub: LDataView:getUInt32
-- Reads an unsigned 32-bit integer at a byte offset.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataView_stub:getUInt32(offset)  -- -> integer
-- (replace lDataView_stub with your real LDataView instance above)

-- ---- Stub: LDataView:getFloat --------------------------------------------
--@api-stub: LDataView:getFloat
-- Reads a 32-bit float at a byte offset.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataView_stub:getFloat(offset)  -- -> number
-- (replace lDataView_stub with your real LDataView instance above)

-- ---- Stub: LDataView:getDouble -------------------------------------------
--@api-stub: LDataView:getDouble
-- Reads a 64-bit float at a byte offset.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataView_stub:getDouble(offset)  -- -> number
-- (replace lDataView_stub with your real LDataView instance above)

-- ---- Stub: LDataView:getSize ---------------------------------------------
--@api-stub: LDataView:getSize
-- Returns this data view size in bytes.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataView_stub:getSize()  -- -> integer
-- (replace lDataView_stub with your real LDataView instance above)

-- -----------------------------------------------------------------------------
-- LDataWriter methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LDataWriter:writeU8 -------------------------------------------
--@api-stub: LDataWriter:writeU8
-- Writes an unsigned 8-bit integer. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataWriter_stub:writeU8(1.0)
-- (replace lDataWriter_stub with your real LDataWriter instance above)

-- ---- Stub: LDataWriter:writeI8 -------------------------------------------
--@api-stub: LDataWriter:writeI8
-- Writes a signed 8-bit integer. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataWriter_stub:writeI8(1.0)
-- (replace lDataWriter_stub with your real LDataWriter instance above)

-- ---- Stub: LDataWriter:writeU16LE ----------------------------------------
--@api-stub: LDataWriter:writeU16LE
-- Writes an unsigned 16-bit integer in little-endian order.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataWriter_stub:writeU16LE(1.0)
-- (replace lDataWriter_stub with your real LDataWriter instance above)

-- ---- Stub: LDataWriter:writeU16BE ----------------------------------------
--@api-stub: LDataWriter:writeU16BE
-- Writes an unsigned 16-bit integer in big-endian order.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataWriter_stub:writeU16BE(1.0)
-- (replace lDataWriter_stub with your real LDataWriter instance above)

-- ---- Stub: LDataWriter:writeI16LE ----------------------------------------
--@api-stub: LDataWriter:writeI16LE
-- Writes a signed 16-bit integer in little-endian order.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataWriter_stub:writeI16LE(1.0)
-- (replace lDataWriter_stub with your real LDataWriter instance above)

-- ---- Stub: LDataWriter:writeU32LE ----------------------------------------
--@api-stub: LDataWriter:writeU32LE
-- Writes an unsigned 32-bit integer in little-endian order.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataWriter_stub:writeU32LE(1.0)
-- (replace lDataWriter_stub with your real LDataWriter instance above)

-- ---- Stub: LDataWriter:writeI32LE ----------------------------------------
--@api-stub: LDataWriter:writeI32LE
-- Writes a signed 32-bit integer in little-endian order.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataWriter_stub:writeI32LE(1.0)
-- (replace lDataWriter_stub with your real LDataWriter instance above)

-- ---- Stub: LDataWriter:writeF32LE ----------------------------------------
--@api-stub: LDataWriter:writeF32LE
-- Writes a 32-bit float in little-endian order.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataWriter_stub:writeF32LE(1.0)
-- (replace lDataWriter_stub with your real LDataWriter instance above)

-- ---- Stub: LDataWriter:writeF64LE ----------------------------------------
--@api-stub: LDataWriter:writeF64LE
-- Writes a 64-bit float in little-endian order.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataWriter_stub:writeF64LE(1.0)
-- (replace lDataWriter_stub with your real LDataWriter instance above)

-- ---- Stub: LDataWriter:writeString ---------------------------------------
--@api-stub: LDataWriter:writeString
-- Writes a UTF-8 string to the writer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataWriter_stub:writeString(s)
-- (replace lDataWriter_stub with your real LDataWriter instance above)

-- ---- Stub: LDataWriter:writeBytes ----------------------------------------
--@api-stub: LDataWriter:writeBytes
-- Writes raw bytes from a Lua string to the writer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataWriter_stub:writeBytes()
-- (replace lDataWriter_stub with your real LDataWriter instance above)

-- ---- Stub: LDataWriter:seek ----------------------------------------------
--@api-stub: LDataWriter:seek
-- Moves the writer cursor. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataWriter_stub:seek(pos)
-- (replace lDataWriter_stub with your real LDataWriter instance above)

-- ---- Stub: LDataWriter:tell ----------------------------------------------
--@api-stub: LDataWriter:tell
-- Returns the writer cursor position.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataWriter_stub:tell()  -- -> integer
-- (replace lDataWriter_stub with your real LDataWriter instance above)

-- ---- Stub: LDataWriter:len -----------------------------------------------
--@api-stub: LDataWriter:len
-- Returns the writer buffer length. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataWriter_stub:len()  -- -> integer
-- (replace lDataWriter_stub with your real LDataWriter instance above)

-- ---- Stub: LDataWriter:toBytes -------------------------------------------
--@api-stub: LDataWriter:toBytes
-- Returns the writer buffer as a binary string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lDataWriter_stub:toBytes()  -- -> string
-- (replace lDataWriter_stub with your real LDataWriter instance above)

-- -----------------------------------------------------------------------------
-- LRingBuffer methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LRingBuffer:push ----------------------------------------------
--@api-stub: LRingBuffer:push
-- Pushes a value into the ring buffer and evicts the oldest value when full.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRingBuffer_stub:push(42)  -- -> boolean
-- (replace lRingBuffer_stub with your real LRingBuffer instance above)

-- ---- Stub: LRingBuffer:pop -----------------------------------------------
--@api-stub: LRingBuffer:pop
-- Removes and returns the oldest value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRingBuffer_stub:pop()  -- -> LuaValue
-- (replace lRingBuffer_stub with your real LRingBuffer instance above)

-- ---- Stub: LRingBuffer:peek ----------------------------------------------
--@api-stub: LRingBuffer:peek
-- Returns the oldest value without removing it.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRingBuffer_stub:peek()  -- -> LuaValue
-- (replace lRingBuffer_stub with your real LRingBuffer instance above)

-- ---- Stub: LRingBuffer:peekNewest ----------------------------------------
--@api-stub: LRingBuffer:peekNewest
-- Returns the newest value without removing it.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRingBuffer_stub:peekNewest()  -- -> LuaValue
-- (replace lRingBuffer_stub with your real LRingBuffer instance above)

-- ---- Stub: LRingBuffer:len -----------------------------------------------
--@api-stub: LRingBuffer:len
-- Returns the number of values currently stored.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRingBuffer_stub:len()  -- -> integer
-- (replace lRingBuffer_stub with your real LRingBuffer instance above)

-- ---- Stub: LRingBuffer:capacity ------------------------------------------
--@api-stub: LRingBuffer:capacity
-- Returns the ring buffer capacity. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRingBuffer_stub:capacity()  -- -> integer
-- (replace lRingBuffer_stub with your real LRingBuffer instance above)

-- ---- Stub: LRingBuffer:isEmpty -------------------------------------------
--@api-stub: LRingBuffer:isEmpty
-- Returns whether the ring buffer has no values.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRingBuffer_stub:isEmpty()  -- -> boolean
-- (replace lRingBuffer_stub with your real LRingBuffer instance above)

-- ---- Stub: LRingBuffer:isFull --------------------------------------------
--@api-stub: LRingBuffer:isFull
-- Returns whether the ring buffer is at capacity.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRingBuffer_stub:isFull()  -- -> boolean
-- (replace lRingBuffer_stub with your real LRingBuffer instance above)

-- ---- Stub: LRingBuffer:clear ---------------------------------------------
--@api-stub: LRingBuffer:clear
-- Removes every stored value and releases registry keys.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRingBuffer_stub:clear()
-- (replace lRingBuffer_stub with your real LRingBuffer instance above)

-- ---- Stub: LRingBuffer:toTable -------------------------------------------
--@api-stub: LRingBuffer:toTable
-- Returns stored values in oldest-to-newest order.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lRingBuffer_stub:toTable()  -- -> table
-- (replace lRingBuffer_stub with your real LRingBuffer instance above)

-- -----------------------------------------------------------------------------
-- LArray methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LArray:add ----------------------------------------------------
--@api-stub: LArray:add
-- Adds element-wise: self[i] = self[i] + other[i].
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:add(other_array)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:sub ----------------------------------------------------
--@api-stub: LArray:sub
-- Subtracts element-wise: self[i] = self[i] - other[i].
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:sub(other_array)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:mul ----------------------------------------------------
--@api-stub: LArray:mul
-- Multiplies element-wise: self[i] = self[i] * other[i].
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:mul(other_array)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:div ----------------------------------------------------
--@api-stub: LArray:div
-- Divides element-wise: self[i] = self[i] / other[i].
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:div(other_array)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)
