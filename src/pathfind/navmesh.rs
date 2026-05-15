
//! - Polygon-based navigation mesh for 2D pathfinding.
//! - A\* search over polygon adjacency graph with centroid heuristic.
//! - Ray-cast point-in-polygon containment test.
//! - Centroid waypoint extraction from polygon corridors.
//! - Directed and bidirectional polygon connectivity.

use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap};
/// Polygon-based 2D navigation mesh supporting A\* pathfinding.
#[derive(Debug, Clone, Default)]
pub struct NavMesh {
    /// Vertex lists for each polygon region.
    polygons: Vec<Vec<(f32, f32)>>,
    /// Adjacency list: `neighbors[i]` holds polygon indices reachable from polygon `i`.
    neighbors: Vec<Vec<usize>>,
}
/// Construction and pathfinding methods for `NavMesh`.
impl NavMesh {
    /// Create an empty mesh. This function is part of the public API.
    pub fn new() -> Self {
        Self::default()
    }
    /// Add a polygon region with at least 3 vertices; return its index or `None` if fewer than 3 vertices.
    pub fn add_polygon(&mut self, vertices: Vec<(f32, f32)>) -> Option<usize> {
        if vertices.len() < 3 {
            return None;
        }
        let id = self.polygons.len();
        self.polygons.push(vertices);
        self.neighbors.push(Vec::new());
        Some(id)
    }
    /// Add a directed edge from polygon `a` to `b`; if `bidirectional`, also add the reverse edge.
    pub fn connect(&mut self, a: usize, b: usize, bidirectional: bool) -> bool {
        if a >= self.polygons.len() || b >= self.polygons.len() || a == b {
            return false;
        }
        if !self.neighbors[a].contains(&b) {
            self.neighbors[a].push(b);
        }
        if bidirectional && !self.neighbors[b].contains(&a) {
            self.neighbors[b].push(a);
        }
        true
    }
    /// Return the total number of registered polygons.
    pub fn polygon_count(&self) -> usize {
        self.polygons.len()
    }
    /// Find a world-space path from `start` to `goal`; return centroid waypoints or `None` if either point is outside all polygons.
    pub fn find_path(&self, start: (f32, f32), goal: (f32, f32)) -> Option<Vec<(f32, f32)>> {
        let start_poly = self.find_polygon_for_point(start)?;
        let goal_poly = self.find_polygon_for_point(goal)?;
        if start_poly == goal_poly {
            return Some(vec![start, goal]);
        }
        let corridor = self.astar_polygons(start_poly, goal_poly)?;
        let mut out = Vec::with_capacity(corridor.len() + 2);
        out.push(start);
        for poly in corridor
            .iter()
            .skip(1)
            .take(corridor.len().saturating_sub(2))
        {
            out.push(self.centroid(*poly));
        }
        out.push(goal);
        Some(out)
    }
    /// Return the index of the first polygon containing `point`, using ray-cast point-in-polygon test.
    fn find_polygon_for_point(&self, point: (f32, f32)) -> Option<usize> {
        self.polygons
            .iter()
            .position(|poly| point_in_polygon(point, poly))
    }
    /// Compute the centroid (average vertex) of polygon `poly_id`.
    fn centroid(&self, poly_id: usize) -> (f32, f32) {
        let poly = &self.polygons[poly_id];
        let mut sx = 0.0;
        let mut sy = 0.0;
        for (x, y) in poly {
            sx += *x;
            sy += *y;
        }
        let inv = 1.0 / poly.len() as f32;
        (sx * inv, sy * inv)
    }
    /// Run A\* over the polygon graph from `start` to `goal`, returning an ordered list of polygon indices.
    fn astar_polygons(&self, start: usize, goal: usize) -> Option<Vec<usize>> {
        let mut open = BinaryHeap::new();
        let mut g_score: HashMap<usize, f32> = HashMap::new();
        let mut parent: HashMap<usize, usize> = HashMap::new();
        g_score.insert(start, 0.0);
        open.push(Node {
            id: start,
            f: self.heuristic(start, goal),
        });
        while let Some(Node { id, .. }) = open.pop() {
            if id == goal {
                return Some(reconstruct(parent, goal));
            }
            let current_g = *g_score.get(&id).unwrap_or(&f32::INFINITY);
            for &next in &self.neighbors[id] {
                let tentative = current_g + self.distance(id, next);
                if tentative < *g_score.get(&next).unwrap_or(&f32::INFINITY) {
                    g_score.insert(next, tentative);
                    parent.insert(next, id);
                    open.push(Node {
                        id: next,
                        f: tentative + self.heuristic(next, goal),
                    });
                }
            }
        }
        None
    }
    /// Return the Euclidean distance between the centroids of polygons `a` and `b`.
    fn distance(&self, a: usize, b: usize) -> f32 {
        let (ax, ay) = self.centroid(a);
        let (bx, by) = self.centroid(b);
        ((bx - ax).powi(2) + (by - ay).powi(2)).sqrt()
    }
    /// Heuristic distance estimate for A\* (centroid-to-centroid).
    fn heuristic(&self, a: usize, b: usize) -> f32 {
        self.distance(a, b)
    }
}
/// Even-odd ray-cast point-in-polygon test.
fn point_in_polygon(point: (f32, f32), polygon: &[(f32, f32)]) -> bool {
    let (px, py) = point;
    let mut inside = false;
    let n = polygon.len();
    let mut j = n - 1;
    for i in 0..n {
        let (xi, yi) = polygon[i];
        let (xj, yj) = polygon[j];
        let intersect = ((yi > py) != (yj > py))
            && (px < (xj - xi) * (py - yi) / ((yj - yi).abs().max(f32::EPSILON)) + xi);
        if intersect {
            inside = !inside;
        }
        j = i;
    }
    inside
}
/// Walk `parent` chain from `goal` to start and return the path in forward order.
fn reconstruct(parent: HashMap<usize, usize>, mut current: usize) -> Vec<usize> {
    let mut out = vec![current];
    while let Some(prev) = parent.get(&current) {
        current = *prev;
        out.push(current);
    }
    out.reverse();
    out
}
/// Internal A\* heap node for polygon-level search.
#[derive(Clone)]
struct Node {
    /// Polygon index.
    id: usize,
    /// f-score = g + h.
    f: f32,
}
/// Equality by f-score.
impl PartialEq for Node {
    /// Compare two nodes by f-score equality.
    fn eq(&self, other: &Self) -> bool {
        self.f == other.f
    }
}
/// Marker trait asserting total equality for `Node`.
impl Eq for Node {}

/// Delegates to `Ord`.
impl PartialOrd for Node {
    /// Delegate partial comparison to the total `Ord` implementation.
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
/// Reverse ordering so `BinaryHeap` is a min-heap.
impl Ord for Node {
    /// Compare in reverse order to produce a min-heap from `BinaryHeap`.
    fn cmp(&self, other: &Self) -> Ordering {
        other.f.partial_cmp(&self.f).unwrap_or(Ordering::Equal)
    }
}
