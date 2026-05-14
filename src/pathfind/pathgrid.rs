//! World-space 8-directional A\* grid with per-cell cost, path smoothing, and line-of-sight.
//! Returns world-space `(f32, f32)` waypoints rather than cell coordinates.
//! Does not own Lua bindings; consumed by `src/lua_api/pathfind_api.rs`.

use std::cmp::Ordering;
use std::collections::BinaryHeap;
/// Walkability and movement cost for a single grid cell.
#[derive(Debug, Clone)]
pub struct Cell {
    /// Whether agents may enter this cell.
    pub walkable: bool,
    /// Movement cost multiplier; `1.0` is standard.
    pub cost: f32,
}
/// Default walkable cell with cost `1.0`.
impl Default for Cell {
    fn default() -> Self {
        Self {
            walkable: true,
            cost: 1.0,
        }
    }
}
/// Internal A\* heap node for `PathGrid`.
#[derive(Debug, Clone)]
struct AStarNode {
    /// Flat cell index.
    idx: usize,
    /// f-score = g + h.
    f_cost: f32,
}
/// Equality by f-score.
impl PartialEq for AStarNode {
    fn eq(&self, other: &Self) -> bool {
        self.f_cost == other.f_cost
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
        other
            .f_cost
            .partial_cmp(&self.f_cost)
            .unwrap_or(Ordering::Equal)
    }
}
/// World-space pathfinding grid: cells have world-space size `cell_size`; paths are in world coordinates.
pub struct PathGrid {
    /// Grid width in cells.
    pub width: usize,
    /// Grid height in cells.
    pub height: usize,
    /// World-space dimension of each cell.
    pub cell_size: f32,
    /// Per-cell data, row-major.
    cells: Vec<Cell>,
}
/// Construction and pathfinding methods for `PathGrid`.
impl PathGrid {
    /// Create a fully walkable `width × height` grid with given world-space `cell_size`.
    pub fn new(width: usize, height: usize, cell_size: f32) -> Self {
        Self {
            width,
            height,
            cell_size,
            cells: vec![Cell::default(); width * height],
        }
    }
    /// Return the flat index for cell `(x, y)`.
    fn idx(&self, x: usize, y: usize) -> usize {
        y * self.width + x
    }
    /// Return true when `(x, y)` is within the grid dimensions.
    pub fn in_bounds(&self, x: usize, y: usize) -> bool {
        x < self.width && y < self.height
    }
    /// Set walkability of cell `(x, y)`.
    pub fn set_walkable(&mut self, x: usize, y: usize, walkable: bool) {
        if self.in_bounds(x, y) {
            let idx = self.idx(x, y);
            self.cells[idx].walkable = walkable;
        }
    }
    /// Return true when `(x, y)` is in-bounds and walkable.
    pub fn is_walkable(&self, x: usize, y: usize) -> bool {
        if self.in_bounds(x, y) {
            self.cells[self.idx(x, y)].walkable
        } else {
            false
        }
    }
    /// Set movement cost of cell `(x, y)`.
    pub fn set_cost(&mut self, x: usize, y: usize, cost: f32) {
        if self.in_bounds(x, y) {
            let idx = self.idx(x, y);
            self.cells[idx].cost = cost;
        }
    }
    /// Return movement cost of cell `(x, y)`, or `f32::INFINITY` when out-of-bounds.
    pub fn get_cost(&self, x: usize, y: usize) -> f32 {
        if self.in_bounds(x, y) {
            self.cells[self.idx(x, y)].cost
        } else {
            f32::INFINITY
        }
    }
    /// Run 8-directional A\* from cell `(sx, sy)` to `(gx, gy)`; return world-space waypoints or `None`.
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
        None
    }
    /// Run A\* then apply string-pull smoothing to reduce waypoint count.
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
    /// Octile distance heuristic.
    fn heuristic(&self, x1: usize, y1: usize, x2: usize, y2: usize) -> f32 {
        let dx = (x1 as f32 - x2 as f32).abs();
        let dy = (y1 as f32 - y2 as f32).abs();
        let min = dx.min(dy);
        let max = dx.max(dy);
        min * 1.414 + (max - min)
    }
    /// Walk `came_from` from `goal_idx` to start and return the world-space path in forward order.
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
    /// Return the world-space centre of cell `(x, y)`.
    pub fn cell_center(&self, x: usize, y: usize) -> (f32, f32) {
        (
            (x as f32 + 0.5) * self.cell_size,
            (y as f32 + 0.5) * self.cell_size,
        )
    }
    /// Return true when the Bresenham line from `from` to `to` passes only through walkable cells.
    fn has_line_of_sight(&self, from: (f32, f32), to: (f32, f32)) -> bool {
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
