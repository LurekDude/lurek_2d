//! Dijkstra-based flow field for crowd pathfinding.
//! Moved from `ai/flowfield`; used by the Lua `lurek.ai.newFlowField` API.
//!
//! Note: this type operates on [`SimpleGrid`].  The higher-level
//! [`crate::pathfinding::FlowField`] operates on [`NavGrid`] instead.

use std::collections::VecDeque;

/// BFS flow field that stores normalized direction vectors toward a goal.
///
/// # Fields
/// - `width` — `usize`.
/// - `height` — `usize`.
/// - `goal` — `Option<(usize, usize)>`.
///
/// Built from a SimpleGrid. Each cell stores a direction vector and BFS distance.
pub struct FlowField {
    /// Grid width.
    pub width: usize,
    /// Grid height.
    pub height: usize,
    /// Normalized direction per cell toward goal; (0,0) if unreachable.
    directions: Vec<(f32, f32)>,
    /// BFS distance per cell; f32::INFINITY if unreachable.
    distances: Vec<f32>,
    /// Current goal cell (0-based), if set.
    pub goal: Option<(usize, usize)>,
    /// Walkability data copied from the SimpleGrid.
    walkable: Vec<bool>,
}

impl FlowField {
    /// Creates a new FlowField from a SimpleGrid's dimensions and walkability.
    ///
    /// # Parameters
    /// - `width` — `usize`.
    /// - `height` — `usize`.
    /// - `walkable` — `Vec<bool>`.
    ///
    /// # Returns
    /// `Self`.
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

    /// Sets the goal cell and triggers BFS recomputation.
    ///
    /// # Parameters
    /// - `gx` — `usize`.
    /// - `gy` — `usize`.
    pub fn set_goal(&mut self, gx: usize, gy: usize) {
        self.goal = Some((gx, gy));
        self.compute();
    }

    /// Recomputes the flow field from the current goal.
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

        // Compute direction vectors
        for y in 0..self.height {
            for x in 0..self.width {
                let idx = y * self.width + x;
                if self.distances[idx] == f32::INFINITY || (x == gx && y == gy) {
                    continue;
                }
                // Direction = toward neighbor with lowest distance
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

                // Normalize
                let mag = (best_dir.0 * best_dir.0 + best_dir.1 * best_dir.1).sqrt();
                if mag > 0.001 {
                    self.directions[idx] = (best_dir.0 / mag, best_dir.1 / mag);
                }
            }
        }
    }

    /// Gets the normalized direction toward the goal for a cell (0-based).
    ///
    /// # Parameters
    /// - `x` — `usize`.
    /// - `y` — `usize`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn get_direction(&self, x: usize, y: usize) -> (f32, f32) {
        if x < self.width && y < self.height {
            self.directions[y * self.width + x]
        } else {
            (0.0, 0.0)
        }
    }

    /// Gets the BFS distance for a cell (0-based). Returns f32::INFINITY if unreachable.
    ///
    /// # Parameters
    /// - `x` — `usize`.
    /// - `y` — `usize`.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_distance(&self, x: usize, y: usize) -> f32 {
        if x < self.width && y < self.height {
            self.distances[y * self.width + x]
        } else {
            f32::INFINITY
        }
    }
}
