//! Light blend mode enum for controlling how light color mixes with the scene.

/// How light color mixes with the scene.
///
/// # Variants
/// - `Add` — Add variant.
/// - `Sub` — Sub variant.
/// - `Mix` — Mix variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum LightBlendMode {
    /// Additive blending — brightens the scene under the light.
    #[default]
    Add,
    /// Subtractive blending — darkens the scene under the light.
    Sub,
    /// Lerp blending — mixes light color with scene by intensity.
    Mix,
}
