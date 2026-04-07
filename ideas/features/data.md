# data — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/data.md`
**Files**: ByteData binary buffers, compression, hashing

## Purpose

Binary data manipulation: create, read, write byte buffers with typed access. Compression (zlib/lz4/zstd). Cryptographic hashing (MD5, SHA-256). Base64 encoding.

## Current Feature Summary

- `ByteData`: typed binary buffer with read/write at offsets (u8/i8/u16/i16/u32/i32/f32/f64/string)
- Endianness: little-endian and big-endian variants
- Compression: zlib, lz4, zstd (compress/decompress)
- Hashing: MD5, SHA-256
- Base64: encode/decode
- Hex: encode/decode
- CRC32 checksum
- UUID generation (v4)
- Buffer concatenation, slicing, copying

## Feature Gaps

1. **No MessagePack serialization**: Binary serialization format popular for game networking. Currently must use JSON (text-based, slower).
2. **No protobuf/flatbuffers**: Schema-based binary formats for efficient data exchange.
3. **No bit-level operations**: Only byte-level access. Bit flags, bit packing common in networking and save formats.
4. **No ring buffer**: No circular buffer for streaming data (audio, network).
5. **No typed array views**: Can read individual values but no typed "view" over a region (like JavaScript's Float32Array).
6. **No TOML overlap resolution**: data module offers binary format tools, while `serial` handles text format conversion. But `engine::Config` also parses TOML. Three different places touch TOML.

## Structural Issues

- **Overlap with compute module**: `data` has ByteData (binary buffers), `compute` has NdArray (dense numerical arrays). Both are "array of numbers." Consider merging or more clearly differentiating: data = binary I/O, compute = math on arrays.
- **Name is generic**: "data" is very broad. Consider renaming to `binary` or `buffer` to be more specific about what it actually does (binary buffer manipulation).

## Suggestions

1. **Rename to `buffer` or `binary`**: More descriptive than "data." `luna.buffer.new(1024)` reads better than `luna.data.new(1024)`.
2. **Add MessagePack**: `luna.data.toMsgPack(table)` / `luna.data.fromMsgPack(bytes)` — efficient binary serialization for networking and save files.
3. **Add bit operations**: `buffer:setBit(byte, bit)` / `buffer:getBit(byte, bit)` / `buffer:readBits(offset, count)` — common for compact data formats.
4. **Clarify boundary with compute**: Document that `data` is for I/O-oriented binary manipulation, `compute` is for mathematical operations on dense arrays.
5. **Add ring buffer**: `luna.data.newRingBuffer(capacity)` — useful for streaming, network buffers, history tracking.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| Binary buffers | ✅ | ✅ (ByteData) | ❌ | ❌ |
| Compression | ✅ (3 algos) | ✅ (lz4) | ❌ | ❌ |
| Hashing | ✅ | ❌ | ❌ | ❌ |
| Base64 | ✅ | ✅ | ❌ | ❌ |
| UUID | ✅ | ❌ | ❌ | ❌ |
| MessagePack | ❌ | ❌ | ❌ | ❌ |
| Bit ops | ❌ | ❌ | ❌ | ❌ |

## Priority

**LOW** — Module is functional. Rename is a clarity improvement. MessagePack would be valuable for networking. Overlap with compute should be resolved at architecture level.
