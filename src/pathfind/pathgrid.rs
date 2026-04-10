//! Weighted grid pathfinding (A*, Dijkstra) with obstacle support.
//! Moved from `ai/pathgrid`; used by the Lua `lurek.ai.newPathGrid` API.
//!
//! This module is part of Lurek2D's `pathfinding` subsystem and provides the implementation
//! details for pathgrid-related operations and data management.
//! Key types exported from this module: `Cell`, `PathGrid`.
//! Primary functions: `new()`, `in_bounds()`, `set_walkable()`, `is_walkable()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use std::cmp::Ordering;
use std::collections::BinaryHeap;

/// Single cell of the navigation grid.
///
/// # Fields
/// - `walkable` — `bool`.
/// - `cost` — `f32`.
#[derive(Debug, Clone)]
pub struct Cell {
    /// Whether agents can traverse this cell.
    pub walkable: bool,
    /// Traversal cost multiplier (1.0 = normal).
    pub cost: f32,
}

impl Default for Cell {
    fn default() -> Self {
        Self {
            walkable: true,
            cost: 1.0,
        }
    }
}

/// A★ node for the priority queue.
#[derive(Debug, Clone)]
struct AStarNode {
    idx: usize,
    f_cost: f32,
}

impl PartialEq for AStarNode {
    fn eq(&self, other: &Self) -> bool {
        self.f_cost == other.f_cost
    }
}
impl Eq for AStarNode {}
impl PartialOrd for AStarNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
impl Ord for AStarNode {
    fn cmp(&self, other: &Self) -> Ordering {
        // Reverse ordering for min-heap
        other
            .f_cost
            .partial_cmp(&self.f_cost)
            .unwrap_or(Ordering::Equal)
    }
}

/// A★ navigation grid.
///
/// # Fields
/// - `width` — `usize`.
/// - `height` — `usize`.
/// - `cell_size` — `f32`.
///
/// Cells are stored row-major, 0-based internally.
/// Supports walkability toggling and per-cell cost multipliers.
pub struct PathGrid {
    /// Grid width in cells.
    pub width: usize,
    /// Grid height in cells.
    pub height: usize,
    /// World-space size of each cell.
    pub cell_size: f32,
    /// Row-major cell data.
    cells: Vec<Cell>,
}

impl PathGrid {
    /// Creates a new PathGrid where all cells are walkable with cost 1.0.
    ///
    /// # Parameters
    /// - `width` — `usize`.
    /// - `height` — `usize`.
    /// - `cell_size` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(width: usize, height: usize, cell_size: f32) -> Self {
        Self {
            width,
            height,
            cell_size,
            cells: vec![Cell::default(); width * height],
        }
    }

    fn idx(&self, x: usize, y: usize) -> usize {
        y * self.width + x
    }

    /// Returns true if (x, y) is within grid bounds.
    ///
    /// # Parameters
    /// - `x` — `usize`.
    /// - `y` — `usize`.
    ///
    /// # Returns
    /// `bool`.
    pub fn in_bounds(&self, x: usize, y: usize) -> bool {
        x < self.width && y < self.height
    }

    /// Sets walkability for a cell (0-based coords).
    ///
    /// # Parameters
    /// - `x` — `usize`.
    /// - `y` — `usize`.
    /// - `walkable` — `bool`.
    pub fn set_walkable(&mut self, x: usize, y: usize, walkable: bool) {
        if self.in_bounds(x, y) {
            let idx = self.idx(x, y);
            self.cells[idx].walkable = walkable;
        }
    }

    /// Returns whether a cell is walkable (0-based coords).
    ///
    /// # Parameters
    /// - `x` — `usize`.
    /// - `y` — `usize`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_walkable(&self, x: usize, y: usize) -> bool {
        if self.in_bounds(x, y) {
            self.cells[self.idx(x, y)].walkable
        } else {
            false
        }
    }

    /// Sets cost multiplier for a cell (0-based coords).
    ///
    /// # Parameters
    /// - `x` — `usize`.
    /// - `y` — `usize`.
    /// - `cost` — `f32`.
    pub fn set_cost(&mut self, x: usize, y: usize, cost: f32) {
        if self.in_bounds(x, y) {
            let idx = self.idx(x, y);
            self.cells[idx].cost = cost;
        }
    }

    /// Gets cost multiplier for a cell (0-based coords).
    ///
    /// # Parameters
    /// - `x` — `usize`.
    /// - `y` — `usize`.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_cost(&self, x: usize, y: usize) -> f32 {
        if self.in_bounds(x, y) {
            self.cells[self.idx(x, y)].cost
        } else {
            f32::INFINITY
        }
    }

    /// A★ search from (sx,sy) to (gx,gy) in 0-based grid coords.
    ///
    /// # Parameters
    /// - `sx` — `usize`.
    /// - `sy` — `usize`.
    /// - `gx` — `usize`.
    /// - `gy` — `usize`.
    ///
    /// # Returns
    /// `Option<Vec<(f32, f32)>>`.
    /// Returns world-space waypoints or None if no path exists.
    pub fn find_path(&self, sx: usize, sy: usize, gx: usize, gy: usize) -> Option<Vec<(f32, f32)>> {
        if !self.in_bounds(sx, sy) || !self.in_bounds(gx, gy) {
            return None;
        }
        if !self.is_walkable(sx, sy) || !self.is_walkable(gx, gy) {
            return None;
        }

        let total = self.width * self.height;
        let mut g_cost = vec![f32::INFINITY; total];
        let mut came_from = vec![usize::MAX; total];
        let mut closed = vec![false; total];

        let start_idx = self.idx(sx, sy);
        let goal_idx = self.idx(gx, gy);
        g_cost[start_idx] = 0.0;

        let mut open = BinaryHeap::new();
        open.push(AStarNode {
            idx: start_idx,
            f_cost: self.heuristic(sx, sy, gx, gy),
        });

        while let Some(current) = open.pop() {
            if current.idx == goal_idx {
                return Some(self.reconstruct_path(&came_from, goal_idx));
            }
            if closed[current.idx] {
                continue;
            }
            closed[current.idx] = true;

            let cx = current.idx % self.width;
            let cy = current.idx / self.width;

            // 8-directional neighbors
            for &(dx, dy) in &[
                (-1i32, -1),
                (-1, 0),
                (-1, 1),
                (0, -1),
                (0, 1),
                (1, -1),
                (1, 0),
                (1, 1),
            ] {
                let nx = cx as i32 + dx;
                let ny = cy as i32 + dy;
                if nx < 0 || ny < 0 || nx >= self.width as i32 || ny >= self.height as i32 {
                    continue;
                }
                let nux = nx as usize;
                let nuy = ny as usize;
                if !self.is_walkable(nux, nuy) {
                    continue;
                }
                // Diagonal movement: check both adjacent cells are walkable to prevent corner cutting
                if dx != 0 && dy != 0 && (!self.is_walkable(cx, nuy) || !self.is_walkable(nux, cy))
                {
                    continue;
                }

                let nidx = self.idx(nux, nuy);
                if closed[nidx] {
                    continue;
                }

                let move_cost = if dx != 0 && dy != 0 { 1.414 } else { 1.0 };
                let tentative = g_cost[current.idx] + move_cost * self.cells[nidx].cost;

                if tentative < g_cost[nidx] {
                    g_cost[nidx] = tentative;
                    came_from[nidx] = current.idx;
                    open.push(AStarNode {
                        idx: nidx,
                        f_cost: tentative + self.heuristic(nux, nuy, gx, gy),
                    });
                }
            }
        }

        None // No path found
    }

    /// A★ + string-pulling (greedy LOS post-processing).
    ///
    /// # Parameters
    /// - `sx` — `usize`.
    /// - `sy` — `usize`.
    /// - `gx` — `usize`.
    /// - `gy` — `usize`.
    ///
    /// # Returns
    /// `Option<Vec<(f32, f32)>>`.
    pub fn find_path_smoothed(
        &self,
        sx: usize,
        sy: usize,
        gx: usize,
        gy: usize,
    ) -> Option<Vec<(f32, f32)>> {
        let path = self.find_path(sx, sy, gx, gy)?;
        if path.len() <= 2 {
            return Some(path);
        }
        // Greedy string-pulling
        let mut smoothed = vec![path[0]];
        let mut anchor = 0;
        let mut current = 1;
        while current < path.len() - 1 {
            let next = current + 1;
            if !self.has_line_of_sight(path[anchor], path[next]) {
                smoothed.push(path[current]);
                anchor = current;
            }
            current += 1;
        }
        smoothed.push(
            *path
                .last()
                .expect("path has >= 3 elements after length guard"),
        );
        Some(smoothed)
    }

    fn heuristic(&self, x1: usize, y1: usize, x2: usize, y2: usize) -> f32 {
        // Octile distance
        let dx = (x1 as f32 - x2 as f32).abs();
        let dy = (y1 as f32 - y2 as f32).abs();
        let min = dx.min(dy);
        let max = dx.max(dy);
        min * 1.414 + (max - min)
    }

    fn reconstruct_path(&self, came_from: &[usize], goal_idx: usize) -> Vec<(f32, f32)> {
        let mut path = Vec::new();
        let mut current = goal_idx;
        while current != usize::MAX {
            let x = current % self.width;
            let y = current / self.width;
            path.push(self.cell_center(x, y));
            current = came_from[current];
        }
        path.reverse();
        path
    }

    /// Returns the world-space center of cell (x, y).
    ///
    /// # Parameters
    /// - `x` — `usize`.
    /// - `y` — `usize`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn cell_center(&self, x: usize, y: usize) -> (f32, f32) {
        (
            (x as f32 + 0.5) * self.cell_size,
            (y as f32 + 0.5) * self.cell_size,
        )
    }

    fn has_line_of_sight(&self, from: (f32, f32), to: (f32, f32)) -> bool {
        // Bresenham-style line of sight check
        let fx = (from.0 / self.cell_size) as i32;
        let fy = (from.1 / self.cell_size) as i32;
        let tx = (to.0 / self.cell_size) as i32;
        let ty = (to.1 / self.cell_size) as i32;

        let mut x = fx;
        let mut y = fy;
        let dx = (tx - fx).abs();
        let dy = (ty - fy).abs();
        let sx = if fx < tx { 1 } else { -1 };
        let sy = if fy < ty { 1 } else { -1 };
        let mut err = dx - dy;

        loop {
            if x >= 0 && y >= 0 && (x as usize) < self.width && (y as usize) < self.height {
                if !self.cells[self.idx(x as usize, y as usize)].walkable {
                    return false;
                }
            } else {
                return false;
            }
            if x == tx && y == ty {
                break;
            }
            let e2 = 2 * err;
            if e2 > -dy {
                err -= dy;
                x += sx;
            }
            if e2 < dx {
                err += dx;
                y += sy;
            }
        }
        true
    }
}
