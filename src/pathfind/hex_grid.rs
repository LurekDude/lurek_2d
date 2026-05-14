//! Offset-coordinate hexagonal grid with flat-top and pointy-top layout support.
//! Provides A\*, range-of-movement, line-of-sight, field-of-view, and neighbour queries.
//! Does not own Lua bindings; consumed by `src/lua_api/pathfind_api.rs`.

use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap};
/// Hex layout convention: column or row is the flat side.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum HexLayout {
    /// Hexagons have flat sides on the left and right; columns are aligned vertically.
    FlatTop,
    /// Hexagons have pointy sides on the top and bottom; rows are aligned horizontally.
    PointyTop,
}
/// Hex grid holding walkability and per-cell movement costs.
pub struct HexGrid {
    /// Grid column count.
    pub width: u32,
    /// Grid row count.
    pub height: u32,
    /// Hex topology: flat-top or pointy-top offset convention.
    layout: HexLayout,
    /// Flat blocked flags indexed by `(row * width + col)`.
    blocked: Vec<bool>,
    /// Per-cell movement cost.
    cost: Vec<f32>,
}
/// Construction and pathfinding methods for `HexGrid`.
impl HexGrid {
    /// Create a fully unblocked hex grid of size `width × height` using `layout`.
    pub fn new(width: u32, height: u32, layout: HexLayout) -> Self {
        let n = (width * height) as usize;
        Self {
            width,
            height,
            layout,
            blocked: vec![false; n],
            cost: vec![1.0; n],
        }
    }
    /// Mark cell `(col, row)` as blocked or passable.
    pub fn set_blocked(&mut self, col: u32, row: u32, blocked: bool) {
        if let Some(idx) = self.index(col, row) {
            self.blocked[idx] = blocked;
        }
    }
    /// Set movement cost for cell `(col, row)`.
    pub fn set_cost(&mut self, col: u32, row: u32, cost: f32) {
        if let Some(idx) = self.index(col, row) {
            self.cost[idx] = cost;
        }
    }
    /// Return true when `(col, row)` is out-of-bounds or explicitly blocked.
    pub fn is_blocked(&self, col: u32, row: u32) -> bool {
        self.index(col, row).is_none_or(|i| self.blocked[i])
    }
    /// Run A\* from `from` to `to`; return ordered path or `None` when unreachable.
    pub fn find_path(&self, from: (u32, u32), to: (u32, u32)) -> Option<Vec<(u32, u32)>> {
        if self.is_blocked(from.0, from.1) || self.is_blocked(to.0, to.1) {
            return None;
        }
        if from == to {
            return Some(vec![from]);
        }
        let mut open: BinaryHeap<AStarNode> = BinaryHeap::new();
        let mut g_cost: HashMap<(u32, u32), f32> = HashMap::new();
        let mut came_from: HashMap<(u32, u32), (u32, u32)> = HashMap::new();
        g_cost.insert(from, 0.0);
        open.push(AStarNode { pos: from, f: 0.0 });
        while let Some(AStarNode { pos, .. }) = open.pop() {
            if pos == to {
                return Some(reconstruct_path(&came_from, to));
            }
            let current_g = *g_cost.get(&pos).unwrap_or(&f32::MAX);
            for nb in self.neighbors(pos.0, pos.1) {
                let nb_idx = self.index(nb.0, nb.1).unwrap();
                let move_cost = self.cost[nb_idx];
                let new_g = current_g + move_cost;
                if new_g < *g_cost.get(&nb).unwrap_or(&f32::MAX) {
                    g_cost.insert(nb, new_g);
                    came_from.insert(nb, pos);
                    let h = self.distance(nb, to) as f32;
                    open.push(AStarNode {
                        pos: nb,
                        f: new_g + h,
                    });
                }
            }
        }
        None
    }
    /// Return true when every hex on the straight line from `from` to `to` is passable.
    pub fn line_of_sight(&self, from: (u32, u32), to: (u32, u32)) -> bool {
        let line = self.hex_line(from, to);
        for cell in &line {
            if self.is_blocked(cell.0, cell.1) {
                return false;
            }
        }
        true
    }
    /// Return all cells visible from `origin` within `max_range` hex steps.
    pub fn field_of_view(&self, origin: (u32, u32), max_range: u32) -> Vec<(u32, u32)> {
        let mut visible = Vec::new();
        for row in 0..self.height {
            for col in 0..self.width {
                let cell = (col, row);
                if self.distance(origin, cell) <= max_range && self.line_of_sight(origin, cell) {
                    visible.push(cell);
                }
            }
        }
        visible
    }
    /// Return all cells reachable from `origin` with total movement cost ≤ `budget`.
    pub fn range_of_movement(&self, origin: (u32, u32), budget: f32) -> Vec<(u32, u32)> {
        let mut cost_map: HashMap<(u32, u32), f32> = HashMap::new();
        let mut heap: BinaryHeap<AStarNode> = BinaryHeap::new();
        cost_map.insert(origin, 0.0);
        heap.push(AStarNode {
            pos: origin,
            f: 0.0,
        });
        let mut result = Vec::new();
        while let Some(AStarNode {
            pos,
            f: current_cost,
        }) = heap.pop()
        {
            if current_cost > *cost_map.get(&pos).unwrap_or(&f32::MAX) {
                continue;
            }
            result.push(pos);
            for nb in self.neighbors(pos.0, pos.1) {
                let nb_idx = self.index(nb.0, nb.1).unwrap();
                let new_cost = current_cost + self.cost[nb_idx];
                if new_cost <= budget && new_cost < *cost_map.get(&nb).unwrap_or(&f32::MAX) {
                    cost_map.insert(nb, new_cost);
                    heap.push(AStarNode {
                        pos: nb,
                        f: new_cost,
                    });
                }
            }
        }
        result
    }
    /// Return the passable hex neighbours of `(col, row)` using layout-appropriate offsets.
    pub fn neighbors(&self, col: u32, row: u32) -> Vec<(u32, u32)> {
        let dirs = self.neighbor_dirs(row);
        let mut result = Vec::with_capacity(6);
        for (dc, dr) in dirs {
            let nc = col as i32 + dc;
            let nr = row as i32 + dr;
            if nc >= 0 && nc < self.width as i32 && nr >= 0 && nr < self.height as i32 {
                let c = nc as u32;
                let r = nr as u32;
                if !self.is_blocked(c, r) {
                    result.push((c, r));
                }
            }
        }
        result
    }
    /// Return the hex-grid distance between `a` and `b` in steps.
    pub fn distance(&self, a: (u32, u32), b: (u32, u32)) -> u32 {
        let (ax, ay, az) = self.to_cube(a);
        let (bx, by, bz) = self.to_cube(b);
        (((ax - bx).abs() + (ay - by).abs() + (az - bz).abs()) / 2) as u32
    }
    /// Convert offset coordinates to cube coordinates.
    fn index(&self, col: u32, row: u32) -> Option<usize> {
        if col < self.width && row < self.height {
            Some((row * self.width + col) as usize)
        } else {
            None
        }
    }
    /// Convert offset `(col, row)` to cube `(x, y, z)` coordinates using `layout`.
    fn to_cube(&self, cell: (u32, u32)) -> (i32, i32, i32) {
        let (col, row) = (cell.0 as i32, cell.1 as i32);
        match self.layout {
            HexLayout::PointyTop => {
                let x = col - (row - (row & 1)) / 2;
                let z = row;
                let y = -x - z;
                (x, y, z)
            }
            HexLayout::FlatTop => {
                let x = col;
                let z = row - (col - (col & 1)) / 2;
                let y = -x - z;
                (x, y, z)
            }
        }
    }
    /// Convert cube `(x, _, z)` back to offset `(col, row)` using `layout`.
    #[allow(clippy::wrong_self_convention)]
    fn from_cube(&self, x: i32, _y: i32, z: i32) -> (u32, u32) {
        match self.layout {
            HexLayout::PointyTop => {
                let col = x + (z - (z & 1)) / 2;
                ((col.max(0)) as u32, (z.max(0)) as u32)
            }
            HexLayout::FlatTop => {
                let row = z + (x - (x & 1)) / 2;
                ((x.max(0)) as u32, (row.max(0)) as u32)
            }
        }
    }
    /// Return the six `(dc, dr)` offset deltas for neighbours of `row` given the current layout.
    fn neighbor_dirs(&self, row: u32) -> [(i32, i32); 6] {
        match self.layout {
            HexLayout::PointyTop => {
                if row.is_multiple_of(2) {
                    [(1, 0), (0, -1), (-1, -1), (-1, 0), (-1, 1), (0, 1)]
                } else {
                    [(1, 0), (1, -1), (0, -1), (-1, 0), (0, 1), (1, 1)]
                }
            }
            HexLayout::FlatTop => [(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)],
        }
    }
    /// Return all cells on the hex line from `a` to `b` using cube-coordinate interpolation.
    fn hex_line(&self, a: (u32, u32), b: (u32, u32)) -> Vec<(u32, u32)> {
        let dist = self.distance(a, b) as usize;
        if dist == 0 {
            return vec![a];
        }
        let (ax, ay, az) = self.to_cube(a);
        let (bx, by, bz) = self.to_cube(b);
        let mut result = Vec::with_capacity(dist + 1);
        for i in 0..=dist {
            let t = i as f32 / dist as f32;
            let cx = (ax as f32 + t * (bx - ax) as f32).round() as i32;
            let cy = (ay as f32 + t * (by - ay) as f32).round() as i32;
            let cz = (az as f32 + t * (bz - az) as f32).round() as i32;
            let (rx, ry, rz) = cube_round(cx as f32, cy as f32, cz as f32);
            let cell = self.from_cube(rx, ry, rz);
            if cell.0 < self.width && cell.1 < self.height {
                result.push(cell);
            }
        }
        result
    }
}
/// Round fractional cube coordinates to the nearest integer cube cell.
fn cube_round(x: f32, y: f32, z: f32) -> (i32, i32, i32) {
    let mut rx = x.round() as i32;
    let mut ry = y.round() as i32;
    let mut rz = z.round() as i32;
    let dx = (rx as f32 - x).abs();
    let dy = (ry as f32 - y).abs();
    let dz = (rz as f32 - z).abs();
    if dx > dy && dx > dz {
        rx = -ry - rz;
    } else if dy > dz {
        ry = -rx - rz;
    } else {
        rz = -rx - ry;
    }
    (rx, ry, rz)
}
/// Internal A\* node holding position and f-score.
#[derive(Clone)]
struct AStarNode {
    /// Hex cell position.
    pos: (u32, u32),
    /// f-score = g + h.
    f: f32,
}
/// Equality by f-score.
impl PartialEq for AStarNode {
    fn eq(&self, other: &Self) -> bool {
        self.f == other.f
    }
}
impl Eq for AStarNode {}

/// Delegates to `Ord`.
impl PartialOrd for AStarNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
/// Reverse ordering so `BinaryHeap` is a min-heap.
impl Ord for AStarNode {
    fn cmp(&self, other: &Self) -> Ordering {
        other.f.partial_cmp(&self.f).unwrap_or(Ordering::Equal)
    }
}
/// Walk `came_from` back from `current` to the start and return the path in forward order.
fn reconstruct_path(
    came_from: &HashMap<(u32, u32), (u32, u32)>,
    mut current: (u32, u32),
) -> Vec<(u32, u32)> {
    let mut path = vec![current];
    while let Some(&prev) = came_from.get(&current) {
        path.push(prev);
        current = prev;
    }
    path.reverse();
    path
}
