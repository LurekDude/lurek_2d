use crate::graph::core::Graph;
use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap};
pub fn graph_astar(
    graph: &Graph,
    from: u64,
    to: u64,
    heuristic: Option<fn(u64, u64) -> f32>,
) -> Option<Vec<u64>> {
    if !graph.nodes.contains_key(&from) || !graph.nodes.contains_key(&to) {
        return None;
    }
    if from == to {
        return Some(vec![from]);
    }
    let mut open: BinaryHeap<GNode> = BinaryHeap::new();
    let mut g_cost: HashMap<u64, f32> = HashMap::new();
    let mut came_from: HashMap<u64, u64> = HashMap::new();
    g_cost.insert(from, 0.0);
    open.push(GNode { id: from, f: 0.0 });
    while let Some(GNode { id, .. }) = open.pop() {
        if id == to {
            return Some(reconstruct(came_from, to));
        }
        let cur_g = *g_cost.get(&id).unwrap_or(&f32::MAX);
        for edge in graph.edges.values() {
            if !edge.active {
                continue;
            }
            let neighbor = if edge.from_node == id {
                edge.to_node
            } else if edge.bidirectional && edge.to_node == id {
                edge.from_node
            } else {
                continue;
            };
            if !graph.nodes.contains_key(&neighbor) {
                continue;
            }
            let edge_cost = edge.weight.max(0.0) as f32;
            let new_g = cur_g + edge_cost;
            if new_g < *g_cost.get(&neighbor).unwrap_or(&f32::MAX) {
                g_cost.insert(neighbor, new_g);
                came_from.insert(neighbor, id);
                let h = heuristic.map_or(0.0, |f| f(neighbor, to));
                open.push(GNode {
                    id: neighbor,
                    f: new_g + h,
                });
            }
        }
    }
    None
}
pub fn graph_range(graph: &Graph, start: u64, max_cost: f32) -> Vec<(u64, f32)> {
    if !graph.nodes.contains_key(&start) {
        return Vec::new();
    }
    let mut dist: HashMap<u64, f32> = HashMap::new();
    let mut heap: BinaryHeap<GNode> = BinaryHeap::new();
    dist.insert(start, 0.0);
    heap.push(GNode { id: start, f: 0.0 });
    let mut result = Vec::new();
    while let Some(GNode { id, f: cost }) = heap.pop() {
        if cost > *dist.get(&id).unwrap_or(&f32::MAX) {
            continue;
        }
        result.push((id, cost));
        for edge in graph.edges.values() {
            if !edge.active {
                continue;
            }
            let neighbor = if edge.from_node == id {
                edge.to_node
            } else if edge.bidirectional && edge.to_node == id {
                edge.from_node
            } else {
                continue;
            };
            if !graph.nodes.contains_key(&neighbor) {
                continue;
            }
            let edge_cost = edge.weight.max(0.0) as f32;
            let new_cost = cost + edge_cost;
            if new_cost <= max_cost && new_cost < *dist.get(&neighbor).unwrap_or(&f32::MAX) {
                dist.insert(neighbor, new_cost);
                heap.push(GNode {
                    id: neighbor,
                    f: new_cost,
                });
            }
        }
    }
    result
}
fn reconstruct(came_from: HashMap<u64, u64>, mut current: u64) -> Vec<u64> {
    let mut path = vec![current];
    while let Some(&prev) = came_from.get(&current) {
        path.push(prev);
        current = prev;
    }
    path.reverse();
    path
}
#[derive(Clone)]
struct GNode {
    id: u64,
    f: f32,
}
impl PartialEq for GNode {
    fn eq(&self, other: &Self) -> bool {
        self.f == other.f
    }
}
impl Eq for GNode {}
impl PartialOrd for GNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
impl Ord for GNode {
    fn cmp(&self, other: &Self) -> Ordering {
        other.f.partial_cmp(&self.f).unwrap_or(Ordering::Equal)
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    use crate::graph::core::Graph;
    fn simple_graph() -> (Graph, u64, u64, u64) {
        let mut g = Graph::new();
        let n1 = g.add_node("room", 10);
        let n2 = g.add_node("room", 10);
        let n3 = g.add_node("room", 10);
        let _ = g.add_edge(n1, n2, None);
        let _ = g.add_edge(n2, n3, None);
        (g, n1, n2, n3)
    }
    #[test]
    fn same_node_path() {
        let (g, n1, _, _) = simple_graph();
        let p = graph_astar(&g, n1, n1, None).unwrap();
        assert_eq!(p, vec![n1]);
    }
    #[test]
    fn linear_path() {
        let (g, n1, n2, n3) = simple_graph();
        let p = graph_astar(&g, n1, n3, None).unwrap();
        assert_eq!(p, vec![n1, n2, n3]);
    }
    #[test]
    fn no_path_missing_node() {
        let (g, n1, _, _) = simple_graph();
        assert!(graph_astar(&g, n1, 9999, None).is_none());
    }
    #[test]
    fn range_query() {
        let (g, n1, n2, n3) = simple_graph();
        let r = graph_range(&g, n1, 1.5);
        let ids: Vec<u64> = r.iter().map(|(id, _)| *id).collect();
        assert!(ids.contains(&n1));
        assert!(ids.contains(&n2));
        let _ = n3;
    }
}
