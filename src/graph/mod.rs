//! Directed graph with item flow simulation for Lurek2D.
//!
//! Provides nodes, edges, typed items, simulation (decay, transit, push/pull flow,
//! conversions, queues), Dijkstra pathfinding, graph algorithms (components, cycles,
//! topological sort), and supply/demand processing.

/// Graph algorithms: connected components, topological sort, cycle detection.
pub mod algorithms;
/// Core `Graph` struct — nodes, edges, and item storage.
pub mod core;
/// Directed edge with capacity, cooldown, and type-filtering.
pub mod edge;
/// Typed items that flow through the graph.
pub mod item;
/// Graph node with conversion rules, overflow policy, and flow mode.
pub mod node;
/// Dijkstra shortest-path on the graph.
pub mod pathfinding;
/// Tick-based simulation: decay, transit, push/pull flow.
pub mod simulation;
/// Supply and demand processing for resource flow graphs.
pub mod supply_demand;

pub use core::{Graph, GraphStats};
pub use edge::Edge;
pub use item::{GraphItem, ItemPosition};
pub use node::{ConversionRule, Demand, FlowMode, Node, OverflowPolicy, Supply};
pub use simulation::GraphEvent;
