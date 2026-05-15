//! - Sine-based flicker configuration that modulates light intensity over time.
//! - Phase accumulates each frame and wraps at TAU for continuous oscillation.
//! - Strength controls peak deviation from base intensity; speed sets radians per second.
//! - Disabled by default; enable to animate torches, candles, or neon lights.

/// Sine-based flicker config that modulates a light's intensity by a small oscillating factor.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct FlickerConfig {
    /// Whether flicker is active; when false, `multiplier()` always returns 1.0.
    pub enabled: bool,
    /// Oscillation frequency in radians per second.
    pub speed: f32,
    /// Peak deviation from 1.0; e.g. 0.15 gives range [0.85, 1.15].
    pub strength: f32,
    /// Current phase in radians, advanced by `advance`.
    pub phase: f32,
}
impl FlickerConfig {
    /// Create an enabled flicker with given speed and strength; phase starts at 0.
    pub fn new(speed: f32, strength: f32) -> Self {
        Self {
            enabled: true,
            speed,
            strength,
            phase: 0.0,
        }
    }
    /// Return the current intensity multiplier; returns 1.0 when disabled.
    pub fn multiplier(&self) -> f32 {
        if self.enabled {
            1.0 + self.strength * self.phase.sin()
        } else {
            1.0
        }
    }
    /// Advance the flicker phase by `dt` seconds, wrapping at TAU.
    pub fn advance(&mut self, dt: f32) {
        if self.enabled {
            self.phase += self.speed * dt;
            self.phase %= std::f32::consts::TAU;
        }
    }
}

/// Provides a disabled flicker with default speed=8.0 and strength=0.15.
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
