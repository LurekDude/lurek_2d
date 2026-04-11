# `pathfind` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | `lurek.pathfind` |
| **Source** | `src/pathfind/` |
| **Rust Tests** | `tests/rust/unit/pathfinding_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_pathfinding.lua`, `tests/lua/stress/test_pathfinding_stress.lua`, `tests/lua/golden/test_pathfinding_golden.lua`, `tests/lua/integration/test_tilemap_pathfinding.lua`, `tests/lua/integration/test_pathfinding_entity.lua`, `tests/lua/integration/test_ai_pathfinding.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The `pathfind` module is Lurek2D's navigation algorithm stack. It covers A-star, flow fields, hierarchical pathfinding, influence maps, unit-size-aware path requests, adjacency-graph pathing, and background worker support for expensive searches.

It exists so movement planning and spatial search stay isolated from AI orchestration, physics, and scene code. Other modules can consume paths, flow directions, or influence values without re-implementing grids, heuristics, smoothing, or asynchronous dispatch.

It intentionally does not own agent decision-making, movement execution, collision resolution, or rendering beyond optional debug output. It answers where to go and how to evaluate traversability, not how a game object should behave once a path exists.

**Scope boundary**: This module currently depends on `image`, `render`, `runtime`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.pathfind.* (Lua API — src/lua_api/pathfind_api.rs)
    |
    v
src/pathfind/mod.rs
    |- ai_flow_field.rs - ai_flow_field
    |- astar.rs - astar
    |- async_pool.rs - async_pool
    |- flow_field.rs - flow_field
    |- graph_path.rs - graph_path
    |- grid.rs - grid
    |- hpa.rs - hpa
    |- influence_map.rs - influence_map
    |- ...
```

---

## Source Files

| File | Purpose |
|------|---------|
| `ai_flow_field.rs` | Provides a simpler BFS-style flow-field implementation used for lightweight AI movement support. |
| `astar.rs` | Implements A-star search, line-of-sight checks, and path smoothing helpers over navigation grids. |
| `async_pool.rs` | Dispatches pathfinding work to background threads with request management and cancellation support. |
| `flow_field.rs` | Implements Dijkstra-based flow fields for crowd steering toward one or more targets. |
| `graph_path.rs` | Implements adjacency-graph pathfinding for province-style or node-link worlds instead of regular grids. |
| `grid.rs` | Defines a standalone grid with generic path search, BFS, Dijkstra, and flow-field generation support. |
| `hpa.rs` | Implements hierarchical pathfinding using chunk abstraction and entrance-based higher-level search. |
| `influence_map.rs` | Stores and updates multi-layer spatial influence values for tactical or strategic reasoning. |
| `mod.rs` | Declares the pathfinding submodules and re-exports the main grids, algorithms, and support types. |
| `nav_grid.rs` | Defines the main navigation grid with walkability, costs, diagonal rules, and thread-friendly snapshots. |
| `pathgrid.rs` | Provides an alternate path grid with float costs and built-in path operations. |
| `render.rs` | Generates debug render output for grids, flow fields, and influence maps. |
| `unit_pathfinder.rs` | Wraps pathfinding for unit-sized actors, including caching, partial paths, and nearest-walkable recovery. |

---

## Submodules

### `pathfind::ai_flow_field`

Provides a simpler BFS-style flow-field implementation used for lightweight AI movement support.

- **`FlowField`** (struct): BFS flow field that stores normalized direction vectors toward a goal.

### `pathfind::astar`

Implements A-star search, line-of-sight checks, and path smoothing helpers over navigation grids.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `pathfind::async_pool`

Dispatches pathfinding work to background threads with request management and cancellation support.

- **`PathResult`** (type): A completed path result returned by [`PathThreadPool::poll`].
- **`PathThreadPool`** (struct): A pool of worker threads that process pathfinding requests asynchronously.

### `pathfind::flow_field`

Implements Dijkstra-based flow fields for crowd steering toward one or more targets.

- **`FlowField`** (struct): A pre-computed flow field that stores a direction vector and integrated cost for every cell, guiding any unit toward one or more target cells.

### `pathfind::graph_path`

Implements adjacency-graph pathfinding for province-style or node-link worlds instead of regular grids.

- **`ProvincePath`** (struct): A path through the province adjacency graph.
- **`ProvinceCostFn`** (struct): Configurable cost function for province pathfinding.

### `pathfind::grid`

Defines a standalone grid with generic path search, BFS, Dijkstra, and flow-field generation support.

- **`Grid`** (struct): 2D pathfinding grid with per-cell walkability and movement costs.

### `pathfind::hpa`

Implements hierarchical pathfinding using chunk abstraction and entrance-based higher-level search.

- **`AbstractEdge`** (struct): An edge in the abstract graph connecting two entrance nodes.
- **`AbstractNode`** (struct): A node in the abstract graph, representing an entrance point on a chunk boundary.
- **`Chunk`** (struct): A chunk region of the grid used during abstract graph construction.
- **`AbstractGraph`** (struct): Pre-computed abstract graph for hierarchical A★ queries.

### `pathfind::influence_map`

Stores and updates multi-layer spatial influence values for tactical or strategic reasoning.

- **`InfluenceMap`** (struct): A multi-layer spatial float grid for influence mapping and strategic reasoning.

### `pathfind::nav_grid`

Defines the main navigation grid with walkability, costs, diagonal rules, and thread-friendly snapshots.

- **`DiagonalMode`** (enum): Controls how diagonal movement is handled during pathfinding.
- **`NavGrid`** (struct): A 2D grid of traversal costs used by pathfinding algorithms.

### `pathfind::pathgrid`

Provides an alternate path grid with float costs and built-in path operations.

- **`Cell`** (struct): Single cell of the navigation grid.
- **`PathGrid`** (struct): A★ navigation grid.

### `pathfind::render`

Generates debug render output for grids, flow fields, and influence maps.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `pathfind::unit_pathfinder`

Wraps pathfinding for unit-sized actors, including caching, partial paths, and nearest-walkable recovery.

- **`Waypoint`** (struct): A waypoint along a computed path.
- **`UnitPathfinder`** (struct): A pathfinder that operates on a shared `NavGrid` with optional result caching.

---

## Key Types

### Public Types

#### `NavGrid`

The main navigation grid used by most search helpers, storing blocked cells, movement costs, and diagonal policy.

#### `PathGrid`

Alternate grid representation with float costs and built-in path utilities.

#### `Grid`

Standalone generic grid type for search algorithms and support operations.

#### `FlowField`

Direction-field result that guides many agents toward a destination without separate full path storage per actor.

#### `InfluenceMap`

Multi-layer float grid for tactical influence, pressure, or ownership analysis.

#### `UnitPathfinder`

High-level wrapper that adapts pathfinding to unit radius, caching, partial paths, and recovery logic.

#### `PathThreadPool`

Background worker pool for off-thread path requests.

#### `AbstractGraph`

Higher-level graph abstraction used by hierarchical pathfinding.

#### `Cell`

Core cell representation used by one of the grid variants.

---

## Lua API

Exposed under `lurek.pathfind.*` by `src/lua_api/pathfind_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.pathfind.newNavGrid` | Creates a new NavGrid with all cells walkable. |
| `lurek.pathfind.newPathfinder` | Creates a new UnitPathfinder backed by a NavGrid. |
| `lurek.pathfind.newFlowField` | Creates a new FlowField backed by a NavGrid. |
| `lurek.pathfind.newPathGrid` | Creates a new PathGrid with per-cell cost and walkability. |
| `lurek.pathfind.newPathFlowField` | Creates a new BFS flow field from a PathGrid. |
| `lurek.pathfind.setThreadCount` | Sets the background pathfinding thread count (currently a no-op). |
| `lurek.pathfind.getThreadCount` | Returns the background pathfinding thread count (currently always 0). |
| `lurek.pathfind.newNavGridFromTileMap` | Builds a NavGrid from a TileMap layer, treating specified GIDs as blocked (unwalkable). |

### `AiFlowField` Methods

| Method | Description |
|--------|-------------|
| `aiflowfield:getWidth(...)` | Returns the grid width. |
| `aiflowfield:getHeight(...)` | Returns the grid height. |
| `aiflowfield:hasGoal(...)` | Returns true if a goal has been set. |
| `aiflowfield:setGoal(...)` | Sets the goal cell and triggers BFS recomputation (1-based coordinates). |
| `aiflowfield:getDirection(...)` | Returns the normalised direction toward the goal (1-based coordinates). |
| `aiflowfield:getDistance(...)` | Returns the BFS distance to the goal (1-based coordinates). |
| `aiflowfield:type(...)` | Returns the type name of this object. |
| `aiflowfield:typeOf(...)` | Returns true if this object is of the given type. |

### `FlowField` Methods

| Method | Description |
|--------|-------------|
| `flowfield:getDirection(...)` | Returns the normalised direction vector at a cell (1-based coordinates). |
| `flowfield:getDirectionAngle(...)` | Returns the flow direction as an angle in radians (1-based coordinates). |
| `flowfield:getCostToTarget(...)` | Returns the integrated cost to the nearest target (1-based coordinates). |
| `flowfield:isCalculated(...)` | Returns true if the flow field has been computed at least once. |
| `flowfield:getTargets(...)` | Returns the target cells from the most recent computation (1-based coordinates). |
| `flowfield:type(...)` | Returns the type name of this object. |
| `flowfield:typeOf(...)` | Returns true if this object is of the given type. |

### `NavGrid` Methods

| Method | Description |
|--------|-------------|
| `navgrid:getWidth(...)` | Returns the grid width in cells. |
| `navgrid:getHeight(...)` | Returns the grid height in cells. |
| `navgrid:getDimensions(...)` | Returns the grid dimensions as width, height. |
| `navgrid:setCost(...)` | Sets the traversal cost of a cell (1-based coordinates). |
| `navgrid:getCost(...)` | Returns the traversal cost of a cell (1-based coordinates). |
| `navgrid:isBlocked(...)` | Returns true if the cell is blocked (1-based coordinates). |
| `navgrid:fill(...)` | Sets every cell to the given cost. |
| `navgrid:loadFromString(...)` | Overwrites the grid from a raw byte string (row-major, one byte per cell). |
| `navgrid:saveToString(...)` | Exports the cost grid as a byte string (row-major, one byte per cell). |
| `navgrid:setChunkSize(...)` | Sets the HPA★ chunk size. |
| `navgrid:getChunkSize(...)` | Returns the current HPA★ chunk size. |
| `navgrid:rebuildAbstract(...)` | Rebuilds the HPA★ abstract graph from the current grid state. |
| `navgrid:setDirty(...)` | Records a dirty rectangle for incremental HPA★ updates (1-based coordinates). |
| `navgrid:clearDirty(...)` | Clears all pending dirty rectangles. |
| `navgrid:setDiagonalMode(...)` | Sets the diagonal movement mode. |
| `navgrid:getDiagonalMode(...)` | Returns the current diagonal movement mode as a string. |
| `navgrid:type(...)` | Returns the type name of this object. |
| `navgrid:typeOf(...)` | Returns true if this object is of the given type. |

### `PathGrid` Methods

| Method | Description |
|--------|-------------|
| `pathgrid:getWidth(...)` | Returns the grid width in cells. |
| `pathgrid:getHeight(...)` | Returns the grid height in cells. |
| `pathgrid:getCellSize(...)` | Returns the world-space size of each cell. |
| `pathgrid:setWalkable(...)` | Sets the walkability of a cell (1-based coordinates). |
| `pathgrid:isWalkable(...)` | Returns true if a cell is walkable (1-based coordinates). |
| `pathgrid:setCost(...)` | Sets the cost multiplier for a cell (1-based coordinates). |
| `pathgrid:getCost(...)` | Returns the cost multiplier for a cell (1-based coordinates). |
| `pathgrid:type(...)` | Returns the type name of this object. |
| `pathgrid:typeOf(...)` | Returns true if this object is of the given type. |

### `UnitPathfinder` Methods

| Method | Description |
|--------|-------------|
| `unitpathfinder:getPathLength(...)` | Returns the euclidean length of a path table. |
| `unitpathfinder:getPathCost(...)` | Returns the sum of grid traversal costs along a path. |
| `unitpathfinder:setCacheEnabled(...)` | Enables or disables path result caching. |
| `unitpathfinder:isCacheEnabled(...)` | Returns true if path result caching is enabled. |
| `unitpathfinder:clearCache(...)` | Removes all cached path results. |
| `unitpathfinder:getCacheSize(...)` | Returns the number of entries in the path cache. |
| `unitpathfinder:setCacheMaxSize(...)` | Sets the maximum number of cached path entries. |
| `unitpathfinder:type(...)` | Returns the type name of this object. |
| `unitpathfinder:typeOf(...)` | Returns true if this object is of the given type. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.pathfind.
if lurek.pathfind then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 16 |
| `enum` | 1 |
| `fn` (Lua API) | 59 |
| **Total** | **76** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `image` | Imports or references `image` from `src/image/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `render` | Imports or references `render` from `src/render/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Feature Systems to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/pathfind/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
