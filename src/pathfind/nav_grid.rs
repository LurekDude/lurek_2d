//! - Integer-cost walkability grid for tile-based pathfinding.
//! - Per-cell movement weight (0 = blocked, 1–254 = traversal cost).
//! - Cardinal and diagonal neighbour queries with corner-cut policies.
//! - Dirty-rectangle tracking for deferred HPA* hierarchy invalidation.
//! - Bulk fill, rect fill, byte import/export, and deep-copy snapshot.
//! - Debug visualisation: render grid + path overlay to an ImageData buffer.

use crate::runtime::log_messages::{NG01, NG02, NG03};
use crate::log_msg;
/// Controls which diagonal moves are permitted during pathfinding.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DiagonalMode {
    /// No diagonal movement allowed.
    None,
    /// Diagonal movement always permitted, even past blocked corners.
    Always,
    /// Diagonal movement only when neither adjacent cardinal neighbour is blocked.
    NoCornerCut,
}
/// Conversion helpers between Lua string names and `DiagonalMode`.
impl DiagonalMode {
    /// Parse a case-insensitive Lua string to a `DiagonalMode`; return `None` for unknown strings.
    pub fn from_lua_str(s: &str) -> Option<Self> {
        match s.to_ascii_lowercase().as_str() {
            "none" => Some(Self::None),
            "always" => Some(Self::Always),
            "nocornercut" | "no_corner_cut" => Some(Self::NoCornerCut),
            _ => Option::None,
        }
    }
    /// Return the canonical lowercase Lua string for this mode.
    pub fn to_lua_str(self) -> &'static str {
        match self {
            Self::None => "none",
            Self::Always => "always",
            Self::NoCornerCut => "nocornercut",
        }
    }
}
/// Runtime walkability grid: integer movement costs, dirty tracking, and snapshot support.
#[derive(Debug, Clone)]
pub struct NavGrid {
    /// Grid width in tiles.
    width: u32,
    /// Grid height in tiles.
    height: u32,
    /// Per-cell cost values; `0` means blocked, `1`–`254` are movement weights.
    costs: Vec<u8>,
    /// Chunk size used by HPA* hierarchy construction.
    chunk_size: u32,
    /// Current diagonal movement policy.
    diagonal_mode: DiagonalMode,
    /// Pending dirty regions awaiting hierarchy rebuild.
    dirty_rects: Vec<(u32, u32, u32, u32)>,
}
/// Construction, query, and mutation methods for `NavGrid`.
impl NavGrid {
    /// Create a fully walkable `width × height` grid with all costs set to `1`.
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
    /// Create a grid from an existing flat cost buffer; panics if `costs.len() != width * height`.
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
    /// Return the grid width in tiles.
    pub fn get_width(&self) -> u32 {
        self.width
    }
    /// Return the grid height in tiles.
    pub fn get_height(&self) -> u32 {
        self.height
    }
    /// Return `(width, height)` as a tuple.
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }
    /// Return the cost at `(x, y)`; returns `0` (blocked) for out-of-bounds coordinates.
    pub fn get_cost(&self, x: u32, y: u32) -> u8 {
        if x >= self.width || y >= self.height {
            return 0;
        }
        self.costs[(y * self.width + x) as usize]
    }
    /// Set the cost at `(x, y)`; silently ignores out-of-bounds coordinates.
    pub fn set_cost(&mut self, x: u32, y: u32, cost: u8) {
        if x < self.width && y < self.height {
            log_msg!(trace, NG03, "({}, {})={}", x, y, cost);
            self.costs[(y * self.width + x) as usize] = cost;
        }
    }
    /// Return true when `(x, y)` has cost `0` (blocked) or is out-of-bounds.
    pub fn is_blocked(&self, x: u32, y: u32) -> bool {
        self.get_cost(x, y) == 0
    }
    /// Set `(x, y)` to cost `0` (blocked) or `1` (passable).
    pub fn set_blocked(&mut self, x: u32, y: u32, blocked: bool) {
        self.set_cost(x, y, if blocked { 0 } else { 1 });
    }
    /// Return true when a `unit_size × unit_size` footprint anchored at `(x, y)` is fully walkable.
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
    /// Set all cells to `cost`. This function is part of the public API.
    pub fn fill(&mut self, cost: u8) {
        self.costs.fill(cost);
    }
    /// Set all cells in the axis-aligned rectangle at `(x, y, w, h)` to `cost`.
    pub fn fill_rect(&mut self, x: u32, y: u32, w: u32, h: u32, cost: u8) {
        let x_end = (x + w).min(self.width);
        let y_end = (y + h).min(self.height);
        for cy in y..y_end {
            for cx in x..x_end {
                self.costs[(cy * self.width + cx) as usize] = cost;
            }
        }
    }
    /// Replace the cost buffer from `data`; return an error if the length does not match `width * height`.
    pub fn load_from_bytes(&mut self, data: &[u8]) -> Result<(), String> {
        let expected = (self.width * self.height) as usize;
        if data.len() != expected {
            return Err(format!("expected {} bytes, got {}", expected, data.len()));
        }
        self.costs.copy_from_slice(data);
        Ok(())
    }
    /// Return a copy of the cost buffer as a byte vector.
    pub fn save_to_bytes(&self) -> Vec<u8> {
        self.costs.clone()
    }
    /// Set the chunk size used by HPA*; clamped to `[2, min(width, height)]`.
    pub fn set_chunk_size(&mut self, size: u32) {
        self.chunk_size = size.max(2).min(self.width.min(self.height).max(2));
    }
    /// Return the current HPA* chunk size.
    pub fn get_chunk_size(&self) -> u32 {
        self.chunk_size
    }
    /// Set the diagonal movement policy for neighbour queries.
    pub fn set_diagonal_mode(&mut self, mode: DiagonalMode) {
        self.diagonal_mode = mode;
    }
    /// Return the current diagonal movement policy.
    pub fn get_diagonal_mode(&self) -> DiagonalMode {
        self.diagonal_mode
    }
    /// Record a dirty rectangle `(x, y, w, h)` for deferred hierarchy invalidation.
    pub fn set_dirty(&mut self, x: u32, y: u32, w: u32, h: u32) {
        self.dirty_rects.push((x, y, w, h));
    }
    /// Clear all pending dirty rectangles.
    pub fn clear_dirty(&mut self) {
        self.dirty_rects.clear();
    }
    /// Return the current slice of pending dirty rectangles.
    pub fn dirty_rects(&self) -> &[(u32, u32, u32, u32)] {
        &self.dirty_rects
    }
    /// Return the passable neighbours of `(x, y)` respecting the current `diagonal_mode`.
    pub fn neighbors(&self, x: u32, y: u32) -> Vec<(u32, u32)> {
        let mut result = Vec::with_capacity(8);
        let w = self.width;
        let h = self.height;
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
    /// Return a deep copy of this grid without carrying over dirty rectangles.
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
    /// Render the grid and optionally overlay a `path`, `start`, and `end` marker into an `ImageData`.
    pub fn draw_to_image(
        &self,
        cell_size: u32,
        path: Option<&[(u32, u32)]>,
        start: Option<(u32, u32)>,
        end: Option<(u32, u32)>,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(self.width * cell_size, self.height * cell_size);
        img.fill(50, 50, 60, 255);
        for y in 0..self.height {
            for x in 0..self.width {
                let cost = self.get_cost(x, y);
                let (r, g, b) = if cost == 0 || cost == 255 {
                    (80u8, 30, 30)
                } else if cost > 3 {
                    (100, 80, 40)
                } else {
                    (50, 70, 50)
                };
                for py in 0..cell_size {
                    for px in 0..cell_size {
                        img.set_pixel(x * cell_size + px, y * cell_size + py, r, g, b, 255);
                    }
                }
            }
        }
        if let Some(p) = path {
            for &(px, py) in p {
                for dy in 2..cell_size.saturating_sub(2) {
                    for dx in 2..cell_size.saturating_sub(2) {
                        img.set_pixel(px * cell_size + dx, py * cell_size + dy, 0, 200, 100, 255);
                    }
                }
            }
        }
        if let Some((sx, sy)) = start {
            img.draw_circle(
                (sx * cell_size + cell_size / 2) as i32,
                (sy * cell_size + cell_size / 2) as i32,
                6,
                0,
                255,
                0,
                255,
            );
        }
        if let Some((ex, ey)) = end {
            img.draw_circle(
                (ex * cell_size + cell_size / 2) as i32,
                (ey * cell_size + cell_size / 2) as i32,
                6,
                255,
                0,
                0,
                255,
            );
        }
        img
    }
}
