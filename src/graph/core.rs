//! Top-level directed graph container with node, edge, and item management.
//!
//! This module is part of Lurek2D's `graph` subsystem and provides the implementation
//! details for core-related operations and data management.
//! Key types exported from this module: `GraphStats`, `Graph`.
//! Primary functions: `new()`, `add_node()`, `remove_node()`, `has_node()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use std::collections::HashMap;

use crate::engine::log_messages::{GC01, GC02, GC03, GC04};
use crate::log_msg;

use super::edge::Edge;
use super::item::{GraphItem, ItemPosition};
use super::node::{Node, OverflowPolicy};

/// A read-only statistics snapshot captured from a [`Graph`] at a point in time.
///
/// # Fields
/// - `nodes` — `usize`.
/// - `edges` — `usize`.
/// - `items` — `usize`.
/// - `active_nodes` — `usize`.
/// - `active_edges` — `usize`.
/// - `items_in_transit` — `usize`.
/// - `items_on_nodes` — `usize`.
/// - `total_demand` — `i32`.
/// - `total_supply` — `i32`.
/// - `queued_items` — `usize`.
#[derive(Debug, Clone)]
pub struct GraphStats {
    /// Total number of nodes.
    pub nodes: usize,
    /// Total number of edges.
    pub edges: usize,
    /// Total number of items.
    pub items: usize,
    /// Number of active nodes.
    pub active_nodes: usize,
    /// Number of active edges.
    pub active_edges: usize,
    /// Items currently in transit on edges.
    pub items_in_transit: usize,
    /// Items currently sitting on nodes.
    pub items_on_nodes: usize,
    /// Sum of all demand quantities.
    pub total_demand: i32,
    /// Sum of all supply quantities.
    pub total_supply: i32,
    /// Total items in all queues.
    pub queued_items: usize,
}

/// A directed graph with typed nodes, edges, and flowing items.
///
/// # Fields
/// - `nodes` — `HashMap<u64, Node>`.
/// - `edges` — `HashMap<u64, Edge>`.
/// - `items` — `HashMap<u64, GraphItem>`.
pub struct Graph {
    /// All nodes keyed by ID.
    pub nodes: HashMap<u64, Node>,
    /// All edges keyed by ID.
    pub edges: HashMap<u64, Edge>,
    /// All items keyed by ID.
    pub items: HashMap<u64, GraphItem>,
    /// Next node ID to assign.
    next_node_id: u64,
    /// Next edge ID to assign.
    next_edge_id: u64,
    /// Next item ID to assign.
    next_item_id: u64,
}

impl Default for Graph {
    fn default() -> Self {
        Self::new()
    }
}

impl Graph {
    /// Create an empty graph. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            nodes: HashMap::new(),
            edges: HashMap::new(),
            items: HashMap::new(),
            next_node_id: 1,
            next_edge_id: 1,
            next_item_id: 1,
        }
    }

    // ---- Node management ----

    /// Add a node with the given type and capacity. Returns the new node ID.
    ///
    /// # Parameters
    /// - `node_type` — `&str`.
    /// - `capacity` — `i32`.
    ///
    /// # Returns
    /// `u64`.
    pub fn add_node(&mut self, node_type: &str, capacity: i32) -> u64 {
        let id = self.next_node_id;
        self.next_node_id += 1;
        log_msg!(debug, GC01, "id={} type={}", id, node_type);
        self.nodes.insert(id, Node::new(id, node_type, capacity));
        id
    }

    /// Remove a node and all connected edges. Items at the node become `Unplaced`.
    ///
    /// # Parameters
    /// - `node_id` — `u64`.
    ///
    /// # Returns
    /// `bool`.
    /// Returns `true` if the node existed.
    pub fn remove_node(&mut self, node_id: u64) -> bool {
        if self.nodes.remove(&node_id).is_none() {
            return false;
        }
        // Remove connected edges
        let edge_ids: Vec<u64> = self
            .edges
            .values()
            .filter(|e| e.from_node == node_id || e.to_node == node_id)
            .map(|e| e.id)
            .collect();
        for eid in edge_ids {
            self.remove_edge(eid);
        }
        // Unplace items that were at this node
        for item in self.items.values_mut() {
            if item.position == ItemPosition::AtNode(node_id) {
                item.position = ItemPosition::Unplaced;
            }
        }
        log_msg!(debug, GC02, "{}", node_id);
        true
    }

    /// Whether a node with the given ID exists.
    ///
    /// # Parameters
    /// - `node_id` — `u64`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_node(&self, node_id: u64) -> bool {
        self.nodes.contains_key(&node_id)
    }

    /// Get all node IDs. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `Vec<u64>`.
    pub fn get_node_ids(&self) -> Vec<u64> {
        self.nodes.keys().copied().collect()
    }

    /// Get the number of nodes. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_node_count(&self) -> usize {
        self.nodes.len()
    }

    // ---- Edge management ----

    /// Add a directed edge between two existing nodes. Returns the edge ID.
    ///
    /// # Parameters
    /// - `from` — `u64`.
    /// - `to` — `u64`.
    /// - `edge_type` — `Option<&str>`.
    ///
    /// # Returns
    /// `Result<u64, String>`.
    pub fn add_edge(&mut self, from: u64, to: u64, edge_type: Option<&str>) -> Result<u64, String> {
        if !self.nodes.contains_key(&from) {
            return Err(format!("source node {from} does not exist"));
        }
        if !self.nodes.contains_key(&to) {
            return Err(format!("destination node {to} does not exist"));
        }
        let id = self.next_edge_id;
        self.next_edge_id += 1;
        let e = Edge::new(id, from, to, edge_type.unwrap_or("default"));
        self.edges.insert(id, e);
        log_msg!(debug, GC03, "{} -> {} (id={})", from, to, id);
        Ok(id)
    }

    /// Remove an edge. Items in transit on it become `Unplaced`. Returns `true` if it existed.
    ///
    /// # Parameters
    /// - `edge_id` — `u64`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_edge(&mut self, edge_id: u64) -> bool {
        if let Some(edge) = self.edges.remove(&edge_id) {
            for &iid in &edge.items_in_transit {
                if let Some(item) = self.items.get_mut(&iid) {
                    item.position = ItemPosition::Unplaced;
                }
            }
            log_msg!(debug, GC04, "{}", edge_id);
            true
        } else {
            false
        }
    }

    /// Whether an edge with the given ID exists.
    ///
    /// # Parameters
    /// - `edge_id` — `u64`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_edge(&self, edge_id: u64) -> bool {
        self.edges.contains_key(&edge_id)
    }

    /// Get all edge IDs. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `Vec<u64>`.
    pub fn get_edge_ids(&self) -> Vec<u64> {
        self.edges.keys().copied().collect()
    }

    /// Get the number of edges. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_edge_count(&self) -> usize {
        self.edges.len()
    }

    /// Find an edge from `from` to `to` (returns the first match).
    ///
    /// # Parameters
    /// - `from` — `u64`.
    /// - `to` — `u64`.
    ///
    /// # Returns
    /// `Option<u64>`.
    pub fn get_edge_between(&self, from: u64, to: u64) -> Option<u64> {
        self.edges
            .values()
            .find(|e| e.from_node == from && e.to_node == to)
            .map(|e| e.id)
    }

    // ---- Item management ----

    /// Create a new item (starts `Unplaced`). Returns the item ID.
    ///
    /// # Parameters
    /// - `item_type` — `&str`.
    /// - `decay_time` — `f64`.
    ///
    /// # Returns
    /// `u64`.
    pub fn create_item(&mut self, item_type: &str, decay_time: f64) -> u64 {
        let id = self.next_item_id;
        self.next_item_id += 1;
        self.items
            .insert(id, GraphItem::new(id, item_type, decay_time));
        id
    }

    /// Try to add an existing item to a node, respecting capacity and overflow policy.
    ///
    /// # Parameters
    /// - `item_id` — `u64`.
    /// - `node_id` — `u64`.
    ///
    /// # Returns
    /// `Result<bool, String>`.
    /// Returns `Ok(true)` if placed, `Ok(false)` if rejected or destroyed, `Err` on invalid IDs.
    pub fn add_item_to_node(&mut self, item_id: u64, node_id: u64) -> Result<bool, String> {
        if !self.items.contains_key(&item_id) {
            return Err(format!("item {item_id} does not exist"));
        }
        let node = self
            .nodes
            .get(&node_id)
            .ok_or_else(|| format!("node {node_id} does not exist"))?;

        if node.is_full() {
            match node.overflow_policy {
                OverflowPolicy::Reject => return Ok(false),
                OverflowPolicy::Destroy => {
                    if let Some(item) = self.items.get_mut(&item_id) {
                        item.kill();
                    }
                    return Ok(false);
                }
                OverflowPolicy::Queue => {
                    let node = self.nodes.get_mut(&node_id).unwrap();
                    let queued = node.enqueue(item_id);
                    if queued {
                        if let Some(item) = self.items.get_mut(&item_id) {
                            item.position = ItemPosition::AtNode(node_id);
                        }
                    }
                    return Ok(queued);
                }
            }
        }

        // Place the item
        let node = self.nodes.get_mut(&node_id).unwrap();
        node.items.push(item_id);
        if let Some(item) = self.items.get_mut(&item_id) {
            item.position = ItemPosition::AtNode(node_id);
        }
        Ok(true)
    }

    /// Remove an item from the graph entirely. Returns the removed value if present, or `None` when the key did not exist.
    ///
    /// # Parameters
    /// - `item_id` — `u64`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_item(&mut self, item_id: u64) -> bool {
        if self.items.remove(&item_id).is_none() {
            return false;
        }
        // Remove from any node
        for node in self.nodes.values_mut() {
            node.items.retain(|&id| id != item_id);
            node.queue.retain(|&id| id != item_id);
        }
        // Remove from any edge transit
        for edge in self.edges.values_mut() {
            edge.items_in_transit.retain(|&id| id != item_id);
        }
        true
    }

    /// Whether an item with the given ID exists.
    ///
    /// # Parameters
    /// - `item_id` — `u64`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_item(&self, item_id: u64) -> bool {
        self.items.contains_key(&item_id)
    }

    /// Get all item IDs. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `Vec<u64>`.
    pub fn get_item_ids(&self) -> Vec<u64> {
        self.items.keys().copied().collect()
    }

    /// Get the number of items. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_item_count(&self) -> usize {
        self.items.len()
    }

    /// Send an item onto an edge (start transit). Returns `Ok(true)` if sent.
    ///
    /// # Parameters
    /// - `item_id` — `u64`.
    /// - `edge_id` — `u64`.
    ///
    /// # Returns
    /// `Result<bool, String>`.
    pub fn send_item(&mut self, item_id: u64, edge_id: u64) -> Result<bool, String> {
        let item = self
            .items
            .get(&item_id)
            .ok_or_else(|| format!("item {item_id} does not exist"))?;
        let item_type = item.item_type.clone();

        let edge = self
            .edges
            .get(&edge_id)
            .ok_or_else(|| format!("edge {edge_id} does not exist"))?;

        if !edge.active {
            return Ok(false);
        }
        if edge.is_on_cooldown() {
            return Ok(false);
        }
        if !edge.is_item_type_allowed(&item_type) {
            return Ok(false);
        }
        if edge.is_transit_full() {
            return Ok(false);
        }

        let from_node = edge.from_node;

        // Remove from source node
        if let Some(node) = self.nodes.get_mut(&from_node) {
            node.items.retain(|&id| id != item_id);
        }

        // Place on edge
        let edge = self.edges.get_mut(&edge_id).unwrap();
        edge.items_in_transit.push(item_id);
        edge.cooldown_timer = edge.cooldown;

        let item = self.items.get_mut(&item_id).unwrap();
        item.position = ItemPosition::InTransit {
            edge_id,
            progress: 0.0,
        };
        Ok(true)
    }

    // ---- Stats ----

    /// Compute a statistics snapshot. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `GraphStats`.
    pub fn get_stats(&self) -> GraphStats {
        let mut stats = GraphStats {
            nodes: self.nodes.len(),
            edges: self.edges.len(),
            items: self.items.len(),
            active_nodes: 0,
            active_edges: 0,
            items_in_transit: 0,
            items_on_nodes: 0,
            total_demand: 0,
            total_supply: 0,
            queued_items: 0,
        };
        for node in self.nodes.values() {
            if node.active {
                stats.active_nodes += 1;
            }
            stats.items_on_nodes += node.items.len();
            stats.queued_items += node.queue.len();
            for d in &node.demands {
                stats.total_demand += d.quantity;
            }
            for s in &node.supplies {
                stats.total_supply += s.quantity;
            }
        }
        for edge in self.edges.values() {
            if edge.active {
                stats.active_edges += 1;
            }
            stats.items_in_transit += edge.items_in_transit.len();
        }
        stats
    }

    // ---- Edge queries ----

    /// Get IDs of edges leaving a node. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `node_id` — `u64`.
    ///
    /// # Returns
    /// `Vec<u64>`.
    pub fn get_outgoing_edges(&self, node_id: u64) -> Vec<u64> {
        self.edges
            .values()
            .filter(|e| e.from_node == node_id)
            .map(|e| e.id)
            .collect()
    }

    /// Get IDs of edges arriving at a node.
    ///
    /// # Parameters
    /// - `node_id` — `u64`.
    ///
    /// # Returns
    /// `Vec<u64>`.
    pub fn get_incoming_edges(&self, node_id: u64) -> Vec<u64> {
        self.edges
            .values()
            .filter(|e| e.to_node == node_id)
            .map(|e| e.id)
            .collect()
    }

    /// Returns edge IDs for a node filtered by direction string.
    ///
    /// # Parameters
    /// - `node_id` — `u64`.
    /// - `direction` — `&str`. One of `"in"`, `"out"`, `"both"`.
    ///
    /// # Returns
    /// `Result<Vec<u64>, String>`.
    pub fn get_edges_by_direction(&self, node_id: u64, direction: &str) -> Result<Vec<u64>, String> {
        if !self.nodes.contains_key(&node_id) {
            return Err("node not found".into());
        }
        match direction {
            "in" => Ok(self.get_incoming_edges(node_id)),
            "out" => Ok(self.get_outgoing_edges(node_id)),
            "both" => {
                let mut combined = self.get_outgoing_edges(node_id);
                combined.extend(self.get_incoming_edges(node_id));
                combined.sort();
                combined.dedup();
                Ok(combined)
            }
            _ => Err(format!(
                "invalid direction: '{}'. Use 'in', 'out', or 'both'",
                direction
            )),
        }
    }

    // ------------------------------------------------------------------
    // Visualization
    // ------------------------------------------------------------------

    /// Render the graph to an image with circular node layout.
    ///
    /// Nodes are laid out in a circle. Edges are drawn as lines. City nodes
    /// appear red; all others green.
    ///
    /// # Parameters
    /// - `width` — `u32`. Output image width.
    /// - `height` — `u32`. Output image height.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(25, 25, 35, 255);
        let cx = width as f32 / 2.0;
        let cy = height as f32 / 2.0;
        let radius = (width.min(height) as f32) * 0.35;

        // Collect nodes in ID order for stable layout
        let mut node_ids: Vec<u64> = self.nodes.keys().copied().collect();
        node_ids.sort();
        let n = node_ids.len();
        if n == 0 {
            return img;
        }

        // Compute circular positions
        let positions: Vec<(f32, f32)> = (0..n)
            .map(|i| {
                let angle = i as f32 * std::f32::consts::PI * 2.0 / n as f32
                    - std::f32::consts::FRAC_PI_2;
                (cx + radius * angle.cos(), cy + radius * angle.sin())
            })
            .collect();

        // Build a map from node ID to index
        let id_to_idx: std::collections::HashMap<u64, usize> =
            node_ids.iter().enumerate().map(|(i, &id)| (id, i)).collect();

        // Draw edges
        for edge in self.edges.values() {
            if let (Some(&ai), Some(&bi)) =
                (id_to_idx.get(&edge.from_node), id_to_idx.get(&edge.to_node))
            {
                let (ax, ay) = positions[ai];
                let (bx, by) = positions[bi];
                img.draw_line(ax as i32, ay as i32, bx as i32, by as i32, 80, 120, 160, 200);
            }
        }

        // Draw nodes
        for (i, &nid) in node_ids.iter().enumerate() {
            let (px, py) = positions[i];
            let (r, g, b) = if self.nodes[&nid].node_type == "city" {
                (200u8, 80, 80)
            } else {
                (80, 200, 80)
            };
            img.draw_circle(px as i32, py as i32, 8, r, g, b, 255);
        }
        img
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn add_and_remove_nodes() {
        let mut g = Graph::new();
        let n1 = g.add_node("a", 5);
        let n2 = g.add_node("b", -1);
        assert!(g.has_node(n1));
        assert!(g.has_node(n2));
        assert_eq!(g.get_node_count(), 2);
        g.remove_node(n1);
        assert!(!g.has_node(n1));
        assert_eq!(g.get_node_count(), 1);
    }

    #[test]
    fn add_and_remove_edges() {
        let mut g = Graph::new();
        let n1 = g.add_node("a", 5);
        let n2 = g.add_node("b", 5);
        let e = g.add_edge(n1, n2, Some("road")).unwrap();
        assert!(g.has_edge(e));
        assert_eq!(g.get_edge_count(), 1);
        assert_eq!(g.get_edge_between(n1, n2), Some(e));
        g.remove_edge(e);
        assert!(!g.has_edge(e));
    }

    #[test]
    fn edge_invalid_nodes() {
        let mut g = Graph::new();
        let n1 = g.add_node("a", 5);
        assert!(g.add_edge(n1, 999, None).is_err());
        assert!(g.add_edge(999, n1, None).is_err());
    }

    #[test]
    fn create_and_place_item() {
        let mut g = Graph::new();
        let n = g.add_node("bin", 2);
        let i1 = g.create_item("wood", -1.0);
        let i2 = g.create_item("stone", -1.0);
        let i3 = g.create_item("gold", -1.0);

        assert!(g.add_item_to_node(i1, n).unwrap());
        assert!(g.add_item_to_node(i2, n).unwrap());
        // full → reject
        assert!(!g.add_item_to_node(i3, n).unwrap());
    }

    #[test]
    fn remove_node_cleans_edges_and_items() {
        let mut g = Graph::new();
        let n1 = g.add_node("a", 5);
        let n2 = g.add_node("b", 5);
        let e = g.add_edge(n1, n2, None).unwrap();
        let i = g.create_item("x", -1.0);
        g.add_item_to_node(i, n1).unwrap();

        g.remove_node(n1);
        assert!(!g.has_edge(e));
        assert_eq!(g.items[&i].position, ItemPosition::Unplaced);
    }

    #[test]
    fn send_item_onto_edge() {
        let mut g = Graph::new();
        let n1 = g.add_node("src", 5);
        let n2 = g.add_node("dst", 5);
        let e = g.add_edge(n1, n2, None).unwrap();
        let i = g.create_item("x", -1.0);
        g.add_item_to_node(i, n1).unwrap();

        assert!(g.send_item(i, e).unwrap());
        assert!(g.nodes[&n1].items.is_empty());
        assert_eq!(g.edges[&e].items_in_transit, vec![i]);
        match g.items[&i].position {
            ItemPosition::InTransit { edge_id, progress } => {
                assert_eq!(edge_id, e);
                assert!((progress).abs() < 1e-9);
            }
            _ => panic!("expected InTransit"),
        }
    }

    #[test]
    fn get_stats() {
        let mut g = Graph::new();
        let n1 = g.add_node("a", 5);
        let n2 = g.add_node("b", 5);
        g.add_edge(n1, n2, None).unwrap();
        let i = g.create_item("x", -1.0);
        g.add_item_to_node(i, n1).unwrap();

        let stats = g.get_stats();
        assert_eq!(stats.nodes, 2);
        assert_eq!(stats.edges, 1);
        assert_eq!(stats.items, 1);
        assert_eq!(stats.items_on_nodes, 1);
    }

    #[test]
    fn outgoing_incoming_edges() {
        let mut g = Graph::new();
        let n1 = g.add_node("a", 5);
        let n2 = g.add_node("b", 5);
        let n3 = g.add_node("c", 5);
        let e1 = g.add_edge(n1, n2, None).unwrap();
        let e2 = g.add_edge(n1, n3, None).unwrap();
        let e3 = g.add_edge(n2, n3, None).unwrap();

        let out = g.get_outgoing_edges(n1);
        assert!(out.contains(&e1));
        assert!(out.contains(&e2));
        assert!(!out.contains(&e3));

        let inc = g.get_incoming_edges(n3);
        assert!(inc.contains(&e2));
        assert!(inc.contains(&e3));
    }
}
