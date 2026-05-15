//! - Procedural generation toolkit: noise, dungeons, heightmaps, and world graphs.
//! - Algorithms: Perlin/Simplex/Worley noise, BSP & room-scatter dungeons, cellular automata caves.
//! - Utilities: Poisson disk sampling, L-systems, Markov name generation, Voronoi, WFC.
//! - All generators are deterministic given a seed via the internal LCG.

/// Biome classification types and rules-based classifier.
pub mod biome;
/// Binary Space Partitioning dungeon generator.
pub mod bsp;
/// Cellular automata cave map generator.
pub mod cellular;
/// Scalar-to-colour RGBA conversion helpers.
pub mod color;
/// 4-connected flood fill mask generator.
pub mod flood_fill;
/// FBM noise-based heightmap with optional erosion.
pub mod heightmap;
/// Linear Congruential Generator for deterministic seeding.
pub mod lcg;
/// L-system string rewriting and turtle geometry.
pub mod lsystem;
/// Markov-chain name generator.
pub mod namegen;
/// Perlin, Simplex, Worley, and fractal noise primitives.
pub mod noise;
/// Poisson disk point sampler. This module is publicly re-exported.
pub mod poisson;
/// Noise-grid rendering helpers.
pub mod render;
/// Random-room scatter dungeon generator.
pub mod rooms;
/// Voronoi diagram with optional domain warp.
pub mod voronoi;
/// Wave Function Collapse tile map generator.
pub mod wfc;
/// World region graph with A*, Dijkstra, and Kruskal MST.
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
