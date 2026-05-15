//! - Grid-based influence map with named floating-point layers over a uniform cell grid.
//! - Stamp radial influence with distance falloff, propagate via neighbourhood smoothing, and decay over time.
//! - Query aggregated influence inside world-space rectangles or locate extrema positions.
//! - Blend multiple layers with weighted combination into a destination layer.
//! - Debug visualisation rendering layers into an RGBA image for inspection.

use crate::runtime::log_messages::{IF01,IF02,IF03};

use crate::log_msg;
use std::collections::HashMap;
/// Grid-based influence map supporting multiple named layers.
pub struct InfluenceMap {
    /// Width in cells.
    pub width: usize,
    /// Height in cells.
    pub height: usize,
    /// World-space size of one cell.
    pub cell_size: f32,
    /// Named layers, each a flat grid of `width * height` influence values.
    pub(crate) layers: HashMap<String, Vec<f32>>,
}
/// Construction and query methods for `InfluenceMap`.
impl InfluenceMap {
    /// Create an empty influence map with the given grid dimensions and world-space `cell_size`.
    pub fn new(width: usize, height: usize, cell_size: f32) -> Self {
        log_msg!(debug, IF01, "{}x{} cell={}", width, height, cell_size);
        Self {
            width,
            height,
            cell_size,
            layers: HashMap::new(),
        }
    }
    /// Register a new zero-filled layer named `name`; replaces any existing layer with that name.
    pub fn add_layer(&mut self, name: &str) {
        log_msg!(debug, IF02, "{}", name);
        self.layers
            .insert(name.to_string(), vec![0.0; self.width * self.height]);
    }
    /// Return true when a layer named `name` exists.
    pub fn has_layer(&self, name: &str) -> bool {
        self.layers.contains_key(name)
    }
    /// Set the influence value at cell `(x, y)` on `layer`; no-op if out-of-bounds.
    pub fn set_influence(&mut self, layer: &str, x: usize, y: usize, value: f32) {
        if let Some(data) = self.layers.get_mut(layer) {
            if x < self.width && y < self.height {
                data[y * self.width + x] = value;
            }
        }
    }
    /// Return the influence value at `(x, y)` on `layer`, or `0.0` if out-of-bounds or layer absent.
    pub fn get_influence(&self, layer: &str, x: usize, y: usize) -> f32 {
        if let Some(data) = self.layers.get(layer) {
            if x < self.width && y < self.height {
                return data[y * self.width + x];
            }
        }
        0.0
    }
    /// Return the grid width in cells.
    pub fn get_width(&self) -> usize {
        self.width
    }
    /// Return the grid height in cells.
    pub fn get_height(&self) -> usize {
        self.height
    }
    /// Return the world-space cell size.
    pub fn get_cell_size(&self) -> f32 {
        self.cell_size
    }
    /// Return the names of all registered layers.
    pub fn get_layer_names(&self) -> Vec<&str> {
        self.layers.keys().map(|s| s.as_str()).collect()
    }
    /// Add `value` (scaled by falloff and distance) to all cells within `radius` of world point `(wx, wy)` on `layer`.
    pub fn stamp_influence(
        &mut self,
        layer: &str,
        wx: f32,
        wy: f32,
        radius: f32,
        value: f32,
        falloff: f32,
    ) {
        let data = match self.layers.get_mut(layer) {
            Some(d) => d,
            None => return,
        };
        let cx = (wx / self.cell_size) as i32;
        let cy = (wy / self.cell_size) as i32;
        let cell_radius = (radius / self.cell_size).ceil() as i32;
        for dy in -cell_radius..=cell_radius {
            for dx in -cell_radius..=cell_radius {
                let nx = cx + dx;
                let ny = cy + dy;
                if nx < 0 || ny < 0 || nx >= self.width as i32 || ny >= self.height as i32 {
                    continue;
                }
                let px = (nx as f32 + 0.5) * self.cell_size;
                let py = (ny as f32 + 0.5) * self.cell_size;
                let dist = ((px - wx) * (px - wx) + (py - wy) * (py - wy)).sqrt();
                if dist <= radius {
                    let factor = 1.0 - (dist / radius) * falloff;
                    let idx = ny as usize * self.width + nx as usize;
                    data[idx] += value * factor.max(0.0);
                }
            }
        }
    }
    /// Smooth `layer` by blending each cell with its 3×3 neighbourhood average, weighted by `momentum`.
    pub fn propagate(&mut self, layer: &str, momentum: f32) {
        let data = match self.layers.get(layer) {
            Some(d) => d.clone(),
            None => return,
        };
        let out = match self.layers.get_mut(layer) {
            Some(d) => d,
            None => return,
        };
        for y in 0..self.height {
            for x in 0..self.width {
                let mut sum = 0.0f32;
                let mut count = 0u32;
                for dy in -1i32..=1 {
                    for dx in -1i32..=1 {
                        let nx = x as i32 + dx;
                        let ny = y as i32 + dy;
                        if nx >= 0
                            && ny >= 0
                            && (nx as usize) < self.width
                            && (ny as usize) < self.height
                        {
                            sum += data[ny as usize * self.width + nx as usize];
                            count += 1;
                        }
                    }
                }
                let avg = sum / count as f32;
                let idx = y * self.width + x;
                out[idx] = data[idx] * momentum + avg * (1.0 - momentum);
            }
        }
    }
    /// Multiply every cell in `layer` by `factor`.
    pub fn decay(&mut self, layer: &str, factor: f32) {
        if let Some(data) = self.layers.get_mut(layer) {
            for v in data.iter_mut() {
                *v *= factor;
            }
        }
    }
    /// Zero all cells in `layer`. This function is part of the public API.
    pub fn clear_layer(&mut self, layer: &str) {
        if let Some(data) = self.layers.get_mut(layer) {
            log_msg!(debug, IF03, "{}", layer);
            for v in data.iter_mut() {
                *v = 0.0;
            }
        }
    }
    /// Zero all cells in every layer.
    pub fn clear_all(&mut self) {
        for data in self.layers.values_mut() {
            for v in data.iter_mut() {
                *v = 0.0;
            }
        }
    }
    /// Return the world-space position of the highest-value cell in `layer`, or `(0.0, 0.0)` if absent.
    pub fn max_position(&self, layer: &str) -> (f32, f32) {
        if let Some(data) = self.layers.get(layer) {
            let mut best_idx = 0;
            let mut best_val = f32::NEG_INFINITY;
            for (i, &v) in data.iter().enumerate() {
                if v > best_val {
                    best_val = v;
                    best_idx = i;
                }
            }
            let x = best_idx % self.width;
            let y = best_idx / self.width;
            (
                (x as f32 + 0.5) * self.cell_size,
                (y as f32 + 0.5) * self.cell_size,
            )
        } else {
            (0.0, 0.0)
        }
    }
    /// Return the world-space position of the lowest-value cell in `layer`, or `(0.0, 0.0)` if absent.
    pub fn min_position(&self, layer: &str) -> (f32, f32) {
        if let Some(data) = self.layers.get(layer) {
            let mut best_idx = 0;
            let mut best_val = f32::INFINITY;
            for (i, &v) in data.iter().enumerate() {
                if v < best_val {
                    best_val = v;
                    best_idx = i;
                }
            }
            let x = best_idx % self.width;
            let y = best_idx / self.width;
            (
                (x as f32 + 0.5) * self.cell_size,
                (y as f32 + 0.5) * self.cell_size,
            )
        } else {
            (0.0, 0.0)
        }
    }
    /// Return the sum of all cell values in `layer` that fall within world-space rectangle `(wx, wy, ww, wh)`.
    pub fn query_rect(&self, layer: &str, wx: f32, wy: f32, ww: f32, wh: f32) -> f32 {
        let data = match self.layers.get(layer) {
            Some(d) => d,
            None => return 0.0,
        };
        let min_x = ((wx / self.cell_size).floor() as i32).max(0) as usize;
        let min_y = ((wy / self.cell_size).floor() as i32).max(0) as usize;
        let max_x = (((wx + ww) / self.cell_size).ceil() as usize).min(self.width);
        let max_y = (((wy + wh) / self.cell_size).ceil() as usize).min(self.height);
        let mut sum = 0.0f32;
        for y in min_y..max_y {
            for x in min_x..max_x {
                sum += data[y * self.width + x];
            }
        }
        sum
    }
    /// Write `weight_a * layer_a + weight_b * layer_b` into `dest`; all three layers must exist.
    pub fn blend(
        &mut self,
        layer_a: &str,
        weight_a: f32,
        layer_b: &str,
        weight_b: f32,
        dest: &str,
    ) {
        let a = match self.layers.get(layer_a) {
            Some(d) => d.clone(),
            None => return,
        };
        let b = match self.layers.get(layer_b) {
            Some(d) => d.clone(),
            None => return,
        };
        let out = match self.layers.get_mut(dest) {
            Some(d) => d,
            None => return,
        };
        for i in 0..out.len() {
            out[i] = weight_a * a[i] + weight_b * b[i];
        }
    }
    /// Render the "enemy" and "ally" layers into a color `ImageData` at `cell_size` pixels per cell.
    pub fn draw_to_image(&self, cell_size: u32) -> crate::image::ImageData {
        let w = self.width as u32;
        let h = self.height as u32;
        let mut img = crate::image::ImageData::new(w * cell_size, h * cell_size);
        img.fill(30, 30, 35, 255);
        for y in 0..self.height {
            for x in 0..self.width {
                let enemy = self.get_influence("enemy", x, y);
                let ally = self.get_influence("ally", x, y);
                let r = (enemy.min(1.0) * 200.0) as u8 + 30;
                let g = 30u8;
                let b = (ally.min(1.0) * 200.0) as u8 + 30;
                for py in 0..cell_size {
                    for px in 0..cell_size {
                        img.set_pixel(
                            x as u32 * cell_size + px,
                            y as u32 * cell_size + py,
                            r,
                            g,
                            b,
                            255,
                        );
                    }
                }
            }
        }
        img
    }
}
