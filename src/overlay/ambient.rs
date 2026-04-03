/// Ambient lighting state with time-of-day colour cycling.
///
/// When `enabled` is `true`, `Overlay::update` calls
/// `compute_color_from_time()` each frame and stores the result back into
/// `color`. This means any manual writes to `color` will be overwritten
/// on the next update. To set the tint manually without cycling, set
/// `enabled = false` and write directly to `color`.
///
/// # Fields
/// - `enabled` — `bool` — Whether time-of-day colour cycling is active.
/// - `color` — `[f32; 4]` — Current ambient tint (RGBA); auto-computed when enabled.
/// - `time_of_day` — `f32` — Time of day in hours (0.0–24.0); drives `compute_color_from_time`.
#[derive(Debug, Clone)]
pub struct AmbientState {
    /// Whether ambient lighting is active.
    pub enabled: bool,
    /// Current ambient tint (RGBA).
    pub color: [f32; 4],
    /// Time of day (0.0–24.0).
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
    /// Computes the ambient colour from time-of-day.
    ///
    /// Uses a simple colour curve:
    /// - 0–5: night (dark blue tint)
    /// - 5–7: dawn (orange-pink)
    /// - 7–17: day (white)
    /// - 17–19: dusk (orange-red)
    /// - 19–24: night (dark blue tint)
    ///
    /// # Returns
    /// `[f32; 4]` — RGBA colour.
    pub fn compute_color_from_time(&self) -> [f32; 4] {
        let t = self.time_of_day.rem_euclid(24.0);
        let (r, g, b) = if t < 5.0 {
            // Night
            (0.1, 0.1, 0.3)
        } else if t < 7.0 {
            // Dawn: lerp from night to day
            let f = (t - 5.0) / 2.0;
            (
                0.1 + f * 0.9,
                0.1 + f * 0.7,
                0.3 + f * 0.3,
            )
        } else if t < 17.0 {
            // Day
            (1.0, 0.8, 0.6)
        } else if t < 19.0 {
            // Dusk: lerp from day to night
            let f = (t - 17.0) / 2.0;
            (
                1.0 - f * 0.9,
                0.8 - f * 0.7,
                0.6 - f * 0.3,
            )
        } else {
            // Night
            (0.1, 0.1, 0.3)
        };
        [r, g, b, 1.0]
    }
}
