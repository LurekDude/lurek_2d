//! Flow field pathfinding for steering many units toward one or more targets.
//!
//! This module is part of Lurek2D's `pathfinding` subsystem and provides the implementation
//! details for flow field-related operations and data management.
//! Key types exported from this module: `FlowField`.
//! Primary functions: `new()`, `calculate()`, `calculate_multi()`, `get_direction()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use std::cell::RefCell;
use std::collections::VecDeque;
use std::rc::Rc;

use crate::runtime::log_messages::{FF01, FF02, FF03};
use crate::log_msg;
use crate::pathfind::nav_grid::NavGrid;

/// A pre-computed flow field that stores a direction vector and integrated cost
/// for every cell, guiding any unit toward one or more target cells.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `directions` — `Vec<(f32`.
/// - `f32` — `:INFINITY` = unreachable).`.
/// - `costs` — `Vec<f32>`.
/// - `calculated` — `bool`.
/// - `targets` — `Vec<(u32`.
/// - `grid` — `Rc<RefCell<NavGrid>>`.
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
    ///
    /// # Parameters
    /// - `grid` — `Rc<RefCell<NavGrid>>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(grid: Rc<RefCell<NavGrid>>) -> Self {
        let g = grid.borrow();
        let w = g.get_width();
        let h = g.get_height();
        let size = (w * h) as usize;
        drop(g);

        log_msg!(debug, FF01);
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
    ///
    /// # Parameters
    /// - `target_x` — `u32`.
    /// - `target_y` — `u32`.
    /// - `unit_size` — `u32`.
    pub fn calculate(&mut self, target_x: u32, target_y: u32, unit_size: u32) {
        self.calculate_multi(&[(target_x, target_y)], unit_size);
    }

    /// Compute the flow field toward multiple target cells simultaneously.
    ///
    /// # Parameters
    /// - `targets` — `&[(u32, u32)]`.
    /// - `unit_size` — `u32`.
    pub fn calculate_multi(&mut self, targets: &[(u32, u32)], unit_size: u32) {
        let grid = self.grid.borrow();
        let w = grid.get_width();
        let h = grid.get_height();
        let size = (w * h) as usize;
        let us = unit_size.max(1);

        log_msg!(debug, FF03);
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

        log_msg!(debug, FF02);
        self.calculated = true;
    }

    /// Get the normalised direction vector at cell `(x, y)`.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    ///
    /// Returns `(0.0, 0.0)` for blocked, unreachable, or out-of-bounds cells.
    pub fn get_direction(&self, x: u32, y: u32) -> (f32, f32) {
        if x >= self.width || y >= self.height {
            return (0.0, 0.0);
        }
        self.directions[(y * self.width + x) as usize]
    }

    /// Get the direction as an angle in radians (via `atan2`).
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_direction_angle(&self, x: u32, y: u32) -> f32 {
        let (dx, dy) = self.get_direction(x, y);
        dy.atan2(dx)
    }

    /// Get the integrated cost from cell `(x, y)` to the nearest target.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `f32`.
    ///
    /// Returns `f32::INFINITY` for unreachable or out-of-bounds cells.
    pub fn get_cost_to_target(&self, x: u32, y: u32) -> f32 {
        if x >= self.width || y >= self.height {
            return f32::INFINITY;
        }
        self.costs[(y * self.width + x) as usize]
    }

    /// Whether the flow field has been computed at least once.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_calculated(&self) -> bool {
        self.calculated
    }

    /// Target cells from the most recent computation.
    ///
    /// # Returns
    /// `Vec<(u32, u32)>`.
    pub fn get_targets(&self) -> Vec<(u32, u32)> {
        self.targets.clone()
    }

    /// Convert a world-space position into a velocity vector.
    ///
    /// # Parameters
    /// - `world_x` — `f32`.
    /// - `world_y` — `f32`.
    /// - `speed` — `f32`.
    /// - `tile_w` — `f32`.
    /// - `tile_h` — `f32`.
    ///
    /// # Returns
    /// `(f32, f32)`.
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

    /// Render the flow field to an image with direction arrows.
    ///
    /// Blocked cells are drawn dark red, non-blocked cells are dark blue-grey.
    /// Each non-blocked cell has a short direction arrow drawn from center.
    /// The first target cell is marked with a red circle.
    ///
    /// # Parameters
    /// - `cell_size` — `u32`. Pixel size of each grid cell.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, cell_size: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(self.width * cell_size, self.height * cell_size);
        img.fill(40, 45, 55, 255);
        // Draw blocked cells
        {
            let g = self.grid.borrow();
            for y in 0..self.height {
                for x in 0..self.width {
                    if g.is_blocked(x, y) {
                        for py in 0..cell_size {
                            for px in 0..cell_size {
                                img.set_pixel(x * cell_size + px, y * cell_size + py, 90, 40, 40, 255);
                            }
                        }
                    }
                }
            }
        }
        // Draw flow arrows
        for y in 0..self.height {
            for x in 0..self.width {
                if !self.grid.borrow().is_blocked(x, y) {
                    let (dx, dy) = self.get_direction(x, y);
                    if dx.abs() > 0.01 || dy.abs() > 0.01 {
                        let cx = (x * cell_size + cell_size / 2) as i32;
                        let cy = (y * cell_size + cell_size / 2) as i32;
                        let ex = cx + (dx * 6.0) as i32;
                        let ey = cy + (dy * 6.0) as i32;
                        img.draw_line(cx, cy, ex, ey, 100, 200, 255, 200);
                    }
                }
            }
        }
        // Mark first target
        if let Some(&(tx, ty)) = self.targets.first() {
            img.draw_circle(
                (tx * cell_size + cell_size / 2) as i32,
                (ty * cell_size + cell_size / 2) as i32,
                5, 255, 80, 80, 255,
            );
        }
        img
    }

}
