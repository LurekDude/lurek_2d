//! 2D grid-based raycaster engine for retro FPS and dungeon-crawler games.
//!
//! Provides DDA ray traversal, segment-based raycasting, visibility polygons,
//! wall column projection, sprite projection, lighting, doors, heightmaps,
//! depth buffering, and minimap extraction.

/// Column-based depth buffer for sprite occlusion.
pub mod depth_buffer;
/// Grid-based raycaster using DDA (Digital Differential Analyzer) traversal.
pub mod dda;
/// Sliding door support for grid-based raycaster levels.
pub mod doors;
/// Floor and ceiling height variations for stepped or multi-level environments.
pub mod heightmap;
/// Static and dynamic point lighting for raycaster worlds.
pub mod lighting;
/// Top-down minimap extraction from a raycaster grid.
pub mod minimap_overlay;
/// Wall column projection and distance-based shading.
pub mod projection;
/// Ray hit result from DDA grid traversal.
pub mod ray_hit;
/// Line segment definition and ray-segment intersection testing.
pub mod segment;
/// Sprite screen-space projection for billboard rendering.
pub mod sprite_projection;
/// Visibility polygon via endpoint raycasting.
pub mod visibility;

// Re-exports
pub use dda::Raycaster2D;
pub use depth_buffer::DepthBuffer;
pub use doors::{Door, DoorDirection, DoorManager, DoorState};
pub use heightmap::HeightMap;
pub use lighting::{apply_lit_shade, compute_lighting, PointLight};
pub use minimap_overlay::{draw_player_arrow, extract_minimap};
pub use projection::{distance_shade, project_column};
pub use ray_hit::RayHit;
pub use segment::{cast_ray_2d, Segment};
pub use sprite_projection::SpriteProjection;
pub use visibility::field_of_view;
