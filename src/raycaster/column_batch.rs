use crate::log_msg;
use crate::math::Color;
use crate::runtime::log_messages::{CB01, CB02};
#[derive(Debug, Clone)]
pub struct ColumnData {
    pub tex_u: f32,
    pub start: f32,
    pub end: f32,
    pub shade: f32,
    pub cell_val: u32,
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
pub struct ColumnBatch {
    pub columns: Vec<ColumnData>,
    pub screen_width: f32,
    pub screen_height: f32,
    pub floor_color: Color,
    pub ceiling_color: Color,
}
impl ColumnBatch {
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
    pub fn get_column(&self, col: usize) -> Option<&ColumnData> {
        self.columns.get(col)
    }
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
    pub fn get_depth_at(&self, col: usize) -> Option<f32> {
        self.columns.get(col).map(|c| c.depth)
    }
    pub fn get_depth_buffer(&self) -> Vec<f32> {
        self.columns.iter().map(|c| c.depth).collect()
    }
    pub fn set_floor_color(&mut self, color: Color) {
        self.floor_color = color;
    }
    pub fn set_ceiling_color(&mut self, color: Color) {
        self.ceiling_color = color;
    }
    pub fn get_column_count(&self) -> usize {
        self.columns.len()
    }
    pub fn get_screen_width(&self) -> f32 {
        self.screen_width
    }
    pub fn get_screen_height(&self) -> f32 {
        self.screen_height
    }
}
