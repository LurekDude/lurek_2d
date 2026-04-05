//! Light type enum for point, directional, and spot lights.

/// The geometric shape of a light source.
///
/// # Variants
/// - `Point` — Point variant.
/// - `Directional` — Directional variant.
/// - `Spot` — Spot variant.
///
/// `Point` emits equally in all directions from a single position.
/// `Directional` casts parallel rays in a given direction with no positional falloff.
/// `Spot` emits a cone of light defined by inner and outer angles.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum LightType {
    /// Omnidirectional point light — emits equally in all directions.
    #[default]
    Point,
    /// Parallel-ray directional light — no positional falloff, only direction matters.
    Directional,
    /// Cone-shaped spot light — defined by direction plus inner/outer angles.
    Spot,
}
