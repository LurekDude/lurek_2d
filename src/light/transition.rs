/// Time-based linear tween that interpolates a light's color, intensity, and radius.
#[derive(Clone)]
pub struct LightTransition {
    /// Starting RGBA color for the interpolation.
    pub from_color: [f32; 4],
    /// Target RGBA color at the end of the transition.
    pub to_color: [f32; 4],
    /// Starting intensity value.
    pub from_intensity: f32,
    /// Target intensity value at the end of the transition.
    pub to_intensity: f32,
    /// Starting radius value.
    pub from_radius: f32,
    /// Target radius value at the end of the transition.
    pub to_radius: f32,
    /// Total transition duration in seconds; clamped to ≥1e-6.
    pub duration: f32,
    /// Accumulated elapsed time in seconds since the transition started.
    pub elapsed: f32,
    /// Whether the transition is still running; set to `false` when elapsed >= duration.
    pub active: bool,
}
impl LightTransition {
    /// Create a new active transition between the given from/to values over `duration` seconds.
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
    /// Advance by `dt` seconds and return `Some((color, intensity, radius))`; returns `None` if inactive.
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
    /// Return the normalised progress in [0.0, 1.0]; returns 1.0 when duration is zero.
    pub fn progress(&self) -> f32 {
        if self.duration <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration).clamp(0.0, 1.0)
        }
    }
}
