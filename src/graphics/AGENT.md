# `graphics` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 1 — Core Engine Subsystems |
| **Lua API** | `luna.graphics` |
| **Source** | `src/graphics/` |
| **Tests** | `tests/graphics_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_graphics.lua` |
| **Extracted modules** | `animation` → `src/animation/`, `camera` → `src/camera/`, `Color` → `src/math/color.rs` |

## Summary

The graphics module owns the entire GPU rendering pipeline for Luna2D — from
the high-level draw calls that Lua scripts make, through a `DrawCommand` queue
that batches all rendering work, to the wgpu GPU backend that executes those
commands against the swapchain.  No other module writes pixels; everything
visual flows through here.

The module is designed around a deferred command queue: during `luna.draw()`
Lua pushes `DrawCommand` variants into a `Vec<DrawCommand>`.  After the Lua
callback returns, the engine calls `GpuRenderer::render_frame()` which
processes the queue in batches through a single GPU encoder pass.  This
means Lua never touches the GPU directly — it constructs a list of intent
and the renderer has full visibility over the draw list to minimise state
switches before any GPU work begins.

All resources (textures, fonts, canvases, shaders, meshes, sprite batches,
and compound shapes) are identified by typed SlotMap keys that are opaque to
Lua.  When a script calls `luna.graphics.newImage("hero.png")`, Lua receives a
lightweight handle table wrapping a `TextureKey`; the actual `wgpu::Texture`
and `wgpu::TextureView` live inside `GpuRenderer` and are never passed to Lua.
`luna.graphics.newShape()` follows the same pattern — Lua holds a `LuaShape`
userdata wrapping a `ShapeKey` while the `CompoundShape` command buffer lives
in `SharedState::shapes`.  This keeps Lua values small and eliminates the need
for Lua `__gc` finalizers on GPU resources.

The transform stack (`push/pop/translate/rotate/scale`) is implemented as
`DrawCommand` variants — the engine maintains a matrix stack as it processes
the queue, multiplying incoming transforms and applying the accumulated matrix
to all vertices in scope.  This gives Lua the familiar, nested transform syntax
of a similar game engine without any Lua-side matrix math.

## Architecture

```
GpuRenderer (wgpu rendering backend)
  │
  ├── Core pipeline
  │     ├── wgpu Device / Queue / Surface
  │     ├── Two pipelines: color-only + textured
  │     ├── Viewport uniform buffer (projection matrix)
  │     ├── Per-frame transform stack (push/pop/translate/rotate/scale)
  │     └── render_frame(draw_commands) → present swapchain
  │
  ├── DrawCommand queue (35+ variants)
  │     ├── Primitives: Rectangle, Circle, Line, Polygon, Arc, Ellipse, Points
  │     ├── Text: Print, Printf (aligned)
  │     ├── Images: DrawTexture, DrawTextureQuad
  │     ├── Batching: DrawSpriteBatch
  │     ├── Canvas: SetCanvas, ClearCanvas
  │     ├── Transform: PushTransform, PopTransform, Translate, Rotate, Scale
  │     ├── State: SetColor, SetBlendMode, SetShader, SetLineWidth
  │     ├── Stencil: SetStencilTest, Stencil
  │     ├── CompoundShape: DrawShape (replays a CompoundShape with affine transform)
  │     └── Advanced: DrawMesh, DrawParticleSystem, DrawAnimation, DrawTrail
  │
  ├── Resources (SlotMap storage)
  │     ├── Textures ── GPU texture handles + metadata
  │     ├── Fonts ── fontdue rasterization + GPU atlas
  │     ├── Canvases ── off-screen render targets
  │     ├── Shaders ── custom WGSL fragment shaders
  │     ├── SpriteBatches ── instanced sprite rendering
  │     └── Shapes ── CompoundShape command buffers (ShapeKey → CompoundShape)
  │     └── SpriteBatches ── instanced sprite rendering
  │
  ├── Camera ── see `src/camera/` (extracted module)
  │
  └── Specialized renderers
        ├── GraphRenderer ── line/scatter/bar data charts
        ├── ColumnBatch ── Wolfenstein-style raycasting columns
        ├── LargeMapRenderer ── chunk-based tilemap with LOD
        ├── PolygonMap ── named polygon regions with hover
        ├── Trail ── fading polyline trails
        ├── DecalSurface ── persistent render target for decals
        └── Light2D ── 2D point light sources
```

## Source Files

| File | Purpose |
|------|---------|
| `animation.rs` | **Extracted** — see `src/animation/AGENT.md` |
| `camera.rs` | **Extracted** — see `src/camera/AGENT.md` |
| `canvas.rs` | Off-screen render targets (canvases) for deferred compositing |
| `column_batch.rs` | Wolfenstein-style raycasting column batch renderer |
| `data_graph_renderer.rs` | Mathematical function graph and chart renderer |
| `decal_surface.rs` | Persistent surface for stamping decal textures |
| `draw_layer.rs` | Z-ordered draw layer for controlling render order |
| `font.rs` | TTF/OTF font loading, glyph rasterization, and atlas packing for GPU text... |
| `large_map_renderer.rs` | Optimized renderer for large tile-based maps with chunking and LOD |
| `light2d.rs` | 2D point light data container for lighting systems |
| `mesh.rs` | Mesh API for custom geometry rendering |
| `nine_slice.rs` | Nine-slice (9-patch) image rendering for scalable UI elements |
| `palette_lut.rs` | Color palette lookup table for shader-based palette swapping |
| `polygon_map.rs` | Polygon map renderer with region management and hit detection |
| `renderer.rs` | Draw command types, blend modes, and texture data for the Luna2D rendering... |
| `shape.rs` | `ShapeCommand` sub-enum and `CompoundShape` pooled builder resource |
| `shader.rs` | Custom WGSL shader support for Luna2D |
| `sprite.rs` | Sprite implementation for the `graphics` subsystem |
| `sprite_batch.rs` | Sprite batching for efficient rendering of many sprites sharing one texture |
| `sprite_sheet.rs` | Grid-based sprite sheet with directional support and named groups |
| `srgb.rs` | **Extracted** — `Color` moved to `src/math/color.rs`; `srgb.rs` re-exports it for compatibility |
| `texture.rs` | Texture implementation for the `graphics` subsystem |
| `texture_atlas.rs` | CPU-side bin-packing texture atlas using a shelf algorithm |
| `trail.rs` | Trail renderer for fading ribbon effects |
| `viewport.rs` | **Extracted** — see `src/camera/AGENT.md` |
| `viewport_scale.rs` | **Extracted** — see `src/camera/AGENT.md` |

## Submodules

### `graphics::animation`

**Extracted** — see `src/animation/AGENT.md`. Types `Animation`, `AnimFrame`, `AnimClip`, `AnimEvent` now live in `crate::animation`; `graphics` re-exports them for backward compatibility.

### `graphics::camera`

**Extracted** — see `src/camera/AGENT.md`. Types `Camera`, `Camera2D`, `Viewport`, `ViewportScale`, `ScaleMode` now live in `crate::camera`; `graphics` re-exports them for backward compatibility.

### `graphics::canvas`

Off-screen render targets (canvases) for deferred compositing.

- **`Canvas`** (struct): An off-screen render target with a fixed pixel resolution.

### `graphics::column_batch`

Wolfenstein-style raycasting column batch renderer.

- **`ColumnData`** (struct): Per-column rendering state produced by a raycaster.
- **`ColumnBatch`** (struct): Wolfenstein-style raycasting column batch renderer.

### `graphics::data_graph_renderer`

Mathematical function graph and chart renderer.

- **`GraphSeries`** (enum): A data series that can be added to a [`GraphRenderer`].
- **`GraphRenderer`** (struct): Mathematical function graph / chart renderer.

### `graphics::decal_surface`

Persistent surface for stamping decal textures.

- **`DecalSurface`** (struct): Persistent render target for stamping decals.

### `graphics::draw_layer`

Z-ordered draw layer for controlling render order.

- **`LayerEntry`** (struct): A queued draw entry with its z-order. Consult the module-level documentation for the broader usage context and...
- **`DrawLayer`** (struct): Z-ordered draw callback queue. Consult the module-level documentation for the broader usage context and preconditions. ...

### `graphics::font`

TTF/OTF font loading, glyph rasterization, and atlas packing for GPU text rendering.

- **`Font`** (struct): A loaded TTF/OTF font with a glyph atlas for GPU rendering.  Wraps a `fontdue::Font` for parsing and rasterization,...
- **`GlyphInfo`** (struct): Information about a single rasterized glyph in the atlas.

### `graphics::gpu_renderer`

GPU-accelerated 2D renderer for Luna2D, backed by wgpu.

- **`RenderStats`** (struct): Per-frame rendering statistics. Consult the module-level documentation for the broader usage context and preconditions.
- **`GpuRenderer`** (struct): GPU-accelerated renderer that processes `DrawCommand` queues via wgpu.
- **`gpu_resources`** (mod): Gpu Resources sub-module.
- **`render_pass`** (mod): Render Pass sub-module.

### `graphics::gpu_renderer::gpu_resources`

Resource-management methods for [`GpuRenderer`].

### `graphics::gpu_renderer::render_pass`

Render-frame execution, draw-call dispatch, tessellation, and pipeline management for [`GpuRenderer`].

- **`parse_filter_mode`** (fn): Parse a Lua string into a wgpu `FilterMode`.

### `graphics::large_map_renderer`

Optimized renderer for large tile-based maps with chunking and LOD.

- **`MapChunk`** (struct): A chunk of tiles pre-batched for fast culling and rendering.
- **`LargeMapRenderer`** (struct): Optimized large tile-map renderer with chunked culling.

### `graphics::light2d`

2D point light data container for lighting systems.

- **`Light2D`** (struct): 2D point light with position, radius, color, and intensity.

### `graphics::mesh`

Mesh API for custom geometry rendering.

- **`MeshDrawMode`** (enum): Drawing mode for mesh geometry. Consult the module-level documentation for the broader usage context and preconditions.
- **`MeshVertex`** (struct): A single vertex in a mesh. Consult the module-level documentation for the broader usage context and preconditions.
- **`Mesh`** (struct): Custom geometry mesh with per-vertex position, UV, and color data.

### `graphics::nine_slice`

Nine-slice (9-patch) image rendering for scalable UI elements.

- **`Patch`** (type): A single patch rectangle: `(src_x, src_y, src_w, src_h, dst_x, dst_y, dst_w, dst_h)`.
- **`NineSlice`** (struct): A nine-slice image definition: a texture plus border insets.  The four insets (`top`, `right`, `bottom`, `left`) define...

### `graphics::palette_lut`

Color palette lookup table for shader-based palette swapping.

- **`PaletteLUT`** (struct): Color palette lookup table mapping source colors to target colors.

### `graphics::polygon_map`

Polygon map renderer with region management and hit detection.

- **`PolygonRegion`** (struct): A named polygon region. Consult the module-level documentation for the broader usage context and preconditions.
- **`PolygonMap`** (struct): Polygon map renderer with region management and hit detection.

### `graphics::renderer`

Draw command types, blend modes, and texture data for the Luna2D rendering pipeline.

- **`CompareMode`** (enum): Stencil comparison mode for `luna.graphics.setStencilTest`.
- **`StencilAction`** (enum): Stencil write action for `luna.graphics.stencil`.
- **`TextAlign`** (enum): Text alignment mode for formatted text printing.
- **`DrawMode`** (enum): Whether a shape is drawn filled or as an outline. Includes the `DrawShape` variant for replaying a `CompoundShape` with an affine transform.
- **`TextureData`** (struct): Raw RGBA pixel data for a loaded texture, stored in the renderer's texture atlas.

### `graphics::shape`

`ShapeCommand` sub-enum and `CompoundShape` pooled builder resource.

- **`ShapeCommand`** (enum): Sub-set of draw primitives stored inside a `CompoundShape` command buffer. Variants: `SetColor`, `SetLineWidth`, `Rectangle`, `RoundedRectangle`, `Circle`, `Ellipse`, `Triangle`, `Polygon`, `Line`, `Polyline`, `Arc`.
- **`CompoundShape`** (struct): Accumulates `ShapeCommand` entries in local object space and replays them via `DrawCommand::DrawShape` with a per-call affine transformoader usage context and...
- **`DrawCommand`** (enum): A single deferred draw operation queued during `luna.draw()` and executed by `GpuRenderer`.
- **`TextureData`** (struct): Raw RGBA pixel data for a loaded texture, stored in the renderer's texture atlas.

### `graphics::shader`

Custom WGSL shader support for Luna2D.

- **`ShaderFragmentInput`** (enum): Which fragment shader input the user's entry point expects.
- **`Shader`** (struct): Represents a compiled custom shader with its uniform values.
- **`UniformValue`** (enum): A uniform value that can be sent to a shader from Lua.

### `graphics::sprite`

Sprite implementation for the `graphics` subsystem.

- **`Sprite`** (struct): A textured game object with position, scale, rotation, and tint color.  `Sprite` acts as a transform + tint wrapper...

### `graphics::sprite_batch`

Sprite batching for efficient rendering of many sprites sharing one texture.

- **`SpriteBatch`** (struct): A batch of sprites sharing a single texture, drawn in one GPU call.  Created via...
- **`BatchEntry`** (struct): A single sprite in a batch, describing position, region, and transform.

### `graphics::sprite_sheet`

Grid-based sprite sheet with directional support and named groups.

- **`FrameGroup`** (struct): Named frame group within the sprite sheet.
- **`DirectionLayout`** (enum): Directional layout for sprite sets. Consult the module-level documentation for the broader usage context and...
- **`SpriteSheet`** (struct): Grid-based sprite sheet with directional support and named groups.

### `graphics::srgb`

**Extracted** — `Color` now lives in `crate::math::color`. `srgb.rs` re-exports `Color` from `crate::math` for backward compatibility.

### `graphics::texture`

Texture implementation for the `graphics` subsystem.

- **`Texture`** (struct): A loaded image asset referenced by its index into the renderer's texture list.  `Texture` is a lightweight handle; the...

### `graphics::texture_atlas`

CPU-side bin-packing texture atlas using a shelf algorithm.

- **`AtlasRegion`** (struct): A named rectangular region packed into the atlas.
- **`TextureAtlas`** (struct): CPU-side bin-packing atlas for sprite regions.

### `graphics::trail`

Trail renderer for fading ribbon effects.

- **`TrailPoint`** (struct): A point in a trail with age tracking.
- **`Trail`** (struct): Fading textured ribbon renderer. Consult the module-level documentation for the broader usage context and preconditions.

### `graphics::viewport`

**Extracted** — see `src/camera/AGENT.md`.

### `graphics::viewport_scale`

**Extracted** — see `src/camera/AGENT.md`.

## Key Types

### Structs

#### `graphics::texture_atlas::AtlasRegion`

A named rectangular region packed into the atlas.

#### `graphics::sprite_batch::BatchEntry`

A single sprite in a batch, describing position, region, and transform.

#### `graphics::shape::CompoundShape`

Accumulates `ShapeCommand` entries in local object space and replays them as a unified draw call via `DrawCommand::DrawShape` with a per-call affine transform.

#### `graphics::canvas::Canvas`

An off-screen render target with a fixed pixel resolution.

#### `graphics::column_batch::ColumnBatch`

Wolfenstein-style raycasting column batch renderer.

#### `graphics::column_batch::ColumnData`

Per-column rendering state produced by a raycaster.

#### `graphics::decal_surface::DecalSurface`

Persistent render target for stamping decals.

#### `graphics::draw_layer::DrawLayer`

Z-ordered draw callback queue. Consult the module-level documentation for the broader usage context and preconditions. ...

#### `graphics::font::Font`

A loaded TTF/OTF font with a glyph atlas for GPU rendering.  Wraps a `fontdue::Font` for parsing and rasterization,...

#### `graphics::sprite_sheet::FrameGroup`

Named frame group within the sprite sheet.

#### `graphics::font::GlyphInfo`

Information about a single rasterized glyph in the atlas.

#### `graphics::gpu_renderer::GpuRenderer`

GPU-accelerated renderer that processes `DrawCommand` queues via wgpu.

#### `graphics::data_graph_renderer::GraphRenderer`

Mathematical function graph / chart renderer.

#### `graphics::large_map_renderer::LargeMapRenderer`

Optimized large tile-map renderer with chunked culling.

#### `graphics::draw_layer::LayerEntry`

A queued draw entry with its z-order. Consult the module-level documentation for the broader usage context and...

#### `graphics::light2d::Light2D`

2D point light with position, radius, color, and intensity.

#### `graphics::large_map_renderer::MapChunk`

A chunk of tiles pre-batched for fast culling and rendering.

#### `graphics::mesh::Mesh`

Custom geometry mesh with per-vertex position, UV, and color data.

#### `graphics::mesh::MeshVertex`

A single vertex in a mesh. Consult the module-level documentation for the broader usage context and preconditions.

#### `graphics::minimap::Minimap`

A grid-based minimap with terrain, fog, objects, pings, and markers.

#### `graphics::minimap::MinimapMarker`

A persistent labeled marker on the minimap.

#### `graphics::minimap::MinimapObject`

A tracked object on the minimap. Consult the module-level documentation for the broader usage context and preconditions.

#### `graphics::minimap::MinimapObjectType`

A registered object type with a display color and visibility toggle.

#### `graphics::minimap::MinimapPing`

A temporary animated ping on the minimap.

#### `graphics::nine_slice::NineSlice`

A nine-slice image definition: a texture plus border insets.  The four insets (`top`, `right`, `bottom`, `left`) define...

#### `graphics::palette_lut::PaletteLUT`

Color palette lookup table mapping source colors to target colors.

#### `graphics::polygon_map::PolygonMap`

Polygon map renderer with region management and hit detection.

#### `graphics::polygon_map::PolygonRegion`

A named polygon region. Consult the module-level documentation for the broader usage context and preconditions.

#### `graphics::postfx::PostFxEffect`

A single post-processing effect with named float parameters.

#### `graphics::postfx::PostFxStack`

An ordered chain of effects that captures and processes the rendered scene.

#### `graphics::gpu_renderer::RenderStats`

Per-frame rendering statistics. Consult the module-level documentation for the broader usage context and preconditions.

#### `graphics::shader::Shader`

Represents a compiled custom shader with its uniform values.

#### `graphics::sprite::Sprite`

A textured game object with position, scale, rotation, and tint color.  `Sprite` acts as a transform + tint wrapper...

#### `graphics::sprite_batch::SpriteBatch`

A batch of sprites sharing a single texture, drawn in one GPU call.  Created via...

#### `graphics::sprite_sheet::SpriteSheet`

Grid-based sprite sheet with directional support and named groups.

#### `graphics::texture::Texture`

A loaded image asset referenced by its index into the renderer's texture list.  `Texture` is a lightweight handle; the...

#### `graphics::texture_atlas::TextureAtlas`

CPU-side bin-packing atlas for sprite regions.

#### `graphics::renderer::TextureData`

Raw RGBA pixel data for a loaded texture, stored in the renderer's texture atlas.

#### `graphics::trail::Trail`

Fading textured ribbon renderer. Consult the module-level documentation for the broader usage context and preconditions.

#### `graphics::trail::TrailPoint`

A point in a trail with age tracking.

#### `graphics::viewport::Viewport`

Virtual resolution with manual transform application.

#### `graphics::viewport_scale::ViewportScale`

Virtual resolution with automatic graphics stack management.

### Enums

#### `graphics::animation::AnimEvent`

Events emitted by [`Animation::update`].

#### `graphics::renderer::BlendMode`

Blending mode for draw operations. Consult the module-level documentation for the broader usage context and...

#### `graphics::minimap::ColorMode`

How cells are colored on the minimap. Consult the module-level documentation for the broader usage context and...

#### `graphics::renderer::CompareMode`

Stencil comparison mode for `luna.graphics.setStencilTest`.

#### `graphics::sprite_sheet::DirectionLayout`

Directional layout for sprite sets. Consult the module-level documentation for the broader usage context and...

#### `graphics::renderer::DrawCommand`

A single deferred draw operation queued during `luna.draw()` and executed by `GpuRenderer`.

#### `graphics::renderer::DrawMode`

Whether a shape is drawn filled or as an outline.

#### `graphics::minimap::FogLevel`

Fog-of-war visibility level for a cell. Consult the module-level documentation for the broader usage context and...

#### `graphics::data_graph_renderer::GraphSeries`

A data series that can be added to a [`GraphRenderer`].

#### `graphics::mesh::MeshDrawMode`

Drawing mode for mesh geometry. Consult the module-level documentation for the broader usage context and preconditions.

#### `graphics::shape::ShapeCommand`

Sub-set of draw primitives stored inside a `CompoundShape` command buffer. Variants: `SetColor`, `SetLineWidth`, `Rectangle`, `RoundedRectangle`, `Circle`, `Ellipse`, `Triangle`, `Polygon`, `Line`, `Polyline`, `Arc`.

#### `graphics::postfx::PostFxEffectType`

Built-in effect types for the post-processing pipeline.  Each variant produces a different full-screen shader pass.

#### `graphics::viewport::ScaleMode`

Scale mode for virtual resolution mapping.

#### `graphics::shader::ShaderFragmentInput`

Which fragment shader input the user's entry point expects.

#### `graphics::renderer::StencilAction`

Stencil write action for `luna.graphics.stencil`.

#### `graphics::renderer::TextAlign`

Text alignment mode for formatted text printing.

#### `graphics::shader::UniformValue`

A uniform value that can be sent to a shader from Lua.

### Type Aliases

#### `graphics::animation::AnimationFrame`

Backward-compatible alias for [`AnimFrame`].  Existing code that imports `AnimationFrame` from `crate::graphics` will...

#### `graphics::nine_slice::Patch`

A single patch rectangle: `(src_x, src_y, src_w, src_h, dst_x, dst_y, dst_w, dst_h)`.

## Public Functions

- **`parse_filter_mode()`** `gpu_renderer::render_pass::` — Parse a Lua string into a wgpu `FilterMode`.

## Lua API

Exposed under `luna.graphics.*` by `src/lua_api/graphics_api/`.

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 16 |
| `fn` | 1 |
| `mod` | 30 |
| `struct` | 47 |
| `type` | 2 |
| **Total** | **96** |

