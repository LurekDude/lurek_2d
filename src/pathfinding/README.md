# `src/pathfinding/` — Grid Pathfinding

## Purpose

Grid-based pathfinding: A*, Hierarchical A* (HPA*), flow fields, and
unit-size-aware navigation. Also includes province-level A* on adjacency graphs.

## Files

| File | Purpose |
|------|---------|
| `astar.rs` | `astar`, `line_of_sight`, `smooth_path` — standard A* |
| `hpa.rs` | `hpa_star`, `build_abstract`, `AbstractGraph` — hierarchical A* |
| `flow_field.rs` | `FlowField` — vector field for crowd movement |
| `nav_grid.rs` | `NavGrid`, `DiagonalMode` — navigation grid setup |
| `unit_pathfinder.rs` | `UnitPathfinder`, `Waypoint` — per-unit path management |
| `async_pool.rs` | `PathThreadPool` — thread-pool for async path queries |
| `province_path.rs` | `find_province_path`, `ProvincePath` — province-level A* |

## Tier

**Tier 2** (generic extension — applicable to many game genres). May import Tier 1 only.
