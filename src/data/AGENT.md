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

## Purpose

The `data` module is Luna2D's pure-CPU data processing layer. It provides binary data
manipulation, compression, hashing, encoding, TOML conversion, and two independent binary
pack/unpack systems — all exposed to Lua scripts through the `luna.data` namespace.

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
| `mod.rs` | Re-exports all public types. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`specs/data.md`](../../specs/data.md)

_Update both this file **and** `specs/data.md` whenever source files, public types, or Lua bindings change._
