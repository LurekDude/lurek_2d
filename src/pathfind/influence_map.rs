//! Multi-layer spatial float grid for strategic area analysis and influence mapping.
//!
//! An [`InfluenceMap`] divides the game world into a uniform grid of cells, each
//! storing one float value per named layer. Layers allow different types of
//! influence to coexist (e.g., `"danger"`, `"resources"`, `"visibility"`) without
//! interfering with each other.
//!
//! ## Common Operations
//!
//! - **Stamping**: `stamp_influence()` adds circular influence with linear falloff
//!   at a world-space position (e.g., stamp enemy threat around each enemy unit).
//! - **Propagation**: `propagate()` applies 3×3 averaging diffusion to spread values
//!   across the grid, controlled by a `momentum` parameter.
//! - **Decay**: `decay()` multiplies all cells by a factor each frame, causing old
//!   influence to fade over time.
//! - **Querying**: `max_position()`, `min_position()`, and `query_rect()` let AI
//!   agents reason about which areas are most/least dangerous, resourceful, etc.
//! - **Blending**: `blend()` combines two layers with weighted addition into a
//!   destination layer (e.g., `combined = 0.7 * danger + 0.3 * distance`).
//!
//! ## Coordinate System
//!
//! The grid uses integer cell coordinates internally, but all public APIs accept
//! and return world-space floating-point coordinates. The `cell_size` parameter
//! controls the mapping between world space and grid space.

use std::collections::HashMap;

use crate::runtime::log_messages::{IF01, IF02, IF03};
use crate::log_msg;

/// A multi-layer spatial float grid for influence mapping and strategic reasoning.
///
/// The grid has fixed dimensions (`width × height` cells) with a configurable
/// `cell_size` in world units. Named float layers can be added dynamically.
/// Each layer is a flat `Vec<f32>` of length `width * height`, indexed as
/// `y * width + x`.
///
/// Designed for AI systems that need to reason about spatial properties:
/// threat levels, resource density, visibility, territorial control, etc.
/// Multiple layers can be queried and blended to produce composite scores
/// for decision-making.
///
/// # Fields
/// - `width` — `usize`.
/// - `height` — `usize`.
/// - `cell_size` — `f32`.
/// - `layers` — `HashMap<String, Vec<f32>>`.
pub struct InfluenceMap {
    /// Number of cells along the X axis.
    pub width: usize,
    /// Number of cells along the Y axis.
    pub height: usize,
    /// World-space size of each cell in both dimensions (cells are square).
    pub cell_size: f32,
    /// Named float layers. Each layer is a flat array of `width * height`
    /// floats, indexed as `y * width + x`.
    pub(crate) layers: HashMap<String, Vec<f32>>,
}

impl InfluenceMap {
    /// Creates a new empty influence map with the given dimensions.
    ///
    /// # Parameters
    /// - `width` — `usize`.
    /// - `height` — `usize`.
    /// - `cell_size` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(width: usize, height: usize, cell_size: f32) -> Self {
        log_msg!(debug, IF01, "{}x{} cell={}", width, height, cell_size);
        Self {
            width,
            height,
            cell_size,
            layers: HashMap::new(),
        }
    }

    /// Adds a new named layer initialized to zero.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    pub fn add_layer(&mut self, name: &str) {
        log_msg!(debug, IF02, "{}", name);
        self.layers
            .insert(name.to_string(), vec![0.0; self.width * self.height]);
    }

    /// Returns whether a layer exists. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_layer(&self, name: &str) -> bool {
        self.layers.contains_key(name)
    }

    /// Sets influence at a grid cell (0-based).
    ///
    /// # Parameters
    /// - `layer` — `&str`.
    /// - `x` — `usize`.
    /// - `y` — `usize`.
    /// - `value` — `f32`.
    pub fn set_influence(&mut self, layer: &str, x: usize, y: usize, value: f32) {
        if let Some(data) = self.layers.get_mut(layer) {
            if x < self.width && y < self.height {
                data[y * self.width + x] = value;
            }
        }
    }

    /// Gets influence at a grid cell (0-based). Returns 0 for out-of-bounds.
    ///
    /// # Parameters
    /// - `layer` — `&str`.
    /// - `x` — `usize`.
    /// - `y` — `usize`.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_influence(&self, layer: &str, x: usize, y: usize) -> f32 {
        if let Some(data) = self.layers.get(layer) {
            if x < self.width && y < self.height {
                return data[y * self.width + x];
            }
        }
        0.0
    }

    /// Number of cells along the X axis.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_width(&self) -> usize {
        self.width
    }

    /// Number of cells along the Y axis.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_height(&self) -> usize {
        self.height
    }

    /// World-space size of each cell.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_cell_size(&self) -> f32 {
        self.cell_size
    }

    /// Names of all registered layers (order not guaranteed).
    ///
    /// # Returns
    /// `Vec<&str>`.
    pub fn get_layer_names(&self) -> Vec<&str> {
        self.layers.keys().map(|s| s.as_str()).collect()
    }

    /// Stamps circular influence in world-space coordinates with linear falloff.
    ///
    /// # Parameters
    /// - `layer` — `&str`.
    /// - `wx` — `f32`.
    /// - `wy` — `f32`.
    /// - `radius` — `f32`.
    /// - `value` — `f32`.
    /// - `falloff` — `f32`.
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

    /// 3×3 averaging diffusion. newVal = old * momentum + avg * (1 - momentum).
    ///
    /// # Parameters
    /// - `layer` — `&str`.
    /// - `momentum` — `f32`.
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

    /// Multiplies every cell in a layer by the decay factor.
    ///
    /// # Parameters
    /// - `layer` — `&str`.
    /// - `factor` — `f32`.
    pub fn decay(&mut self, layer: &str, factor: f32) {
        if let Some(data) = self.layers.get_mut(layer) {
            for v in data.iter_mut() {
                *v *= factor;
            }
        }
    }

    /// Clears all cells in a layer to zero.
    ///
    /// # Parameters
    /// - `layer` — `&str`.
    pub fn clear_layer(&mut self, layer: &str) {
        if let Some(data) = self.layers.get_mut(layer) {
            log_msg!(debug, IF03, "{}", layer);
            for v in data.iter_mut() {
                *v = 0.0;
            }
        }
    }

    /// Clears all layers to zero. After this call the container is in the same state as immediately after construction.
    pub fn clear_all(&mut self) {
        for data in self.layers.values_mut() {
            for v in data.iter_mut() {
                *v = 0.0;
            }
        }
    }

    /// Returns the world-space position of the cell with the highest value.
    ///
    /// # Parameters
    /// - `layer` — `&str`.
    ///
    /// # Returns
    /// `(f32, f32)`.
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

    /// Returns the world-space position of the cell with the lowest value.
    ///
    /// # Parameters
    /// - `layer` — `&str`.
    ///
    /// # Returns
    /// `(f32, f32)`.
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

    /// Sums influence within a world-space rectangle.
    ///
    /// # Parameters
    /// - `layer` — `&str`.
    /// - `wx` — `f32`.
    /// - `wy` — `f32`.
    /// - `ww` — `f32`.
    /// - `wh` — `f32`.
    ///
    /// # Returns
    /// `f32`.
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

    /// Blends two layers into a destination: dest = wA * A + wB * B.
    ///
    /// # Parameters
    /// - `layer_a` — `&str`.
    /// - `weight_a` — `f32`.
    /// - `layer_b` — `&str`.
    /// - `weight_b` — `f32`.
    /// - `dest` — `&str`.
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

    /// Render the influence map to an image.
    ///
    /// Enemy influence is mapped to red and ally influence to blue. Cells with
    /// no influence use a dark background. The "enemy" and "ally" layers are
    /// read by convention; missing layers are treated as zero.
    ///
    /// # Parameters
    /// - `cell_size` — `u32`. Pixel size of each grid cell.
    ///
    /// # Returns
    /// `ImageData`.
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
                        img.set_pixel(x as u32 * cell_size + px, y as u32 * cell_size + py, r, g, b, 255);
                    }
                }
            }
        }
        img
    }

}
