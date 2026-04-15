# IDEA.md — `save` module

> Migrated from `ideas/features/savegame.md`.
> Status checked against `src/save/` and `src/lua_api/save_api.rs`.
> Lua namespace: `lurek.savegame`.

---

## Features

### ✅ DONE — Save Slots with Metadata
**Source**: features/savegame.md — Summary

Named slots with metadata (timestamp, playtime, custom data). `lurek.savegame.save(slot, data, meta)`.

---

### ✅ DONE — Auto-Save
**Source**: features/savegame.md — Summary

Auto-save support implemented.

---

### ✅ DONE — Save Versioning
**Source**: features/savegame.md — Summary

Version field and schema version tracking implemented in domain module.

---

### ✅ DONE — Save Migration Framework
**Source**: features/savegame.md — Feature Gaps #2 / Suggestions #1

`saveManager:addMigration(fromVersion, fn)` implemented at `save_api.rs:311`.
`apply_migrations()` runs all applicable upgrades on load at `save_api.rs:90`.
Migration keys stored in `HashMap<i32, LuaRegistryKey>`.

---

### ✅ DONE — Integrity Checking (Checksum)
**Source**: features/savegame.md — Summary

Checksum validation on file read implemented.

---

### ✅ DONE — Save Compression
**Source**: features/savegame.md — Feature Gaps #5 / Suggestions #2

LZ4 + base64 compression added to `LuaSaveManager`. Enable via `saveManager:setCompress(true)`.
Check state with `saveManager:isCompressed()`. Files are auto-detected on load via `--[[COMPRESSED]]` header.

---

### ✅ DONE — Save Event Hooks (`onBeforeSave`, `onAfterLoad`)
**Source**: features/savegame.md — Feature Gaps #7 / Suggestions #5

`saveManager:onBeforeSave(fn)` and `saveManager:onAfterLoad(fn)` added to `LuaSaveManager`.
Callbacks receive the `slotName` string. Pass `nil` to remove an existing callback.

---

### ❌ DEFERRED — Entity Serialization Bridge
**Source**: features/savegame.md — Structural Issues / Suggestions #4

Needs design alignment with `lurek.ecs`. Deferred.

---

### ❌ DEFERRED — Screenshot Thumbnail Attachment
**Source**: features/savegame.md — Feature Gaps #4 / Suggestions #3

Needs render module integration. Deferred.

---

### ❌ DEFERRED — Incremental / Delta Saves
**Source**: features/savegame.md — Feature Gaps #1

Complex implementation. Deferred until save profiling shows this is a bottleneck.
