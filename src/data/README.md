# `src/data/` — Data Processing Utilities

## Purpose

The data module provides a runtime key-value store and a TOML serialisation
surface that together fill the gap between ephemeral Lua local variables and
full save-game persistence.  Global game flags, player preferences,
cross-scene statistics, and configuration values live here: any Lua script can
read or write a named key without passing values through the call stack or
storing them in globals.

The TOML marshaller (`luna.data.parseToml` / `luna.data.encodeToml`) handles
the full TOML value space — strings, integers, floats, booleans, datetime
strings, inline tables, and arrays — mapping each TOML type to the nearest Lua
equivalent and back with round-trip fidelity for typical config patterns.
Beyond TOML the module also exposes hash functions (MD5, SHA-1, CRC32) for
save-data integrity checksums and deflate/inflate compression for binary
storage and network transfer.

## Architecture

```
data/
  │
  ├── ByteData ── Vec<u8> wrapper with Lua UserData interface
  │
  ├── compress ── deflate / gzip / lz4 / zlib (level 0-9)
  │
  ├── encode ── base64 / hex encoding and decoding
  │
  ├── hash ── md5 / sha1 / sha256 / sha512 → hex string
  │
  └── toml_convert ── parse_toml / encode_toml for TOML ↔ Lua table
```

### How It Works

The key-value store is a `HashMap<String, LuaValue>` anchored in
`SharedState`.  It does not persist to disk automatically — writing is an
explicit two-step: `luna.data.encodeToml(store)` → `luna.filesystem.write()`.
This keeps the I/O boundary explicit and the module logic pure and unit-testable
without touching the filesystem.

TOML parsing delegates to the `toml` crate.  The conversion walks
`toml::Value` recursively: tables become Lua tables, arrays become
integer-keyed Lua tables, scalars map to Lua equivalents.  The reverse path
(`encodeToml`) performs the same recursive walk on a Lua table; non-serialisable
values (functions, userdata) are silently skipped with a log warning rather
than returning an error, which matches typical Lua serialisation conventions.

Hash and compression functions accept either a `string` or an `ImageData`
userdata from Lua and are implemented as thin wrappers over the `crc32fast`,
`md5`, and `flate2` crates.  They are synchronous — suitable for small
payloads.  Large-file compression should use the `compute/` module's background
thread path.

### Dependency Direction

```
data/ ──────► (none)
```

**Leaf module** — no Luna2D dependencies. Uses only external crates (flate2, lz4_flex,
base64, md-5, sha1/sha2, toml).

---

## File-by-File Analysis

### `mod.rs` — Module Root

Re-exports all public types and functions.

**~10 lines** — pure re-exports.

---

### `byte_data.rs` — `ByteData` (Binary Data Wrapper)

**~106 lines** | Wraps `Vec<u8>` with Lua UserData methods for binary data manipulation.

#### Struct: `ByteData`

```rust
pub struct ByteData {
    data: Vec<u8>,
}
```

Methods: `new`, `from_vec`, `len`, `get_byte`, `set_byte`, `append`, `slice`,
`to_string` (lossy UTF-8), `as_bytes`.

Lua UserData methods: `getSize`, `getByte`, `setByte`, `getString`, `append`, `slice`.

---

### `compress.rs` — Compression

**~88 lines** | Compression and decompression with four format options.

#### Enum: `CompressFormat`

`Deflate | Gzip | Lz4 | Zlib`

| Function | Purpose |
|----------|---------|
| `compress(data, format, level)` | Compress bytes (level 0–9) |
| `decompress(data, format)` | Decompress bytes |

---

### `encode.rs` — Encoding

**~47 lines** | Base64 and hex encoding/decoding.

#### Enum: `EncodeFormat`

`Base64 | Hex`

| Function | Purpose |
|----------|---------|
| `encode(data, format)` | Bytes → string |
| `decode(string, format)` | String → bytes |

---

### `hash.rs` — Hashing

**~58 lines** | Cryptographic hashing returning hex strings.

#### Enum: `HashAlgorithm`

`Md5 | Sha1 | Sha256 | Sha512`

| Function | Returns |
|----------|---------|
| `hash(data, algorithm)` | Hex-encoded hash string |

---

### `toml_convert.rs` — TOML Conversion

**~16 lines** | Thin wrappers around the `toml` crate.

| Function | Purpose |
|----------|---------|
| `parse_toml(string)` | TOML string → Rust `toml::Value` |
| `encode_toml(value)` | Rust value → TOML string |

**Note**: The Lua API uses `luna.data.parseToml` and `luna.data.encodeToml`.

---

## Cross-Cutting Concerns

### Lua Integration

The Lua bridge lives in `src/lua_api/data_api.rs` (~180 lines), exposing
functions under `luna.data.*`.

### Usage from Lua

```lua
-- Compression
local compressed = luna.data.compress("hello world", "deflate")
local original = luna.data.decompress(compressed, "deflate")

-- Hashing
local hash = luna.data.hash("password", "sha256")

-- Base64
local encoded = luna.data.encode(data, "base64")

-- TOML
local config = luna.data.parseToml(toml_string)
local output = luna.data.encodeToml(config_table)
```
