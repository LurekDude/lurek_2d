//! Generic directed/undirected weighted graph for pathfinding, dialogue trees,
//! skill dependencies, and other relationship graphs exposed to Lua.

/// A node in the graph.
#[derive(Debug, Clone)]
pub struct GraphNode {
    /// Stable node ID assigned at insertion.
    pub id: u32,
    /// Human-readable label (optional).
    pub label: String,
}

/// A directed edge between two nodes.
#[derive(Debug, Clone)]
pub struct GraphEdge {
    /// Stable edge ID assigned at insertion.
    pub id: u32,
    /// Source node ID.
    pub from: u32,
    /// Target node ID.
    pub to: u32,
    /// Edge weight (default `1.0`).
    pub weight: f64,
    /// Optional edge label.
    pub label: String,
}

/// A simple adjacency-list graph.
///
/// Supports directed and undirected operation — undirected graphs store
/// both `(from → to)` and `(to → from)` edges automatically.
#[derive(Debug, Clone)]
pub struct Graph {
    nodes: Vec<GraphNode>,
    edges: Vec<GraphEdge>,
    next_node: u32,
    next_edge: u32,
    /// When `true`, [`add_edge`] also inserts the reverse edge.
    pub undirected: bool,
}

impl Graph {
    /// Creates an empty directed graph.
    pub fn new() -> Self {
        Self {
            nodes: Vec::new(),
            edges: Vec::new(),
            next_node: 1,
            next_edge: 1,
            undirected: false,
        }
    }

    /// Creates an empty undirected graph.
    pub fn new_undirected() -> Self {
        Self {
            undirected: true,
            ..Self::new()
        }
    }

    // ── Nodes ──────────────────────────────────────────────────────────────

    /// Adds a node with the given label and returns its ID.
    pub fn add_node(&mut self, label: &str) -> u32 {
        let id = self.next_node;
        self.next_node += 1;
        self.nodes.push(GraphNode {
            id,
            label: label.to_string(),
        });
        id
    }

    /// Removes the node with the given ID and all edges incident to it.
    /// Returns `true` when the node was found.
    pub fn remove_node(&mut self, id: u32) -> bool {
        if let Some(pos) = self.nodes.iter().position(|n| n.id == id) {
            self.nodes.swap_remove(pos);
            self.edges.retain(|e| e.from != id && e.to != id);
            true
        } else {
            false
        }
    }

    /// Returns the node with the given ID, if it exists.
    pub fn get_node(&self, id: u32) -> Option<&GraphNode> {
        self.nodes.iter().find(|n| n.id == id)
    }

    /// Returns `true` when a node with the given ID exists.
    pub fn has_node(&self, id: u32) -> bool {
        self.nodes.iter().any(|n| n.id == id)
    }

    /// Returns all node IDs.
    pub fn node_ids(&self) -> Vec<u32> {
        self.nodes.iter().map(|n| n.id).collect()
    }

    /// Returns the number of nodes.
    pub fn node_count(&self) -> usize {
        self.nodes.len()
    }

    // ── Edges ──────────────────────────────────────────────────────────────

    /// Adds an edge from `from` to `to` with the given weight and label.
    ///
    /// For undirected graphs the reverse edge is also inserted automatically,
    /// sharing the same ID but stored as a second `GraphEdge` entry.
    ///
    /// Returns the edge ID, or `0` when either node is unknown.
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

    /// Removes all edges with the given ID.
    /// Returns `true` when at least one was removed.
    pub fn remove_edge(&mut self, id: u32) -> bool {
        let before = self.edges.len();
        self.edges.retain(|e| e.id != id);
        self.edges.len() < before
    }

    /// Returns the edge with the given ID (first occurrence for undirected).
    pub fn get_edge(&self, id: u32) -> Option<&GraphEdge> {
        self.edges.iter().find(|e| e.id == id)
    }

    /// Returns all edges whose source is `from`.
    pub fn edges_from(&self, from: u32) -> Vec<&GraphEdge> {
        self.edges.iter().filter(|e| e.from == from).collect()
    }

    /// Returns all edges whose target is `to`.
    pub fn edges_to(&self, to: u32) -> Vec<&GraphEdge> {
        self.edges.iter().filter(|e| e.to == to).collect()
    }

    /// Returns the number of stored edge records.
    pub fn edge_count(&self) -> usize {
        self.edges.len()
    }

    // ── Algorithms ─────────────────────────────────────────────────────────

    /// Returns the direct neighbours of `node_id` (targets of outgoing edges).
    pub fn neighbors(&self, node_id: u32) -> Vec<u32> {
        self.edges
            .iter()
            .filter(|e| e.from == node_id)
            .map(|e| e.to)
            .collect()
    }

    /// Breadth-first search from `start`. Returns visited node IDs in BFS order.
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

    /// Depth-first search from `start`. Returns visited node IDs in DFS order.
    pub fn dfs(&self, start: u32) -> Vec<u32> {
        let mut visited = std::collections::HashSet::new();
        let mut order = Vec::new();
        self.dfs_inner(start, &mut visited, &mut order);
        order
    }

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

    /// Checks whether a path exists between `from` and `to`.
    pub fn is_connected(&self, from: u32, to: u32) -> bool {
        self.bfs(from).contains(&to)
    }

    /// Resets the graph to an empty state.
    pub fn clear(&mut self) {
        self.nodes.clear();
        self.edges.clear();
    }
}

impl Default for Graph {
    fn default() -> Self {
        Self::new()
    }
}
