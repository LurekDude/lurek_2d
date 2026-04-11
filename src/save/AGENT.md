# save

## Module Info
- Module name: `save`
- Module group: `Feature Systems`
- Spec path: `docs/specs/save.md`
- Lua API path(s): `src/lua_api/save_api.rs`
- Rust test path(s): `tests/rust/unit/savegame_tests.rs`
- Lua test path(s): `tests/lua/unit/test_savegame.lua`, `tests/lua/stress/test_savegame_stress.lua`, `tests/lua/security/test_savegame_validation.lua`, `tests/lua/integration/test_save_entity.lua`, `tests/lua/integration/test_savegame_tilemap.lua`, `tests/lua/integration/test_savegame_entity_scene.lua`

## Module Purpose
The `save` module provides slot-based savegame coordination for Lua-driven games. It tracks registered save collectors, restore callbacks, schema versions, dirty state, auto-save timing, and slot metadata while keeping the actual save payload in a Lua-serializable value model.

It exists so save orchestration, migration bookkeeping, and slot metadata do not get scattered across gameplay modules. Systems can register what they need to persist, and the save manager provides a stable place to coordinate schema upgrades and slot lifecycle.

It intentionally does not own general filesystem policy, encryption, cloud sync, binary serialization, or rollback history. The module focuses on save structure and coordination; higher layers decide when and where files are read or written.

## Files
- `mod.rs` - Declares the save submodules and re-exports the public save manager, value, metadata, and serialization-facing types.
- `save_data.rs` - Holds an alternate save-data type definition set that currently lives in the module tree but is not the primary surface re-exported from `mod.rs`.
- `save_manager.rs` - Implements `SaveManager`, slot metadata, schema versioning, dirty tracking, collector registration, restore hooks, and auto-save timing.

## Key Types
- `SaveManager` - The central save coordination object. It owns collectors, restore callbacks, schema versioning, dirty state, auto-save timers, and slot metadata handling.
- `SaveValue` - The Lua-serializable value enum used to represent saved data trees without depending on arbitrary engine internals.
- `SlotMeta` - Metadata describing a save slot, such as name, timestamp, version, and summary fields.
