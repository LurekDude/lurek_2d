//! Collision implementation for the `physics` subsystem.
//!
//! This module is part of Luna2D's `physics` subsystem and provides the implementation
//! details for collision-related operations and data management.
//! Key types exported from this module: `CollisionInfo`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.
//!
use crate::math::Vec2;

/// Collision contact data: penetration depth and separating normal.
///
/// Retained for backward compatibility; collision detection is now handled
/// by rapier2d internally. See `World::get_collision_events()` for events.
///
/// # Fields
/// - `penetration` — How much the two bodies overlap along the minimum separation axis.
/// - `normal` — Unit vector pointing from body B towards body A.
pub struct CollisionInfo {
    /// How much the two bodies overlap along the minimum separation axis.
    pub penetration: f32,
    /// Unit vector pointing from body B towards body A along the separation axis.
    pub normal: Vec2,
}
