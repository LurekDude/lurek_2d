# src/lua_api/

Lua bindings layer — all luna.* namespace APIs exposed to game scripts.

## What This Module Contains

35 API binding files. SharedState struct holds all mutable engine state (resource pools, input states, draw commands, config). create_lua_vm() initializes the Lua VM with sandboxed stdlib and registers all API modules. Each module follows the register(lua, luna_table, state) pattern.

## Files

| File | Purpose |
|------|---------|
| `ai_api.rs` | `AiApi` implementation |
| `audio_api.rs` | `AudioApi` implementation |
| `compute_api.rs` | `ComputeApi` implementation |
| `data_api.rs` | `DataApi` implementation |
| `dataframe_api.rs` | `DataframeApi` implementation |
| `debug_api.rs` | `DebugApi` implementation |
| `debugbridge_api.rs` | `DebugbridgeApi` implementation |
| `docs_api.rs` | `DocsApi` implementation |
| `entity_api.rs` | `EntityApi` implementation |
| `event_api.rs` | `EventApi` implementation |
| `filesystem_api.rs` | `FilesystemApi` implementation |
| `graph_api.rs` | `GraphApi` implementation |
| `graphics_api.rs` | `GraphicsApi` implementation |
| `graphics_ext_api.rs` | `GraphicsExtApi` implementation |
| `image_api.rs` | `ImageApi` implementation |
| `input_api.rs` | `InputApi` implementation |
| `localization_api.rs` | `LocalizationApi` implementation |
| `log_api.rs` | `LogApi` implementation |
| `lua_types.rs` | `LuaTypes` implementation |
| `math_api.rs` | `MathApi` implementation |
| `math_ext_api.rs` | `MathExtApi` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `modding_api.rs` | `ModdingApi` implementation |
| `particle_api.rs` | `ParticleApi` implementation |
| `pathfinding_api.rs` | `PathfindingApi` implementation |
| `patterns_api.rs` | `PatternsApi` implementation |
| `physics_api.rs` | `PhysicsApi` implementation |
| `savegame_api.rs` | `SavegameApi` implementation |
| `scene_api.rs` | `SceneApi` implementation |
| `sound_api.rs` | `SoundApi` implementation |
| `system_api.rs` | `SystemApi` implementation |
| `thread_api.rs` | `ThreadApi` implementation |
| `tilemap_api.rs` | `TilemapApi` implementation |
| `timer_api.rs` | `TimerApi` implementation |
| `window_api.rs` | `WindowApi` implementation |

## Navigation

- **Owner agent**: `Developer / Lua-Designer`
- **Tests**: `tests/lua_tests.rs`
- **Lua API bindings**: `(this is the API layer itself)`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
