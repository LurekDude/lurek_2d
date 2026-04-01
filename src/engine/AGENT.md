# src/engine/

Core engine lifecycle: application loop, configuration, error handling, and diagnostics.

## What This Module Contains

App drives the winit event loop via ApplicationHandler, fires luna.load/update/draw and all input callbacks, and holds every domain subsystem. Config loads from conf.lua. EngineError enum (thiserror). ErrorScreen renders blue error overlay. DebugOverlay for FPS/memory stats. ResourceKeys defines SlotMap typed keys.

## Files

| File | Purpose |
|------|---------|
| `app.rs` | `App` implementation |
| `config.rs` | `Config` implementation |
| `debug_overlay.rs` | `DebugOverlay` implementation |
| `error.rs` | `Error` implementation |
| `error_screen.rs` | `ErrorScreen` implementation |
| `log_messages.rs` | `LogMessages` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `resource_keys.rs` | `ResourceKeys` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/engine_tests.rs, tests/config_tests.rs`
- **Lua API bindings**: `src/lua_api/ (all modules register through engine)`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
