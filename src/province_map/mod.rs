//! Province map module — spatial province data from colour-coded PNG images or definitions.
//!
//! A province map is a pure spatial data structure, like a tilemap — game-specific
//! data (owner, terrain type, politics) lives externally in the stats or entity modules.
//! Worldgen and minimap rendering are handled by game-developer code using the
//! `crate::math` Voronoi utilities and existing minimap infrastructure.

/// Core data structures: [`Province`], [`AdjacencyEdge`], [`ProvinceMap`].
pub mod core;
/// Province map loader from colour-coded PNG images.
pub mod loader;
/// Adjacency detection between provinces from the pixel grid.
pub mod adjacency;
/// Border segment extraction for province rendering.
pub mod borders;
/// Province centre-point calculation.
pub mod positions;
/// Map mode colour assignment for province rendering.
pub mod map_mode;
/// Province map event bus.
pub mod events;
/// Load province definitions from structured data (TOML tables, Lua tables).
pub mod definition_loader;
/// Bridge to convert adjacency data to a [`crate::graph::Graph`].
pub mod graph_bridge;

pub use core::{AdjacencyEdge, Province, ProvinceError, ProvinceMap};
pub use loader::color_to_id;
pub use adjacency::{detect_adjacency, detect_adjacency_with_tags};
pub use borders::{
    extract_all_borders, extract_borders_by_property, extract_borders_with_tag, BorderSegment,
    BorderStyle,
};
pub use positions::{calculate_all_positions, calculate_capital};
pub use map_mode::{resolve_colors, MapMode, MapModeColorFn};
pub use events::ProvinceMapEventBus;
pub use definition_loader::{load_from_definitions, ProvinceDefinition};
pub use graph_bridge::adjacency_to_graph;
