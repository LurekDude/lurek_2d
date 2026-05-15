//! - Full-screen effect state machines: flash, shake, and fade.
//! - Each state tracks active flag, timing, and per-frame parameters.
//! - Deterministic PRNG for shake offsets without external RNG dependency.

#[derive(Debug, Clone)]
/// Tracks a time-limited full-screen flash overlay.
pub struct FlashState {
    /// Indicates whether the flash is currently active.
    pub active: bool,
    /// RGBA flash color, including the starting alpha.
    pub color: [f32; 4],
    /// Flash duration in seconds.
    pub duration: f32,
    /// Time already elapsed since the flash started.
    pub elapsed: f32,
}
impl Default for FlashState {
    /// Builds the default inactive flash state.
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
/// Tracks camera shake intensity, timing, and generated offsets.
pub struct ShakeState {
    /// Indicates whether shake offsets should currently be applied.
    pub active: bool,
    /// Peak shake amplitude in screen units.
    pub intensity: f32,
    /// Total shake duration in seconds.
    pub duration: f32,
    /// Time already elapsed since the shake started.
    pub elapsed: f32,
    /// Latest horizontal shake offset.
    pub offset_x: f32,
    /// Latest vertical shake offset.
    pub offset_y: f32,
    /// Internal PRNG state used for deterministic shake samples.
    seed: u32,
}
impl Default for ShakeState {
    /// Builds the default inactive shake state.
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
    /// Advances the shake PRNG and returns a sample in the `[-1, 1]` range.
    pub(crate) fn next_random(&mut self) -> f32 {
        self.seed ^= self.seed << 13;
        self.seed ^= self.seed >> 17;
        self.seed ^= self.seed << 5;
        (self.seed as f32 / u32::MAX as f32) * 2.0 - 1.0
    }
}
#[derive(Debug, Clone)]
/// Tracks a timed fade toward a target alpha value.
pub struct FadeState {
    /// Indicates whether the fade is currently advancing.
    pub active: bool,
    /// RGBA fade color with the current interpolated alpha.
    pub color: [f32; 4],
    /// Alpha value that the fade interpolates toward.
    pub target_alpha: f32,
    /// Fade duration in seconds.
    pub duration: f32,
    /// Time already elapsed since the fade started.
    pub elapsed: f32,
    /// Alpha value captured at fade start for interpolation.
    pub start_alpha: f32,
}
impl Default for FadeState {
    /// Builds the default inactive fade state.
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
