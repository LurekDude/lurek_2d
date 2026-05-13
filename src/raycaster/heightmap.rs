pub struct HeightMap {
    width: u32,
    height: u32,
    floor_heights: Vec<f32>,
    ceiling_heights: Vec<f32>,
}
impl HeightMap {
    pub fn new(width: u32, height: u32) -> Self {
        let count = (width * height) as usize;
        Self {
            width,
            height,
            floor_heights: vec![0.0; count],
            ceiling_heights: vec![1.0; count],
        }
    }
    pub fn set_floor(&mut self, x: u32, y: u32, h: f32) {
        if x < self.width && y < self.height {
            self.floor_heights[(y * self.width + x) as usize] = h;
        }
    }
    pub fn set_ceiling(&mut self, x: u32, y: u32, h: f32) {
        if x < self.width && y < self.height {
            self.ceiling_heights[(y * self.width + x) as usize] = h;
        }
    }
    pub fn floor_at(&self, x: u32, y: u32) -> f32 {
        if x < self.width && y < self.height {
            self.floor_heights[(y * self.width + x) as usize]
        } else {
            0.0
        }
    }
    pub fn ceiling_at(&self, x: u32, y: u32) -> f32 {
        if x < self.width && y < self.height {
            self.ceiling_heights[(y * self.width + x) as usize]
        } else {
            1.0
        }
    }
    pub fn set_floor_rect(&mut self, x: u32, y: u32, w: u32, h: u32, height: f32) {
        for cy in y..y.saturating_add(h) {
            for cx in x..x.saturating_add(w) {
                self.set_floor(cx, cy, height);
            }
        }
    }
    pub fn set_ceiling_rect(&mut self, x: u32, y: u32, w: u32, h: u32, height: f32) {
        for cy in y..y.saturating_add(h) {
            for cx in x..x.saturating_add(w) {
                self.set_ceiling(cx, cy, height);
            }
        }
    }
}
