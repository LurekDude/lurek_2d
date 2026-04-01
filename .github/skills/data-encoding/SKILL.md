---
name: data-encoding
description: "Load this skill when working with Luna2D data utilities: compression (deflate/gzip/lz4/zlib), hashing (MD5/SHA), encoding (base64/hex), TOML parsing, or binary ByteData buffers. Skip it for save game serialization, filesystem I/O, or asset loading."
---

# Data Encoding — Luna2D Engine

## Load When

- Compressing or decompressing data (deflate, gzip, lz4, zlib)
- Computing hashes (MD5, SHA-1, SHA-256, SHA-512)
- Encoding/decoding data (base64, hex)
- Parsing or generating TOML configuration
- Working with raw binary ByteData buffers
- Using `luna.data.*` API functions

## Owns

- `src/data/` module — ByteData, compression, hashing, encoding, TOML
- `src/lua_api/data_api.rs` — `luna.data.*` Lua bindings
- Format selection guidance for compression, hashing, and encoding

## Does Not Cover

- Save game serialization → use `save-data` skill
- Filesystem sandboxing → use `asset-pipeline` skill
- Network protocols → out of scope for Luna2D
- DataFrame/CSV → use separate dataframe module

## Live Repository Contracts

- `src/data/byte_data.rs` — `ByteData` (raw byte buffer manipulation)
- `src/data/compress.rs` — `compress()`, `decompress()`, `CompressFormat`
- `src/data/hash.rs` — `hash()`, `HashAlgorithm`
- `src/data/encode.rs` — `encode()`, `decode()`, `EncodeFormat`
- `src/data/toml_convert.rs` — TOML parsing and encoding
- `tests/data_tests.rs` — round-trip tests for all formats

## Decision Rules

- **TOML API uses `parseToml` and `encodeToml`** — these are the canonical function names
- **Compression is synchronous** — all operations block; use Workers for large data
- **Hash output is hex string** — all hash functions return lowercase hex-encoded digest
- **ByteData is 0-indexed** — byte positions start at 0, unlike Lua's 1-based indexing
- **lz4 is fastest** — use for real-time compression (save states, network)
- **gzip has best compatibility** — use for data exchange with external tools
- **SHA-256 is recommended** — use for integrity checks; MD5 and SHA-1 are legacy

## Format Selection

### Compression

| Format | Speed | Ratio | Use Case |
|---|---|---|---|
| `lz4` | Fastest | Lower | Real-time: save states, frame data, hot-path compression |
| `deflate` | Fast | Good | General purpose, small payloads |
| `zlib` | Fast | Good | Streaming data, protocol compatibility |
| `gzip` | Moderate | Good | File exchange, external tool compatibility |

### Hashing

| Algorithm | Speed | Security | Use Case |
|---|---|---|---|
| `md5` | Fastest | Broken | Legacy compatibility only — never for security |
| `sha1` | Fast | Weak | Legacy compatibility — prefer SHA-256 |
| `sha256` | Moderate | Strong | Integrity checks, data fingerprinting (recommended) |
| `sha512` | Moderate | Strongest | When maximum collision resistance needed |

### Encoding

| Format | Use Case |
|---|---|
| `base64` | Text-safe binary encoding (embedding in config, save files) |
| `hex` | Human-readable byte representation (debugging, display) |

## Best Practices

- Use lz4 for game save compression — fast enough for real-time
- Use SHA-256 for asset integrity verification
- Use base64 for embedding binary data in TOML/JSON config
- ByteData: check bounds before get/set — out-of-bounds returns 0, not error
- TOML: prefer for game configuration — matches Luna2D config format convention

## Anti-Patterns

- **MD5 for security**: Using MD5 for integrity where tampering is possible — use SHA-256
- **Compressing small data**: Compression overhead exceeds savings for data under ~100 bytes
- **Blocking main thread**: Compressing megabytes synchronously in `luna.update()` — use Worker thread
- **Wrong encoding**: Using hex for large binary data — base64 is 33% smaller than hex representation
