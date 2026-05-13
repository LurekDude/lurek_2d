#[derive(Clone)]
pub struct LightTransition {
    pub from_color: [f32; 4],
    pub to_color: [f32; 4],
    pub from_intensity: f32,
    pub to_intensity: f32,
    pub from_radius: f32,
    pub to_radius: f32,
    pub duration: f32,
    pub elapsed: f32,
    pub active: bool,
}
impl LightTransition {
    pub fn new(
        from_color: [f32; 4],
        to_color: [f32; 4],
        from_intensity: f32,
        to_intensity: f32,
        from_radius: f32,
        to_radius: f32,
        duration: f32,
    ) -> Self {
        LightTransition {
            from_color,
            to_color,
            from_intensity,
            to_intensity,
            from_radius,
            to_radius,
            duration: duration.max(1e-6),
            elapsed: 0.0,
            active: true,
        }
    }
    pub fn update(&mut self, dt: f32) -> Option<([f32; 4], f32, f32)> {
        if !self.active {
            return None;
        }
        self.elapsed += dt;
        let t = if self.elapsed >= self.duration {
            self.active = false;
            1.0_f32
        } else {
            (self.elapsed / self.duration).clamp(0.0, 1.0)
        };
        let lerp = |a: f32, b: f32| a + (b - a) * t;
        let color = [
            lerp(self.from_color[0], self.to_color[0]),
            lerp(self.from_color[1], self.to_color[1]),
            lerp(self.from_color[2], self.to_color[2]),
            lerp(self.from_color[3], self.to_color[3]),
        ];
        Some((
            color,
            lerp(self.from_intensity, self.to_intensity),
            lerp(self.from_radius, self.to_radius),
        ))
    }
    pub fn progress(&self) -> f32 {
        if self.duration <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration).clamp(0.0, 1.0)
        }
    }
}
