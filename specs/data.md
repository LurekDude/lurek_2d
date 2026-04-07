# `data` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 1 — Core Engine Subsystems |
| **Status** | Implemented — Full |
| **Lua API** | `luna.data` |
| **Source** | `src/data/` |
| **Rust Tests** | `tests/rust/unit/data_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_data.lua` |
| **Architecture** | — |

## Summary

The `data` module is Luna2D's pure-CPU data processing layer. It provides binary data
manipulation, compression, hashing, encoding, TOML conversion, and two independent binary
pack/unpack systems — all exposed to Lua scripts through the `luna.data` namespace.

**ByteData** wraps a `Vec<u8>` with indexed get/set operations and string conversion, serving
as the primary mutable byte buffer exchanged between Lua and the engine. **DataView** offers a
read-only, windowed cursor into a shared `Arc<Vec<u8>>` buffer with typed little-endian accessors
(u8 through f64) and bounds-checked access on every read.

**Compression** supports four formats — deflate, gzip, zlib (via `flate2`), and LZ4 (via
`lz4_flex`) — with configurable compression level (0–9). **Hashing** computes MD5, SHA-1,
SHA-256, and SHA-512 digests returned as hex strings. **Encoding** converts between binary data
and Base64 or hex string representations.

The module provides **two binary pack/unpack systems**. The first (`pack.rs`) uses single-character
format strings compatible with LÖVE2D's `data.pack` API (`<`, `>`, `b`, `B`, `h`, `H`, `i`, `I`,
`l`, `L`, `f`, `d`, `s`, `z`, `x`). The second (`bin_pack.rs`) uses space-separated named type
tokens (`u8`, `u16`, `f32`, `str`, `cstr`, `pad`, `le`, `be`) with a cleaner, more readable syntax.
Both systems produce and consume `ByteData` buffers.

**TOML conversion** parses TOML strings into `toml::Value` and encodes them back, enabling the
Lua API to round-trip TOML configuration between strings and Lua tables.

**Scope boundary**: This module is a pure CPU data-processing layer. It has no GPU, audio, window,
filesystem, or physics dependencies. It depends only on `math` and `engine` (Baseline). The
`ByteData` type is also used by other modules (e.g. `bin_pack`, `pack`) as their output buffer.

## Architecture

```
luna.data.*  (Lua API — src/lua_api/data_api.rs)
    │
    ▼
src/data/mod.rs  (re-exports all submodules)
    │
    ├── byte_data.rs ── ByteData (Vec<u8> wrapper, UserData)
    │       │
    │       └──── used by bin_pack.rs and pack.rs as output buffer
    │
    ├── dataview.rs ─── DataView (Arc<Vec<u8>> windowed view, UserData)
    │
    ├── compress.rs ─── CompressFormat enum + compress()/decompress()
    │                   └── flate2 (deflate/gzip/zlib) + lz4_flex (LZ4)
    │
    ├── hash.rs ─────── HashAlgorithm enum + hash()
    │                   └── md5 + sha1 + sha2 (SHA-256/SHA-512)
    │
    ├── encode.rs ───── EncodeFormat enum + encode()/decode()
    │                   └── base64 + hex
    │
    ├── pack.rs ─────── PackValue enum + pack()/unpack()/get_packed_size()
    │                   └── LÖVE2D-compatible single-char format strings
    │
    ├── bin_pack.rs ─── BinValue enum + write()/read()/measure_size()
    │                   └── Luna2D named-token format strings
    │
    └── toml_convert.rs ── parse_toml()/encode_toml()
                           └── toml crate
```

## Source Files

| File | Purpose |
|------|---------|
| `bin_pack.rs` | Luna2D Binary Pack Format — space-separated named-token binary serialization (`write`, `read`, `measure_size`). Tokens: `u8`–`u64`, `i8`–`i64`, `f32`, `f64`, `bool`, `str`, `cstr`, `pad`, `le`/`be` endian modifiers. |
| `byte_data.rs` | Contiguous byte buffer (`ByteData`) wrapping `Vec<u8>` with indexed get/set, string conversion, and mlua `UserData` implementation. |
| `compress.rs` | Data compression and decompression using deflate, gzip, zlib (flate2) and LZ4 (lz4_flex). Configurable compression level 0–9. |
| `dataview.rs` | Read-only windowed view (`DataView`) into a shared `Arc<Vec<u8>>` buffer. Typed little-endian accessors for u8 through f64 with bounds checking. |
| `encode.rs` | Base64 (RFC 4648) and hexadecimal encoding/decoding for data serialization. |
| `hash.rs` | Cryptographic hash functions — MD5, SHA-1, SHA-256, SHA-512 — returning hex-string digests. |
| `pack.rs` | LÖVE2D-compatible binary pack/unpack with single-character format strings (`<`, `>`, `b`/`B`, `h`/`H`, `i`/`I`, `l`/`L`, `f`, `d`, `s`, `z`, `x`). |
| `toml_convert.rs` | TOML parsing (`str → toml::Value`) and encoding (`toml::Value → str`) via the `toml` crate. |

## Submodules

### `data::bin_pack`

Luna2D Binary Pack Format — format-string based binary serialization using space-separated
named type tokens. Provides `write()`, `read()`, and `measure_size()`. Endianness is controlled
by `le`/`be` tokens (default: little-endian). Supported tokens: `u8`–`u64`, `i8`–`i64`, `f32`,
`f64`, `bool`, `str` (u32-length-prefixed UTF-8), `cstr` (null-terminated UTF-8), `pad` (zero byte).

- **`BinValue`** (enum): Tagged union of all serializable binary value types (U8–U64, I8–I64, F32, F64, Bool, Str, Bytes).

### `data::byte_data`

Contiguous byte buffer accessible from Lua. Wraps `Vec<u8>` with indexed get/set operations,
string conversion, and cloning. Implements mlua `UserData` with methods `getSize`, `getString`,
`getByte`, `setByte`, and `clone`.

- **`ByteData`** (struct): Mutable byte buffer wrapping `Vec<u8>` for binary data manipulation.

### `data::compress`

Data compression and decompression supporting four formats: deflate, gzip, zlib (via flate2),
and LZ4 (via lz4_flex). Compression level is clamped to 0–9. LZ4 uses size-prepended block format.

- **`CompressFormat`** (enum): Supported compression formats — `Deflate`, `Gzip`, `Lz4`, `Zlib`.

### `data::dataview`

Read-only windowed view into a shared byte buffer. Uses `Arc<Vec<u8>>` for zero-copy shared
ownership. All reads are little-endian. Bounds are checked on every access; out-of-range indices
return an error string.

- **`DataView`** (struct): Windowed read-only view into a shared `Arc<Vec<u8>>` with typed accessors (u8–f64).

### `data::encode`

Base64 and hex encoding/decoding. Base64 uses the RFC 4648 standard alphabet via the `base64`
crate. Hex uses lowercase output via the `hex` crate.

- **`EncodeFormat`** (enum): Supported encoding formats — `Base64`, `Hex`.

### `data::hash`

Cryptographic hash functions for data integrity verification. MD5 and SHA-1 are included for
compatibility but are not recommended for security. SHA-256 and SHA-512 are the preferred
algorithms. All digests are returned as lowercase hex strings.

- **`HashAlgorithm`** (enum): Supported hash algorithms — `Md5`, `Sha1`, `Sha256`, `Sha512`.

### `data::pack`

LÖVE2D-compatible binary pack/unpack. Uses single-character format strings where `<`/`>` set
endianness, letter characters select data types, and `x` inserts padding. Produces `ByteData`
output. `get_packed_size()` computes the output size without packing.

- **`PackValue`** (enum): Tagged union for pack/unpack values — `Int(i64)`, `UInt(u64)`, `Float(f32)`, `Double(f64)`, `Str(String)`, `Bytes(Vec<u8>)`.

### `data::toml_convert`

TOML parsing and encoding via the `toml` crate. `parse_toml()` converts a TOML string into a
`toml::Value` tree. `encode_toml()` serializes a `toml::Value::Table` back to a TOML string.
Non-table root values return an error on encode.

## Key Types

### Structs

#### `data::byte_data::ByteData`

Contiguous byte buffer wrapping `Vec<u8>` for binary data manipulation. Provides constructors
(`new`, `from_bytes`, `from_string`), indexed access (`get_byte`, `set_byte`), string conversion
(`get_string`), raw slice access (`as_bytes`, `as_bytes_mut`), and cloning (`clone_data`).
Implements mlua `UserData` with Lua-callable methods: `getSize()`, `getString()`, `getByte(offset)`,
`setByte(offset, value)`, `clone()`.

#### `data::dataview::DataView`

Windowed read-only view into a shared `Arc<Vec<u8>>` byte buffer. Constructors: `new(data)` for
the whole buffer, `new_slice(data, offset, size)` for a sub-range. Typed little-endian accessors:
`get_u8`, `get_i8`, `get_u16`, `get_i16`, `get_u32`, `get_i32`, `get_f32`, `get_f64`. All reads
are bounds-checked. Fields: `data` (Arc), `offset`, `size`.

### Enums

#### `data::bin_pack::BinValue`

Tagged union of serializable binary values for the Luna2D Binary Pack Format. Variants: `U8(u8)`,
`U16(u16)`, `U32(u32)`, `U64(u64)`, `I8(i8)`, `I16(i16)`, `I32(i32)`, `I64(i64)`, `F32(f32)`,
`F64(f64)`, `Bool(bool)`, `Str(String)`, `Bytes(Vec<u8>)`.

#### `data::compress::CompressFormat`

Supported compression formats: `Deflate` (raw deflate), `Gzip` (gzip container), `Lz4` (LZ4
block compression), `Zlib` (zlib container). Parsed from strings via `parse_str()`.

#### `data::encode::EncodeFormat`

Supported encoding formats: `Base64` (RFC 4648 standard alphabet), `Hex` (lowercase hexadecimal).
Parsed from strings via `parse_str()`.

#### `data::hash::HashAlgorithm`

Supported hash algorithms: `Md5` (128-bit), `Sha1` (160-bit), `Sha256` (256-bit), `Sha512`
(512-bit). Parsed from strings via `parse_str()` which accepts aliases like `"sha-256"`.

#### `data::pack::PackValue`

Tagged union for LÖVE2D-compatible pack/unpack operations. Variants: `Int(i64)`, `UInt(u64)`,
`Float(f32)`, `Double(f64)`, `Str(String)`, `Bytes(Vec<u8>)`.

## Lua API

Exposed under `luna.data.*` by `src/lua_api/data_api.rs`. The API provides 15 module-level
functions plus two UserData types with their own methods.

### Module Functions

| Function | Description |
|----------|-------------|
| `luna.data.pack(format, ...)` | Packs values into a binary byte string using LÖVE2D-compatible single-character format strings. Returns a string. |
| `luna.data.unpack(format, data, offset?)` | Unpacks values from a binary byte string. Returns decoded values followed by the next byte offset. Default offset is 0. |
| `luna.data.getPackedSize(format, ...)` | Returns the byte count the given format and values would occupy when packed. |
| `luna.data.compress(format, data, level?)` | Compresses a string using the given algorithm (`"deflate"`, `"gzip"`, `"zlib"`, `"lz4"`). Default level is 6. |
| `luna.data.decompress(format, data)` | Decompresses a string using the given algorithm. |
| `luna.data.encode(format, data)` | Encodes binary data to a string (`"base64"` or `"hex"`). |
| `luna.data.decode(format, encoded)` | Decodes an encoded string back to binary data. |
| `luna.data.hash(algorithm, data)` | Computes a cryptographic hash (`"md5"`, `"sha1"`, `"sha256"`, `"sha512"`). Returns a hex string. |
| `luna.data.newByteData(value)` | Creates a mutable byte buffer from a size (integer) or string. |
| `luna.data.newDataView(data, offset?, size?)` | Creates a read-only windowed view into a byte string. |
| `luna.data.parseToml(input)` | Parses a TOML string and returns a Lua table. |
| `luna.data.encodeToml(input)` | Encodes a Lua table as a TOML string. |
| `luna.data.write(format, ...)` | Writes values using the Luna2D Binary Pack Format (space-separated named tokens). |
| `luna.data.read(format, data, offset?)` | Reads values using the Luna2D Binary Pack Format. Returns decoded values. |
| `luna.data.size(format)` | Returns the byte size of a Luna2D Binary Pack Format string (fixed-width tokens only). |

### ByteData Methods

| Method | Description |
|--------|-------------|
| `bd:getSize()` | Returns buffer size in bytes. |
| `bd:getString()` | Returns buffer contents as a lossy UTF-8 string. |
| `bd:getByte(offset)` | Returns the byte at offset (0-based). Errors on out-of-bounds. |
| `bd:setByte(offset, value)` | Sets the byte at offset. Errors on out-of-bounds. |
| `bd:clone()` | Returns a deep copy of this ByteData. |

### DataView Methods

| Method | Description |
|--------|-------------|
| `dv:getUInt8(offset)` | Reads unsigned 8-bit integer. |
| `dv:getInt8(offset)` | Reads signed 8-bit integer. |
| `dv:getUInt16(offset)` | Reads unsigned 16-bit integer (little-endian). |
| `dv:getInt16(offset)` | Reads signed 16-bit integer (little-endian). |
| `dv:getUInt32(offset)` | Reads unsigned 32-bit integer (little-endian). |
| `dv:getInt32(offset)` | Reads signed 32-bit integer (little-endian). |
| `dv:getFloat(offset)` | Reads 32-bit float (little-endian). |
| `dv:getDouble(offset)` | Reads 64-bit float (little-endian). |
| `dv:getSize()` | Returns the size of this view in bytes. |

## Lua Examples

```lua
-- Compression round-trip
function luna.init()
    local original = "Hello, Luna2D! Compress me!"
    local compressed = luna.data.compress("gzip", original, 6)
    local restored = luna.data.decompress("gzip", compressed)
    print(restored) -- "Hello, Luna2D! Compress me!"

    -- Hashing
    local digest = luna.data.hash("sha256", "secret data")
    print("SHA-256: " .. digest)

    -- Encoding
    local b64 = luna.data.encode("base64", "binary\0data")
    local decoded = luna.data.decode("base64", b64)

    -- Pack/unpack (LÖVE2D-compatible)
    local packed = luna.data.pack("<If", 42, 3.14)
    local val1, val2, next_pos = luna.data.unpack("<If", packed)
    print(val1, val2) -- 42, 3.14...

    -- ByteData
    local bd = luna.data.newByteData(16)
    bd:setByte(0, 255)
    print(bd:getByte(0)) -- 255
    print(bd:getSize())  -- 16

    -- DataView (read-only typed cursor)
    local raw = luna.data.pack("<Hf", 1000, 1.5)
    local dv = luna.data.newDataView(raw)
    print(dv:getUInt16(0)) -- 1000
    print(dv:getFloat(2))  -- 1.5

    -- Luna2D Binary Pack (named tokens)
    local buf = luna.data.write("u32 f32 str", 42, 3.14, "hello")
    local a, b, c = luna.data.read("u32 f32 str", buf)
    print(a, b, c) -- 42, 3.14..., "hello"

    -- TOML round-trip
    local tbl = luna.data.parseToml('title = "My Game"\nversion = 1')
    print(tbl.title)   -- "My Game"
    local toml_str = luna.data.encodeToml({ name = "Luna2D", debug = true })
    print(toml_str)
end
```

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 2 |
| `enum` | 5 |
| `fn` | 38 |
| **Total** | **45** |

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `engine` | Imports from | Uses `SharedState` via `Rc<RefCell<>>` in the Lua API registration |
| `math` | Imports from | Baseline dependency (no types currently used directly) |
| `lua_api` | Imported by | `data_api.rs` binds all public types and functions to `luna.data.*` |

**Similar modules**:

| Module | Differentiation |
|--------|-----------------|
| `image` | `ImageData` is a pixel buffer (RGBA8) for graphics; `ByteData` is raw bytes with no pixel semantics |
| `sound` | `SoundData` is interleaved PCM audio samples; `ByteData` is format-agnostic binary data |
| `filesystem` | Filesystem handles file I/O on disk; `data` processes in-memory byte buffers |

## Notes

- **Two pack systems**: The module deliberately ships two binary pack APIs. `pack.rs` (LÖVE2D-compatible) uses terse single-character format strings for familiarity with existing Lua game code. `bin_pack.rs` (Luna2D-native) uses space-separated named tokens for readability. Both produce `ByteData` output.
- **External crate versions**: flate2 1.x (deflate/gzip/zlib), lz4_flex 0.11 (LZ4), sha2 0.10, md-5 0.10, sha1 (latest), base64 (latest), hex (latest), toml (latest). These are all pure-Rust crates with no native C dependencies.
- **DataView uses `Arc`**: `DataView` wraps `Arc<Vec<u8>>` (not `Rc`) because it may be shared across multiple Lua userdata references. The Lua API creates a fresh `Arc` from the input string bytes.
- **No streaming**: All compression, hashing, and encoding operations work on complete in-memory buffers. There is no streaming/chunked API. This is intentional — Lua scripts operate on finite data.
- **Hash algorithms for integrity, not security**: MD5 and SHA-1 are included for compatibility (save file checksums, asset verification) but should not be used for cryptographic security. The docstrings document this.
- **Endianness defaults**: `pack.rs` defaults to little-endian (`<`); `bin_pack.rs` also defaults to little-endian (`le`). `DataView` reads are always little-endian with no endian-switch option.
- **TOML encode requires table root**: `encode_toml()` returns an error if the root value is not a `toml::Value::Table`. This matches the TOML specification where the root document is always a table.
- **Breaking change surface**: Renaming or removing any `luna.data.*` function breaks game scripts. The pack format strings (`<If`, `"u32 f32 str"`) are part of the API contract — changing token meanings would silently corrupt saved binary data.
