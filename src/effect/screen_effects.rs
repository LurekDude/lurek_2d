#[derive(Debug, Clone)]
pub struct FlashState {
    pub active: bool,
    pub color: [f32; 4],
    pub duration: f32,
    pub elapsed: f32,
}
impl Default for FlashState {
    fn default() -> Self {
        Self {
            active: false,
            color: [1.0, 1.0, 1.0, 1.0],
            duration: 0.2,
            elapsed: 0.0,
        }
    }
}
#[derive(Debug, Clone)]
pub struct ShakeState {
    pub active: bool,
    pub intensity: f32,
    pub duration: f32,
    pub elapsed: f32,
    pub offset_x: f32,
    pub offset_y: f32,
    seed: u32,
}
impl Default for ShakeState {
    fn default() -> Self {
        Self {
            active: false,
            intensity: 5.0,
            duration: 0.5,
            elapsed: 0.0,
            offset_x: 0.0,
            offset_y: 0.0,
            seed: 12345,
        }
    }
}
impl ShakeState {
    pub(crate) fn next_random(&mut self) -> f32 {
        self.seed ^= self.seed << 13;
        self.seed ^= self.seed >> 17;
        self.seed ^= self.seed << 5;
        (self.seed as f32 / u32::MAX as f32) * 2.0 - 1.0
    }
}
#[derive(Debug, Clone)]
pub struct FadeState {
    pub active: bool,
    pub color: [f32; 4],
    pub target_alpha: f32,
    pub duration: f32,
    pub elapsed: f32,
    pub start_alpha: f32,
}
impl Default for FadeState {
    fn default() -> Self {
        Self {
            active: false,
            color: [0.0, 0.0, 0.0, 0.0],
            target_alpha: 1.0,
            duration: 1.0,
            elapsed: 0.0,
            start_alpha: 0.0,
        }
    }
}
