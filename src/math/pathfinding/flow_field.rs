//! Flow field pathfinding for steering many units toward one or more targets.

use std::cell::RefCell;
use std::collections::VecDeque;
use std::rc::Rc;

use crate::math::pathfinding::nav_grid::NavGrid;

/// A pre-computed flow field that stores a direction vector and integrated cost
/// for every cell, guiding any unit toward one or more target cells.
pub struct FlowField {
    /// Grid width.
    width: u32,
    /// Grid height.
    height: u32,
    /// Normalised direction vector per cell (row-major).
    directions: Vec<(f32, f32)>,
    /// Integrated cost-to-target per cell (`f32::INFINITY` = unreachable).
    costs: Vec<f32>,
    /// Whether the field has been computed.
    calculated: bool,
    /// Target cell(s) used in the last computation.
    targets: Vec<(u32, u32)>,
    /// Shared navigation grid.
    grid: Rc<RefCell<NavGrid>>,
}

impl FlowField {
    /// Create an empty flow field backed by `grid`.
    pub fn new(grid: Rc<RefCell<NavGrid>>) -> Self {
        let g = grid.borrow();
        let w = g.get_width();
        let h = g.get_height();
        let size = (w * h) as usize;
        drop(g);

        Self {
            width: w,
            height: h,
            directions: vec![(0.0, 0.0); size],
            costs: vec![f32::INFINITY; size],
            calculated: false,
            targets: Vec::new(),
            grid,
        }
    }

    /// Compute the flow field toward a single target cell.
    pub fn calculate(&mut self, target_x: u32, target_y: u32, unit_size: u32) {
        self.calculate_multi(&[(target_x, target_y)], unit_size);
    }

    /// Compute the flow field toward multiple target cells simultaneously.
    pub fn calculate_multi(&mut self, targets: &[(u32, u32)], unit_size: u32) {
        let grid = self.grid.borrow();
        let w = grid.get_width();
        let h = grid.get_height();
        let size = (w * h) as usize;
        let us = unit_size.max(1);

        // Reset
        self.width = w;
        self.height = h;
        self.directions.clear();
        self.directions.resize(size, (0.0, 0.0));
        self.costs.clear();
        self.costs.resize(size, f32::INFINITY);
        self.targets = targets.to_vec();

        // BFS integration field
        let mut queue = VecDeque::new();
        for &(tx, ty) in targets {
            if tx < w && ty < h && grid.is_walkable(tx, ty, us) {
                let idx = (ty * w + tx) as usize;
                self.costs[idx] = 0.0;
                queue.push_back((tx, ty));
            }
        }

        while let Some((cx, cy)) = queue.pop_front() {
            let cur_cost = self.costs[(cy * w + cx) as usize];

            // Expand to all 8 neighbours
            for dy in -1i32..=1 {
                for dx in -1i32..=1 {
                    if dx == 0 && dy == 0 {
                        continue;
                    }
                    let nx = cx as i32 + dx;
                    let ny = cy as i32 + dy;
                    if nx < 0 || ny < 0 || nx >= w as i32 || ny >= h as i32 {
                        continue;
                    }
                    let (nxu, nyu) = (nx as u32, ny as u32);
                    if !grid.is_walkable(nxu, nyu, us) {
                        continue;
                    }

                    let is_diag = dx != 0 && dy != 0;
                    let step = if is_diag {
                        std::f32::consts::SQRT_2
                    } else {
                        1.0
                    } * grid.get_cost(nxu, nyu) as f32;

                    let new_cost = cur_cost + step;
                    let n_idx = (nyu * w + nxu) as usize;
                    if new_cost < self.costs[n_idx] {
                        self.costs[n_idx] = new_cost;
                        queue.push_back((nxu, nyu));
                    }
                }
            }
        }

        // Direction field: each cell points toward the neighbour with lowest cost
        for cy in 0..h {
            for cx in 0..w {
                let idx = (cy * w + cx) as usize;
                if self.costs[idx] == f32::INFINITY {
                    continue;
                }

                let mut best_cost = self.costs[idx];
                let mut best_dir = (0.0f32, 0.0f32);

                for dy in -1i32..=1 {
                    for dx in -1i32..=1 {
                        if dx == 0 && dy == 0 {
                            continue;
                        }
                        let nx = cx as i32 + dx;
                        let ny = cy as i32 + dy;
                        if nx < 0 || ny < 0 || nx >= w as i32 || ny >= h as i32 {
                            continue;
                        }
                        let n_idx = (ny as u32 * w + nx as u32) as usize;
                        if self.costs[n_idx] < best_cost {
                            best_cost = self.costs[n_idx];
                            best_dir = (dx as f32, dy as f32);
                        }
                    }
                }

                // Normalise
                let len = (best_dir.0 * best_dir.0 + best_dir.1 * best_dir.1).sqrt();
                if len > 0.0 {
                    self.directions[idx] = (best_dir.0 / len, best_dir.1 / len);
                }
            }
        }

        self.calculated = true;
    }

    /// Get the normalised direction vector at cell `(x, y)`.
    ///
    /// Returns `(0.0, 0.0)` for blocked, unreachable, or out-of-bounds cells.
    pub fn get_direction(&self, x: u32, y: u32) -> (f32, f32) {
        if x >= self.width || y >= self.height {
            return (0.0, 0.0);
        }
        self.directions[(y * self.width + x) as usize]
    }

    /// Get the direction as an angle in radians (via `atan2`).
    pub fn get_direction_angle(&self, x: u32, y: u32) -> f32 {
        let (dx, dy) = self.get_direction(x, y);
        dy.atan2(dx)
    }

    /// Get the integrated cost from cell `(x, y)` to the nearest target.
    ///
    /// Returns `f32::INFINITY` for unreachable or out-of-bounds cells.
    pub fn get_cost_to_target(&self, x: u32, y: u32) -> f32 {
        if x >= self.width || y >= self.height {
            return f32::INFINITY;
        }
        self.costs[(y * self.width + x) as usize]
    }

    /// Whether the flow field has been computed at least once.
    pub fn is_calculated(&self) -> bool {
        self.calculated
    }

    /// Target cells from the most recent computation.
    pub fn get_targets(&self) -> Vec<(u32, u32)> {
        self.targets.clone()
    }

    /// Convert a world-space position into a velocity vector.
    ///
    /// `tile_w` and `tile_h` are the pixel dimensions of one tile. The returned
    /// velocity is the flow direction scaled by `speed`.
    pub fn steer(
        &self,
        world_x: f32,
        world_y: f32,
        speed: f32,
        tile_w: f32,
        tile_h: f32,
    ) -> (f32, f32) {
        if tile_w <= 0.0 || tile_h <= 0.0 {
            return (0.0, 0.0);
        }
        let tx = (world_x / tile_w).floor() as i32;
        let ty = (world_y / tile_h).floor() as i32;
        if tx < 0 || ty < 0 || tx >= self.width as i32 || ty >= self.height as i32 {
            return (0.0, 0.0);
        }
        let (dx, dy) = self.get_direction(tx as u32, ty as u32);
        (dx * speed, dy * speed)
    }
}
