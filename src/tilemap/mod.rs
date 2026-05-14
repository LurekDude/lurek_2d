//! Tilemap subsystem: tile grids, tilesets, autotile sheets, isometric maps,
//! chunk-based large maps, TMX and LDtk import, procedural map generation,
//! polygon regions, tile-space coordinate helpers, and the walker iterator.
//! Does not own rendering or physics; callers route output to the render layer.

/// Autotile sprite-sheet layout and rule matching.
pub mod autotile_sheet;
/// Chunk-based storage for very large tile grids.
pub mod chunk;
/// Tile-space coordinate conversion helpers.
pub mod coords;
/// Isometric tile maps with layered `IsoTile` items.
pub mod isomap;
/// Large-map chunked renderer suitable for maps exceeding GPU texture limits.
pub mod large_map_renderer;
/// LDtk JSON level format import.
pub mod ldtk;
/// Procedural map generator using zones, groups, and scripted steps.
pub mod mapgen;
/// Polygon-region map for zone-based game maps.
pub mod polygon_map;
/// Render helpers converting tilemap data to `RenderCommand` sequences.
pub mod render;
/// Core `TileMap` and `TileLayer` types.
#[allow(clippy::module_inception)]
pub mod tilemap;
/// Tileset metadata and animation frame types.
pub mod tileset;
/// Tile-space walker/iterator over connected cells.
pub mod tile_walker;
/// Tiled TMX XML format import.
pub mod tmx;

/// Re-export autotile layout and sheet types for callers.
pub use autotile_sheet::{AutoTileLayout, AutoTileSheet};
/// Re-export chunk map type for callers.
pub use chunk::ChunkMap;
/// Re-export all coordinate helpers as a flat namespace.
pub use coords::*;
/// Re-export isometric map types for callers.
pub use isomap::{IsoDrawItem, IsoLevel, IsoMap, IsoTile, IsoTilePart};
/// Re-export the LDtk level loader function.
pub use ldtk::load_ldtk;
/// Re-export large-map renderer types.
pub use large_map_renderer::{LargeMapRenderer, MapChunk};
/// Re-export procedural map generation types.
pub use mapgen::{
    Edge, LayerMode, MapBlock, MapGen, MapGroup, MapOrientation, MapScript, MapSize, MapZone,
    ScriptStep, StepType,
};
/// Re-export polygon map types.
pub use polygon_map::{PolygonMap, PolygonRegion};
/// Re-export core tilemap types.
pub use tilemap::{SweepResult, TileLayer, TileMap};
/// Re-export tileset types.
pub use tileset::{TileAnimFrame, TileSet};
/// Re-export TMX import types and loader function.
pub use tmx::{
    load_tmx, TmxLayer, TmxMap, TmxObject, TmxObjectLayer, TmxOrientation, TmxTileLayer,
    TmxTileset,
};

