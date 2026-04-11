# pathfind

## Module Info
- Module name: `pathfind`
- Module group: `Feature Systems`
- Spec path: `docs/specs/pathfind.md`
- Lua API path(s): `src/lua_api/pathfind_api.rs`
- Rust test path(s): `tests/rust/unit/pathfinding_tests.rs`
- Lua test path(s): `tests/lua/unit/test_pathfinding.lua`, `tests/lua/stress/test_pathfinding_stress.lua`, `tests/lua/golden/test_pathfinding_golden.lua`, `tests/lua/integration/test_tilemap_pathfinding.lua`, `tests/lua/integration/test_pathfinding_entity.lua`, `tests/lua/integration/test_ai_pathfinding.lua`

## Module Purpose
The `pathfind` module is Lurek2D's navigation algorithm stack. It covers A-star, flow fields, hierarchical pathfinding, influence maps, unit-size-aware path requests, adjacency-graph pathing, and background worker support for expensive searches.

It exists so movement planning and spatial search stay isolated from AI orchestration, physics, and scene code. Other modules can consume paths, flow directions, or influence values without re-implementing grids, heuristics, smoothing, or asynchronous dispatch.

It intentionally does not own agent decision-making, movement execution, collision resolution, or rendering beyond optional debug output. It answers where to go and how to evaluate traversability, not how a game object should behave once a path exists.

## Files
- `mod.rs` - Declares the pathfinding submodules and re-exports the main grids, algorithms, and support types.
- `ai_flow_field.rs` - Provides a simpler BFS-style flow-field implementation used for lightweight AI movement support.
- `astar.rs` - Implements A-star search, line-of-sight checks, and path smoothing helpers over navigation grids.
- `async_pool.rs` - Dispatches pathfinding work to background threads with request management and cancellation support.
- `flow_field.rs` - Implements Dijkstra-based flow fields for crowd steering toward one or more targets.
- `graph_path.rs` - Implements adjacency-graph pathfinding for province-style or node-link worlds instead of regular grids.
- `grid.rs` - Defines a standalone grid with generic path search, BFS, Dijkstra, and flow-field generation support.
- `hpa.rs` - Implements hierarchical pathfinding using chunk abstraction and entrance-based higher-level search.
- `influence_map.rs` - Stores and updates multi-layer spatial influence values for tactical or strategic reasoning.
- `nav_grid.rs` - Defines the main navigation grid with walkability, costs, diagonal rules, and thread-friendly snapshots.
- `pathgrid.rs` - Provides an alternate path grid with float costs and built-in path operations.
- `render.rs` - Generates debug render output for grids, flow fields, and influence maps.
- `unit_pathfinder.rs` - Wraps pathfinding for unit-sized actors, including caching, partial paths, and nearest-walkable recovery.

## Key Types
- `NavGrid` - The main navigation grid used by most search helpers, storing blocked cells, movement costs, and diagonal policy.
- `PathGrid` - Alternate grid representation with float costs and built-in path utilities.
- `Grid` - Standalone generic grid type for search algorithms and support operations.
- `FlowField` - Direction-field result that guides many agents toward a destination without separate full path storage per actor.
- `InfluenceMap` - Multi-layer float grid for tactical influence, pressure, or ownership analysis.
- `UnitPathfinder` - High-level wrapper that adapts pathfinding to unit radius, caching, partial paths, and recovery logic.
- `PathThreadPool` - Background worker pool for off-thread path requests.
- `AbstractGraph` - Higher-level graph abstraction used by hierarchical pathfinding.
- `Cell` - Core cell representation used by one of the grid variants.
