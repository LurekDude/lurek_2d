//! Water surface overlay with UV distortion and depth-tint controls.
//!
//! `WaterOverlayState` drives a full-screen water-distortion effect rendered
//! in the `lurek.overlay.water.*` Lua API. Unlike the weather sub-system it
//! does **not** spawn CPU particles — the distortion is entirely shader-based,
//! so `update` only advances the internal time accumulator used to animate
//! the wave pattern.

/// Full-screen water-surface overlay state.
///
/// The distortion is applied as a shader pass on the final composited frame.
/// Set `enabled = true` and tune the wave/tint parameters; call
/// `update(dt)` each frame to advance the animation clock.
///
/// # Fields
/// - `enabled` — `bool` — Whether the water overlay is rendered.
/// - `amplitude` — `f32` — Peak UV distortion offset (0.0–0.02 is typical).
/// - `frequency` — `f32` — Spatial wave frequency; higher = tighter ripples.
/// - `speed` — `f32` — Animation speed multiplier.
/// - `tint_r/g/b` — `f32` — Additive colour tint applied to the distorted sample.
/// - `tint_strength` — `f32` — Blend factor from original to tinted colour (0.0–1.0).
/// - `depth_r/g/b` — `f32` — Depth-fog colour shown in fully-opaque areas.
/// - `depth_strength` — `f32` — Depth tint strength (0.0–1.0).
/// - `time` — `f32` — Internal clock advanced by `update(dt)`.
#[derive(Debug, Clone)]
pub struct WaterOverlayState {
    /// Whether the water overlay is rendered.
    pub enabled: bool,
    /// Peak UV offset per wave (0.0–0.02).
    pub amplitude: f32,
    /// Spatial wave frequency.
    pub frequency: f32,
    /// Wave animation speed multiplier.
    pub speed: f32,
    /// Tint red channel.
    pub tint_r: f32,
    /// Tint green channel.
    pub tint_g: f32,
    /// Tint blue channel.
    pub tint_b: f32,
    /// Tint blend strength (0.0–1.0).
    pub tint_strength: f32,
    /// Depth fog red channel.
    pub depth_r: f32,
    /// Depth fog green channel.
    pub depth_g: f32,
    /// Depth fog blue channel.
    pub depth_b: f32,
    /// Depth fog blend strength (0.0–1.0).
    pub depth_strength: f32,
    /// Internal animation clock in seconds.
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
    /// Creates a new disabled `WaterOverlayState` with default wave parameters.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self::default()
    }

    /// Advances the animation clock by `dt` seconds.
    ///
    /// # Parameters
    /// - `dt` — `f32` — Frame delta time in seconds.
    pub fn update(&mut self, dt: f32) {
        if self.enabled {
            self.time += dt * self.speed;
        }
    }

    /// Resets all parameters and the animation clock to their defaults.
    pub fn reset(&mut self) {
        *self = Self::default();
    }
}
