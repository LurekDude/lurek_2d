pub struct DecalSurface {
    pub width: u32,
    pub height: u32,
}
impl DecalSurface {
    pub fn new(width: u32, height: u32) -> Self {
        Self { width, height }
    }
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }
    pub fn get_width(&self) -> u32 {
        self.width
    }
    pub fn get_height(&self) -> u32 {
        self.height
    }
}
