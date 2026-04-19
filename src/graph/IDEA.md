# IDEA — graph

| Field  | Value        |
| ------ | ------------ |
| Module | `graph`      |
| Path   | `src/graph/` |
| Date   | 2026-04-18   |
| Tier   | Foundations  |

## Mission

Provide a directed flow-simulation graph for Lurek2D: typed nodes and edges with capacity, cooldown, and type filtering; items that flow, decay, and convert; Dijkstra pathfinding; standard graph algorithms (components, cycles, topological sort, MST, A*, bipartite check, colouring); supply/demand routing; and debug render output — all exposed via `lurek.graph.*`.

## Strengths

- **Full simulation substrate** — not just a data-structure graph; items have decay, priority, transit progress, and conversion rules at nodes.
- **Comprehensive algorithm library** — connected components, cycle detection, topological sort, Kruskal MST, graph colouring, bipartite check, A*, Dijkstra — all in pure Rust with no external crate.
- **Event-driven simulation** — `update(dt)` returns a `Vec<GraphEvent>` covering enter/leave/decay/convert/queue/demand events, ready for Lua callback dispatch.

## Gaps

- `graph.rs` (619L) and `traversal.rs` (472L) are dead-code duplicates of `core.rs` and `pathfinding.rs` — not declared in `mod.rs` but still on disk.
- `rayon` is a hard dependency for `update_parallel()` — games that don't use graph simulation still pay the compile cost.
- All pathfinding scans `self.edges.values()` per node expansion — O(E) per relaxation step instead of adjacency-list O(deg).

## Features — Competitor Comparison

| Feature                    | Lurek2D (graph)              | LÖVE2D                     | Godot 4                   |
| -------------------------- | ---------------------------- | -------------------------- | ------------------------- |
| Flow simulation with items | ✅ Full push/pull/queue/decay | ❌ No built-in graph system | ❌ No item-flow graph      |
| Supply/demand auto-routing | ✅ Priority-ordered fulfil    | ❌ N/A                      | ❌ Manual via GDScript     |
| Graph algorithms (MST, A*) | ✅ 7+ algorithms built-in     | ❌ Manual or lib            | ✅ A* via AStarGrid2D only |

## Performance / Quality

- Dijkstra uses `BinaryHeap` min-heap; correct reverse-ordering via `Ord` impl on `DijkstraState`.
- Simulation runs phases in sequence: decay → transit → cooldowns → push/pull → conversions → queues.
- `update_parallel()` uses rayon only for the decay decrement phase; remaining phases are sequential due to mutable aliasing.
- Node/edge/item storage is `HashMap<u64, T>` — fine for graph sizes typical in games (<10k nodes).

## Test Gaps

- All 11 active source files have inline `#[cfg(test)]` suites — **no new tests needed**.
- `graph.rs` and `traversal.rs` also have tests but are dead code.
- Missing coverage: `update_parallel()` (rayon path), edge cooldown expiry edge cases, large-graph stress (>1000 nodes).

## TODO(dedup)

- [ ] Delete `graph.rs` (duplicate of `core.rs`) and `traversal.rs` (duplicate of `pathfinding.rs`) — both are dead code not declared in `mod.rs`.

## TODO(helper)

- [ ] Build adjacency-list index in `Graph` so pathfinding doesn't scan all edges per node.
- [ ] Add `Graph::subgraph(node_ids)` for extracting a subgraph (useful for component-isolated simulation).

## TODO(plugin)

- [ ] `TIER-1-PLUGIN` candidate — graph simulation is used by strategy/logistics games but not by platformers or visual novels.
- [ ] Plugin boundary: entire `src/graph/` behind a `graph` Cargo feature flag; `lurek.graph.*` namespace gated.
- [ ] `rayon` dependency can be feature-gated inside the plugin to avoid pulling it for non-graph games.

## Prior Ideas (Migrated)

- 🤔 CONSIDER — Algorithm Graph vs Flow Graph Naming — dual identity between `lurek.graph` (flow sim) and pure algorithms. Requires Lua-Designer decision.

## References

- `docs/specs/graph.md` — module spec
- `src/lua_api/graph_api.rs` — Lua bridge
- `tests/lua/unit/test_graph.lua` — Lua test suite
