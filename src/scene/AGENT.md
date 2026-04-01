# src/scene/

Scene stack for managing game scene lifecycle and transitions.

## What This Module Contains

LIFO stack of Lua scene tables with lifecycle callbacks (enter, exit, update, draw, pause, resume). Animated transitions (fade, slide, custom). Named scene registry for direct access. DepthSorter for y-sorted or z-ordered rendering within scenes.

## Files

| File | Purpose |
|------|---------|
| `depth_sorter.rs` | `DepthSorter` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `stack.rs` | `Stack` implementation |
| `transition.rs` | `Transition` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/scene_tests.rs`
- **Lua API bindings**: `src/lua_api/scene_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
