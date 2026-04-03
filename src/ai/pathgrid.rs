//! Weighted grid pathfinding (A★, Dijkstra) with obstacle support.
//!
//! This is a thin re-export of the canonical implementation in
//! [`crate::pathfinding::pathgrid`]. Re-exported here so that the
//! `luna.ai.*` Lua API can access grid pathfinding through a unified
//! AI namespace.
//!
//! See the `pathfinding` module for the full implementation (PathGrid,
//! Cell types, heuristics, and path result structures).
pub use crate::pathfinding::pathgrid::*;
