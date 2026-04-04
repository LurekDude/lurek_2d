//! Ray hit result from DDA grid traversal.
//!
//! Contains the [`RayHit`] struct returned by [`super::Raycaster2D::cast_ray()`]
//! and [`super::Raycaster2D::cast_rays()`].

/// Result of a single ray cast.
///
/// Returned by the DDA raycaster when a ray hits a wall or reaches its maximum
/// distance without hitting anything (`hit = false`).
///
/// # Fields
/// - `distance` — `f32`.
/// - `raw_distance` — `f32`.
/// - `cell_value` — `u32`.
/// - `side` — `u8`.
/// - `tex_u` — `f32`.
/// - `hit_x` — `f32`.
/// - `hit_y` — `f32`.
/// - `hit` — `bool`.
#[derive(Debug, Clone)]
pub struct RayHit {
    /// Perpendicular wall distance (fisheye-corrected).
    pub distance: f32,
    /// Uncorrected Euclidean distance.
    pub raw_distance: f32,
    /// Wall type (>0 = wall).
    pub cell_value: u32,
    /// 0 = horizontal hit, 1 = vertical hit.
    pub side: u8,
    /// Texture U coordinate in [0, 1].
    pub tex_u: f32,
    /// World-space hit point X.
    pub hit_x: f32,
    /// World-space hit point Y.
    pub hit_y: f32,
    /// Whether the ray actually hit a wall.
    pub hit: bool,
}
