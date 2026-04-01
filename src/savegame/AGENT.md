# src/savegame/

Save/load slot system with schema versioning and autosave.

## What This Module Contains

SaveData manages named save slots. Supports collectors for gathering game state, dirty tracking for change detection, auto-save by interval, and schema versioning for backward-compatible save migration.

## Files

| File | Purpose |
|------|---------|
| `mod.rs` | Module root — re-exports and module-level docs |
| `save_data.rs` | `SaveData` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/savegame_tests.rs`
- **Lua API bindings**: `src/lua_api/savegame_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
