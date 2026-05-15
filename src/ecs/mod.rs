//! - Lightweight ECS: entities with generational IDs, Lua-table components, tags, and blueprints.
//! - Relationship graph for parent/child, ownership, and custom link types between entities.
//! - Deep-copy and snapshot utilities for cloning Lua component tables.

/// Entity id packing and unpacking helpers.
pub mod generational_id;
/// Lua table cloning helpers for ECS snapshots and blueprints.
pub mod lua_table;
/// Relationship types and graph storage between entities.
pub mod relationships;
/// Core ECS storage for entities, components, tags, and blueprints.
pub mod universe;
pub use generational_id::GenerationalId;
pub use lua_table::deep_copy_table;
pub use relationships::{RelationType, Relationship, RelationshipManager};
pub use universe::{SnapshotDiff, Universe};
