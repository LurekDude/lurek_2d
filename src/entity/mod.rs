//! Entity/ECS module — lightweight entity-component-system with ID recycling,
//! bitmap tags, layers, blueprints, and system dispatch.
//!
//! This module is part of Lurek2D's `entity` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

/// Generic relationship system for entity pairs.
pub mod relationships;
/// Universe — entity management with ID recycling, components, tags, and systems.
pub mod universe;

pub use relationships::{RelationType, Relationship, RelationshipManager};
pub use universe::{deep_copy_table, Universe};
