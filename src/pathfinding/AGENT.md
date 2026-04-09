# Module

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.pathfinding`                                   |
| **Source**      | `src/pathfinding/`                                   |
| **Rust Tests** | `tests/unit/pathfinding_tests.rs`                    |
| **Lua Tests**  | `tests/lua/unit/test_pathfinding.lua`                |
| **Architecture** | —                                                  |

## Purpose

The pathfinding module provides a comprehensive multi-layer grid pathfinding stack for 2D games, covering everything from simple A★ grid searches to hierarchical long-range navigation and crowd-steering flow fields. The module is organized around three grid abstractions — `NavGrid`, `PathGrid`, and `Grid` — each serving different use cases: `NavGrid` is the primary u8-cost grid used by the A★ engine, HPA★ hierarchy, flow fields, and the `UnitPathfinder` wrapper; `PathGrid` is a legacy f32-cost grid from the former `ai/pathgrid` with built-in A★, Dijkstra, and string-pulling; `Grid` is a standalone grid supporting A★, Dijkstra, BFS, and flow field generation with f32 costs. The A★ implementation in `astar.rs` supports octile and Manhattan heuristics, partial paths with node expansion limits, unit-size-aware footprint checking, and Theta★ line-of-sight path smoothing. `FlowField` provides Dijkstra-sourced direction vectors for steering crowds of units toward single or multiple targets with integrated cost queries and world-space velocity steering. `AiFlowField` (in `ai_flow_field.rs`) is a simpler BFS-based variant for basic walkability grids. Hierarchical A★ (`hpa.rs`) pre-computes an abstract graph by dividing the `NavGrid` into chunks, finding entrance pairs on chunk boundaries, and connecting intra-chunk entrances via local A★ — enabling fast long-range queries that skip fine-grained grid search. `UnitPathfinder` wraps `NavGrid` with LRU path caching, unit-radius-aware passability checks, partial path support, nearest-walkable BFS, flood-fill reachability, and heuristic distance queries. `PathThreadPool` dispatches A★ requests to background worker threads with cancellation support, keeping the game loop unblocked for expensive queries. Graph-level pathfinding (`graph_path.rs`) operates on abstract adjacency graphs with centroid-based A★ and Dijkstra reachability within cost budgets — suitable for province maps, world graphs, or any sparse neighbor topology without relying on a grid. `InfluenceMap` provides a multi-layer spatial float grid for strategic AI reasoning, supporting circular influence stamping with linear falloff, 3×3 averaging propagation, decay, rectangular queries, and weighted layer blending.

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

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/pathfinding.md`](../../docs/specs/pathfinding.md)

_Update both this file **and** `docs/specs/pathfinding.md` whenever source files, public types, or Lua bindings change._
