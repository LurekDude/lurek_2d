//! Pathfinding subsystem: grid-based A\*, bidirectional search, JPS, HPA\*, flow fields,
//! navmesh triangulation, influence maps, and async request pooling.
//! Does not own physics collision or Lua API bindings.
//! Consumed by `src/ai/`, `src/physics/`, and `src/lua_api/pathfind_api.rs`.

pub mod ai_flow_field;
pub mod astar;
pub mod async_pool;
pub mod bidir;
pub mod flow_field;
pub mod graph_path;
pub mod grid;
pub mod hpa;
pub mod influence_map;
pub mod nav_grid;
pub mod navmesh;
pub mod pathgrid;
pub mod render;
pub mod unit_pathfinder;
pub use ai_flow_field::FlowField as SimpleFlowField;
pub use astar::{astar, line_of_sight, smooth_path};
pub use async_pool::PathThreadPool;
pub use bidir::bidirectional_astar;
pub use flow_field::FlowField;
pub use graph_path::{find_province_path, province_reachable, ProvinceCostFn, ProvincePath};
pub use grid::Grid;
pub use hpa::{build_abstract, hpa_star, is_reachable as hpa_is_reachable, AbstractGraph};
pub use influence_map::InfluenceMap;
pub use nav_grid::{DiagonalMode, NavGrid};
pub use navmesh::NavMesh;
pub use pathgrid::{Cell, PathGrid};
pub use unit_pathfinder::{UnitPathfinder, Waypoint};
#[cfg(feature = "graph")]
pub mod graph_nav;
pub mod hex_grid;
pub mod iso_grid;
pub mod jps;
pub mod range_map;
#[cfg(feature = "graph")]
pub use graph_nav::{graph_astar, graph_range};
pub use hex_grid::{HexGrid, HexLayout};
pub use iso_grid::IsoGrid;
pub use jps::JpsGrid;
pub use range_map::RangeMap;
