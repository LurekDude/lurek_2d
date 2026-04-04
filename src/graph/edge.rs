//! Graph edge — a directed connection between nodes.
//!
//! This module is part of Luna2D's `graph` subsystem and provides the implementation
//! details for edge-related operations and data management.
//! Key types exported from this module: `Edge`.
//! Primary functions: `new()`, `get_type()`, `set_type()`, `is_on_cooldown()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::HashSet;

/// A directed connection between two nodes in the graph.
///
/// # Fields
/// - `id` — `u64`.
/// - `edge_type` — `String`.
/// - `from_node` — `u64`.
/// - `to_node` — `u64`.
/// - `capacity` — `i32`.
/// - `throughput` — `f64`.
/// - `travel_time` — `f64`.
/// - `weight` — `f64`.
/// - `speed_modifier` — `f64`.
/// - `cooldown` — `f64`.
/// - `cooldown_timer` — `f64`.
/// - `bidirectional` — `bool`.
/// - `active` — `bool`.
/// - `allowed_types` — `HashSet<String>`.
/// - `items_in_transit` — `Vec<u64>`.
pub struct Edge {
    /// Unique identifier.
    pub id: u64,
    /// Application-defined type tag.
    pub edge_type: String,
    /// Source node ID.
    pub from_node: u64,
    /// Destination node ID.
    pub to_node: u64,
    /// Max items in transit simultaneously. `-1` = unlimited.
    pub capacity: i32,
    /// Items per second this edge can move. Default `1.0`.
    pub throughput: f64,
    /// Seconds for an item to travel the edge. Default `1.0`.
    pub travel_time: f64,
    /// Cost for pathfinding. Default `1.0`.
    pub weight: f64,
    /// Multiplier on travel speed. Default `1.0`.
    pub speed_modifier: f64,
    /// Cooldown period in seconds after an item enters. Default `0.0`.
    pub cooldown: f64,
    /// Remaining cooldown time.
    pub cooldown_timer: f64,
    /// Whether the edge can be traversed in both directions.
    pub bidirectional: bool,
    /// Whether this edge participates in simulation.
    pub active: bool,
    /// Item types allowed on this edge. Empty = allow all.
    pub allowed_types: HashSet<String>,
    /// Item IDs currently in transit on this edge.
    pub items_in_transit: Vec<u64>,
}

impl Edge {
    /// Create a new edge with defaults. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `id` — `u64`.
    /// - `from` — `u64`.
    /// - `to` — `u64`.
    /// - `edge_type` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(id: u64, from: u64, to: u64, edge_type: &str) -> Self {
        Self {
            id,
            edge_type: edge_type.to_string(),
            from_node: from,
            to_node: to,
            capacity: -1,
            throughput: 1.0,
            travel_time: 1.0,
            weight: 1.0,
            speed_modifier: 1.0,
            cooldown: 0.0,
            cooldown_timer: 0.0,
            bidirectional: false,
            active: true,
            allowed_types: HashSet::new(),
            items_in_transit: Vec::new(),
        }
    }

    /// Get the edge type. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `&str`.
    pub fn get_type(&self) -> &str {
        &self.edge_type
    }

    /// Set the edge type. Replaces the current type value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `t` — `&str`.
    pub fn set_type(&mut self, t: &str) {
        self.edge_type = t.to_string();
    }

    /// Whether the edge is in cooldown. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_on_cooldown(&self) -> bool {
        self.cooldown_timer > 0.0
    }

    /// Whether the given item type is allowed on this edge.
    ///
    /// # Parameters
    /// - `t` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_item_type_allowed(&self, t: &str) -> bool {
        self.allowed_types.is_empty() || self.allowed_types.contains(t)
    }

    /// Add an allowed item type. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `t` — `&str`.
    pub fn add_allowed_type(&mut self, t: &str) {
        self.allowed_types.insert(t.to_string());
    }

    /// Remove an allowed item type. Returns the removed value if present, or `None` when the key did not exist.
    ///
    /// # Parameters
    /// - `t` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_allowed_type(&mut self, t: &str) -> bool {
        self.allowed_types.remove(t)
    }

    /// Clear all allowed type restrictions (all types become allowed).
    pub fn clear_allowed_types(&mut self) {
        self.allowed_types.clear();
    }

    /// Whether transit capacity is full. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_transit_full(&self) -> bool {
        if self.capacity < 0 {
            false
        } else {
            self.items_in_transit.len() >= self.capacity as usize
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_edge_defaults() {
        let e = Edge::new(1, 10, 20, "road");
        assert_eq!(e.id, 1);
        assert_eq!(e.from_node, 10);
        assert_eq!(e.to_node, 20);
        assert_eq!(e.get_type(), "road");
        assert!((e.throughput - 1.0).abs() < 1e-9);
        assert!((e.travel_time - 1.0).abs() < 1e-9);
        assert!((e.weight - 1.0).abs() < 1e-9);
        assert!(e.active);
        assert!(!e.bidirectional);
        assert!(!e.is_on_cooldown());
    }

    #[test]
    fn allowed_types() {
        let mut e = Edge::new(1, 0, 1, "pipe");
        // empty = allow all
        assert!(e.is_item_type_allowed("anything"));
        e.add_allowed_type("water");
        assert!(e.is_item_type_allowed("water"));
        assert!(!e.is_item_type_allowed("oil"));
        e.add_allowed_type("oil");
        assert!(e.is_item_type_allowed("oil"));
        e.remove_allowed_type("oil");
        assert!(!e.is_item_type_allowed("oil"));
        e.clear_allowed_types();
        assert!(e.is_item_type_allowed("anything"));
    }

    #[test]
    fn cooldown() {
        let mut e = Edge::new(1, 0, 1, "x");
        assert!(!e.is_on_cooldown());
        e.cooldown_timer = 0.5;
        assert!(e.is_on_cooldown());
    }

    #[test]
    fn transit_capacity() {
        let mut e = Edge::new(1, 0, 1, "x");
        assert!(!e.is_transit_full()); // unlimited
        e.capacity = 1;
        assert!(!e.is_transit_full());
        e.items_in_transit.push(100);
        assert!(e.is_transit_full());
    }
}
