//! Atmospheric overlay state types for clouds, fog, haze, grain, and lightning.

#[derive(Debug, Clone)]
/// Configures animated cloud overlay generation.
pub struct CloudState {
    /// Enables cloud overlay updates and rendering.
    pub enabled: bool,
    /// Target number of cloud sprites or bands to render.
    pub count: u32,
    /// Horizontal cloud scroll speed in screen units per second.
    pub speed: f32,
    /// Uniform scale multiplier for cloud geometry.
    pub scale: f32,
    /// Alpha multiplier applied to cloud rendering.
    pub opacity: f32,
    /// Current scroll offset accumulated by updates.
    pub offset: f32,
}
impl Default for CloudState {
    /// Builds the default disabled cloud overlay configuration.
    fn default() -> Self {
        Self {
            enabled: false,
            count: 5,
            speed: 20.0,
            scale: 1.0,
            opacity: 0.3,
            offset: 0.0,
        }
    }
}
#[derive(Debug, Clone)]
/// Configures full-screen fog tint and density.
pub struct FogState {
    /// Enables fog blending in the overlay.
    pub enabled: bool,
    /// Strength of the fog blend factor.
    pub density: f32,
    /// RGBA fog color used for the blend.
    pub color: [f32; 4],
}
impl Default for FogState {
    /// Builds the default disabled fog configuration.
    fn default() -> Self {
        Self {
            enabled: false,
            density: 0.3,
            color: [0.7, 0.7, 0.8, 1.0],
        }
    }
}
#[derive(Debug, Clone)]
/// Controls screen-space heat haze distortion intensity.
pub struct HeatHazeState {
    /// Enables the heat haze overlay pass.
    pub enabled: bool,
    /// Distortion strength applied by the haze effect.
    pub intensity: f32,
}
impl Default for HeatHazeState {
    /// Builds the default disabled heat haze state.
    fn default() -> Self {
        Self {
            enabled: false,
            intensity: 0.5,
        }
    }
}
#[derive(Debug, Clone)]
/// Controls vignette darkening around the screen edges.
pub struct VignetteState {
    /// Enables vignette rendering.
    pub enabled: bool,
    /// Multiplier applied to vignette opacity.
    pub strength: f32,
}
impl Default for VignetteState {
    /// Builds the default disabled vignette state.
    fn default() -> Self {
        Self {
            enabled: false,
            strength: 0.5,
        }
    }
}
#[derive(Debug, Clone)]
/// Controls full-screen film grain intensity.
pub struct FilmGrainState {
    /// Enables film grain rendering.
    pub enabled: bool,
    /// Grain amount applied during rendering.
    pub intensity: f32,
}
impl Default for FilmGrainState {
    /// Builds the default disabled film grain state.
    fn default() -> Self {
        Self {
            enabled: false,
            intensity: 0.3,
        }
    }
}
#[derive(Debug, Clone)]
/// Tracks a short-lived lightning flash overlay.
pub struct LightningState {
    /// Indicates whether the lightning flash is currently active.
    pub active: bool,
    /// RGBA flash color used while the effect is active.
    pub color: [f32; 4],
    /// Time already elapsed since the flash started.
    pub elapsed: f32,
    /// Total flash duration in seconds.
    pub duration: f32,
}
impl Default for LightningState {
    /// Builds the default inactive lightning flash state.
    fn default() -> Self {
        Self {
            active: false,
            color: [0.9, 0.9, 1.0, 0.8],
            elapsed: 0.0,
            duration: 0.15,
        }
    }
}
