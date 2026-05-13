#[derive(Debug, Clone)]
pub struct GraphNode {
    pub id: u32,
    pub label: String,
}
#[derive(Debug, Clone)]
pub struct GraphEdge {
    pub id: u32,
    pub from: u32,
    pub to: u32,
    pub weight: f64,
    pub label: String,
}
#[derive(Debug, Clone)]
pub struct Graph {
    nodes: Vec<GraphNode>,
    edges: Vec<GraphEdge>,
    next_node: u32,
    next_edge: u32,
    pub undirected: bool,
}
impl Graph {
    pub fn new() -> Self {
        Self {
            nodes: Vec::new(),
            edges: Vec::new(),
            next_node: 1,
            next_edge: 1,
            undirected: false,
        }
    }
    pub fn new_undirected() -> Self {
        Self {
            undirected: true,
            ..Self::new()
        }
    }
    pub fn add_node(&mut self, label: &str) -> u32 {
        let id = self.next_node;
        self.next_node += 1;
        self.nodes.push(GraphNode {
            id,
            label: label.to_string(),
        });
        id
    }
    pub fn remove_node(&mut self, id: u32) -> bool {
        if let Some(pos) = self.nodes.iter().position(|n| n.id == id) {
            self.nodes.swap_remove(pos);
            self.edges.retain(|e| e.from != id && e.to != id);
            true
        } else {
            false
        }
    }
    pub fn get_node(&self, id: u32) -> Option<&GraphNode> {
        self.nodes.iter().find(|n| n.id == id)
    }
    pub fn has_node(&self, id: u32) -> bool {
        self.nodes.iter().any(|n| n.id == id)
    }
    pub fn node_ids(&self) -> Vec<u32> {
        self.nodes.iter().map(|n| n.id).collect()
    }
    pub fn node_count(&self) -> usize {
        self.nodes.len()
    }
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
    pub fn remove_edge(&mut self, id: u32) -> bool {
        let before = self.edges.len();
        self.edges.retain(|e| e.id != id);
        self.edges.len() < before
    }
    pub fn get_edge(&self, id: u32) -> Option<&GraphEdge> {
        self.edges.iter().find(|e| e.id == id)
    }
    pub fn edges_from(&self, from: u32) -> Vec<&GraphEdge> {
        self.edges.iter().filter(|e| e.from == from).collect()
    }
    pub fn edges_to(&self, to: u32) -> Vec<&GraphEdge> {
        self.edges.iter().filter(|e| e.to == to).collect()
    }
    pub fn edge_count(&self) -> usize {
        self.edges.len()
    }
    pub fn neighbors(&self, node_id: u32) -> Vec<u32> {
        self.edges
            .iter()
            .filter(|e| e.from == node_id)
            .map(|e| e.to)
            .collect()
    }
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
    pub fn is_connected(&self, from: u32, to: u32) -> bool {
        self.bfs(from).contains(&to)
    }
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
