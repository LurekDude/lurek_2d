//! Dijkstra-based flow field for efficient crowd pathfinding.
//!
//! This is a thin re-export of the canonical implementation in
//! [`crate::pathfinding::ai_flow_field`]. Re-exported here so that
//! the `luna.ai.*` Lua API can access flow fields through a unified
//! AI namespace without requiring users to know the underlying module layout.
//!
//! See the `pathfinding` module for the full implementation details.
pub use crate::pathfinding::ai_flow_field::*;
