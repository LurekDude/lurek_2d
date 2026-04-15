# IDEA.md — `serial` module

> Migrated from `ideas/features/serial.md`.
> Status checked against `src/serial/` and `src/lua_api/serial_api.rs`.
> Lua namespace: `lurek.codec`.

---

## Features

### ✅ DONE — JSON Encode / Decode
**Source**: features/serial.md — Summary

`lurek.codec.encodeJson(tbl, pretty?)` / `lurek.codec.decodeJson(str)`.

---

### ✅ DONE — TOML Encode / Decode
**Source**: features/serial.md — Summary

`lurek.codec.encodeToml(tbl, pretty?)` / `lurek.codec.decodeToml(str)`.

---

### ✅ DONE — CSV Encode / Decode
**Source**: features/serial.md — Summary

`lurek.codec.encodeCsv(rows, headers?)` / `lurek.codec.decodeCsv(str, headers?)`.

---

### ✅ DONE — MessagePack Encode / Decode (HIGH PRIORITY)
**Source**: features/serial.md — Feature Gaps #1 / Suggestions #1

`src/serial/msgpack.rs` — domain module using `rmp-serde 1`.
`lurek.codec.encodeMsgPack(tbl)` → binary string.
`lurek.codec.decodeMsgPack(bytes)` → Lua table.
Round-trips via `MsgValue` serde mirror. Registered in `src/lua_api/serial_api.rs`.
Tests: `tests/lua/unit/test_serial_msgpack.lua`.

```lua
local bytes = lurek.codec.encodeMsgPack(tbl)
local tbl   = lurek.codec.decodeMsgPack(bytes)
```

---

### ✅ DONE — XML Decode (Read-Only)
**Source**: features/serial.md — Feature Gaps #3 / Suggestions #2

`src/serial/xml.rs` — domain module using `roxmltree 0.20` (already in Cargo.toml).
`lurek.codec.decodeXml(str)` → nested Lua table with keys `tag`, `attrs`, `text`, `children`.
Registered in `src/lua_api/serial_api.rs`.
Tests: `tests/lua/unit/test_serial_xml.lua`.

```lua
local tbl = lurek.codec.decodeXml(str)
```

---

### ✅ DONE — Schema Validation
**Source**: features/serial.md — Feature Gaps #5 / Suggestions #3

`src/serial/schema.rs` — pure Rust, no external crates.
`lurek.codec.validate(tbl, schema)` → `(true, nil)` or `(false, error_string)`.
Schema fields: `type`, `required`, `min`, `max`, `minlen`, `maxlen`, `fields`, `items`.
Registered in `src/lua_api/serial_api.rs`.
Tests: `tests/lua/unit/test_serial_schema.lua`.

---

### 🤔 CONSIDER — Unified Format Parameter API
**Source**: features/serial.md — Suggestions #4

Instead of format-specific functions, a single:
```lua
lurek.codec.encode(tbl, "json")
lurek.codec.decode(str, "json")
```
Easier to switch formats programmatically. Both APIs could co-exist.
