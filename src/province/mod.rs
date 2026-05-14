//! Province subsystem: pixel-map political geography — registry, topology, rendering, and metadata import.
//! Owns ProvinceRegistry (style + geometry), adjacency graph, GPU bridge, and import pipeline.
//! Does not own pathfinding, AI, or game-logic rules.

/// Border classification: derive BorderClass from two adjacent province styles.
pub mod borders;
/// Binary-format geometry cache for province spans and border segments.
pub mod cache;
/// Change and event enums emitted by ProvinceRegistry mutations.
pub mod events;
/// GPU record builder: packs province styles into upload-ready structs.
pub mod gpu_bridge;
/// Metadata import pipeline: colour-map PNG + CSV/TOML → ProvinceRegistry.
pub mod import;
/// Label centroid computation from province span runs.
pub mod labels;
/// Map mode enum and per-mode colour resolver.
pub mod map_modes;
/// Authoritative store for all province state, geometry, and change history.
pub mod registry;
/// RenderCommand generation for fills, borders, capitals, and text labels.
pub mod render;
/// Province adjacency graph built from pixel-scan output.
pub mod topology;
/// Core types: ProvinceId, BorderClass, ProvinceStyle, ProvinceSnapshot.
pub mod types;
/// Camera/view-transform helpers: fit, screen-to-map, cell lookup, zoom-at-point.
pub mod view_transform;

pub use events::{ProvinceChange, ProvinceEvent};
pub use import::{
    import_metadata_from_files, sanitize_marked_png, MarkerSanitizeOptions, MarkerSanitizeSummary,
    ProvinceMetadataImportOptions, ProvinceMetadataImportSummary,
};
pub use registry::ProvinceRegistry;
pub use types::{BorderClass, ProvinceId, ProvinceSnapshot, ProvinceStyle};
pub use view_transform::{fit_camera_to_screen, map_to_cell, screen_to_map, zoom_camera_at};
