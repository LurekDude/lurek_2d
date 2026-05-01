# Lurek2D — Render Command Architecture

Source of truth for the three-layer rendering pipeline, per-module output catalogue, resource handle system, and the raycaster/lighting design decisions.

Companion documents: [engine-architecture.md](engine-architecture.md) · [philosophy.md](philosophy.md)

`engine-architecture.md` covers the full engine structure. This document covers the rendering pipeline in depth.

---

## Table of Contents

1. [Overview — Three-Layer Model](#overview--three-layer-model)
2. [Layer 1 — CPU Domain Modules](#layer-1--cpu-domain-modules)
3. [Layer 2 — App Coordinator](#layer-2--app-coordinator)
4. [Layer 3 — GPU Renderer](#layer-3--gpu-renderer)
5. [RenderCommand Variants](#rendercommand-variants)
6. [Resource Handle System](#resource-handle-system)
7. [Per-Frame Data Flow](#per-frame-data-flow)
8. [Module Output Catalogue](#module-output-catalogue)
9. [Design Decisions](#design-decisions)
10. [Lua Binding Strategy](#lua-binding-strategy)

---

## Overview — Three-Layer Model

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ LAYER 1 — CPU Domain Modules (src/<module>/)                                 │
│                                                                              │
│  particle: Vec<RenderCommand>          tilemap: Vec<RenderCommand>           │
│  parallax: Vec<RenderCommand>          ui: Vec<RenderCommand>                │
│  animation: Vec<RenderCommand>         raycaster: RaycasterScene             │
│  light: Vec<Light2D> + Vec<Occluder>   effect: Vec<PostFxEffect>             │
│  camera: transform wrappers                                                  │
│                                                                              │
│  NO GPU calls. NO wgpu imports. Just plain Rust structs.                     │
└──────────────────────────────────────────────────────────────────────────────┘
                                  │  pass data
                                  ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ LAYER 2 — App Coordinator (src/app/)                                         │
│                                                                              │
│  Orchestrates frame: poll input → run Lua callbacks → collect RenderCommands │
│  → collect lights/occluders/postfx → call GpuRenderer::render_frame()       │
│                                                                              │
│  Knows about all modules. Never contains game logic or GPU calls.            │
└──────────────────────────────────────────────────────────────────────────────┘
                                  │  Vec<RenderCommand> + lights + postfx
                                  ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ LAYER 3 — GPU Renderer (src/render/gpu_renderer.rs)                          │
│                                                                              │
│  The ONLY module that calls wgpu. Walks the command list,                    │
│  runs shadow/light/postfx passes, presents to screen.                        │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Invariants:**
- No module outside `src/render/` imports wgpu
- `RenderCommand` is a data enum — no methods, no GPU handles, no trait objects
- Light and post-FX data flow as structured arguments, not as `RenderCommand` variants
- GPU handles (`wgpu::Buffer`, `wgpu::Texture`) never appear in `SharedState`

---

## Layer 1 — CPU Domain Modules

Each domain module that produces visual output implements a `generate_render_commands()` method (or equivalent). Rules:

1. **No GPU calls** — push enum variants into a `Vec`, nothing else
2. **Handles only** — use `TextureKey`, `FontKey`, `CanvasKey`, never raw pointers
3. **Snapshot** — clone any data that changes after `generate_render_commands()` returns; the Vec must be sendable
4. **Pre-sorted** — sort within the module's own output by Z-order; App does not re-sort within a module's block
5. **Bracket correctness** — if you emit `BeginPostFx`, emit matching `EndPostFx` in the same call

**Lua scripts push commands via `lurek.*` API calls:**
```lua
lurek.graphics.setColor(1, 0, 0, 1)
lurek.graphics.rectangle("fill", 100, 100, 200, 50)
lurek.graphics.drawImage(tex, 0, 0)
```
Each call is translated by `src/lua_api/<module>_api.rs` into one or more `RenderCommand` pushes into `SharedState.render_commands`.

---

## Layer 2 — App Coordinator

`src/app/app.rs` runs the frame in this exact sequence:

### Collect phase (`collect()`)

```
1. Clear SharedState.render_commands
2. Poll winit events → update InputState
3. Fire input Lua callbacks (keypressed, mousepressed, etc.)
4. Call Lua: lurek.process(dt)
5. Call Lua: lurek.process_physics(dt)  [0..N times, fixed timestep]
6. Call Lua: lurek.process_late(dt)
7. Call Lua: lurek.draw()               ← game pushes world commands
8. Call Lua: lurek.draw_ui()            ← game pushes UI commands
9. Auto: particle_sys.generate_render_commands() → extend commands
10. Auto: tilemap.generate_render_commands() → extend commands
11. Auto: parallax.generate_render_commands() → extend commands
12. Auto: ui_ctx.generate_render_commands() → extend commands
13. Collect lights: light_world.get_active_lights() → Vec<Light2D>
14. Collect occluders: light_world.get_occluders() → Vec<Occluder>
15. Collect post-FX: postfx_stack.get_active_effects() → Vec<PostFxEffect>
16. Collect viewport transform (letterbox/pixel-perfect PushTransform wrapper)
17. Append debug overlay commands
```

### Draw order (back to front)

```
1. Background clear (SetBackground)
2. Parallax layers
3. Tilemap background layers
4. Game world (from lurek.draw() callback)
5. Tilemap foreground layers
6. Particles
7. Post-processing wraps steps 1–6 (BeginPostFx / ApplyPostFx)
8. Light pass — GPU composites light buffer over scene
9. UI / HUD (lurek.draw_ui() + ui_ctx.generate_render_commands())
10. Debug overlay
```

### Render phase (`render()`)

```
GpuRenderer::render_frame(commands, lights, occluders, postfx_stack)
  → FrameStats { draw_calls, batched_draws }
```

### App must NOT

- Contain game logic (belongs in Lua or domain modules)
- Contain GPU code (belongs in `src/render/`)
- Contain Lua API registration (belongs in `src/lua_api/`)

---

## Layer 3 — GPU Renderer

`src/render/gpu_renderer.rs` contains `GpuRenderer::render_frame()` — the **only** function in the entire engine that issues wgpu draw calls.

### Renderer ownership

The renderer is not just a command interpreter. It owns several GPU subsystems:

| Subsystem | Location | Data source | Responsibility |
|-----------|----------|-------------|---------------|
| Command dispatch | `gpu_renderer.rs` | `Vec<RenderCommand>` | Walk command list, batch geometry, issue draws |
| Camera transforms | `gpu_renderer.rs` | `src/camera/` | Apply viewport matrix, coordinate transforms |
| Post-processing | `gpu_renderer.rs` | `src/effect/` (`PostFxEffect`) | Multi-pass WGSL pipeline (bloom, blur, CRT, custom) |
| 2D lighting | `gpu_renderer.rs` | `src/light/` (`Light2D`, `Occluder`) | Shadow map, light accumulation, compositing |
| Texture upload | `gpu_renderer.rs` | `src/image/` (pixel data) | Upload CPU pixels to GPU textures |
| Sprite batching | `gpu_renderer.rs` | `SpriteBatchKey` | Instance buffer management |
| Canvas (off-screen) | `gpu_renderer.rs` | `CanvasKey` | Off-screen render targets |

### What the renderer does NOT know about

- Widget types, particle emitters, animation states, tile map data
- Lua scripting, game logic, physics
- Module identity — a `Rectangle` is a `Rectangle` regardless of which module pushed it

---

## RenderCommand Variants

46+ variants in `src/render/renderer.rs`:

```rust
pub enum RenderCommand {
    // Primitives
    SetColor(f32, f32, f32, f32),
    Rectangle { mode: DrawMode, x, y, w, h },
    RoundedRectangle { mode, x, y, w, h, rx, ry },
    Circle { mode, x, y, r },
    Line { x1, y1, x2, y2 },
    Polygon { mode, vertices: Vec<f32> },
    Print { font_key, text, x, y, scale },

    // Textured draws
    DrawImage { texture_key, x, y, effect },
    DrawImageEx { texture_key, x, y, rotation, sx, sy, ox, oy, effect },
    DrawQuad { texture_key, quad_x, quad_y, quad_w, quad_h, ... },
    DrawNineSlice { texture_key, ..., x, y, w, h },

    // Batched
    DrawBatch { batch_key: SpriteBatchKey },
    DrawParticleSystem { particles: Vec<ParticleInstance> },

    // Transform stack
    PushTransform, PopTransform,
    Translate { x, y }, Scale { sx, sy }, Rotate { angle },
    ApplyTransform { matrix: [f32; 9] },

    // Canvas / render targets
    SetCanvas(Option<CanvasKey>),
    DrawCanvas { canvas_key, x, y, ... },

    // State
    SetBlendMode(BlendMode),
    SetScissor(Option<(f32, f32, f32, f32)>),
    SetShader(Option<ShaderKey>),

    // Stencil
    StencilBegin { action, value },
    StencilEnd,

    // Post-FX
    BeginPostFx { stack_id },
    EndPostFx { stack_id },
    ApplyPostFx { stack_id },
}
```

**Light and PostFx data are NOT `RenderCommand` variants** — they flow as separate typed arguments to `render_frame()`. This preserves type safety and allows the GPU subsystems to make rendering decisions that CPU modules should not know about.

---

## Resource Handle System

**Never pass live Rust references into a `RenderCommand`.**

All resources live in typed `SlotMap` pools inside `SharedState`:

| Handle | Pool | What it identifies |
|--------|------|--------------------|
| `TextureKey` | `SharedState::textures` | Uploaded GPU texture |
| `FontKey` | `SharedState::fonts` | Rasterised font atlas |
| `CanvasKey` | `SharedState::canvases` | Off-screen render target |
| `SpriteBatchKey` | `SharedState::sprite_batches` | Batched sprite geometry |
| `MeshKey` | `SharedState::meshes` | Raw vertex/index buffer |
| `ShaderKey` | `SharedState::shaders` | Custom WGSL shader |

**Lua integer IDs:** Lua scripts receive integer slot indices. `src/lua_api/` converts them to typed keys before pushing `RenderCommand`. The renderer resolves keys against the pool. **Stale keys log a warning and skip the draw call — never panic.**

---

## Per-Frame Data Flow

```
main.lua
  │  lurek.draw() / lurek.draw_ui()
  ▼
src/lua_api/*_api.rs             (Lua API — thin glue only)
  │  push RenderCommand into SharedState.render_commands
  ▼
src/app/app.rs                   (coordinator)
  │  + particle_sys.generate_render_commands()
  │  + tilemap.generate_render_commands()
  │  + ui_ctx.generate_render_commands()
  │  + light_world.get_active_lights() → Vec<Light2D>
  │  + light_world.get_occluders() → Vec<Occluder>
  │  + postfx_stack.get_active_effects() → Vec<PostFxEffect>
  │  + viewport PushTransform/Scale wrapper
  ▼
GpuRenderer::render_frame(commands, lights, occluders, postfx_stack)
  │
  │  1. Light pass — shadow geometry from Occluders → shadow map
  │                  light accumulation buffer (additive blend)
  │
  │  2. Scene pass — for each RenderCommand:
  │     Rectangle   → geometry batch
  │     DrawImage   → texture quad (TextureKey → GPU buffer)
  │     Print       → font atlas quads (FontKey → atlas)
  │     DrawParticleSystem → instanced quads
  │     DrawQuad    → sprite-sheet region
  │     ...
  │
  │  3. Light composite — blend light buffer over scene
  │
  │  4. PostFx pass — for each PostFxEffect:
  │                   capture to canvas → WGSL shader → composite
  ▼
wgpu surface present → screen
```

---

## Module Output Catalogue

### Modules that produce `Vec<RenderCommand>`

| Module | Commands emitted | Notes |
|--------|-----------------|-------|
| `particle` | `DrawParticleSystem { particles: Vec<ParticleInstance> }` | One batched command per emitter |
| `ui` | `Rectangle`, `RoundedRectangle`, `Print`, `DrawImage`, `DrawNineSlice`, `SetScissor` | Requires layout pass first |
| `tilemap` | `DrawQuad` per visible tile | Frustum-cull against camera rect; per-tile tint via `SetColor`; layer parallax via `Translate` |
| `parallax` | `DrawImageEx` per layer | Each layer at scrolled offset |
| `animation` | `DrawQuad` per animated object | Sprite-sheet frame selection → quad region |
| `spine` | `DrawQuad` per mesh attachment slot | Mesh deformation computed on CPU |
| `camera` | `PushTransform`, `Translate`, `Scale`, `Rotate`, `PopTransform` | Wraps other content in a transform — not a content producer |

### Modules that produce structured data (not `RenderCommand`)

These give the renderer domain-specific data; the renderer decides how to draw them.

| Module | Output type | Consumed by |
|--------|------------|-------------|
| `light` | `Vec<Light2D>` + `Vec<Occluder>` | `GpuRenderer` light pass — shadow map, accumulation buffer, composite |
| `effect` | `Vec<PostFxEffect>` with `HashMap<String, f32>` params | `GpuRenderer` post-FX pass — bloom, blur, CRT, chromatic, custom WGSL |
| `raycaster` | `RaycasterScene` (wall/floor/ceiling/sprite quads) | `GpuRenderer` raycaster path — textured perspective quads |
| `minimap` | Terrain grid + fog + objects + markers | May produce `Vec<RenderCommand>` (rects/images) OR render to a canvas |

### Modules that produce multiple output types

The architecture does not assume one output type per module:

| Module | Output 1 | Output 2 | Output 3 |
|--------|----------|----------|----------|
| `raycaster` | `RaycasterScene` for GPU | `Vec<BillboardSprite>` (depth-sorted) | Testing: `ImageData` via `draw_to_image()` |
| `minimap` | `Vec<RenderCommand>` (terrain/fog) | Ping animations | Viewport indicator rect |
| `effect` | `Vec<PostFxEffect>` | Overlay state (ambient, weather, fade, shake) | Per-image `ShaderPassDescriptor` |
| `tilemap` | `Vec<RenderCommand>` (tile quads) | Collision data (`Vec<SweepResult>`) | Animation frame updates |
| `ui` | `Vec<RenderCommand>` (widget primitives) | Hit-test results | Layout data (`computed_rect` per widget) |
| `physics` | Nothing (simulation only) | Debug: `Vec<RenderCommand>` (wireframe shapes) | — |

App collects each output type through the appropriate channel:
- `Vec<RenderCommand>` → extend the main command buffer
- Light/PostFx data → pass as separate arguments to `render_frame()`
- Collision/hit-test data → consumed by physics or input handling, not rendering

### Modules with no render output

| Module | Role |
|--------|------|
| `audio` | Audio backend |
| `input` | Input backend |
| `ai` | Decision logic |
| `math` | Foundation math |
| `data` | Foundation data structures |
| `physics` | Simulation only (debug draw is opt-in) |

---

## Design Decisions

### Raycaster — textured-quad 2.5D renderer

The raycaster produces a `RaycasterScene` — a set of perspective-projected textured quads — **not** column strips or scanlines.

**World model:** A 2D tile grid where each cell can have:
- **Wall faces** (N/S/E/W) — each face is a textured quad (different textures per face)
- **Floor tile** — a textured quad per tile
- **Ceiling tile** — a textured quad per tile
- **Billboard sprites** — camera-facing sprites (enemies, items, torches)

**Why textured quads, not column strips:**

| Approach | Pros | Cons |
|----------|------|------|
| Column strips (vertical scanlines) | Classic, simple | Cannot render per-tile floor/ceiling textures; poor quality at high resolution |
| Textured quads (Minecraft-style) | Per-tile textures; perspective-correct; GPU-native; scales to any resolution | More geometry to upload |

Column rendering assumes all floor/ceiling tiles share one colour. Games need paths, water, different materials per tile — textured quads solve this naturally.

**Output types:**

```rust
pub struct RaycasterScene {
    pub walls: Vec<WallQuad>,      // projected wall faces
    pub floors: Vec<FloorQuad>,    // projected floor tiles
    pub ceilings: Vec<CeilingQuad>, // projected ceiling tiles
    pub sprites: Vec<BillboardSprite>, // depth-sorted sprites
    pub fog_color: Color,
    pub fog_density: f32,
    pub ambient_light: Color,
}
```

Each `WallQuad` / `FloorQuad` / `CeilingQuad` carries: `corners: [Vec2; 4]`, `tex_coords: [Vec2; 4]`, `texture_id: u32`, `shade: f32`, `depth: f32`, `light_color: Color`.

**Lighting:** The same `Light2D` descriptors that illuminate 2D sprites also affect raycaster quads. Each quad carries a `light_color` tint computed from nearby light sources. `fog_color` + `fog_density` are applied by the GPU renderer during drawing.

**`draw_to_image()`** in `src/raycaster/draw.rs` is a CPU software rasteriser for headless tests, golden image comparison, and visual debugging — **not the production path**.

**Module file layout:**
```
src/raycaster/
    mod.rs     ← thin re-exports
    dda.rs     ← core DDA ray traversal, hit detection
    scene.rs   ← RaycasterScene, WallQuad, FloorQuad, CeilingQuad, BillboardSprite
    draw.rs    ← draw_to_image() — CPU pixel rasteriser for testing only
```

---

### Lighting — GPU shader system with CPU data

`Light2D` and `Occluder` are **pure CPU data descriptors**. They are passed to the renderer as structured arguments — never as `RenderCommand` variants.

**Light2D fields:** position, radius, color, intensity, falloff curve, light type (point/directional/spot), shadow config (PCF filter, shadow color), flicker params, masking (light_mask, shadow_mask).

**Occluder:** A polygon shadow caster with 3–512 vertices and an opacity value.

**GPU light pipeline (inside `src/render/light/`):**

1. **Shadow pass** — for each shadow-enabled light, render occluder geometry into a 1D radial shadow map. Uses `ShadowFilter` (None, PCF5, PCF13) for edge quality.
2. **Light accumulation** — for each light, draw a light quad into an accumulation canvas (additive blending). Fragment shader samples the shadow map and applies falloff.
3. **Compositing** — multiply-blend the accumulation buffer over the scene.

This is a GPU off-screen operation using `CanvasKey` render targets. The CPU module provides data descriptors; the GPU module does all rendering. Occluder shadows are **GPU-computed**, not CPU-computed — CPU shadow casting does not scale beyond ~50 occluders at 60 FPS.

---

### UI — layout owned by `src/ui/`, renderer never sees layout data

`src/ui/` owns layout computation. The renderer only receives final draw primitives (`Rectangle`, `Print`, etc.). This matches Flutter, Bevy UI, and Godot 4 Control nodes.

Layout pass runs during `generate_render_commands()` — computed rects are an internal detail of `src/ui/`, not part of the `RenderCommand` stream.

---

### `draw_to_image()` — testing and debugging only

Several modules have `draw_to_image()` functions producing `ImageData` (CPU pixel buffer). These are **not the production rendering path**.

**Purpose:** Unit testing without a GPU, visual debugging, screenshot for documentation, headless CI.

**Location:** `src/<module>/draw.rs` — separate file, not mixed into core algorithm files.

**Production rendering always goes through `src/render/` via the GPU.**

---

## Lua Binding Strategy

All Lua bindings live in `src/lua_api/<module>_api.rs`. Domain modules (`src/<module>/`) have no mlua dependency.

**Benefits of this separation:**
- Domain modules are GPU-free and Lua-free — testable without a VM
- Swap Lua for another scripting language: edit only `src/lua_api/`
- mlua compiled once, not for every domain module
- Thin wrapper rule is enforced by file location

**Registration contract (C-02):**

```rust
pub fn register(
    lua: &Lua,
    lurek: &LuaTable,
    state: Rc<RefCell<SharedState>>,
) -> LuaResult<()>
```

**Thin wrapper rule:** If a closure body exceeds ~10 lines, extract a `pub fn` on the domain type and call it from `lua_api`. Business logic must not live in `lua_api`.

**`impl LuaUserData` in `src/<module>/` is a blocking defect.** All Lua binding impls live in `src/lua_api/`.
