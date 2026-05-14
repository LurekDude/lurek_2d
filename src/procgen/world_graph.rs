//! World-graph construction and pathfinding for `src/procgen`.
//! Owns `WorldRegion`, `WorldEdge`, `WorldGraph`, `generate_world_graph`, and the
//! private `WNode` min-heap entry. Provides A*, bounded Dijkstra, Kruskal MST,
//! and k-nearest edge generation. Does not own biome classification or dungeon layout.

use crate::procgen::lcg::Lcg;
use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap};

/// A named point-of-interest region in the world graph.
#[derive(Debug, Clone)]
pub struct WorldRegion {
    /// Unique region identifier assigned at insertion.
    pub id: u32,
    /// Human-readable name used for display or lookup.
    pub name: String,
    /// X world-space coordinate.
    pub x: f32,
    /// Y world-space coordinate.
    pub y: f32,
    /// Arbitrary classification tags attached to this region.
    pub tags: Vec<String>,
}

/// A directed or bidirectional connection between two regions.
#[derive(Debug, Clone)]
pub struct WorldEdge {
    /// Source region ID.
    pub from: u32,
    /// Destination region ID.
    pub to: u32,
    /// Traversal cost; clamped to >= 0 during pathfinding.
    pub cost: f32,
    /// When true, the edge can be traversed in both directions.
    pub bidirectional: bool,
}

/// Directed world graph with regions, edges, and graph algorithm methods.
#[derive(Debug, Clone, Default)]
pub struct WorldGraph {
    /// All regions in insertion order.
    pub regions: Vec<WorldRegion>,
    /// All edges in insertion order.
    pub edges: Vec<WorldEdge>,
    /// Auto-increment counter for new region IDs.
    next_id: u32,
}

impl WorldGraph {
    /// Create an empty world graph.
    pub fn new() -> Self {
        Self::default()
    }

    /// Add a named region at `(x, y)` and return its assigned ID.
    pub fn add_region(&mut self, name: &str, x: f32, y: f32) -> u32 {
        let id = self.next_id;
        self.next_id += 1;
        self.regions.push(WorldRegion {
            id,
            name: name.to_string(),
            x,
            y,
            tags: Vec::new(),
        });
        id
    }

    /// Add an edge from `from` to `to` with the given `cost`; bidirectional edges traverse both ways.
    pub fn add_edge(&mut self, from: u32, to: u32, cost: f32, bidirectional: bool) {
        self.edges.push(WorldEdge {
            from,
            to,
            cost,
            bidirectional,
        });
    }

    /// Find the shortest path from `from` to `to` using A* with Euclidean heuristic; returns `None` when no path exists.
    pub fn find_path(&self, from: u32, to: u32) -> Option<Vec<u32>> {
        if from == to {
            return Some(vec![from]);
        }
        let pos: HashMap<u32, (f32, f32)> =
            self.regions.iter().map(|r| (r.id, (r.x, r.y))).collect();
        let goal_pos = pos.get(&to).copied().unwrap_or((0.0, 0.0));
        let heuristic = |a: u32| -> f32 {
            let (ax, ay) = pos.get(&a).copied().unwrap_or((0.0, 0.0));
            ((ax - goal_pos.0).powi(2) + (ay - goal_pos.1).powi(2)).sqrt()
        };
        let mut g_cost: HashMap<u32, f32> = HashMap::new();
        let mut came_from: HashMap<u32, u32> = HashMap::new();
        let mut open: BinaryHeap<WNode> = BinaryHeap::new();
        g_cost.insert(from, 0.0);
        open.push(WNode {
            id: from,
            f: heuristic(from),
        });
        while let Some(WNode { id, .. }) = open.pop() {
            if id == to {
                return Some(self.reconstruct(&came_from, to));
            }
            let cur_g = *g_cost.get(&id).unwrap_or(&f32::MAX);
            for edge in self.edges.iter() {
                let neighbor = if edge.from == id {
                    edge.to
                } else if edge.bidirectional && edge.to == id {
                    edge.from
                } else {
                    continue;
                };
                let new_g = cur_g + edge.cost.max(0.0);
                if new_g < *g_cost.get(&neighbor).unwrap_or(&f32::MAX) {
                    g_cost.insert(neighbor, new_g);
                    came_from.insert(neighbor, id);
                    open.push(WNode {
                        id: neighbor,
                        f: new_g + heuristic(neighbor),
                    });
                }
            }
        }
        None
    }

    /// Return all region IDs reachable from `start` within cumulative edge cost `max_cost` using bounded Dijkstra.
    pub fn reachable_from(&self, start: u32, max_cost: f32) -> Vec<u32> {
        let mut dist: HashMap<u32, f32> = HashMap::new();
        let mut heap: BinaryHeap<WNode> = BinaryHeap::new();
        dist.insert(start, 0.0);
        heap.push(WNode { id: start, f: 0.0 });
        let mut result = Vec::new();
        while let Some(WNode { id, f: cost }) = heap.pop() {
            if cost > *dist.get(&id).unwrap_or(&f32::MAX) {
                continue;
            }
            result.push(id);
            for edge in self.edges.iter() {
                let nb = if edge.from == id {
                    edge.to
                } else if edge.bidirectional && edge.to == id {
                    edge.from
                } else {
                    continue;
                };
                let new_cost = cost + edge.cost.max(0.0);
                if new_cost <= max_cost && new_cost < *dist.get(&nb).unwrap_or(&f32::MAX) {
                    dist.insert(nb, new_cost);
                    heap.push(WNode {
                        id: nb,
                        f: new_cost,
                    });
                }
            }
        }
        result
    }

    /// Compute a minimum spanning tree using Kruskal's algorithm; returns `(from, to, cost)` triples.
    pub fn mst(&self) -> Vec<(u32, u32, f32)> {
        let mut sorted_edges: Vec<&WorldEdge> = self.edges.iter().collect();
        sorted_edges.sort_by(|a, b| a.cost.partial_cmp(&b.cost).unwrap_or(Ordering::Equal));
        let ids: Vec<u32> = self.regions.iter().map(|r| r.id).collect();
        let mut parent: HashMap<u32, u32> = ids.iter().map(|&id| (id, id)).collect();
        fn find(parent: &mut HashMap<u32, u32>, x: u32) -> u32 {
            if parent[&x] != x {
                let p = find(parent, parent[&x]);
                parent.insert(x, p);
            }
            parent[&x]
        }
        let mut result = Vec::new();
        for edge in sorted_edges {
            let rx = find(&mut parent, edge.from);
            let ry = find(&mut parent, edge.to);
            if rx != ry {
                parent.insert(rx, ry);
                result.push((edge.from, edge.to, edge.cost));
            }
        }
        result
    }

    /// Return references to all regions in insertion order.
    pub fn to_regions_list(&self) -> Vec<&WorldRegion> {
        self.regions.iter().collect()
    }

    /// Walk `came_from` back from `cur` to the start and return the forward path.
    fn reconstruct(&self, came_from: &HashMap<u32, u32>, mut cur: u32) -> Vec<u32> {
        let mut path = vec![cur];
        while let Some(&prev) = came_from.get(&cur) {
            path.push(prev);
            cur = prev;
        }
        path.reverse();
        path
    }
}

/// Generate a random world graph with `region_count` regions inside a `width × height` bounding box, connecting each to its 3 nearest neighbours.
pub fn generate_world_graph(width: f32, height: f32, region_count: u32, seed: u64) -> WorldGraph {
    let mut rng = Lcg::new(seed);
    let mut graph = WorldGraph::new();
    let mut positions: Vec<(u32, f32, f32)> = Vec::with_capacity(region_count as usize);
    for i in 0..region_count {
        let x = rng.next_f32() * width;
        let y = rng.next_f32() * height;
        let id = graph.add_region(&format!("Region{i}"), x, y);
        positions.push((id, x, y));
    }
    let k = 3usize;
    let ids: Vec<u32> = positions.iter().map(|p| p.0).collect();
    for &(id, x, y) in &positions {
        let mut dists: Vec<(u32, f32)> = ids
            .iter()
            .filter(|&&other| other != id)
            .map(|&other| {
                let (_, ox, oy) = positions[other as usize];
                let d = ((x - ox).powi(2) + (y - oy).powi(2)).sqrt();
                (other, d)
            })
            .collect();
        dists.sort_by(|a, b| a.1.partial_cmp(&b.1).unwrap_or(Ordering::Equal));
        for (other, cost) in dists.into_iter().take(k) {
            graph.add_edge(id, other, cost, true);
        }
    }
    graph
}

/// Min-heap entry used by A* and bounded Dijkstra; `f` is negated to make `BinaryHeap` act as a min-heap.
#[derive(Clone)]
struct WNode {
    /// Region ID at this heap entry.
    id: u32,
    /// Priority value; lower is better — `Ord` implementation reverses comparison.
    f: f32,
}

/// Delegate equality to `f` field comparison.
impl PartialEq for WNode {
    fn eq(&self, o: &Self) -> bool {
        self.f == o.f
    }
}

/// Satisfy `Eq` bound required by `BinaryHeap`.
impl Eq for WNode {}

/// Provide partial ordering over `f` for `Ord`.
impl PartialOrd for WNode {
    fn partial_cmp(&self, o: &Self) -> Option<Ordering> {
        Some(self.cmp(o))
    }
}

/// Reverse `f` ordering so `BinaryHeap` operates as a min-heap.
impl Ord for WNode {
    fn cmp(&self, o: &Self) -> Ordering {
        o.f.partial_cmp(&self.f).unwrap_or(Ordering::Equal)
    }
}
    pub id: u32,
    pub name: String,
    pub x: f32,
    pub y: f32,
    pub tags: Vec<String>,
}
#[derive(Debug, Clone)]
pub struct WorldEdge {
    pub from: u32,
    pub to: u32,
    pub cost: f32,
    pub bidirectional: bool,
}
#[derive(Debug, Clone, Default)]
pub struct WorldGraph {
    pub regions: Vec<WorldRegion>,
    pub edges: Vec<WorldEdge>,
    next_id: u32,
}
impl WorldGraph {
    pub fn new() -> Self {
        Self::default()
    }
    pub fn add_region(&mut self, name: &str, x: f32, y: f32) -> u32 {
        let id = self.next_id;
        self.next_id += 1;
        self.regions.push(WorldRegion {
            id,
            name: name.to_string(),
            x,
            y,
            tags: Vec::new(),
        });
        id
    }
    pub fn add_edge(&mut self, from: u32, to: u32, cost: f32, bidirectional: bool) {
        self.edges.push(WorldEdge {
            from,
            to,
            cost,
            bidirectional,
        });
    }
    pub fn find_path(&self, from: u32, to: u32) -> Option<Vec<u32>> {
        if from == to {
            return Some(vec![from]);
        }
        let pos: HashMap<u32, (f32, f32)> =
            self.regions.iter().map(|r| (r.id, (r.x, r.y))).collect();
        let goal_pos = pos.get(&to).copied().unwrap_or((0.0, 0.0));
        let heuristic = |a: u32| -> f32 {
            let (ax, ay) = pos.get(&a).copied().unwrap_or((0.0, 0.0));
            ((ax - goal_pos.0).powi(2) + (ay - goal_pos.1).powi(2)).sqrt()
        };
        let mut g_cost: HashMap<u32, f32> = HashMap::new();
        let mut came_from: HashMap<u32, u32> = HashMap::new();
        let mut open: BinaryHeap<WNode> = BinaryHeap::new();
        g_cost.insert(from, 0.0);
        open.push(WNode {
            id: from,
            f: heuristic(from),
        });
        while let Some(WNode { id, .. }) = open.pop() {
            if id == to {
                return Some(self.reconstruct(&came_from, to));
            }
            let cur_g = *g_cost.get(&id).unwrap_or(&f32::MAX);
            for edge in self.edges.iter() {
                let neighbor = if edge.from == id {
                    edge.to
                } else if edge.bidirectional && edge.to == id {
                    edge.from
                } else {
                    continue;
                };
                let new_g = cur_g + edge.cost.max(0.0);
                if new_g < *g_cost.get(&neighbor).unwrap_or(&f32::MAX) {
                    g_cost.insert(neighbor, new_g);
                    came_from.insert(neighbor, id);
                    open.push(WNode {
                        id: neighbor,
                        f: new_g + heuristic(neighbor),
                    });
                }
            }
        }
        None
    }
    pub fn reachable_from(&self, start: u32, max_cost: f32) -> Vec<u32> {
        let mut dist: HashMap<u32, f32> = HashMap::new();
        let mut heap: BinaryHeap<WNode> = BinaryHeap::new();
        dist.insert(start, 0.0);
        heap.push(WNode { id: start, f: 0.0 });
        let mut result = Vec::new();
        while let Some(WNode { id, f: cost }) = heap.pop() {
            if cost > *dist.get(&id).unwrap_or(&f32::MAX) {
                continue;
            }
            result.push(id);
            for edge in self.edges.iter() {
                let nb = if edge.from == id {
                    edge.to
                } else if edge.bidirectional && edge.to == id {
                    edge.from
                } else {
                    continue;
                };
                let new_cost = cost + edge.cost.max(0.0);
                if new_cost <= max_cost && new_cost < *dist.get(&nb).unwrap_or(&f32::MAX) {
                    dist.insert(nb, new_cost);
                    heap.push(WNode {
                        id: nb,
                        f: new_cost,
                    });
                }
            }
        }
        result
    }
    pub fn mst(&self) -> Vec<(u32, u32, f32)> {
        let mut sorted_edges: Vec<&WorldEdge> = self.edges.iter().collect();
        sorted_edges.sort_by(|a, b| a.cost.partial_cmp(&b.cost).unwrap_or(Ordering::Equal));
        let ids: Vec<u32> = self.regions.iter().map(|r| r.id).collect();
        let mut parent: HashMap<u32, u32> = ids.iter().map(|&id| (id, id)).collect();
        fn find(parent: &mut HashMap<u32, u32>, x: u32) -> u32 {
            if parent[&x] != x {
                let p = find(parent, parent[&x]);
                parent.insert(x, p);
            }
            parent[&x]
        }
        let mut result = Vec::new();
        for edge in sorted_edges {
            let rx = find(&mut parent, edge.from);
            let ry = find(&mut parent, edge.to);
            if rx != ry {
                parent.insert(rx, ry);
                result.push((edge.from, edge.to, edge.cost));
            }
        }
        result
    }
    pub fn to_regions_list(&self) -> Vec<&WorldRegion> {
        self.regions.iter().collect()
    }
    fn reconstruct(&self, came_from: &HashMap<u32, u32>, mut cur: u32) -> Vec<u32> {
        let mut path = vec![cur];
        while let Some(&prev) = came_from.get(&cur) {
            path.push(prev);
            cur = prev;
        }
        path.reverse();
        path
    }
}
pub fn generate_world_graph(width: f32, height: f32, region_count: u32, seed: u64) -> WorldGraph {
    let mut rng = Lcg::new(seed);
    let mut graph = WorldGraph::new();
    let mut positions: Vec<(u32, f32, f32)> = Vec::with_capacity(region_count as usize);
    for i in 0..region_count {
        let x = rng.next_f32() * width;
        let y = rng.next_f32() * height;
        let id = graph.add_region(&format!("Region{i}"), x, y);
        positions.push((id, x, y));
    }
    let k = 3usize;
    let ids: Vec<u32> = positions.iter().map(|p| p.0).collect();
    for &(id, x, y) in &positions {
        let mut dists: Vec<(u32, f32)> = ids
            .iter()
            .filter(|&&other| other != id)
            .map(|&other| {
                let (_, ox, oy) = positions[other as usize];
                let d = ((x - ox).powi(2) + (y - oy).powi(2)).sqrt();
                (other, d)
            })
            .collect();
        dists.sort_by(|a, b| a.1.partial_cmp(&b.1).unwrap_or(Ordering::Equal));
        for (other, cost) in dists.into_iter().take(k) {
            graph.add_edge(id, other, cost, true);
        }
    }
    graph
}
#[derive(Clone)]
struct WNode {
    id: u32,
    f: f32,
}
impl PartialEq for WNode {
    fn eq(&self, o: &Self) -> bool {
        self.f == o.f
    }
}
impl Eq for WNode {}
impl PartialOrd for WNode {
    fn partial_cmp(&self, o: &Self) -> Option<Ordering> {
        Some(self.cmp(o))
    }
}
impl Ord for WNode {
    fn cmp(&self, o: &Self) -> Ordering {
        o.f.partial_cmp(&self.f).unwrap_or(Ordering::Equal)
    }
}
