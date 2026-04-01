# src/thread/

Thread infrastructure for background Lua execution.

## What This Module Contains

Channel provides type-safe inter-thread communication backed by Rust mpsc channels. Worker spawns background Lua VMs on OS threads for compute-heavy tasks without blocking the main game loop.

## Files

| File | Purpose |
|------|---------|
| `channel.rs` | `Channel` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `worker.rs` | `Worker` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/thread_tests.rs`
- **Lua API bindings**: `src/lua_api/thread_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
