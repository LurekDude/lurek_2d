//! Collision query result type shared across detection helpers and the physics world.

use crate::math::Vec2;

/// Result of a collision detection query.
pub struct CollisionInfo {
    /// Depth of penetration in world units.
    pub penetration: f32,
    /// Collision normal pointing from B toward A.
    pub normal: Vec2,
}
