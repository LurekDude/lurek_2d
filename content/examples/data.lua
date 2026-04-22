-- content/examples/data.lua
-- Hand-written coverage of the lurek.data API (57 items).
--
-- The lurek.data namespace bundles binary serialisation (pack /
-- write / DataView / DataWriter / ByteData), text codecs (encode /
-- decode / hash / crc32), compression (deflate / gzip / lz4),
-- TOML and MessagePack converters, plus a fixed-capacity ring
-- buffer. All byte payloads are exchanged as plain Lua strings.
--
-- Run: cargo run -- content/examples/data.lua

-- ── lurek.data.* functions ──

--@api-stub: lurek.data.pack
-- Packs values into a binary byte string using the format string.
-- Format chars: b/B i8/u8, h/H i16/u16, i/I i32/u32, f/d float, s len-prefixed string, < / > endian.
do  -- lurek.data.pack
  local header = lurek.data.pack("<HHs", 1, 0, "lurek-save")
  lurek.log.info("packed save header: " .. #header .. " bytes", "data")
end

--@api-stub: lurek.data.unpack
-- Unpacks values from a binary byte string, returning values followed by next offset.
-- The trailing integer return is the byte offset just past the consumed data — feed it back as `offset` to chain reads.
do  -- lurek.data.unpack
  local blob = lurek.data.pack("<II", 42, 7)
  local hp, mana, next_off = lurek.data.unpack("<II", blob, 0)
  lurek.log.info("hp=" .. hp .. " mana=" .. mana .. " consumed=" .. next_off, "data")
end

--@api-stub: lurek.data.getPackedSize
-- Returns the number of bytes the given format and values would occupy.
-- Use to pre-allocate save-file buffers or to validate that a fixed-size record matches a struct layout before writing.
do  -- lurek.data.getPackedSize
  local size = lurek.data.getPackedSize("<IIff", 0, 0, 0, 0)
  if size ~= 16 then
    lurek.log.warn("entity record size drifted: " .. size, "data")
  end
end

--@api-stub: lurek.data.compress
-- Compresses data using the given algorithm (deflate, gzip, lz4).
-- Pick "lz4" for fast in-memory caches, "gzip" for shipping archives, "deflate" for embedded payloads.
do  -- lurek.data.compress
  local raw = string.rep("level_data ", 256)
  local packed = lurek.data.compress("lz4", raw)
  lurek.log.info("compressed " .. #raw .. " -> " .. #packed .. " bytes", "data")
end

--@api-stub: lurek.data.decompress
-- Decompresses data using the given algorithm (deflate, gzip, lz4).
-- Always pair with the same algorithm used at compress time; mismatched formats raise a runtime error.
do  -- lurek.data.decompress
  local packed = lurek.data.compress("gzip", "tilemap_payload")
  local raw = lurek.data.decompress("gzip", packed)
  lurek.log.info("round-trip ok: " .. raw, "data")
end

--@api-stub: lurek.data.encode
-- Encodes binary data using the given format (base64, hex).
-- Use "base64" for embedding bytes in JSON / TOML / network text, "hex" for hashes and debug logs.
do  -- lurek.data.encode
  local key = lurek.data.pack("<I", 0xCAFEF00D)
  local hex = lurek.data.encode("hex", key)
  local b64 = lurek.data.encode("base64", key)
  lurek.log.info("hex=" .. hex .. " b64=" .. b64, "data")
end

--@api-stub: lurek.data.decode
-- Decodes encoded text back to binary (base64, hex).
-- Decoded output is a binary Lua string — feed straight into newDataView, unpack, or fromMsgPack.
do  -- lurek.data.decode
  local b64 = lurek.data.encode("base64", "lurek")
  local raw = lurek.data.decode("base64", b64)
  lurek.log.info("decoded back to: '" .. raw .. "'", "data")
end

--@api-stub: lurek.data.hash
-- Returns the cryptographic hash of the input (md5, sha1, sha256, sha512).
-- Default return is raw bytes; wrap with encode("hex", …) for printable digests in logs or save-file footers.
do  -- lurek.data.hash
  local digest = lurek.data.encode("hex", lurek.data.hash("sha256", "player_save_v3"))
  lurek.log.info("save digest: " .. digest, "data")
end

--@api-stub: lurek.data.crc32
-- Returns the CRC-32 checksum of the input data as an integer.
-- Cheap integrity check for chunk streams or replay frames; not cryptographically safe — use hash() for tamper detection.
do  -- lurek.data.crc32
  local payload = lurek.data.pack("<II", 1024, 768)
  local sum = lurek.data.crc32(payload)
  lurek.log.info(string.format("payload crc32 = 0x%08X", sum), "data")
end

--@api-stub: lurek.data.newDataView
-- Creates a read-only windowed view into a byte string.
-- Cheap alternative to slicing strings; reads are zero-copy and bounds-checked, ideal for parsing fixed binary headers.
do  -- lurek.data.newDataView
  local blob = lurek.data.pack("<HHI", 0xBEEF, 0xCAFE, 12345)
  local view = lurek.data.newDataView(blob, 0, #blob)
  lurek.log.info("view bytes: " .. view:getSize(), "data")
end

--@api-stub: lurek.data.write
-- Writes values using the Lurek2D Binary Pack Format.
-- Tokens are space-separated names (`u32`, `f32`, `str`, …) — easier to read than pack()'s single-char format.
do  -- lurek.data.write
  local record = lurek.data.write("u32 f32 str", 7, 1.5, "goblin")
  lurek.log.info("entity record bytes: " .. #record, "data")
end

--@api-stub: lurek.data.read
-- Reads values using the Lurek2D Binary Pack Format.
-- Pass the same format string used in write(); offset defaults to 0 — useful when scanning past a header.
do  -- lurek.data.read
  local record = lurek.data.write("u16 u16", 800, 600)
  local w, h = lurek.data.read("u16 u16", record, 0)
  lurek.log.info("resolution: " .. w .. "x" .. h, "data")
end

--@api-stub: lurek.data.size
-- Returns the byte size of a Lurek2D Binary Pack Format string.
-- Errors on `str` / `cstr` tokens (length is data-dependent); use only with fully-fixed-width formats.
do  -- lurek.data.size
  local sz = lurek.data.size("u32 f32 f32")
  lurek.log.info("transform record = " .. sz .. " bytes", "data")
end

--@api-stub: lurek.data.parseToml
-- Parses a TOML string into a Lua table.
-- Use for hand-edited config; the returned table mirrors TOML's nesting (`[section] key = …`).
do  -- lurek.data.parseToml
  local cfg = lurek.data.parseToml("[window]\nwidth = 1280\nheight = 720\n")
  lurek.log.info("window=" .. cfg.window.width .. "x" .. cfg.window.height, "data")
end

--@api-stub: lurek.data.encodeToml
-- Encodes a Lua table into a TOML string.
-- Round-trip-safe with parseToml; use for writing user-friendly settings files alongside binary saves.
do  -- lurek.data.encodeToml
  local text = lurek.data.encodeToml({ audio = { master = 0.8, music = 0.6 } })
  lurek.log.info("toml output:\n" .. text, "data")
end

--@api-stub: lurek.data.newRingBuffer
-- Creates a fixed-capacity ring buffer that can store any Lua value.
-- Pushing past capacity overwrites the oldest entry — perfect for frame-time history or recent-input buffers.
do  -- lurek.data.newRingBuffer
  local recent_inputs = lurek.data.newRingBuffer(8)
  recent_inputs:push("jump")
  lurek.log.info("input buffer size=" .. recent_inputs:len(), "data")
end

--@api-stub: lurek.data.toMsgPack
-- Serializes a Lua value (table, string, number, boolean, or nil) to MessagePack binary.
-- Smaller and faster than JSON; ideal for network packets or compact saves consumed by other MessagePack libraries.
do  -- lurek.data.toMsgPack
  local packet = lurek.data.toMsgPack({ kind = "move", x = 32, y = 48 })
  lurek.log.info("msgpack packet size: " .. #packet, "net")
end

--@api-stub: lurek.data.fromMsgPack
-- Deserializes a MessagePack binary string back into a Lua value.
-- Throws on malformed input; treat untrusted bytes as suspect and validate field types before use.
do  -- lurek.data.fromMsgPack
  local packet = lurek.data.toMsgPack({ id = 17, hp = 90 })
  local msg = lurek.data.fromMsgPack(packet)
  lurek.log.info("decoded id=" .. msg.id .. " hp=" .. msg.hp, "net")
end

--@api-stub: lurek.data.newWriter
-- Creates a new write-cursor for building binary data.
-- Preferred over manual `..` concatenation when assembling multi-field records — supports seek/tell for back-patching.
do  -- lurek.data.newWriter
  local w = lurek.data.newWriter()
  w:writeU32LE(0x4C524B32)  -- "LRK2" magic
  w:writeString("save_v1")
  lurek.log.info("header bytes: " .. w:len(), "save")
end

-- ── RingBuffer methods ──

--@api-stub: RingBuffer:push
-- Pushes a value onto the ring buffer.
-- When the buffer is full the oldest element is dropped silently — read len() before pushing if you need to detect that.
do  -- RingBuffer:push
  local frame_times = lurek.data.newRingBuffer(60)
  frame_times:push(0.0166)
  frame_times:push(0.0172)
  lurek.log.info("samples buffered: " .. frame_times:len(), "perf")
end

--@api-stub: RingBuffer:pop
-- Removes and returns the oldest element, or nil if the buffer is empty.
-- FIFO order; pair with push() to use the buffer as a bounded job queue.
do  -- RingBuffer:pop
  local jobs = lurek.data.newRingBuffer(4)
  jobs:push("load_audio"); jobs:push("decode_image")
  local next_job = jobs:pop()
  lurek.log.info("running job: " .. tostring(next_job), "jobs")
end

--@api-stub: RingBuffer:peek
-- Returns the oldest element without removing it, or nil if empty.
-- Use to inspect the head of a queue (e.g. preview the next replay event) without consuming it.
do  -- RingBuffer:peek
  local events = lurek.data.newRingBuffer(8)
  events:push({ t = 0.0, kind = "spawn" })
  local head = events:peek()
  lurek.log.info("next event kind=" .. head.kind, "replay")
end

--@api-stub: RingBuffer:peekNewest
-- Returns the newest element without removing it, or nil if empty.
-- Handy for "most recent input" queries — e.g. checking the last keypress for combo detection.
do  -- RingBuffer:peekNewest
  local recent = lurek.data.newRingBuffer(8)
  recent:push("a"); recent:push("b"); recent:push("c")
  lurek.log.info("last input: " .. tostring(recent:peekNewest()), "input")
end

--@api-stub: RingBuffer:len
-- Returns the number of elements currently in the buffer.
-- Use before peek/pop to avoid nil returns; capped at capacity().
do  -- RingBuffer:len
  local rb = lurek.data.newRingBuffer(4)
  rb:push(1); rb:push(2); rb:push(3)
  if rb:len() >= 3 then lurek.log.info("buffered enough samples", "data") end
end

--@api-stub: RingBuffer:capacity
-- Returns the maximum number of elements the buffer can hold.
-- Constant for the lifetime of the buffer — useful for percent-full diagnostics.
do  -- RingBuffer:capacity
  local rb = lurek.data.newRingBuffer(120)
  rb:push(0.016)
  local pct = (rb:len() / rb:capacity()) * 100
  lurek.log.info(string.format("buffer %.1f%% full", pct), "perf")
end

--@api-stub: RingBuffer:isEmpty
-- Returns true if the buffer contains no elements.
-- Cheaper than len() == 0 in hot loops; idiomatic guard before pop().
do  -- RingBuffer:isEmpty
  local jobs = lurek.data.newRingBuffer(4)
  if jobs:isEmpty() then
    lurek.log.info("no pending jobs this frame", "jobs")
  end
end

--@api-stub: RingBuffer:clear
-- Removes all elements from the buffer, releasing their registry entries.
-- Call on scene transition to release Lua references the buffer is keeping alive.
do  -- RingBuffer:clear
  local trail = lurek.data.newRingBuffer(32)
  for i = 1, 10 do trail:push({ x = i, y = i }) end
  trail:clear()
  lurek.log.info("trail cleared, len=" .. trail:len(), "fx")
end

--@api-stub: RingBuffer:toTable
-- Returns all elements as an array table ordered oldest-first.
-- Use for snapshotting state into a save file or feeding the contents to a Lua `for ipairs` consumer.
do  -- RingBuffer:toTable
  local rb = lurek.data.newRingBuffer(4)
  rb:push("a"); rb:push("b"); rb:push("c")
  local arr = rb:toTable()
  lurek.log.info("ordered: " .. table.concat(arr, ","), "data")
end

-- ── DataView methods ──

--@api-stub: DataView:getUInt8
-- Reads an unsigned 8-bit integer at the given offset.
-- Offsets are 0-based; out-of-range reads raise an error rather than returning garbage.
do  -- DataView:getUInt8
  local view = lurek.data.newDataView(string.char(0x42, 0xFF))
  local first = view:getUInt8(0)
  lurek.log.info("first byte = " .. first, "data")
end

--@api-stub: DataView:getInt8
-- Reads a signed 8-bit integer at the given offset.
-- Two's-complement: 0xFF reads back as -1; pair with getUInt8 if you need unsigned semantics.
do  -- DataView:getInt8
  local view = lurek.data.newDataView(string.char(0xFF, 0x01))
  local v = view:getInt8(0)
  lurek.log.info("signed byte = " .. v, "data")
end

--@api-stub: DataView:getInt16
-- Reads a signed 16-bit integer at the given offset.
-- Endianness follows whatever the underlying buffer uses; default DataView reads are little-endian.
do  -- DataView:getInt16
  local raw = lurek.data.pack("<h", -1234)
  local v = lurek.data.newDataView(raw):getInt16(0)
  lurek.log.info("signed16 = " .. v, "data")
end

--@api-stub: DataView:getUInt16
-- Reads an unsigned 16-bit integer at the given offset.
-- Common for tile IDs, sprite indices, or 16-bit colour channels packed into a binary asset.
do  -- DataView:getUInt16
  local raw = lurek.data.pack("<H", 0xBEEF)
  local v = lurek.data.newDataView(raw):getUInt16(0)
  lurek.log.info(string.format("u16 = 0x%04X", v), "data")
end

--@api-stub: DataView:getInt32
-- Reads a signed 32-bit integer at the given offset.
-- Use for chunk lengths or world coordinates; for unsigned IDs prefer getUInt32 to avoid sign-bit surprises.
do  -- DataView:getInt32
  local raw = lurek.data.pack("<i", -42000)
  local v = lurek.data.newDataView(raw):getInt32(0)
  lurek.log.info("signed32 = " .. v, "data")
end

--@api-stub: DataView:getUInt32
-- Reads an unsigned 32-bit integer at the given offset.
-- Returned as a Lua integer; safe to compare against magic constants like 0x4C524B32.
do  -- DataView:getUInt32
  local raw = lurek.data.pack("<I", 0x4C524B32)
  local magic = lurek.data.newDataView(raw):getUInt32(0)
  if magic == 0x4C524B32 then lurek.log.info("save magic ok", "save") end
end

--@api-stub: DataView:getFloat
-- Reads a 32-bit float at the given offset.
-- Returned as a Lua number (f64-promoted); fine for storing positions, rotations, or normalised colour channels.
do  -- DataView:getFloat
  local raw = lurek.data.pack("<f", 3.14)
  local v = lurek.data.newDataView(raw):getFloat(0)
  lurek.log.info(string.format("f32 = %.4f", v), "data")
end

--@api-stub: DataView:getDouble
-- Reads a 64-bit float at the given offset.
-- Use for high-precision values like timestamps, accumulated game time, or world-space simulation state.
do  -- DataView:getDouble
  local raw = lurek.data.pack("<d", 1.7e9)
  local t = lurek.data.newDataView(raw):getDouble(0)
  lurek.log.info("timestamp = " .. t, "data")
end

--@api-stub: DataView:getSize
-- Returns the size of this view in bytes.
-- Loop bound for streaming readers; the view never extends past this even if the source string is longer.
do  -- DataView:getSize
  local view = lurek.data.newDataView(lurek.data.pack("<III", 1, 2, 3))
  for off = 0, view:getSize() - 4, 4 do
    lurek.log.info("u32 at " .. off .. " = " .. view:getUInt32(off), "data")
  end
end

-- ── DataWriter methods ──

--@api-stub: DataWriter:writeU8
-- Writes an unsigned 8-bit integer.
-- Cursor advances by 1 byte; value must fit in [0, 255] or mlua coerces / errors.
do  -- DataWriter:writeU8
  local w = lurek.data.newWriter()
  w:writeU8(0xAB); w:writeU8(0xCD)
  lurek.log.info("wrote " .. w:len() .. " bytes", "data")
end

--@api-stub: DataWriter:writeI8
-- Writes a signed 8-bit integer.
-- Range [-128, 127]; useful for compact deltas like per-frame velocity tweaks.
do  -- DataWriter:writeI8
  local w = lurek.data.newWriter()
  w:writeI8(-1); w:writeI8(64)
  lurek.log.info("signed bytes len=" .. w:len(), "data")
end

--@api-stub: DataWriter:writeU16LE
-- Writes an unsigned 16-bit LE integer.
-- Standard layout for most binary save formats and network packets in this engine.
do  -- DataWriter:writeU16LE
  local w = lurek.data.newWriter()
  w:writeU16LE(800); w:writeU16LE(600)
  lurek.log.info("resolution record = " .. w:len() .. " bytes", "data")
end

--@api-stub: DataWriter:writeU16BE
-- Writes an unsigned 16-bit BE integer.
-- Use when interoperating with network protocols or file formats that mandate big-endian (PNG chunks, BMP fields).
do  -- DataWriter:writeU16BE
  local w = lurek.data.newWriter()
  w:writeU16BE(0xCAFE)
  lurek.log.info("BE bytes hex = " .. lurek.data.encode("hex", w:toBytes()), "data")
end

--@api-stub: DataWriter:writeI16LE
-- Writes a signed 16-bit LE integer.
-- Range [-32768, 32767]; ideal for tile-grid offsets or audio sample data.
do  -- DataWriter:writeI16LE
  local w = lurek.data.newWriter()
  w:writeI16LE(-15000); w:writeI16LE(15000)
  lurek.log.info("signed16 record = " .. w:len() .. " bytes", "data")
end

--@api-stub: DataWriter:writeU32LE
-- Writes an unsigned 32-bit LE integer.
-- Common for entity IDs, file offsets, and 32-bit colour values (RGBA8).
do  -- DataWriter:writeU32LE
  local w = lurek.data.newWriter()
  w:writeU32LE(0x4C524B32)
  lurek.log.info("magic written, len=" .. w:len(), "save")
end

--@api-stub: DataWriter:writeI32LE
-- Writes a signed 32-bit LE integer.
-- Use for world coordinates that may go negative or for accumulator deltas.
do  -- DataWriter:writeI32LE
  local w = lurek.data.newWriter()
  w:writeI32LE(-1024); w:writeI32LE(2048)
  lurek.log.info("delta record bytes=" .. w:len(), "data")
end

--@api-stub: DataWriter:writeF32LE
-- Writes a 32-bit LE float.
-- Half the size of f64 with enough precision for positions and per-vertex attributes.
do  -- DataWriter:writeF32LE
  local w = lurek.data.newWriter()
  w:writeF32LE(0.5); w:writeF32LE(0.25)
  lurek.log.info("vec2 bytes=" .. w:len(), "data")
end

--@api-stub: DataWriter:writeF64LE
-- Writes a 64-bit LE float.
-- Use for timestamps, simulation time, or any value where f32 rounding would be visible.
do  -- DataWriter:writeF64LE
  local w = lurek.data.newWriter()
  w:writeF64LE(os.time())
  lurek.log.info("timestamp record bytes=" .. w:len(), "save")
end

--@api-stub: DataWriter:writeString
-- Writes a length-prefixed UTF-8 string (4-byte LE length + bytes).
-- Self-describing — pairs with a matching `str` token in lurek.data.read for round-trip parsing.
do  -- DataWriter:writeString
  local w = lurek.data.newWriter()
  w:writeString("player_one")
  lurek.log.info("string record total bytes=" .. w:len(), "save")
end

--@api-stub: DataWriter:writeBytes
-- Writes raw bytes from a Lua string.
-- No length prefix — caller is responsible for tracking the size separately if it needs to be read back.
do  -- DataWriter:writeBytes
  local w = lurek.data.newWriter()
  w:writeBytes(string.char(0x89, 0x50, 0x4E, 0x47))  -- PNG signature
  lurek.log.info("raw bytes hex=" .. lurek.data.encode("hex", w:toBytes()), "data")
end

--@api-stub: DataWriter:seek
-- Moves the write cursor to the given position.
-- Use for back-patching a length or checksum field after writing the payload it covers.
do  -- DataWriter:seek
  local w = lurek.data.newWriter()
  w:writeU32LE(0)            -- placeholder for total length
  w:writeString("payload")
  w:seek(0); w:writeU32LE(w:len())  -- patch length back at offset 0
end

--@api-stub: DataWriter:tell
-- Returns the current write cursor position.
-- Capture before writing a sub-section so you can later seek back and patch a length or offset.
do  -- DataWriter:tell
  local w = lurek.data.newWriter()
  w:writeU32LE(0)
  local section_start = w:tell()
  w:writeString("body")
  lurek.log.info("section started at offset " .. section_start, "data")
end

--@api-stub: DataWriter:len
-- Returns the total buffer length.
-- Differs from tell() only after a seek; len() always reports the high-water mark.
do  -- DataWriter:len
  local w = lurek.data.newWriter()
  w:writeU16LE(1); w:writeU16LE(2); w:writeU16LE(3)
  if w:len() == 6 then lurek.log.info("buffer fully populated", "data") end
end

--@api-stub: DataWriter:toBytes
-- Returns the buffer contents as a Lua string.
-- Call once after all writes are done; the returned string is independent of the writer (safe to keep after GC).
do  -- DataWriter:toBytes
  local w = lurek.data.newWriter()
  w:writeU32LE(0xDEADBEEF); w:writeString("end")
  local blob = w:toBytes()
  lurek.log.info("final blob hex=" .. lurek.data.encode("hex", blob), "data")
end

-- ── mlua methods (ByteData) ──

--@api-stub: mlua:getSize
-- Get the size.
-- ByteData::len in bytes — use to bound loops over getByte / setByte.
do  -- mlua:getSize
  local bd = lurek.data.newByteData("hello")
  lurek.log.info("byte data size = " .. bd:getSize(), "data")
end

--@api-stub: mlua:getString
-- Get the string representation.
-- Returns the underlying bytes as a Lua string — safe to feed straight back into newDataView or hash().
do  -- mlua:getString
  local bd = lurek.data.newByteData("save_v1")
  local digest = lurek.data.encode("hex", lurek.data.hash("md5", bd:getString()))
  lurek.log.info("md5 = " .. digest, "data")
end

--@api-stub: mlua:getByte
-- Get a byte at the specified offset.
-- Offset is 0-based; out-of-bounds raises an error rather than returning nil — guard with getSize() first.
do  -- mlua:getByte
  local bd = lurek.data.newByteData("ABC")
  local first = bd:getByte(0)
  lurek.log.info("first byte (A=65) = " .. first, "data")
end

--@api-stub: mlua:setByte
-- Set a byte at the specified offset.
-- In-place mutation; use to patch a single field without reallocating the whole buffer.
do  -- mlua:setByte
  local bd = lurek.data.newByteData("AAAA")
  bd:setByte(0, 0x42)  -- 'B'
  lurek.log.info("patched: " .. bd:getString(), "data")
end

--@api-stub: mlua:clone
-- Clone the ByteData.
-- Independent copy — mutating the clone via setByte does not touch the original; use before destructive edits.
do  -- mlua:clone
  local original = lurek.data.newByteData("base")
  local copy = original:clone()
  copy:setByte(0, 0x42)
  lurek.log.info("orig=" .. original:getString() .. " copy=" .. copy:getString(), "data")
end
