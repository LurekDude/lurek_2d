# `graphics` — Agent Reference

| Property       | Value                                                        |
|----------------|--------------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                              |
| **Status**     | Implemented — Full                                           |
| **Lua API**    | `lurek.gfx`                                              |
| **Source**     | `src/graphics/`                                              |
| **Rust Tests** | `tests/rust/unit/graphics_tests.rs`, `tests/rust/ext/graphics_ext_tests.rs`, `tests/rust/ext/graphics_runtime_smoke_tests.rs` |
| **Lua Tests**  | `tests/lua/unit/test_graphics.lua`                           |
| **Architecture** | `docs/architecture/engine-architecture.md` § Rendering Pipeline |

## Summary

The graphics module owns the entire GPU rendering pipeline for Lurek2D — from the high-level draw calls that Lua scripts issue through `lurek.gfx.*`, through a deferred `DrawCommand` queue that batches all rendering work, to the wgpu GPU backend that executes those commands against the swapchain. No other module writes pixels to the screen; everything visual flows through this module.

The module is built around a **deferred command queue** architecture: during `lurek.draw()`, Lua pushes `DrawCommand` variants into a `Vec<DrawCommand>` stored in `SharedState`. After the Lua callback returns, the engine calls `GpuRenderer::render_frame()` which processes the queue in one GPU encoder pass. This means Lua never touches the GPU directly — it constructs a declarative list of rendering intent, and the renderer has full visibility over the draw list to minimise pipeline state switches before any GPU work begins.

All GPU resources (textures, fonts, canvases, shaders, meshes, sprite batches, and compound shapes) are identified by typed `SlotMap` keys that are opaque to Lua. When a script calls `lurek.gfx.newImage("hero.png")`, Lua receives a lightweight `LuaImage` userdata wrapping a `TextureKey`; the actual `wgpu::Texture` and `wgpu::TextureView` live inside `GpuRenderer` and are never exposed to Lua. This keeps Lua values small and eliminates the need for Lua `__gc` finalizers on GPU resources.

The transform stack (`push/pop/translate/rotate/scale/shear/origin`) is implemented as `DrawCommand` variants — the renderer maintains a `Mat3` matrix stack as it processes the queue, multiplying incoming transforms and applying the accumulated matrix to all vertices in scope. The module also provides stencil buffer support (write + test), depth mode control, blend modes (five pre-built pipeline variants), scissor clipping, color masking, wireframe mode, and custom WGSL shader support with per-shader uniform buffers.

Scope boundary: the `animation`, `camera`, and `Color` types have been **extracted** to their own modules (`src/animation/`, `src/camera/`, `src/math/color.rs`). The `graphics` module re-exports them for backward compatibility but does not own their implementation. Post-processing (`PostFxStack`, `PostFxEffect`) lives in `src/postfx/`; the graphics module only handles `BeginPostFx`/`EndPostFx`/`ApplyPostFx` draw commands. Particle rendering is driven by the `particle` module which pushes `DrawParticleSystem` commands into the queue.

## Architecture

```
lurek.gfx.* (Lua API — 66 functions, 7 UserData types)
  │
  ▼
DrawCommand queue (SharedState::draw_commands)
  │  45+ variants: shapes, images, text, state, transforms, stencil, post-fx
  │
  ▼
GpuRenderer (wgpu rendering backend)
  ├── wgpu::Device + Queue + Surface (swapchain)
  ├── Pipeline cache
  │     ├── Color pipelines     (5 blend modes × 2 wireframe states)
  │     ├── Texture pipelines   (5 blend modes × 2 wireframe states)
  │     ├── Stencil pipelines   (write mode, test mode)
  │     ├── Color mask variants (lazily created, cached)
  │     └── Custom shader pipelines (per Shader object)
  ├── Depth/stencil texture    (Depth24PlusStencil8)
  ├── GPU resource pools
  │     ├── gpu_textures        SlotMap<TextureKey, GpuTexture>
  │     ├── canvas_gpu_textures SlotMap<CanvasKey, GpuTexture>
  │     └── font_atlas_textures SlotMap<FontKey, GpuTexture>
  ├── Vertex buffers (pre-allocated, grown at startup)
  │     ├── Color: 131K verts / 524K indices
  │     └── Texture: 16K verts / 65K indices
  └── Per-frame transform stack (Mat3 stack)

Resource handles (SlotMap keys — opaque to Lua)
  ├── TextureKey   → TextureData (CPU) + GpuTexture (GPU)
  ├── FontKey      → Font (fontdue + atlas) + GpuTexture (atlas)
  ├── CanvasKey    → Canvas (metadata) + GpuTexture (off-screen target)
  ├── ShaderKey    → Shader (WGSL source + uniforms + pipeline)
  ├── MeshKey      → Mesh (vertices + indices + optional texture)
  ├── SpriteBatchKey → SpriteBatch (batched entries + texture)
  └── ShapeKey     → CompoundShape (vector primitive command buffer)
```

## Source Files

| File               | Purpose                                                              |
|--------------------|----------------------------------------------------------------------|
| `canvas.rs`        | Off-screen render target metadata (`Canvas` struct with width/height) |
| `color.rs`         | Orphaned `Color` struct — not declared in `mod.rs`; active `Color` lives in `src/math/color.rs` |
| `decal_surface.rs` | Persistent surface descriptor for stamping decal textures            |
| `draw_layer.rs`    | Z-ordered draw callback queue for controlling render order           |
| `font.rs`          | TTF/OTF font loading via fontdue, glyph rasterization, shelf-packed RGBA atlas |
| `gpu_renderer.rs`  | GPU-accelerated 2D renderer backed by wgpu; processes DrawCommand queue, manages GPU resources and render passes |
| `image_effect.rs`  | Per-image shader-effect pass descriptor for the draw command pipeline |
| `mesh.rs`          | Custom geometry mesh with per-vertex position, UV, and color data    |
| `nine_slice.rs`    | Nine-slice (9-patch) image rendering for scalable UI elements        |
| `renderer.rs`      | `DrawCommand` enum (45+ variants), `BlendMode`, `DrawMode`, `TextAlign`, `StencilMode`, `TextureData`, and related types |
| `shader.rs`        | Custom WGSL shader support — source validation via naga, uniform variables, per-shader pipeline |
| `shape.rs`         | `CompoundShape` builder and `ShapeCommand` sub-enum for multi-primitive vector drawing |
| `sprite.rs`        | `Sprite` struct — texture handle + transform + tint color wrapper    |
| `sprite_batch.rs`  | Sprite batching for efficient rendering of many sprites sharing one texture |
| `sprite_sheet.rs`  | Grid-based sprite sheet with directional support and named frame groups |
| `texture.rs`       | Texture loading (PNG/JPEG/BMP), premultiplied-alpha conversion, and `TextureKey` handle |
| `texture_atlas.rs` | CPU-side bin-packing texture atlas using shelf algorithm              |

## Submodules

### `graphics::canvas`

Off-screen render targets for deferred compositing.

- **`Canvas`** (struct): Logical metadata (width, height) for an off-screen texture. GPU-side resources are managed by `GpuRenderer`.

### `graphics::decal_surface`

Persistent surface for stamping decal textures.

- **`DecalSurface`** (struct): Width/height descriptor for a persistent render target; actual pixel data is managed by the renderer.

### `graphics::draw_layer`

Z-ordered draw callback queue. Entries are queued with a z-order value and flushed in ascending order (back-to-front).

- **`LayerEntry`** (struct): A queued draw entry with z-order and callback ID.
- **`DrawLayer`** (struct): Collects entries during the draw phase and flushes them sorted by z-order.

### `graphics::font`

TTF/OTF font loading, glyph rasterization, and atlas packing for GPU text rendering.

- **`Font`** (struct): Wraps a `fontdue::Font` with a glyph cache and row-based RGBA atlas bitmap. Glyphs are rasterized on-demand and packed using a shelf algorithm. Atlas starts at 512×512, grows to 2048×2048 max.
- **`GlyphInfo`** (struct): UV coordinates and metric data (advance width, baseline offset) for a single rasterized glyph in the atlas.

### `graphics::gpu_renderer`

GPU-accelerated 2D renderer backed by wgpu. Contains two internal sub-modules.

- **`RenderStats`** (struct): Per-frame statistics — draw calls, texture/canvas/shader switches, batched draws.
- **`GpuRenderer`** (struct): Processes `DrawCommand` queues via wgpu. Manages all GPU-side resources (textures, canvases, font atlases, shader pipelines), vertex buffers, depth/stencil targets, and the per-frame render pass.

#### `gpu_renderer::gpu_resources`

Resource-management methods for `GpuRenderer` — texture uploads, canvas creation, font atlas updates.

#### `gpu_renderer::render_pass`

Render-frame execution, draw-call dispatch, geometry tessellation, and pipeline management.

### `graphics::image_effect`

Lightweight per-image shader-effect pass data.

- **`ShaderPassDescriptor`** (struct): Describes one shader pass in a per-image effect chain — carries an effect name, float parameter map, and enabled flag. Lives in Tier 1 with no imports from `src/postfx/`.

### `graphics::mesh`

Custom geometry mesh for arbitrary vertex data rendering.

- **`MeshDrawMode`** (enum): Drawing topology — `Triangles`, `Fan`, `Strip`.
- **`MeshVertex`** (struct): Per-vertex data: position (x,y), UV (u,v), and RGBA color.
- **`Mesh`** (struct): Vertex buffer, optional index buffer, optional texture key, and draw mode.

### `graphics::nine_slice`

Nine-slice (9-patch) image rendering for scalable UI elements. Corners maintain original size, edges stretch along one axis, center stretches in both.

- **`Patch`** (type alias): `(src_x, src_y, src_w, src_h, dst_x, dst_y, dst_w, dst_h)`.
- **`NineSlice`** (struct): Texture key plus four border insets (top, right, bottom, left) and source texture dimensions.

### `graphics::renderer`

Draw command types, blend modes, stencil state, and texture data for the rendering pipeline.

- **`CompareMode`** (enum): Stencil comparison function — `Equal`, `NotEqual`, `Less`, `LessEqual`, `Greater`, `GreaterEqual`, `Always`, `Never`.
- **`StencilAction`** (enum): Stencil write operation — `Keep`, `Zero`, `Replace`, `Increment`, `Decrement`, `IncrementWrap`, `DecrementWrap`, `Invert`.
- **`StencilMode`** (struct): Combined stencil state — action, compare mode, and reference value.
- **`DepthMode`** (enum): Depth test comparison — `Always` (default/disabled), `Never`, `Less`, `LessEqual`, `Equal`, `NotEqual`, `Greater`, `GreaterEqual`.
- **`TextAlign`** (enum): Text alignment for `printf` — `Left`, `Center`, `Right`, `Justify`.
- **`DrawMode`** (enum): Shape fill mode — `Fill` (solid) or `Line` (outline).
- **`BlendMode`** (enum): Blending pipeline — `Alpha` (default), `Add`, `Multiply`, `Replace`, `Screen`.
- **`DrawCommand`** (enum): Central deferred draw operation enum with 45+ variants covering shapes, images, text, transforms, state changes, stencil, canvas, mesh, nine-slice, compound shape, particle system, and post-fx.
- **`TextureData`** (struct): Raw RGBA pixel data (premultiplied alpha) with width and height.
- **`ParticleRenderShape`** (enum): Geometric shape for untextured particle rendering — `Square`, `Circle`, `Triangle`, `Spark`, `Diamond`.
- **`ParticleInstance`** (struct): Pre-computed per-particle render data (position, color, rotation, size, shape, optional texture/quad).
- **`DrawableKind`** (enum): Type discriminator for `lurek.gfx.draw()` polymorphism — `Image`, `Canvas`, `SpriteBatch`, `Mesh`.

### `graphics::shader`

Custom WGSL shader support with uniform variables.

- **`Shader`** (struct): Compiled custom shader — WGSL source, wrapper source, fragment entry name, and `HashMap<String, UniformValue>` for uniforms. GPU pipeline is created lazily.
- **`UniformValue`** (enum): Uniform value types — `Float`, `Vec2`, `Vec3`, `Vec4`, `Int`, `Bool`.

### `graphics::shape`

Compound shape builder for multi-primitive vector drawing.

- **`ShapeCommand`** (enum): Restricted subset of `DrawCommand` for object-space primitives — `SetColor`, `SetLineWidth`, `Rectangle`, `RoundedRectangle`, `Circle`, `Ellipse`, `Triangle`, `Polygon`, `Line`, `Polyline`, `Arc`.
- **`CompoundShape`** (struct): Accumulates `ShapeCommand` entries in local object space. Replayed via `DrawCommand::DrawShape` with a per-call affine transform.

### `graphics::sprite`

Sprite struct combining a texture handle, transform, and tint color.

- **`Sprite`** (struct): Texture ID, position (`Vec2`), scale (`Vec2`), rotation (`f32`), and tint color (`Color`).

### `graphics::sprite_batch`

Sprite batching for efficient rendering of many sprites sharing one texture.

- **`SpriteBatch`** (struct): Batch of sprites sharing a `TextureKey`, drawn in one GPU call. Supports a maximum entry cap (0 = unlimited).
- **`BatchEntry`** (struct): Per-sprite data — screen position, source quad region, rotation, scale, and origin offset.

### `graphics::sprite_sheet`

Grid-based sprite sheet with directional support and named groups.

- **`FrameGroup`** (struct): Named group of contiguous frames (name, start index, count).
- **`DirectionLayout`** (enum): Whether directional sets are arranged in `Rows` or `Columns`.
- **`SpriteSheet`** (struct): Divides a texture into equal-sized cells, pre-computes UV quads per frame, and supports named groups and 4/8-directional layouts.

### `graphics::texture`

Texture loading and handle management.

- **`Texture`** (struct): Lightweight handle — `TextureKey`, width, and height. Actual pixel data lives in `TextureData` inside `SharedState::textures`.

### `graphics::texture_atlas`

CPU-side bin-packing texture atlas using a shelf algorithm.

- **`AtlasRegion`** (struct): Named rectangular region packed into the atlas (name, x, y, w, h).
- **`TextureAtlas`** (struct): Fixed-size atlas with shelf-packing. Regions are placed left-to-right; new shelves open below when a region does not fit.

## Key Types

### Structs

#### `graphics::canvas::Canvas`

An off-screen render target with a fixed pixel resolution. Stores only logical width/height metadata; the GPU texture is managed by `GpuRenderer`.

#### `graphics::shape::CompoundShape`

Accumulates `ShapeCommand` entries in local object space and replays them as a unified draw call via `DrawCommand::DrawShape` with a per-call affine transform.

#### `graphics::decal_surface::DecalSurface`

Persistent render target descriptor for stamping decals. Stores width/height dimensions only.

#### `graphics::draw_layer::DrawLayer`

Z-ordered draw callback queue. Collects entries during the draw phase and flushes them sorted by z-order (ascending, back-to-front).

#### `graphics::draw_layer::LayerEntry`

A queued draw entry with a z-order sorting key and a callback ID.

#### `graphics::font::Font`

Loaded TTF/OTF font with a glyph atlas for GPU rendering. Wraps a `fontdue::Font` for parsing and on-demand glyph rasterization. Atlas starts at 512×512 and grows to a 2048×2048 maximum.

#### `graphics::font::GlyphInfo`

UV coordinates and metric data for a single rasterized glyph in the font atlas — advance width, baseline offset, and atlas region bounds.

#### `graphics::gpu_renderer::GpuRenderer`

GPU-accelerated renderer that processes `DrawCommand` queues via wgpu. Manages all GPU-side resources, vertex/index buffers, the depth/stencil target, pipeline cache, and the per-frame render pass. Entry point: `render_frame()`.

#### `graphics::gpu_renderer::RenderStats`

Per-frame rendering statistics: draw calls, texture switches, canvas switches, shader switches, and batched draws.

#### `graphics::mesh::Mesh`

Custom geometry mesh with per-vertex position, UV, and color data. Supports optional index buffers and optional textures. Three draw modes: triangles, fan, strip.

**Public functions:**
- `from_vertex_rows(rows: &[[f32; 8]], mode: MeshDrawMode) -> Self` — Creates a `Mesh` from a slice of flat 8-element rows `[x, y, u, v, r, g, b, a]`; convenience constructor used by `lurek.gfx.newMesh`.

#### `graphics::mesh::MeshVertex`

A single vertex in a mesh — position (x,y), UV (u,v), and RGBA color (r,g,b,a).

#### `graphics::nine_slice::NineSlice`

Nine-slice image definition: a texture key plus four border insets and source texture dimensions. Generates 9 `Patch` rectangles for rendering.

#### `graphics::renderer::ParticleInstance`

Pre-computed per-particle render data for a single frame — world position, RGBA color, rotation, size, shape, optional texture key and quad region.

#### `graphics::image_effect::ShaderPassDescriptor`

One shader pass in a per-image effect chain. Carries the effect name, a flat float-parameter map, and an enabled flag.

#### `graphics::shader::Shader`

Compiled custom shader — WGSL source, wrapper source, fragment entry name, inputs, and uniform values. GPU pipeline is created lazily on first use.

#### `graphics::sprite::Sprite`

Textured game object with position, scale, rotation, and tint color. Acts as a transform + tint wrapper around a texture index.

#### `graphics::sprite_batch::SpriteBatch`

Batch of sprites sharing a single texture, drawn in one GPU call. Supports an optional maximum entry cap.

#### `graphics::sprite_batch::BatchEntry`

Per-sprite data in a batch — screen position, source quad region, rotation, scale, and origin offset.

#### `graphics::sprite_sheet::SpriteSheet`

Grid-based sprite sheet with directional support and named groups. Divides a texture into equal-sized cells and pre-computes UV quads.

#### `graphics::sprite_sheet::FrameGroup`

Named frame group within a sprite sheet (name, start frame index, frame count).

#### `graphics::renderer::StencilMode`

Combined stencil state — action, compare mode, and reference value. Stored in `SharedState` and applied lazily by the pipeline.

#### `graphics::texture::Texture`

Lightweight handle for a loaded image asset — `TextureKey`, width, and height. Actual pixel data lives in `TextureData` within `SharedState::textures`.

#### `graphics::texture_atlas::TextureAtlas`

CPU-side bin-packing atlas for sprite regions using a shelf-packing algorithm.

#### `graphics::texture_atlas::AtlasRegion`

Named rectangular region packed into the atlas (name, x, y, w, h).

#### `graphics::renderer::TextureData`

Raw RGBA pixel data (premultiplied alpha) with width and height dimensions.

### Enums

#### `graphics::renderer::BlendMode`

Blending pipeline for draw operations — `Alpha` (default), `Add`, `Multiply`, `Replace`, `Screen`. Each mode has a pre-built wgpu pipeline.

#### `graphics::renderer::CompareMode`

Stencil comparison function — `Equal`, `NotEqual`, `Less`, `LessEqual`, `Greater`, `GreaterEqual`, `Always`, `Never`.

#### `graphics::renderer::DepthMode`

Depth test comparison mode — `Always` (default, disabled), `Never`, `Less`, `LessEqual`, `Equal`, `NotEqual`, `Greater`, `GreaterEqual`.

#### `graphics::sprite_sheet::DirectionLayout`

Whether directional sprite sets are arranged in `Rows` or `Columns`.

#### `graphics::renderer::DrawCommand`

Central deferred draw operation enum with 45+ variants. Covers: shape primitives (Rectangle, RoundedRectangle, Circle, Ellipse, Triangle, Polygon, Arc, Line, Polyline, Points), images (DrawImage, DrawImageEx, DrawQuad), text (Print, PrintFont, PrintFormatted), canvas (SetCanvas, DrawCanvas, RegisterCanvas), batch draws (DrawBatch, DrawMesh, DrawNineSlice, DrawShape, DrawParticleSystem), state changes (SetColor, SetBlendMode, SetShader, SetLineWidth, SetPointSize, SetScissor, SetColorMask, SetWireframe), stencil (StencilBegin, StencilEnd, SetStencilTest), transforms (PushTransform, PopTransform, Translate, Rotate, Scale, Shear, Origin, ApplyTransform), and post-fx (BeginPostFx, EndPostFx, ApplyPostFx).

#### `graphics::renderer::DrawMode`

Shape fill mode — `Fill` (solid) or `Line` (outline using current line width).

#### `graphics::renderer::DrawableKind`

Type discriminator for `lurek.gfx.draw()` polymorphism — `Image(TextureKey)`, `Canvas(CanvasKey)`, `SpriteBatch(SpriteBatchKey)`, `Mesh(MeshKey)`.

#### `graphics::mesh::MeshDrawMode`

Drawing topology for mesh geometry — `Triangles`, `Fan`, `Strip`.

#### `graphics::renderer::ParticleRenderShape`

Geometric shape for untextured particle rendering — `Square`, `Circle`, `Triangle`, `Spark`, `Diamond`.

#### `graphics::shape::ShapeCommand`

Restricted subset of `DrawCommand` for object-space primitives stored inside a `CompoundShape` — `SetColor`, `SetLineWidth`, `Rectangle`, `RoundedRectangle`, `Circle`, `Ellipse`, `Triangle`, `Polygon`, `Line`, `Polyline`, `Arc`.

#### `graphics::renderer::StencilAction`

Stencil write operation — `Keep`, `Zero`, `Replace`, `Increment`, `Decrement`, `IncrementWrap`, `DecrementWrap`, `Invert`.

#### `graphics::renderer::TextAlign`

Text alignment mode for formatted text printing — `Left`, `Center`, `Right`, `Justify`.

#### `graphics::shader::UniformValue`

Uniform value types for custom shaders — `Float(f32)`, `Vec2([f32;2])`, `Vec3([f32;3])`, `Vec4([f32;4])`, `Int(i32)`, `Bool(bool)`.

### Type Aliases

#### `graphics::nine_slice::Patch`

Single patch rectangle tuple: `(src_x, src_y, src_w, src_h, dst_x, dst_y, dst_w, dst_h)`.

## Lua API

Exposed under `lurek.gfx.*` by `src/lua_api/graphics_api.rs` (2,407 lines). The API provides 66 namespace functions and 7 UserData types.

### Namespace Functions (66)

#### Color
- `lurek.gfx.setColor(r, g, b, a?)` — set the active draw color
- `lurek.gfx.getColor()` — get the current draw color (r, g, b, a)
- `lurek.gfx.setBackgroundColor(r, g, b, a?)` — set the clear/background color
- `lurek.gfx.getBackgroundColor()` — get the current background color

#### Shape Drawing
- `lurek.gfx.rectangle(mode, x, y, w, h, rx?, ry?)` — draw a rectangle (optionally rounded)
- `lurek.gfx.circle(mode, x, y, r)` — draw a circle
- `lurek.gfx.ellipse(mode, x, y, rx, ry)` — draw an ellipse
- `lurek.gfx.triangle(mode, x1, y1, x2, y2, x3, y3)` — draw a triangle
- `lurek.gfx.line(x1, y1, x2, y2, ...)` — draw a line or polyline
- `lurek.gfx.polygon(mode, vertices)` — draw a polygon from a flat vertex list
- `lurek.gfx.arc(mode, x, y, r, angle1, angle2, segments?)` — draw an arc
- `lurek.gfx.points(...)` — draw points at specified coordinates

#### Drawing
- `lurek.gfx.draw(drawable, x?, y?, r?, sx?, sy?, ox?, oy?)` — draw an Image, Canvas, SpriteBatch, or Mesh
- `lurek.gfx.drawq(image, quad, x, y, r?, sx?, sy?, ox?, oy?)` — draw a sub-region of an image using a Quad

#### Text
- `lurek.gfx.print(text, x, y)` — draw text at a position
- `lurek.gfx.printf(text, x, y, limit, align?)` — draw word-wrapped, aligned text

#### Clear
- `lurek.gfx.clear(r?, g?, b?, a?)` — clear the screen or active canvas

#### Line and Point Style
- `lurek.gfx.setLineWidth(width)` — set the stroke width
- `lurek.gfx.getLineWidth()` — get the current stroke width
- `lurek.gfx.setPointSize(size)` — set the point size
- `lurek.gfx.getPointSize()` — get the current point size

#### Blend Mode
- `lurek.gfx.setBlendMode(mode)` — set the active blend mode
- `lurek.gfx.getBlendMode()` — get the current blend mode

#### Font Management
- `lurek.gfx.newFont(path, size)` — load a TTF/OTF font
- `lurek.gfx.setFont(font)` — set the active font
- `lurek.gfx.getFont()` — get the active font
- `lurek.gfx.getFontWidth(text)` — get pixel width of text in the current font
- `lurek.gfx.getFontHeight()` — get the line height of the current font
- `lurek.gfx.getFontAscent()` — get the ascent of the current font
- `lurek.gfx.getFontDescent()` — get the descent of the current font
- `lurek.gfx.getFontWrap(text, limit)` — get word-wrap info for the current font

#### Image Management
- `lurek.gfx.newImage(path)` — load an image from file as a GPU texture

#### Canvas Management
- `lurek.gfx.newCanvas(width, height)` — create an off-screen render target
- `lurek.gfx.setCanvas(canvas?)` — set the active render target (nil = screen)
- `lurek.gfx.getCanvas()` — get the active canvas (nil if drawing to screen)
- `lurek.gfx.getCanvasSize(canvas)` — get canvas dimensions

#### SpriteBatch
- `lurek.gfx.newSpriteBatch(image, maxSprites?)` — create a sprite batch

#### Mesh
- `lurek.gfx.newMesh(vertices, mode?, image?)` — create a custom geometry mesh

#### Shader
- `lurek.gfx.newShader(source)` — compile a custom WGSL fragment shader
- `lurek.gfx.setShader(shader?)` — set the active shader (nil = default pipeline)
- `lurek.gfx.getShader()` — get the active shader

#### Quad
- `lurek.gfx.newQuad(x, y, w, h, sw, sh)` — create a sub-region quad for sprite-sheet access

#### Transform Stack
- `lurek.gfx.push()` — push a copy of the current transform
- `lurek.gfx.pop()` — pop the top transform
- `lurek.gfx.translate(x, y)` — apply a translation
- `lurek.gfx.rotate(angle)` — apply a rotation (radians)
- `lurek.gfx.scale(sx, sy?)` — apply a scale
- `lurek.gfx.shear(kx, ky)` — apply a shear (skew)
- `lurek.gfx.origin()` — reset transform to identity
- `lurek.gfx.applyTransform(transform)` — apply a Transform userdata

#### Scissor
- `lurek.gfx.setScissor(x?, y?, w?, h?)` — set or clear the scissor rectangle
- `lurek.gfx.getScissor()` — get the current scissor rectangle
- `lurek.gfx.intersectScissor(x, y, w, h)` — intersect with the current scissor

#### Color Mask
- `lurek.gfx.setColorMask(r, g, b, a)` — set which color channels can be written
- `lurek.gfx.getColorMask()` — get the current color mask

#### Wireframe
- `lurek.gfx.setWireframe(enable)` — enable or disable wireframe mode
- `lurek.gfx.isWireframe()` — check if wireframe mode is active

#### Stencil
- `lurek.gfx.stencil(func, action?, value?)` — execute a function that writes to the stencil buffer
- `lurek.gfx.setStencilTest(compareMode?, value?)` — set or disable stencil testing

#### Window Dimensions
- `lurek.gfx.getWidth()` — get the window width in pixels
- `lurek.gfx.getHeight()` — get the window height in pixels
- `lurek.gfx.getDimensions()` — get the window dimensions (w, h)

#### Default Filter
- `lurek.gfx.setDefaultFilter(mode)` — set the default texture filter mode ("nearest" or "linear")
- `lurek.gfx.getDefaultFilter()` — get the current default filter mode

#### Stats and Screenshot
- `lurek.gfx.getStats()` — get per-frame render statistics table
- `lurek.gfx.saveScreenshot(path)` — save a screenshot PNG to the save directory

### UserData Types (7)

#### `LuaImage`
Methods: `getWidth()`, `getHeight()`, `getDimensions()`, `release()`, `typeOf()`, `type()`

#### `LuaFont`
Methods: `getWidth(text)`, `getHeight()`, `getLineHeight()`, `setLineHeight(h)`, `getAscent()`, `getDescent()`, `getWrap(text, limit)`, `release()`, `typeOf()`, `type()`

#### `LuaCanvas`
Methods: `getWidth()`, `getHeight()`, `getDimensions()`, `release()`, `typeOf()`, `type()`

#### `LuaSpriteBatch`
Methods: `add(...)`, `clear()`, `getCount()`, `getBufferSize()`, `release()`, `typeOf()`, `type()`

#### `LuaMesh`
Methods: `getVertexCount()`, `getVertex(index)`, `setVertex(index, ...)`, `setTexture(image)`, `release()`, `typeOf()`, `type()`

#### `LuaShader`
Methods: `send(name, value)`, `hasUniform(name)`, `release()`, `typeOf()`, `type()`

#### `LuaQuad`
Methods: `getViewport()`, `setViewport(x, y, w, h)`, `getTextureDimensions()`, `typeOf()`, `type()`

## Lua Examples

```lua
function lurek.init()
    -- Load resources
    img = lurek.gfx.newImage("player.png")
    font = lurek.gfx.newFont("font.ttf", 18)
    canvas = lurek.gfx.newCanvas(800, 600)
    batch = lurek.gfx.newSpriteBatch(img, 100)

    -- Add sprites to batch
    for i = 1, 10 do
        batch:add(i * 40, 100)
    end
end

function lurek.render()
    -- Render scene to canvas
    lurek.gfx.setCanvas(canvas)
    lurek.gfx.clear(0.1, 0.1, 0.2)

    -- Transform stack
    lurek.gfx.push()
    lurek.gfx.translate(400, 300)
    lurek.gfx.rotate(0.5)
    lurek.gfx.draw(img, -32, -32)
    lurek.gfx.pop()

    -- Draw shapes
    lurek.gfx.setColor(1, 0, 0)
    lurek.gfx.rectangle("fill", 50, 50, 100, 80)
    lurek.gfx.setColor(0, 1, 0)
    lurek.gfx.circle("line", 300, 200, 40)

    -- Draw batch
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.draw(batch, 0, 300)

    -- Switch to screen
    lurek.gfx.setCanvas()

    -- Composite canvas to screen
    lurek.gfx.draw(canvas, 0, 0)

    -- Draw text
    lurek.gfx.setFont(font)
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("Score: 42", 10, 10)
    lurek.gfx.printf("Centered text", 0, 560, 800, "center")
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `struct`   | 26    |
| `enum`     | 13    |
| `type`     | 1     |
| `fn`       | 86    |
| **Total**  | **126** |

## References

| Module      | Relationship  | Notes                                                              |
|-------------|---------------|--------------------------------------------------------------------|
| `engine`    | Imports from  | `SharedState`, `EngineError`, all `SlotMap` resource key types     |
| `math`      | Imports from  | `Vec2`, `Mat3`, `Rect`, `Color` for rendering math and colour     |
| `image`     | Related       | `image` provides CPU pixel buffers (`ImageData`); `graphics` uploads them to GPU via `Texture::from_rgba` |
| `camera`    | Related       | Extracted module; `camera` sets the view transform consumed by `GpuRenderer` |
| `animation` | Related       | Extracted module; `animation` provides sprite animation types      |
| `particle`  | Related       | Tier 2 module; pushes `DrawParticleSystem` commands into the draw queue |
| `postfx`    | Related       | Tier 2 module; provides `PostFxStack` and `PostFxEffect`; graphics handles `BeginPostFx`/`EndPostFx`/`ApplyPostFx` commands |
| `lua_api`   | Imported by   | `src/lua_api/graphics_api.rs` registers all `lurek.gfx.*` bindings |

**Similar modules and differentiation:**
- `image` vs `graphics`: `image` owns CPU-side pixel buffers (`ImageData`) for manipulation; `graphics` owns GPU-side textures and rendering.
- `camera` vs `graphics`: `camera` was extracted from `graphics`; it provides `Camera2D`, `Viewport`, and `ViewportScale` types that feed the view matrix into `GpuRenderer`.

## Notes

- **Draw command flow**: Commands are queued during `lurek.draw()` and processed in submission order by `GpuRenderer::render_frame()`. Never allocate GPU resources inside `lurek.draw()` — all resource creation (`newImage`, `newFont`, etc.) should happen in `lurek.load()`.
- **GPU backend**: wgpu 22 (Vulkan/DX12/Metal). No raw OpenGL path, no software fallback.
- **Premultiplied alpha**: All textures are premultiply-converted on load. The GPU pipeline assumes premultiplied colour space.
- **Canvas ping-pong**: `setCanvas(canvas)` begins a new render pass to the off-screen target; `setCanvas()` (no args) returns to the screen.
- **Blend mode pipelines**: Five blend modes × two wireframe states = 10 pre-built pipelines. Custom blend behaviour requires a custom `Shader`.
- **Vertex buffer limits**: Color geometry: 131K vertices / 524K indices. Textured geometry: 16K vertices / 65K indices. Exceeding these limits in a single frame causes silent clipping.
- **Font atlas growth**: The glyph atlas starts at 512×512 and doubles when full, up to a 2048×2048 maximum. Exceeding the maximum logs a warning and skips new glyphs.
- **Adding new `DrawCommand` variants**: Both `renderer.rs` (enum definition) and `gpu_renderer/render_pass.rs` (execution arm) must be updated together.
- **Orphaned `color.rs`**: `src/graphics/color.rs` defines a `Color` struct but is not declared in `mod.rs`. The active `Color` type lives in `src/math/color.rs`.
- **Per-frame allocations**: The draw command queue must avoid heap allocations per frame. Grow buffers at startup, reuse across frames.
- **Transform stack**: Implemented as `DrawCommand` variants (`PushTransform`, `PopTransform`, `Translate`, `Rotate`, `Scale`, `Shear`, `Origin`, `ApplyTransform`). The renderer maintains a `Mat3` stack internally.
- **Coordinate system**: Origin at top-left, Y increases downward (screen coordinates).
- **Custom shaders**: WGSL fragment shaders with auto-prepended globals (`luna_ScreenSize`, `luna_Time`). Validated by naga before pipeline creation. Return a descriptive `LuaError` on validation failure.
- **Stencil support**: Two-phase workflow — `stencil()` writes to the stencil buffer, then `setStencilTest()` configures subsequent draws to pass/fail based on the stencil value.
- **Screenshot**: `lurek.gfx.saveScreenshot(path)` reads back the surface buffer asynchronously and encodes to PNG. Not suitable for per-frame capture.
