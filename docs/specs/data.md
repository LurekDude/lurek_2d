# data

## General Info

- Module group: `Foundations`
- Source path: `src/data/`
- Lua API path(s): `src/lua_api/data_api.rs`
- Primary Lua namespace: `lurek.data`
- Rust test path(s): tests/rust/unit/data_tests.rs; tests/rust/stress/data_stress_tests.rs; inline tests in src/data/byte_data.rs, src/data/encode.rs, src/data/hash.rs
- Lua test path(s): tests/lua/unit/test_data_core_unit.lua; tests/lua/stress/test_data_stress.lua; tests/lua/integration/test_data_filesystem.lua; tests/lua/integration/test_data_compute.lua; tests/lua/golden/test_data_golden.lua

## Summary

The `data` module is Lurek2D's binary data manipulation toolkit — a Foundations tier module with no engine dependencies. It provides the low-level building blocks used by game code and engine internals that must work with binary data at the byte level: raw byte buffers, compression, cryptographic hashing, binary encoding/decoding, structured pack/unpack, and ring buffers.

**`ByteData` — the core buffer.** `ByteData` is an owned, heap-allocated raw byte buffer with bounds-checked element access. It is the primary interchange type: network payloads, save-file blobs, compressed data, and hashed content all flow through `ByteData`. Key operations: `new(n)`, `from_slice`, `as_slice`, `get(i)`, `set(i, v)`, `len`, `append`, `split_at`, `concat`. Lua scripts receive `ByteData` userdata with the full method set including `toHex()`, `toBase64()`, `slice(start, len)`.

**Compression.** `compress.rs` wraps deflate, gzip, zlib (via flate2), and LZ4 (via lz4_flex) behind the `CompressFormat` enum. `compress(data, format)` and `decompress(data, format)` remain the primary whole-buffer interfaces. For large payload pipelines, `compress_stream` / `decompress_stream` and `compress_chunks` / `decompress_chunks` add chunked I/O paths that do not require callers to pre-concatenate input bytes.

**Hashing.** `hash.rs` provides `hash(data, algorithm) → ByteData` for MD5, SHA-1, SHA-256, and SHA-512 via the `HashAlgorithm` enum. Output is a fixed-length `ByteData` digest. The Lua surface exposes `lurek.data.hash(bytes, "sha256")` returning a hex string directly.

**Binary encoding.** `encode.rs` provides `encode(data, format)` / `decode(text, format)` for the `EncodeFormat` enum variants: `Base64` and `Hex`. Used for transport-safe representations of binary payloads.

**Pack/unpack.** `pack.rs` implements a LÖVE2D-compatible single-character format string binary packer: `b` (byte), `i`/`I` (signed/unsigned integers in 1/2/4/8 byte widths), `f` (float32), `d` (float64), `s` (length-prefixed string), `z` (null-terminated), `c<n>` (fixed-length bytes). `pack(fmt, values) → ByteData` / `unpack(fmt, data) → table`. Used by network serialisation and persistent save-data encoding for cross-platform compatibility.

**Named-token format.** `bin_pack.rs` implements Lurek2D's own named-token binary format (`u32`, `f64`, `str`, `i16`, with endian modifiers). `BinValue` is the tagged value enum bridging dynamic Lua input to strongly-typed binary writes. Intended for human-readable debug encoding scenarios.

**DataView / DataWriter.** `DataView` is a read-only typed cursor over a byte slice with bounds-checked little-endian typed accessors (no copy). `DataWriter` is the growable write-cursor companion. `LuaDataView` wraps `DataView` as Lua userdata keeping the domain type free of Lua method registration.

**Serial delegation.** Lua-facing `lurek.data.parseToml`, `lurek.data.encodeToml`, `lurek.data.toMsgPack`, and `lurek.data.fromMsgPack` are thin adapters in `src/lua_api/data_api.rs` that delegate parsing/encoding to the `serial` module (`src/serial/toml.rs` and `src/serial/msgpack.rs`).

**Ring buffer.** `RingBuffer<T>` is a generic fixed-capacity circular buffer, useful for input history windows, debug log tails, and time-stamped event queues. Exposes `push`, `pop`, `peek`, `len`, `is_full`, clone-based collection (`to_vec`) and non-cloning access (`iter`, `to_refs`) for large element types.

**Lua surface.** `lurek.data.new(n)` creates a `ByteData`. `lurek.data.compress/decompress(bytes, format)`, `lurek.data.hash(bytes, algo)`, `lurek.data.encode/decode(bytes, format)`, `lurek.data.pack(fmt, ...)`, `lurek.data.unpack(fmt, bytes)`, `lurek.data.newView(bytes)` → `DataView`, `lurek.data.newWriter()` → `DataWriter`. `ByteData` userdata: `get`, `set`, `len`, `append`, `slice`, `toHex`, `toBase64`, `toTable`.

**Note.** Text format parsing (JSON, TOML, CSV) is the responsibility of the `serial` module under `lurek.serial`. `data` covers only binary representations.

**Scope boundary.** Foundations tier. Depends only on external crates: flate2, lz4_flex, sha2, base64, hex. Lua bridge in `src/lua_api/data_api.rs`.

## Files

- `bin_pack.rs`: Implements the Lurek2D-native binary pack format with readable named tokens such as `u32`, `f64`, `str`, and endian modifiers.
- `byte_data.rs`: Defines the owned byte-buffer type used to construct, mutate, clone, and expose raw bytes to Lua.
- `compress.rs`: Provides whole-buffer, stream, and chunked compression/decompression for deflate, gzip, zlib, and LZ4 formats.
- `data_writer.rs`: Write-cursor companion to [`DataView`](super::DataView).
- `dataview.rs`: Implements a read-only typed cursor over shared bytes with bounds-checked little-endian accessors.
- `encode.rs`: Handles base64 and hex encoding and decoding for binary payload transport.
- `hash.rs`: Computes MD5, SHA-1, SHA-256, and SHA-512 digests over in-memory data.
- `mod.rs`: Re-exports the public binary-data surface and keeps callers from importing individual helpers ad hoc.
- `pack.rs`: Implements the LÖVE-style single-character binary pack and unpack format used for compact compatibility-oriented serialization.
- `ring_buffer.rs`: Fixed-capacity circular ring buffer.

## Types

- `BinValue` (`enum`, `bin_pack.rs`): Tagged value enum used by the named-token pack format. It is the bridge between dynamically typed inputs and strongly typed binary writes and reads.
- `ByteData` (`struct`, `byte_data.rs`): Primary owned byte buffer for Lua and Rust interop. It is the mutable container that other helpers serialize into or read from.
- `CompressFormat` (`enum`, `compress.rs`): Supported compression backends for whole-buffer, stream, and chunked compression/decompression. It keeps format parsing and dispatch explicit rather than stringly typed deep in the implementation.
- `DataWriter` (`struct`, `data_writer.rs`): A growable byte buffer with a write cursor.
- `DataView` (`struct`, `dataview.rs`): Read-only window over shared bytes with typed accessors. It exists for cheap inspection of binary payloads without copying or mutating them.
- `LuaDataView` (`struct`, `dataview.rs`): Lua-facing wrapper over `DataView`. Keeping it separate lets the domain type stay free of Lua-specific method registration.
- `EncodeFormat` (`enum`, `encode.rs`): Supported binary-to-text encoding modes. It is the small dispatch enum behind the base64 and hex helpers.
- `HashAlgorithm` (`enum`, `hash.rs`): Supported digest algorithms for byte hashing. It centralizes algorithm parsing so the Lua API and Rust callers use the same accepted names.
- `PackValue` (`enum`, `pack.rs`): Tagged value enum used by the LÖVE-compatible pack format. It preserves the compatibility surface independently from the native `BinValue` format.
- `RingBuffer` (`struct`, `ring_buffer.rs`): A fixed-capacity circular ring buffer.

## Functions

- `write` (`bin_pack.rs`): Write values into a binary buffer according to a Lurek2D format string.
- `read` (`bin_pack.rs`): Read values from a binary buffer according to a Lurek2D format string.
- `measure_size` (`bin_pack.rs`): Compute the total byte size that `write` would produce for the given format string.
- `ByteData::new` (`byte_data.rs`): Create a zero-filled buffer of the given size.
- `ByteData::from_bytes` (`byte_data.rs`): Create from an existing byte vector, taking ownership.
- `ByteData::from_string` (`byte_data.rs`): Create from a UTF-8 string, copying the string’s bytes into the buffer.
- `ByteData::len` (`byte_data.rs`): Get the size of the buffer in bytes.
- `ByteData::is_empty` (`byte_data.rs`): Check if the buffer contains zero bytes.
- `ByteData::get_byte` (`byte_data.rs`): Get a byte at the given offset (0-based).
- `ByteData::set_byte` (`byte_data.rs`): Set a byte at the given offset (0-based).
- `ByteData::get_string` (`byte_data.rs`): Get the data as a lossy UTF-8 string.
- `ByteData::as_bytes` (`byte_data.rs`): Returns a reference to the raw byte slice.
- `ByteData::as_bytes_mut` (`byte_data.rs`): Get a mutable reference to the raw bytes.
- `ByteData::clone_data` (`byte_data.rs`): Clones the internal byte buffer into a new standalone `ByteData` instance.
- `CompressFormat::parse_str` (`compress.rs`): Parse a format name string (case-insensitive).
- `compress` (`compress.rs`): Compress data using the specified format and compression level (0-9).
- `decompress` (`compress.rs`): Decompress data using the specified format.
- `compress_stream` (`compress.rs`): Compresses data from any `Read` source into any `Write` sink.
- `decompress_stream` (`compress.rs`): Decompresses data from any `Read` source into any `Write` sink.
- `compress_chunks` (`compress.rs`): Compresses ordered byte chunks without pre-concatenating input.
- `decompress_chunks` (`compress.rs`): Decompresses ordered compressed chunks back into a contiguous byte vector.
- `DataWriter::new` (`data_writer.rs`): Creates a new empty `DataWriter`.
- `DataWriter::with_capacity` (`data_writer.rs`): Creates a `DataWriter` pre-allocated with `capacity` bytes.
- `DataWriter::tell` (`data_writer.rs`): Returns the current cursor position.
- `DataWriter::len` (`data_writer.rs`): Returns the number of bytes written so far.
- `DataWriter::is_empty` (`data_writer.rs`): Returns `true` if no bytes have been written.
- `DataWriter::seek` (`data_writer.rs`): Moves the write cursor to `pos`.
- `DataWriter::into_bytes` (`data_writer.rs`): Consumes the writer and returns the underlying byte vector.
- `DataWriter::as_bytes` (`data_writer.rs`): Returns a shared reference to the written bytes.
- `DataWriter::write_u8` (`data_writer.rs`): Writes a single byte and advances the cursor.
- `DataWriter::write_i8` (`data_writer.rs`): Writes an `i8` and advances the cursor.
- `DataWriter::write_u16_le` (`data_writer.rs`): Writes a little-endian `u16` and advances the cursor.
- `DataWriter::write_u16_be` (`data_writer.rs`): Writes a big-endian `u16` and advances the cursor.
- `DataWriter::write_i16_le` (`data_writer.rs`): Writes a little-endian `i16` and advances the cursor.
- `DataWriter::write_u32_le` (`data_writer.rs`): Writes a little-endian `u32` and advances the cursor.
- `DataWriter::write_i32_le` (`data_writer.rs`): Writes a little-endian `i32` and advances the cursor.
- `DataWriter::write_f32_le` (`data_writer.rs`): Writes a little-endian `f32` and advances the cursor.
- `DataWriter::write_f64_le` (`data_writer.rs`): Writes a little-endian `f64` and advances the cursor.
- `DataWriter::write_string` (`data_writer.rs`): Writes a length-prefixed UTF-8 string (4-byte LE length + bytes).
- `DataWriter::write_bytes` (`data_writer.rs`): Writes raw bytes and advances the cursor.
- `DataView::new` (`dataview.rs`): Creates a new view spanning the entire buffer.
- `DataView::new_slice` (`dataview.rs`): Creates a view starting at `offset` covering `size` bytes.
- `DataView::get_size` (`dataview.rs`): Returns the number of bytes in this view.
- `DataView::get_u8` (`dataview.rs`): Reads a `u8` at `idx` relative to this view's start offset.
- `DataView::get_i8` (`dataview.rs`): Reads an `i8` at `idx`.
- `DataView::get_u16` (`dataview.rs`): Reads a little-endian `u16` at `idx`.
- `DataView::get_i16` (`dataview.rs`): Reads a little-endian `i16` at `idx`.
- `DataView::get_u32` (`dataview.rs`): Reads a little-endian `u32` at `idx`.
- `DataView::get_i32` (`dataview.rs`): Reads a little-endian `i32` at `idx`.
- `DataView::get_f32` (`dataview.rs`): Reads a little-endian `f32` at `idx`.
- `DataView::get_f64` (`dataview.rs`): Reads a little-endian `f64` at `idx`.
- `LuaDataView::new` (`dataview.rs`): Creates a new `LuaDataView` wrapping the given `DataView`.
- `EncodeFormat::parse_str` (`encode.rs`): Parse a format name string (case-insensitive).
- `encode` (`encode.rs`): Encode bytes into a string using the specified format.
- `decode` (`encode.rs`): Decode a string back into bytes using the specified format.
- `HashAlgorithm::parse_str` (`hash.rs`): Parse an algorithm name string (case-insensitive).
- `hash` (`hash.rs`): Compute the hash of data using the specified algorithm, returned as a hex string.
- `crc32` (`hash.rs`): Compute the CRC-32 checksum of `data`, returned as a `u64` in the range `[0, 2³²)`.
- `pack` (`pack.rs`): Packs values according to a format string into a `ByteData` buffer.
- `unpack` (`pack.rs`): Unpacks values from a byte buffer according to a format string.
- `get_packed_size` (`pack.rs`): Computes the total byte size that `pack` would produce for the given format and values.
- `RingBuffer::new` (`ring_buffer.rs`): Creates a new ring buffer with the given capacity.
- `RingBuffer::push` (`ring_buffer.rs`): Pushes `value` onto the buffer.
- `RingBuffer::pop` (`ring_buffer.rs`): Removes and returns the oldest element (FIFO order).
- `RingBuffer::peek` (`ring_buffer.rs`): Returns a reference to the oldest element without removing it.
- `RingBuffer::peek_newest` (`ring_buffer.rs`): Returns a reference to the newest element without removing it.
- `RingBuffer::get` (`ring_buffer.rs`): Returns a reference to the element at the given logical index.
- `RingBuffer::capacity` (`ring_buffer.rs`): Returns the maximum number of elements the buffer can hold.
- `RingBuffer::len` (`ring_buffer.rs`): Returns the number of elements currently stored.
- `RingBuffer::is_empty` (`ring_buffer.rs`): Returns `true` if the buffer contains no elements.
- `RingBuffer::is_full` (`ring_buffer.rs`): Returns `true` if the buffer has reached its capacity.
- `RingBuffer::clear` (`ring_buffer.rs`): Removes all elements from the buffer.
- `RingBuffer::iter` (`ring_buffer.rs`): Returns borrowed references oldest-first without cloning.
- `RingBuffer::to_vec` (`ring_buffer.rs`): Returns all elements as a `Vec`, ordered oldest-first.
- `RingBuffer::to_refs` (`ring_buffer.rs`): Returns a `Vec<&T>` oldest-first without cloning elements.
- `RingBuffer::collect_copy` (`ring_buffer.rs`): Collects items efficiently for `Copy` element types.

## Lua API Reference

- Binding path(s): `src/lua_api/data_api.rs`
- Namespace: `lurek.data`

### Module Functions
- `lurek.data.pack`: Packs values into a binary byte string using the format string.
- `lurek.data.unpack`: Unpacks values from a binary byte string, returning values followed by next offset.
- `lurek.data.getPackedSize`: Returns the number of bytes the given format and values would occupy.
- `lurek.data.compress`: Compresses data using the given algorithm (deflate, gzip, lz4, zlib).
- `lurek.data.decompress`: Decompresses data using the given algorithm (deflate, gzip, lz4, zlib).
- `lurek.data.compressChunks`: Compresses a byte string or array-like table of byte chunks using the given algorithm.
- `lurek.data.decompressChunks`: Decompresses a compressed byte string or array-like table of compressed chunks.
- `lurek.data.encode`: Encodes binary data using the given format (base64, hex).
- `lurek.data.decode`: Decodes encoded text back to binary (base64, hex).
- `lurek.data.hash`: Returns the cryptographic hash of the input (md5, sha1, sha256, sha512).
- `lurek.data.crc32`: Returns the CRC-32 checksum of the input data as an integer.
- `lurek.data.newByteData`: Instantiates a raw byte data container object.
- `lurek.data.newDataView`: Creates a read-only windowed view into a byte string.
- `lurek.data.write`: Writes values using the Lurek2D Binary Pack Format.
- `lurek.data.read`: Reads values using the Lurek2D Binary Pack Format.
- `lurek.data.size`: Returns the byte size of a Lurek2D Binary Pack Format string.
- `lurek.data.parseToml`: Parses a TOML string into a Lua table.
- `lurek.data.encodeToml`: Encodes a Lua table into a TOML string.
- `lurek.data.newRingBuffer`: Creates a fixed-capacity ring buffer that can store any Lua value.
- `lurek.data.toMsgPack`: Serializes a Lua value (table, string, number, boolean, or nil) to MessagePack binary.
- `lurek.data.fromMsgPack`: Deserializes a MessagePack binary string back into a Lua value.
- `lurek.data.newWriter`: Creates a new write-cursor for building binary data.

### `LByteData` Methods
- `LByteData:getSize`: Returns the total byte length of this buffer.
- `LByteData:getString`: Get the string representation.
- `LByteData:getByte`: Get a byte at the specified offset.
- `LByteData:setByte`: Set a byte at the specified offset.
- `LByteData:clone`: Creates an independent copy of this byte buffer with identical contents.
- `LByteData:setBit`: Sets or clears a single bit within the buffer.
- `LByteData:getBit`: Returns the value of a single bit within the buffer.
- `LByteData:readBits`: Reads consecutive bits and packs them into a 32-bit integer.

### `LDataView` Methods
- `LDataView:getUInt8`: Reads an unsigned 8-bit integer at the given offset.
- `LDataView:getInt8`: Reads a signed 8-bit integer at the given offset.
- `LDataView:getInt16`: Reads a signed 16-bit integer at the given offset.
- `LDataView:getUInt16`: Reads an unsigned 16-bit integer at the given offset.
- `LDataView:getInt32`: Reads a signed 32-bit integer at the given offset.
- `LDataView:getUInt32`: Reads an unsigned 32-bit integer at the given offset.
- `LDataView:getFloat`: Reads a 32-bit float at the given offset.
- `LDataView:getDouble`: Reads a 64-bit float at the given offset.
- `LDataView:getSize`: Returns the size of this view in bytes.
- `LDataView:type`: Returns the type name of this object.
- `LDataView:typeOf`: Returns true if this object is of the given type.

### `LDataWriter` Methods
- `LDataWriter:writeU8`: Writes an unsigned 8-bit integer.
- `LDataWriter:writeI8`: Writes a signed 8-bit integer.
- `LDataWriter:writeU16LE`: Writes an unsigned 16-bit LE integer.
- `LDataWriter:writeU16BE`: Writes an unsigned 16-bit BE integer.
- `LDataWriter:writeI16LE`: Writes a signed 16-bit LE integer.
- `LDataWriter:writeU32LE`: Writes an unsigned 32-bit LE integer.
- `LDataWriter:writeI32LE`: Writes a signed 32-bit LE integer.
- `LDataWriter:writeF32LE`: Writes a 32-bit LE float.
- `LDataWriter:writeF64LE`: Writes a 64-bit LE float.
- `LDataWriter:writeString`: Writes a length-prefixed UTF-8 string (4-byte LE length + bytes).
- `LDataWriter:writeBytes`: Writes raw bytes from a Lua string.
- `LDataWriter:seek`: Moves the write cursor to the given position.
- `LDataWriter:tell`: Returns the current write cursor position.
- `LDataWriter:len`: Returns the total buffer length.
- `LDataWriter:toBytes`: Returns the buffer contents as a Lua string.
- `LDataWriter:type`: Returns the type name of this object.
- `LDataWriter:typeOf`: Returns true if this object is of the given type.

### `LRingBuffer` Methods
- `LRingBuffer:push`: Pushes a value onto the ring buffer.
- `LRingBuffer:pop`: Removes and returns the oldest element, or nil if the buffer is empty.
- `LRingBuffer:peek`: Returns the oldest element without removing it, or nil if empty.
- `LRingBuffer:peekNewest`: Returns the newest element without removing it, or nil if empty.
- `LRingBuffer:len`: Returns the number of elements currently in the buffer.
- `LRingBuffer:capacity`: Returns the maximum number of elements the buffer can hold.
- `LRingBuffer:isEmpty`: Returns true if the buffer contains no elements.
- `LRingBuffer:isFull`: Returns true if the buffer has reached its capacity.
- `LRingBuffer:clear`: Removes all elements from the buffer, releasing their registry entries.
- `LRingBuffer:toTable`: Returns all elements as an array table ordered oldest-first.
- `LRingBuffer:type`: Returns the type name of this object.
- `LRingBuffer:typeOf`: Returns true if this object is of the given type.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/data/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
