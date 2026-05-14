//! Falloff mode enum for the radial intensity shape of a 2D light beyond the attenuation curve.
//! Used by `Light2D` and evaluated in `LightWorld` when building per-pixel intensity.
//! Does not own the actual curve math — the renderer applies the mode during light accumulation.

/// Radial intensity falloff shape applied on top of attenuation distance decay.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum FalloffMode {
    /// Linearly decreases intensity from center to radius boundary (default).
    #[default]
    Linear,
    /// Smooth-step curve: flat near center, steep at the boundary.
    Smooth,
    /// No radial falloff — uniform intensity within the light radius.
    Constant,
}
