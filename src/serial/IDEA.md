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

### ❌ TODO — MessagePack Encode / Decode (HIGH PRIORITY)
**Source**: features/serial.md — Feature Gaps #1 / Suggestions #1

No binary MessagePack. Required for compact save data, efficient network payloads,
and large dataset exchange. Much smaller and faster to parse than JSON.

```lua
local bytes = lurek.codec.encodeMsgPack(tbl)
local tbl   = lurek.codec.decodeMsgPack(bytes)
```

---

### ❌ TODO — XML Decode (Read-Only)
**Source**: features/serial.md — Feature Gaps #3 / Suggestions #2

No XML parsing. Required for Tiled TMX map import and third-party tool interop.
Encoding XML is lower priority — read-only decode covers most game use cases.

```lua
local tbl = lurek.codec.decodeXml(str)
```

---

### ❌ TODO — Schema Validation
**Source**: features/serial.md — Feature Gaps #5 / Suggestions #3

No `lurek.codec.validate(tbl, schema)`. Useful for validating decoded save data
against expected structure during migration and for network protocol safety.

---

### 🤔 CONSIDER — Unified Format Parameter API
**Source**: features/serial.md — Suggestions #4

Instead of format-specific functions, a single:
```lua
lurek.codec.encode(tbl, "json")
lurek.codec.decode(str, "json")
```
Easier to switch formats programmatically. Both APIs could co-exist.
