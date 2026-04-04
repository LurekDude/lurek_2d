# `binary` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 1 — Core Engine Subsystems |
| **Lua API** | `luna.binary` |
| **Source** | `src/binary/` |
| **Tests** | `tests/unit/data_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_binary.lua` |

## Summary

The binary module provides low-level binary data utilities for the Luna2D engine.
It exposes byte buffers (`ByteData`), data compression and decompression,
base64/hex encoding, cryptographic hashing, the Luna2D Binary Pack Format for
structured binary I/O, and a `DataView` interface for reading typed values from
arbitrary byte slices.

The Luna2D Binary Pack Format (`luna.binary.write` / `luna.binary.read` /
`luna.binary.size`) uses space-separated format token strings (e.g. `"le u32 f32 str"`)
to write and read structured binary data with explicit endianness (`le` / `be`).
Supported token types: `u8 u16 u32 u64 i8 i16 i32 i64 f32 f64 bool str cstr pad`.

Format serialization belongs in `src/serial/` (`luna.serial.*`).

## Architecture

```
binary/
  │
  ├── ByteData ── Vec<u8> wrapper with Lua UserData interface
  │
  ├── compress ── deflate / gzip / lz4 / zlib (level 0–9)
  │
  ├── encode ── base64 / hex encoding and decoding
  │
  ├── hash ── md5 / sha1 / sha256 / sha512 → hex string
  │
  ├── pack ── Luna2D Binary Pack Format (write / read / measure_size)
  │
  └── dataview ── DataView: read typed values from a byte slice
```

## Source Files

| File | Purpose |
|------|---------|
| `byte_data.rs` | Contiguous byte buffer accessible from Lua |
| `compress.rs` | Data compression and decompression using deflate, gzip, zlib, and LZ4 |
| `encode.rs` | Base64 and hex encoding/decoding for data serialization |
| `hash.rs` | Cryptographic hash functions for data integrity verification |
| `pack.rs` | Luna2D Binary Pack Format — write/read/measure_size with BinValue |
| `dataview.rs` | DataView for reading typed values from a shared byte slice |

## Submodules

### `binary::byte_data`

Contiguous byte buffer accessible from Lua.

- **`ByteData`** (struct): Wraps `Vec<u8>` with indexed get/set operations and string conversion.

### `binary::compress`

Data compression and decompression using deflate, gzip, zlib, and LZ4.

- **`CompressFormat`** (enum): Deflate, Gzip, Zlib, Lz4.
- **`compress`** (fn): Compress data with level 0–9.
- **`decompress`** (fn): Decompress data using the matching format.

### `binary::encode`

Base64 and hex encoding/decoding.

- **`EncodeFormat`** (enum): Base64, Hex.
- **`encode`** (fn): Encode bytes to string.
- **`decode`** (fn): Decode string back to bytes.

### `binary::hash`

Cryptographic hash functions.

- **`HashAlgorithm`** (enum): Md5, Sha1, Sha256, Sha512.
- **`hash`** (fn): Compute hash, returned as a lowercase hex string.

### `binary::pack`

Luna2D Binary Pack Format — structured binary I/O with format strings.

- **`BinValue`** (enum): U8/U16/U32/U64/I8/I16/I32/I64/F32/F64/Bool/Str/Bytes.
- **`write`** (fn): Serialise `&[BinValue]` to `ByteData` using a format string.
- **`read`** (fn): Deserialise `&[u8]` from offset into `Vec<BinValue>` + next offset.
- **`measure_size`** (fn): Return byte count for a format string (error on `str`/`cstr`).

### `binary::dataview`

Read typed values from an `Arc<Vec<u8>>` with bounds checking.

- **`DataView`** (struct): Slice view into a shared byte buffer with `get_u8/u16/u32/u64/i8/i16/i32/i64/f32/f64` methods.

## Lua API

Exposed under `luna.binary.*` by `src/lua_api/binary_api.rs`.

| Lua Function | Description |
|---|---|
| `luna.binary.newByteData(size)` | Allocate a zeroed byte buffer |
| `luna.binary.compress(data, fmt, level)` | Compress ByteData |
| `luna.binary.decompress(data, fmt)` | Decompress ByteData |
| `luna.binary.hash(algo, data)` | Hash → hex string |
| `luna.binary.encode(fmt, data)` | Encode bytes → string |
| `luna.binary.decode(fmt, str)` | Decode string → ByteData |
| `luna.binary.write(fmt, ...)` | Write values with format string → ByteData |
| `luna.binary.read(fmt, data, offset?)` | Read values from ByteData/string |
| `luna.binary.size(fmt)` | Measure format string byte size |
| `luna.binary.newDataView(data)` | Create a DataView over ByteData |

