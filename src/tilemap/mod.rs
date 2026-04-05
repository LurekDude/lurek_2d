//! Tilemap engine module — TileSet, TileMap, AutoTileSheet, IsoMap, ChunkMap, TMX loader, and procedural generation types.
//!
//! This module is part of Luna2D's `tilemap` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// Auto-tile atlas with bitmask-based tile selection.
pub mod autotile_sheet;
/// Sparse chunk-based tilemap storage for large and infinite maps.
pub mod chunk;
/// Coordinate helpers for tile ↔ world conversions.
pub mod coords;
/// Multi-level isometric tilemap with painter's-algorithm draw order.
pub mod isomap;
/// Procedural map generation scripts and room placement.
pub mod mapgen;
#[allow(clippy::module_inception)]
/// Core tilemap: layers, tile CRUD, sweep queries, and serialization.
pub mod tilemap;
/// Tile set definition with per-tile properties and animation frames.
pub mod tileset;
/// Tiled TMX/TSX map format parser.
pub mod tmx;

pub use autotile_sheet::{AutoTileLayout, AutoTileSheet};
pub use chunk::ChunkMap;
pub use coords::*;
pub use isomap::{IsoDrawItem, IsoLevel, IsoMap, IsoTile, IsoTilePart};
pub use mapgen::{
    Edge, LayerMode, MapBlock, MapGen, MapGroup, MapOrientation, MapScript, MapSize, MapZone,
    ScriptStep, StepType,
};
pub use tilemap::{SweepResult, TileLayer, TileMap};
pub use tileset::{TileAnimFrame, TileSet};
pub use tmx::{
    load_tmx, TmxLayer, TmxMap, TmxObject, TmxObjectLayer, TmxOrientation, TmxTileLayer, TmxTileset,
};
/// Grid-direction walker for tile stepping.
pub mod tile_walker;
/// Optimized renderer data model for large tile-based maps with chunking and LOD.
pub mod large_map_renderer;
pub use large_map_renderer::{LargeMapRenderer, MapChunk};
/// Polygon map with named regions, hit detection, and labeling.
pub mod polygon_map;
pub use polygon_map::{PolygonMap, PolygonRegion};
