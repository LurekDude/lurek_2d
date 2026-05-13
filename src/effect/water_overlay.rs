#[derive(Debug, Clone)]
pub struct WaterOverlayState {
    pub enabled: bool,
    pub amplitude: f32,
    pub frequency: f32,
    pub speed: f32,
    pub tint_r: f32,
    pub tint_g: f32,
    pub tint_b: f32,
    pub tint_strength: f32,
    pub depth_r: f32,
    pub depth_g: f32,
    pub depth_b: f32,
    pub depth_strength: f32,
    pub time: f32,
}
impl Default for WaterOverlayState {
    fn default() -> Self {
        Self {
            enabled: false,
            amplitude: 0.004,
            frequency: 12.0,
            speed: 1.5,
            tint_r: 0.1,
            tint_g: 0.3,
            tint_b: 0.8,
            tint_strength: 0.15,
            depth_r: 0.0,
            depth_g: 0.1,
            depth_b: 0.4,
            depth_strength: 0.0,
            time: 0.0,
        }
    }
}
impl WaterOverlayState {
    pub fn new() -> Self {
        Self::default()
    }
    pub fn update(&mut self, dt: f32) {
        if self.enabled {
            self.time += dt * self.speed;
        }
    }
    pub fn reset(&mut self) {
        *self = Self::default();
    }
}
