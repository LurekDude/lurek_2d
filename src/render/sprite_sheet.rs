//! Grid-based sprite sheet with directional support and named groups.
//!
//! Splits a texture into a uniform grid of frames and provides indexed,
//! row/column, named-group, and directional access to the resulting quads.

use std::collections::HashMap;

use crate::runtime::log_messages::{SS01, SS02};
use crate::log_msg;
use crate::math::Rect;

/// Named frame group within the sprite sheet.
///
/// # Fields
/// - `name` — `String`.
/// - `start_frame` — `usize`.
/// - `count` — `usize`.
#[derive(Debug, Clone)]
pub struct FrameGroup {
    /// Human-readable name for this group.
    pub name: String,
    /// 0-based index of the first frame in the group.
    pub start_frame: usize,
    /// Number of frames in the group.
    pub count: usize,
}

/// Directional layout for sprite sets. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Variants
/// - `Rows` — Rows variant.
/// - `Columns` — Columns variant.
#[derive(Debug, Clone, PartialEq)]
pub enum DirectionLayout {
    /// Each direction occupies a row.
    Rows,
    /// Each direction occupies a column.
    Columns,
}

/// Grid-based sprite sheet with directional support and named groups.
///
/// # Fields
/// - `frame_width` — `u32`.
/// - `frame_height` — `u32`.
/// - `columns` — `u32`.
/// - `rows` — `u32`.
/// - `texture_width` — `u32`.
/// - `texture_height` — `u32`.
///
/// Divides a texture into equal-sized cells and pre-computes UV quads
/// for every frame. Supports named groups and 4/8-directional layouts.
pub struct SpriteSheet {
    /// Width of a single frame in pixels.
    pub frame_width: u32,
    /// Height of a single frame in pixels.
    pub frame_height: u32,
    /// Number of columns in the grid.
    pub columns: u32,
    /// Number of rows in the grid.
    pub rows: u32,
    /// Width of the source texture in pixels.
    pub texture_width: u32,
    /// Height of the source texture in pixels.
    pub texture_height: u32,
    /// Pre-computed quads for every frame.
    frames: Vec<Rect>,
    /// Named frame groups.
    groups: HashMap<String, FrameGroup>,
    /// Optional directional count (4 or 8).
    direction_count: Option<u32>,
    /// Whether directions are laid out in rows or columns.
    direction_layout: DirectionLayout,
}

impl SpriteSheet {
    /// Create a new sprite sheet by dividing a texture into a uniform grid.
    ///
    /// # Parameters
    /// - `texture_width` — `u32`.
    /// - `texture_height` — `u32`.
    /// - `frame_width` — `u32`.
    /// - `frame_height` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Computes columns/rows from texture and frame dimensions and
    /// pre-generates all frame quads.
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

    /// Return the quad for a 0-based frame index.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<Rect>`.
    pub fn get_frame(&self, index: usize) -> Option<Rect> {
        self.frames.get(index).copied()
    }

    /// Total number of frames in the sheet. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_frame_count(&self) -> usize {
        self.frames.len()
    }

    /// Dimensions of a single frame `(width, height)`.
    ///
    /// # Returns
    /// `(u32, u32)`.
    pub fn get_frame_size(&self) -> (u32, u32) {
        (self.frame_width, self.frame_height)
    }

    /// Grid dimensions `(columns, rows)`. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `(u32, u32)`.
    pub fn get_grid_size(&self) -> (u32, u32) {
        (self.columns, self.rows)
    }

    /// Return all frame quads in a 0-based row.
    ///
    /// # Parameters
    /// - `row` — `u32`.
    ///
    /// # Returns
    /// `Vec<Rect>`.
    pub fn get_row(&self, row: u32) -> Vec<Rect> {
        if row >= self.rows {
            return Vec::new();
        }
        let start = (row * self.columns) as usize;
        let end = start + self.columns as usize;
        self.frames[start..end.min(self.frames.len())].to_vec()
    }

    /// Return all frame quads in a 0-based column.
    ///
    /// # Parameters
    /// - `col` — `u32`.
    ///
    /// # Returns
    /// `Vec<Rect>`.
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

    /// Return a contiguous range of frame quads starting at `start` (0-based).
    ///
    /// # Parameters
    /// - `start` — `usize`.
    /// - `count` — `usize`.
    ///
    /// # Returns
    /// `Vec<Rect>`.
    pub fn get_range(&self, start: usize, count: usize) -> Vec<Rect> {
        let end = (start + count).min(self.frames.len());
        if start >= self.frames.len() {
            return Vec::new();
        }
        self.frames[start..end].to_vec()
    }

    /// Store a named frame group. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    /// - `start_frame` — `usize`.
    /// - `count` — `usize`.
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

    /// Return the frame quads for a named group.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<Vec<Rect>>`.
    pub fn get_group(&self, name: &str) -> Option<Vec<Rect>> {
        let group = self.groups.get(name)?;
        Some(self.get_range(group.start_frame, group.count))
    }

    /// Return the names of all defined groups. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn get_group_names(&self) -> Vec<String> {
        self.groups.keys().cloned().collect()
    }

    /// Set the directional mode (4 or 8 directions) and layout.
    ///
    /// # Parameters
    /// - `count` — `u32`.
    /// - `layout` — `DirectionLayout`.
    pub fn set_directions(&mut self, count: u32, layout: DirectionLayout) {
        self.direction_count = Some(count);
        self.direction_layout = layout;
    }

    /// Return the frame quads for a 0-based direction index.
    ///
    /// # Parameters
    /// - `direction` — `u32`.
    ///
    /// # Returns
    /// `Option<Vec<Rect>>`.
    ///
    /// With `Rows` layout, direction `n` maps to row `n`.
    /// With `Columns` layout, direction `n` maps to column `n`.
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
}
