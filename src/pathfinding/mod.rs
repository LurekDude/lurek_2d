//! Grid-based pathfinding: A★, HPA★, flow fields, and unit-size-aware navigation.
//! Also includes adjacency-graph A★ for province and world-graph navigation.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// AStar, Dijkstra, and line-of-sight on NavGrid.
pub mod astar;
/// Async pathfinding thread pool for off-thread NavGrid queries.
pub mod async_pool;
/// Flow field pathfinding for crowd steering (NavGrid-based).
pub mod flow_field;
/// 2D walkable grid with A*, Dijkstra, BFS, and flow field generation.
pub mod grid;
/// Hierarchical pathfinding A* (HPA*) with abstract graph and level-of-detail.
pub mod hpa;
/// AI flow field (simple walkability grid, moved from ai/flowfield).
pub mod ai_flow_field;
/// Navigation grid with per-cell costs, diagonal modes, and HPA* support.
pub mod nav_grid;
/// Adjacency-graph pathfinding (A* and Dijkstra) over abstract neighbor maps.
/// Suitable for province-level and world-graph navigation.
pub mod graph_path;
/// Multi-layer spatial float grid for strategic area analysis and influence mapping.
pub mod influence_map;
/// Weighted walkability grid with `Cell` type (moved from ai/pathgrid).
pub mod pathgrid;
/// Unit-radius-aware pathfinding wrapper over NavGrid.
pub mod unit_pathfinder;

pub use ai_flow_field::FlowField as SimpleFlowField;
pub use astar::{astar, line_of_sight, smooth_path};
pub use async_pool::PathThreadPool;
pub use flow_field::FlowField;
pub use graph_path::{find_province_path, province_reachable, ProvinceCostFn, ProvincePath};
pub use grid::Grid;
pub use hpa::{build_abstract, hpa_star, is_reachable as hpa_is_reachable, AbstractGraph};
pub use influence_map::InfluenceMap;
pub use nav_grid::{DiagonalMode, NavGrid};
pub use pathgrid::{Cell, PathGrid};
pub use unit_pathfinder::{UnitPathfinder, Waypoint};

