
//! - Adjacency-list graph with directed and undirected mode support.
//! - Node and edge CRUD with stable integer identifiers.
//! - Weighted, labelled edges with automatic reverse-edge insertion for undirected graphs.
//! - BFS and DFS traversals from any start node.
//! - Connectivity queries and neighbour enumeration.

/// A graph node with a debug label.
#[derive(Debug, Clone)]
pub struct GraphNode {
    /// Unique identifier within the owning `Graph`.
    pub id: u32,
    /// Human-readable debug label.
    pub label: String,
}
/// A directed edge connecting two nodes with a weight and label.
#[derive(Debug, Clone)]
pub struct GraphEdge {
    /// Unique edge identifier.
    pub id: u32,
    /// Source node id.
    pub from: u32,
    /// Destination node id.
    pub to: u32,
    /// Traversal cost.
    pub weight: f64,
    /// Human-readable debug label.
    pub label: String,
}
/// Adjacency-list graph supporting directed and undirected modes.
#[derive(Debug, Clone)]
pub struct Graph {
    /// All nodes.
    nodes: Vec<GraphNode>,
    /// All edges; undirected graphs store both directions.
    edges: Vec<GraphEdge>,
    /// Next node id to assign.
    next_node: u32,
    /// Next edge id to assign.
    next_edge: u32,
    /// When true, `add_edge` inserts a reverse edge automatically.
    pub undirected: bool,
}
/// Construction and traversal methods for `Graph`.
impl Graph {
    /// Create an empty directed graph.
    pub fn new() -> Self {
        Self {
            nodes: Vec::new(),
            edges: Vec::new(),
            next_node: 1,
            next_edge: 1,
            undirected: false,
        }
    }
    /// Create an empty undirected graph.
    pub fn new_undirected() -> Self {
        Self {
            undirected: true,
            ..Self::new()
        }
    }
    /// Add a node with `label`; return the new node id.
    pub fn add_node(&mut self, label: &str) -> u32 {
        let id = self.next_node;
        self.next_node += 1;
        self.nodes.push(GraphNode {
            id,
            label: label.to_string(),
        });
        id
    }
    /// Remove node `id` and all edges incident to it; return true when it existed.
    pub fn remove_node(&mut self, id: u32) -> bool {
        if let Some(pos) = self.nodes.iter().position(|n| n.id == id) {
            self.nodes.swap_remove(pos);
            self.edges.retain(|e| e.from != id && e.to != id);
            true
        } else {
            false
        }
    }
    /// Return a reference to the node with `id`, or `None`.
    pub fn get_node(&self, id: u32) -> Option<&GraphNode> {
        self.nodes.iter().find(|n| n.id == id)
    }
    /// Return true when a node with `id` exists.
    pub fn has_node(&self, id: u32) -> bool {
        self.nodes.iter().any(|n| n.id == id)
    }
    /// Return all node ids. This function is part of the public API.
    pub fn node_ids(&self) -> Vec<u32> {
        self.nodes.iter().map(|n| n.id).collect()
    }
    /// Return the total number of nodes.
    pub fn node_count(&self) -> usize {
        self.nodes.len()
    }
    /// Add an edge from `from` to `to` with `weight` and `label`; return edge id, or `0` if either node is missing.
    pub fn add_edge(&mut self, from: u32, to: u32, weight: f64, label: &str) -> u32 {
        if !self.has_node(from) || !self.has_node(to) {
            return 0;
        }
        let id = self.next_edge;
        self.next_edge += 1;
        self.edges.push(GraphEdge {
            id,
            from,
            to,
            weight,
            label: label.to_string(),
        });
        if self.undirected && from != to {
            self.edges.push(GraphEdge {
                id,
                from: to,
                to: from,
                weight,
                label: label.to_string(),
            });
        }
        id
    }
    /// Remove all edges with `id`; return true when at least one was removed.
    pub fn remove_edge(&mut self, id: u32) -> bool {
        let before = self.edges.len();
        self.edges.retain(|e| e.id != id);
        self.edges.len() < before
    }
    /// Return a reference to the first edge with `id`, or `None`.
    pub fn get_edge(&self, id: u32) -> Option<&GraphEdge> {
        self.edges.iter().find(|e| e.id == id)
    }
    /// Return all edges originating from `from`.
    pub fn edges_from(&self, from: u32) -> Vec<&GraphEdge> {
        self.edges.iter().filter(|e| e.from == from).collect()
    }
    /// Return all edges pointing to `to`.
    pub fn edges_to(&self, to: u32) -> Vec<&GraphEdge> {
        self.edges.iter().filter(|e| e.to == to).collect()
    }
    /// Return the total number of stored edge entries.
    pub fn edge_count(&self) -> usize {
        self.edges.len()
    }
    /// Return the ids of all direct outgoing neighbours of `node_id`.
    pub fn neighbors(&self, node_id: u32) -> Vec<u32> {
        self.edges
            .iter()
            .filter(|e| e.from == node_id)
            .map(|e| e.to)
            .collect()
    }
    /// Return node ids reachable from `start` in BFS order.
    pub fn bfs(&self, start: u32) -> Vec<u32> {
        use std::collections::{HashSet, VecDeque};
        let mut visited = HashSet::new();
        let mut queue = VecDeque::new();
        let mut order = Vec::new();
        if !self.has_node(start) {
            return order;
        }
        queue.push_back(start);
        visited.insert(start);
        while let Some(cur) = queue.pop_front() {
            order.push(cur);
            for &nb in &self.neighbors(cur) {
                if visited.insert(nb) {
                    queue.push_back(nb);
                }
            }
        }
        order
    }
    /// Return node ids reachable from `start` in DFS order.
    pub fn dfs(&self, start: u32) -> Vec<u32> {
        let mut visited = std::collections::HashSet::new();
        let mut order = Vec::new();
        self.dfs_inner(start, &mut visited, &mut order);
        order
    }
    /// Recursive DFS helper accumulating visited nodes into `order`.
    fn dfs_inner(
        &self,
        cur: u32,
        visited: &mut std::collections::HashSet<u32>,
        order: &mut Vec<u32>,
    ) {
        if !visited.insert(cur) {
            return;
        }
        order.push(cur);
        for &nb in &self.neighbors(cur) {
            self.dfs_inner(nb, visited, order);
        }
    }
    /// Return true when `to` is reachable from `from`.
    pub fn is_connected(&self, from: u32, to: u32) -> bool {
        self.bfs(from).contains(&to)
    }
    /// Remove all nodes and edges. This function is part of the public API.
    pub fn clear(&mut self) {
        self.nodes.clear();
        self.edges.clear();
    }
}
/// Delegates to `Self::new()`.
impl Default for Graph {
    fn default() -> Self {
        Self::new()
    }
}
