//! Procedural world generation utilities.
//!
//! Cave maps, Voronoi diagrams, flood fill, Poisson disk sampling,
//! and periodic Perlin noise for tileable textures.

/// Cellular automata cave/dungeon generation.
pub mod cellular;
/// BFS flood fill on a flat grid.
pub mod flood_fill;
/// Linear congruential generator for deterministic procgen.
pub(crate) mod lcg;
/// Periodic Perlin noise for tileable textures.
pub mod noise_ext;
/// Poisson disk sampling for point distribution.
pub mod poisson;
/// Voronoi diagram generation with optional warp.
pub mod voronoi;
/// Procedural generation visualization: `NoiseGrid` with `generate_render_commands` and `draw_to_image`.
pub mod render;

pub use cellular::{cellular_automata, CellularOpts};
pub use flood_fill::flood_fill;
pub use noise_ext::perlin_noise_periodic;
pub use poisson::poisson_disk;
pub use voronoi::{voronoi_diagram, VoronoiOpts};
