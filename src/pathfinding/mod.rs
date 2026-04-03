//! Grid-based pathfinding: A★, HPA★, flow fields, and unit-size-aware navigation.
//! Also includes province-level A★ on adjacency graphs.
//!
//! This module is part of Luna2D's `pathfinding` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// astar.
pub mod astar;
/// async_pool.
pub mod async_pool;
/// flow_field.
pub mod flow_field;
/// hpa.
pub mod hpa;
/// nav_grid.
pub mod nav_grid;
/// Province-level pathfinding on adjacency graphs.
pub mod province_path;
/// unit_pathfinder.
pub mod unit_pathfinder;
/// PathGrid-based pathfinding, moved from `ai/pathgrid`.
pub mod pathgrid;
/// AI flow field (PathGrid-based), moved from `ai/flowfield`.
pub mod ai_flow_field;

pub use astar::{astar, line_of_sight, smooth_path};
pub use async_pool::PathThreadPool;
pub use flow_field::FlowField;
pub use hpa::{build_abstract, hpa_star, is_reachable as hpa_is_reachable, AbstractGraph};
pub use nav_grid::{DiagonalMode, NavGrid};
pub use province_path::{find_province_path, province_reachable, ProvinceCostFn, ProvincePath};
pub use unit_pathfinder::{UnitPathfinder, Waypoint};
