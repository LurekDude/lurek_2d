//! Entity/ECS module — lightweight entity-component-system with ID recycling,
//! bitmap tags, layers, blueprints, and system dispatch.
//!
//! This module is part of Lurek2D's `ecs` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

/// Packed generational entity-id helpers.
pub mod generational_id;
/// Shared Lua table helper functions.
pub mod lua_table;
/// Generic relationship system for entity pairs.
pub mod relationships;
/// Universe — entity management with ID recycling, components, tags, and systems.
pub mod universe;

pub use generational_id::GenerationalId;
pub use lua_table::deep_copy_table;
pub use relationships::{RelationType, Relationship, RelationshipManager};
pub use universe::{SnapshotDiff, Universe};
