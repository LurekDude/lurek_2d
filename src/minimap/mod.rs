//! Minimap subsystem: top-down overview rendering with markers, pings, fog, and overlays.
//! Owns the minimap state, its renderer, province-map integration, and all public types.
//! Does not own the main world camera or the 2D sprite renderer; it uses its own render pass.
//! Consumed by `src/lua_api/minimap_api.rs`.

#[allow(clippy::module_inception)]
/// Core minimap state and update logic.
pub mod minimap;
/// Adapter that bridges province-map data into minimap layer format.
pub mod province_adapter;
/// Pixel-buffer rendering for the minimap texture.
pub mod render;
/// Shared data types for markers, layers, overlays, fog, and pings.
pub mod types;

pub use minimap::Minimap;
pub use types::{
    ColorMode, FogLevel, LayerData, MarkerAnimation, MinimapMarker, MinimapObject,
    MinimapObjectType, MinimapPing, OverlayPath, OverlayShape,
};

