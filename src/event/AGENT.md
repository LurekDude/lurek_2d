# src/event/

Event queue for polling system and custom events, plus Signal pub-sub.

## What This Module Contains

EventQueue provides FIFO polling alternative to callbacks. Signal type enables handle-based pub-sub event dispatching with connect/disconnect/emit semantics.

## Files

| File | Purpose |
|------|---------|
| `mod.rs` | Module root — re-exports and module-level docs |
| `signal.rs` | `Signal` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/event_tests.rs`
- **Lua API bindings**: `src/lua_api/event_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
