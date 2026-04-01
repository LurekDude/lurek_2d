# src/timer/

Frame-based clock and scheduled event management.

## What This Module Contains

Clock tracks delta time, total elapsed time, and FPS. Scheduler manages delayed and repeating timed callbacks with pause/resume support.

## Files

| File | Purpose |
|------|---------|
| `clock.rs` | `Clock` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `scheduler.rs` | `Scheduler` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/timer_tests.rs`
- **Lua API bindings**: `src/lua_api/timer_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
