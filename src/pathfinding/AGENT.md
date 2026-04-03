# `pathfinding` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 2 — Engine Extensions |
| **Lua API** | `luna.pathfinding` |
| **Source** | `src/pathfinding/` |
| **Tests** | `tests/pathfinding_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_pathfinding.lua` |

## Summary

The pathfinding module provides a multi-layer grid pathfinding stack for 2D
games.  The core layer is `PathGrid` / `NavGrid` — a weighted grid where each
cell has a traversal cost and blocked cells are treated as impassable —
supporting A* with octile (diagonal) or Manhattan heuristics and optional
Theta* post-processing for smooth, straight-looking paths.  The mid layer adds
`FlowField` (Dijkstra-sourced direction vectors for steering crowds of units
toward a single goal), `AiFlowField` (BFS-sourced variant), and Hierarchical
A* (`hpa.rs`) which pre-computes an abstract graph over chunk boundaries so
that long-range queries across large maps skip most of the fine-grained grid
and only refine to full resolution for the final local segments.  A thread pool
(`async_pool.rs`) dispatches path requests to worker threads so the game loop
is never blocked by expensive long-distance queries.

`UnitPathfinder` wraps the grid with a result cache and unit-size awareness —
a unit larger than one cell can be excluded from narrow passages by eroding the
walkable area according to the unit radius before running A*.  Province-level
pathfinding (`province_path.rs`) operates on a `ProvinceMap` adjacency graph
rather than a grid, enabling coarse strategic pathing (move army from province
A to province B via cheapest border crossings) without a pixel grid at all.

## Architecture

```
NavGrid / PathGrid (base cost grid)
  │
  ├── cell width/height, traversal costs, blocked set
  ├── DiagonalMode: None | Eight | OnlyWhenNoObstacles
  ├── A★ with octile/Manhattan heuristic (astar.rs)
  └── Theta★ path smoothing via line-of-sight checks
  │
  ├── FlowField (crowd steering)
  │     ├── goal cells → Dijkstra integration
  │     ├── direction vectors at every reachable cell
  │     └── query(x,y) → (dx, dy)
  │
  ├── HPA★ hierarchy (hpa.rs)
  │     ├── Chunk grid: divide NavGrid into N×N chunks
  │     ├── AbstractNode: entrance points on chunk boundaries
  │     ├── AbstractGraph: inter-chunk edges (pre-computed)
  │     └── hpa_star: coarse A★ → local refinement
  │
  ├── UnitPathfinder (caching wrapper)
  │     ├── Shared Arc<NavGrid>
  │     ├── Waypoint cache keyed by (start, goal)
  │     └── unit_radius → eroded passable set
  │
  ├── PathThreadPool (async_pool.rs)
  │     ├── Worker threads (rayon or std::thread)
  │     ├── Request queue: (id, start, goal)
  │     └── poll() → Option<(id, Vec<Waypoint>)>
  │
  └── ProvincePath (province_path.rs)
        ├── Operates on ProvinceMap adjacency graph
        ├── Centroid distance heuristic for A★
        └── Dijkstra reachability within cost budget
```

## Source Files

| File | Purpose |
|------|---------|
| `ai_flow_field.rs` | Dijkstra-based flow field for crowd pathfinding |
| `astar.rs` | A★ search with octile/Manhattan heuristic and Theta★ path smoothing |
| `async_pool.rs` | Thread pool for asynchronous path computation |
| `flow_field.rs` | Flow field pathfinding for steering many units toward one or more targets |
| `hpa.rs` | Hierarchical Pathfinding A★ (HPA★) for fast long-range queries |
| `nav_grid.rs` | Navigation grid with per-cell traversal costs and diagonal movement modes |
| `pathgrid.rs` | Weighted grid pathfinding (A*, Dijkstra) with obstacle support |
| `province_path.rs` | Province-level pathfinding on an adjacency graph using A* and Dijkstra |
| `unit_pathfinder.rs` | Unit-aware pathfinder with result caching and convenience methods |

## Submodules

### `pathfinding::ai_flow_field`

Dijkstra-based flow field for crowd pathfinding.

- **`FlowField`** (struct): BFS flow field that stores normalized direction vectors toward a goal.

### `pathfinding::astar`

A★ search with octile/Manhattan heuristic and Theta★ path smoothing.

- **`astar`** (fn): Run A★ search on `grid` from `start` to `goal`.
- **`line_of_sight`** (fn): Check line-of-sight between two cells using Bresenham's algorithm,
- **`smooth_path`** (fn): Smooth a path by removing unnecessary waypoints via line-of-sight checks

### `pathfinding::async_pool`

Thread pool for asynchronous path computation.

- **`PathResult`** (type): A completed path result returned by [`PathThreadPool::poll`].
- **`PathThreadPool`** (struct): A pool of worker threads that process pathfinding requests asynchronously.

### `pathfinding::flow_field`

Flow field pathfinding for steering many units toward one or more targets.

- **`FlowField`** (struct): A pre-computed flow field that stores a direction vector and integrated cost for every cell, guiding any unit toward...

### `pathfinding::hpa`

Hierarchical Pathfinding A★ (HPA★) for fast long-range queries.

- **`AbstractEdge`** (struct): An edge in the abstract graph connecting two entrance nodes.
- **`AbstractNode`** (struct): A node in the abstract graph, representing an entrance point on a chunk boundary.
- **`Chunk`** (struct): A chunk region of the grid used during abstract graph construction.
- **`AbstractGraph`** (struct): Pre-computed abstract graph for hierarchical A★ queries.
- **`build_abstract`** (fn): Build the abstract graph from a `NavGrid`.
- **`hpa_star`** (fn): Run HPA★ from `start` to `goal` on the abstract graph, then refine to tiles.
- **`is_reachable`** (fn): Check if `goal` is reachable from `start` using the abstract graph.

### `pathfinding::nav_grid`

Navigation grid with per-cell traversal costs and diagonal movement modes.

- **`DiagonalMode`** (enum): Controls how diagonal movement is handled during pathfinding.
- **`NavGrid`** (struct): A 2D grid of traversal costs used by pathfinding algorithms.  Cells are addressed with 0-based `(x, y)` coordinates in...

### `pathfinding::pathgrid`

Weighted grid pathfinding (A*, Dijkstra) with obstacle support.

- **`Cell`** (struct): Single cell of the navigation grid. Consult the module-level documentation for the broader usage context and...
- **`PathGrid`** (struct): A★ navigation grid. Consult the module-level documentation for the broader usage context and preconditions.

### `pathfinding::province_path`

Province-level pathfinding on an adjacency graph using A* and Dijkstra.

- **`ProvincePath`** (struct): A path through the province adjacency graph.
- **`ProvinceCostFn`** (struct): Configurable cost function for province pathfinding.  `tag_costs` adds extra cost when crossing an edge with matching...
- **`find_province_path`** (fn): Find a path between two provinces using A* with centroid distance heuristic.
- **`province_reachable`** (fn): Find all provinces reachable from `start` within a cost budget using Dijkstra.  Returns a map of `province_id →...

### `pathfinding::unit_pathfinder`

Unit-aware pathfinder with result caching and convenience methods.

- **`Waypoint`** (struct): A waypoint along a computed path. Consult the module-level documentation for the broader usage context and...
- **`UnitPathfinder`** (struct): A pathfinder that operates on a shared `NavGrid` with optional result caching.

## Key Types

### Structs

#### `pathfinding::hpa::AbstractEdge`

An edge in the abstract graph connecting two entrance nodes.

#### `pathfinding::hpa::AbstractGraph`

Pre-computed abstract graph for hierarchical A★ queries.

#### `pathfinding::hpa::AbstractNode`

A node in the abstract graph, representing an entrance point on a chunk boundary.

#### `pathfinding::pathgrid::Cell`

Single cell of the navigation grid. Consult the module-level documentation for the broader usage context and...

#### `pathfinding::hpa::Chunk`

A chunk region of the grid used during abstract graph construction.

#### `pathfinding::ai_flow_field::FlowField`

BFS flow field that stores normalized direction vectors toward a goal.

#### `pathfinding::flow_field::FlowField`

A pre-computed flow field that stores a direction vector and integrated cost for every cell, guiding any unit toward...

#### `pathfinding::nav_grid::NavGrid`

A 2D grid of traversal costs used by pathfinding algorithms.  Cells are addressed with 0-based `(x, y)` coordinates in...

#### `pathfinding::pathgrid::PathGrid`

A★ navigation grid. Consult the module-level documentation for the broader usage context and preconditions.

#### `pathfinding::async_pool::PathThreadPool`

A pool of worker threads that process pathfinding requests asynchronously.

#### `pathfinding::province_path::ProvinceCostFn`

Configurable cost function for province pathfinding.  `tag_costs` adds extra cost when crossing an edge with matching...

#### `pathfinding::province_path::ProvincePath`

A path through the province adjacency graph.

#### `pathfinding::unit_pathfinder::UnitPathfinder`

A pathfinder that operates on a shared `NavGrid` with optional result caching.

#### `pathfinding::unit_pathfinder::Waypoint`

A waypoint along a computed path. Consult the module-level documentation for the broader usage context and...

### Enums

#### `pathfinding::nav_grid::DiagonalMode`

Controls how diagonal movement is handled during pathfinding.

### Type Aliases

#### `pathfinding::async_pool::PathResult`

A completed path result returned by [`PathThreadPool::poll`].

## Public Functions

- **`astar()`** `astar::` — Run A★ search on `grid` from `start` to `goal`.
- **`build_abstract()`** `hpa::` — Build the abstract graph from a `NavGrid`.
- **`find_province_path()`** `province_path::` — Find a path between two provinces using A* with centroid distance heuristic.
- **`hpa_star()`** `hpa::` — Run HPA★ from `start` to `goal` on the abstract graph, then refine to tiles.
- **`is_reachable()`** `hpa::` — Check if `goal` is reachable from `start` using the abstract graph.
- **`line_of_sight()`** `astar::` — Check line-of-sight between two cells using Bresenham's algorithm,
- **`province_reachable()`** `province_path::` — Find all provinces reachable from `start` within a cost budget using Dijkstra.  Returns a map of `province_id →...
- **`smooth_path()`** `astar::` — Smooth a path by removing unnecessary waypoints via line-of-sight checks

## Lua API

Exposed under `luna.pathfinding.*` by `src/lua_api/pathfinding_api/`.

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 1 |
| `fn` | 8 |
| `mod` | 9 |
| `struct` | 14 |
| `type` | 1 |
| **Total** | **33** |

