# savegame — Feature Analysis

**Tier**: 2 (Extension)
**Spec**: `specs/savegame.md`
**Files**: Save/load system

## Purpose

Game save system: serialize game state to files, manage save slots, versioning, integrity checking.

## Current Feature Summary

- Save slots with metadata (name, timestamp, playtime, custom data)
- Auto-save capability
- Save data serialization (Lua tables → binary/JSON)
- Save versioning for forward compatibility
- Integrity checking (checksum validation)
- Save directory management via GameFS
- Collect/restore pattern: gather state → serialize → write file, read file → deserialize → restore state
- Save slot listing, deletion, export
- Custom metadata per save

## Feature Gaps

1. **No incremental saves**: Must serialize entire game state every save. No delta/diff saves for large game states.
2. **No save migration**: Version field exists but no framework for automatically migrating saves between game versions (renaming fields, adding defaults).
3. **No cloud save support**: No integration with cloud storage for cross-device saves.
4. **No thumbnail generation**: Can't capture a screenshot to attach to save file for visual save selection.
5. **No save compression**: Large saves are stored uncompressed (could use `luna.data` compress).
6. **No encrypted saves**: Saves are readable/editable. No tamper protection.
7. **No save event hooks**: No `onBeforeSave`, `onAfterLoad` callbacks for cleanup.

## Structural Issues

- **Business logic in lua_api**: The spec mentions that collect/restore/serialize logic should be in the domain module, not in lua_api. If it's currently in the API layer, it should be extracted.
- **Correct tier placement**: Tier 2 is appropriate — save system builds on filesystem (Tier 1).
- **Entity integration missing**: No direct bridge to serialize entity/component state from entity module.

## Suggestions

1. **Add save migration framework**: `luna.savegame.registerMigration(fromVersion, toVersion, fn)` — transform save data during load when version doesn't match.
2. **Add save compression**: Use `luna.data.compress()` internally — saves should be compressed by default.
3. **Add screenshot attachment**: `luna.savegame.saveWithScreenshot(slot, data)` — capture current frame as thumbnail.
4. **Add entity serialization bridge**: `luna.savegame.saveEntities(universe)` / `luna.savegame.loadEntities(data, universe)` — seamless entity state persistence.
5. **Add save event hooks**: `luna.savegame.onBeforeSave(fn)` / `luna.savegame.onAfterLoad(fn)`.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Gideros |
|---|---|---|---|---|
| Save system | ✅ (built-in) | ❌ (manual) | ❌ (manual) | ❌ |
| Save slots | ✅ | N/A | N/A | N/A |
| Versioning | ✅ | N/A | N/A | N/A |
| Integrity check | ✅ | N/A | N/A | N/A |
| Auto-save | ✅ | N/A | N/A | N/A |
| Migration | ❌ | N/A | N/A | N/A |

Luna2D is unique in having a built-in save system. Most engines leave this entirely to the developer.

## Priority

**MEDIUM** — Save migration and entity serialization bridge are the highest-impact improvements. Compression should be default.
