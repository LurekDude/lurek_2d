# data

## General Info

- Module group: `Foundations`
- Source path: `src/data/`
- Lua API path(s): `src/lua_api/data_api.rs`
- Primary Lua namespace: `lurek.data`
- Rust test path(s): tests/rust/unit/data_tests.rs; tests/rust/stress/data_stress_tests.rs; inline tests in src/data/byte_data.rs, src/data/encode.rs, src/data/hash.rs
- Lua test path(s): tests/lua/unit/test_data.lua; tests/lua/stress/test_data_stress.lua; tests/lua/stress/test_data_compression_stress.lua; tests/lua/integration/test_data_app.lua; tests/lua/integration/test_data_fileapp.lua; tests/lua/integration/test_data_compute.lua; tests/lua/integration/test_thread_data.lua; tests/lua/golden/test_data_golden.lua

## Summary

The `data` module provides Lurek2D's binary data manipulation toolkit: raw byte buffers, compression, cryptographic hashing, binary encoding, and structured pack/unpack utilities. It is a Foundations tier module with no engine dependencies, used by game code and engine internals that need to work with binary data at a byte level.

The core type is `ByteData`, a heap-allocated raw byte buffer with bounds-checked element access. Most operations work by consuming or returning `ByteData` instances rather than modifying them in place.

Compression (`compress` submodule) supports deflate, gzip, lz4, and zlib via the `CompressFormat` enum. Hashing (`hash`) provides MD5, SHA-1, SHA-256, and SHA-512 via the `HashAlgorithm` enum. Encoding (`encode`) provides base64 and hex via the `EncodeFormat` enum.

The `pack`/`unpack` functions provide a LÖVE2D-compatible binary pack format using format-string tokens (`b` byte, `i` / `I` signed/unsigned integers in various widths, `f` float, `d` double, `s` length-prefixed string, `z` null-terminated string, `c` fixed-length byte sequence). This API is used by network serialization and save-data encoding. The separate `bin_pack` module implements Lurek2D's own space-separated type-token serialization format for edge cases requiring human-readable binary encoding. `DataView` provides a windowed, read-only view into a byte slice without copying. `RingBuffer` is a generic fixed-capacity circular buffer useful for input history, debug logs, and event queues. `toml_convert` handles TOML string ↔ `toml::Value` conversion for the Lua bridge, and `msgpack` provides MessagePack serialization via `rmp-serde` using `serde_json::Value` as the intermediate representation.

Text format parsing (JSON, TOML, CSV) is the responsibility of the `serial` module under `lurek.serial`.

**Scope boundary**: Foundations tier. Depends only on external crates (flate2, lz4_flex, sha2, base64, hex, rmp-serde, toml). Lua bridge in `src/lua_api/data_api.rs`.

## Files

- `bin_pack.rs`: Implements the Lurek2D-native binary pack format with readable named tokens such as `u32`, `f64`, `str`, and endian modifiers.
- `byte_data.rs`: Defines the owned byte-buffer type used to construct, mutate, clone, and expose raw bytes to Lua.
- `compress.rs`: Provides whole-buffer compression and decompression for deflate, gzip, zlib, and LZ4 formats.
- `data_writer.rs`: Write-cursor companion to [`DataView`](super::DataView).
- `dataview.rs`: Implements a read-only typed cursor over shared bytes with bounds-checked little-endian accessors.
- `encode.rs`: Handles base64 and hex encoding and decoding for binary payload transport.
- `hash.rs`: Computes MD5, SHA-1, SHA-256, and SHA-512 digests over in-memory data.
- `mod.rs`: Re-exports the public binary-data surface and keeps callers from importing individual helpers ad hoc.
- `msgpack.rs`: MessagePack serialization and deserialization for Lurek2D.
- `pack.rs`: Implements the LÖVE-style single-character binary pack and unpack format used for compact compatibility-oriented serialization.
- `ring_buffer.rs`: Fixed-capacity circular ring buffer.
- `toml_convert.rs`: Converts between TOML text and `toml::Value` trees for the Lua-facing TOML helpers.

## Types

- `BinValue` (`enum`, `bin_pack.rs`): Tagged value enum used by the named-token pack format. It is the bridge between dynamically typed inputs and strongly typed binary writes and reads.
- `ByteData` (`struct`, `byte_data.rs`): Primary owned byte buffer for Lua and Rust interop. It is the mutable container that other helpers serialize into or read from.
- `CompressFormat` (`enum`, `compress.rs`): Supported compression backends for whole-buffer compression and decompression. It keeps format parsing and dispatch explicit rather than stringly typed deep in the implementation.
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
- `to_msgpack` (`msgpack.rs`): Serializes a `serde_json::Value` to MessagePack bytes.
- `from_msgpack` (`msgpack.rs`): Deserializes MessagePack bytes into a `serde_json::Value`.
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
- `RingBuffer::to_vec` (`ring_buffer.rs`): Returns all elements as a `Vec`, ordered oldest-first.
- `parse_toml` (`toml_convert.rs`): Parse a TOML string into a `toml::Value`.
- `encode_toml` (`toml_convert.rs`): Encode a `toml::Value` into a TOML string.

## Lua API Reference

- Binding path(s): `src/lua_api/data_api.rs`
- Namespace: `lurek.data`

### Module Functions
- `lurek.data.pack`: Packs values into a binary byte string using the format string.
- `lurek.data.unpack`: Unpacks values from a binary byte string, returning values followed by next offset.
- `lurek.data.getPackedSize`: Returns the number of bytes the given format and values would occupy.
- `lurek.data.compress`: Compresses data using the given algorithm (deflate, gzip, lz4).
- `lurek.data.decompress`: Decompresses data using the given algorithm (deflate, gzip, lz4).
- `lurek.data.encode`: Encodes binary data using the given format (base64, hex).
- `lurek.data.decode`: Decodes encoded text back to binary (base64, hex).
- `lurek.data.hash`: Returns the cryptographic hash of the input (md5, sha1, sha256, sha512).
- `lurek.data.crc32`: Returns the CRC-32 checksum of the input data as an integer.
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

### `DataView` Methods
- `DataView:getUInt8`: Reads an unsigned 8-bit integer at the given offset.
- `DataView:getInt8`: Reads a signed 8-bit integer at the given offset.
- `DataView:getInt16`: Reads a signed 16-bit integer at the given offset.
- `DataView:getUInt16`: Reads an unsigned 16-bit integer at the given offset.
- `DataView:getInt32`: Reads a signed 32-bit integer at the given offset.
- `DataView:getUInt32`: Reads an unsigned 32-bit integer at the given offset.
- `DataView:getFloat`: Reads a 32-bit float at the given offset.
- `DataView:getDouble`: Reads a 64-bit float at the given offset.
- `DataView:getSize`: Returns the size of this view in bytes.

### `DataWriter` Methods
- `DataWriter:writeU8`: Writes an unsigned 8-bit integer.
- `DataWriter:writeI8`: Writes a signed 8-bit integer.
- `DataWriter:writeU16LE`: Writes an unsigned 16-bit LE integer.
- `DataWriter:writeU16BE`: Writes an unsigned 16-bit BE integer.
- `DataWriter:writeI16LE`: Writes a signed 16-bit LE integer.
- `DataWriter:writeU32LE`: Writes an unsigned 32-bit LE integer.
- `DataWriter:writeI32LE`: Writes a signed 32-bit LE integer.
- `DataWriter:writeF32LE`: Writes a 32-bit LE float.
- `DataWriter:writeF64LE`: Writes a 64-bit LE float.
- `DataWriter:writeString`: Writes a length-prefixed UTF-8 string (4-byte LE length + bytes).
- `DataWriter:writeBytes`: Writes raw bytes from a Lua string.
- `DataWriter:seek`: Moves the write cursor to the given position.
- `DataWriter:tell`: Returns the current write cursor position.
- `DataWriter:len`: Returns the total buffer length.
- `DataWriter:toBytes`: Returns the buffer contents as a Lua string.

### `RingBuffer` Methods
- `RingBuffer:push`: Pushes a value onto the ring buffer.
- `RingBuffer:pop`: Removes and returns the oldest element, or nil if the buffer is empty.
- `RingBuffer:peek`: Returns the oldest element without removing it, or nil if empty.
- `RingBuffer:peekNewest`: Returns the newest element without removing it, or nil if empty.
- `RingBuffer:len`: Returns the number of elements currently in the buffer.
- `RingBuffer:capacity`: Returns the maximum number of elements the buffer can hold.
- `RingBuffer:isEmpty`: Returns true if the buffer contains no elements.
- `RingBuffer:clear`: Removes all elements from the buffer, releasing their registry entries.
- `RingBuffer:toTable`: Returns all elements as an array table ordered oldest-first.

### `mlua` Methods
- `mlua:getSize`: Get the size.
- `mlua:getString`: Get the string representation.
- `mlua:getByte`: Get a byte at the specified offset.
- `mlua:setByte`: Set a byte at the specified offset.
- `mlua:clone`: Clone the ByteData.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/data/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
