//! 2D physics subsystem: rigid bodies, shapes, collision detection, terrain, zones, and cellular worlds.
//! Wraps rapier2d 0.32; all public Lua-facing handles go through `World` — raw rapier handles are never exposed.
//! Does not own Lua bindings; those live in `src/lua_api/physics_api.rs`.

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
/// Static terrain tile-map.
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
