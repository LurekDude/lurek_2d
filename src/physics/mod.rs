//! Physics simulation module backed by rapier2d.
//!
//! Provides rigid-body simulation with circles, rectangles, sensors,
//! raycasting, joints, and collision event recording.
//!
//! This module is part of Luna2D's `physics` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// Body types, shapes, and the `Body` struct used by the physics world.
pub mod body;
/// Collision event structs returned by `World::get_collision_events`.
pub mod collision;
/// Extended shape types: Polygon, Edge, and Chain colliders.
pub mod shape;
/// The `World` struct and all simulation management: bodies, joints, raycasting, contacts.
pub mod world;

pub use body::{Body, BodyShape, BodyType};
pub use collision::CollisionInfo;
pub use shape::{Shape, StandaloneShape};
// Re-export BodyContact as CollisionEvent to preserve the existing public API.
pub use world::BodyContact as CollisionEvent;
pub use world::{ContactInfo, RaycastHit, World};
