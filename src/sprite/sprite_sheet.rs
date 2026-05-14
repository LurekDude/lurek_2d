//! SpriteSheet: uniform grid frame extraction and named group management for a single texture.
//! Owns SpriteSheet, FrameGroup, and DirectionLayout; precomputes all Rect frames at construction time.
//! Does not own texture upload or rendering — callers use get_frame() / get_group() to drive draw calls.
//! Key dependencies: math::Rect for frame regions, SpriteAtlas for from_atlas construction.

use crate::log_msg;
use crate::math::Rect;
use crate::runtime::log_messages::{SS01, SS02};
use std::collections::HashMap;
/// Named contiguous frame range within a SpriteSheet, used by get_group().
#[derive(Debug, Clone)]
pub struct FrameGroup {
    /// Name used as the lookup key in the groups map.
    pub name: String,
    /// First frame index in the sheet's frame array.
    pub start_frame: usize,
    /// Number of frames in this group.
    pub count: usize,
}
/// Axis along which direction slots are arranged in a directional sprite sheet.
#[derive(Debug, Clone, PartialEq)]
pub enum DirectionLayout {
    /// Each direction occupies a horizontal row.
    Rows,
    /// Each direction occupies a vertical column.
    Columns,
}
/// Uniform grid frame extractor for a single texture with optional named groups and directional layout.
pub struct SpriteSheet {
    /// Width of each frame in pixels.
    pub frame_width: u32,
    /// Height of each frame in pixels.
    pub frame_height: u32,
    /// Number of columns of frames across the texture.
    pub columns: u32,
    /// Number of rows of frames down the texture.
    pub rows: u32,
    /// Total source texture width in pixels.
    pub texture_width: u32,
    /// Total source texture height in pixels.
    pub texture_height: u32,
    /// Precomputed Rect for every frame at construction time; index = row*columns + column.
    frames: Vec<Rect>,
    /// Named frame group registry.
    groups: HashMap<String, FrameGroup>,
    /// Number of logical directions when set_directions is used.
    direction_count: Option<u32>,
    /// Layout axis for direction slots.
    direction_layout: DirectionLayout,
}
/// Construction and frame/group/direction methods for SpriteSheet.
impl SpriteSheet {
    /// Create a SpriteSheet from texture dimensions and per-frame size; precomputes all frame Rects.
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
    /// Return the Rect for frame at linear index, or None when out of bounds.
    pub fn get_frame(&self, index: usize) -> Option<Rect> {
        self.frames.get(index).copied()
    }
    /// Return the total number of precomputed frames.
    pub fn get_frame_count(&self) -> usize {
        self.frames.len()
    }
    /// Return (frame_width, frame_height) in pixels.
    pub fn get_frame_size(&self) -> (u32, u32) {
        (self.frame_width, self.frame_height)
    }
    /// Return (columns, rows) of the grid.
    pub fn get_grid_size(&self) -> (u32, u32) {
        (self.columns, self.rows)
    }
    /// Return all frame Rects on the given row index; empty vec when row >= rows.
    pub fn get_row(&self, row: u32) -> Vec<Rect> {
        if row >= self.rows {
            return Vec::new();
        }
        let start = (row * self.columns) as usize;
        let end = start + self.columns as usize;
        self.frames[start..end.min(self.frames.len())].to_vec()
    }
    /// Return all frame Rects in the given column index; empty vec when col >= columns.
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
    /// Return up to count frames starting at start; empty vec when start >= frame count.
    pub fn get_range(&self, start: usize, count: usize) -> Vec<Rect> {
        let end = (start + count).min(self.frames.len());
        if start >= self.frames.len() {
            return Vec::new();
        }
        self.frames[start..end].to_vec()
    }
    /// Register a named frame group starting at start_frame for count consecutive frames.
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
    /// Return the Rects for the named group, or None when the name is not registered.
    pub fn get_group(&self, name: &str) -> Option<Vec<Rect>> {
        let group = self.groups.get(name)?;
        Some(self.get_range(group.start_frame, group.count))
    }
    /// Return all registered group names in unspecified order.
    pub fn get_group_names(&self) -> Vec<String> {
        self.groups.keys().cloned().collect()
    }
    /// Configure the sheet for directional animation with count directions arranged by layout.
    pub fn set_directions(&mut self, count: u32, layout: DirectionLayout) {
        self.direction_count = Some(count);
        self.direction_layout = layout;
    }
    /// Return all frame Rects for the given direction index; None when set_directions was not called or index out of range.
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
    /// Rasterise the sheet grid (red borders, green for group starts) into a new ImageData of the given dimensions.
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
    /// Create a SpriteSheet pre-configured for the RPGMaker 3×4 character sheet layout with named direction groups.
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
    /// Build a SpriteSheet from a SpriteAtlas using atlas entry Rects as frames; names each entry as a group.
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
