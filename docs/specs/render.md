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
