use super::core::Graph;
use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap, HashSet};
#[derive(Debug, Clone)]
pub struct PathResult {
    pub nodes: Vec<u64>,
    pub edges: Vec<u64>,
    pub cost: f64,
}
#[derive(PartialEq)]
struct DijkstraState {
    cost: f64,
    node_id: u64,
}
impl Eq for DijkstraState {}
impl PartialOrd for DijkstraState {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
impl Ord for DijkstraState {
    fn cmp(&self, other: &Self) -> Ordering {
        other
            .cost
            .partial_cmp(&self.cost)
            .unwrap_or(Ordering::Equal)
            .then_with(|| self.node_id.cmp(&other.node_id))
    }
}
impl Graph {
    pub fn find_path(&self, from: u64, to: u64) -> Option<PathResult> {
        if !self.has_node(from) || !self.has_node(to) {
            return None;
        }
        if from == to {
            return Some(PathResult {
                nodes: vec![from],
                edges: vec![],
                cost: 0.0,
            });
        }
        let mut dist: HashMap<u64, f64> = HashMap::new();
        let mut prev: HashMap<u64, (u64, u64)> = HashMap::new();
        let mut heap = BinaryHeap::new();
        dist.insert(from, 0.0);
        heap.push(DijkstraState {
            cost: 0.0,
            node_id: from,
        });
        while let Some(DijkstraState { cost, node_id }) = heap.pop() {
            if node_id == to {
                return Some(self.reconstruct_path(&prev, from, to, cost));
            }
            if let Some(&d) = dist.get(&node_id) {
                if cost > d {
                    continue;
                }
            }
            for &edge_id in self.outgoing_edge_ids_slice(node_id) {
                let Some(edge) = self.edges.get(&edge_id) else {
                    continue;
                };
                if !edge.active {
                    continue;
                }
                let next = edge.to_node;
                let new_cost = cost + edge.weight;
                let better = dist.get(&next).is_none_or(|&d| new_cost < d);
                if better {
                    dist.insert(next, new_cost);
                    prev.insert(next, (node_id, edge.id));
                    heap.push(DijkstraState {
                        cost: new_cost,
                        node_id: next,
                    });
                }
            }
            for &edge_id in self.incoming_edge_ids_slice(node_id) {
                let Some(edge) = self.edges.get(&edge_id) else {
                    continue;
                };
                if !edge.active || !edge.bidirectional {
                    continue;
                }
                let next = edge.from_node;
                let new_cost = cost + edge.weight;
                let better = dist.get(&next).is_none_or(|&d| new_cost < d);
                if better {
                    dist.insert(next, new_cost);
                    prev.insert(next, (node_id, edge.id));
                    heap.push(DijkstraState {
                        cost: new_cost,
                        node_id: next,
                    });
                }
            }
        }
        None
    }
    pub fn find_path_for_item(&self, item_id: u64, from: u64, to: u64) -> Option<PathResult> {
        let item_type = self.items.get(&item_id)?.item_type.clone();
        if !self.has_node(from) || !self.has_node(to) {
            return None;
        }
        if from == to {
            return Some(PathResult {
                nodes: vec![from],
                edges: vec![],
                cost: 0.0,
            });
        }
        let mut dist: HashMap<u64, f64> = HashMap::new();
        let mut prev: HashMap<u64, (u64, u64)> = HashMap::new();
        let mut heap = BinaryHeap::new();
        dist.insert(from, 0.0);
        heap.push(DijkstraState {
            cost: 0.0,
            node_id: from,
        });
        while let Some(DijkstraState { cost, node_id }) = heap.pop() {
            if node_id == to {
                return Some(self.reconstruct_path(&prev, from, to, cost));
            }
            if let Some(&d) = dist.get(&node_id) {
                if cost > d {
                    continue;
                }
            }
            for &edge_id in self.outgoing_edge_ids_slice(node_id) {
                let Some(edge) = self.edges.get(&edge_id) else {
                    continue;
                };
                if !edge.active || edge.is_on_cooldown() {
                    continue;
                }
                if !edge.is_item_type_allowed(&item_type) {
                    continue;
                }
                let next = edge.to_node;
                let new_cost = cost + edge.weight;
                let better = dist.get(&next).is_none_or(|&d| new_cost < d);
                if better {
                    dist.insert(next, new_cost);
                    prev.insert(next, (node_id, edge.id));
                    heap.push(DijkstraState {
                        cost: new_cost,
                        node_id: next,
                    });
                }
            }
            for &edge_id in self.incoming_edge_ids_slice(node_id) {
                let Some(edge) = self.edges.get(&edge_id) else {
                    continue;
                };
                if !edge.active || !edge.bidirectional || edge.is_on_cooldown() {
                    continue;
                }
                if !edge.is_item_type_allowed(&item_type) {
                    continue;
                }
                let next = edge.from_node;
                let new_cost = cost + edge.weight;
                let better = dist.get(&next).is_none_or(|&d| new_cost < d);
                if better {
                    dist.insert(next, new_cost);
                    prev.insert(next, (node_id, edge.id));
                    heap.push(DijkstraState {
                        cost: new_cost,
                        node_id: next,
                    });
                }
            }
        }
        None
    }
    pub fn get_distance(&self, from: u64, to: u64) -> Option<f64> {
        self.find_path(from, to).map(|p| p.cost)
    }
    pub fn get_reachable(&self, from: u64, max_dist: Option<f64>) -> Vec<u64> {
        if !self.has_node(from) {
            return Vec::new();
        }
        let mut dist: HashMap<u64, f64> = HashMap::new();
        let mut heap = BinaryHeap::new();
        let mut result = Vec::new();
        dist.insert(from, 0.0);
        heap.push(DijkstraState {
            cost: 0.0,
            node_id: from,
        });
        while let Some(DijkstraState { cost, node_id }) = heap.pop() {
            if let Some(&d) = dist.get(&node_id) {
                if cost > d {
                    continue;
                }
            }
            if node_id != from {
                result.push(node_id);
            }
            for &edge_id in self.outgoing_edge_ids_slice(node_id) {
                let Some(edge) = self.edges.get(&edge_id) else {
                    continue;
                };
                if !edge.active {
                    continue;
                }
                let next = edge.to_node;
                let new_cost = cost + edge.weight;
                if let Some(max) = max_dist {
                    if new_cost > max {
                        continue;
                    }
                }
                let better = dist.get(&next).is_none_or(|&d| new_cost < d);
                if better {
                    dist.insert(next, new_cost);
                    heap.push(DijkstraState {
                        cost: new_cost,
                        node_id: next,
                    });
                }
            }
            for &edge_id in self.incoming_edge_ids_slice(node_id) {
                let Some(edge) = self.edges.get(&edge_id) else {
                    continue;
                };
                if !edge.active || !edge.bidirectional {
                    continue;
                }
                let next = edge.from_node;
                let new_cost = cost + edge.weight;
                if let Some(max) = max_dist {
                    if new_cost > max {
                        continue;
                    }
                }
                let better = dist.get(&next).is_none_or(|&d| new_cost < d);
                if better {
                    dist.insert(next, new_cost);
                    heap.push(DijkstraState {
                        cost: new_cost,
                        node_id: next,
                    });
                }
            }
        }
        result
    }
    pub fn get_neighbors(&self, node_id: u64) -> Vec<u64> {
        let mut result = HashSet::new();
        for &edge_id in self.outgoing_edge_ids_slice(node_id) {
            let Some(edge) = self.edges.get(&edge_id) else {
                continue;
            };
            if edge.active {
                result.insert(edge.to_node);
            }
        }
        for &edge_id in self.incoming_edge_ids_slice(node_id) {
            let Some(edge) = self.edges.get(&edge_id) else {
                continue;
            };
            if edge.active && edge.bidirectional {
                result.insert(edge.from_node);
            }
        }
        result.into_iter().collect()
    }
    fn reconstruct_path(
        &self,
        prev: &HashMap<u64, (u64, u64)>,
        from: u64,
        to: u64,
        cost: f64,
    ) -> PathResult {
        let mut nodes = Vec::new();
        let mut edges = Vec::new();
        let mut current = to;
        while current != from {
            nodes.push(current);
            if let Some(&(prev_node, edge_id)) = prev.get(&current) {
                edges.push(edge_id);
                current = prev_node;
            } else {
                break;
            }
        }
        nodes.push(from);
        nodes.reverse();
        edges.reverse();
        PathResult { nodes, edges, cost }
    }
}
