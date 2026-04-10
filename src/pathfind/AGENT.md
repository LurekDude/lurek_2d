# Module

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.pathfinding`                                   |
| **Source**      | `src/pathfind/`                                   |
| **Rust Tests** | `tests/unit/pathfinding_tests.rs`                    |
| **Lua Tests**  | `tests/lua/unit/test_pathfinding.lua`                |
| **Architecture** | —                                                  |

## Purpose

The `pathfinding` module provides a multi-layer grid pathfinding stack for 2D games: simple A★ search via `NavGrid`, hierarchical long-range navigation via HPA abstract graphs, and crowd-steering flow fields. `AsyncPathPool` dispatches parallel path requests to worker threads. `UnitPathfinder` provides per-entity waypoint following. See `docs/specs/pathfinding.md`.

## Source Files

| File                | Purpose                                                                          |
|---------------------|----------------------------------------------------------------------------------|
| `mod.rs`            | Module declaration, public re-exports, and type aliases                          |
| `ai_flow_field.rs`  | BFS-based flow field for simple walkability grids (moved from `ai/flowfield`)    |
| `astar.rs`          | A★ search with octile/Manhattan heuristic, line-of-sight, and Theta★ smoothing   |
| `async_pool.rs`     | Thread pool for asynchronous off-thread A★ path computation                      |
| `flow_field.rs`     | Dijkstra-based flow field for NavGrid with multi-target and world-space steering |
| `graph_path.rs`     | Adjacency-graph A★ and Dijkstra for province maps and sparse neighbor topologies |
| `grid.rs`           | Standalone 2D grid with A★, Dijkstra, BFS pathfinding and flow field generation  |
| `hpa.rs`            | Hierarchical Pathfinding A★ (HPA★): chunk abstraction, entrance detection, tile refinement |
| `influence_map.rs`  | Multi-layer spatial float grid for influence mapping and strategic AI reasoning   |
| `nav_grid.rs`       | Navigation grid with u8 per-cell costs, diagonal modes, dirty rects, and snapshot |
| `pathgrid.rs`       | Weighted f32-cost grid with Cell type, A★, and string-pulling (moved from `ai/pathgrid`) |
| `unit_pathfinder.rs`| Unit-size-aware pathfinder with LRU caching, partial paths, BFS nearest-walkable |

## Key Types

| Type | Description |
|------|-------------|
| `FlowField` | Principal type for the `pathfinding` module. |
| `PathThreadPool` | Principal type for the `pathfinding` module. |
| `ProvincePath` | Principal type for the `pathfinding` module. |
| `ProvinceCostFn` | Principal type for the `pathfinding` module. |
| `Grid` | Principal type for the `pathfinding` module. |
| `AbstractEdge` | Principal type for the `pathfinding` module. |
| `AbstractNode` | Principal type for the `pathfinding` module. |
| `Chunk` | Principal type for the `pathfinding` module. |
| `AbstractGraph` | Principal type for the `pathfinding` module. |
| `InfluenceMap` | Principal type for the `pathfinding` module. |
| `DiagonalMode` | Principal type for the `pathfinding` module. |
| `NavGrid` | Principal type for the `pathfinding` module. |

## Lua API Summary

| Function | Description |
|----------|-------------|
| `lurek.pathfinding.newNavGrid()` | See `docs/specs/pathfinding.md`. |
| `lurek.pathfinding.newPathfinder()` | See `docs/specs/pathfinding.md`. |
| `lurek.pathfinding.newFlowField()` | See `docs/specs/pathfinding.md`. |
| `lurek.pathfinding.newPathGrid()` | See `docs/specs/pathfinding.md`. |
| `lurek.pathfinding.newPathFlowField()` | See `docs/specs/pathfinding.md`. |
| `lurek.pathfinding.setThreadCount()` | See `docs/specs/pathfinding.md`. |
| `lurek.pathfinding.getThreadCount()` | See `docs/specs/pathfinding.md`. |
| `lurek.pathfinding.newNavGridFromTileMap()` | See `docs/specs/pathfinding.md`. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/pathfinding.md`](../../docs/specs/pathfinding.md)

_Update both this file **and** `docs/specs/pathfinding.md` whenever source files, public types, or Lua bindings change._
