//! Per-column wall data for the legacy column-based raycaster path. Stores projected
//! wall-slice coordinates, texture U offset, shade, and depth for each screen column.
//! `ColumnBatch` is populated from raw ray arrays and read by the CPU-side draw path.
//! Does not own DDA stepping or GPU upload.

use crate::log_msg;
use crate::math::Color;
use crate::runtime::log_messages::{CB01, CB02};
/// Projected wall-slice data for one screen column produced by a single DDA ray.
#[derive(Debug, Clone)]
pub struct ColumnData {
    /// Horizontal texture coordinate for this column, 0.0..1.0.
    pub tex_u: f32,
    /// Screen Y of the top of the wall slice.
    pub start: f32,
    /// Screen Y of the bottom of the wall slice.
    pub end: f32,
    /// Distance-based brightness multiplier, 0.0..1.0.
    pub shade: f32,
    /// Cell value of the wall hit by this ray.
    pub cell_val: u32,
    /// Camera-space depth to the wall hit.
    pub depth: f32,
}
/// Implement `Default` for `ColumnData` providing identity values.
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
/// All columns for a full raycaster frame, plus screen dimensions and flat floor/ceiling colors.
pub struct ColumnBatch {
    /// Projected wall-slice data, one entry per screen column.
    pub columns: Vec<ColumnData>,
    /// Render target width in pixels.
    pub screen_width: f32,
    /// Render target height in pixels.
    pub screen_height: f32,
    /// Flat color for floor pixels not covered by a wall slice.
    pub floor_color: Color,
    /// Flat color for ceiling pixels not covered by a wall slice.
    pub ceiling_color: Color,
}
impl ColumnBatch {
    /// Create a new `ColumnBatch` with `column_count` default columns for the given screen size.
    pub fn new(column_count: usize, screen_width: f32, screen_height: f32) -> Self {
        log_msg!(debug, CB01, "{}", column_count);
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
    /// Write projected wall-slice data to column `col`; silently ignores out-of-range indices.
    pub fn set_column(
        &mut self,
        col: usize,
        tex_u: f32,
        start: f32,
        end: f32,
        shade: f32,
        cell_val: u32,
    ) {
        log_msg!(trace, CB02, "col={} cell={}", col, cell_val);
        if let Some(c) = self.columns.get_mut(col) {
            c.tex_u = tex_u;
            c.start = start;
            c.end = end;
            c.shade = shade;
            c.cell_val = cell_val;
            c.depth = 0.0;
        }
    }
    /// Return the `ColumnData` for column `col`, or `None` if `col` is out of range.
    pub fn get_column(&self, col: usize) -> Option<&ColumnData> {
        self.columns.get(col)
    }
    /// Populate columns from a packed float slice produced by the DDA stepper; each ray is 5 floats.
    pub fn update_from_ray_data(&mut self, rays: &[f32], _fov: f32, max_shade_dist: Option<f32>) {
        let floats_per_ray = 5;
        let ray_count = rays.len() / floats_per_ray;
        for i in 0..ray_count.min(self.columns.len()) {
            let base = i * floats_per_ray;
            let distance = rays[base];
            let cell_value = rays[base + 1] as u32;
            let tex_u = rays[base + 3];
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
    /// Return the depth value stored in column `col`, or `None` if out of range.
    pub fn get_depth_at(&self, col: usize) -> Option<f32> {
        self.columns.get(col).map(|c| c.depth)
    }
    /// Collect depth values from all columns into a new `Vec<f32>`.
    pub fn get_depth_buffer(&self) -> Vec<f32> {
        self.columns.iter().map(|c| c.depth).collect()
    }
    /// Set the flat floor color.
    pub fn set_floor_color(&mut self, color: Color) {
        self.floor_color = color;
    }
    /// Set the flat ceiling color.
    pub fn set_ceiling_color(&mut self, color: Color) {
        self.ceiling_color = color;
    }
    /// Return the number of columns in this batch.
    pub fn get_column_count(&self) -> usize {
        self.columns.len()
    }
    /// Return the render target width this batch was created for.
    pub fn get_screen_width(&self) -> f32 {
        self.screen_width
    }
    /// Return the render target height this batch was created for.
    pub fn get_screen_height(&self) -> f32 {
        self.screen_height
    }
}
