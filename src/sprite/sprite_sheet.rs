use crate::log_msg;
use crate::math::Rect;
use crate::runtime::log_messages::{SS01, SS02};
use std::collections::HashMap;
#[derive(Debug, Clone)]
pub struct FrameGroup {
    pub name: String,
    pub start_frame: usize,
    pub count: usize,
}
#[derive(Debug, Clone, PartialEq)]
pub enum DirectionLayout {
    Rows,
    Columns,
}
pub struct SpriteSheet {
    pub frame_width: u32,
    pub frame_height: u32,
    pub columns: u32,
    pub rows: u32,
    pub texture_width: u32,
    pub texture_height: u32,
    frames: Vec<Rect>,
    groups: HashMap<String, FrameGroup>,
    direction_count: Option<u32>,
    direction_layout: DirectionLayout,
}
impl SpriteSheet {
    pub fn new(
        texture_width: u32,
        texture_height: u32,
        frame_width: u32,
        frame_height: u32,
    ) -> Self {
        let columns = if frame_width > 0 {
            texture_width / frame_width
        } else {
            0
        };
        let rows = if frame_height > 0 {
            texture_height / frame_height
        } else {
            0
        };
        let total = (columns * rows) as usize;
        let mut frames = Vec::with_capacity(total);
        for i in 0..total {
            let col = (i as u32) % columns;
            let row = (i as u32) / columns;
            frames.push(Rect {
                x: (col * frame_width) as f32,
                y: (row * frame_height) as f32,
                width: frame_width as f32,
                height: frame_height as f32,
            });
        }
        log_msg!(debug, SS01, "frames={}", total);
        Self {
            frame_width,
            frame_height,
            columns,
            rows,
            texture_width,
            texture_height,
            frames,
            groups: HashMap::new(),
            direction_count: None,
            direction_layout: DirectionLayout::Rows,
        }
    }
    pub fn get_frame(&self, index: usize) -> Option<Rect> {
        self.frames.get(index).copied()
    }
    pub fn get_frame_count(&self) -> usize {
        self.frames.len()
    }
    pub fn get_frame_size(&self) -> (u32, u32) {
        (self.frame_width, self.frame_height)
    }
    pub fn get_grid_size(&self) -> (u32, u32) {
        (self.columns, self.rows)
    }
    pub fn get_row(&self, row: u32) -> Vec<Rect> {
        if row >= self.rows {
            return Vec::new();
        }
        let start = (row * self.columns) as usize;
        let end = start + self.columns as usize;
        self.frames[start..end.min(self.frames.len())].to_vec()
    }
    pub fn get_column(&self, col: u32) -> Vec<Rect> {
        if col >= self.columns {
            return Vec::new();
        }
        (0..self.rows)
            .filter_map(|r| {
                let idx = (r * self.columns + col) as usize;
                self.frames.get(idx).copied()
            })
            .collect()
    }
    pub fn get_range(&self, start: usize, count: usize) -> Vec<Rect> {
        let end = (start + count).min(self.frames.len());
        if start >= self.frames.len() {
            return Vec::new();
        }
        self.frames[start..end].to_vec()
    }
    pub fn name_group(&mut self, name: impl Into<String>, start_frame: usize, count: usize) {
        let name = name.into();
        log_msg!(debug, SS02, "{} [{}..{}]", name, start_frame, count);
        self.groups.insert(
            name.clone(),
            FrameGroup {
                name,
                start_frame,
                count,
            },
        );
    }
    pub fn get_group(&self, name: &str) -> Option<Vec<Rect>> {
        let group = self.groups.get(name)?;
        Some(self.get_range(group.start_frame, group.count))
    }
    pub fn get_group_names(&self) -> Vec<String> {
        self.groups.keys().cloned().collect()
    }
    pub fn set_directions(&mut self, count: u32, layout: DirectionLayout) {
        self.direction_count = Some(count);
        self.direction_layout = layout;
    }
    pub fn get_direction_frames(&self, direction: u32) -> Option<Vec<Rect>> {
        let count = self.direction_count?;
        if direction >= count {
            return None;
        }
        match self.direction_layout {
            DirectionLayout::Rows => {
                if direction >= self.rows {
                    return None;
                }
                Some(self.get_row(direction))
            }
            DirectionLayout::Columns => {
                if direction >= self.columns {
                    return None;
                }
                Some(self.get_column(direction))
            }
        }
    }
    pub fn draw_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        for y in 0..height {
            for x in 0..width {
                img.set_pixel(x, y, 255, 255, 255, 255);
            }
        }
        let mut group_starts: std::collections::HashSet<usize> = std::collections::HashSet::new();
        for group in self.groups.values() {
            group_starts.insert(group.start_frame);
        }
        let scale_x = width as f32 / self.texture_width as f32;
        let scale_y = height as f32 / self.texture_height as f32;
        for i in 0..self.get_frame_count() {
            if let Some(rect) = self.get_frame(i) {
                let rx = (rect.x * scale_x) as i32;
                let ry = (rect.y * scale_y) as i32;
                let rw = ((rect.width * scale_x) as u32).max(1);
                let rh = ((rect.height * scale_y) as u32).max(1);
                let (r, g, b) = if group_starts.contains(&i) {
                    (0, 200, 0)
                } else {
                    (200, 0, 0)
                };
                img.draw_rect(rx, ry, rw, 1, r, g, b, 255);
                img.draw_rect(rx, ry + rh as i32 - 1, rw, 1, r, g, b, 255);
                img.draw_rect(rx, ry, 1, rh, r, g, b, 255);
                img.draw_rect(rx + rw as i32 - 1, ry, 1, rh, r, g, b, 255);
            }
        }
        img
    }
    pub fn from_rpgmaker(texture_width: u32, texture_height: u32) -> Self {
        let mut sheet = Self::new(
            texture_width,
            texture_height,
            texture_width / 3,
            texture_height / 4,
        );
        sheet.name_group("down", 0, 3);
        sheet.name_group("left", 3, 3);
        sheet.name_group("right", 6, 3);
        sheet.name_group("up", 9, 3);
        sheet
    }
    pub fn from_atlas(
        atlas: &super::atlas::SpriteAtlas,
        sheet_width: u32,
        sheet_height: u32,
    ) -> Self {
        let count = atlas.entry_count().max(1);
        let w = if count > 0 {
            sheet_width / count as u32
        } else {
            sheet_width
        };
        let mut sheet = Self::new(sheet_width, sheet_height, w.max(1), sheet_height);
        sheet.frames.clear();
        for i in 0..atlas.entry_count() {
            if let Some(entry) = atlas.get_by_index(i) {
                sheet.frames.push(Rect::new(
                    entry.x as f32,
                    entry.y as f32,
                    entry.w as f32,
                    entry.h as f32,
                ));
                let start = sheet.frames.len() - 1;
                sheet.name_group(&entry.name, start, 1);
            }
        }
        sheet
    }
}
