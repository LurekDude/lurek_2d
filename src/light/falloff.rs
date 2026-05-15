//! - Radial intensity falloff shapes applied on top of distance attenuation.
//! - Variants control how brightness decreases from a light's center to its radius edge.

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
