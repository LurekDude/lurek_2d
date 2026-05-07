//! Province engine module.
//!
//! Owns high-level province runtime state for political/terrain map rendering,
//! independent from concrete frontends (`globe`, `minimap`, `province_map` Lua lib).
//! Rendering backends (GPU/CPU) consume [`ProvinceSnapshot`] data from this module.

/// Border classification utilities.
pub mod borders;
/// Cache serialization helpers for province geometry.
pub mod cache;
/// Province domain events and change notifications.
pub mod events;
/// GPU-facing packed data builders.
pub mod gpu_bridge;
/// Province label/centroid helpers.
pub mod labels;
/// Province map preprocessing and metadata import helpers.
pub mod import;
/// Map-mode helpers for province shading.
pub mod map_modes;
/// Province runtime registry.
pub mod registry;
/// Province render command generation.
pub mod render;
/// Province graph/topology model.
pub mod topology;
/// Core public province types.
pub mod types;
/// Screen/map transform helpers for province cameras.
pub mod view_transform;

pub use events::{ProvinceChange, ProvinceEvent};
pub use import::{
	import_metadata_from_files, sanitize_marked_png, MarkerSanitizeOptions,
	MarkerSanitizeSummary, ProvinceMetadataImportOptions, ProvinceMetadataImportSummary,
};
pub use registry::ProvinceRegistry;
pub use types::{BorderClass, ProvinceId, ProvinceSnapshot, ProvinceStyle};
pub use view_transform::{fit_camera_to_screen, map_to_cell, screen_to_map, zoom_camera_at};
