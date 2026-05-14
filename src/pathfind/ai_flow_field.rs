//! BFS-based flow field for AI crowd movement on a flat walkability grid.
//! Does not own unit steering or pathfinding A\*; consumed by `src/ai/` and
//! `src/lua_api/pathfind_api.rs`. Re-exported from `pathfind` as `SimpleFlowField`.

use std::collections::VecDeque;

/// Precomputed directional flow field driving units toward a single goal cell.
pub struct FlowField {
    /// Grid width in cells.
    pub width: usize,
    /// Grid height in cells.
    pub height: usize,
    /// Normalised move direction per cell, pointing toward the goal.
    directions: Vec<(f32, f32)>,
    /// Dijkstra distance from each cell to the goal.
    distances: Vec<f32>,
    /// Active goal cell; `None` until `set_goal` is called.
    pub goal: Option<(usize, usize)>,
    /// Flat walkability mask; `true` means the cell is passable.
    walkable: Vec<bool>,
}

/// Inherent methods for constructing and querying the flow field.
impl FlowField {
    /// Create an uninitialised field of size `width × height` using the supplied walkability mask.
    pub fn new(width: usize, height: usize, walkable: Vec<bool>) -> Self {
        let total = width * height;
        Self {
            width,
            height,
            directions: vec![(0.0, 0.0); total],
            distances: vec![f32::INFINITY; total],
            goal: None,
            walkable,
        }
    }
    /// Set the goal cell to `(gx, gy)` and recompute the full flow field.
    pub fn set_goal(&mut self, gx: usize, gy: usize) {
        self.goal = Some((gx, gy));
        self.compute();
    }
    /// Run a BFS from the current goal cell to fill `distances` then derive `directions`.
    pub fn compute(&mut self) {
        let total = self.width * self.height;
        self.distances = vec![f32::INFINITY; total];
        self.directions = vec![(0.0, 0.0); total];
        let (gx, gy) = match self.goal {
            Some(g) => g,
            None => return,
        };
        if gx >= self.width || gy >= self.height {
            return;
        }
        let goal_idx = gy * self.width + gx;
        if !self.walkable[goal_idx] {
            return;
        }
        self.distances[goal_idx] = 0.0;
        let mut queue = VecDeque::new();
        queue.push_back((gx, gy));
        while let Some((cx, cy)) = queue.pop_front() {
            let curr_dist = self.distances[cy * self.width + cx];
            for &(dx, dy) in &[
                (-1i32, 0),
                (1, 0),
                (0, -1),
                (0, 1),
                (-1, -1),
                (-1, 1),
                (1, -1),
                (1, 1),
            ] {
                let nx = cx as i32 + dx;
                let ny = cy as i32 + dy;
                if nx < 0 || ny < 0 || nx >= self.width as i32 || ny >= self.height as i32 {
                    continue;
                }
                let nux = nx as usize;
                let nuy = ny as usize;
                let nidx = nuy * self.width + nux;
                if !self.walkable[nidx] {
                    continue;
                }
                let step = if dx != 0 && dy != 0 { 1.414 } else { 1.0 };
                let new_dist = curr_dist + step;
                if new_dist < self.distances[nidx] {
                    self.distances[nidx] = new_dist;
                    queue.push_back((nux, nuy));
                }
            }
        }
        for y in 0..self.height {
            for x in 0..self.width {
                let idx = y * self.width + x;
                if self.distances[idx] == f32::INFINITY || (x == gx && y == gy) {
                    continue;
                }
                let mut best_dir = (0.0f32, 0.0f32);
                let mut best_dist = self.distances[idx];
                for &(dx, dy) in &[
                    (-1i32, 0),
                    (1, 0),
                    (0, -1),
                    (0, 1),
                    (-1, -1),
                    (-1, 1),
                    (1, -1),
                    (1, 1),
                ] {
                    let nx = x as i32 + dx;
                    let ny = y as i32 + dy;
                    if nx < 0 || ny < 0 || nx >= self.width as i32 || ny >= self.height as i32 {
                        continue;
                    }
                    let nidx = ny as usize * self.width + nx as usize;
                    if self.distances[nidx] < best_dist {
                        best_dist = self.distances[nidx];
                        best_dir = (dx as f32, dy as f32);
                    }
                }
                let mag = (best_dir.0 * best_dir.0 + best_dir.1 * best_dir.1).sqrt();
                if mag > 0.001 {
                    self.directions[idx] = (best_dir.0 / mag, best_dir.1 / mag);
                }
            }
        }
    }
    /// Return the normalised direction at `(x, y)`; returns `(0,0)` when out of bounds.
    pub fn get_direction(&self, x: usize, y: usize) -> (f32, f32) {
        if x < self.width && y < self.height {
            self.directions[y * self.width + x]
        } else {
            (0.0, 0.0)
        }
    }
    /// Return the BFS distance at `(x, y)`; returns `INFINITY` when out of bounds or unreachable.
    pub fn get_distance(&self, x: usize, y: usize) -> f32 {
        if x < self.width && y < self.height {
            self.distances[y * self.width + x]
        } else {
            f32::INFINITY
        }
    }
}
