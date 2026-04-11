# `data` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Foundations |
| **Status** | Implemented |
| **Lua API** | `lurek.data` |
| **Source** | `src/data/` |
| **Rust Tests** | `tests/rust/unit/data_tests.rs`; `tests/rust/stress/data_stress_tests.rs`; inline tests in `src/data/byte_data.rs`, `src/data/encode.rs`, `src/data/hash.rs` |
| **Lua Tests** | `tests/lua/unit/test_data.lua`; `tests/lua/stress/test_data_stress.lua`; `tests/lua/stress/test_data_compression_stress.lua`; `tests/lua/integration/test_data_system.lua`; `tests/lua/integration/test_data_filesystem.lua`; `tests/lua/integration/test_data_compute.lua`; `tests/lua/integration/test_thread_data.lua`; `tests/lua/golden/test_data_golden.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Foundations` |

---

## Summary

The `data` module owns in-memory binary data processing for Lurek2D. It gives the engine and Lua scripts a common place for mutable byte buffers, typed read-only byte views, binary packing formats, compression, binary-to-text encoding, and hashing.

This module exists so scripting-facing systems can move bytes around without depending on platform I/O or renderer-specific types. The central abstractions are `ByteData` for owned mutable buffers and `DataView` for safe typed reads over shared bytes; the surrounding helpers build on those to support serialization, asset preprocessing, save payload handling, and interop with Lua code.

`data` intentionally does not own filesystem access, streaming I/O, structured tabular analysis, or most human-authored text formats. It does currently include TOML conversion helpers and exposes them through `lurek.data`, but JSON, CSV, YAML, and broader text codec responsibilities live in `src/serial/`.

**Scope boundary**: This module currently acts as a mostly self-contained part of the Foundations layer. Cross-module behavior should remain anchored to the top-level source files and Lua bindings listed below.

---

## Architecture

```
lurek.data.* (Lua API — src/lua_api/data_api.rs)
    |
    v
src/data/mod.rs
    |- bin_pack.rs - bin_pack
    |- byte_data.rs - byte_data
    |- compress.rs - compress
    |- dataview.rs - dataview
    |- encode.rs - encode
    |- hash.rs - hash
    |- pack.rs - pack
    |- toml_convert.rs - toml_convert
    |- ...
```

---

## Source Files

| File | Purpose |
|------|---------|
| `bin_pack.rs` | Implements the Lurek2D-native binary pack format with readable named tokens such as `u32`, `f64`, `str`, and endian modifiers. |
| `byte_data.rs` | Defines the owned byte-buffer type used to construct, mutate, clone, and expose raw bytes to Lua. |
| `compress.rs` | Provides whole-buffer compression and decompression for deflate, gzip, zlib, and LZ4 formats. |
| `dataview.rs` | Implements a read-only typed cursor over shared bytes with bounds-checked little-endian accessors. |
| `encode.rs` | Handles base64 and hex encoding and decoding for binary payload transport. |
| `hash.rs` | Computes MD5, SHA-1, SHA-256, and SHA-512 digests over in-memory data. |
| `mod.rs` | Re-exports the public binary-data surface and keeps callers from importing individual helpers ad hoc. |
| `pack.rs` | Implements the LÖVE-style single-character binary pack and unpack format used for compact compatibility-oriented serialization. |
| `toml_convert.rs` | Converts between TOML text and `toml::Value` trees for the Lua-facing TOML helpers. |

---

## Submodules

### `data::bin_pack`

Implements the Lurek2D-native binary pack format with readable named tokens such as `u32`, `f64`, `str`, and endian modifiers.

- **`BinValue`** (enum): A Lurek2D serializable binary value.

### `data::byte_data`

Defines the owned byte-buffer type used to construct, mutate, clone, and expose raw bytes to Lua.

- **`ByteData`** (struct): Contiguous byte buffer for binary data manipulation.

### `data::compress`

Provides whole-buffer compression and decompression for deflate, gzip, zlib, and LZ4 formats.

- **`CompressFormat`** (enum): Supported compression algorithms available through `lurek.data.compress()` and `lurek.data.decompress()`.

### `data::dataview`

Implements a read-only typed cursor over shared bytes with bounds-checked little-endian accessors.

- **`DataView`** (struct): A windowed, read-only view into a shared byte buffer.
- **`LuaDataView`** (struct): Lua-side wrapper around [`DataView`].

### `data::encode`

Handles base64 and hex encoding and decoding for binary payload transport.

- **`EncodeFormat`** (enum): Supported binary-to-text encoding formats for `lurek.data.encode()` and `lurek.data.decode()`.

### `data::hash`

Computes MD5, SHA-1, SHA-256, and SHA-512 digests over in-memory data.

- **`HashAlgorithm`** (enum): Supported cryptographic hash algorithms for `lurek.data.hash()`.

### `data::pack`

Implements the LÖVE-style single-character binary pack and unpack format used for compact compatibility-oriented serialization.

- **`PackValue`** (enum): A Rust-side value that can be packed into or unpacked from a binary buffer.

### `data::toml_convert`

Converts between TOML text and `toml::Value` trees for the Lua-facing TOML helpers.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

---

## Key Types

### Public Types

#### `ByteData`

Primary owned byte buffer for Lua and Rust interop.

#### `DataView`

Read-only window over shared bytes with typed accessors.

#### `LuaDataView`

Lua-facing wrapper over `DataView`.

#### `BinValue`

Tagged value enum used by the named-token pack format.

#### `PackValue`

Tagged value enum used by the LÖVE-compatible pack format.

#### `CompressFormat`

Supported compression backends for whole-buffer compression and decompression.

#### `EncodeFormat`

Supported binary-to-text encoding modes.

#### `HashAlgorithm`

Supported digest algorithms for byte hashing.

---

## Lua API

Exposed under `lurek.data.*` by `src/lua_api/data_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.data.pack` | Packs values into a binary byte string using the format string. |
| `lurek.data.unpack` | Unpacks values from a binary byte string, returning values followed by next offset. |
| `lurek.data.getPackedSize` | Returns the number of bytes the given format and values would occupy. |
| `lurek.data.compress` | Compresses data using the given algorithm (deflate, gzip, lz4). |
| `lurek.data.decompress` | Decompresses data using the given algorithm (deflate, gzip, lz4). |
| `lurek.data.encode` | Encodes binary data using the given format (base64, hex). |
| `lurek.data.decode` | Decodes encoded text back to binary (base64, hex). |
| `lurek.data.hash` | Returns the cryptographic hash of the input (md5, sha1, sha256, sha512). |
| `lurek.data.newByteData` | Creates a new mutable byte buffer from a size or string. |
| `lurek.data.newDataView` | Creates a read-only windowed view into a byte string. |
| `lurek.data.write` | Writes values using the Lurek2D Binary Pack Format. |
| `lurek.data.read` | Reads values using the Lurek2D Binary Pack Format. |
| `lurek.data.size` | Returns the byte size of a Lurek2D Binary Pack Format string. |
| `lurek.data.parseToml` | Parses a TOML string into a Lua table. |
| `lurek.data.encodeToml` | Encodes a Lua table into a TOML string. |

### `DataView` Methods

| Method | Description |
|--------|-------------|
| `dataview:getUInt8(...)` | Reads an unsigned 8-bit integer at the given offset. |
| `dataview:getInt8(...)` | Reads a signed 8-bit integer at the given offset. |
| `dataview:getInt16(...)` | Reads a signed 16-bit integer at the given offset. |
| `dataview:getUInt16(...)` | Reads an unsigned 16-bit integer at the given offset. |
| `dataview:getInt32(...)` | Reads a signed 32-bit integer at the given offset. |
| `dataview:getUInt32(...)` | Reads an unsigned 32-bit integer at the given offset. |
| `dataview:getFloat(...)` | Reads a 32-bit float at the given offset. |
| `dataview:getDouble(...)` | Reads a 64-bit float at the given offset. |
| `dataview:getSize(...)` | Returns the size of this view in bytes. |

### `mlua` Methods

| Method | Description |
|--------|-------------|
| `mlua:getSize(...)` | Lua-facing function documented in the binding source. |
| `mlua:getString(...)` | Lua-facing function documented in the binding source. |
| `mlua:getByte(...)` | Lua-facing function documented in the binding source. |
| `mlua:setByte(...)` | Lua-facing function documented in the binding source. |
| `mlua:clone(...)` | Lua-facing function documented in the binding source. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.data.
if lurek.data then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 3 |
| `enum` | 5 |
| `fn` (Lua API) | 29 |
| **Total** | **37** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| — | No top-level `crate::<module>` imports were detected in this module's source files. | Keep the source files as the primary dependency reference. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/data/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
