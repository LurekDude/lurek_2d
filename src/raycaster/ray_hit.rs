//! `RayHit` record produced by a single DDA ray step. Carries all data needed
//! by `build_scene` and `projection` to draw a wall slice: distance, texture
//! coordinate, side, hit position, and the cell value of the struck wall.

/// Result record for one DDA ray; produced by `Raycaster2D::cast_ray`.
#[derive(Debug, Clone)]
pub struct RayHit {
    /// Fish-eye-corrected perpendicular distance from the camera plane to the wall.
    pub distance: f32,
    /// Euclidean ray travel distance before fish-eye correction.
    pub raw_distance: f32,
    /// Tile value of the wall cell that was hit.
    pub cell_value: u32,
    /// Alpha of the wall type; 1.0 = fully opaque, < 1.0 = transparent/glass.
    pub alpha: f32,
    /// Hit side: 0 = X-aligned face, 1 = Y-aligned face.
    pub side: u8,
    /// Horizontal texture coordinate at the hit point, 0.0..1.0.
    pub tex_u: f32,
    /// World X coordinate of the exact hit point.
    pub hit_x: f32,
    /// World Y coordinate of the exact hit point.
    pub hit_y: f32,
    /// True when the ray struck a solid or semi-transparent wall before `max_dist`.
    pub hit: bool,
}
