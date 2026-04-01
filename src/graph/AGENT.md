# src/graph/

Directed graph with item flow simulation for logistics and economy modeling.

## What This Module Contains

Nodes, edges, typed items. Simulation supports decay, transit delays, push/pull flow, conversions, and queues. Dijkstra pathfinding. Supply/demand modeling. Graph algorithms (topological sort, cycle detection, reachability).

## Files

| File | Purpose |
|------|---------|
| `algorithms.rs` | `Algorithms` implementation |
| `core.rs` | `Core` implementation |
| `edge.rs` | `Edge` implementation |
| `item.rs` | `Item` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `node.rs` | `Node` implementation |
| `simulation.rs` | `Simulation` implementation |
| `supply_demand.rs` | `SupplyDemand` implementation |
| `traversal.rs` | `Traversal` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/graph_tests.rs`
- **Lua API bindings**: `src/lua_api/graph_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
