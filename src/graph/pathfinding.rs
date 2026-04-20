//! Dijkstra pathfinding and reachability queries on the graph.

use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap, HashSet};

use super::core::Graph;

/// Result of a successful pathfinding query.
///
/// # Fields
/// - `nodes` — `Vec<u64>`. Ordered sequence of node IDs from source to destination.
/// - `edges` — `Vec<u64>`. Ordered sequence of edge IDs traversed.
/// - `cost` — `f64`. Total path cost (sum of edge weights).
#[derive(Debug, Clone)]
pub struct PathResult {
    /// Ordered sequence of node IDs from source to destination.
    pub nodes: Vec<u64>,
    /// Ordered sequence of edge IDs traversed.
    pub edges: Vec<u64>,
    /// Total path cost (sum of edge weights).
    pub cost: f64,
}

/// Internal state for Dijkstra's algorithm.
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
        // Reverse ordering for min-heap
        other
            .cost
            .partial_cmp(&self.cost)
            .unwrap_or(Ordering::Equal)
            .then_with(|| self.node_id.cmp(&other.node_id))
    }
}

impl Graph {
    /// Find the shortest path from `from` to `to` using Dijkstra's algorithm.
    /// Uses edge `weight` as cost. Returns `None` if no path exists.
    ///
    /// # Parameters
    /// - `from` — `u64`. Source node ID.
    /// - `to` — `u64`. Destination node ID.
    ///
    /// # Returns
    /// `Option<PathResult>`.
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
        let mut prev: HashMap<u64, (u64, u64)> = HashMap::new(); // node -> (prev_node, edge_id)
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

            for edge in self.edges.values() {
                let neighbor = if edge.from_node == node_id {
                    Some(edge.to_node)
                } else if edge.bidirectional && edge.to_node == node_id {
                    Some(edge.from_node)
                } else {
                    None
                };

                if let Some(next) = neighbor {
                    if !edge.active {
                        continue;
                    }
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
        }

        None
    }

    /// Find a path that only uses edges the given item can traverse.
    /// Filters by: edge active, item type allowed, not on cooldown.
    ///
    /// # Parameters
    /// - `item_id` — `u64`. ID of the item to route.
    /// - `from` — `u64`. Source node ID.
    /// - `to` — `u64`. Destination node ID.
    ///
    /// # Returns
    /// `Option<PathResult>`.
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

            for edge in self.edges.values() {
                let neighbor = if edge.from_node == node_id {
                    Some(edge.to_node)
                } else if edge.bidirectional && edge.to_node == node_id {
                    Some(edge.from_node)
                } else {
                    None
                };

                if let Some(next) = neighbor {
                    if !edge.active || edge.is_on_cooldown() {
                        continue;
                    }
                    if !edge.is_item_type_allowed(&item_type) {
                        continue;
                    }
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
        }

        None
    }

    /// Get the shortest-path distance between two nodes, or `None` if unreachable.
    ///
    /// # Parameters
    /// - `from` — `u64`. Source node ID.
    /// - `to` — `u64`. Destination node ID.
    ///
    /// # Returns
    /// `Option<f64>`.
    pub fn get_distance(&self, from: u64, to: u64) -> Option<f64> {
        self.find_path(from, to).map(|p| p.cost)
    }

    /// Get all nodes reachable from `from`, optionally limited by max distance.
    ///
    /// # Parameters
    /// - `from` — `u64`. Source node ID.
    /// - `max_dist` — `Option<f64>`. Optional maximum travel cost cutoff.
    ///
    /// # Returns
    /// `Vec<u64>`.
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

            for edge in self.edges.values() {
                let neighbor = if edge.from_node == node_id {
                    Some(edge.to_node)
                } else if edge.bidirectional && edge.to_node == node_id {
                    Some(edge.from_node)
                } else {
                    None
                };

                if let Some(next) = neighbor {
                    if !edge.active {
                        continue;
                    }
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
        }

        result
    }

    /// Get direct outgoing neighbors of a node.
    ///
    /// # Parameters
    /// - `node_id` — `u64`. The node to query.
    ///
    /// # Returns
    /// `Vec<u64>`.
    pub fn get_neighbors(&self, node_id: u64) -> Vec<u64> {
        let mut result = HashSet::new();
        for edge in self.edges.values() {
            if edge.from_node == node_id && edge.active {
                result.insert(edge.to_node);
            }
            if edge.bidirectional && edge.to_node == node_id && edge.active {
                result.insert(edge.from_node);
            }
        }
        result.into_iter().collect()
    }

    /// Reconstruct a path from the predecessor map.
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
