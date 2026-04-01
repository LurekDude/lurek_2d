//! Entity/ECS module — lightweight entity-component-system with ID recycling,
//! bitmap tags, layers, blueprints, and system dispatch.

/// universe.
pub mod universe;

pub use universe::{deep_copy_table, Universe};
