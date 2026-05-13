#[derive(Debug, Clone)]
pub struct AmbientState {
    pub enabled: bool,
    pub color: [f32; 4],
    pub time_of_day: f32,
}
impl Default for AmbientState {
    fn default() -> Self {
        Self {
            enabled: false,
            color: [1.0, 1.0, 1.0, 1.0],
            time_of_day: 12.0,
        }
    }
}
impl AmbientState {
    pub fn compute_color_from_time(&self) -> [f32; 4] {
        let t = self.time_of_day.rem_euclid(24.0);
        let (r, g, b) = if t < 5.0 {
            (0.1, 0.1, 0.3)
        } else if t < 7.0 {
            let f = (t - 5.0) / 2.0;
            (0.1 + f * 0.9, 0.1 + f * 0.7, 0.3 + f * 0.3)
        } else if t < 17.0 {
            (1.0, 0.8, 0.6)
        } else if t < 19.0 {
            let f = (t - 17.0) / 2.0;
            (1.0 - f * 0.9, 0.8 - f * 0.7, 0.6 - f * 0.3)
        } else {
            (0.1, 0.1, 0.3)
        };
        [r, g, b, 1.0]
    }
}
