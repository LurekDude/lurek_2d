//! Raycaster subsystem: DDA ray casting, scene building, sprite projection, lighting,
//! doors, grid motion, depth buffering, minimap overlay, and visualization helpers.
//! Produces a `RaycasterScene` each frame consumed by `src/render/`. Does not own
//! Lua bindings or file I/O; depends on `math` and `render` types.

/// Raycaster scene construction from camera and world grid.
pub mod build_scene;
/// Per-column batch data passed to the renderer.
pub mod column_batch;
/// DDA (digital differential analysis) ray-stepping core.
pub mod dda;
/// Per-pixel depth buffer used for sprite occlusion.
pub mod depth_buffer;
/// Door state machine and door manager.
pub mod doors;
/// High-level draw call assembly for a full raycasted frame.
pub mod draw;
/// Grid-aligned player movement helpers.
pub mod grid_motion;
/// Variable floor/ceiling height map.
pub mod heightmap;
/// Distance-based wall and sprite lighting.
pub mod lighting;
/// Minimap tile extraction and overlay rendering.
pub mod minimap_overlay;
/// Column projection math: wall slice height and screen coordinates.
pub mod projection;
/// Ray-hit record produced by a single DDA ray.
pub mod ray_hit;
/// Top-level render dispatch for a raycaster frame.
pub mod render;
/// `RaycasterScene` and its constituent quad/sprite/mesh types.
pub mod scene;
/// 2D line segment and `cast_ray_2d` entry point.
pub mod segment;
/// Sprite registry and frustum-sorted sprite list.
pub mod sprite_manager;
/// Screen-space sprite projection math.
pub mod sprite_projection;
/// Field-of-view visibility grid computation.
pub mod visibility;
/// Debug visualization helpers (ray paths, normals, tiles).
pub mod visualization;
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
