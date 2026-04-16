//! Minimap — real-time overhead map with configurable markers and region tracking. data structures for overhead map displays (Tier 2).
//!
//! Provides a grid-based minimap with terrain coloring, fog of war,
//! tracked objects, pings, markers, and viewport rectangle overlay.
//!
//! This is a **pure CPU data-model module** -- it has no GPU dependencies.
//!
//! Sub-files: types.rs for supporting enums/structs;
//! minimap.rs for the Minimap data model.

/// Core Minimap data model holding region bounds, markers, and camera viewport.
#[allow(clippy::module_inception)]
pub mod minimap;
/// GPU render-command generation for the minimap overlay.
pub mod render;
/// Supporting type definitions: enums and plain data structs.
pub mod types;

pub use minimap::Minimap;
pub use types::{
    ColorMode, FogLevel, LayerData, MarkerAnimation, MinimapMarker, MinimapObject,
    MinimapObjectType, MinimapPing, OverlayPath, OverlayShape,
};
