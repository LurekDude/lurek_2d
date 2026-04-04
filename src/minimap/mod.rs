//! Minimap data structures for overhead map displays (Tier 2).
//!
//! Provides a grid-based minimap with terrain coloring, fog of war,
//! tracked objects, pings, markers, and viewport rectangle overlay.
//!
//! This is a **pure CPU data-model module** -- it has no GPU dependencies.
//!
//! Sub-files: types.rs for supporting enums/structs;
//! minimap.rs for the Minimap data model.

/// Core Minimap data model.
#[allow(clippy::module_inception)]
pub mod minimap;
/// Supporting type definitions: enums and plain data structs.
pub mod types;

pub use minimap::Minimap;
pub use types::{
    ColorMode, FogLevel, MinimapMarker, MinimapObject, MinimapObjectType, MinimapPing,
};
