//! Entity/ECS module — lightweight entity-component-system with ID recycling,
//! bitmap tags, layers, blueprints, and system dispatch.

/// Universe — entity management with ID recycling, components, tags, and systems.
pub mod universe;
/// Generic relationship system for entity pairs.
pub mod relationships;

pub use relationships::{Relationship, RelationshipManager, RelationType};
pub use universe::{deep_copy_table, Universe};
