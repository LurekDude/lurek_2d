---
description: "Create a new tilemap feature (layer type, autotile rule, collision mapping, or TMX extension). Follow the tilemap module's existing patterns for TileSet, TileMap, AutoTileSheet, IsoMap, and ChunkMap."
---

# Create Tilemap Feature

## Prerequisites

- Read `src/tilemap/mod.rs` for module structure and exports
- Read `src/lua_api/tilemap_api.rs` for existing Lua bindings
- Read `tests/tilemap_tests.rs` for test patterns
- Load the `tilemap-rendering` skill

## Steps

1. **Define the feature scope**
   - Which tilemap type is affected? (TileMap, IsoMap, ChunkMap, AutoTileSheet, TileSet)
   - Is this a new layer type, a new operation, or an extension to existing behavior?
   - Does it affect TMX (Tiled) import/export?

2. **Implement in Rust**
   - Add types/methods to `src/tilemap/` following existing patterns
   - Use `pub` for cross-module types, `pub(crate)` when possible
   - Error handling: `EngineError` for internal errors, `LuaResult` for Lua-facing functions
   - Respect dependency direction: tilemap may depend on math, must NOT depend on graphics/engine

3. **Add Lua bindings** (if user-facing)
   - Add to `src/lua_api/tilemap_api.rs` following the `register()` pattern
   - Namespace: `luna.tilemap.*`
   - Closures capture `Rc<RefCell<SharedState>>` — clone Rc before moving into closure
   - Return `LuaResult<T>` from all Lua-callable functions

4. **Write tests**
   - Add integration tests to `tests/tilemap_tests.rs`
   - Test helper: `create_test_vm()` for Lua-level tests
   - Test edge cases: empty maps, single tile, maximum dimensions
   - Float comparisons: `(a - b).abs() < 1e-5`

5. **Update documentation**
   - Add `///` doc comments to all public items
   - Update `docs/API/lua_api_reference_generated.md` via `python tools/gen_lua_api.py`

## Acceptance Criteria

- [ ] Feature compiles with 0 clippy warnings
- [ ] Integration tests pass
- [ ] Lua bindings follow `luna.tilemap.*` naming
- [ ] Public types have `///` doc comments
- [ ] No dependency direction violations
