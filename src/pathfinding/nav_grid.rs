//! Navigation grid with per-cell traversal costs and diagonal movement modes.
//!
//! This module is part of Lurek2D's `pathfinding` subsystem and provides the implementation
//! details for nav grid-related operations and data management.
//! Key types exported from this module: `DiagonalMode`, `NavGrid`.
//! Primary functions: `from_lua_str()`, `new()`, `from_costs()`, `get_width()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use crate::engine::log_messages::{NG01, NG02, NG03};
use crate::log_msg;

/// Controls how diagonal movement is handled during pathfinding.
///
/// # Variants
/// - `None` — None variant.
/// - `Always` — Always variant.
/// - `NoCornerCut` — NoCornerCut variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DiagonalMode {
    /// 4-directional movement only (up, down, left, right).
    None,
    /// 8-directional movement; diagonals always allowed at cost √2.
    Always,
    /// 8-directional movement but diagonals blocked when either adjacent
    /// cardinal neighbour is impassable (prevents corner-cutting).
    NoCornerCut,
}

impl DiagonalMode {
    /// Parse a Lua string into a `DiagonalMode`.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Option<Self>`.
    ///
    /// Accepted values: `"none"`, `"always"`, `"nocornercut"` (case-insensitive).
    /// Returns `None` for unrecognised strings.
    pub fn from_lua_str(s: &str) -> Option<Self> {
        match s.to_ascii_lowercase().as_str() {
            "none" => Some(Self::None),
            "always" => Some(Self::Always),
            "nocornercut" | "no_corner_cut" => Some(Self::NoCornerCut),
            _ => Option::None,
        }
    }

    /// Convert to the canonical Lua string representation.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn to_lua_str(self) -> &'static str {
        match self {
            Self::None => "none",
            Self::Always => "always",
            Self::NoCornerCut => "nocornercut",
        }
    }
}

/// A 2D grid of traversal costs used by pathfinding algorithms.
///
/// Cells are addressed with 0-based `(x, y)` coordinates in row-major order.
/// A cost of `0` marks a cell as blocked; values `1.=255` represent movement cost.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `costs` — `Vec<u8>`.
/// - `chunk_size` — `u32`.
/// - `diagonal_mode` — `DiagonalMode`.
/// - `dirty_rects` — `Vec<(u32`.
#[derive(Debug, Clone)]
pub struct NavGrid {
    /// Grid width in cells.
    width: u32,
    /// Grid height in cells.
    height: u32,
    /// Per-cell cost in row-major order. 0 = blocked, 1-255 = traversal cost.
    costs: Vec<u8>,
    /// HPA* chunk size (default 16).
    chunk_size: u32,
    /// How diagonal movement is handled.
    diagonal_mode: DiagonalMode,
    /// Rectangles (x, y, w, h) marking regions that changed since last clear.
    dirty_rects: Vec<(u32, u32, u32, u32)>,
}

impl NavGrid {
    /// Create a new grid where every cell has cost 1 (fully walkable).
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(width: u32, height: u32) -> Self {
        log_msg!(debug, NG01, "{}x{}", width, height);
        Self {
            width,
            height,
            costs: vec![1u8; (width * height) as usize],
            chunk_size: 16,
            diagonal_mode: DiagonalMode::NoCornerCut,
            dirty_rects: Vec::new(),
        }
    }

    /// Create a grid from a pre-built cost array.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    /// - `costs` — `Vec<u8>`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// `costs` must have exactly `width * height` elements.
    /// A cost of 0 marks blocked; 1-255 is traversal cost.
    pub fn from_costs(width: u32, height: u32, costs: Vec<u8>) -> Self {
        assert_eq!(
            costs.len(),
            (width * height) as usize,
            "costs length must equal width * height"
        );
        log_msg!(debug, NG02, "{}x{} {} costs", width, height, costs.len());
        Self {
            width,
            height,
            costs,
            chunk_size: 16,
            diagonal_mode: DiagonalMode::NoCornerCut,
            dirty_rects: Vec::new(),
        }
    }

    /// Grid width in cells. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_width(&self) -> u32 {
        self.width
    }

    /// Grid height in cells. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_height(&self) -> u32 {
        self.height
    }

    /// Returns `(width, height)`. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `(u32, u32)`.
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }

    /// Get the traversal cost of cell `(x, y)`. Returns 0 for out-of-bounds.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `u8`.
    pub fn get_cost(&self, x: u32, y: u32) -> u8 {
        if x >= self.width || y >= self.height {
            return 0;
        }
        self.costs[(y * self.width + x) as usize]
    }

    /// Set the traversal cost of cell `(x, y)`. No-op for out-of-bounds.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `cost` — `u8`.
    pub fn set_cost(&mut self, x: u32, y: u32, cost: u8) {
        if x < self.width && y < self.height {
            log_msg!(trace, NG03, "({}, {})={}", x, y, cost);
            self.costs[(y * self.width + x) as usize] = cost;
        }
    }

    /// Returns `true` if cell `(x, y)` is blocked (cost 0 or out-of-bounds).
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_blocked(&self, x: u32, y: u32) -> bool {
        self.get_cost(x, y) == 0
    }

    /// Mark cell `(x, y)` as blocked (cost 0) or unblocked (cost 1).
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `blocked` — `bool`.
    pub fn set_blocked(&mut self, x: u32, y: u32, blocked: bool) {
        self.set_cost(x, y, if blocked { 0 } else { 1 });
    }

    /// Check whether an `NxN` unit footprint anchored at `(x, y)` is fully walkable.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `unit_size` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_walkable(&self, x: u32, y: u32, unit_size: u32) -> bool {
        let size = unit_size.max(1);
        if x + size > self.width || y + size > self.height {
            return false;
        }
        for dy in 0..size {
            for dx in 0..size {
                if self.is_blocked(x + dx, y + dy) {
                    return false;
                }
            }
        }
        true
    }

    /// Set every cell to `cost`.
    ///
    /// # Parameters
    /// - `cost` — `u8`.
    pub fn fill(&mut self, cost: u8) {
        self.costs.fill(cost);
    }

    /// Set all cells in the rectangle `(x, y, w, h)` to `cost`, clamped to grid bounds.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `w` — `u32`.
    /// - `h` — `u32`.
    /// - `cost` — `u8`.
    pub fn fill_rect(&mut self, x: u32, y: u32, w: u32, h: u32, cost: u8) {
        let x_end = (x + w).min(self.width);
        let y_end = (y + h).min(self.height);
        for cy in y..y_end {
            for cx in x..x_end {
                self.costs[(cy * self.width + cx) as usize] = cost;
            }
        }
    }

    /// Overwrite the grid from a raw byte slice (row-major, one byte per cell).
    ///
    /// # Parameters
    /// - `data` — `&[u8]`.
    ///
    /// # Returns
    /// `Result<(), String>`.
    ///
    /// Returns `Err` if the slice length doesn't match `width * height`.
    pub fn load_from_bytes(&mut self, data: &[u8]) -> Result<(), String> {
        let expected = (self.width * self.height) as usize;
        if data.len() != expected {
            return Err(format!("expected {} bytes, got {}", expected, data.len()));
        }
        self.costs.copy_from_slice(data);
        Ok(())
    }

    /// Export the cost grid as a byte vector (row-major, one byte per cell).
    ///
    /// # Returns
    /// `Vec<u8>`.
    pub fn save_to_bytes(&self) -> Vec<u8> {
        self.costs.clone()
    }

    /// Set the HPA* chunk size (clamped to `[2, min(width, height)]`).
    ///
    /// # Parameters
    /// - `size` — `u32`.
    pub fn set_chunk_size(&mut self, size: u32) {
        self.chunk_size = size.max(2).min(self.width.min(self.height).max(2));
    }

    /// Current HPA* chunk size. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_chunk_size(&self) -> u32 {
        self.chunk_size
    }

    /// Set the diagonal movement mode. Replaces the current diagonal mode value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `mode` — `DiagonalMode`.
    pub fn set_diagonal_mode(&mut self, mode: DiagonalMode) {
        self.diagonal_mode = mode;
    }

    /// Current diagonal movement mode. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `DiagonalMode`.
    pub fn get_diagonal_mode(&self) -> DiagonalMode {
        self.diagonal_mode
    }

    /// Record a dirty rectangle `(x, y, w, h)` for incremental HPA* updates.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `w` — `u32`.
    /// - `h` — `u32`.
    pub fn set_dirty(&mut self, x: u32, y: u32, w: u32, h: u32) {
        self.dirty_rects.push((x, y, w, h));
    }

    /// Clear all pending dirty rectangles. After this call the container is in the same state as immediately after construction.
    pub fn clear_dirty(&mut self) {
        self.dirty_rects.clear();
    }

    /// Returns the list of dirty rectangles recorded since the last clear.
    ///
    /// # Returns
    /// `&[(u32, u32, u32, u32)]`.
    pub fn dirty_rects(&self) -> &[(u32, u32, u32, u32)] {
        &self.dirty_rects
    }

    /// Return walkable neighbours of `(x, y)` respecting the current diagonal mode.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `Vec<(u32, u32)>`.
    pub fn neighbors(&self, x: u32, y: u32) -> Vec<(u32, u32)> {
        let mut result = Vec::with_capacity(8);
        let w = self.width;
        let h = self.height;

        // Cardinals
        let can_up = y > 0 && !self.is_blocked(x, y - 1);
        let can_down = y + 1 < h && !self.is_blocked(x, y + 1);
        let can_left = x > 0 && !self.is_blocked(x - 1, y);
        let can_right = x + 1 < w && !self.is_blocked(x + 1, y);

        if can_up {
            result.push((x, y - 1));
        }
        if can_down {
            result.push((x, y + 1));
        }
        if can_left {
            result.push((x - 1, y));
        }
        if can_right {
            result.push((x + 1, y));
        }

        match self.diagonal_mode {
            DiagonalMode::None => {}
            DiagonalMode::Always => {
                // All four diagonals if the diagonal cell itself is walkable
                if y > 0 && x > 0 && !self.is_blocked(x - 1, y - 1) {
                    result.push((x - 1, y - 1));
                }
                if y > 0 && x + 1 < w && !self.is_blocked(x + 1, y - 1) {
                    result.push((x + 1, y - 1));
                }
                if y + 1 < h && x > 0 && !self.is_blocked(x - 1, y + 1) {
                    result.push((x - 1, y + 1));
                }
                if y + 1 < h && x + 1 < w && !self.is_blocked(x + 1, y + 1) {
                    result.push((x + 1, y + 1));
                }
            }
            DiagonalMode::NoCornerCut => {
                // Diagonal only if both adjacent cardinals are walkable
                if can_up && can_left && !self.is_blocked(x - 1, y - 1) {
                    result.push((x - 1, y - 1));
                }
                if can_up && can_right && !self.is_blocked(x + 1, y - 1) {
                    result.push((x + 1, y - 1));
                }
                if can_down && can_left && !self.is_blocked(x - 1, y + 1) {
                    result.push((x - 1, y + 1));
                }
                if can_down && can_right && !self.is_blocked(x + 1, y + 1) {
                    result.push((x + 1, y + 1));
                }
            }
        }

        result
    }

    /// Create a lightweight clone suitable for use on another thread.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Copies dimensions, costs, chunk size, and diagonal mode but omits dirty rects.
    pub fn snapshot(&self) -> Self {
        Self {
            width: self.width,
            height: self.height,
            costs: self.costs.clone(),
            chunk_size: self.chunk_size,
            diagonal_mode: self.diagonal_mode,
            dirty_rects: Vec::new(),
        }
    }

    /// Render the navigation grid to an image with optional path overlay.
    ///
    /// Blocked cells (cost 0 / 255) are drawn dark red, high-cost cells are
    /// brownish, and normal cells are dark green. An optional path is
    /// highlighted in green, with start and end markers.
    ///
    /// # Parameters
    /// - `cell_size` — `u32`. Pixel size of each grid cell.
    /// - `path` — `Option<&[(u32, u32)]>`. Path cells to highlight.
    /// - `start` — `Option<(u32, u32)>`. Start cell for circle marker.
    /// - `end` — `Option<(u32, u32)>`. End cell for circle marker.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn render_to_image(
        &self,
        cell_size: u32,
        path: Option<&[(u32, u32)]>,
        start: Option<(u32, u32)>,
        end: Option<(u32, u32)>,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(self.width * cell_size, self.height * cell_size);
        img.fill(50, 50, 60, 255);
        // Draw cells
        for y in 0..self.height {
            for x in 0..self.width {
                let cost = self.get_cost(x, y);
                let (r, g, b) = if cost == 0 || cost == 255 {
                    (80u8, 30, 30) // blocked
                } else if cost > 3 {
                    (100, 80, 40) // high cost
                } else {
                    (50, 70, 50) // normal
                };
                for py in 0..cell_size {
                    for px in 0..cell_size {
                        img.set_pixel(x * cell_size + px, y * cell_size + py, r, g, b, 255);
                    }
                }
            }
        }
        // Draw path
        if let Some(p) = path {
            for &(px, py) in p {
                for dy in 2..cell_size.saturating_sub(2) {
                    for dx in 2..cell_size.saturating_sub(2) {
                        img.set_pixel(px * cell_size + dx, py * cell_size + dy, 0, 200, 100, 255);
                    }
                }
            }
        }
        // Start marker
        if let Some((sx, sy)) = start {
            img.draw_circle(
                (sx * cell_size + cell_size / 2) as i32,
                (sy * cell_size + cell_size / 2) as i32,
                6, 0, 255, 0, 255,
            );
        }
        // End marker
        if let Some((ex, ey)) = end {
            img.draw_circle(
                (ex * cell_size + cell_size / 2) as i32,
                (ey * cell_size + cell_size / 2) as i32,
                6, 255, 0, 0, 255,
            );
        }
        img
    }

}
