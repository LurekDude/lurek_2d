
use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap, HashSet};
/// Result of a province-level pathfinding query.
#[derive(Debug, Clone)]
pub struct ProvincePath {
    /// Ordered sequence of province ids from start to destination, inclusive.
    pub provinces: Vec<u32>,
    /// Summed move cost along the chosen path.
    pub total_cost: f64,
}
/// Per-province and per-edge-tag move-cost configuration passed to path queries.
#[derive(Debug, Clone, Default)]
pub struct ProvinceCostFn {
    /// Base cost applied to every traversable province.
    pub default_cost: f64,
    /// Per-province cost additions keyed by province id.
    pub province_costs: HashMap<u32, f64>,
    /// Edge surcharges applied when a crossing edge carries the given tag.
    pub tag_costs: HashMap<String, f64>,
    /// Province ids that cannot be entered; paths will not pass through them.
    pub blocked: HashSet<u32>,
}
/// Construction and cost helpers for `ProvinceCostFn`.
impl ProvinceCostFn {
    /// Create a default cost function with `default_cost = 1.0` and no blocked provinces.
    pub fn new() -> Self {
        Self {
            default_cost: 1.0,
            ..Default::default()
        }
    }
    /// Return the total cost to enter `province_id`, or `None` when blocked or infinite.
    fn cost_for(&self, province_id: u32) -> Option<f64> {
        if self.blocked.contains(&province_id) {
            return None;
        }
        let base = self.default_cost;
        let extra = self
            .province_costs
            .get(&province_id)
            .copied()
            .unwrap_or(0.0);
        let total = base + extra;
        if total.is_infinite() {
            None
        } else {
            Some(total)
        }
    }
    /// Sum tag surcharges for an edge whose tag set intersects `edge_tags`.
    fn edge_cost(&self, edge_tags: &HashSet<String>) -> f64 {
        let mut extra = 0.0;
        for (tag, &cost) in &self.tag_costs {
            if edge_tags.contains(tag) {
                extra += cost;
            }
        }
        extra
    }
}
/// Internal priority-queue node for province-level A\* and Dijkstra.
struct AStarNode {
    /// Province id held by this node.
    province_id: u32,
    /// f-score (g + h for A\*, g for Dijkstra).
    f_score: f64,
}
/// Equality by f-score.
impl PartialEq for AStarNode {
    fn eq(&self, other: &Self) -> bool {
        self.f_score == other.f_score
    }
}
impl Eq for AStarNode {}

/// Delegates to `Ord`.
impl PartialOrd for AStarNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
/// Reverse ordering so `BinaryHeap` is a min-heap on f-score.
impl Ord for AStarNode {
    fn cmp(&self, other: &Self) -> Ordering {
        other
            .f_score
            .partial_cmp(&self.f_score)
            .unwrap_or(Ordering::Equal)
    }
}
/// Run A\* across province adjacency; return the cheapest path and its cost, or `None` when unreachable.
pub fn find_province_path(
    neighbors: &HashMap<u32, Vec<u32>>,
    centroids: &HashMap<u32, (f32, f32)>,
    edge_tags: &HashMap<(u32, u32), HashSet<String>>,
    from: u32,
    to: u32,
    cost_fn: &ProvinceCostFn,
) -> Option<ProvincePath> {
    if from == to {
        return Some(ProvincePath {
            provinces: vec![from],
            total_cost: 0.0,
        });
    }
    let goal_centroid = centroids.get(&to)?;
    centroids.get(&from)?;
    let mut open = BinaryHeap::new();
    let mut g_score: HashMap<u32, f64> = HashMap::new();
    let mut came_from: HashMap<u32, u32> = HashMap::new();
    let mut closed: HashSet<u32> = HashSet::new();
    g_score.insert(from, 0.0);
    let h = centroid_distance(centroids.get(&from)?, goal_centroid);
    open.push(AStarNode {
        province_id: from,
        f_score: h,
    });
    while let Some(current) = open.pop() {
        let current_id = current.province_id;
        if current_id == to {
            let mut path = vec![to];
            let mut node = to;
            while let Some(&prev) = came_from.get(&node) {
                path.push(prev);
                node = prev;
            }
            path.reverse();
            return Some(ProvincePath {
                provinces: path,
                total_cost: g_score[&to],
            });
        }
        if !closed.insert(current_id) {
            continue;
        }
        let current_g = g_score[&current_id];
        let empty_neighbors = Vec::new();
        let neighbor_ids = neighbors.get(&current_id).unwrap_or(&empty_neighbors);
        for &neighbor_id in neighbor_ids {
            if closed.contains(&neighbor_id) {
                continue;
            }
            let step_cost = match cost_fn.cost_for(neighbor_id) {
                Some(c) => c,
                None => continue,
            };
            let edge_key = if current_id <= neighbor_id {
                (current_id, neighbor_id)
            } else {
                (neighbor_id, current_id)
            };
            let edge_extra = edge_tags
                .get(&edge_key)
                .map(|tags| cost_fn.edge_cost(tags))
                .unwrap_or(0.0);
            let tentative_g = current_g + step_cost + edge_extra;
            if tentative_g < *g_score.get(&neighbor_id).unwrap_or(&f64::INFINITY) {
                g_score.insert(neighbor_id, tentative_g);
                came_from.insert(neighbor_id, current_id);
                let nc = match centroids.get(&neighbor_id) {
                    Some(c) => c,
                    None => continue,
                };
                let h = centroid_distance(nc, goal_centroid);
                open.push(AStarNode {
                    province_id: neighbor_id,
                    f_score: tentative_g + h,
                });
            }
        }
    }
    None
}
/// Return all provinces reachable from `start` within `max_cost` as a map of `province_id → cost`.
pub fn province_reachable(
    neighbors: &HashMap<u32, Vec<u32>>,
    edge_tags: &HashMap<(u32, u32), HashSet<String>>,
    start: u32,
    max_cost: f64,
    cost_fn: &ProvinceCostFn,
) -> HashMap<u32, f64> {
    let mut dist: HashMap<u32, f64> = HashMap::new();
    let mut heap = BinaryHeap::new();
    let mut visited: HashSet<u32> = HashSet::new();
    dist.insert(start, 0.0);
    heap.push(AStarNode {
        province_id: start,
        f_score: 0.0,
    });
    while let Some(current) = heap.pop() {
        let current_id = current.province_id;
        let current_dist = *dist.get(&current_id).unwrap_or(&f64::INFINITY);
        if current_dist > max_cost || !visited.insert(current_id) {
            continue;
        }
        let empty_neighbors = Vec::new();
        let neighbor_ids = neighbors.get(&current_id).unwrap_or(&empty_neighbors);
        for &neighbor_id in neighbor_ids {
            if visited.contains(&neighbor_id) {
                continue;
            }
            let step_cost = match cost_fn.cost_for(neighbor_id) {
                Some(c) => c,
                None => continue,
            };
            let edge_key = if current_id <= neighbor_id {
                (current_id, neighbor_id)
            } else {
                (neighbor_id, current_id)
            };
            let edge_extra = edge_tags
                .get(&edge_key)
                .map(|tags| cost_fn.edge_cost(tags))
                .unwrap_or(0.0);
            let new_dist = current_dist + step_cost + edge_extra;
            if new_dist <= max_cost && new_dist < *dist.get(&neighbor_id).unwrap_or(&f64::INFINITY)
            {
                dist.insert(neighbor_id, new_dist);
                heap.push(AStarNode {
                    province_id: neighbor_id,
                    f_score: new_dist,
                });
            }
        }
    }
    dist.into_iter()
        .filter(|(id, _)| visited.contains(id))
        .collect()
}
/// Return Euclidean distance between two centroid points.
fn centroid_distance(a: &(f32, f32), b: &(f32, f32)) -> f64 {
    let dx = (a.0 - b.0) as f64;
    let dy = (a.1 - b.1) as f64;
    (dx * dx + dy * dy).sqrt()
}
