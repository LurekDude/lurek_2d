# src/pathfinding/

Grid-based pathfinding algorithms for game AI navigation.

## What This Module Contains

A* (classic grid pathfinding), HPA* (hierarchical for large maps), flow fields (crowd movement), NavGrid (walkability grid with dynamic obstacles), UnitPathfinder (unit-size-aware navigation), AsyncPool (background pathfinding on worker threads).

## Files

| File | Purpose |
|------|---------|
| `astar.rs` | `Astar` implementation |
| `async_pool.rs` | `AsyncPool` implementation |
| `flow_field.rs` | `FlowField` implementation |
| `hpa.rs` | `Hpa` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `nav_grid.rs` | `NavGrid` implementation |
| `unit_pathfinder.rs` | `UnitPathfinder` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/pathfinding_tests.rs`
- **Lua API bindings**: `src/lua_api/pathfinding_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
