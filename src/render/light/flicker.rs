//! Built-in flicker effect configuration for lights.

/// Built-in flicker effect that modulates light intensity over time.
///
/// # Fields
/// - `enabled` — `bool`.
/// - `speed` — `f32`.
/// - `strength` — `f32`.
/// - `phase` — `f32`.
///
/// When enabled, the engine modulates `intensity` each frame by:
/// `intensity * (1.0 + strength * sin(phase))`.
/// The `phase` field auto-advances by `speed * dt` each tick.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct FlickerConfig {
    /// Whether the flicker effect is active.
    pub enabled: bool,
    /// Speed of flicker oscillation in radians per second (default 8.0).
    pub speed: f32,
    /// Amplitude of flicker as a fraction of base intensity (default 0.15).
    pub strength: f32,
    /// Current oscillation phase in radians (auto-advances each frame).
    pub phase: f32,
}

impl FlickerConfig {
    /// Creates a new enabled `FlickerConfig` with the given speed and strength.
    ///
    /// # Parameters
    /// - `speed` — `f32`.
    /// - `strength` — `f32`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(speed: f32, strength: f32) -> Self {
        Self {
            enabled: true,
            speed,
            strength,
            phase: 0.0,
        }
    }

    /// Computes the intensity multiplier for the current phase.
    ///
    /// # Returns
    /// `f32`.
    pub fn multiplier(&self) -> f32 {
        if self.enabled {
            1.0 + self.strength * self.phase.sin()
        } else {
            1.0
        }
    }

    /// Advances the phase by `dt` seconds.
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    pub fn advance(&mut self, dt: f32) {
        if self.enabled {
            self.phase += self.speed * dt;
            // Keep phase in [0, 2π) to prevent float overflow over long sessions.
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
