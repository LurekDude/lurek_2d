//! Wolfenstein-style raycasting column batch renderer.
//!
//! Stores per-column wall data produced by a raycaster and provides
//! helpers for updating columns from raw ray data and querying depth.
//!
//! This module is part of Luna2D's `raycaster` subsystem and provides the implementation
//! details for column batch-related operations and data management.
//! Key types exported from this module: `ColumnData`, `ColumnBatch`.
//! Primary functions: `new()`, `set_column()`, `get_column()`, `update_from_ray_data()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use crate::math::Color;

/// Per-column rendering state produced by a raycaster.
///
/// # Fields
/// - `tex_u` — `f32`.
/// - `start` — `f32`.
/// - `end` — `f32`.
/// - `shade` — `f32`.
/// - `cell_val` — `u32`.
/// - `depth` — `f32`.
#[derive(Debug, Clone)]
pub struct ColumnData {
    /// Texture U coordinate in `[0.0, 1.0]`.
    pub tex_u: f32,
    /// Screen Y start of the wall slice.
    pub start: f32,
    /// Screen Y end of the wall slice.
    pub end: f32,
    /// Distance-based shade factor (`0.0`–`1.0`, `1.0` = brightest).
    pub shade: f32,
    /// Wall type identifier for multi-texture support.
    pub cell_val: u32,
    /// Ray distance used as a depth value.
    pub depth: f32,
}

impl Default for ColumnData {
    fn default() -> Self {
        Self {
            tex_u: 0.0,
            start: 0.0,
            end: 0.0,
            shade: 1.0,
            cell_val: 0,
            depth: 0.0,
        }
    }
}

/// Wolfenstein-style raycasting column batch renderer.
///
/// # Fields
/// - `columns` — `Vec<ColumnData>`.
/// - `screen_width` — `f32`.
/// - `screen_height` — `f32`.
/// - `floor_color` — `Color`.
/// - `ceiling_color` — `Color`.
///
/// Holds an array of column slices sized to the screen width together
/// with floor/ceiling colors. Columns can be set individually or
/// bulk-updated from raw ray data.
pub struct ColumnBatch {
    /// Per-column rendering data.
    pub columns: Vec<ColumnData>,
    /// Screen width in pixels.
    pub screen_width: f32,
    /// Screen height in pixels.
    pub screen_height: f32,
    /// Floor color drawn below wall columns.
    pub floor_color: Color,
    /// Ceiling color drawn above wall columns.
    pub ceiling_color: Color,
}

impl ColumnBatch {
    /// Create a new batch with `column_count` empty columns.
    ///
    /// # Parameters
    /// - `column_count` — `usize`.
    /// - `screen_width` — `f32`.
    /// - `screen_height` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(column_count: usize, screen_width: f32, screen_height: f32) -> Self {
        let mut columns = Vec::with_capacity(column_count);
        columns.resize_with(column_count, ColumnData::default);
        Self {
            columns,
            screen_width,
            screen_height,
            floor_color: Color::BLACK,
            ceiling_color: Color::BLACK,
        }
    }

    /// Set the data for a single 0-based column index.
    ///
    /// # Parameters
    /// - `col` — `usize`.
    /// - `tex_u` — `f32`.
    /// - `start` — `f32`.
    /// - `end` — `f32`.
    /// - `shade` — `f32`.
    /// - `cell_val` — `u32`.
    pub fn set_column(
        &mut self,
        col: usize,
        tex_u: f32,
        start: f32,
        end: f32,
        shade: f32,
        cell_val: u32,
    ) {
        if let Some(c) = self.columns.get_mut(col) {
            c.tex_u = tex_u;
            c.start = start;
            c.end = end;
            c.shade = shade;
            c.cell_val = cell_val;
            c.depth = 0.0;
        }
    }

    /// Reference to a single column by 0-based index.
    ///
    /// # Parameters
    /// - `col` — `usize`.
    ///
    /// # Returns
    /// `Option<&ColumnData>`.
    pub fn get_column(&self, col: usize) -> Option<&ColumnData> {
        self.columns.get(col)
    }

    /// Bulk-update columns from raw ray data. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `rays` — `&[f32]`.
    /// - `_fov` — `f32`.
    /// - `max_shade_dist` — `Option<f32>`.
    ///
    /// `rays` is a flat array with 5 `f32` values per ray:
    /// `[distance, cellValue, side, texU, hit]`.
    /// `fov` is unused but reserved for future projection math.
    /// `max_shade_dist` controls distance fog; `None` disables shading.
    pub fn update_from_ray_data(&mut self, rays: &[f32], _fov: f32, max_shade_dist: Option<f32>) {
        let floats_per_ray = 5;
        let ray_count = rays.len() / floats_per_ray;

        for i in 0..ray_count.min(self.columns.len()) {
            let base = i * floats_per_ray;
            let distance = rays[base];
            let cell_value = rays[base + 1] as u32;
            // side = rays[base + 2] — reserved
            let tex_u = rays[base + 3];
            // hit = rays[base + 4] — reserved

            let wall_height = if distance > 0.0 {
                self.screen_height / distance
            } else {
                self.screen_height
            };
            let start = (self.screen_height - wall_height) / 2.0;
            let end = start + wall_height;
            let shade = match max_shade_dist {
                Some(max) if max > 0.0 => (1.0 - distance / max).max(0.0),
                _ => 1.0,
            };

            if let Some(c) = self.columns.get_mut(i) {
                c.tex_u = tex_u;
                c.start = start;
                c.end = end;
                c.shade = shade;
                c.cell_val = cell_value;
                c.depth = distance;
            }
        }
    }

    /// Depth value at a 0-based column index. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `col` — `usize`.
    ///
    /// # Returns
    /// `Option<f32>`.
    pub fn get_depth_at(&self, col: usize) -> Option<f32> {
        self.columns.get(col).map(|c| c.depth)
    }

    /// Depth buffer as a flat vector (one entry per column).
    ///
    /// # Returns
    /// `Vec<f32>`.
    pub fn get_depth_buffer(&self) -> Vec<f32> {
        self.columns.iter().map(|c| c.depth).collect()
    }

    /// Set the floor color. Replaces the current floor color value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `color` — `Color`.
    pub fn set_floor_color(&mut self, color: Color) {
        self.floor_color = color;
    }

    /// Set the ceiling color. Replaces the current ceiling color value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `color` — `Color`.
    pub fn set_ceiling_color(&mut self, color: Color) {
        self.ceiling_color = color;
    }

    /// Number of columns. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_column_count(&self) -> usize {
        self.columns.len()
    }

    /// Screen width in pixels. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_screen_width(&self) -> f32 {
        self.screen_width
    }

    /// Screen height in pixels. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_screen_height(&self) -> f32 {
        self.screen_height
    }
}
