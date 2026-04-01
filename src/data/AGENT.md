# src/data/

Binary data manipulation, compression, hashing, and encoding utilities.

## What This Module Contains

ByteData for raw byte buffers. Compression: deflate, gzip, zlib (flate2), LZ4 (lz4_flex). Hashing: MD5, SHA-1, SHA-256, SHA-512. Encoding: base64, hex. TOML parsing and encoding (toml crate).

## Files

| File | Purpose |
|------|---------|
| `byte_data.rs` | `ByteData` implementation |
| `compress.rs` | `Compress` implementation |
| `encode.rs` | `Encode` implementation |
| `hash.rs` | `Hash` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `toml_convert.rs` | `TomlConvert` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/data_tests.rs, tests/stress/data_stress_tests.rs`
- **Lua API bindings**: `src/lua_api/data_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
