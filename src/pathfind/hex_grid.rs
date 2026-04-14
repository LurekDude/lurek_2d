//! Hexagonal grid pathfinding, LOS, FOV, and range-of-movement.
//!
//! Uses offset coordinates (odd-r) with flat-top or pointy-top hex layouts.
//! A* is used for pathfinding; Dijkstra for range-of-movement.

use std::collections::{BinaryHeap, HashMap};
use std::cmp::Ordering;

/// Hex grid layout orientation.
///
/// # Variants
/// - `FlatTop` — FlatTop variant.
/// - `PointyTop` — PointyTop variant.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum HexLayout {
    /// Flat-top hexagons (pointy sides on left/right).
    FlatTop,
    /// Pointy-top hexagons (flat sides on left/right).
    PointyTop,
}

/// A hexagonal grid supporting pathfinding, LOS, FOV, and range queries.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
pub struct HexGrid {
    /// Width in columns.
    pub width: u32,
    /// Height in rows.
    pub height: u32,
    layout: HexLayout,
    blocked: Vec<bool>,
    cost: Vec<f32>,
}

impl HexGrid {
    /// Create a new hex grid of the given size and layout.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    /// - `layout` — `HexLayout`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// All cells start unblocked with cost `1.0`.
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

    /// Mark or unmark a cell as blocked.
    ///
    /// # Parameters
    /// - `col` — `u32`.
    /// - `row` — `u32`.
    /// - `blocked` — `bool`.
    pub fn set_blocked(&mut self, col: u32, row: u32, blocked: bool) {
        if let Some(idx) = self.index(col, row) {
            self.blocked[idx] = blocked;
        }
    }

    /// Set the movement cost for a cell. Zero cost means impassable.
    ///
    /// # Parameters
    /// - `col` — `u32`.
    /// - `row` — `u32`.
    /// - `cost` — `f32`.
    pub fn set_cost(&mut self, col: u32, row: u32, cost: f32) {
        if let Some(idx) = self.index(col, row) {
            self.cost[idx] = cost;
        }
    }

    /// Returns `true` if the cell is blocked or out of bounds.
    ///
    /// # Parameters
    /// - `col` — `u32`.
    /// - `row` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_blocked(&self, col: u32, row: u32) -> bool {
        self.index(col, row).map_or(true, |i| self.blocked[i])
    }

    /// A* pathfinding on the hex grid.
    ///
    /// # Parameters
    /// - `from` — `(u32, u32)`.
    /// - `to` — `(u32, u32)`.
    ///
    /// # Returns
    /// `Option<Vec<(u32, u32)>>`.
    ///
    /// Returns `Some(path)` as a vec of `(col, row)` tuples, or `None` if unreachable.
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
                    open.push(AStarNode { pos: nb, f: new_g + h });
                }
            }
        }
        None
    }

    /// Line-of-sight between two hex cells using hex linear interpolation.
    ///
    /// # Parameters
    /// - `from` — `(u32, u32)`.
    /// - `to` — `(u32, u32)`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Returns `true` if no blocked cell lies along the line.
    pub fn line_of_sight(&self, from: (u32, u32), to: (u32, u32)) -> bool {
        let line = self.hex_line(from, to);
        for cell in &line {
            if self.is_blocked(cell.0, cell.1) {
                return false;
            }
        }
        true
    }

    /// Field of view from `origin` out to `max_range`.
    ///
    /// # Parameters
    /// - `origin` — `(u32, u32)`.
    /// - `max_range` — `u32`.
    ///
    /// # Returns
    /// `Vec<(u32, u32)>`.
    ///
    /// Returns all cells visible from the origin within range (shadow-casting approximation).
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

    /// Range-of-movement: all cells reachable within `budget` using Dijkstra.
    ///
    /// # Parameters
    /// - `origin` — `(u32, u32)`.
    /// - `budget` — `f32`.
    ///
    /// # Returns
    /// `Vec<(u32, u32)>`.
    pub fn range_of_movement(&self, origin: (u32, u32), budget: f32) -> Vec<(u32, u32)> {
        let mut cost_map: HashMap<(u32, u32), f32> = HashMap::new();
        let mut heap: BinaryHeap<AStarNode> = BinaryHeap::new();

        cost_map.insert(origin, 0.0);
        heap.push(AStarNode { pos: origin, f: 0.0 });

        let mut result = Vec::new();

        while let Some(AStarNode { pos, f: current_cost }) = heap.pop() {
            if current_cost > *cost_map.get(&pos).unwrap_or(&f32::MAX) {
                continue;
            }
            result.push(pos);

            for nb in self.neighbors(pos.0, pos.1) {
                let nb_idx = self.index(nb.0, nb.1).unwrap();
                let new_cost = current_cost + self.cost[nb_idx];
                if new_cost <= budget && new_cost < *cost_map.get(&nb).unwrap_or(&f32::MAX) {
                    cost_map.insert(nb, new_cost);
                    heap.push(AStarNode { pos: nb, f: new_cost });
                }
            }
        }
        result
    }

    /// Returns grid-bounded neighbors for the given cell in offset coordinates.
    ///
    /// # Parameters
    /// - `col` — `u32`.
    /// - `row` — `u32`.
    ///
    /// # Returns
    /// `Vec<(u32, u32)>`.
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

    /// Hex distance between two cells (cube coordinate distance).
    ///
    /// # Parameters
    /// - `a` — `(u32, u32)`.
    /// - `b` — `(u32, u32)`.
    ///
    /// # Returns
    /// `u32`.
    pub fn distance(&self, a: (u32, u32), b: (u32, u32)) -> u32 {
        let (ax, ay, az) = self.to_cube(a);
        let (bx, by, bz) = self.to_cube(b);
        (((ax - bx).abs() + (ay - by).abs() + (az - bz).abs()) / 2) as u32
    }

    // ── Private helpers ────────────────────────────────────────────────

    fn index(&self, col: u32, row: u32) -> Option<usize> {
        if col < self.width && row < self.height {
            Some((row * self.width + col) as usize)
        } else {
            None
        }
    }

    /// Offset-to-cube coordinate conversion (odd-r).
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

    /// Cube-to-offset coordinate conversion.
    fn from_cube(&self, x: i32, y: i32, z: i32) -> (u32, u32) {
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

    /// Neighbor direction offsets for odd-r offset coordinates.
    fn neighbor_dirs(&self, row: u32) -> [(i32, i32); 6] {
        match self.layout {
            HexLayout::PointyTop => {
                if row % 2 == 0 {
                    [(1, 0), (0, -1), (-1, -1), (-1, 0), (-1, 1), (0, 1)]
                } else {
                    [(1, 0), (1, -1), (0, -1), (-1, 0), (0, 1), (1, 1)]
                }
            }
            HexLayout::FlatTop => {
                [(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)]
            }
        }
    }

    /// Generate all cells along the hex line from `a` to `b`.
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
            // Cube-round fix
            let (rx, ry, rz) = cube_round(cx as f32, cy as f32, cz as f32);
            let cell = self.from_cube(rx, ry, rz);
            if cell.0 < self.width && cell.1 < self.height {
                result.push(cell);
            }
        }
        result
    }
}

/// Round floating-point cube coordinates to integers.
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

// ── A* node ──────────────────────────────────────────────────────────────

#[derive(Clone)]
struct AStarNode {
    pos: (u32, u32),
    f: f32,
}

impl PartialEq for AStarNode {
    fn eq(&self, other: &Self) -> bool { self.f == other.f }
}
impl Eq for AStarNode {}

impl PartialOrd for AStarNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> { Some(self.cmp(other)) }
}

impl Ord for AStarNode {
    fn cmp(&self, other: &Self) -> Ordering {
        other.f.partial_cmp(&self.f).unwrap_or(Ordering::Equal)
    }
}

fn reconstruct_path(came_from: &HashMap<(u32, u32), (u32, u32)>, mut current: (u32, u32)) -> Vec<(u32, u32)> {
    let mut path = vec![current];
    while let Some(&prev) = came_from.get(&current) {
        path.push(prev);
        current = prev;
    }
    path.reverse();
    path
}
