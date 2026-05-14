
use crate::log_msg;
use std::cell::RefCell;
use std::collections::VecDeque;
use std::rc::Rc;
/// Grid-resident flow field pointing each reachable cell toward one or more goal cells.
pub struct FlowField {
    /// Width of the backing grid in cells.
    width: u32,
    /// Height of the backing grid in cells.
    height: u32,
    /// Normalised move direction per cell, pointing toward the nearest goal.
    directions: Vec<(f32, f32)>,
    /// Dijkstra distance from each cell to the nearest goal.
    costs: Vec<f32>,
    /// True after `calculate` or `calculate_multi` has run at least once.
    calculated: bool,
    /// Seed cells used for the last computation.
    targets: Vec<(u32, u32)>,
    /// Shared grid reference used for walkability and move-cost queries.
    grid: Rc<RefCell<NavGrid>>,
}
/// Construction and query methods for `FlowField`.
impl FlowField {
    /// Create an uninitialised flow field linked to `grid`; call `calculate` before querying.
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
    /// Seed the field with a single target cell and recompute.
    pub fn calculate(&mut self, target_x: u32, target_y: u32, unit_size: u32) {
        self.calculate_multi(&[(target_x, target_y)], unit_size);
    }
    /// Recompute the field seeded from all cells in `targets`.
    pub fn calculate_multi(&mut self, targets: &[(u32, u32)], unit_size: u32) {
        let grid = self.grid.borrow();
        let w = grid.get_width();
        let h = grid.get_height();
        let size = (w * h) as usize;
        let us = unit_size.max(1);
        log_msg!(debug, FF03);
        self.width = w;
        self.height = h;
        self.directions.clear();
        self.directions.resize(size, (0.0, 0.0));
        self.costs.clear();
        self.costs.resize(size, f32::INFINITY);
        self.targets = targets.to_vec();
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
                let len = (best_dir.0 * best_dir.0 + best_dir.1 * best_dir.1).sqrt();
                if len > 0.0 {
                    self.directions[idx] = (best_dir.0 / len, best_dir.1 / len);
                }
            }
        }
        log_msg!(debug, FF02);
        self.calculated = true;
    }
    /// Return the normalised flow direction at `(x, y)`; returns `(0,0)` when out of bounds.
    pub fn get_direction(&self, x: u32, y: u32) -> (f32, f32) {
        if x >= self.width || y >= self.height {
            return (0.0, 0.0);
        }
        self.directions[(y * self.width + x) as usize]
    }
    /// Return the flow direction at `(x, y)` as an angle in radians relative to the +x axis.
    pub fn get_direction_angle(&self, x: u32, y: u32) -> f32 {
        let (dx, dy) = self.get_direction(x, y);
        dy.atan2(dx)
    }
    /// Return the Dijkstra cost from `(x, y)` to the nearest target; `INFINITY` when unreachable.
    pub fn get_cost_to_target(&self, x: u32, y: u32) -> f32 {
        if x >= self.width || y >= self.height {
            return f32::INFINITY;
        }
        self.costs[(y * self.width + x) as usize]
    }
    /// Return true if `calculate` or `calculate_multi` has been called at least once.
    pub fn is_calculated(&self) -> bool {
        self.calculated
    }
    /// Return a clone of the target cells used for the last computation.
    pub fn get_targets(&self) -> Vec<(u32, u32)> {
        self.targets.clone()
    }
    /// Return the grid width.
    pub fn get_width(&self) -> u32 {
        self.width
    }
    /// Return the grid height.
    pub fn get_height(&self) -> u32 {
        self.height
    }
    /// Convert world position to tile, sample direction, and return a velocity scaled by `speed`.
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
    /// Render the flow field to an `ImageData` with `cell_size` pixels per tile for debugging.
    pub fn draw_to_image(&self, cell_size: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(self.width * cell_size, self.height * cell_size);
        img.fill(40, 45, 55, 255);
        {
            let g = self.grid.borrow();
            for y in 0..self.height {
                for x in 0..self.width {
                    if g.is_blocked(x, y) {
                        for py in 0..cell_size {
                            for px in 0..cell_size {
                                img.set_pixel(
                                    x * cell_size + px,
                                    y * cell_size + py,
                                    90,
                                    40,
                                    40,
                                    255,
                                );
                            }
                        }
                    }
                }
            }
        }
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
        if let Some(&(tx, ty)) = self.targets.first() {
            img.draw_circle(
                (tx * cell_size + cell_size / 2) as i32,
                (ty * cell_size + cell_size / 2) as i32,
                5,
                255,
                80,
                80,
                255,
            );
        }
        img
    }
}
