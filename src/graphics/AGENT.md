# src/graphics/

2D GPU rendering pipeline built on wgpu with DrawCommand queue architecture.

## What This Module Contains

GpuRenderer manages wgpu device/surface/pipeline. DrawCommand enum queued during luna.draw(), processed in render_frame(). Camera for world/screen transforms. Font (fontdue TTF rasterization). Canvas for off-screen render targets. Mesh for custom geometry. Shader for custom WGSL fragment shaders. SpriteSheet/SpriteAtlas for frame-based animations. NineSlice for scalable UI panels. SpriteBatch for efficient instanced draws. ColumnBatch for raycasting. Light2D, Trail, DecalSurface, PaletteLUT for effects.

## Files

| File | Purpose |
|------|---------|
| `animation.rs` | `Animation` implementation |
| `camera.rs` | `Camera` implementation |
| `canvas.rs` | `Canvas` implementation |
| `column_batch.rs` | `ColumnBatch` implementation |
| `data_graph_renderer.rs` | `DataGraphRenderer` implementation |
| `decal_surface.rs` | `DecalSurface` implementation |
| `draw_layer.rs` | `DrawLayer` implementation |
| `font.rs` | `Font` implementation |
| `gpu_renderer.rs` | `GpuRenderer` implementation |
| `large_map_renderer.rs` | `LargeMapRenderer` implementation |
| `light2d.rs` | `Light2D` implementation |
| `mesh.rs` | `Mesh` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `nine_slice.rs` | `NineSlice` implementation |
| `palette_lut.rs` | `PaletteLut` implementation |
| `polygon_map.rs` | `PolygonMap` implementation |
| `renderer.rs` | `Renderer` implementation |
| `shader.rs` | `Shader` implementation |
| `sprite.rs` | `Sprite` implementation |
| `sprite_batch.rs` | `SpriteBatch` implementation |
| `sprite_sheet.rs` | `SpriteSheet` implementation |
| `srgb.rs` | `Srgb` implementation |
| `texture.rs` | `Texture` implementation |
| `texture_atlas.rs` | `TextureAtlas` implementation |
| `trail.rs` | `Trail` implementation |
| `viewport.rs` | `Viewport` implementation |
| `viewport_scale.rs` | `ViewportScale` implementation |

## Navigation

- **Owner agent**: `Renderer`
- **Tests**: `tests/graphics_tests.rs, tests/graphics_ext_tests.rs`
- **Lua API bindings**: `src/lua_api/graphics_api.rs, src/lua_api/graphics_ext_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
