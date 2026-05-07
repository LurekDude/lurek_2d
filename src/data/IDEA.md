# IDEA — `src/data/`

> **This file is forward-looking.** It records ideas, not commitments.

---

## 1. Header

- **Module**: `data`
- **Owner module path**: `src/data/`
- **Last reviewed**: 2026-04-18 (UTC)
- **Reviewer agent**: `developer` · Session: `src-module-review-20260418`
- **Plugin tier candidacy**: `CORE-KEEP`
- **LOC (rust only)**: ~1400 · **Public Lua surface**: `lurek.data` — 30+ fns / 2 userdata (ByteData, DataView)
- **Inbound non-`lua_api` callers**: `log::sinks` (VecDeque ring), `serial` (encode/hash utilities)
- **Heavy dependencies**: `flate2`, `lz4_flex`, `sha2`, `md-5`, `base64`, `hex`, `rmp-serde`

## 2. Mission Summary

The `data` module provides Lurek2D's binary-data toolkit: byte buffers with typed get/set, compression (deflate/gzip/lz4/zlib), hashing (md5/sha256/crc32), encoding (base64/hex), struct packing, ring buffers, TOML conversion helpers, and MessagePack serialization. It serves EngDev (binary protocol parsing), GameDev (save-data encoding), and Modder (binary file I/O). It is NOT a database or ORM layer.

## 3. Existing Strengths

- `ByteData` gives C-struct-like typed access (get/set u8..f64, little/big endian) over a raw byte buffer — covers binary format parsing.
- `DataView` adds cursor-based sequential read over a ByteData buffer, useful for streaming formats.
- Four compression formats in one clean API: `compress(data, fmt, level)` / `decompress(data, fmt)`.
- RingBuffer is generic `<T: Clone>` and allocation-free after construction.
- `pack` / `bin_pack` implement Lua-style struct.pack format strings.

## 4. Gap List

1. ~~**[P2][GAP]** No streaming compression — `compress()` takes the entire `&[u8]` at once; large assets cause a full copy.~~ ✅ **DONE** — Added `compress_stream`, `decompress_stream`, `compress_chunks`, and `decompress_chunks` in `src/data/compress.rs`, plus Lua `lurek.data.compressChunks` and `lurek.data.decompressChunks`.
   - ~~Why: Compressing a 50 MB save file doubles peak memory.~~
2. **[P3][GAP]** `DataView` has no write cursor — read-only sequential access; building binary messages requires manual offset math on `ByteData`.
   - Why: GameDev sending binary network packets must track write offsets manually.

## 5. Feature Ideas

1. ~~**[P3][FEAT]** `DataWriter` — write-cursor companion to `DataView` for building binary messages sequentially.~~ ✅ **DONE** — `DataWriter` added to `src/data/data_writer.rs`. Methods: `write_u8`, `write_u32_le`, `write_string`, `seek`, `tell`, `len`, `into_bytes`, and more. Lua: `lurek.data.newWriter()` returns a DataWriter userdata.
   - ~~Rationale: Symmetric read/write API simplifies binary protocol work for GameDev.~~
   - ~~Effort: M · Risk: low.~~
   - ~~Competitor inspiration: [love2d: "love.data.ByteData with string.pack for binary protocols" — https://love2d.org/wiki/ByteData]~~
2. ~~**[P3][FEAT]** Streaming compress/decompress via reader/writer wrappers — chunk-based for large data.~~ ✅ **DONE** — Implemented reader/writer stream APIs and chunk-based helpers in Rust core; exposed chunked API in Lua.
   - ~~Rationale: Prevents 2x peak memory for large files.~~
   - ~~Effort: M · Risk: low.~~

## 6. Performance / Reliability / Quality Ideas

- **[P3][PERF]** `RingBuffer::to_vec` clones every element — for large T types, consider an iterator adapter instead.
  - Hot path: `ring_buffer.rs:to_vec`.
  - Verification: benchmark with 10k-element ring of 1 KB structs.
- **[P3][QUAL]** `toml_convert.rs` and `msgpack.rs` are thin wrappers (~40 LOC each) — consider inlining into `serial` module to reduce file count.
  - File / type: `toml_convert.rs`, `msgpack.rs`.
  - Reason: clarity — these are serialization concerns, not data-buffer concerns.

## 7. Test Coverage Gaps

- **[P2][TEST-RUST]** ~~Add Rust unit tests for `DataView` cursor operations~~ — DONE (2026-04-18): 13 tests in `dataview.rs`.
- **[P2][TEST-RUST]** ~~Add Rust unit tests for `pack.rs` / `bin_pack.rs` pack/unpack round-trips~~ — DONE (2026-04-18): 9 additional tests in `pack.rs`, 8 additional tests in `bin_pack.rs`.
- **[P2][TEST-RUST]** Add Rust unit tests for `msgpack.rs` — DONE (2026-04-18): 9 tests in `msgpack.rs`.
- **[P2][TEST-RUST]** Add Rust unit tests for `toml_convert.rs` — DONE (2026-04-18): 7 tests in `toml_convert.rs`.
- **[P2][TEST-LUA]** Add Lua BDD test for `lurek.data.compress` + `lurek.data.decompress` round-trip (all 4 formats).

## 8. TODO(dedup): Cross-Module Overlap

TODO(dedup): serial::msgpack — `data::msgpack` and `serial::msgpack` both wrap `rmp-serde`; consider merging into one canonical location.
TODO(dedup): log::sinks — `MemorySink` uses `VecDeque` as a bounded ring, duplicating `data::RingBuffer` semantics.

## 9. TODO(helper): Engine-Level Helper Candidates

~~TODO(helper): `lurek.data.crc32(str)` — expose CRC-32 for quick checksum needs (asset validation); currently only md5/sha256 are in the Lua surface.~~ ✅ **DONE** — Added `data::crc32(data: &[u8]) -> u64` + `lurek.data.crc32(str)` Lua binding (via `crc32fast` crate).

## 10. TODO(plugin): Plugin Candidacy Proposal

TODO(plugin): CORE-KEEP — data buffers, compression, and hashing are used by save, network, asset, and serial modules. Extracting would orphan most data-dependent subsystems.
- **Extraction blockers**: `ByteData` used by serial, save, network modules.
- **Heavy dep impact if extracted**: flate2 + lz4_flex + sha2 = ~200 KB binary overhead (acceptable).
- **Lua surface stability**: stable.
- **Migration step**: n/a.

## 11. References

- Module spec: [docs/specs/data.md](../../../docs/specs/data.md)
- Lua API reference: [docs/API/lua-api.md#data](../../../docs/API/lua-api.md)
- Plugin doc tier table: [plugins.md §5](../../../docs/architecture/plugins.md#5-candidate-modules)
- Competitor links cited above: https://love2d.org/wiki/ByteData
- Authoring guide: [IDEA_AUTHORING.md](../../work/src-module-review-20260418/reports/IDEA_AUTHORING.md)
