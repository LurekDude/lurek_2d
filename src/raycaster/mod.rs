//! 2D grid-based raycaster engine for retro FPS and dungeon-crawler games.
//!
//! Provides DDA ray traversal, segment-based raycasting, visibility polygons,
//! wall column projection, sprite projection, lighting, doors, heightmaps,
//! depth buffering, minimap extraction, and textured-quad scene building.

/// Scene builder for textured-quad raycaster rendering.
pub mod build_scene;
/// Wolfenstein-style raycasting column batch renderer.
pub mod column_batch;
/// Grid-based raycaster using DDA (Digital Differential Analyzer) traversal.
pub mod dda;
/// Column-based depth buffer for sprite occlusion.
pub mod depth_buffer;
/// Sliding door support for grid-based raycaster levels.
pub mod doors;
/// CPU software-rendering fallback for headless testing.
pub mod draw;
/// Floor and ceiling height variations for stepped or multi-level environments.
pub mod heightmap;
/// Grid movement helpers for 4-direction dungeon movement.
pub mod grid_motion;
/// Static and dynamic point lighting for raycaster worlds.
pub mod lighting;
/// Top-down minimap extraction from a raycaster grid.
pub mod minimap_overlay;
/// Wall column projection and distance-based shading.
pub mod projection;
/// Ray hit result from DDA grid traversal.
pub mod ray_hit;
/// Render-command generation for raycaster scenes.
pub mod render;
/// Raycaster scene types for textured-quad rendering.
pub mod scene;
/// Line segment definition and ray-segment intersection testing.
pub mod segment;
/// Batch sprite manager with depth-sorted projection for raycaster worlds.
pub mod sprite_manager;
/// Sprite projection for billboard rendering.
pub mod sprite_projection;
/// Visibility polygon via endpoint raycasting.
pub mod visibility;
/// Diagnostic draw_*_to_image helpers for raycaster debugging.
pub mod visualization;

// Re-exports
pub use build_scene::{SceneBuildParams, WorldSprite};
pub use column_batch::{ColumnBatch, ColumnData};
pub use dda::Raycaster2D;
pub use depth_buffer::DepthBuffer;
pub use doors::{Door, DoorDirection, DoorManager, DoorState};
pub use grid_motion::{dir4_delta, try_move, GridMoveAction};
pub use heightmap::HeightMap;
pub use lighting::{apply_lit_shade, compute_lighting, PointLight};
pub use minimap_overlay::{
	build_minimap_tile_window, compute_tile_light, draw_player_arrow, extract_minimap,
	reveal_cells_from_rays, MinimapTileSample,
};
pub use projection::{distance_shade, project_column};
pub use ray_hit::RayHit;
pub use scene::{BillboardSprite, CeilingQuad, FloorQuad, ModelMesh, RaycasterScene, WallQuad};
pub use segment::{cast_ray_2d, Segment};
pub use sprite_manager::{SpriteManager, WorldSprite as ManagedSprite};
pub use sprite_projection::SpriteProjection;
pub use visibility::field_of_view;
