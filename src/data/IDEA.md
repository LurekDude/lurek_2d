# IDEA.md — `data` module

> Migrated from `ideas/features/data.md`.
> Status checked against `src/data/` and `src/lua_api/data_api.rs`.
> Lua namespace: `lurek.data`.

---

## Features

### ✅ DONE — Typed DataView (Typed Array Views)
**Source**: features/data.md — Feature Gaps #5

`DataView` and `LuaDataView` exist in `src/data/dataview.rs` and are exposed as
`lurek.data.newDataView()` in `data_api.rs` (line ~315). Provides windowed typed-access
over a ByteData buffer.

---

### ✅ DONE — Binary Pack / Unpack
**Source**: features/data.md (related)

`pack.rs` with `PackValue` helpers exposed in `data_api.rs`. Structured binary packing and
unpacking of typed values into/from byte buffers.

---

### ❌ TODO — MessagePack Serialization
**Source**: features/data.md — Feature Gaps #1 / Suggestions #2

No `toMsgPack(table)` / `fromMsgPack(bytes)` found. MessagePack is efficient binary
serialization useful for networking and save files. The `data/pack.rs` custom format exists
but MessagePack provides standard interoperability.

---

### ✅ DONE — Bit-Level Operations
**Source**: features/data.md — Feature Gaps #3 / Suggestions #3

✅ DONE (2026-04-15) — Added setBit, getBit, readBits as methods on ByteData in data_api.rs. Supports cross-byte bit reads.

---

### ❌ TODO — Ring Buffer
**Source**: features/data.md — Feature Gaps #4 / Suggestions #5

No circular/ring buffer in `src/data/`. Useful for streaming audio, network receive buffers,
and rolling history tracking patterns.

---

### 🤔 CONSIDER — Rename Module Namespace
**Source**: features/data.md — Structural Issues

`lurek.data` is very generic — the module specifically handles binary buffer manipulation.
Consider `lurek.buffer` or `lurek.binary` for clarity. This is a **breaking API change**
requiring MAJOR version bump and Lua-Designer sign-off.

---

### 🤔 CONSIDER — Clarify Boundary with `compute`
**Source**: features/data.md — Structural Issues

`data` = I/O-oriented binary manipulation (byte buffers, compression, hashing).
`compute` = mathematical operations on dense numerical arrays (NdArray).
This distinction is correct but undocumented. Add a one-liner to each module's docs and
`docs/specs/data.md` pointing to the other.
