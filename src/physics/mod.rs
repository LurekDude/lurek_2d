//! Physics simulation module backed by rapier2d.
//!
//! Provides rigid-body simulation with circles, rectangles, sensors,
//! raycasting, joints, and collision event recording.
//!
//! This module is part of Lurek2D's `physics` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

/// Body types, shapes, and the `Body` struct used by the physics world.
pub mod body;
/// Falling-sand cellular automaton independent of rapier.
pub mod cellular;
/// Collision event structs returned by `World::get_collision_events`.
pub mod collision;
/// Debug render commands and image export for the physics world.
pub mod render;
/// Extended shape types: Polygon, Edge, and Chain colliders.
pub mod shape;
/// Destructible terrain: bitgrid with chunked static physics colliders.
pub mod terrain;
/// The `World` struct and all simulation management: bodies, joints, raycasting, contacts.
pub mod world;
/// Gravity and damping zones applied before each rapier pipeline step.
pub mod zone;
/// Lightweight stateless geometric overlap helpers. No physics world required.
pub mod collision_helpers;

pub use body::{Body, BodyShape, BodyType};
pub use cellular::{default_palette, CellType, CellularWorld};
pub use collision::CollisionInfo;
pub use shape::{Shape, StandaloneShape};
pub use terrain::TerrainMap;
// Re-export BodyContact as CollisionEvent to preserve the existing public API.
pub use world::BodyContact as CollisionEvent;
pub use world::{ContactInfo, PhysicsShapeSnapshot, RaycastHit, World};
pub use zone::{PhysicsZone, ZoneBoundary, ZoneEvent, ZoneEventKind, ZoneGravityMode};
pub use collision_helpers::{test_aabb, test_circles, test_point_aabb, test_circle_aabb};
