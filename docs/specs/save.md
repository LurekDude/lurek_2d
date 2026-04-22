# save

## General Info

- Module group: `Feature Systems`
- Source path: `src/save/`
- Lua API path(s): `src/lua_api/save_api.rs`
- Primary Lua namespace: `lurek.save`
- Rust test path(s): tests/rust/unit/savegame_tests.rs
- Lua test path(s): tests/lua/unit/test_save.lua, tests/lua/stress/test_save_stress.lua, tests/lua/security/test_save_validation.lua, tests/lua/integration/test_save_ecs.lua, tests/lua/integration/test_save_tilemap.lua, tests/lua/integration/test_save_ecs_scene.lua

## Summary

The `save` module provides Lurek2D's game save/load orchestration system. It focuses on lifecycle management — coordinating when and what to save, handling schema versioning, running migrations, and driving auto-save — rather than on byte serialization (that responsibility belongs to `serial`).

`SaveManager` is the core type: it maintains a registry of named collector module names (Lua callbacks that gather/restore game state), a current schema version integer, a dirty flag that becomes true when save data has changed, an optional auto-save config (interval in seconds + slot name), and a list of migration version checkpoints. `SlotMeta` describes one save slot: name string, Unix timestamp, schema version when saved, and a user-readable summary string. `SaveValue` is the Lua-compatible value enum (nil, bool, number, string, table) used for Rust-side serialization. `serialize_table` / `serialize_value` produce Lua-syntax return strings. `SaveValue::from_lua` converts `mlua::Value` to `SaveValue`.

Save operations work through the collector pattern: Lua registers named modules whose `gather()` / `restore()` callbacks are invoked by SaveManager. Schema versioning compares slot metadata against the current version and runs ordered migration functions. Auto-save triggers when the dirty flag is set and the configured interval elapses.

**Note**: `save_data.rs` exists in the source tree but is NOT declared in `mod.rs` — it is dead code containing an older copy of the same types. The canonical implementation lives in `save_manager.rs`. The duplicate types and functions listed below from `save_data.rs` are NOT compiled or reachable.

**Scope boundary**: Feature Systems tier. Depends on `filesystem`, `runtime`, `serial`. Lua bridge in `src/lua_api/save_api.rs`.

## Files

- `mod.rs`: Declares the save submodules and re-exports the public save manager, value, metadata, serialization-facing types, and compression helpers.
- `save_data.rs`: Holds an alternate save-data type definition set that currently lives in the module tree but is not the primary surface re-exported from `mod.rs`.
- `save_manager.rs`: Implements `SaveManager`, slot metadata, schema versioning, dirty tracking, collector registration, restore hooks, auto-save timing, and save-file compression helpers (`compress_save_content`, `decompress_save_content`).

## Types

- `SlotMeta` (`struct`, `save_data.rs`): Metadata describing a save slot, such as name, timestamp, version, and summary fields.
- `SaveManager` (`struct`, `save_data.rs`): The central save coordination object. It owns collectors, restore callbacks, schema versioning, dirty state, auto-save timers, and slot metadata handling.
- `SaveValue` (`enum`, `save_data.rs`): The Lua-serializable value enum used to represent saved data trees without depending on arbitrary engine internals.
- `SlotMeta` (`struct`, `save_manager.rs`): Metadata describing a save slot, such as name, timestamp, version, and summary fields.
- `SaveManager` (`struct`, `save_manager.rs`): The central save coordination object. It owns collectors, restore callbacks, schema versioning, dirty state, auto-save timers, and slot metadata handling.
- `SaveValue` (`enum`, `save_manager.rs`): The Lua-serializable value enum used to represent saved data trees without depending on arbitrary engine internals.

## Functions

- `SaveManager::new` (`save_data.rs`): Create a new empty SaveManager.
- `SaveManager::register` (`save_data.rs`): Register a named collector module.
- `SaveManager::unregister` (`save_data.rs`): Removes a previously registered data collector from the save/restore cycle.
- `SaveManager::registered_names` (`save_data.rs`): Get registered module names.
- `SaveManager::set_schema_version` (`save_data.rs`): Set the current schema version.
- `SaveManager::schema_version` (`save_data.rs`): Returns the schema version number used to detect save-file format upgrades.
- `SaveManager::add_migration` (`save_data.rs`): Record a migration version key.
- `SaveManager::applicable_migrations` (`save_data.rs`): Get migration versions >=`from` and < current, in ascending order.
- `SaveManager::mark_dirty` (`save_data.rs`): Mark data as dirty (modified since last save/load).
- `SaveManager::is_dirty` (`save_data.rs`): Whether data is dirty.
- `SaveManager::clear_dirty` (`save_data.rs`): Clear the dirty flag (called after save/load).
- `SaveManager::enable_auto_save` (`save_data.rs`): Enable auto-save with interval and target slot.
- `SaveManager::disable_auto_save` (`save_data.rs`): Disables the automatic save timer, preventing any further background saves.
- `SaveManager::update` (`save_data.rs`): Advance the auto-save timer.
- `SaveManager::reset` (`save_data.rs`): Reset all state.
- `serialize_table` (`save_data.rs`): Serialize a simple Lua-compatible value hierarchy into a `return { ...
- `serialize_value` (`save_data.rs`): Serialize a single value.
- `SaveManager::new` (`save_manager.rs`): Create a new empty SaveManager.
- `SaveManager::register` (`save_manager.rs`): Register a named collector module.
- `SaveManager::unregister` (`save_manager.rs`): Unregister a collector by name.
- `SaveManager::registered_names` (`save_manager.rs`): Get registered module names.
- `SaveManager::set_schema_version` (`save_manager.rs`): Set the current schema version.
- `SaveManager::schema_version` (`save_manager.rs`): Get the current schema version.
- `SaveManager::add_migration` (`save_manager.rs`): Record a migration version key.
- `SaveManager::applicable_migrations` (`save_manager.rs`): Get migration versions >=`from` and < current, in ascending order.
- `SaveManager::mark_dirty` (`save_manager.rs`): Mark data as dirty (modified since last save/load).
- `SaveManager::is_dirty` (`save_manager.rs`): Whether data is dirty.
- `SaveManager::clear_dirty` (`save_manager.rs`): Clear the dirty flag (called after save/load).
- `SaveManager::enable_auto_save` (`save_manager.rs`): Enable auto-save with interval and target slot.
- `SaveManager::disable_auto_save` (`save_manager.rs`): Disable auto-save.
- `SaveManager::update` (`save_manager.rs`): Advance the auto-save timer.
- `SaveManager::reset` (`save_manager.rs`): Reset all state.
- `SaveManager::slot_path` (`save_manager.rs`): Build the save file path for a given slot name.
- `SaveManager::set_summary` (`save_manager.rs`): Set the summary string for save metadata.
- `SaveManager::summary` (`save_manager.rs`): Get the summary string.
- `SaveManager::parse_save_string` (`save_manager.rs`): Validates and returns save-file content, rejecting empty input.
- `serialize_table` (`save_manager.rs`): Serialize a simple Lua-compatible value hierarchy into a `return { ...
- `serialize_value` (`save_manager.rs`): Serialize a single value.
- `SaveValue::from_lua` (`save_manager.rs`): Converts a [`LuaValue`] into a [`SaveValue`] for Rust-side serialization.

## Lua API Reference

- Binding path(s): `src/lua_api/save_api.rs`
- Namespace: `lurek.save`

### Module Functions
- `lurek.save.newSaveManager`: Creates a new SaveManager for slot-based save/load operations.

### `SaveManager` Methods
- `SaveManager:unregister`: Removes a named module and its callbacks
- `SaveManager:setSchemaVersion`: Sets the current schema version for new saves
- `SaveManager:getSchemaVersion`: Returns the current schema version
- `SaveManager:collect`: Collects data from all registered collectors into a table with metadata
- `SaveManager:restore`: Restores data from a table, applying migrations and calling restorers
- `SaveManager:markDirty`: Marks data as modified since the last save or load
- `SaveManager:isDirty`: Returns whether data has been modified since the last save or load
- `SaveManager:disableAutoSave`: Disables automatic periodic saving; manual `write()` calls still work.
- `SaveManager:update`: Advances the auto-save timer, returning the slot name if a save should trigger
- `SaveManager:setSummary`: Sets the summary string included in save metadata
- `SaveManager:getSummary`: Returns the current summary string
- `SaveManager:reset`: Resets all state, removing callbacks and clearing the manager
- `SaveManager:setCompress`: Enables or disables LZ4 compression for saved data
- `SaveManager:isCompressed`: Returns whether compression is currently enabled.
- `SaveManager:onBeforeSave`: Registers a callback that fires before every save operation.
- `SaveManager:onAfterLoad`: Registers a callback that fires after every successful load operation.
- `SaveManager:save`: Collects data and writes it to a slot file.
- `SaveManager:load`: Loads data from a slot file, applies migrations, and restores.
- `SaveManager:delete`: Deletes a save file for the given slot.
- `SaveManager:exists`: Returns whether a save file exists for the given slot.
- `SaveManager:getSlots`: Returns a list of all save slots with metadata.
- `SaveManager:getSlotInfo`: Returns metadata for a single slot, or nil if not found.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/save/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
