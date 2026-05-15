//! - Directed graph container with typed nodes, edges, and item flow.
//! - Supply/demand modeling, conversion rules, and overflow policies.
//! - Pathfinding, simulation stepping, and event emission.
//! - Render helpers for visual graph output.

/// Graph algorithm helpers. This module is publicly re-exported.
pub mod algorithms;
/// Core graph container and stats.
pub mod core;
/// Edge data and transit helpers.
pub mod edge;
/// Graph item data. This module is publicly re-exported.
pub mod item;
/// Node data and flow configuration.
pub mod node;
/// Graph pathfinding helpers. This module is publicly re-exported.
pub mod pathfinding;
/// Graph render helpers. This module is publicly re-exported.
pub mod render;
/// Graph simulation update logic.
pub mod simulation;
/// Supply and demand helpers. This module is publicly re-exported.
pub mod supply_demand;
/// Core graph container and stats.
pub use core::{Graph, GraphStats};
/// Edge data type.
pub use edge::Edge;
/// Item data types.
pub use item::{GraphItem, ItemPosition};
/// Node data and flow configuration types.
pub use node::{ConversionRule, Demand, FlowMode, Node, OverflowPolicy, Supply};
/// Graph simulation event type.
pub use simulation::GraphEvent;
