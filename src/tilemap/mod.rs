//! Tilemap engine module — TileSet, TileMap, AutoTileSheet, IsoMap, ChunkMap, TMX loader, and procedural generation types.

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
