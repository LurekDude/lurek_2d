//! - Rapier2D-backed rigid-body physics: bodies, shapes, world stepping, and raycasting.
//! - Collision helpers (AABB, circle, point) and contact/event reporting.
//! - Terrain tile-maps, spatial trigger zones, and cellular-automaton simulation.

/// Rigid body management and handle types.
pub mod body;
/// Cellular automaton world simulation.
pub mod cellular;
/// Collision query and contact result types.
pub mod collision;
/// AABB, circle, and point-AABB collision helpers.
pub mod collision_helpers;
/// Debug render helpers for physics shapes.
pub mod render;
/// Shape definitions for bodies and standalone queries.
pub mod shape;
/// Static terrain tile-map. This module is publicly re-exported.
pub mod terrain;
/// Physics world, stepping, bodies, and raycasting.
pub mod world;
/// Spatial trigger zones with gravity and event tracking.
pub mod zone;
pub use body::{Body, BodyShape, BodyType};
pub use cellular::{default_palette, CellType, CellularWorld};
pub use collision::CollisionInfo;
pub use collision_helpers::{test_aabb, test_circle_aabb, test_circles, test_point_aabb};
pub use shape::{Shape, StandaloneShape};
pub use terrain::TerrainMap;
pub use world::BodyContact as CollisionEvent;
pub use world::{ContactInfo, PhysicsShapeSnapshot, RaycastHit, World};
pub use zone::{PhysicsZone, ZoneBoundary, ZoneEvent, ZoneEventKind, ZoneGravityMode};
