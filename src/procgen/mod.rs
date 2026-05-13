//! Procedural world generation utilities.
//!
//! Cave maps, Voronoi diagrams, flood fill, Poisson disk sampling,
//! noise functions, dungeon generators, heightmaps, WFC, L-systems,
//! name generation, biome classification, and world-level topology graphs.

/// Biome classification layer over heightmap and noise data.
pub mod biome;
/// Binary Space Partitioning dungeon generator.
pub mod bsp;
/// Cellular automata cave/dungeon generation.
pub mod cellular;
/// Shared scalar-map color conversion helpers.
pub mod color;
/// BFS flood fill on a flat grid.
pub mod flood_fill;
/// Heightmap generation using fractal noise, erosion, and normalization.
pub mod heightmap;
/// Linear congruential generator for deterministic procgen.
pub mod lcg;
/// L-system string rewriter for procedural plant/structure generation.
pub mod lsystem;
/// Markov chain name generator.
pub mod namegen;
/// Procedural noise functions and generators: Perlin, Simplex, Worley, fractal combinators.
pub mod noise;
/// Poisson disk sampling for point distribution.
pub mod poisson;
/// Procedural generation visualization: `NoiseGrid`.
pub mod render;
/// Rooms-and-corridors dungeon generator.
pub mod rooms;
/// Voronoi diagram generation with optional warp.
pub mod voronoi;
/// Wave Function Collapse tile grid generator.
pub mod wfc;
/// World-level topology graph with pathfinding and MST.
pub mod world_graph;

pub use biome::{biome_map_to_rgba, BiomeClassifier, BiomeRules, BiomeType};
pub use bsp::{
    bsp_dungeon, bsp_dungeon_with_prefabs, BspDungeon, BspOpts, BspPrefabStamp, BspRoom,
    PlacedBspPrefab,
};
pub use cellular::{cellular_automata, CellularOpts};
pub use color::scalar_map_to_rgba_bytes;
pub use flood_fill::flood_fill;
pub use heightmap::{Heightmap, HeightmapOpts};
pub use lsystem::LSystem;
pub use namegen::NameGen;
pub use noise::{
    fbm, generate_noise_map_parallel, perlin2d, perlin3d, perlin4d, perlin_noise_periodic,
    simplex2d, simplex_noise_2d, simplex_noise_3d, DistType, FractalType, MapGenOptions,
    NoiseGenerator, NoiseKind,
};
pub use poisson::poisson_disk;
pub use render::NoiseGrid;
pub use rooms::{
    rooms_dungeon, rooms_dungeon_with_prefabs, PlacedRoomPrefab, Room, RoomPrefabStamp,
    RoomsDungeon, RoomsOpts,
};
pub use voronoi::{voronoi_diagram, VoronoiOpts};
pub use wfc::{wfc_generate, WfcGrid, WfcOpts, WfcRules, WfcTile};
pub use world_graph::{generate_world_graph, WorldEdge, WorldGraph, WorldRegion};
