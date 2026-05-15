//! - Define the geometric illumination models available for 2D lights.
//! - Discriminate between point, directional, and spot light behavior.
//! - Drive intensity falloff and ray direction logic in the lighting pipeline.

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
