# `src/graphics/` — GPU-Accelerated 2D Rendering

## Purpose

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

All resources (textures, fonts, canvases, shaders, meshes, sprite batches)
are identified by typed SlotMap keys that are opaque to Lua.  When a script
calls `luna.graphics.newImage("hero.png")`, Lua receives a lightweight handle
table wrapping a `TextureKey`; the actual `wgpu::Texture` and
`wgpu::TextureView` live inside `GpuRenderer` and are never passed to Lua.
This keeps Lua values small and eliminates the need for Lua `__gc` finalizers
on GPU resources.

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
  │     └── Advanced: DrawMesh, DrawParticleSystem, DrawAnimation, DrawTrail
  │
  ├── Resources (SlotMap storage)
  │     ├── Textures ── GPU texture handles + metadata
  │     ├── Fonts ── fontdue rasterization + GPU atlas
  │     ├── Canvases ── off-screen render targets
  │     ├── Shaders ── custom WGSL fragment shaders
  │     ├── Meshes ── vertex data + optional texture
  │     └── SpriteBatches ── instanced sprite rendering
  │
  ├── Camera ── Camera2D with smooth follow, shake, dead zone
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

### How It Works

The GPU pipeline uses two `wgpu::RenderPipeline` instances: a colour-only
pipeline for solid and outlined primitives, and a textured pipeline for
images, text glyphs, and canvas compositing.  The command processor tracks the
current pipeline by comparing the last-used pipeline tag; a switch is only
encoded when a command requires a different one, minimising GPU state
transitions.

Text rendering uses `fontdue` for glyph rasterisation.  Glyphs are packed into
growing atlas textures (starting at 512² and doubling up to 2048²) using a
shelf bin-packing algorithm.  The atlas is uploaded to the GPU as a
`wgpu::Texture` when the dirty flag is set (new glyphs were rasterised this
frame).  Pure bitmap rasterisation at the requested point size is used — no
signed distance field blending — which gives pixel-perfect results at the
sizes game text typically uses.

Custom shaders are composed rather than replaced: user WGSL provides only the
fragment function body, and the engine wraps it with the entry-point signature,
bind-group bindings, and fragment-input struct the pipeline requires.  Naga
validates the composed shader at creation time, reporting WGSL syntax errors
before the asset ever reaches a frame boundary.

The `SpriteBatch` path avoids redundant texture binds by grouping all instances
from a single batch behind one `draw_indexed_indirect` call per batch, with
per-instance data (position, scale, rotation, UV, colour) in a GPU instance
buffer.  This is the recommended path for rendering large numbers of sprites
from the same texture atlas.

### Dependency Direction

```
graphics/ ──────► math (Vec2, Mat3, Rect, Color)
              ──► engine::resource_keys (TextureKey, FontKey, CanvasKey, ShaderKey, MeshKey, SpriteBatchKey)
```

---

## File-by-File Analysis

### `mod.rs` — Module Root

Re-exports 37 public types from all sub-modules.

**~45 lines** — re-exports.

---

### `gpu_renderer.rs` — `GpuRenderer` (wgpu Backend)

**~3000+ lines** | The core rendering engine. Largest file in the codebase.

#### Struct: `GpuRenderer`

Contains wgpu device, queue, surface, pipeline caches (color pipeline, texture
pipeline), GPU texture maps, font atlas textures, canvas targets, stencil state,
and per-frame transform stack.

#### Struct: `RenderStats`

```rust
pub struct RenderStats {
    pub draw_calls: u32,
    pub texture_switches: u32,
    pub canvas_switches: u32,
    pub shader_switches: u32,
    pub batched_draws: u32,
}
```

#### Key Methods

| Method | Purpose |
|--------|---------|
| `new(window, config)` | Initialize wgpu pipeline |
| `render_frame(commands, stats)` | Process DrawCommand queue |
| `resize(w, h)` | Handle window resize |
| `upload_texture(key, data)` | Upload texture to GPU |
| `create_canvas(w, h)` | Create off-screen render target |

**Design**: Two render pipelines — a color-only pipeline for primitives and a
textured pipeline for images/fonts. Transform stack is rebuilt per-frame from
push/pop/translate/rotate/scale DrawCommands. Custom shaders are composed via
wrapper WGSL that delegates to user fragment code.

---

### `renderer.rs` — DrawCommand and Shared Types

**~292 lines** | The DrawCommand enum and associated types.

#### Enum: `DrawCommand` (35+ variants)

```
Rectangle, Circle, Line, Polygon, Arc, Ellipse, Points,
Print, Printf,
DrawTexture, DrawTextureQuad,
DrawSpriteBatch,
SetCanvas, ClearCanvas,
PushTransform, PopTransform, Translate, Rotate, Scale,
SetColor, SetBlendMode, SetShader, SetLineWidth,
SetStencilTest, Stencil,
DrawMesh, DrawParticleSystem, DrawAnimation, DrawTrail,
... and more
```

#### Enum: `BlendMode`

`Alpha | Add | Multiply | Replace | Screen`

#### Enum: `DrawMode`

`Fill | Line`

#### Enum: `CompareMode` (8 variants)

Stencil comparison operations.

#### Enum: `TextAlign`

`Left | Center | Right | Justify`

---

### `color.rs` — `Color`

**~129 lines** | RGBA color with presets.

```rust
pub struct Color {
    pub r: f32, pub g: f32, pub b: f32, pub a: f32,
}
```

Constants: `WHITE`, `BLACK`, `RED`, `GREEN`, `BLUE`, `LUNA_BG`, `LUNA_ACCENT`.

Methods: `new`, `from_u8`, `to_u8`, `to_rgb_u32`.

---

### `texture.rs` — `Texture`

**~82 lines** | GPU texture handle with dimensions.

```rust
pub struct Texture {
    pub key: TextureKey,
    pub width: u32,
    pub height: u32,
}
```

Methods: `load(path)` (premultiplies alpha), `from_rgba(data, w, h)`.

---

### `sprite.rs` — `Sprite`

**~75 lines** | Positioned textured quad.

```rust
pub struct Sprite {
    pub texture_id: TextureKey,
    pub position: Vec2,
    pub scale: Vec2,
    pub rotation: f32,
    pub color: Color,
}
```

Methods: `new`, `set_position`, `set_scale`, `set_rotation`, `set_color`.

---

### `font.rs` — `Font` (Text Rasterization)

**~503 lines** | fontdue-based font with GPU atlas management.

Constants: `INITIAL_ATLAS = 512`, `MAX_ATLAS = 2048`, `GLYPH_PADDING = 1`.

Methods: `from_bytes`, `ensure_glyph`, `text_width`, `line_height`,
`set_line_height`, `ascent`, `descent`, `atlas_data`, `is_dirty`,
`mark_clean`, `glyph`, `size`, `wrap_text`.

**Design**: Shelf-packing atlas allocator. Glyphs are rasterized on-demand
with fontdue and packed into a texture atlas that grows up to `MAX_ATLAS`.
GPU atlas is re-uploaded when dirty.

---

### `camera.rs` — `Camera` / `Camera2D`

**~557 lines** | 2D camera with smooth follow, dead zone, bounds, and shake.

```rust
pub struct Camera {
    pub position: Vec2,
    pub zoom: f32,
    pub rotation: f32,
}
```

`Camera2D` extends with: smooth follow, dead zone rectangle, world bounds
clamping, look-ahead, and screen shake.

Methods: `view_matrix`, `set/get position/zoom/rotation`, `set/remove bounds`,
`set/get dead_zone/target/follow_smooth/look_ahead`, `shake(amount, duration)`,
`to_world_coords`, `to_screen_coords`, `get_visible_area`.

---

### `shader.rs` — `Shader` (Custom WGSL Shaders)

**~392 lines** | Custom fragment shaders with uniform support.

```rust
pub struct Shader {
    source: String,      // normalized WGSL
    wrapper: String,     // composed wrapper calling user code
    uniforms: HashMap<String, UniformValue>,
}
```

Enum `ShaderFragmentInput`: `Color | Uv`.
Enum `UniformValue`: `Float | Vec2 | Vec3 | Vec4 | Int | Bool`.

Methods: `new(source)` (Naga validation), `send(name, value)`, `has_uniform`.

**Design**: User WGSL is wrapped in a composition layer that provides the entry
point. Naga validates the shader at load time to catch errors early.

---

### `mesh.rs` — `Mesh`

**~193 lines** | Custom vertex data with optional texture.

```rust
pub struct MeshVertex {
    pub x: f32, pub y: f32,
    pub u: f32, pub v: f32,
    pub r: f32, pub g: f32, pub b: f32, pub a: f32,
}
```

Enum `MeshDrawMode`: `Triangles | Fan | Strip`.

Methods: `new`, `from_vertices`, `set/get_vertex`, `set_vertex_map`,
`vertex_count`, `set_texture`, `set_draw_mode`, `triangulate`.

---

### `sprite_sheet.rs` — `SpriteSheet`

**~195 lines** | Uniform grid sprite sheet with named frame groups.

Methods: `new`, frame access, group naming, `set_directions`,
`get_direction_frames`. Supports 4/8-direction animation layouts.

---

### `sprite_batch.rs` — `SpriteBatch`

**~111 lines** | Batch rendering of sprites from the same texture.

Methods: `new`, `add`, `clear`, `texture_key`, `entries`, `len`,
`is_empty`, `buffer_size`.

---

### `texture_atlas.rs` — `TextureAtlas`

**~214 lines** | Shelf bin-packing texture atlas.

Methods: `new`, `pack(name, w, h)`, `get_region`, `get_region_count`,
`get_dimensions`, `get_regions`, `clear`.

---

### `canvas.rs` — `Canvas` (Off-Screen Target)

**~24 lines** | Off-screen render target descriptor.

```rust
pub struct Canvas {
    pub width: u32,
    pub height: u32,
}
```

---

### `viewport.rs` — `Viewport`

**~140 lines** | Game-to-screen coordinate mapping with scale modes.

Enum `ScaleMode`: `Letterbox | Stretch | PixelPerfect`.

Methods: `new`, `resize`, `get_scale/offset/game_dimensions/scale_mode`,
`set_scale_mode`, `to_game`, `to_screen`.

---

### `viewport_scale.rs` — `ViewportScale`

**~108 lines** | Extended viewport with scaled dimensions.

---

### `animation.rs` — `Animation`

**~550+ lines** | Named clip-based sprite animation system.

Methods: `new`, `add_frame`, `add_frames_from_grid`, `add_clip`, `play`,
`stop`, `pause`, `resume`, `update`, `current_quad/frame`,
`get_current_clip`, `is_playing/looping`, `get/set_speed`,
`drain_events`, `set_frame`.

Events: `AnimEvent::Finished | FrameChanged | Looped`.

---

### `palette_lut.rs` — `PaletteLUT`

**~68 lines** | Color palette lookup table for palette-swap effects.

---

### `trail.rs` — `Trail`

**~127 lines** | Fading polyline trail renderer.

Methods: `new`, `push_point`, `update`, `set_width`, `set/get_lifetime`,
`set_min_distance`, `clear`, `get_point_count`, `set_head/tail_color`.

---

### `column_batch.rs` — `ColumnBatch`

**~170 lines** | Wolfenstein-style raycasting column renderer.

---

### `decal_surface.rs` — `DecalSurface`

**~37 lines** | Persistent render target for decal overlays.

---

### `draw_layer.rs` — `DrawLayer`

**~75 lines** | Z-ordered draw call layer.

---

### `graph_renderer.rs` — `GraphRenderer`

**~710+ lines** | Data visualization (line/scatter/bar charts).

Methods: `new`, `set/get viewport/range`, `auto_range`,
`add_line/scatter/bar_series`, `remove/clear_series`,
`set_show_grid/axes/labels`, `world_to/from_screen`.

---

### `light2d.rs` — `Light2D`

**~89 lines** | 2D point light source.

```rust
pub struct Light2D {
    pub x: f32, pub y: f32,
    pub radius: f32,
    pub color: Color,
    pub intensity: f32,
    pub enabled: bool,
}
```

---

### `large_map_renderer.rs` — `LargeMapRenderer`

**~580+ lines** | Chunk-based tilemap renderer with LOD support.

Methods: `new`, `set_map_data`, `set/get_tile`, `set/get_chunk_size`,
`invalidate_chunk/all`, `get_visible/total_chunks`, `set_camera`,
`set_viewport`, `set_lod_enabled/thresholds`.

---

### `polygon_map.rs` — `PolygonMap`

**~450+ lines** | Named polygon region renderer with hit testing.

Methods: `new`, `add/remove_region`, `set/get_region_color`,
`set_region_label`, `get_region_at` (ray-cast point-in-polygon),
`get_region_names/vertices/center/bounding_box`,
`set_outline/highlight_color`, `highlight/clear_highlight`.

---

## Cross-Cutting Concerns

### Error Handling

Rendering errors are logged but do not crash the game. Invalid texture keys
and missing fonts produce visible debug output (magenta rectangles, error text)
rather than panicking.

### Thread Safety

`GpuRenderer` is main-thread only — wgpu requires surface operations on the
thread that created the window. No `Send`/`Sync` bounds needed.

### Lua Integration

The Lua bridge lives in `src/lua_api/graphics_api.rs` (~2150 lines) and
`src/lua_api/graphics_ext_api.rs` (~300 lines), together providing 120+
functions under `luna.graphics.*`.

### Usage from Lua

```lua
-- Drawing primitives
luna.graphics.setColor(1, 0, 0)
luna.graphics.rectangle("fill", 100, 100, 200, 150)
luna.graphics.circle("line", 400, 300, 50)

-- Textures
local img = luna.graphics.newImage("sprites/hero.png")
luna.graphics.draw(img, 100, 200)

-- Fonts
local font = luna.graphics.newFont("fonts/pixel.ttf", 16)
luna.graphics.setFont(font)
luna.graphics.print("Hello Luna2D!", 10, 10)

-- Transform stack
luna.graphics.push()
luna.graphics.translate(400, 300)
luna.graphics.rotate(angle)
luna.graphics.draw(img, -32, -32)  -- centered
luna.graphics.pop()

-- Canvas (off-screen rendering)
local canvas = luna.graphics.newCanvas(800, 600)
luna.graphics.setCanvas(canvas)
-- draw to canvas...
luna.graphics.setCanvas()  -- back to screen
luna.graphics.draw(canvas, 0, 0)
```
