//! Entity/ECS module — lightweight entity-component-system with ID recycling,
//! bitmap tags, layers, blueprints, and system dispatch.
//!
//! This module is part of Luna2D's `entity` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// Universe — entity management with ID recycling, components, tags, and systems.
pub mod universe;
/// Generic relationship system for entity pairs.
pub mod relationships;

pub use relationships::{Relationship, RelationshipManager, RelationType};
pub use universe::{deep_copy_table, Universe};
