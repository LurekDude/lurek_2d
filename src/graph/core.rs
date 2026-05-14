use super::edge::Edge;
use super::item::{GraphItem, ItemPosition};
use super::node::{Node, OverflowPolicy};
use crate::log_msg;
use crate::runtime::log_messages::{GC01, GC02, GC03, GC04};
use std::collections::{HashMap, HashSet};
/// Aggregate counts derived from the current graph state.
#[derive(Debug, Clone)]
pub struct GraphStats {
    /// Total node count.
    pub nodes: usize,
    /// Total edge count.
    pub edges: usize,
    /// Total item count.
    pub items: usize,
    /// Number of active nodes.
    pub active_nodes: usize,
    /// Number of active edges.
    pub active_edges: usize,
    /// Number of items currently in transit.
    pub items_in_transit: usize,
    /// Number of items currently on nodes.
    pub items_on_nodes: usize,
    /// Sum of node demand quantities.
    pub total_demand: i32,
    /// Sum of node supply quantities.
    pub total_supply: i32,
    /// Number of queued items across all nodes.
    pub queued_items: usize,
}
/// Main graph container with nodes, edges, items, and adjacency indexes.
pub struct Graph {
    /// Stored nodes by id.
    pub nodes: HashMap<u64, Node>,
    /// Stored edges by id.
    pub edges: HashMap<u64, Edge>,
    /// Stored items by id.
    pub items: HashMap<u64, GraphItem>,
    /// Outgoing edge ids keyed by source node id.
    outgoing_index: HashMap<u64, Vec<u64>>,
    /// Incoming edge ids keyed by destination node id.
    incoming_index: HashMap<u64, Vec<u64>>,
    /// Next node id to assign.
    next_node_id: u64,
    /// Next edge id to assign.
    next_edge_id: u64,
    /// Next item id to assign.
    next_item_id: u64,
}
/// Create an empty graph with fresh id counters.
impl Default for Graph {
    fn default() -> Self {
        Self::new()
    }
}
impl Graph {
    /// Create an empty graph with fresh id counters.
    pub fn new() -> Self {
        Self {
            nodes: HashMap::new(),
            edges: HashMap::new(),
            items: HashMap::new(),
            outgoing_index: HashMap::new(),
            incoming_index: HashMap::new(),
            next_node_id: 1,
            next_edge_id: 1,
            next_item_id: 1,
        }
    }
    /// Add an edge id to the outgoing and incoming indexes.
    fn index_edge(&mut self, edge_id: u64, from_node: u64, to_node: u64) {
        self.outgoing_index
            .entry(from_node)
            .or_default()
            .push(edge_id);
        self.incoming_index
            .entry(to_node)
            .or_default()
            .push(edge_id);
    }
    /// Remove an edge id from the outgoing and incoming indexes.
    fn unindex_edge(&mut self, edge_id: u64, from_node: u64, to_node: u64) {
        if let Some(ids) = self.outgoing_index.get_mut(&from_node) {
            ids.retain(|&id| id != edge_id);
        }
        if let Some(ids) = self.incoming_index.get_mut(&to_node) {
            ids.retain(|&id| id != edge_id);
        }
    }
    /// Return the indexed outgoing edge ids for a node.
    pub(crate) fn outgoing_edge_ids_slice(&self, node_id: u64) -> &[u64] {
        self.outgoing_index
            .get(&node_id)
            .map(Vec::as_slice)
            .unwrap_or(&[])
    }
    /// Return the indexed incoming edge ids for a node.
    pub(crate) fn incoming_edge_ids_slice(&self, node_id: u64) -> &[u64] {
        self.incoming_index
            .get(&node_id)
            .map(Vec::as_slice)
            .unwrap_or(&[])
    }
    /// Add a node and return its assigned id.
    pub fn add_node(&mut self, node_type: &str, capacity: i32) -> u64 {
        let id = self.next_node_id;
        self.next_node_id += 1;
        log_msg!(debug, GC01, "id={} type={}", id, node_type);
        self.nodes.insert(id, Node::new(id, node_type, capacity));
        self.outgoing_index.entry(id).or_default();
        self.incoming_index.entry(id).or_default();
        id
    }
    /// Remove a node and all connected edges, returning true when it existed.
    pub fn remove_node(&mut self, node_id: u64) -> bool {
        if self.nodes.remove(&node_id).is_none() {
            return false;
        }
        let edge_ids: Vec<u64> = self
            .edges
            .values()
            .filter(|e| e.from_node == node_id || e.to_node == node_id)
            .map(|e| e.id)
            .collect();
        for eid in edge_ids {
            self.remove_edge(eid);
        }
        for item in self.items.values_mut() {
            if item.position == ItemPosition::AtNode(node_id) {
                item.position = ItemPosition::Unplaced;
            }
        }
        self.outgoing_index.remove(&node_id);
        self.incoming_index.remove(&node_id);
        log_msg!(debug, GC02, "{}", node_id);
        true
    }
    /// Return true when the node id exists.
    pub fn has_node(&self, node_id: u64) -> bool {
        self.nodes.contains_key(&node_id)
    }
    /// Return all node ids in arbitrary order.
    pub fn get_node_ids(&self) -> Vec<u64> {
        self.nodes.keys().copied().collect()
    }
    /// Return the number of nodes.
    pub fn get_node_count(&self) -> usize {
        self.nodes.len()
    }
    /// Add an edge and return its assigned id or an error when either endpoint is missing.
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
        self.index_edge(id, from, to);
        log_msg!(debug, GC03, "{} -> {} (id={})", from, to, id);
        Ok(id)
    }
    /// Remove an edge and detach any items in transit, returning true when it existed.
    pub fn remove_edge(&mut self, edge_id: u64) -> bool {
        if let Some(edge) = self.edges.remove(&edge_id) {
            self.unindex_edge(edge_id, edge.from_node, edge.to_node);
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
    /// Return true when the edge id exists.
    pub fn has_edge(&self, edge_id: u64) -> bool {
        self.edges.contains_key(&edge_id)
    }
    /// Return all edge ids in arbitrary order.
    pub fn get_edge_ids(&self) -> Vec<u64> {
        self.edges.keys().copied().collect()
    }
    /// Return the number of edges.
    pub fn get_edge_count(&self) -> usize {
        self.edges.len()
    }
    /// Return the first outgoing edge id that connects the supplied nodes.
    pub fn get_edge_between(&self, from: u64, to: u64) -> Option<u64> {
        self.outgoing_edge_ids_slice(from)
            .iter()
            .find_map(|edge_id| {
                self.edges.get(edge_id).and_then(|edge| {
                    if edge.to_node == to {
                        Some(edge.id)
                    } else {
                        None
                    }
                })
            })
    }
    /// Build a new graph containing only the selected nodes and connected data.
    pub fn subgraph(&self, node_ids: &[u64]) -> Self {
        let requested: HashSet<u64> = node_ids
            .iter()
            .copied()
            .filter(|id| self.nodes.contains_key(id))
            .collect();
        let mut sorted_nodes: Vec<u64> = requested.iter().copied().collect();
        sorted_nodes.sort_unstable();
        let mut sub = Graph::new();
        let mut node_map: HashMap<u64, u64> = HashMap::new();
        for old_id in sorted_nodes {
            let old = &self.nodes[&old_id];
            let new_id = sub.add_node(&old.node_type, old.capacity);
            let new_node = sub.nodes.get_mut(&new_id).expect("new node must exist");
            new_node.active = old.active;
            new_node.overflow_policy = old.overflow_policy.clone();
            new_node.flow_mode = old.flow_mode.clone();
            new_node.push_rate = old.push_rate;
            new_node.pull_rate = old.pull_rate;
            new_node.push_filter = old.push_filter.clone();
            new_node.pull_filter = old.pull_filter.clone();
            new_node.process_time = old.process_time;
            new_node.queue_enabled = old.queue_enabled;
            new_node.queue_capacity = old.queue_capacity;
            new_node.conversions = old.conversions.clone();
            new_node.demands = old.demands.clone();
            new_node.supplies = old.supplies.clone();
            new_node.tags = old.tags.clone();
            node_map.insert(old_id, new_id);
        }
        let mut edge_map: HashMap<u64, u64> = HashMap::new();
        let mut edge_ids: Vec<u64> = self.edges.keys().copied().collect();
        edge_ids.sort_unstable();
        for old_edge_id in edge_ids {
            let old_edge = &self.edges[&old_edge_id];
            let Some(&new_from) = node_map.get(&old_edge.from_node) else {
                continue;
            };
            let Some(&new_to) = node_map.get(&old_edge.to_node) else {
                continue;
            };
            let new_edge_id = sub
                .add_edge(new_from, new_to, Some(&old_edge.edge_type))
                .expect("subgraph edge endpoints should be valid");
            let new_edge = sub
                .edges
                .get_mut(&new_edge_id)
                .expect("new edge must exist");
            new_edge.capacity = old_edge.capacity;
            new_edge.throughput = old_edge.throughput;
            new_edge.travel_time = old_edge.travel_time;
            new_edge.weight = old_edge.weight;
            new_edge.speed_modifier = old_edge.speed_modifier;
            new_edge.cooldown = old_edge.cooldown;
            new_edge.cooldown_timer = old_edge.cooldown_timer;
            new_edge.bidirectional = old_edge.bidirectional;
            new_edge.active = old_edge.active;
            new_edge.allowed_types = old_edge.allowed_types.clone();
            edge_map.insert(old_edge_id, new_edge_id);
        }
        let mut item_map: HashMap<u64, u64> = HashMap::new();
        let mut item_ids: Vec<u64> = self.items.keys().copied().collect();
        item_ids.sort_unstable();
        for old_item_id in item_ids {
            let old_item = &self.items[&old_item_id];
            let new_position = match old_item.position {
                ItemPosition::AtNode(old_node_id) => {
                    let Some(&new_node_id) = node_map.get(&old_node_id) else {
                        continue;
                    };
                    ItemPosition::AtNode(new_node_id)
                }
                ItemPosition::InTransit {
                    edge_id: old_edge_id,
                    progress,
                } => {
                    let Some(&new_edge_id) = edge_map.get(&old_edge_id) else {
                        continue;
                    };
                    ItemPosition::InTransit {
                        edge_id: new_edge_id,
                        progress,
                    }
                }
                ItemPosition::Unplaced => ItemPosition::Unplaced,
            };
            let new_item_id = sub.create_item(&old_item.item_type, old_item.decay_time);
            let new_item = sub
                .items
                .get_mut(&new_item_id)
                .expect("new item must exist");
            new_item.remaining_life = old_item.remaining_life;
            new_item.alive = old_item.alive;
            new_item.priority = old_item.priority;
            new_item.position = new_position;
            item_map.insert(old_item_id, new_item_id);
        }
        for (&old_node_id, &new_node_id) in &node_map {
            if let Some(old_node) = self.nodes.get(&old_node_id) {
                if let Some(new_node) = sub.nodes.get_mut(&new_node_id) {
                    new_node.items = old_node
                        .items
                        .iter()
                        .filter_map(|old_item_id| item_map.get(old_item_id).copied())
                        .collect();
                    new_node.queue = old_node
                        .queue
                        .iter()
                        .filter_map(|old_item_id| item_map.get(old_item_id).copied())
                        .collect();
                }
            }
        }
        for (&old_edge_id, &new_edge_id) in &edge_map {
            if let Some(old_edge) = self.edges.get(&old_edge_id) {
                if let Some(new_edge) = sub.edges.get_mut(&new_edge_id) {
                    new_edge.items_in_transit = old_edge
                        .items_in_transit
                        .iter()
                        .filter_map(|old_item_id| item_map.get(old_item_id).copied())
                        .collect();
                }
            }
        }
        sub
    }
    /// Create an item and return its assigned id.
    pub fn create_item(&mut self, item_type: &str, decay_time: f64) -> u64 {
        let id = self.next_item_id;
        self.next_item_id += 1;
        self.items
            .insert(id, GraphItem::new(id, item_type, decay_time));
        id
    }
    /// Add an item to a node and return whether the placement succeeded.
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
        let node = self.nodes.get_mut(&node_id).unwrap();
        node.items.push(item_id);
        if let Some(item) = self.items.get_mut(&item_id) {
            item.position = ItemPosition::AtNode(node_id);
        }
        Ok(true)
    }
    /// Remove an item from the graph and all node or edge containers.
    pub fn remove_item(&mut self, item_id: u64) -> bool {
        if self.items.remove(&item_id).is_none() {
            return false;
        }
        for node in self.nodes.values_mut() {
            node.items.retain(|&id| id != item_id);
            node.queue.retain(|&id| id != item_id);
        }
        for edge in self.edges.values_mut() {
            edge.items_in_transit.retain(|&id| id != item_id);
        }
        true
    }
    /// Return true when the item id exists.
    pub fn has_item(&self, item_id: u64) -> bool {
        self.items.contains_key(&item_id)
    }
    /// Return all item ids in arbitrary order.
    pub fn get_item_ids(&self) -> Vec<u64> {
        self.items.keys().copied().collect()
    }
    /// Return the number of items.
    pub fn get_item_count(&self) -> usize {
        self.items.len()
    }
    /// Send an item onto an edge and return whether the transfer succeeded.
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
        if let Some(node) = self.nodes.get_mut(&from_node) {
            node.items.retain(|&id| id != item_id);
        }
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
    /// Return aggregate counts derived from the current graph state.
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
    /// Return outgoing edge ids for a node.
    pub fn get_outgoing_edges(&self, node_id: u64) -> Vec<u64> {
        self.outgoing_edge_ids_slice(node_id).to_vec()
    }
    /// Return incoming edge ids for a node.
    pub fn get_incoming_edges(&self, node_id: u64) -> Vec<u64> {
        self.incoming_edge_ids_slice(node_id).to_vec()
    }
    /// Return edge ids by requested direction or an error when the direction is invalid.
    pub fn get_edges_by_direction(
        &self,
        node_id: u64,
        direction: &str,
    ) -> Result<Vec<u64>, String> {
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
    /// Draw a simple circular graph preview into an image buffer.
    pub fn draw_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(25, 25, 35, 255);
        let cx = width as f32 / 2.0;
        let cy = height as f32 / 2.0;
        let radius = (width.min(height) as f32) * 0.35;
        let mut node_ids: Vec<u64> = self.nodes.keys().copied().collect();
        node_ids.sort();
        let n = node_ids.len();
        if n == 0 {
            return img;
        }
        let positions: Vec<(f32, f32)> = (0..n)
            .map(|i| {
                let angle =
                    i as f32 * std::f32::consts::PI * 2.0 / n as f32 - std::f32::consts::FRAC_PI_2;
                (cx + radius * angle.cos(), cy + radius * angle.sin())
            })
            .collect();
        let id_to_idx: std::collections::HashMap<u64, usize> = node_ids
            .iter()
            .enumerate()
            .map(|(i, &id)| (id, i))
            .collect();
        for edge in self.edges.values() {
            if let (Some(&ai), Some(&bi)) =
                (id_to_idx.get(&edge.from_node), id_to_idx.get(&edge.to_node))
            {
                let (ax, ay) = positions[ai];
                let (bx, by) = positions[bi];
                img.draw_line(
                    ax as i32, ay as i32, bx as i32, by as i32, 80, 120, 160, 200,
                );
            }
        }
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
    /// Serialize nodes and edges into a JSON-like value map.
    pub fn serialize(&self) -> HashMap<String, serde_json::Value> {
        use serde_json::{json, Value};
        let mut nodes_arr: Vec<Value> = self
            .nodes
            .values()
            .map(|n| json!({ "id": n.id, "node_type": n.node_type, "capacity": n.capacity }))
            .collect();
        nodes_arr.sort_by_key(|v| v["id"].as_u64().unwrap_or(0));
        let mut edges_arr: Vec<Value> = self
            .edges
            .values()
            .map(|e| {
                json!({ "id": e.id, "from": e.from_node, "to": e.to_node,
                    "weight": e.weight, "edge_type": e.edge_type,
                    "bidirectional": e.bidirectional })
            })
            .collect();
        edges_arr.sort_by_key(|v| v["id"].as_u64().unwrap_or(0));
        let mut map = HashMap::new();
        map.insert("nodes".to_string(), Value::Array(nodes_arr));
        map.insert("edges".to_string(), Value::Array(edges_arr));
        map
    }
    /// Deserialize a graph from the JSON-like value map or return a shape error.
    pub fn deserialize(data: &HashMap<String, serde_json::Value>) -> Result<Self, String> {
        let mut g = Self::new();
        if let Some(nodes_val) = data.get("nodes") {
            let arr = nodes_val.as_array().ok_or("nodes must be an array")?;
            for n in arr {
                let node_type = n["node_type"].as_str().unwrap_or("default");
                let capacity = n["capacity"].as_i64().unwrap_or(-1) as i32;
                g.add_node(node_type, capacity);
            }
        }
        if let Some(edges_val) = data.get("edges") {
            let arr = edges_val.as_array().ok_or("edges must be an array")?;
            for e in arr {
                let from = e["from"].as_u64().ok_or("edge missing 'from'")?;
                let to = e["to"].as_u64().ok_or("edge missing 'to'")?;
                let edge_type = e["edge_type"].as_str();
                let weight = e["weight"].as_f64().unwrap_or(1.0);
                let bidirectional = e["bidirectional"].as_bool().unwrap_or(false);
                let eid = g
                    .add_edge(from, to, edge_type)
                    .map_err(|e| format!("add_edge error: {e}"))?;
                if let Some(edge) = g.edges.get_mut(&eid) {
                    edge.weight = weight;
                    edge.bidirectional = bidirectional;
                }
            }
        }
        Ok(g)
    }
}
