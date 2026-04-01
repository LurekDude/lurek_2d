# src/modding/

Mod management framework for game extension loading.

## What This Module Contains

ModInfo struct for mod metadata (name, version, author, dependencies). ModManager handles registration, dependency resolution, load ordering, folder scanning, and hot-reload queuing.

## Files

| File | Purpose |
|------|---------|
| `mod.rs` | Module root — re-exports and module-level docs |
| `mod_manager.rs` | `ModManager` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/modding_tests.rs`
- **Lua API bindings**: `src/lua_api/modding_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
