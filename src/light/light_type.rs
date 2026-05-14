//! Light type discriminant distinguishing point, directional, and spot 2D lights.
//! Used by `Light2D` and read by `LightWorld` to select the correct illumination model.
//! Does not own light parameters — only the variant that selects the math path.

/// Discriminant for the geometric illumination model used by a `Light2D`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum LightType {
    /// Omnidirectional point light; illuminates equally in all directions (default).
    #[default]
    Point,
    /// Infinite-distance directional light; all rays parallel to `direction`.
    Directional,
    /// Cone-shaped spot light; intensity falls between `inner_angle` and `outer_angle`.
    Spot,
}
