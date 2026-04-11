# data

## Module Info
- Module name: `data`
- Module group: `Foundations`
- Spec path: `docs/specs/data.md`
- Lua API path(s): `src/lua_api/data_api.rs`
- Rust test path(s): `tests/rust/unit/data_tests.rs`; `tests/rust/stress/data_stress_tests.rs`; inline tests in `src/data/byte_data.rs`, `src/data/encode.rs`, `src/data/hash.rs`
- Lua test path(s): `tests/lua/unit/test_data.lua`; `tests/lua/stress/test_data_stress.lua`; `tests/lua/stress/test_data_compression_stress.lua`; `tests/lua/integration/test_data_system.lua`; `tests/lua/integration/test_data_filesystem.lua`; `tests/lua/integration/test_data_compute.lua`; `tests/lua/integration/test_thread_data.lua`; `tests/lua/golden/test_data_golden.lua`

## Module Purpose
The `data` module owns in-memory binary data processing for Lurek2D. It gives the engine and Lua scripts a common place for mutable byte buffers, typed read-only byte views, binary packing formats, compression, binary-to-text encoding, and hashing.

This module exists so scripting-facing systems can move bytes around without depending on platform I/O or renderer-specific types. The central abstractions are `ByteData` for owned mutable buffers and `DataView` for safe typed reads over shared bytes; the surrounding helpers build on those to support serialization, asset preprocessing, save payload handling, and interop with Lua code.

`data` intentionally does not own filesystem access, streaming I/O, structured tabular analysis, or most human-authored text formats. It does currently include TOML conversion helpers and exposes them through `lurek.data`, but JSON, CSV, YAML, and broader text codec responsibilities live in `src/serial/`.

## Files
- `mod.rs`: Re-exports the public binary-data surface and keeps callers from importing individual helpers ad hoc.
- `bin_pack.rs`: Implements the Lurek2D-native binary pack format with readable named tokens such as `u32`, `f64`, `str`, and endian modifiers.
- `byte_data.rs`: Defines the owned byte-buffer type used to construct, mutate, clone, and expose raw bytes to Lua.
- `compress.rs`: Provides whole-buffer compression and decompression for deflate, gzip, zlib, and LZ4 formats.
- `dataview.rs`: Implements a read-only typed cursor over shared bytes with bounds-checked little-endian accessors.
- `encode.rs`: Handles base64 and hex encoding and decoding for binary payload transport.
- `hash.rs`: Computes MD5, SHA-1, SHA-256, and SHA-512 digests over in-memory data.
- `pack.rs`: Implements the LÖVE-style single-character binary pack and unpack format used for compact compatibility-oriented serialization.
- `toml_convert.rs`: Converts between TOML text and `toml::Value` trees for the Lua-facing TOML helpers.

## Key Types
- `ByteData`: Primary owned byte buffer for Lua and Rust interop. It is the mutable container that other helpers serialize into or read from.
- `DataView`: Read-only window over shared bytes with typed accessors. It exists for cheap inspection of binary payloads without copying or mutating them.
- `LuaDataView`: Lua-facing wrapper over `DataView`. Keeping it separate lets the domain type stay free of Lua-specific method registration.
- `BinValue`: Tagged value enum used by the named-token pack format. It is the bridge between dynamically typed inputs and strongly typed binary writes and reads.
- `PackValue`: Tagged value enum used by the LÖVE-compatible pack format. It preserves the compatibility surface independently from the native `BinValue` format.
- `CompressFormat`: Supported compression backends for whole-buffer compression and decompression. It keeps format parsing and dispatch explicit rather than stringly typed deep in the implementation.
- `EncodeFormat`: Supported binary-to-text encoding modes. It is the small dispatch enum behind the base64 and hex helpers.
- `HashAlgorithm`: Supported digest algorithms for byte hashing. It centralizes algorithm parsing so the Lua API and Rust callers use the same accepted names.