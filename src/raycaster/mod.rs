pub mod build_scene;
pub mod column_batch;
pub mod dda;
pub mod depth_buffer;
pub mod doors;
pub mod draw;
pub mod grid_motion;
pub mod heightmap;
pub mod lighting;
pub mod minimap_overlay;
pub mod projection;
pub mod ray_hit;
pub mod render;
pub mod scene;
pub mod segment;
pub mod sprite_manager;
pub mod sprite_projection;
pub mod visibility;
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
