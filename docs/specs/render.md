# `render` — Agent Reference

| Property       | Value                                                        |
|----------------|--------------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                              |
| **Status**     | Implemented — Full                                           |
| **Lua API**    | `lurek.graphic` (81 module functions, 11 UserData types)     |
| **Source**     | `src/render/`                                                |
| **Rust Tests** | `tests/rust/unit/graphics_tests.rs`, `tests/rust/ext/graphics_ext_tests.rs`, `tests/rust/ext/graphics_runtime_smoke_tests.rs` |
| **Lua Tests**  | `tests/lua/unit/test_graphics.lua`                           |
| **Architecture** | `docs/architecture/engine-architecture.md` § Rendering Pipeline |

## Summary

The `render` module is Lurek2D's authoritative GPU rendering pipeline. It owns every
stage from the high-level draw calls Lua scripts issue through `lurek.graphic.*`, through
the deferred `RenderCommand` queue that batches all rendering work, to the wgpu GPU
backend that executes those commands against the swapchain. No other module writes pixels
to the screen; everything visual flows through this module.

The module is built around a **deferred command queue** architecture: during `lurek.render()`
and `lurek.render_ui()` callbacks, Lua pushes `RenderCommand` variants into a
`Vec<RenderCommand>` stored in `SharedState`. After each Lua callback returns,
`GpuRenderer::render_frame()` processes the queue in one GPU encoder pass. Lua never touches
the GPU directly — it constructs a declarative list of rendering intent, and the renderer has
full visibility over the draw list to minimise pipeline state switches before any GPU work begins.

All GPU resources (textures, fonts, canvases, shaders, meshes, sprite batches, and compound
shapes) are identified by typed `SlotMap` keys that are opaque to Lua. `LuaImage`, `LuaFont`,
`LuaCanvas`, `LuaShader`, `LuaMesh`, `LuaSpriteBatch`, `LuaShape`, `LuaQuad`, `LuaNineSlice`,
`LuaImageData`, and `LuaDrawLayer` UserData types are thin wrappers around the corresponding
`*Key` handles or value types; the actual `wgpu::Texture` objects and GPU pipelines live inside
`GpuRenderer`.

**Scope boundary**: This module covers only the core rendering pipeline registered by
`src/lua_api/render_api.rs` as `lurek.graphic`. The camera system (`lurek.camera`), visual
effects (`lurek.overlay`/`lurek.postfx`), and lighting (`lurek.light`) are sub-systems under
`src/render/camera/`, `src/render/effect/`, and `src/render/light/` respectively — each has
its own spec and Lua API file.

## Architecture

```
lurek.graphic.*  (Lua API — src/lua_api/render_api.rs)
    │  81 module functions, 11 UserData types
    │
    ▼
RenderCommand queue  (SharedState::render_commands)
    │  50+ variants: shapes, images, text, canvas, transform, stencil, depth,
    │  blend mode, wireframe, scissor, color mask, mesh sync, screenshots
    │
    ▼
GpuRenderer  (src/render/gpu_renderer.rs — wgpu backend)
    ├── wgpu Device + Queue + Surface (swapchain)
    ├── Pipeline cache (blend modes × wireframe × shader × stencil × color-mask)
    ├── Depth/stencil texture  (Depth24PlusStencil8)
    ├── GPU resource pools
    │     ├── gpu_textures         SlotMap<TextureKey, GpuTexture>
    │     ├── canvas_gpu_textures  SlotMap<CanvasKey, GpuTexture>
    │     └── font_atlas_textures  SlotMap<FontKey, GpuTexture>
    ├── Vertex buffers (pre-allocated — 131K color verts, 16K texture verts)
    └── Per-frame transform stack (Mat3)

src/render/mod.rs  (re-exports all submodules)
    │
    ├── renderer.rs ──── RenderCommand (50+ variants), BlendMode, DrawMode,
    │                     TextAlign, StencilMode, StencilAction, CompareMode,
    │                     DepthMode, TextureData, DrawableKind
    │
    ├── canvas.rs ────── Canvas (off-screen render target metadata)
    ├── font.rs ─────── Font (TTF/OTF, fontdue glyph atlas, bitmap PNG)
    ├── texture.rs ───── Texture (PNG/JPEG/BMP loader, premultiplied alpha)
    ├── shader.rs ────── Shader (WGSL source, naga validation, uniforms)
    ├── mesh.rs ──────── Mesh (custom geometry, per-vertex pos/UV/color)
    ├── sprite_batch.rs  SpriteBatch (batched quad rendering, one draw call)
    ├── shape.rs ─────── CompoundShape + ShapeCommand (vector primitive builder)
    ├── nine_slice.rs ── NineSlice (9-patch image rendering)
    ├── sprite.rs ────── Sprite (texture + transform + tint)
    ├── sprite_sheet.rs  SpriteSheet (grid animation, named frame groups)
    ├── draw_layer.rs ── DrawLayer (z-ordered draw callback queue)
    ├── decal_surface.rs DecalSurface (persistent stamp descriptor)
    ├── texture_atlas.rs TextureAtlas (CPU-side shelf bin-packing)
    ├── image_effect.rs  ShaderPassDescriptor (per-image shader effect)
    └── gpu_renderer.rs  GpuRenderer (wgpu backend, render passes)

Sub-systems (separate specs):
    ├── camera/ ──────── Camera2D, shake, zoom, follow (→ docs/specs/camera.md)
    ├── effect/ ──────── Post-processing, overlays (→ docs/specs/effect.md)
    └── light/ ───────── 2D lighting, shadow maps (→ docs/specs/light.md)
```

## Source Files

| File                | Purpose                                                               |
|---------------------|-----------------------------------------------------------------------|
| `mod.rs`            | Module root — declares all submodules via `pub mod` and re-exports public types |
| `renderer.rs`       | `RenderCommand` enum (50+ variants), `BlendMode`, `DrawMode`, `TextAlign`, `StencilMode`, `StencilAction`, `CompareMode`, `DepthMode`, `TextureData`, and related types |
| `gpu_renderer.rs`   | wgpu-backed 2D renderer; processes `RenderCommand` queue, manages GPU resources, pipeline cache, and render passes |
| `canvas.rs`         | Off-screen render target metadata (`Canvas` struct with width/height) |
| `font.rs`           | TTF/OTF font loading via fontdue, glyph rasterization, shelf-packed RGBA atlas, built-in bitmap font |
| `texture.rs`        | Texture loading (PNG/JPEG/BMP), premultiplied-alpha conversion, and `TextureKey` handle |
| `shader.rs`         | Custom WGSL shader support — source validation via naga, uniform variables, per-shader pipeline |
| `mesh.rs`           | Custom geometry mesh with per-vertex position, UV, and color data     |
| `sprite_batch.rs`   | Sprite batching for efficient rendering of many sprites sharing one texture |
| `shape.rs`          | `CompoundShape` builder and `ShapeCommand` sub-enum for multi-primitive vector drawing |
| `nine_slice.rs`     | Nine-slice (9-patch) image rendering for scalable UI elements         |
| `sprite.rs`         | `Sprite` struct — texture handle + transform + tint color wrapper     |
| `sprite_sheet.rs`   | Grid-based sprite sheet with directional support and named frame groups |
| `draw_layer.rs`     | Z-ordered draw callback queue for controlling render order            |
| `decal_surface.rs`  | Persistent surface descriptor for stamping decal textures             |
| `texture_atlas.rs`  | CPU-side bin-packing texture atlas using the shelf algorithm           |
| `image_effect.rs`   | Lightweight per-image shader-effect pass descriptor for the draw command pipeline |
| `color.rs`          | Legacy `Color` struct file; not declared in `mod.rs` — canonical `Color` is in `src/math/color.rs` |

## Submodules

### `render::renderer` — RenderCommand Queue and Draw Types

The central data model for the deferred rendering pipeline. `RenderCommand` is a fat enum with
50+ variants encoding every drawable operation — shapes, images, text, canvas switches, transform
stack manipulation, stencil/depth state, blend modes, and resource synchronization. The queue is
filled during Lua callbacks and consumed by `GpuRenderer::render_frame()`.

- **`RenderCommand`** (enum): 50+ variant enum encoding every drawable GPU operation.
- **`BlendMode`** (enum): `Alpha`, `Add`, `Multiply`, `Replace`, `Screen`.
- **`DrawMode`** (enum): `Fill` or `Line` draw style.
- **`TextAlign`** (enum): `Left`, `Center`, `Right`, `Justify` text alignment.
- **`StencilMode`** (struct): Combined stencil action + compare + value.
- **`StencilAction`** (enum): `Keep`, `Zero`, `Replace`, `Increment`, `Decrement`, `IncrementWrap`, `DecrementWrap`, `Invert`.
- **`CompareMode`** (enum): `Equal`, `NotEqual`, `Less`, `LessEqual`, `Greater`, `GreaterEqual`, `Always`, `Never`.
- **`DepthMode`** (enum): `Always`, `Never`, `Less`, `LessEqual`, `Equal`, `NotEqual`, `Greater`, `GreaterEqual`.
- **`DrawableKind`** (enum): Canvas vs. swapchain render-target tag.
- **`TextureData`** (struct): CPU-side `RgbaImage` pixel buffer with deduplication path.

### `render::gpu_renderer` — wgpu Backend

Owns the wgpu device, surface, pipeline cache, and GPU resource pools. Processes the
`RenderCommand` queue once per frame via `render_frame()`. Manages GPU-side textures,
canvas framebuffers, and font atlas uploads. Pre-allocates vertex buffers at startup
(131K color vertices, 16K texture vertices) to avoid per-frame heap allocations.

- **`GpuRenderer`** (struct): Full wgpu backend — device, surface, pipeline cache, GPU resource pools, vertex buffers, transform stack.
- **`RenderStats`** (struct): Per-frame statistics — draw calls, texture count, font count, canvas count, texture memory.

### `render::canvas` — Off-screen Render Targets

- **`Canvas`** (struct): Width × height metadata for a GPU-managed off-screen render surface. Constructor: `Canvas::new(width, height)`.

### `render::font` — Font Loading and Atlas

TTF/OTF font loading via fontdue with glyph rasterization and a CPU-side shelf-packed RGBA
atlas. Also supports loading bitmap PNG fonts with fixed cell dimensions. Built-in fonts are
available at multiple pixel heights via `Font::nearest_size()`.

- **`Font`** (struct): TTF/OTF or bitmap font backed by fontdue; owns glyph atlas, line metrics, and text measurement.
- **`GlyphInfo`** (struct): Cached rasterized glyph metrics and atlas coordinates.
- **`AVAILABLE_HEIGHTS`** (const): Array of built-in font pixel heights.

### `render::texture` — Texture Loading

- **`Texture`** (struct): Loaded GPU texture with `TextureKey` handle, width, height, and path metadata. Loader: `Texture::load()`, `Texture::from_rgba()`.

### `render::shader` — Custom WGSL Shaders

- **`Shader`** (struct): Custom WGSL fragment shader with named uniform variables; naga-validated at load time. Methods: `new()`, `send()`, `has_uniform()`.
- **`UniformValue`** (enum): `Float`, `Int`, `Bool`, `Vec2`, `Vec3`, `Vec4` typed uniform binding.

### `render::mesh` — Custom Geometry Mesh

- **`Mesh`** (struct): Indexed geometry with per-vertex position, UV, and color. Constructed from vertex row arrays. Methods: `from_vertex_rows()`, `vertex_count()`, `get_vertex()`, `set_vertex()`, `set_texture()`.
- **`MeshVertex`** (struct): Single vertex — position `(x, y)`, UV `(u, v)`, color `(r, g, b, a)`.
- **`MeshDrawMode`** (enum): `Triangles`, `Fan`, `Strip` draw topology.

### `render::sprite_batch` — Efficient Multi-Sprite Rendering

- **`SpriteBatch`** (struct): Pre-sorted `BatchEntry` quad list sharing one texture; rendered in a single GPU draw call. Methods: `new()`, `add()`, `clear()`, `len()`, `buffer_size()`.
- **`BatchEntry`** (struct): Single sprite entry — position, quad offsets, rotation, scale, origin.

### `render::shape` — Compound Vector Shapes

- **`CompoundShape`** (struct): Builder accumulating `ShapeCommand` sub-operations for batched vector drawing. Methods: `new()`, `push_command()`, `clear()`, `command_count()`.
- **`ShapeCommand`** (enum): Sub-operations — `Rectangle`, `RoundedRectangle`, `Circle`, `Ellipse`, `Triangle`, `Polygon`, `Line`, `Polyline`, `Arc`, `Point`, `SetColor`, `SetLineWidth`.

### `render::nine_slice` — 9-Patch Image Rendering

- **`NineSlice`** (struct): Nine-slice descriptor with four inset distances (top, right, bottom, left).
- **`Patch`** (struct): One of 9 rectangular quads composing the slice layout.

### `render::sprite` — Sprite Wrapper

- **`Sprite`** (struct): Combines `TextureKey`, transform, and tint color into a drawable object.

### `render::sprite_sheet` — Grid-Based Sprite Sheet

- **`SpriteSheet`** (struct): Grid animation source with named frame groups and directional support.

### `render::draw_layer` — Z-Ordered Draw Callbacks

- **`DrawLayer`** (struct): Ordered list of draw callbacks keyed by layer index.

### `render::decal_surface` — Decal Stamp Surface

- **`DecalSurface`** (struct): Persistent descriptor for stamping decal textures onto surfaces.

### `render::texture_atlas` — CPU Bin-Packing Atlas

- **`TextureAtlas`** (struct): Shelf-algorithm CPU-side texture atlas packing utility.

### `render::image_effect` — Shader Effect Pass

- **`ShaderPassDescriptor`** (struct): Lightweight descriptor for a per-image shader pass in the pipeline.

## Key Types

### Structs

#### `render::gpu_renderer::GpuRenderer`

Owns the wgpu device, surface, swapchain, render pipeline cache, and GPU resource pools.
Processes the `RenderCommand` queue once per frame via `render_frame()`. Pre-allocates
131K color vertices and 16K texture vertices at startup. Caches render pipelines keyed by
`(BlendMode, shader_key, wireframe_flag)` to minimise state switches. Manages depth/stencil
texture (`Depth24PlusStencil8`) and canvas framebuffers.

#### `render::canvas::Canvas`

Off-screen render target metadata. Stores `width` and `height` in pixels. The GPU-side
framebuffer texture is managed by `GpuRenderer` and keyed by `CanvasKey`.

#### `render::font::Font`

TTF/OTF font backed by fontdue, or bitmap PNG font with fixed cell dimensions. Owns the
CPU-side glyph shelf-atlas (RGBA) and uploads to a GPU atlas texture on demand. Provides
text measurement (`text_width`, `wrap_text`), line metrics (`line_height`, `ascent`, `descent`),
and built-in size selection via `nearest_size()`.

#### `render::texture::Texture`

Loaded texture with `TextureKey` handle. Supports PNG, JPEG, and BMP formats. Applies
premultiplied-alpha conversion on load. Deduplication via path matching in the texture pool.

#### `render::shader::Shader`

Custom WGSL fragment shader. Source is validated at load time via the naga shader compiler.
Named uniform variables (float, int, bool, vec2–vec4) can be set per-frame via `send()`.
Each unique shader gets its own cached `wgpu::RenderPipeline`.

#### `render::mesh::Mesh`

Custom geometry with per-vertex data: position `(x, y)`, UV `(u, v)`, color `(r, g, b, a)`.
Supports three draw topologies: `Triangles`, `Fan`, `Strip`. Optionally textured via
`set_texture()`. Mesh vertex data syncs to the GPU via `SyncMesh` render commands.

#### `render::sprite_batch::SpriteBatch`

Efficient multi-sprite renderer. All sprites in a batch share one texture and are rendered
in a single GPU draw call. Has a fixed maximum capacity. Entries are `BatchEntry` quads with
position, rotation, scale, and origin offset.

#### `render::shape::CompoundShape`

Builder for multi-primitive vector shapes. Accumulates `ShapeCommand` sub-operations
(rectangles, circles, lines, polygons, arcs, etc.) with per-command color and line width.
The entire shape is replayed via `DrawShape` render command with a unified affine transform.

### Enums

#### `render::renderer::RenderCommand`

Fat enum with 50+ variants encoding every drawable operation. Key variant groups:
shapes (`Rectangle`, `Circle`, `Ellipse`, `Triangle`, `Polygon`, `Line`, `Polyline`, `Arc`, `Points`, `RoundedRectangle`),
images (`DrawImage`, `DrawImageEx`, `DrawQuad`, `DrawCanvas`, `DrawNineSlice`),
text (`Print`, `PrintFormatted`),
state (`SetColor`, `SetBlendMode`, `SetLineWidth`, `SetPointSize`, `SetWireframe`, `SetScissor`, `SetColorMask`, `SetCanvas`, `SetShader`),
transform (`PushTransform`, `PopTransform`, `Translate`, `Rotate`, `Scale`, `Shear`, `Origin`, `ApplyTransform`),
stencil/depth (`StencilBegin`, `SetStencilTest`),
resources (`RegisterCanvas`, `SyncMesh`, `DrawBatch`, `DrawMesh`, `DrawShape`).

#### `render::renderer::BlendMode`

Pipeline blend modes: `Alpha` (default — standard alpha blending), `Add` (additive — glowing
effects), `Multiply` (darkening compositing), `Replace` (overwrite — no blending), `Screen`
(lightening compositing).

#### `render::renderer::DrawMode`

Draw style for shape primitives: `Fill` (solid interior) or `Line` (outline only).

#### `render::renderer::TextAlign`

Horizontal text alignment for `printf`: `Left`, `Center`, `Right`, `Justify`.

#### `render::renderer::StencilAction`

Stencil buffer write operations: `Keep`, `Zero`, `Replace`, `Increment`, `Decrement`,
`IncrementWrap`, `DecrementWrap`, `Invert`.

#### `render::renderer::CompareMode`

Depth/stencil comparison functions: `Equal`, `NotEqual`, `Less`, `LessEqual`, `Greater`,
`GreaterEqual`, `Always`, `Never`.

#### `render::renderer::DepthMode`

Depth test modes: `Always`, `Never`, `Less`, `LessEqual`, `Equal`, `NotEqual`, `Greater`,
`GreaterEqual`.

#### `render::shader::UniformValue`

Typed shader uniform values: `Float(f32)`, `Int(i32)`, `Bool(bool)`, `Vec2([f32; 2])`,
`Vec3([f32; 3])`, `Vec4([f32; 4])`.

#### `render::mesh::MeshDrawMode`

Mesh draw topologies: `Triangles`, `Fan`, `Strip`.

## Lua API

Registered by `src/lua_api/render_api.rs` as `lurek.graphic`. The namespace exposes 81
module-level functions for resource creation, 2D drawing, state management, and transform
manipulation, plus 11 UserData types with their own methods.

### Module Functions — Color

| Function | Description |
|----------|-------------|
| `lurek.graphic.setColor(r, g, b, a?)` | Sets the current drawing color (RGBA, 0–1). Alpha defaults to 1. |
| `lurek.graphic.getColor()` | Returns the current drawing color as r, g, b, a. |
| `lurek.graphic.setBackgroundColor(r, g, b)` | Sets the background clear color. |
| `lurek.graphic.getBackgroundColor()` | Returns the background clear color as r, g, b, a. |

### Module Functions — Shape Drawing

| Function | Description |
|----------|-------------|
| `lurek.graphic.rectangle(mode, x, y, w, h, rx?, ry?)` | Draws a rectangle. If rx is given, draws a rounded rectangle with corner radii rx, ry. |
| `lurek.graphic.circle(mode, x, y, radius)` | Draws a circle at (x, y) with the given radius. |
| `lurek.graphic.ellipse(mode, x, y, rx, ry)` | Draws an ellipse at (x, y) with horizontal radius rx and vertical radius ry. |
| `lurek.graphic.triangle(mode, x1, y1, x2, y2, x3, y3)` | Draws a triangle between three vertices. |
| `lurek.graphic.line(x1, y1, x2, y2, ...)` | Draws a line segment. If more than 4 coordinates are given, draws a polyline. |
| `lurek.graphic.polygon(mode, ...)` | Draws a filled or outlined polygon from variadic coordinates or a table of vertices. |
| `lurek.graphic.arc(mode, x, y, radius, angle1, angle2, segments?)` | Draws a partial circle arc. Segments defaults to 32. |
| `lurek.graphic.points(...)` | Draws a list of points from variadic x, y pairs or a table of {x, y} tables. |

### Module Functions — Drawing

| Function | Description |
|----------|-------------|
| `lurek.graphic.draw(drawable, x?, y?, r?, sx?, sy?, ox?, oy?)` | Draws an Image, Canvas, SpriteBatch, or Mesh at the given position with optional transform. |
| `lurek.graphic.drawq(image, quad, x?, y?, r?, sx?, sy?, ox?, oy?)` | Draws a sub-region of an image defined by a Quad. |
| `lurek.graphic.drawNineSlice(slice, x, y, w, h)` | Draws a 9-slice image scaled to the given rectangle. |

### Module Functions — Text

| Function | Description |
|----------|-------------|
| `lurek.graphic.print(text, x?, y?, scale?)` | Draws text at (x, y) using the active font. Scale defaults to 1. |
| `lurek.graphic.printf(text, x, y, limit, align?)` | Draws word-wrapped text within a pixel width limit. Align: "left", "center", "right", "justify". |

### Module Functions — Clear

| Function | Description |
|----------|-------------|
| `lurek.graphic.clear(r?, g?, b?)` | Clears the render command queue (resets the screen for this frame). |

### Module Functions — Line and Point Style

| Function | Description |
|----------|-------------|
| `lurek.graphic.setLineWidth(width)` | Sets the line width for outline drawing in pixels. |
| `lurek.graphic.getLineWidth()` | Returns the current line width. |
| `lurek.graphic.setPointSize(size)` | Sets the point diameter in pixels. |
| `lurek.graphic.getPointSize()` | Returns the current point size. |

### Module Functions — Blend Mode

| Function | Description |
|----------|-------------|
| `lurek.graphic.setBlendMode(mode)` | Sets the blend mode: "alpha", "add", "multiply", "replace", "screen". |
| `lurek.graphic.getBlendMode()` | Returns the current blend mode as a string. |

### Module Functions — Font Management

| Function | Description |
|----------|-------------|
| `lurek.graphic.newFont(path_or_size, size?)` | Loads a bitmap font PNG from a file path, or selects a built-in font by pixel height. Default size is 14. |
| `lurek.graphic.setFont(font)` | Sets the active font for subsequent print/printf calls. |
| `lurek.graphic.getFont()` | Returns the currently active font, or nil. |
| `lurek.graphic.getFontSizes()` | Returns a table of available built-in font pixel heights. |
| `lurek.graphic.getDefaultFont(pixel_height?)` | Returns a built-in font by pixel height (snaps to nearest available size). Default 14. |
| `lurek.graphic.getFontCellWidth(font)` | Returns the cell width of a font (for monospaced bitmap fonts). |
| `lurek.graphic.getFontWidth(font, text)` | Returns the pixel width of text rendered in the given font. |
| `lurek.graphic.getFontHeight(font)` | Returns the line height of the given font in pixels. |
| `lurek.graphic.getFontLineHeight(font)` | Returns the line height of the given font (alias for getFontHeight). |
| `lurek.graphic.setFontLineHeight(font, h)` | Sets the line height of the given font (stub — no effect in headless mode). |
| `lurek.graphic.getFontAscent(font)` | Returns the ascent of the given font in pixels. |
| `lurek.graphic.getFontDescent(font)` | Returns the descent of the given font in pixels. |
| `lurek.graphic.getFontWrap(text, limit)` | Returns wrapped lines table and maximum line width for the active font. |

### Module Functions — Image Management

| Function | Description |
|----------|-------------|
| `lurek.graphic.newImage(path_or_data)` | Loads an image from a file path string or creates one from an ImageData userdata. |

### Module Functions — Canvas Management

| Function | Description |
|----------|-------------|
| `lurek.graphic.newCanvas(width, height)` | Creates an off-screen render canvas. Width and height must be > 0. |
| `lurek.graphic.setCanvas(canvas?)` | Sets the active render target to a Canvas, or back to the screen (nil). |
| `lurek.graphic.getCanvas()` | Returns the current canvas, or nil if drawing to the screen. |
| `lurek.graphic.getCanvasSize(canvas)` | Returns the width and height of a canvas. |

### Module Functions — SpriteBatch

| Function | Description |
|----------|-------------|
| `lurek.graphic.newSpriteBatch(image, max_sprites?)` | Creates a new sprite batch for the given image. Default max is 1000. |

### Module Functions — Mesh

| Function | Description |
|----------|-------------|
| `lurek.graphic.newMesh(vertices, mode?)` | Creates a custom mesh from a table of vertex rows `{x, y, u, v, r, g, b, a}`. Mode: "triangles" (default), "fan", "strip". |

### Module Functions — Shader

| Function | Description |
|----------|-------------|
| `lurek.graphic.newShader(code)` | Compiles a custom WGSL fragment shader and returns its handle. Validated via naga. |
| `lurek.graphic.setShader(shader?)` | Sets the active shader for subsequent draw calls, or clears it (nil). |
| `lurek.graphic.getShader()` | Returns the active shader, or nil. |

### Module Functions — Quad

| Function | Description |
|----------|-------------|
| `lurek.graphic.newQuad(x, y, w, h, sw, sh)` | Creates a Quad viewport rectangle (x, y, w, h) referencing a texture of size (sw, sh). |

### Module Functions — NineSlice

| Function | Description |
|----------|-------------|
| `lurek.graphic.newNineSlice(image, top, right, bottom, left)` | Creates a 9-slice descriptor from an image and four non-negative inset values. |

### Module Functions — Shape and DrawLayer

| Function | Description |
|----------|-------------|
| `lurek.graphic.newShape()` | Creates a new empty CompoundShape for batched vector drawing. |
| `lurek.graphic.newDrawLayer()` | Creates a new z-ordered draw-call queue for controlling render order. |

### Module Functions — Transform Stack

| Function | Description |
|----------|-------------|
| `lurek.graphic.push()` | Pushes the current transform onto the stack. |
| `lurek.graphic.pop()` | Pops the transform from the stack. |
| `lurek.graphic.translate(x, y)` | Translates the coordinate system. |
| `lurek.graphic.rotate(angle)` | Rotates the coordinate system by angle (radians). |
| `lurek.graphic.scale(sx, sy?)` | Scales the coordinate system. sy defaults to sx for uniform scaling. |
| `lurek.graphic.shear(kx, ky)` | Shears the coordinate system. |
| `lurek.graphic.origin()` | Resets the transform to the identity matrix. |
| `lurek.graphic.applyTransform(matrix)` | Applies an affine transform from a 9-element table (3×3 row-major matrix). |

### Module Functions — Scissor

| Function | Description |
|----------|-------------|
| `lurek.graphic.setScissor(x?, y?, w?, h?)` | Restricts drawing to a rectangle. Call with no args to clear the scissor. |
| `lurek.graphic.getScissor()` | Returns the active scissor rectangle as x, y, w, h — or nothing if no scissor is set. |
| `lurek.graphic.intersectScissor(x, y, w, h)` | Intersects the current scissor with a new rectangle. Sets scissor if none exists. |

### Module Functions — Color Mask

| Function | Description |
|----------|-------------|
| `lurek.graphic.setColorMask(r?, g?, b?, a?)` | Sets which RGBA channels are written (booleans). Call with no args to reset all to true. |
| `lurek.graphic.getColorMask()` | Returns the current color mask as r, g, b, a booleans. |

### Module Functions — Wireframe

| Function | Description |
|----------|-------------|
| `lurek.graphic.setWireframe(enabled)` | Enables or disables wireframe rendering mode. |
| `lurek.graphic.isWireframe()` | Returns whether wireframe mode is active. |

### Module Functions — Stencil

| Function | Description |
|----------|-------------|
| `lurek.graphic.stencil(action?, value?)` | Begins stencil writing. Action: "replace" (default), "keep", "zero", "increment", "decrement", "incrementwrap", "decrementwrap", "invert". Value defaults to 1. |
| `lurek.graphic.setStencilTest(compare?, value?)` | Sets the stencil comparison test, or disables stencil testing (nil). Compare: "equal", "notequal", "less", "lequal", "greater", "gequal", "always", "never". |
| `lurek.graphic.setStencilMode(action, compare?, value?)` | Sets the stencil buffer write/test mode as a combined action + compare + value. |
| `lurek.graphic.getStencilMode()` | Returns the current stencil mode as (action, compare, value). |
| `lurek.graphic.clearStencil()` | Resets the stencil mode to the default (keep / always / 0). |

### Module Functions — Depth

| Function | Description |
|----------|-------------|
| `lurek.graphic.setDepthMode(mode, write?)` | Sets the depth test comparison function. Write defaults to false. |
| `lurek.graphic.getDepthMode()` | Returns the current depth mode as (mode, write). |

### Module Functions — Window Dimensions

| Function | Description |
|----------|-------------|
| `lurek.graphic.getWidth()` | Returns the window width in pixels. |
| `lurek.graphic.getHeight()` | Returns the window height in pixels. |
| `lurek.graphic.getDimensions()` | Returns the window width and height. |

### Module Functions — Default Filter

| Function | Description |
|----------|-------------|
| `lurek.graphic.setDefaultFilter(min, mag, anisotropy?)` | Sets the default texture filter mode. Anisotropy defaults to 1. |
| `lurek.graphic.getDefaultFilter()` | Returns the default texture filter as (min, mag, anisotropy). |

### Module Functions — Stats and Screenshots

| Function | Description |
|----------|-------------|
| `lurek.graphic.getStats()` | Returns a table with renderer statistics: drawcalls, textures, fonts, canvases, texture_memory. |
| `lurek.graphic.saveScreenshot(path)` | Queues a screenshot to be saved after the current frame. Path must start with "save/". |
| `lurek.graphic.captureScreenshot(callback)` | Calls the callback with an ImageData captured from the current frame. |

### ImageData Methods

| Method | Description |
|--------|-------------|
| `imgData:getWidth()` | Returns the pixel width of this image buffer. |
| `imgData:getHeight()` | Returns the pixel height of this image buffer. |
| `imgData:type()` | Returns `"ImageData"`. |
| `imgData:typeOf(name)` | Returns true when name matches `"ImageData"` or `"Object"`. |

### Image Methods

| Method | Description |
|--------|-------------|
| `img:getWidth()` | Returns the width of this image in pixels. |
| `img:getHeight()` | Returns the height of this image in pixels. |
| `img:getDimensions()` | Returns width and height as two integers. |
| `img:release()` | Releases GPU texture memory; returns true on success. |
| `img:type()` | Returns `"Image"`. |
| `img:typeOf()` | Returns `"Image"`. |

### NineSlice Methods

| Method | Description |
|--------|-------------|
| `ns:getInsets()` | Returns the four inset values as top, right, bottom, left. |
| `ns:getTextureSize()` | Returns the source texture width and height. |
| `ns:draw(x, y, w, h)` | Compatibility stub (use `lurek.graphic.drawNineSlice` instead). |
| `ns:type()` | Returns `"NineSlice"`. |
| `ns:typeOf(name)` | Returns true when name matches `"NineSlice"` or `"Object"`. |

### Font Methods

| Method | Description |
|--------|-------------|
| `font:getWidth(text)` | Returns the rendered pixel width of text. |
| `font:getHeight()` | Returns the line height of this font in pixels. |
| `font:getLineHeight()` | Returns the line height multiplier. |
| `font:setLineHeight(h)` | Sets the line height multiplier. |
| `font:getAscent()` | Returns the ascent in pixels. |
| `font:getDescent()` | Returns the descent in pixels. |
| `font:getWrap(text, limit)` | Wraps text to the given width; returns lines table and max width. |
| `font:release()` | Releases font atlas memory; returns true on success. |
| `font:type()` | Returns `"Font"`. |
| `font:typeOf()` | Returns `"Font"`. |

### Canvas Methods

| Method | Description |
|--------|-------------|
| `canvas:getWidth()` | Returns the canvas width in pixels. |
| `canvas:getHeight()` | Returns the canvas height in pixels. |
| `canvas:getDimensions()` | Returns width and height as two integers. |
| `canvas:release()` | Releases GPU framebuffer; returns true on success. |
| `canvas:type()` | Returns `"Canvas"`. |
| `canvas:typeOf()` | Returns `"Canvas"`. |

### SpriteBatch Methods

| Method | Description |
|--------|-------------|
| `batch:add(x, y, r?, sx?, sy?, ox?, oy?)` | Adds a sprite entry; returns 1-based index or nil when full. |
| `batch:clear()` | Removes all sprites from this batch. |
| `batch:getCount()` | Returns the number of sprites in this batch. |
| `batch:getBufferSize()` | Returns the maximum capacity. |
| `batch:release()` | Releases this sprite batch; returns true on success. |
| `batch:type()` | Returns `"SpriteBatch"`. |
| `batch:typeOf()` | Returns `"SpriteBatch"`. |

### Mesh Methods

| Method | Description |
|--------|-------------|
| `mesh:getVertexCount()` | Returns the number of vertices. |
| `mesh:getVertex(i)` | Returns x, y, u, v, r, g, b, a for the vertex at 1-based index i. |
| `mesh:setVertex(i, data)` | Sets vertex data at 1-based index from a flat table {x, y, u, v, r, g, b, a}. |
| `mesh:setTexture(img?)` | Assigns a texture to this mesh, or clears it (nil). |
| `mesh:release()` | Releases this mesh; returns true on success. |
| `mesh:type()` | Returns `"Mesh"`. |
| `mesh:typeOf()` | Returns `"Mesh"`. |

### Shader Methods

| Method | Description |
|--------|-------------|
| `shader:send(name, value)` | Sends a uniform value (number, boolean, or 2–4 element table). |
| `shader:hasUniform(name)` | Returns whether this shader has a uniform with the given name. |
| `shader:release()` | Releases this shader; returns true on success. |
| `shader:type()` | Returns `"Shader"`. |
| `shader:typeOf()` | Returns `"Shader"`. |

### Quad Methods

| Method | Description |
|--------|-------------|
| `quad:getViewport()` | Returns the source rectangle as x, y, w, h. |
| `quad:setViewport(x, y, w, h)` | Sets the source rectangle. |
| `quad:getTextureDimensions()` | Returns the reference texture width and height. |
| `quad:type()` | Returns `"Quad"`. |
| `quad:typeOf()` | Returns `"Quad"`. |

### Shape Methods

| Method | Description |
|--------|-------------|
| `shape:getCommandCount()` | Returns the number of drawing commands stored. |
| `shape:clear()` | Removes all commands and resets the shape to empty. |
| `shape:setColor(r, g, b, a?)` | Sets the drawing color for subsequent primitives. Alpha defaults to 1. |
| `shape:setLineWidth(w)` | Sets the stroke width for subsequent outlined primitives. |
| `shape:rectangle(mode, x, y, w, h)` | Queues a rectangle command ("fill" or "line"). |
| `shape:roundedRectangle(mode, x, y, w, h, rx, ry?)` | Queues a rounded rectangle command. ry defaults to rx. |
| `shape:circle(mode, x, y, r)` | Queues a circle command. |
| `shape:ellipse(mode, x, y, rx, ry)` | Queues an ellipse command. |
| `shape:triangle(mode, x1, y1, x2, y2, x3, y3)` | Queues a triangle command. |
| `shape:polygon(mode, ...)` | Queues a polygon from variadic coordinate pairs (minimum 3 vertices). |
| `shape:line(x1, y1, x2, y2)` | Queues a line segment command. |
| `shape:polyline(...)` | Queues a polyline from variadic coordinate pairs (minimum 2 points). |
| `shape:arc(mode, x, y, r, a1, a2, segments?)` | Queues an arc command. Segments defaults to 32. |
| `shape:draw(x, y, rotation?, sx?, sy?, ox?, oy?)` | Queues a DrawShape render command for this shape at the given position. |
| `shape:type()` | Returns `"Shape"`. |
| `shape:typeOf(name)` | Returns true when name matches `"Shape"` or `"Object"`. |

### DrawLayer Methods

| Method | Description |
|--------|-------------|
| `layer:queue(z, fn)` | Queues a draw callback at the given z-order value. |
| `layer:flush()` | Sorts and calls all queued callbacks by ascending z, then empties the queue. |
| `layer:clear()` | Removes all queued callbacks without calling them. |
| `layer:getCount()` | Returns the number of queued callbacks. |
| `layer:type()` | Returns `"DrawLayer"`. |
| `layer:typeOf(name)` | Returns true when name matches `"DrawLayer"` or `"Object"`. |

## Lua Examples

```lua
-- Basic image and text rendering
local img  = lurek.graphic.newImage("assets/player.png")
local font = lurek.graphic.newFont("assets/ui.ttf", 24)

lurek.render = function()
    -- Fill background
    lurek.graphic.setColor(0.1, 0.1, 0.2, 1.0)
    lurek.graphic.rectangle("fill", 0, 0, 800, 600)

    -- Draw sprite at original size
    lurek.graphic.setColor(1, 1, 1, 1)
    lurek.graphic.draw(img, 100, 200)

    -- Draw with transform stack
    lurek.graphic.push()
    lurek.graphic.translate(400, 300)
    lurek.graphic.rotate(math.pi / 4)
    lurek.graphic.draw(img, -32, -32)
    lurek.graphic.pop()

    -- Draw filled circle
    lurek.graphic.setColor(1, 0.5, 0, 1)
    lurek.graphic.circle("fill", 200, 400, 40)

    -- Print text
    lurek.graphic.setColor(1, 1, 0, 1)
    lurek.graphic.setFont(font)
    lurek.graphic.print("Score: 100", 10, 10)
end
```

```lua
-- Canvas (off-screen render target)
local fb = lurek.graphic.newCanvas(800, 600)

lurek.render = function()
    lurek.graphic.setCanvas(fb)
    lurek.graphic.setColor(0, 0, 0, 1)
    lurek.graphic.rectangle("fill", 0, 0, 800, 600)
    -- ... draw scene to canvas ...
    lurek.graphic.setCanvas(nil)

    -- Composite canvas onto screen
    lurek.graphic.setColor(1, 1, 1, 1)
    lurek.graphic.draw(fb, 0, 0)
end
```

```lua
-- Custom WGSL shader
local shader = lurek.graphic.newShader([[
    @fragment fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
        return vec4<f32>(uv.x, uv.y, 0.5, 1.0);
    }
]])

lurek.render = function()
    lurek.graphic.setShader(shader)
    lurek.graphic.draw(img, 0, 0)
    lurek.graphic.setShader(nil)
end
```

```lua
-- CompoundShape for batched vector drawing
local hud = lurek.graphic.newShape()
hud:setColor(0.2, 0.2, 0.3, 0.8)
hud:rectangle("fill", 0, 0, 200, 50)
hud:setColor(1, 1, 1, 1)
hud:line(0, 50, 200, 50)

lurek.render_ui = function()
    hud:draw(10, 10) -- replay all commands with one draw call
end
```

```lua
-- Quad-based sprite sheet clipping
local sheet = lurek.graphic.newImage("assets/tileset.png")
local q = lurek.graphic.newQuad(0, 0, 32, 32, 256, 256)

lurek.render = function()
    lurek.graphic.setColor(1, 1, 1, 1)
    lurek.graphic.drawq(sheet, q, 100, 100)
end
```

```lua
-- DrawLayer for z-ordered rendering
local layer = lurek.graphic.newDrawLayer()

lurek.render = function()
    layer:queue(10, function()
        lurek.graphic.setColor(1, 0, 0, 1)
        lurek.graphic.rectangle("fill", 50, 50, 100, 100)
    end)
    layer:queue(5, function()
        lurek.graphic.setColor(0, 0, 1, 1)
        lurek.graphic.rectangle("fill", 75, 75, 100, 100)
    end)
    layer:flush() -- blue drawn first (z=5), then red (z=10)
end
```

```lua
-- 9-slice UI panel
local panel_img = lurek.graphic.newImage("assets/panel.png")
local panel = lurek.graphic.newNineSlice(panel_img, 8, 8, 8, 8)

lurek.render_ui = function()
    lurek.graphic.setColor(1, 1, 1, 1)
    lurek.graphic.drawNineSlice(panel, 20, 20, 300, 200)
end
```

```lua
-- Custom mesh (textured quad)
local mesh = lurek.graphic.newMesh({
    {0,   0,   0, 0, 1, 1, 1, 1},  -- top-left
    {100, 0,   1, 0, 1, 1, 1, 1},  -- top-right
    {100, 100, 1, 1, 1, 1, 1, 1},  -- bottom-right
    {0,   100, 0, 1, 1, 1, 1, 1},  -- bottom-left
}, "fan")

local tex = lurek.graphic.newImage("assets/tile.png")
mesh:setTexture(tex)

lurek.render = function()
    lurek.graphic.setColor(1, 1, 1, 1)
    lurek.graphic.draw(mesh, 200, 100)
end
```

```lua
-- Stencil masking
lurek.render = function()
    -- Write circle to stencil buffer
    lurek.graphic.stencil("replace", 1)
    lurek.graphic.circle("fill", 400, 300, 100)

    -- Only draw where stencil == 1
    lurek.graphic.setStencilTest("equal", 1)
    lurek.graphic.setColor(1, 1, 1, 1)
    lurek.graphic.draw(img, 300, 200)
    lurek.graphic.setStencilTest() -- disable
end
```

## Item Summary

| Kind                    | Count |
|-------------------------|-------|
| Structs (Rust)          | 18    |
| Enums (Rust)            | 12    |
| Module Functions (Lua)  | 81    |
| UserData Types          | 11    |
| UserData Methods (Lua)  | 77    |
| **Total public items**  | **199** |

## References

| Module       | Relationship | Notes |
|--------------|-------------|-------|
| `runtime`    | Imports from | `SharedState` holds `render_commands: Vec<RenderCommand>` and the typed `SlotMap` resource pools (`textures`, `fonts`, `canvases`, `shaders`, `meshes`, `sprite_batches`, `shapes`). |
| `math`       | Imports from | `Color`, `Vec2`, `Mat3`, `Rect` are imported from `src/math/` and used throughout render types. |
| `image`      | Imports from | `src/image/` provides `ImageData` (raw pixel buffer) used by `captureScreenshot` and `newImage(ImageData)`. |
| `lua_api`    | Imported by  | `render_api.rs` binds all public types and functions to `lurek.graphic.*`. |
| `camera`     | Sub-system   | `src/render/camera/` — camera offsets the transform stack; integrated via `SetCamera` render command. Separate spec: `docs/specs/camera.md`. |
| `effect`     | Sub-system   | `src/render/effect/` — post-processing effects driven via `BeginPostFx`/`EndPostFx`/`ApplyPostFx` commands. Separate spec: `docs/specs/effect.md`. |
| `light`      | Sub-system   | `src/render/light/` — 2D lighting, shadow maps, occlusion geometry. Separate spec: `docs/specs/light.md`. |
| `particle`   | Used by      | `src/particle/` pushes `DrawParticleSystem` commands into the render queue. |
| `tilemap`    | Used by      | `src/tilemap/` pushes tile draw commands into the render queue. |

## Notes

- **Deferred rendering**: Lua closures never touch the GPU directly. `GpuRenderer::render_frame()` processes the full `RenderCommand` queue in a single encoder pass after each callback returns.
- **Pre-allocated vertex buffers**: 131K color vertices and 16K texture vertices are allocated at startup and reused every frame — no per-frame heap allocations in the hot path.
- **Depth/stencil format**: `Depth24PlusStencil8`; the 8-bit stencil provides masking and cut-out operations via `StencilMode`.
- **Pipeline cache**: The renderer caches `wgpu::RenderPipeline` objects keyed by `(BlendMode, shader_key, wireframe_flag)` to minimise state switches during a frame.
- **`color.rs` status**: `src/render/color.rs` exists as a file but is not declared in `mod.rs`. The canonical `Color` type for the engine lives in `src/math/color.rs`.
- **Namespace**: The Lua namespace is `lurek.graphic` (singular), registered by `src/lua_api/render_api.rs`. The Rust module is `src/render/`.
- **newFont dual mode**: `newFont` accepts either a file path string (loads bitmap PNG font) or a number (selects a built-in font by pixel height). The keyword `"default"` also selects a built-in font.
- **Screenshot path restriction**: `saveScreenshot` enforces that the path starts with `"save/"` to prevent writing outside the sandboxed save directory.
- **Mesh vertex format**: Each mesh vertex is 8 floats: `{x, y, u, v, r, g, b, a}` (position, UV, color). 1-based indexing in Lua.
- **Breaking change surface**: Adding a new `RenderCommand` variant is backward-compatible. Renaming or removing an existing variant breaks any serialized replay or record files. Renaming or removing any `lurek.graphic.*` function breaks game scripts.
# `render` — Agent Reference

| Property       | Value                                                        |
|----------------|--------------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                              |
| **Status**     | Implemented — Full                                           |
| **Lua API**    | `lurek.graphic` (66 functions, 7 UserData types)             |
| **Source**     | `src/render/`                                                |
| **Rust Tests** | `tests/rust/unit/graphics_tests.rs`, `tests/rust/ext/graphics_ext_tests.rs`, `tests/rust/ext/graphics_runtime_smoke_tests.rs` |
| **Lua Tests**  | `tests/lua/unit/test_graphics.lua`                           |
| **Architecture** | `docs/architecture/engine-architecture.md` § Rendering Pipeline |

## Summary

`src/render/` is the authoritative GPU rendering pipeline for Lurek2D. It owns every
stage from the high-level draw calls Lua scripts issue through `lurek.graphic.*`, through
the deferred `RenderCommand` queue that batches all rendering work, to the wgpu GPU
backend that executes those commands against the swapchain. No other module writes pixels
to the screen; everything visual flows through this module.

The module is built around a **deferred command queue** architecture: during `lurek.draw()`
Lua pushes `RenderCommand` variants into a `Vec<RenderCommand>` stored in `SharedState`.
After the Lua callback returns, `GpuRenderer::render_frame()` processes the queue in one
GPU encoder pass. Lua never touches the GPU directly — it constructs a declarative list of
rendering intent, and the renderer has full visibility over the draw list to minimise
pipeline state switches before any GPU work begins.

All GPU resources (textures, fonts, canvases, shaders, meshes, sprite batches, and compound
shapes) are identified by typed `SlotMap` keys that are opaque to Lua. `LuaImage`,
`LuaFont`, `LuaCanvas`, `LuaShader`, `LuaMesh`, `LuaSpriteBatch`, and `LuaShape` UserData
types are thin wrappers around the corresponding `*Key` handles; the actual `wgpu::Texture`
objects and GPU pipelines live inside `GpuRenderer`.

> **Source boundary:** `src/render/` is the canonical home for the GPU pipeline. The legacy
> `src/graphics/` directory contains only `gpu_renderer.rs` as a transitional artefact; it
> will be merged into `src/render/` and removed in a future cleanup. All new GPU work goes
> in `src/render/`.

## Architecture

```
lurek.graphic.* (Lua API — src/lua_api/render_api.rs)
  │  66 functions, 7 UserData types
  │
  ▼
RenderCommand queue  (SharedState::render_commands)
  │  45+ variants: shapes, images, text, state, transforms, stencil, post-fx
  │
  ▼
GpuRenderer  (src/render/gpu_renderer.rs — wgpu backend)
  ├── wgpu Device + Queue + Surface (swapchain)
  ├── Pipeline cache (5 blend modes × wireframe, stencil, color-mask, custom shaders)
  ├── Depth/stencil texture  (Depth24PlusStencil8)
  ├── GPU resource pools
  │     ├── gpu_textures         SlotMap<TextureKey, GpuTexture>
  │     ├── canvas_gpu_textures  SlotMap<CanvasKey, GpuTexture>
  │     └── font_atlas_textures  SlotMap<FontKey, GpuTexture>
  ├── Vertex buffers (pre-allocated — 131K color verts, 16K texture verts)
  └── Per-frame transform stack (Mat3)
```

## Source Files

| File                | Purpose                                                               |
|---------------------|-----------------------------------------------------------------------|
| `canvas.rs`         | Off-screen render target metadata (`Canvas` struct with width/height) |
| `decal_surface.rs`  | Persistent surface descriptor for stamping decal textures             |
| `draw_layer.rs`     | Z-ordered draw callback queue for controlling render order            |
| `font.rs`           | TTF/OTF font loading via fontdue, glyph rasterization, shelf-packed RGBA atlas |
| `gpu_renderer.rs`   | wgpu-backed 2D renderer; processes `RenderCommand` queue, manages GPU resources and render passes |
| `image_effect.rs`   | Per-image shader-effect pass descriptor for the draw command pipeline |
| `mesh.rs`           | Custom geometry mesh with per-vertex position, UV, and color data     |
| `nine_slice.rs`     | Nine-slice (9-patch) image rendering for scalable UI elements         |
| `renderer.rs`       | `RenderCommand` enum (45+ variants), `BlendMode`, `DrawMode`, `TextAlign`, `StencilMode`, `TextureData`, and related types |
| `shader.rs`         | Custom WGSL shader support — source validation via naga, uniform variables, per-shader pipeline |
| `shape.rs`          | `CompoundShape` builder and `ShapeCommand` sub-enum for multi-primitive vector drawing |
| `sprite.rs`         | `Sprite` struct — texture handle + transform + tint color wrapper     |
| `sprite_batch.rs`   | Sprite batching for efficient rendering of many sprites sharing one texture |
| `sprite_sheet.rs`   | Grid-based sprite sheet with directional support and named frame groups |
| `texture.rs`        | Texture loading (PNG/JPEG/BMP), premultiplied-alpha conversion, and `TextureKey` handle |
| `texture_atlas.rs`  | CPU-side bin-packing texture atlas using the shelf algorithm           |
| `color.rs`          | Legacy `Color` struct file; not declared in `mod.rs` — canonical `Color` is in `src/math/color.rs` |
| `mod.rs`            | Module root — declares all submodules via `pub mod` and re-exports public types      |

## Key Types

| Type              | Description                                                                          |
|-------------------|--------------------------------------------------------------------------------------|
| `RenderCommand`   | 45+ variant enum encoding every drawable operation; enqueued by Lua, consumed by `GpuRenderer::render_frame()`. |
| `GpuRenderer`     | Owns the wgpu device, surface, pipeline cache, and GPU resource pools; executes the `RenderCommand` queue once per frame. |
| `Canvas`          | Logical metadata for an off-screen render target; GPU-side texture managed by `GpuRenderer`. |
| `Font`            | TTF/OTF font backed by fontdue; owns the CPU-side glyph shelf-atlas and uploads to a GPU atlas texture on demand. |
| `Shader`          | Custom WGSL shader with named uniform variables; validated at load time via naga and cached as a `wgpu::RenderPipeline`. |
| `Mesh`            | Indexed geometry with per-vertex position, UV, and color; drawn with `DrawMesh`. |
| `SpriteBatch`     | Pre-sorted list of `BatchEntry` quads sharing one texture; rendered in a single draw call. |
| `CompoundShape`   | Builder for multi-primitive vector shapes composed of `ShapeCommand` sub-operations. |
| `BlendMode`       | Five pre-built pipeline blend modes: `Alpha`, `Additive`, `Subtract`, `Multiply`, `Replace`. |
| `TextureData`     | CPU-side `RgbaImage` pixel buffer tagged with its origin path for deduplication. |


## Submodules

### `canvas` — Off-screen Render Targets
- `Canvas` — Width × height metadata for a GPU-managed off-screen render surface.

### `decal_surface` — Decal Stamp Surface
- `DecalSurface` — Persistent descriptor for stamping decal textures onto surfaces.

### `draw_layer` — Z-Ordered Draw Callbacks
- `DrawLayer` — Ordered list of draw callbacks keyed by layer index.
- `LayerEntry` — Single callback entry with z-order and draw function.

### `font` — Font Loading and Atlas
- `Font` — TTF/OTF font backed by fontdue; owns the CPU-side glyph shelf-atlas.
- `GlyphInfo` — Cached rasterized glyph metrics and atlas coordinates.

### `gpu_renderer` — wgpu Renderer
- `GpuRenderer` — Owns wgpu device, surface, pipeline cache, and GPU resource pools.
- `RenderStats` — Per-frame draw call and vertex count statistics.

### `image_effect` — Shader Effect Pass
- `ShaderPassDescriptor` — Lightweight descriptor for a per-image shader pass in the pipeline.

### `mesh` — Custom Geometry Mesh
- `Mesh` — Indexed geometry with per-vertex position, UV, and color.
- `MeshVertex` — Single vertex: position `(f32, f32)`, UV `(f32, f32)`, color `[f32; 4]`.
- `MeshDrawMode` — `Triangles`, `Lines`, or `Points` draw topology.

### `nine_slice` — 9-Patch Image Rendering
- `NineSlice` — Nine-slice descriptor with four inset distances (top, right, bottom, left).
- `Patch` — One of 9 rectangular quads composing the slice layout.

### `renderer` — RenderCommand Queue and Draw Enums
- `RenderCommand` — 45+ variant enum encoding every drawable GPU operation.
- `BlendMode` — `Alpha`, `Additive`, `Subtract`, `Multiply`, `Replace`, `Screen`.
- `DrawMode` — `Fill` or `Line` draw style.
- `TextAlign` — `Left`, `Center`, or `Right` text alignment.
- `StencilMode` — Stencil write/test configuration.
- `StencilAction` — `Replace`, `Keep`, or `Zero` stencil operations.
- `DepthMode` — `ReadWrite`, `ReadOnly`, or `None` depth buffer mode.
- `CompareMode` — Depth/stencil comparison function selector.
- `DrawableKind` — Canvas vs. swapchain render-target tag.
- `TextureData` — CPU-side `RgbaImage` pixel buffer with deduplication path.

### `shader` — Custom WGSL Shaders
- `Shader` — Custom WGSL fragment shader with named uniform variables; naga-validated.
- `UniformValue` — `Float`, `Vec2`, `Vec4`, or `Mat4` typed uniform binding.

### `shape` — Compound Vector Shapes
- `CompoundShape` — Builder accumulating `ShapeCommand` sub-operations for vector drawing.
- `ShapeCommand` — Sub-operations: `Rectangle`, `Circle`, `Line`, `Polygon`, `Point`.

### `sprite` — Sprite Wrapper
- `Sprite` — Combines `TextureKey`, transform, and tint color into a drawable object.

### `sprite_batch` — Efficient Multi-Sprite Rendering
- `SpriteBatch` — Pre-sorted `BatchEntry` quad list sharing one texture; one GPU draw call.

### `sprite_sheet` — Grid-Based Sprite Sheet
- `SpriteSheet` — Grid animation source with named frame groups and directional support.

### `texture` — Texture Loading
- `Texture` — Loaded GPU texture with `TextureKey` handle, width, height, and path metadata.

### `texture_atlas` — CPU Bin-Packing Atlas
- `TextureAtlas` — Shelf-algorithm CPU-side texture atlas packing utility.

## Lua API

Registered by `src/lua_api/render_api.rs` as `lurek.graphic`. The `lurek.graphic` namespace exposes resource creation and scene-graph drawing functions. Visual drawing commands (draw, rectangle, circle, print, etc.) are defined directly in this file. There is no separate `graphic_api.rs`.

### Stats fields

These read-only fields on the `lurek.graphic` table expose per-frame renderer statistics:

| Field | Description |
|---|---|
| `lurek.graphic.canvases` | Number of canvas render targets allocated. |
| `lurek.graphic.drawcalls` | Number of GPU draw calls issued in the last frame. |
| `lurek.graphic.fonts` | Number of font atlases loaded. |
| `lurek.graphic.textures` | Number of GPU textures loaded. |
| `lurek.graphic.texture_memory` | Estimated GPU texture memory in bytes. |

### Image methods

| Method | Description |
|---|---|
| `img:getWidth()` | Returns the width of this image in pixels. |
| `img:getHeight()` | Returns the height of this image in pixels. |
| `img:getDimensions()` | Returns the width and height as two integers. |
| `img:release()` | Releases GPU texture memory; returns `true` on success. |
| `img:type()` | Returns the type name `"Image"`. |
| `img:typeOf(name)` | Returns `true` when name matches `"Image"` or a parent type. |

### Font methods

| Method | Description |
|---|---|
| `font:getWidth(text)` | Returns the rendered pixel width of text. |
| `font:getHeight()` | Returns the line height of this font. |
| `font:getLineHeight()` | Returns the line height multiplier. |
| `font:setLineHeight(h)` | Sets the line height multiplier. |
| `font:getAscent()` | Returns the ascent in pixels. |
| `font:getDescent()` | Returns the descent in pixels. |
| `font:getWrap(text, limit)` | Wraps text to limit and returns lines table plus max width. |
| `font:release()` | Releases font atlas memory; returns `true` on success. |
| `font:type()` | Returns the type name `"Font"`. |
| `font:typeOf(name)` | Returns `true` when name matches `"Font"` or a parent type. |

### Canvas methods

| Method | Description |
|---|---|
| `canvas:getWidth()` | Returns the canvas width in pixels. |
| `canvas:getHeight()` | Returns the canvas height in pixels. |
| `canvas:getDimensions()` | Returns width and height as two integers. |
| `canvas:release()` | Releases GPU framebuffer; returns `true` on success. |
| `canvas:type()` | Returns the type name `"Canvas"`. |
| `canvas:typeOf(name)` | Returns `true` when name matches `"Canvas"` or a parent type. |

### SpriteBatch methods

| Method | Description |
|---|---|
| `batch:add(x, y, r?, sx?, sy?, ox?, oy?)` | Adds a sprite entry; returns 1-based index or nil when full. |
| `batch:clear()` | Removes all sprites from this batch. |
| `batch:getCount()` | Returns the number of sprites in this batch. |
| `batch:getBufferSize()` | Returns the maximum capacity. |
| `batch:flush()` | Flushes the batch to the GPU draw queue. |
| `batch:release()` | Releases this sprite batch; returns `true` on success. |
| `batch:type()` | Returns the type name `"SpriteBatch"`. |
| `batch:typeOf(name)` | Returns `true` when name matches `"SpriteBatch"` or a parent type. |

### Mesh methods

| Method | Description |
|---|---|
| `mesh:getVertexCount()` | Returns the number of vertices. |
| `mesh:getVertex(i)` | Returns x, y, u, v, r, g, b, a for vertex at 1-based index. |
| `mesh:setVertex(i, data)` | Sets vertex data at 1-based index from a flat table. |
| `mesh:setTexture(img?)` | Assigns or clears the texture for this mesh. |
| `mesh:queue()` | Queues this mesh for rendering this frame. |
| `mesh:release()` | Releases this mesh; returns `true` on success. |
| `mesh:type()` | Returns the type name `"Mesh"`. |
| `mesh:typeOf(name)` | Returns `true` when name matches `"Mesh"` or a parent type. |

### Shader methods

| Method | Description |
|---|---|
| `shader:send(name, value)` | Sends a uniform value (number, boolean, or 2-4 element table). |
| `shader:hasUniform(name)` | Returns whether this shader has a uniform with the given name. |
| `shader:release()` | Releases this shader; returns `true` on success. |
| `shader:type()` | Returns the type name `"Shader"`. |
| `shader:typeOf(name)` | Returns `true` when name matches `"Shader"` or a parent type. |

### Quad methods

| Method | Description |
|---|---|
| `quad:getViewport()` | Returns the source rectangle as x, y, w, h. |
| `quad:getTextureDimensions()` | Returns the reference texture width and height. |
| `quad:type()` | Returns the type name `"Quad"`. |
| `quad:typeOf(name)` | Returns `true` when name matches `"Quad"` or a parent type. |

### NineSlice methods

| Method | Description |
|---|---|
| `ns:getInsets()` | Returns the four inset values as top, right, bottom, left. |
| `ns:getTextureSize()` | Returns the source texture width and height. |
| `ns:type()` | Returns the type name `"NineSlice"`. |
| `ns:typeOf(name)` | Returns `true` when name matches `"NineSlice"` or a parent type. |

### Shape methods

| Method | Description |
|---|---|
| `shape:getCommandCount()` | Returns the number of drawing commands stored. |
| `shape:clear()` | Removes all commands and resets the shape to empty. |
| `shape:setColor(r, g, b, a?)` | Sets the drawing color for subsequent primitives. |
| `shape:setLineWidth(w)` | Sets the stroke width for subsequent outlined primitives. |
| `shape:rectangle(mode, x, y, w, h)` | Queues a fill or line rectangle command. |
| `shape:line(x1, y1, x2, y2)` | Queues a line segment command. |
| `shape:polyline(vertices)` | Queues a polyline from a flat vertices table. |
| `shape:type()` | Returns the type name `"Shape"`. |
| `shape:typeOf(name)` | Returns `true` when name matches `"Shape"` or a parent type. |

## Lua Examples

```lua
-- Basic image and text rendering
local img  = lurek.graphic.newImage("assets/player.png")
local font = lurek.graphic.newFont("assets/ui.ttf", 24)

lurek.render = function()
    -- Fill background
    lurek.graphic.setColor(0.1, 0.1, 0.2, 1.0)
    lurek.graphic.rectangle("fill", 0, 0, 800, 600)

    -- Draw sprite at original size
    lurek.graphic.setColor(1, 1, 1, 1)
    lurek.graphic.draw(img, 100, 200)

    -- Draw with transform stack
    lurek.graphic.push()
    lurek.graphic.translate(400, 300)
    lurek.graphic.rotate(math.pi / 4)
    lurek.graphic.draw(img, -32, -32)
    lurek.graphic.pop()

    -- Draw filled circle
    lurek.graphic.setColor(1, 0.5, 0, 1)
    lurek.graphic.circle("fill", 200, 400, 40)

    -- Print text
    lurek.graphic.setColor(1, 1, 0, 1)
    lurek.graphic.print(font, "Score: 100", 10, 10)
end

-- Canvas (off-screen render target)
local fb = lurek.graphic.newCanvas(800, 600)

lurek.render = function()
    lurek.graphic.setCanvas(fb)
    lurek.graphic.setColor(0, 0, 0, 1)
    lurek.graphic.rectangle("fill", 0, 0, 800, 600)
    -- ... draw scene ...
    lurek.graphic.setCanvas(nil)

    -- Composite canvas onto screen
    lurek.graphic.drawCanvas(fb, 0, 0)
end

-- Custom WGSL shader
local shader = lurek.graphic.newShader([[
    @fragment fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
        return vec4<f32>(uv.x, uv.y, 0.5, 1.0);
    }
]])
lurek.graphic.setShader(shader)
lurek.graphic.draw(img, 0, 0)
lurek.graphic.setShader(nil)
```

## Item Summary

| Kind                | Count |
|---------------------|-------|
| Structs             | 18    |
| Enums               | 12    |
| Functions (Lua API) | 66    |
| **Total**           | **96** |

## References

| Module       | Relationship                                                                         |
|--------------|--------------------------------------------------------------------------------------|
| `runtime`    | `SharedState` holds `render_commands: Vec<RenderCommand>` and the typed `SlotMap` resource pools. |
| `math`       | `Color`, `Vec2`, `Mat3`, `Rect` are imported from `src/math/` and used throughout render types. |
| `image`      | `src/image/` provides `ImageData` (raw pixel buffer) used by `TextureData`. |
| `camera`     | `src/render/camera/` — `Camera` offsets the transform stack; integrated via `SetCamera` command. |
| `postfx`     | `src/postfx/` drives multi-pass effects using `BeginPostFx`/`EndPostFx`/`ApplyPostFx` commands. |
| `particle`   | `src/particle/` pushes `DrawParticleSystem` commands into the render queue.          |
| `light`      | `src/render/light/` manages `LightWorld` and occlusion geometry for the shadow pass. |

## Notes

- **Deferred rendering**: Lua closures never touch the GPU directly. `GpuRenderer::render_frame()` processes the full `RenderCommand` queue in a single encoder pass after each callback returns.
- **Pre-allocated vertex buffers**: 131 K color vertices and 16 K texture vertices are allocated at startup and reused every frame — no per-frame heap allocations in the hot path.
- **Depth/stencil format**: `Depth24PlusStencil8`; the 8-bit stencil provides masking and cut-out operations via `StencilMode`.
- **`color.rs` status**: `src/render/color.rs` exists as a file but is not declared in `mod.rs`. The canonical `Color` type for the engine lives in `src/math/color.rs`.
- **Breaking change surface**: Adding a new `RenderCommand` variant is backward-compatible. Renaming or removing an existing variant breaks any serialized replay or record files.
- **Pipeline cache**: The renderer caches `wgpu::RenderPipeline` objects keyed by `(BlendMode, shader_key, wireframe_flag)` to minimise state switches during a frame.
