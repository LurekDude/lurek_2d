# src/window/

Window event loop integration with winit.

## What This Module Contains

Platform window creation and event loop management. Integrates with winit 0.30 ApplicationHandler pattern for cross-platform windowing.

## Files

| File | Purpose |
|------|---------|
| `event_loop.rs` | `EventLoop` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `(tested through engine_tests.rs)`
- **Lua API bindings**: `src/lua_api/window_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
