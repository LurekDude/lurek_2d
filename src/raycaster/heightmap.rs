//! Floor and ceiling height variations for stepped or multi-level environments.
//!
//! Provides a [`HeightMap`] that stores per-cell floor and ceiling heights,
//! enabling variable-height corridors in grid-based raycaster levels.

/// Per-cell floor and ceiling heights for variable-height levels.
///
/// Each cell has a floor height (default 0.0) and ceiling height (default 1.0).
/// These can be used to render stepped floors, raised platforms, and lowered
/// ceilings in dungeon-crawler style environments.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `floor_heights` — `Vec<f32>`.
/// - `ceiling_heights` — `Vec<f32>`.
pub struct HeightMap {
    width: u32,
    height: u32,
    floor_heights: Vec<f32>,
    ceiling_heights: Vec<f32>,
}

impl HeightMap {
    /// Creates a new height map with default values (floor=0.0, ceiling=1.0).
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(width: u32, height: u32) -> Self {
        let count = (width * height) as usize;
        Self {
            width,
            height,
            floor_heights: vec![0.0; count],
            ceiling_heights: vec![1.0; count],
        }
    }

    /// Sets the floor height at (x, y).
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `h` — `f32`.
    pub fn set_floor(&mut self, x: u32, y: u32, h: f32) {
        if x < self.width && y < self.height {
            self.floor_heights[(y * self.width + x) as usize] = h;
        }
    }

    /// Sets the ceiling height at (x, y).
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `h` — `f32`.
    pub fn set_ceiling(&mut self, x: u32, y: u32, h: f32) {
        if x < self.width && y < self.height {
            self.ceiling_heights[(y * self.width + x) as usize] = h;
        }
    }

    /// Returns the floor height at (x, y). Returns 0.0 for out-of-bounds.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `f32`.
    pub fn floor_at(&self, x: u32, y: u32) -> f32 {
        if x < self.width && y < self.height {
            self.floor_heights[(y * self.width + x) as usize]
        } else {
            0.0
        }
    }

    /// Returns the ceiling height at (x, y). Returns 1.0 for out-of-bounds.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    ///
    /// # Returns
    /// `f32`.
    pub fn ceiling_at(&self, x: u32, y: u32) -> f32 {
        if x < self.width && y < self.height {
            self.ceiling_heights[(y * self.width + x) as usize]
        } else {
            1.0
        }
    }

    /// Sets the floor height for a rectangular region.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `w` — `u32`.
    /// - `h` — `u32`.
    /// - `height` — `f32`.
    pub fn set_floor_rect(&mut self, x: u32, y: u32, w: u32, h: u32, height: f32) {
        for cy in y..y.saturating_add(h) {
            for cx in x..x.saturating_add(w) {
                self.set_floor(cx, cy, height);
            }
        }
    }

    /// Sets the ceiling height for a rectangular region.
    ///
    /// # Parameters
    /// - `x` — `u32`.
    /// - `y` — `u32`.
    /// - `w` — `u32`.
    /// - `h` — `u32`.
    /// - `height` — `f32`.
    pub fn set_ceiling_rect(&mut self, x: u32, y: u32, w: u32, h: u32, height: f32) {
        for cy in y..y.saturating_add(h) {
            for cx in x..x.saturating_add(w) {
                self.set_ceiling(cx, cy, height);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_heights() {
        let hm = HeightMap::new(4, 4);
        assert!((hm.floor_at(0, 0)).abs() < 1e-5);
        assert!((hm.ceiling_at(0, 0) - 1.0).abs() < 1e-5);
    }

    #[test]
    fn test_set_floor_ceiling() {
        let mut hm = HeightMap::new(4, 4);
        hm.set_floor(1, 2, 0.5);
        hm.set_ceiling(1, 2, 0.8);
        assert!((hm.floor_at(1, 2) - 0.5).abs() < 1e-5);
        assert!((hm.ceiling_at(1, 2) - 0.8).abs() < 1e-5);
    }

    #[test]
    fn test_out_of_bounds() {
        let hm = HeightMap::new(4, 4);
        assert!((hm.floor_at(10, 10)).abs() < 1e-5);
        assert!((hm.ceiling_at(10, 10) - 1.0).abs() < 1e-5);
    }

    #[test]
    fn test_set_rect() {
        let mut hm = HeightMap::new(8, 8);
        hm.set_floor_rect(2, 2, 3, 3, 0.25);
        assert!((hm.floor_at(3, 3) - 0.25).abs() < 1e-5);
        assert!((hm.floor_at(0, 0)).abs() < 1e-5);
    }
}
