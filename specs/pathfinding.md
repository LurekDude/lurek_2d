# `pathfinding` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.pathfinding`                                   |
| **Source**      | `src/pathfinding/`                                   |
| **Rust Tests** | `tests/unit/pathfinding_tests.rs`                    |
| **Lua Tests**  | `tests/lua/unit/test_pathfinding.lua`                |
| **Architecture** | —                                                  |

## Summary

The pathfinding module provides a comprehensive multi-layer grid pathfinding stack for 2D games, covering everything from simple A★ grid searches to hierarchical long-range navigation and crowd-steering flow fields. The module is organized around three grid abstractions — `NavGrid`, `PathGrid`, and `Grid` — each serving different use cases: `NavGrid` is the primary u8-cost grid used by the A★ engine, HPA★ hierarchy, flow fields, and the `UnitPathfinder` wrapper; `PathGrid` is a legacy f32-cost grid from the former `ai/pathgrid` with built-in A★, Dijkstra, and string-pulling; `Grid` is a standalone grid supporting A★, Dijkstra, BFS, and flow field generation with f32 costs. The A★ implementation in `astar.rs` supports octile and Manhattan heuristics, partial paths with node expansion limits, unit-size-aware footprint checking, and Theta★ line-of-sight path smoothing. `FlowField` provides Dijkstra-sourced direction vectors for steering crowds of units toward single or multiple targets with integrated cost queries and world-space velocity steering. `AiFlowField` (in `ai_flow_field.rs`) is a simpler BFS-based variant for basic walkability grids. Hierarchical A★ (`hpa.rs`) pre-computes an abstract graph by dividing the `NavGrid` into chunks, finding entrance pairs on chunk boundaries, and connecting intra-chunk entrances via local A★ — enabling fast long-range queries that skip fine-grained grid search. `UnitPathfinder` wraps `NavGrid` with LRU path caching, unit-radius-aware passability checks, partial path support, nearest-walkable BFS, flood-fill reachability, and heuristic distance queries. `PathThreadPool` dispatches A★ requests to background worker threads with cancellation support, keeping the game loop unblocked for expensive queries. Graph-level pathfinding (`graph_path.rs`) operates on abstract adjacency graphs with centroid-based A★ and Dijkstra reachability within cost budgets — suitable for province maps, world graphs, or any sparse neighbor topology without relying on a grid. `InfluenceMap` provides a multi-layer spatial float grid for strategic AI reasoning, supporting circular influence stamping with linear falloff, 3×3 averaging propagation, decay, rectangular queries, and weighted layer blending.

## Architecture

```
luna.pathfinding (Lua API — pathfinding_api.rs)
  │
  ├── LuaNavGrid ─────────────────────────────────────────────────────
  │     └── NavGrid (nav_grid.rs)
  │           ├── u8 cost grid, 0=blocked, 1-255=cost
  │           ├── DiagonalMode: None | Always | NoCornerCut
  │           ├── HPA★ chunk_size, dirty_rects for incremental updates
  │           └── snapshot() for thread-safe cloning
  │
  ├── LuaUnitPathfinder ──────────────────────────────────────────────
  │     └── UnitPathfinder (unit_pathfinder.rs)
  │           ├── Shared Rc<RefCell<NavGrid>>
  │           ├── A★ (astar.rs): octile/Manhattan, Theta★ smoothing
  │           ├── LRU path cache (HashMap + Vec<CacheKey>)
  │           ├── unit_size footprint → multi-cell walkability
  │           ├── find_partial_path (node limit)
  │           ├── find_nearest_walkable (BFS)
  │           └── is_reachable (flood fill)
  │
  ├── LuaFlowField ──────────────────────────────────────────────────
  │     └── FlowField (flow_field.rs)
  │           ├── Dijkstra integration field from NavGrid
  │           ├── Single or multi-target, unit_size-aware
  │           ├── Normalised direction vectors per cell
  │           └── steer(world_x, world_y, speed, tile_w, tile_h)
  │
  ├── LuaPathGrid ───────────────────────────────────────────────────
  │     └── PathGrid (pathgrid.rs)
  │           ├── f32 cost grid with Cell { walkable, cost }
  │           ├── A★ with 8-dir corner-cut prevention
  │           └── find_path_smoothed (greedy string-pulling)
  │
  ├── LuaAiFlowField ────────────────────────────────────────────────
  │     └── ai_flow_field::FlowField
  │           ├── BFS-based (simple walkability, no costs)
  │           └── set_goal → recompute, get_direction, get_distance
  │
  ├── HPA★ (hpa.rs) ─────────────────────────────────────────────────
  │     ├── build_abstract: chunk grid → boundary entrances → intra-chunk A★
  │     ├── AbstractGraph { nodes, edges, chunks }
  │     ├── hpa_star: abstract A★ → local tile refinement
  │     └── is_reachable: chunk-level BFS connectivity
  │
  ├── PathThreadPool (async_pool.rs) ─────────────────────────────────
  │     ├── std::thread workers with mpsc channels
  │     ├── submit(id, grid_snapshot, start, goal, unit_size)
  │     ├── poll() → Vec<(id, Option<path>)>
  │     └── cancel(id) — best-effort cancellation
  │
  ├── Graph Pathfinding (graph_path.rs) ──────────────────────────────
  │     ├── find_province_path: A★ over adjacency graph + centroids
  │     ├── province_reachable: Dijkstra within cost budget
  │     └── ProvinceCostFn: tag_costs, province_costs, blocked set
  │
  ├── Grid (grid.rs) ────────────────────────────────────────────────
  │     ├── Standalone f32-cost grid
  │     ├── A★, Dijkstra, BFS pathfinding
  │     └── build_flow_field (Dijkstra-based)
  │
  └── InfluenceMap (influence_map.rs) ────────────────────────────────
        ├── Multi-layer float grid (named layers)
        ├── stamp_influence, propagate, decay
        ├── max_position, min_position, query_rect
        └── blend(layer_a, weight_a, layer_b, weight_b, dest)
```

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

## Submodules

### `pathfinding::ai_flow_field`

BFS-based flow field for simple walkability grids. Operates on a flat `Vec<bool>` walkability array rather than a cost grid. Moved from `ai/flowfield`; used by `luna.pathfinding.newPathFlowField`.

- **`FlowField`** (struct) — BFS flow field storing normalised direction vectors and BFS distances toward a goal cell. Supports 8-directional expansion with √2 diagonal cost.

### `pathfinding::astar`

A★ search engine for `NavGrid` with multiple heuristic modes and path post-processing.

- **`astar()`** (fn) — Run A★ from start to goal on a `NavGrid`, returning `(Option<path>, complete)`. Supports `unit_size` footprint and `max_nodes` expansion limit for partial paths.
- **`line_of_sight()`** (fn) — Bresenham line-of-sight check between two cells, respecting `unit_size` footprint.
- **`smooth_path()`** (fn) — Remove unnecessary waypoints via line-of-sight checks (Theta★-style post-processing).

### `pathfinding::async_pool`

Thread pool for off-thread A★ computation against snapshots of `NavGrid`.

- **`PathResult`** (type alias) — `(u64, Option<Vec<(u32, u32)>>)` — completed path result with request ID.
- **`PathThreadPool`** (struct) — Worker thread pool with `submit()`, `poll()`, and `cancel()` methods. Pre/post cancellation checks avoid wasted computation.

### `pathfinding::flow_field`

Dijkstra-based flow field operating on `NavGrid` with cost-weighted expansion.

- **`FlowField`** (struct) — Pre-computed flow field with normalised direction vectors and integrated cost-to-target per cell. Supports single-target `calculate()`, multi-target `calculate_multi()`, direction queries, angle queries, cost-to-target queries, and world-space `steer()` for velocity conversion.

### `pathfinding::graph_path`

Adjacency-graph pathfinding using A★ and Dijkstra over abstract neighbor maps.

- **`ProvincePath`** (struct) — A path result with ordered province IDs and total cost.
- **`ProvinceCostFn`** (struct) — Configurable cost function with `default_cost`, per-province cost overrides, edge tag costs (e.g. `"river"` → 0.5), and blocked province sets.
- **`find_province_path()`** (fn) — A★ search on adjacency graph with centroid distance heuristic.
- **`province_reachable()`** (fn) — Dijkstra reachability within a cost budget, returning a map of reachable node IDs to costs.

### `pathfinding::grid`

Standalone 2D pathfinding grid with per-cell walkability and f32 movement costs.

- **`Grid`** (struct) — Grid supporting A★ (`find_path_astar`), Dijkstra (`find_path_dijkstra`), BFS (`find_path_bfs`), and flow field generation (`build_flow_field`). Coordinates are 0-based with 4-directional or 8-directional neighbour expansion.

### `pathfinding::hpa`

Hierarchical Pathfinding A★ (HPA★) for fast long-range queries on large grids.

- **`AbstractEdge`** (struct) — Edge in the abstract graph connecting two entrance nodes with a cost.
- **`AbstractNode`** (struct) — Entrance point on a chunk boundary with tile coordinates and chunk ID.
- **`Chunk`** (struct) — Region of the grid with top-left position, dimensions, and entrance node indices.
- **`AbstractGraph`** (struct) — Pre-computed abstract graph with nodes, adjacency edges, chunk map, and grid metadata.
- **`build_abstract()`** (fn) — Build the abstract graph from a `NavGrid` by dividing into chunks, finding boundary entrances, and connecting intra-chunk entrances via local A★.
- **`hpa_star()`** (fn) — Run HPA★ from start to goal: insert temporary nodes, search abstract graph, refine to tile-level path.
- **`is_reachable()`** (fn) — Fast chunk-level BFS connectivity check.

### `pathfinding::influence_map`

Multi-layer spatial float grid for strategic area analysis and influence mapping. Moved from `src/ai/influence_map.rs`; re-exported as `crate::ai::InfluenceMap` for backward compatibility.

- **`InfluenceMap`** (struct) — Grid with fixed dimensions (`width × height`), configurable `cell_size`, and named float layers. Operations: `add_layer`, `set_influence`, `get_influence`, `stamp_influence` (circular with falloff), `propagate` (3×3 averaging), `decay`, `clear_layer`, `clear_all`, `max_position`, `min_position`, `query_rect`, `blend`.

### `pathfinding::nav_grid`

Primary navigation grid type used by A★, HPA★, flow fields, and unit pathfinding.

- **`DiagonalMode`** (enum) — `None` (4-dir), `Always` (8-dir), `NoCornerCut` (8-dir but diagonal blocked when adjacent cardinal is impassable). Parses from Lua strings via `from_lua_str`.
- **`NavGrid`** (struct) — 2D u8 cost grid (0=blocked, 1-255=traversal cost). Supports `fill`, `fill_rect`, `load_from_bytes`, `save_to_bytes`, `set_chunk_size`, `set_diagonal_mode`, `neighbors`, `is_walkable` with unit footprint, `set_dirty`/`clear_dirty` for incremental HPA★ updates, and `snapshot()` for thread-safe cloning.

### `pathfinding::pathgrid`

Legacy weighted grid from `ai/pathgrid` with `Cell` type and self-contained A★.

- **`Cell`** (struct) — Grid cell with `walkable: bool` and `cost: f32` fields.
- **`PathGrid`** (struct) — A★ navigation grid with world-space cell size. Methods: `find_path` (A★ with 8-dir corner-cut prevention, returns world-space waypoints), `find_path_smoothed` (greedy string-pulling), `cell_center`, `set_walkable`, `set_cost`, `get_cost`.

### `pathfinding::unit_pathfinder`

High-level pathfinder wrapping `NavGrid` with caching and convenience methods.

- **`Waypoint`** (struct) — Tile-coordinate waypoint with `x: u32`, `y: u32`.
- **`UnitPathfinder`** (struct) — Pathfinder with `find_path`, `find_path_smooth` (Theta★), `find_partial_path` (node limit), `find_nearest_walkable` (BFS), `is_reachable` (flood fill), `heuristic_distance`, `line_of_sight`, `get_path_length`, `get_path_cost`, and LRU cache management (`set_cache_enabled`, `clear_cache`, `get_cache_size`, `set_cache_max_size`).

## Key Types

### Structs

#### `pathfinding::ai_flow_field::FlowField`

BFS flow field that stores normalised direction vectors toward a goal. Each cell holds a direction `(f32, f32)` and a BFS distance `f32`. Operates on a simple `Vec<bool>` walkability array with 8-directional expansion. Construct with `new(width, height, walkable)`, set goal with `set_goal(gx, gy)`, query with `get_direction(x, y)` and `get_distance(x, y)`.

#### `pathfinding::async_pool::PathThreadPool`

A pool of worker threads that process A★ pathfinding requests asynchronously. Each worker pulls requests from a shared MPSC channel, runs `astar::astar` on a `NavGrid` snapshot, and pushes results to a result channel. Supports pre- and post-computation cancellation checks. Construct with `new(thread_count)`, dispatch with `submit()`, collect with `poll()`.

#### `pathfinding::flow_field::FlowField`

Dijkstra-based flow field backed by a shared `Rc<RefCell<NavGrid>>`. Stores normalised direction vectors and integrated cost-to-target for every cell. Supports single-target `calculate()`, multi-target `calculate_multi()`, direction queries, angle queries, cost-to-target queries, and world-space velocity steering via `steer()`.

#### `pathfinding::graph_path::ProvincePath`

A path through an adjacency graph containing an ordered `Vec<u32>` of province IDs from start to goal and the accumulated `total_cost: f64`.

#### `pathfinding::graph_path::ProvinceCostFn`

Configurable cost function for graph pathfinding. Fields: `default_cost: f64`, `province_costs: HashMap<u32, f64>` (per-province overrides), `tag_costs: HashMap<String, f64>` (edge tag costs), `blocked: HashSet<u32>` (impassable provinces). Returns `None` from `cost_for()` for blocked provinces.

#### `pathfinding::grid::Grid`

Standalone 2D pathfinding grid with per-cell `walkable: Vec<bool>` and `costs: Vec<f32>`. Provides `find_path_astar`, `find_path_dijkstra`, `find_path_bfs`, and `build_flow_field`. Includes inline unit tests.

#### `pathfinding::hpa::AbstractEdge`

An edge in the abstract HPA★ graph connecting two entrance nodes with a `cost: f32` representing tile-level distance through the chunk.

#### `pathfinding::hpa::AbstractNode`

An entrance point on a chunk boundary with tile coordinates `(x, y)` and the `chunk: (u32, u32)` it belongs to.

#### `pathfinding::hpa::Chunk`

A chunk region with column/row indices, top-left tile position, dimensions, and a list of entrance node indices into the `AbstractGraph`.

#### `pathfinding::hpa::AbstractGraph`

Pre-computed abstract graph for HPA★. Contains `nodes: Vec<AbstractNode>`, `edges: Vec<Vec<AbstractEdge>>` (adjacency list), `chunks: HashMap<(u32,u32), Chunk>`, and grid metadata (width, height, chunk_size).

#### `pathfinding::influence_map::InfluenceMap`

Multi-layer spatial float grid for influence mapping and strategic AI reasoning. Grid has fixed dimensions with configurable `cell_size` in world units. Named float layers support stamping, propagation, decay, positional queries, rectangular queries, and weighted blending.

#### `pathfinding::nav_grid::NavGrid`

Primary 2D navigation grid with u8 per-cell costs (0=blocked, 1-255). Supports diagonal modes, HPA★ chunk sizing, dirty rect tracking for incremental updates, byte serialization, and thread-safe `snapshot()` cloning.

#### `pathfinding::pathgrid::Cell`

Single cell of the `PathGrid` with `walkable: bool` and `cost: f32` (default: walkable, cost 1.0).

#### `pathfinding::pathgrid::PathGrid`

A★ navigation grid with world-space `cell_size`. Cells stored row-major. Self-contained A★ with 8-directional movement and corner-cut prevention. Returns world-space `(f32, f32)` waypoints.

#### `pathfinding::unit_pathfinder::Waypoint`

A tile-coordinate waypoint with `x: u32` and `y: u32` (0-based). Derives `Copy`, `PartialEq`, `Eq`, `Hash`.

#### `pathfinding::unit_pathfinder::UnitPathfinder`

High-level pathfinder backed by a shared `Rc<RefCell<NavGrid>>`. Provides A★ with caching, Theta★ smoothing, partial path search, nearest-walkable BFS, flood-fill reachability, heuristic distance, and line-of-sight checks. LRU cache evicts oldest entries when exceeding `cache_max_size` (default 1024).

### Enums

#### `pathfinding::nav_grid::DiagonalMode`

Controls how diagonal movement is handled. Variants:
- `None` — 4-directional movement only.
- `Always` — 8-directional; diagonals always allowed at cost √2.
- `NoCornerCut` — 8-directional but diagonals blocked when either adjacent cardinal neighbour is impassable.

### Type Aliases

#### `pathfinding::async_pool::PathResult`

`(u64, Option<Vec<(u32, u32)>>)` — A completed path result with request ID and optional path.

## Lua API

Exposed under `luna.pathfinding.*` by `src/lua_api/pathfinding_api.rs`. All grid coordinates in the Lua API are **1-based**; the binding layer converts to/from 0-based internally.

### Constructor Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `luna.pathfinding.newNavGrid(w, h)` | `NavGrid` | Create a NavGrid with all cells walkable (cost 1) |
| `luna.pathfinding.newPathfinder(grid)` | `UnitPathfinder` | Create a UnitPathfinder backed by a NavGrid |
| `luna.pathfinding.newFlowField(grid)` | `FlowField` | Create a FlowField backed by a NavGrid |
| `luna.pathfinding.newPathGrid(w, h, cellSize)` | `PathGrid` | Create a PathGrid with per-cell cost and walkability |
| `luna.pathfinding.newPathFlowField(grid)` | `AiFlowField` | Create a BFS flow field from a PathGrid |
| `luna.pathfinding.setThreadCount(n)` | `nil` | Set background thread count (currently no-op) |
| `luna.pathfinding.getThreadCount()` | `integer` | Get background thread count (currently always 0) |

### NavGrid Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `grid:getWidth()` | `integer` | Grid width in cells |
| `grid:getHeight()` | `integer` | Grid height in cells |
| `grid:getDimensions()` | `integer, integer` | Width and height |
| `grid:setCost(x, y, cost)` | `nil` | Set cell traversal cost (1-based) |
| `grid:getCost(x, y)` | `integer` | Get cell traversal cost (1-based) |
| `grid:setBlocked(x, y, blocked)` | `nil` | Block or unblock a cell |
| `grid:isBlocked(x, y)` | `boolean` | Check if cell is blocked |
| `grid:isWalkable(x, y, unitSize?)` | `boolean` | Check if unit footprint is walkable |
| `grid:fill(cost)` | `nil` | Set every cell to cost |
| `grid:fillRect(x, y, w, h, cost)` | `nil` | Set rectangular area to cost |
| `grid:loadFromString(data)` | `nil` | Overwrite grid from raw byte string |
| `grid:saveToString()` | `string` | Export grid as byte string |
| `grid:setChunkSize(size)` | `nil` | Set HPA★ chunk size |
| `grid:getChunkSize()` | `integer` | Get HPA★ chunk size |
| `grid:rebuildAbstract()` | `nil` | Rebuild HPA★ abstract graph |
| `grid:setDirty(x, y, w, h)` | `nil` | Record dirty rectangle |
| `grid:clearDirty()` | `nil` | Clear dirty rectangles |
| `grid:setDiagonalMode(mode)` | `nil` | Set diagonal mode ("none"/"always"/"nocornercut") |
| `grid:getDiagonalMode()` | `string` | Get current diagonal mode |

### UnitPathfinder Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `pf:findPath(x1, y1, x2, y2, unitSize?)` | `table?` | A★ path (array of `{x, y}`, 1-based) |
| `pf:findPathSmooth(x1, y1, x2, y2, unitSize?)` | `table?` | Theta★ smoothed path |
| `pf:getPathLength(path)` | `number` | Euclidean length of a path table |
| `pf:getPathCost(path)` | `number` | Sum of grid traversal costs along path |
| `pf:findPartialPath(x1, y1, x2, y2, maxNodes, unitSize?)` | `table, boolean` | Partial path with completion flag |
| `pf:findNearestWalkable(x, y, maxRadius, unitSize?)` | `integer?, integer?` | Nearest walkable cell via BFS |
| `pf:isReachable(x1, y1, x2, y2, unitSize?)` | `boolean` | Flood-fill connectivity check |
| `pf:heuristicDistance(x1, y1, x2, y2)` | `number` | Octile heuristic distance |
| `pf:lineOfSight(x1, y1, x2, y2, unitSize?)` | `boolean` | Bresenham line-of-sight check |
| `pf:setCacheEnabled(enabled)` | `nil` | Enable/disable path caching |
| `pf:isCacheEnabled()` | `boolean` | Check if caching is enabled |
| `pf:clearCache()` | `nil` | Clear all cached paths |
| `pf:getCacheSize()` | `integer` | Number of cached entries |
| `pf:setCacheMaxSize(n)` | `nil` | Set max cache entries |

### FlowField Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `ff:calculate(tx, ty, unitSize?)` | `nil` | Compute flow toward single target |
| `ff:calculateMulti(targets, unitSize?)` | `nil` | Compute flow toward multiple targets |
| `ff:getDirection(x, y)` | `number, number` | Normalised direction at cell |
| `ff:getDirectionAngle(x, y)` | `number` | Direction as angle in radians |
| `ff:getCostToTarget(x, y)` | `number` | Integrated cost to nearest target |
| `ff:isCalculated()` | `boolean` | Whether field has been computed |
| `ff:getTargets()` | `table` | Target cells from last computation |
| `ff:steer(wx, wy, speed, tw, th)` | `number, number` | World-space velocity vector |

### PathGrid Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `pg:getWidth()` | `integer` | Grid width |
| `pg:getHeight()` | `integer` | Grid height |
| `pg:getCellSize()` | `number` | World-space cell size |
| `pg:setWalkable(x, y, walkable)` | `nil` | Set cell walkability |
| `pg:isWalkable(x, y)` | `boolean` | Check cell walkability |
| `pg:setCost(x, y, cost)` | `nil` | Set cell cost multiplier |
| `pg:getCost(x, y)` | `number` | Get cell cost multiplier |
| `pg:findPath(sx, sy, gx, gy)` | `table?` | A★ path (world-space waypoints) |
| `pg:findPathSmoothed(sx, sy, gx, gy)` | `table?` | String-pulled A★ path |

### AiFlowField Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `aff:getWidth()` | `integer` | Grid width |
| `aff:getHeight()` | `integer` | Grid height |
| `aff:hasGoal()` | `boolean` | Whether a goal is set |
| `aff:setGoal(x, y)` | `nil` | Set goal and trigger recomputation |
| `aff:getGoal()` | `integer?, integer?` | Current goal or nil |
| `aff:getDirection(x, y)` | `number, number` | Direction toward goal |
| `aff:getDistance(x, y)` | `number` | BFS distance to goal |

## Lua Examples

```lua
-- Basic A★ pathfinding with NavGrid + UnitPathfinder
function luna.load()
    -- Create a 40x30 navigation grid (1-based in Lua)
    grid = luna.pathfinding.newNavGrid(40, 30)

    -- Block a wall of cells
    for x = 10, 20 do
        grid:setBlocked(x, 15, true)
    end

    -- Set diagonal mode (default is "nocornercut")
    grid:setDiagonalMode("nocornercut")

    -- Create a unit pathfinder backed by the grid
    pathfinder = luna.pathfinding.newPathfinder(grid)

    -- Find a path from (1,1) to (38,28)
    path = pathfinder:findPath(1, 1, 38, 28)
    if path then
        print("Path found with " .. #path .. " waypoints")
        -- Each waypoint is { x = ..., y = ... } (1-based)
        for _, wp in ipairs(path) do
            print("  -> (" .. wp.x .. ", " .. wp.y .. ")")
        end
    end

    -- Smoothed path using Theta★ line-of-sight
    smooth = pathfinder:findPathSmooth(1, 1, 38, 28)
    if smooth then
        print("Smooth path: " .. #smooth .. " waypoints")
    end
end
```

```lua
-- Flow field for crowd steering
function luna.load()
    grid = luna.pathfinding.newNavGrid(50, 50)
    flow = luna.pathfinding.newFlowField(grid)

    -- Compute flow toward cell (25, 25)
    flow:calculate(25, 25)
end

function luna.update(dt)
    if flow:isCalculated() then
        -- Steer a unit at world position toward the target
        local vx, vy = flow:steer(unit_x, unit_y, 100, 32, 32)
        unit_x = unit_x + vx * dt
        unit_y = unit_y + vy * dt
    end
end
```

```lua
-- PathGrid with per-cell costs and path smoothing
function luna.load()
    local pg = luna.pathfinding.newPathGrid(20, 20, 32)

    -- Create a swamp region with higher cost
    for x = 5, 10 do
        for y = 5, 10 do
            pg:setCost(x, y, 3.0)
        end
    end

    -- Block a wall
    for x = 12, 12 do
        for y = 1, 15 do
            pg:setWalkable(x, y, false)
        end
    end

    local path = pg:findPathSmoothed(1, 1, 20, 20)
    if path then
        print("Smoothed path with " .. #path .. " points")
    end
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `struct`   | 16    |
| `enum`     | 1     |
| `type`     | 1     |
| `pub fn`   | 8     |
| **Total**  | **26** |

## References

| Module      | Relationship | Notes                                                          |
|-------------|--------------|----------------------------------------------------------------|
| `engine`    | Imports from | Uses log messages from `log_messages` module                   |
| `math`      | Imports from | `Vec2`, `Rect` for grid coordinates (indirect usage)           |
| `ai`        | Related      | `InfluenceMap` moved from `ai/`; re-exported for backward compatibility. `ai` module uses pathfinding for movement. |
| `tilemap`   | Related      | Tilemaps commonly provide the walkability grid for pathfinding  |
| `lua_api`   | Imported by  | `src/lua_api/pathfinding_api.rs` registers `luna.pathfinding.*` |
| `thread`    | Related      | `PathThreadPool` uses `std::thread` directly (not `thread` module); background pathfinding concept aligns with `luna.thread` |
| `graph`     | Similar      | `graph` module provides generic directed graphs; `graph_path.rs` provides A★/Dijkstra over adjacency maps specifically for navigation |

## Notes

- **1-based Lua coordinates**: All Lua API coordinates are 1-based. The binding layer in `pathfinding_api.rs` subtracts 1 on input and adds 1 on output. Forgetting this conversion causes off-by-one pathfinding failures.
- **NavGrid cost semantics**: Cost `0` means blocked, `1`–`255` are traversal costs. This is a `u8` grid — no floating-point costs. Use `PathGrid` if you need `f32` costs.
- **Three grid types**: `NavGrid` (primary, u8 cost, used by A★/HPA★/FlowField/UnitPathfinder), `PathGrid` (legacy, f32 cost, self-contained A★), `Grid` (standalone, f32 cost, A★/Dijkstra/BFS/flow field). New code should prefer `NavGrid` + `UnitPathfinder`.
- **HPA★ graph must be rebuilt**: After modifying the `NavGrid`, call `grid:rebuildAbstract()` before HPA★ queries. Dirty rects are tracked but incremental updating is not yet implemented.
- **Thread pool uses NavGrid snapshots**: `PathThreadPool.submit()` requires a `NavGrid::snapshot()` clone because workers run on separate threads. The main-thread `NavGrid` can be modified while workers are computing.
- **Cache invalidation**: `UnitPathfinder` caches path results keyed by `(start, goal, unit_size)`. If the grid changes, call `pf:clearCache()` to avoid stale paths.
- **InfluenceMap provenance**: Moved from `src/ai/influence_map.rs` to `src/pathfinding/influence_map.rs`. A re-export `crate::ai::InfluenceMap` exists for backward compatibility.
- **setThreadCount/getThreadCount**: Currently no-ops in the Lua API. The `PathThreadPool` Rust type is functional but not yet exposed to Lua beyond these stubs.
- **Breaking change surface**: Renaming NavGrid methods, changing coordinate conventions (0-based vs 1-based), or altering the `DiagonalMode` enum variants would break existing Lua scripts using `luna.pathfinding.*`.
