#[derive(Debug, Clone, Copy, PartialEq)]
pub struct FlickerConfig {
    pub enabled: bool,
    pub speed: f32,
    pub strength: f32,
    pub phase: f32,
}
impl FlickerConfig {
    pub fn new(speed: f32, strength: f32) -> Self {
        Self {
            enabled: true,
            speed,
            strength,
            phase: 0.0,
        }
    }
    pub fn multiplier(&self) -> f32 {
        if self.enabled {
            1.0 + self.strength * self.phase.sin()
        } else {
            1.0
        }
    }
    pub fn advance(&mut self, dt: f32) {
        if self.enabled {
            self.phase += self.speed * dt;
            self.phase %= std::f32::consts::TAU;
        }
    }
}
impl Default for FlickerConfig {
    fn default() -> Self {
        Self {
            enabled: false,
            speed: 8.0,
            strength: 0.15,
            phase: 0.0,
        }
    }
}
