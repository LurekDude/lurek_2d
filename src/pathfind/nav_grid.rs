use crate::log_msg;
use crate::runtime::log_messages::{NG01, NG02, NG03};
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DiagonalMode {
    None,
    Always,
    NoCornerCut,
}
impl DiagonalMode {
    pub fn from_lua_str(s: &str) -> Option<Self> {
        match s.to_ascii_lowercase().as_str() {
            "none" => Some(Self::None),
            "always" => Some(Self::Always),
            "nocornercut" | "no_corner_cut" => Some(Self::NoCornerCut),
            _ => Option::None,
        }
    }
    pub fn to_lua_str(self) -> &'static str {
        match self {
            Self::None => "none",
            Self::Always => "always",
            Self::NoCornerCut => "nocornercut",
        }
    }
}
#[derive(Debug, Clone)]
pub struct NavGrid {
    width: u32,
    height: u32,
    costs: Vec<u8>,
    chunk_size: u32,
    diagonal_mode: DiagonalMode,
    dirty_rects: Vec<(u32, u32, u32, u32)>,
}
impl NavGrid {
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
    pub fn get_width(&self) -> u32 {
        self.width
    }
    pub fn get_height(&self) -> u32 {
        self.height
    }
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }
    pub fn get_cost(&self, x: u32, y: u32) -> u8 {
        if x >= self.width || y >= self.height {
            return 0;
        }
        self.costs[(y * self.width + x) as usize]
    }
    pub fn set_cost(&mut self, x: u32, y: u32, cost: u8) {
        if x < self.width && y < self.height {
            log_msg!(trace, NG03, "({}, {})={}", x, y, cost);
            self.costs[(y * self.width + x) as usize] = cost;
        }
    }
    pub fn is_blocked(&self, x: u32, y: u32) -> bool {
        self.get_cost(x, y) == 0
    }
    pub fn set_blocked(&mut self, x: u32, y: u32, blocked: bool) {
        self.set_cost(x, y, if blocked { 0 } else { 1 });
    }
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
    pub fn fill(&mut self, cost: u8) {
        self.costs.fill(cost);
    }
    pub fn fill_rect(&mut self, x: u32, y: u32, w: u32, h: u32, cost: u8) {
        let x_end = (x + w).min(self.width);
        let y_end = (y + h).min(self.height);
        for cy in y..y_end {
            for cx in x..x_end {
                self.costs[(cy * self.width + cx) as usize] = cost;
            }
        }
    }
    pub fn load_from_bytes(&mut self, data: &[u8]) -> Result<(), String> {
        let expected = (self.width * self.height) as usize;
        if data.len() != expected {
            return Err(format!("expected {} bytes, got {}", expected, data.len()));
        }
        self.costs.copy_from_slice(data);
        Ok(())
    }
    pub fn save_to_bytes(&self) -> Vec<u8> {
        self.costs.clone()
    }
    pub fn set_chunk_size(&mut self, size: u32) {
        self.chunk_size = size.max(2).min(self.width.min(self.height).max(2));
    }
    pub fn get_chunk_size(&self) -> u32 {
        self.chunk_size
    }
    pub fn set_diagonal_mode(&mut self, mode: DiagonalMode) {
        self.diagonal_mode = mode;
    }
    pub fn get_diagonal_mode(&self) -> DiagonalMode {
        self.diagonal_mode
    }
    pub fn set_dirty(&mut self, x: u32, y: u32, w: u32, h: u32) {
        self.dirty_rects.push((x, y, w, h));
    }
    pub fn clear_dirty(&mut self) {
        self.dirty_rects.clear();
    }
    pub fn dirty_rects(&self) -> &[(u32, u32, u32, u32)] {
        &self.dirty_rects
    }
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
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn new_grid_all_walkable() {
        let g = NavGrid::new(10, 10);
        assert_eq!(g.get_width(), 10);
        assert_eq!(g.get_height(), 10);
        assert_eq!(g.get_dimensions(), (10, 10));
        for y in 0..10 {
            for x in 0..10 {
                assert!(!g.is_blocked(x, y));
                assert_eq!(g.get_cost(x, y), 1);
            }
        }
    }
    #[test]
    fn set_cost_and_blocked() {
        let mut g = NavGrid::new(5, 5);
        g.set_cost(2, 3, 0);
        assert!(g.is_blocked(2, 3));
        g.set_blocked(1, 1, true);
        assert!(g.is_blocked(1, 1));
        g.set_blocked(1, 1, false);
        assert!(!g.is_blocked(1, 1));
    }
    #[test]
    fn out_of_bounds_returns_blocked() {
        let g = NavGrid::new(3, 3);
        assert_eq!(g.get_cost(5, 5), 0);
        assert!(g.is_blocked(3, 0));
    }
    #[test]
    fn is_walkable_unit_size() {
        let mut g = NavGrid::new(5, 5);
        assert!(g.is_walkable(0, 0, 2));
        g.set_blocked(1, 0, true);
        assert!(!g.is_walkable(0, 0, 2));
    }
    #[test]
    fn from_costs_matches() {
        let costs = vec![1u8; 9];
        let g = NavGrid::from_costs(3, 3, costs);
        assert_eq!(g.get_dimensions(), (3, 3));
        assert!(!g.is_blocked(0, 0));
    }
    #[test]
    fn fill_and_fill_rect() {
        let mut g = NavGrid::new(4, 4);
        g.fill(0);
        assert!(g.is_blocked(2, 2));
        g.fill(1);
        g.fill_rect(1, 1, 2, 2, 0);
        assert!(g.is_blocked(1, 1));
        assert!(g.is_blocked(2, 2));
        assert!(!g.is_blocked(0, 0));
    }
    #[test]
    fn diagonal_mode_round_trip() {
        assert_eq!(
            DiagonalMode::from_lua_str("always"),
            Some(DiagonalMode::Always)
        );
        assert_eq!(DiagonalMode::from_lua_str("none"), Some(DiagonalMode::None));
        assert_eq!(
            DiagonalMode::from_lua_str("nocornercut"),
            Some(DiagonalMode::NoCornerCut)
        );
        assert_eq!(DiagonalMode::from_lua_str("bogus"), None);
        assert_eq!(DiagonalMode::Always.to_lua_str(), "always");
    }
    #[test]
    fn load_save_bytes_round_trip() {
        let mut g = NavGrid::new(3, 3);
        g.set_cost(1, 1, 5);
        let bytes = g.save_to_bytes();
        let mut g2 = NavGrid::new(3, 3);
        g2.load_from_bytes(&bytes).unwrap();
        assert_eq!(g2.get_cost(1, 1), 5);
    }
    #[test]
    fn load_from_bytes_wrong_len_errors() {
        let mut g = NavGrid::new(3, 3);
        assert!(g.load_from_bytes(&[0u8; 5]).is_err());
    }
}
