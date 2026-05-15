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
- `ByteData::new` (`byte_data.rs`): Create zero-filled buffer and return new value.
- `ByteData::from_bytes` (`byte_data.rs`): Wrap existing bytes and return new value.
- `ByteData::from_string` (`byte_data.rs`): Encode UTF-8 text bytes and return new value.
- `ByteData::len` (`byte_data.rs`): Return buffer length in bytes.
- `ByteData::is_empty` (`byte_data.rs`): Return true when buffer has no bytes.
- `ByteData::get_byte` (`byte_data.rs`): Read byte at offset and return optional value.
- `ByteData::set_byte` (`byte_data.rs`): Write byte at offset and return success flag.
- `ByteData::get_string` (`byte_data.rs`): Decode bytes as UTF-8 lossily and return string.
- `ByteData::as_bytes` (`byte_data.rs`): Return immutable byte slice view.
- `ByteData::as_bytes_mut` (`byte_data.rs`): Return mutable byte slice view.
- `ByteData::clone_data` (`byte_data.rs`): Clone internal bytes and return copied buffer.
- `CompressFormat::parse_str` (`compress.rs`): Parse codec label and return variant or error.
- `compress` (`compress.rs`): Compress data using the specified format and compression level (0-9).
- `decompress` (`compress.rs`): Decompress data using the specified format.
- `compress_chunks` (`compress.rs`): Compresses ordered byte chunks without pre-concatenating input.
- `decompress_chunks` (`compress.rs`): Decompresses ordered compressed chunks back into a contiguous byte vector.
- `compress_stream` (`compress.rs`): Compresses data from any `Read` source into any `Write` sink.
- `decompress_stream` (`compress.rs`): Decompresses data from any `Read` source into any `Write` sink.
- `DataWriter::new` (`data_writer.rs`): Create empty writer and return value.
- `DataWriter::with_capacity` (`data_writer.rs`): Create writer with reserved capacity and return value.
- `DataWriter::tell` (`data_writer.rs`): Return current cursor position.
- `DataWriter::len` (`data_writer.rs`): Return current buffer length.
- `DataWriter::is_empty` (`data_writer.rs`): Return true when buffer is empty.
- `DataWriter::seek` (`data_writer.rs`): Move cursor to position and grow buffer when needed.
- `DataWriter::into_bytes` (`data_writer.rs`): Consume writer and return owned bytes.
- `DataWriter::as_bytes` (`data_writer.rs`): Return immutable bytes view.
- `DataWriter::write_u8` (`data_writer.rs`): Write one u8 value at cursor.
- `DataWriter::write_i8` (`data_writer.rs`): Write one i8 value at cursor.
- `DataWriter::write_u16_le` (`data_writer.rs`): Write u16 in little-endian order.
- `DataWriter::write_u16_be` (`data_writer.rs`): Write u16 in big-endian order.
- `DataWriter::write_i16_le` (`data_writer.rs`): Write i16 in little-endian order.
- `DataWriter::write_u32_le` (`data_writer.rs`): Write u32 in little-endian order.
- `DataWriter::write_i32_le` (`data_writer.rs`): Write i32 in little-endian order.
- `DataWriter::write_f32_le` (`data_writer.rs`): Write f32 in little-endian order.
- `DataWriter::write_f64_le` (`data_writer.rs`): Write f64 in little-endian order.
- `DataWriter::write_string` (`data_writer.rs`): Write length-prefixed UTF-8 string.
- `DataWriter::write_bytes` (`data_writer.rs`): Write raw bytes at cursor.
- `DataView::new` (`dataview.rs`): Create full-buffer view and return value.
- `DataView::new_slice` (`dataview.rs`): Create sub-slice view and return value or bounds error.
- `DataView::get_size` (`dataview.rs`): Return view size in bytes.
- `DataView::get_u8` (`dataview.rs`): Read u8 at index and return value or error.
- `DataView::get_i8` (`dataview.rs`): Read i8 at index and return value or error.
- `DataView::get_u16` (`dataview.rs`): Read little-endian u16 at index and return value or error.
- `DataView::get_i16` (`dataview.rs`): Read little-endian i16 at index and return value or error.
- `DataView::get_u32` (`dataview.rs`): Read little-endian u32 at index and return value or error.
- `DataView::get_i32` (`dataview.rs`): Read little-endian i32 at index and return value or error.
- `DataView::get_f32` (`dataview.rs`): Read little-endian f32 at index and return value or error.
- `DataView::get_f64` (`dataview.rs`): Read little-endian f64 at index and return value or error.
- `LuaDataView::new` (`dataview.rs`): Wrap DataView and return LuaDataView.
- `EncodeFormat::parse_str` (`encode.rs`): Parse format label and return encoding variant or error.
- `encode` (`encode.rs`): Encode bytes into a string using the specified format.
- `decode` (`encode.rs`): Decode a string back into bytes using the specified format.
- `HashAlgorithm::parse_str` (`hash.rs`): Parse algorithm label and return hash variant or error.
- `hash` (`hash.rs`): Compute the hash of data using the specified algorithm, returned as a hex string.
- `crc32` (`hash.rs`): Compute the CRC-32 checksum of `data`, returned as a `u64` in the range `[0, 2³²)`.
- `pack` (`pack.rs`): Packs values according to a format string into a `ByteData` buffer.
- `unpack` (`pack.rs`): Unpacks values from a byte buffer according to a format string.
- `get_packed_size` (`pack.rs`): Computes the total byte size that `pack` would produce for the given format and values.
- `RingBuffer::new` (`ring_buffer.rs`): Create ring buffer with capacity clamped to at least one.
- `RingBuffer::push` (`ring_buffer.rs`): Push value and return true when buffer was not full.
- `RingBuffer::pop` (`ring_buffer.rs`): Pop oldest value and return optional element.
- `RingBuffer::peek` (`ring_buffer.rs`): Return oldest element reference.
- `RingBuffer::peek_newest` (`ring_buffer.rs`): Return newest element reference.
- `RingBuffer::get` (`ring_buffer.rs`): Return element by logical index from oldest.
- `RingBuffer::capacity` (`ring_buffer.rs`): Return configured capacity.
- `RingBuffer::len` (`ring_buffer.rs`): Return current element count.
- `RingBuffer::is_empty` (`ring_buffer.rs`): Return true when element count is zero.
- `RingBuffer::is_full` (`ring_buffer.rs`): Return true when element count equals capacity.
- `RingBuffer::clear` (`ring_buffer.rs`): Clear all elements and reset indices.
- `RingBuffer::iter` (`ring_buffer.rs`): Iterate elements from oldest to newest.
- `RingBuffer::to_vec` (`ring_buffer.rs`): Clone elements into Vec from oldest to newest.
- `RingBuffer::to_refs` (`ring_buffer.rs`): Collect references into Vec from oldest to newest.
- `RingBuffer::collect_copy` (`ring_buffer.rs`): Copy elements into Vec from oldest to newest.

## Lua API Reference

- Binding path(s): `src/lua_api/data_api.rs`
- Namespace: `lurek.data`

### Module Functions
- `lurek.data.pack`: Packs Lua values into a binary string using a format string.
- `lurek.data.unpack`: Unpacks values from a binary string using a format string.
- `lurek.data.getPackedSize`: Computes the packed byte size for values and a format string.
- `lurek.data.compress`: Compresses a binary string using a named compression format.
- `lurek.data.decompress`: Decompresses a binary string using a named compression format.
- `lurek.data.compressChunks`: Compresses a string or table of strings as a chunked byte stream.
- `lurek.data.decompressChunks`: Decompresses a string or table of strings as a chunked byte stream.
- `lurek.data.encode`: Encodes a binary string using a named text encoding format.
- `lurek.data.decode`: Decodes a string using a named text encoding format.
- `lurek.data.hash`: Hashes a binary string with a named algorithm.
- `lurek.data.crc32`: Computes CRC32 for a binary string.
- `lurek.data.newByteData`: Creates ByteData from a size or string.
- `lurek.data.newDataView`: Creates a DataView over a binary string slice.
- `lurek.data.write`: Writes binary values into a byte string using a format string.
- `lurek.data.read`: Reads binary values from a byte string using a format string.
- `lurek.data.size`: Measures fixed byte size for a binary format string.
- `lurek.data.parseToml`: Parses TOML text into Lua tables and scalar values.
- `lurek.data.encodeToml`: Encodes a Lua table into TOML text.
- `lurek.data.newRingBuffer`: Creates a fixed-capacity ring buffer for Lua values.
- `lurek.data.toMsgPack`: Encodes a Lua value into the current structured binary interchange payload.
- `lurek.data.fromMsgPack`: Decodes a structured binary interchange payload back into Lua values.
- `lurek.data.newWriter`: Creates an empty binary data writer.

### `LByteData` Methods
- `LByteData:getSize`: Returns the byte buffer length.
- `LByteData:getString`: Returns the byte buffer as a string.
- `LByteData:getByte`: Reads one byte at a zero-based offset.
- `LByteData:setByte`: Writes one byte at a zero-based offset.
- `LByteData:clone`: Returns a copy of this byte buffer.
- `LByteData:setBit`: Sets or clears one bit inside a byte.
- `LByteData:getBit`: Reads one bit inside a byte.
- `LByteData:readBits`: Reads up to 32 bits starting at a byte and bit offset.

### `LDataView` Methods
- `LDataView:getUInt8`: Reads an unsigned 8-bit integer at a byte offset.
- `LDataView:getInt8`: Reads a signed 8-bit integer at a byte offset.
- `LDataView:getInt16`: Reads a signed 16-bit integer at a byte offset.
- `LDataView:getUInt16`: Reads an unsigned 16-bit integer at a byte offset.
- `LDataView:getInt32`: Reads a signed 32-bit integer at a byte offset.
- `LDataView:getUInt32`: Reads an unsigned 32-bit integer at a byte offset.
- `LDataView:getFloat`: Reads a 32-bit float at a byte offset.
- `LDataView:getDouble`: Reads a 64-bit float at a byte offset.
- `LDataView:getSize`: Returns this data view size in bytes.
- `LDataView:type`: Returns the Lua-visible type name for this data view handle.
- `LDataView:typeOf`: Returns whether this data view handle matches a supported type name.

### `LDataWriter` Methods
- `LDataWriter:writeU8`: Writes an unsigned 8-bit integer.
- `LDataWriter:writeI8`: Writes a signed 8-bit integer.
- `LDataWriter:writeU16LE`: Writes an unsigned 16-bit integer in little-endian order.
- `LDataWriter:writeU16BE`: Writes an unsigned 16-bit integer in big-endian order.
- `LDataWriter:writeI16LE`: Writes a signed 16-bit integer in little-endian order.
- `LDataWriter:writeU32LE`: Writes an unsigned 32-bit integer in little-endian order.
- `LDataWriter:writeI32LE`: Writes a signed 32-bit integer in little-endian order.
- `LDataWriter:writeF32LE`: Writes a 32-bit float in little-endian order.
- `LDataWriter:writeF64LE`: Writes a 64-bit float in little-endian order.
- `LDataWriter:writeString`: Writes a UTF-8 string to the writer.
- `LDataWriter:writeBytes`: Writes raw bytes from a Lua string to the writer.
- `LDataWriter:seek`: Moves the writer cursor.
- `LDataWriter:tell`: Returns the writer cursor position.
- `LDataWriter:len`: Returns the writer buffer length.
- `LDataWriter:toBytes`: Returns the writer buffer as a binary string.
- `LDataWriter:type`: Returns the Lua-visible type name for this data writer handle.
- `LDataWriter:typeOf`: Returns whether this data writer handle matches a supported type name.

### `LRingBuffer` Methods
- `LRingBuffer:push`: Pushes a value into the ring buffer and evicts the oldest value when full.
- `LRingBuffer:pop`: Removes and returns the oldest value.
- `LRingBuffer:peek`: Returns the oldest value without removing it.
- `LRingBuffer:peekNewest`: Returns the newest value without removing it.
- `LRingBuffer:len`: Returns the number of values currently stored.
- `LRingBuffer:capacity`: Returns the ring buffer capacity.
- `LRingBuffer:isEmpty`: Returns whether the ring buffer has no values.
- `LRingBuffer:isFull`: Returns whether the ring buffer is at capacity.
- `LRingBuffer:clear`: Removes every stored value and releases registry keys.
- `LRingBuffer:toTable`: Returns stored values in oldest-to-newest order.
- `LRingBuffer:type`: Returns the Lua-visible type name for this ring buffer handle.
- `LRingBuffer:typeOf`: Returns whether this ring buffer handle matches a supported type name.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/data/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
