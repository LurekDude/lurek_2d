//! - Directed edge connecting two graph nodes with capacity, throughput, and cooldown constraints.
//! - Type-based filtering restricts which items may transit an edge.
//! - Supports bidirectional flag and per-edge speed/weight modifiers for pathfinding.

use std::collections::HashSet;
/// Directed connection between two graph nodes.
pub struct Edge {
    /// Stable edge identifier.
    pub id: u64,
    /// Edge type name.
    pub edge_type: String,
    /// Source node id.
    pub from_node: u64,
    /// Destination node id.
    pub to_node: u64,
    /// Maximum items in transit, or negative for unlimited.
    pub capacity: i32,
    /// Maximum items that can move per update window.
    pub throughput: f64,
    /// Travel time in seconds.
    pub travel_time: f64,
    /// Pathfinding weight.
    pub weight: f64,
    /// Speed multiplier applied during transit.
    pub speed_modifier: f64,
    /// Cooldown duration between sends.
    pub cooldown: f64,
    /// Remaining cooldown time.
    pub cooldown_timer: f64,
    /// Flag that marks the edge as bidirectional.
    pub bidirectional: bool,
    /// Flag that enables the edge in simulation.
    pub active: bool,
    /// Allowed item types, or empty for no restriction.
    pub allowed_types: HashSet<String>,
    /// Item ids currently moving along the edge.
    pub items_in_transit: Vec<u64>,
}
impl Edge {
    /// Create an edge with default transit settings.
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
    /// Return the edge type string.
    pub fn get_type(&self) -> &str {
        &self.edge_type
    }
    /// Set the edge type string.
    pub fn set_type(&mut self, t: &str) {
        self.edge_type = t.to_string();
    }
    /// Return true when the edge is still on cooldown.
    pub fn is_on_cooldown(&self) -> bool {
        self.cooldown_timer > 0.0
    }
    /// Return true when the item type is allowed by the edge filter.
    pub fn is_item_type_allowed(&self, t: &str) -> bool {
        self.allowed_types.is_empty() || self.allowed_types.contains(t)
    }
    /// Allow an item type on the edge.
    pub fn add_allowed_type(&mut self, t: &str) {
        self.allowed_types.insert(t.to_string());
    }
    /// Remove an allowed item type and return true when it existed.
    pub fn remove_allowed_type(&mut self, t: &str) -> bool {
        self.allowed_types.remove(t)
    }
    /// Remove all allowed item type filters.
    pub fn clear_allowed_types(&mut self) {
        self.allowed_types.clear();
    }
    /// Return true when the transit buffer is at or above capacity.
    pub fn is_transit_full(&self) -> bool {
        if self.capacity < 0 {
            false
        } else {
            self.items_in_transit.len() >= self.capacity as usize
        }
    }
}
