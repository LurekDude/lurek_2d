#[derive(Debug, Clone)]
/// Stores parameters for animated water distortion and tint overlays.
pub struct WaterOverlayState {
    /// Enables water overlay updates and rendering.
    pub enabled: bool,
    /// Distortion amplitude applied to the screen sample offset.
    pub amplitude: f32,
    /// Spatial wave frequency used by the distortion pattern.
    pub frequency: f32,
    /// Time scale applied when advancing the wave animation.
    pub speed: f32,
    /// Red channel of the shallow-water tint.
    pub tint_r: f32,
    /// Green channel of the shallow-water tint.
    pub tint_g: f32,
    /// Blue channel of the shallow-water tint.
    pub tint_b: f32,
    /// Blend strength of the tint overlay.
    pub tint_strength: f32,
    /// Red channel of the deep-water color shift.
    pub depth_r: f32,
    /// Green channel of the deep-water color shift.
    pub depth_g: f32,
    /// Blue channel of the deep-water color shift.
    pub depth_b: f32,
    /// Blend strength of the depth-based color shift.
    pub depth_strength: f32,
    /// Accumulated animation time used by the distortion function.
    pub time: f32,
}
impl Default for WaterOverlayState {
    /// Builds the default disabled water overlay state.
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
    /// Creates a water overlay with default parameters.
    pub fn new() -> Self {
        Self::default()
    }
    /// Advances the overlay animation clock while the effect is enabled.
    pub fn update(&mut self, dt: f32) {
        if self.enabled {
            self.time += dt * self.speed;
        }
    }
    /// Restores every water overlay parameter to its default value.
    pub fn reset(&mut self) {
        *self = Self::default();
    }
}
