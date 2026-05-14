//! Variable floor and ceiling height map for the raycaster. Stores per-tile height
//! values (0.0=ground level, 1.0=full cell height) used by `build_scene` to offset
//! the floor and ceiling planes. Does not own rendering or tile blocking logic.

/// Per-tile floor and ceiling height overrides for a raycaster map.
pub struct HeightMap {
    /// Map width in tiles.
    width: u32,
    /// Map height in tiles.
    height: u32,
    /// Floor height per tile, 0.0 = default ground level.
    floor_heights: Vec<f32>,
    /// Ceiling height per tile, 1.0 = default ceiling level.
    ceiling_heights: Vec<f32>,
}
impl HeightMap {
    /// Create a new `HeightMap` with default floor heights 0.0 and ceiling heights 1.0.
    pub fn new(width: u32, height: u32) -> Self {
        let count = (width * height) as usize;
        Self {
            width,
            height,
            floor_heights: vec![0.0; count],
            ceiling_heights: vec![1.0; count],
        }
    }
    /// Set the floor height for tile `(x, y)`; silently ignores out-of-bounds coordinates.
    pub fn set_floor(&mut self, x: u32, y: u32, h: f32) {
        if x < self.width && y < self.height {
            self.floor_heights[(y * self.width + x) as usize] = h;
        }
    }
    /// Set the ceiling height for tile `(x, y)`; silently ignores out-of-bounds coordinates.
    pub fn set_ceiling(&mut self, x: u32, y: u32, h: f32) {
        if x < self.width && y < self.height {
            self.ceiling_heights[(y * self.width + x) as usize] = h;
        }
    }
    /// Return the floor height at tile `(x, y)`, or 0.0 for out-of-bounds coordinates.
    pub fn floor_at(&self, x: u32, y: u32) -> f32 {
        if x < self.width && y < self.height {
            self.floor_heights[(y * self.width + x) as usize]
        } else {
            0.0
        }
    }
    /// Return the ceiling height at tile `(x, y)`, or 1.0 for out-of-bounds coordinates.
    pub fn ceiling_at(&self, x: u32, y: u32) -> f32 {
        if x < self.width && y < self.height {
            self.ceiling_heights[(y * self.width + x) as usize]
        } else {
            1.0
        }
    }
    /// Set the floor height for all tiles in the rectangle `(x, y, w, h)` to `height`.
    pub fn set_floor_rect(&mut self, x: u32, y: u32, w: u32, h: u32, height: f32) {
        for cy in y..y.saturating_add(h) {
            for cx in x..x.saturating_add(w) {
                self.set_floor(cx, cy, height);
            }
        }
    }
    /// Set the ceiling height for all tiles in the rectangle `(x, y, w, h)` to `height`.
    pub fn set_ceiling_rect(&mut self, x: u32, y: u32, w: u32, h: u32, height: f32) {
        for cy in y..y.saturating_add(h) {
            for cx in x..x.saturating_add(w) {
                self.set_ceiling(cx, cy, height);
            }
        }
    }
}
