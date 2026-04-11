# `save` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | `lurek.save` |
| **Source** | `src/save/` |
| **Rust Tests** | `tests/rust/unit/savegame_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_savegame.lua`, `tests/lua/stress/test_savegame_stress.lua`, `tests/lua/security/test_savegame_validation.lua`, `tests/lua/integration/test_save_entity.lua`, `tests/lua/integration/test_savegame_tilemap.lua`, `tests/lua/integration/test_savegame_entity_scene.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The `save` module provides slot-based savegame coordination for Lua-driven games. It tracks registered save collectors, restore callbacks, schema versions, dirty state, auto-save timing, and slot metadata while keeping the actual save payload in a Lua-serializable value model.

It exists so save orchestration, migration bookkeeping, and slot metadata do not get scattered across gameplay modules. Systems can register what they need to persist, and the save manager provides a stable place to coordinate schema upgrades and slot lifecycle.

It intentionally does not own general filesystem policy, encryption, cloud sync, binary serialization, or rollback history. The module focuses on save structure and coordination; higher layers decide when and where files are read or written.

**Scope boundary**: This module currently depends on `runtime`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.save.* (Lua API — src/lua_api/save_api.rs)
    |
    v
src/save/mod.rs
    |- save_data.rs - save_data
    |- save_manager.rs - save_manager
```

---

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | Declares the save submodules and re-exports the public save manager, value, metadata, and serialization-facing types. |
| `save_data.rs` | Holds an alternate save-data type definition set that currently lives in the module tree but is not the primary surface re-exported from `mod.rs`. |
| `save_manager.rs` | Implements `SaveManager`, slot metadata, schema versioning, dirty tracking, collector registration, restore hooks, and auto-save timing. |

---

## Submodules

### `save::save_data`

Holds an alternate save-data type definition set that currently lives in the module tree but is not the primary surface re-exported from `mod.rs`.

- **`SlotMeta`** (struct): Metadata extracted from a save-slot header without loading the full save data.
- **`SaveManager`** (struct): Pure-data save manager providing registration of named collectors, schema versioning, dirty-state tracking, and auto-save timer.
- **`SaveValue`** (enum): A simple value type matching the Lua subset we can serialize.

### `save::save_manager`

Implements `SaveManager`, slot metadata, schema versioning, dirty tracking, collector registration, restore hooks, and auto-save timing.

- **`SlotMeta`** (struct): Metadata extracted from a save slot.
- **`SaveManager`** (struct): Pure-data save manager providing registration of named collectors, schema versioning, dirty-state tracking, and auto-save timer.
- **`SaveValue`** (enum): A simple value type matching the Lua subset we can serialize.

---

## Key Types

### Public Types

#### `SaveManager`

The central save coordination object.

#### `SaveValue`

The Lua-serializable value enum used to represent saved data trees without depending on arbitrary engine internals.

#### `SlotMeta`

Metadata describing a save slot, such as name, timestamp, version, and summary fields.

---

## Lua API

Exposed under `lurek.save.*` by `src/lua_api/save_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.save.newSaveManager` | Creates a new SaveManager for slot-based save/load operations. |

### `SaveManager` Methods

| Method | Description |
|--------|-------------|
| `savemanager:unregister(...)` | Removes a named module and its callbacks. |
| `savemanager:setSchemaVersion(...)` | Sets the current schema version for new saves. |
| `savemanager:getSchemaVersion(...)` | Returns the current schema version. |
| `savemanager:collect(...)` | Collects data from all registered collectors into a table with metadata. |
| `savemanager:restore(...)` | Restores data from a table, applying migrations and calling restorers. |
| `savemanager:markDirty(...)` | Marks data as modified since the last save or load. |
| `savemanager:isDirty(...)` | Returns whether data has been modified since the last save or load. |
| `savemanager:disableAutoSave(...)` | Disables auto-save. |
| `savemanager:update(...)` | Advances the auto-save timer, returning the slot name if a save should trigger. |
| `savemanager:setSummary(...)` | Sets the summary string included in save metadata. |
| `savemanager:getSummary(...)` | Returns the current summary string. |
| `savemanager:reset(...)` | Resets all state, removing callbacks and clearing the manager. |
| `savemanager:save(...)` | Collects data and writes it to a slot file. |
| `savemanager:load(...)` | Loads data from a slot file, applies migrations, and restores. |
| `savemanager:delete(...)` | Deletes a save file for the given slot. |
| `savemanager:exists(...)` | Returns whether a save file exists for the given slot. |
| `savemanager:getSlots(...)` | Returns a list of all save slots with metadata. |
| `savemanager:getSlotInfo(...)` | Returns metadata for a single slot, or nil if not found. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.save.
if lurek.save then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 4 |
| `enum` | 2 |
| `fn` (Lua API) | 19 |
| **Total** | **25** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Feature Systems to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/save/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
