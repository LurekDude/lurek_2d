# Lurek2D — Render-Command Architecture

> **Status**: Design target and implementation guide.
> Describes how all CPU-side domain modules prepare data for `src/render/`,
> how the `App` layer orchestrates collection, and how `src/render/` is the
> single GPU execution point.
>
> Companion documents:
> [engine-architecture.md](engine-architecture.md) (module groups, boot) ·
> [philosophy.md](philosophy.md) (binding constraints)

---

## Table of Contents

1. [Core Principle](#core-principle)
2. [Three-Layer Model](#three-layer-model)
3. [Layer 1 — CPU Domain Modules](#layer-1--cpu-domain-modules)
4. [Layer 2 — App Coordinator](#layer-2--app-coordinator)
5. [Layer 3 — GPU Renderer (src/render/)](#layer-3--gpu-renderer-srcrender)
6. [Lua Binding Strategy](#lua-binding-strategy)
7. [Per-Frame Data Flow](#per-frame-data-flow)
8. [RenderCommand Package Contract](#rendercommand-package-contract)
9. [Resource Handle System](#resource-handle-system)
10. [Module Output Catalogue](#module-output-catalogue)
11. [Design Decisions](#design-decisions)
    - [Raycaster — a full 2.5D renderer, not a "draw image"](#raycaster--a-full-25d-renderer-not-a-draw-image)
    - [Lighting — GPU-side shader system with CPU data](#lighting--gpu-side-shader-system-with-cpu-data)
    - [Modules that produce multiple output types](#modules-that-produce-multiple-output-types)
    - [draw_to_image is for testing and debugging only](#draw_to_image-is-for-testing-and-debugging-only)
    - [UI Layout ownership](#ui-layout-ownership)
12. [Module Internal File Structure Standard](#module-internal-file-structure-standard)
13. [Render Module Refactoring Plan](#render-module-refactoring-plan)
14. [Current State vs Target State](#current-state-vs-target-state)
15. [Implementation Checklist](#implementation-checklist)

---

## Core Principle

> **`src/render/` is the only module that talks to the GPU.**
>
> Every other module runs on CPU only. A module's job is to prepare data —
> structs, buffers, parameters — that describes what it needs rendered.
> The renderer receives this data and decides how to draw it.
> Domain modules never call wgpu, never touch texture buffers, never
> write to the GPU.

This is the **stateless renderer** pattern used in commercial engines
(Frostbite, The Machinery, Godot 4). It enables:
- CPU modules testable with no GPU present
- Renderer swappable without touching game logic
- Parallel CPU preparation (future work)
- Clear profiling boundary: CPU time vs GPU time

---

## Three-Layer Model

```
┌────────────────────────────────────────────────────────────────────┐
│  LAYER 1 — CPU DOMAIN MODULES                                     │
│                                                                    │
│  src/ui/         src/particle/     src/animation/    src/tween/   │
│  src/effect/     src/camera/       src/tilemap/      src/scene/   │
│  src/parallax/   src/minimap/      src/raycaster/    src/spine/   │
│  src/physics/    src/ai/           src/ecs/                       │
│                                                                    │
│  Each module: pure CPU logic. Prepares data for rendering.        │
│  No wgpu, no winit, no GPU state, no mlua.                        │
└────────────────────────┬───────────────────────────────────────────┘
                         │  Data: structs, buffers, Vec<RenderCommand>
                         ▼
┌────────────────────────────────────────────────────────────────────┐
│  LAYER 2 — APP COORDINATOR  src/app/                              │
│                                                                    │
│  - Calls Lua callbacks (process, render, render_ui)               │
│  - Calls generate_render_commands() on each active module         │
│  - Passes light/shadow data to renderer as uniform data           │
│  - Merges all output in draw-order                                │
│  - Applies viewport transform (letterbox / pixel-perfect)         │
│  - Passes final data to Layer 3                                   │
└────────────────────────┬───────────────────────────────────────────┘
                         │  &Vec<RenderCommand> + light uniforms + ...
                         ▼
┌────────────────────────────────────────────────────────────────────┐
│  LAYER 3 — GPU RENDERER  src/render/                              │
│                                                                    │
│  GpuRenderer::render_frame(...)                                    │
│  - Interprets RenderCommand list                                   │
│  - Manages GPU buffers, pipelines, render passes                   │
│  - Returns FrameStats back to App                                  │
│                                                                    │
│  Receives structured data FROM top-level CPU modules:              │
│    src/camera/  — viewport transforms (PushTransform/Scale/Rotate) │
│    src/effect/  — PostFxEffect descriptors (shader pipeline config)│
│    src/light/   — Light2D + Occluder data (light/shadow uniforms)  │
└────────────────────────────────────────────────────────────────────┘
```

**Important**: `src/camera/`, `src/effect/`, and `src/light/` are **top-level
CPU domain modules** — they are NOT subdirectories of `src/render/`. They
prepare data (viewport transforms, PostFxEffect descriptors, Light2D + Occluder
structs) that the renderer consumes. The GPU rendering code for these features
lives inside `src/render/gpu_renderer.rs` — the renderer knows how to process
the data these modules produce.

Light *data* (Light2D, Occluder) lives in `src/light/`.
Light *rendering* (shadow maps, accumulation passes, compositing) lives in
`src/render/gpu_renderer.rs`.
Post-FX *data* (PostFxEffect, ShaderPassDescriptor) lives in `src/effect/`.
Post-FX *rendering* (multi-pass WGSL shader pipeline) lives in
`src/render/gpu_renderer.rs`.
Camera *data* (viewport, scale mode) lives in `src/camera/`.
Camera *transforms* are applied as RenderCommand wrappers by App.

---

## Layer 1 — CPU Domain Modules

### What a CPU module does

Every CPU domain module **does exactly two things**:

1. **State update** — called by App during the logic phase. Updates internal
   CPU state (widget positions, particle velocities, animation frames, etc.).
   No rendering.

2. **Data preparation** — prepares whatever the renderer needs. This takes
   different forms depending on the module:
   - **Simple modules** → `Vec<RenderCommand>` (draw primitives, quads, images)
   - **Complex modules** → structured data (light descriptors, occluder lists,
     post-FX stacks, raycaster scene data) consumed by dedicated renderer subsystems
   - **Some modules produce both** — e.g., tile layer draw commands AND
     collision data for physics

### API contract: `generate_render_commands()`

For modules whose output is a list of draw primitives:

```rust
impl ParticleSystem {
    /// Return the draw commands for this frame.
    /// Called once per frame by App after all Lua render callbacks finish.
    /// Must NOT mutate self — read-only snapshot.
    pub fn generate_render_commands(&self) -> Vec<RenderCommand> { ... }
}
```

**Not every module uses this pattern.** The light system, for example, does not
produce a `Vec<RenderCommand>`. It produces `Vec<Light2D>` and `Vec<Occluder>`
that the GPU renderer's light subsystem consumes directly. Forcing every module
into a flat command list would lose type safety and domain knowledge.

### What a CPU module must NOT do

- Import `wgpu`, `winit`, `mlua`, or any GPU crate
- Call any function on `GpuRenderer`
- Allocate GPU buffers or upload textures
- Spawn OS threads (use `src/thread/` Channel pattern instead)

---

## Layer 2 — App Coordinator

`src/app/app.rs` owns the frame loop and is the only place that connects all
layers.

### Frame tick sequence (target design)

```
tick_frame():
  ┌─ LOGIC PHASE ──────────────────────────────────────────────────┐
  │  1. Call Lua: lurek.process(dt)          - game logic          │
  │  2. Call Lua: lurek.process_physics(dt)  - physics step        │
  │  3. Call Lua: lurek.process_late(dt)     - post-physics logic   │
  └────────────────────────────────────────────────────────────────┘
  ┌─ COLLECT PHASE ────────────────────────────────────────────────┐
  │  4. Clear render_commands buffer                               │
  │  5. Call Lua: lurek.render()             - game draw commands   │
  │  6. Call Lua: lurek.render_ui()          - UI draw commands    │
  │  7. Auto: particle_sys.generate_render_commands() → extend     │
  │  8. Auto: tilemap.generate_render_commands()      → extend     │
  │  9. Auto: parallax.generate_render_commands()     → extend     │
  │  10. Auto: ui_ctx.generate_render_commands()      → extend     │
  │  11. Collect light data: lights[], occluders[]                 │
  │  12. Collect post-FX stack configuration                       │
  │  13. Append debug overlay commands                             │
  └────────────────────────────────────────────────────────────────┘
  ┌─ VIEWPORT PHASE ───────────────────────────────────────────────┐
  │  14. Wrap buffer in PushTransform/Scale/PopTransform           │
  │      if letterbox or pixel-perfect mode is active              │
  └────────────────────────────────────────────────────────────────┘

render():
  ┌─ GPU PHASE ────────────────────────────────────────────────────┐
  │  15. GpuRenderer::render_frame(                                │
  │        commands,                                                │
  │        lights,       ← Light2D array (uniforms for shader)     │
  │        occluders,    ← Occluder polygons (shadow geometry)     │
  │        postfx_stack, ← PostFxEffect pipeline config            │
  │        ...                                                      │
  │      )                                                          │
  │  16. Receive FrameStats (draw_calls, batched_draws)            │
  │  17. Store stats in SharedState for Lua and overlay            │
  └────────────────────────────────────────────────────────────────┘
```

### Draw order (Z-sorting responsibility)

App collects commands in this order (back to front):

```
1. Background clear color (SetBackground)
2. Parallax layers
3. Tilemap background layers
4. Game world (from Lua lurek.render() callback)
5. Tilemap foreground layers
6. Particles
7. Post-processing (BeginPostFx / ApplyPostFx) — wraps the above
8. Light pass — GPU composites light buffer over the scene
9. UI / HUD (from lurek.render_ui() + ui_ctx.generate_render_commands())
10. Debug overlay (always on top)
```

Modules within a group sort by their own Z-order; App does not re-sort within
a group.

### App must NOT

- Contain game logic (that belongs in Lua or domain modules)
- Contain GPU code (that belongs in `src/render/`)
- Contain Lua API registration (that belongs in `src/lua_api/`)

---

## Layer 3 — GPU Renderer (`src/render/`)

`src/render/gpu_renderer.rs` contains `GpuRenderer::render_frame()` — the only
function in the entire engine that issues wgpu draw calls.

### What the renderer owns

The renderer is NOT just a command interpreter. It owns several GPU subsystems:

| Subsystem | GPU Code Location | Data Source | Responsibility |
|---|---|---|---|
| Command dispatch | `gpu_renderer.rs` | `renderer.rs` (RenderCommand enum) | Walk `Vec<RenderCommand>`, batch geometry, issue draws |
| Camera transforms | `gpu_renderer.rs` | `src/camera/` (viewport, scale) | Apply viewport matrix, coordinate transforms |
| Post-processing | `gpu_renderer.rs` | `src/effect/` (PostFxEffect stack) | Multi-pass WGSL shader pipeline (bloom, blur, CRT, custom) |
| 2D lighting | `gpu_renderer.rs` | `src/light/` (Light2D, Occluder) | Shadow map generation, light accumulation buffer, compositing |
| Texture upload | `gpu_renderer.rs` | `texture.rs` (TextureData pixels) | Upload CPU pixel data to GPU textures |
| Sprite batching | `gpu_renderer.rs` | `sprite_batch.rs` (BatchEntry list) | Instance buffer management for batched draws |
| Canvas (off-screen) | `gpu_renderer.rs` | `canvas.rs` (Canvas descriptor) | Off-screen render targets for multi-pass rendering |

### What the renderer knows about

- `RenderCommand` enum variants and how to execute each one
- `Light2D` descriptors and `Occluder` polygons (for shadow/light passes)
- `PostFxEffect` stacks (for post-processing pipeline)
- wgpu device, queue, pipelines, bind groups
- GPU texture buffers (accessed via `TextureKey`)
- GPU font atlases (accessed via `FontKey`)
- Canvas render-to-texture buffers (accessed via `CanvasKey`)
- Sprite batch buffers (accessed via `SpriteBatchKey`)

### What the renderer does NOT know about

- Widget types, particle emitters, animation states, tile map data
- Lua scripting, game logic, physics
- Module identity — a `Rectangle` is a `Rectangle` regardless of origin

---

## Lua Binding Strategy

### Decision: separate `src/lua_api/` module (not per-domain files)

**This is the correct design for Lurek2D.** One `src/lua_api/<module>_api.rs`
per domain module.

**Why not `src/ui/lua.rs` inside each domain?**

| Concern | Separate lua_api/ | Per-domain lua.rs |
|---|---|---|
| Domain module purity | ✅ No mlua dependency in domain | ❌ mlua bleeds into every domain |
| Replaceability | ✅ Swap Lua for Wren: edit lua_api/ only | ❌ Touch all 15 domain modules |
| Compile time | ✅ mlua only compiled once | ❌ Recompiles all domains on mlua change |
| Testing | ✅ Domain tests need no Lua VM | ❌ Domain tests drag in mlua |
| Thin wrapper rule | ✅ Enforced by file location | ❌ Easy to add business logic in domain |

**The binding registration contract** (mandatory for every lua_api file):

```rust
// src/lua_api/ui_api.rs

/// Register the lurek.ui namespace.
pub fn register(
    lua: &Lua,
    lurek: &LuaTable,           // the lurek.* table
    state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let ui = lua.create_table()?;

    // ── addButton ────────────────────────────────
    /// Adds a button widget to the UI context.
    /// @param label : string
    /// @param x : number
    /// @param y : number
    /// @return integer  widget ID
    let s = state.clone();
    ui.set("addButton", lua.create_function(move |_, (label, x, y): (String, f32, f32)| {
        let id = s.borrow_mut().ui_ctx.add_button(label, x, y);
        Ok(id as i64)
    })?)?;

    lurek.set("ui", ui)?;
    Ok(())
}
```

**Thin Wrapper Rule** — enforced:
- `src/lua_api/<module>_api.rs` — ONLY Lua glue: `pub fn register()`, Lua
  UserData wrappers, `add_method` calls
- `src/<module>/` — ONLY pure Rust logic, algorithms, data types
- `impl LuaUserData` anywhere in `src/<module>/` is a blocking defect
- Do NOT implement business logic in the Lua binding. If your function body
  in lua_api is more than ~10 lines, the logic belongs in the domain module.

---

## Per-Frame Data Flow

Complete data flow from game script to pixel:

```
main.lua
  │
  │  lurek.render()  /  lurek.render_ui()
  ▼
src/lua_api/*_api.rs            (Lua API layer — thin glue only)
  │  pushes RenderCommand into SharedState.render_commands
  ▼
src/app/app.rs
  │  + particle_sys.generate_render_commands()    → Vec<RenderCommand>
  │  + tilemap.generate_render_commands()         → Vec<RenderCommand>
  │  + ui_ctx.generate_render_commands()          → Vec<RenderCommand>
  │  + light_world.get_active_lights()            → Vec<Light2D>
  │  + light_world.get_occluders()                → Vec<Occluder>
  │  + postfx_stack.get_active_effects()          → Vec<PostFxEffect>
  │  + viewport PushTransform/Scale wrapper
  ▼
src/render/gpu_renderer.rs — render_frame(commands, lights, occluders, ...)
  │
  │  1. Light pass: for each Light2D →
  │     shadow geometry from Occluders → shadow map
  │     light accumulation buffer (additive blend)
  │
  │  2. Scene pass: for each RenderCommand →
  │     Rectangle  → geometry batch
  │     DrawImage  → texture quad (TextureKey → GPU buffer)
  │     Print      → font atlas quads (FontKey → atlas)
  │     DrawParticleSystem → instanced particle quads
  │     DrawQuad   → sprite-sheet region
  │     ...
  │
  │  3. Light composite: blend light buffer over scene
  │
  │  4. PostFx pass: for each PostFxEffect →
  │     capture to canvas → apply WGSL shader → composite
  │
  ▼
wgpu surface present → screen
```

---

## RenderCommand Package Contract

A `Vec<RenderCommand>` produced by a CPU module must follow these rules:

1. **No GPU calls** — just `Vec::push()` with enum variants
2. **Handles only** — use `TextureKey`, `FontKey`, `CanvasKey` — never raw
   pointers or `Arc<Mutex<Texture>>`
3. **Snapshot, not reference** — the package must be sendable. Clone any data
   that changes after `generate_render_commands()` returns.
4. **Pre-sorted within the package** — the module sorts its own output by
   Z-order. App does not re-sort within a module's block.
5. **Bracket correctness** — if your module emits `BeginPostFx`, it must emit
   a matching `EndPostFx` in the same package.

### Key RenderCommand variants (46+ total, see `src/render/renderer.rs`)

```rust
pub enum RenderCommand {
    // --- Primitives ---
    SetColor(f32, f32, f32, f32),
    Rectangle { mode: DrawMode, x, y, w, h },
    RoundedRectangle { mode, x, y, w, h, rx, ry },
    Circle { mode, x, y, r },
    Line { x1, y1, x2, y2 },
    Polygon { mode, vertices: Vec<f32> },
    Print { font_key, text, x, y, scale },

    // --- Textured draws ---
    DrawImage { texture_key, x, y, effect },
    DrawImageEx { texture_key, x, y, rotation, sx, sy, ox, oy, effect },
    DrawQuad { texture_key, quad_x, quad_y, quad_w, quad_h, ... },
    DrawNineSlice { texture_key, ..., x, y, w, h },

    // --- Batched ---
    DrawBatch { batch_key: SpriteBatchKey },
    DrawParticleSystem { particles: Vec<ParticleInstance> },

    // --- Transform stack ---
    PushTransform, PopTransform,
    Translate { x, y }, Scale { sx, sy }, Rotate { angle },
    ApplyTransform { matrix: [f32; 9] },

    // --- Canvas / render targets ---
    SetCanvas(Option<CanvasKey>),
    DrawCanvas { canvas_key, x, y, ... },

    // --- State ---
    SetBlendMode(BlendMode),
    SetScissor(Option<(f32, f32, f32, f32)>),
    SetShader(Option<ShaderKey>),

    // --- Stencil ---
    StencilBegin { action, value },
    StencilEnd,

    // --- Post-FX ---
    BeginPostFx { stack_id },
    EndPostFx { stack_id },
    ApplyPostFx { stack_id },
}
```

---

## Resource Handle System

**Never pass live Rust references into a `RenderCommand`.**

Resources live in typed `SlotMap` pools inside `SharedState`:

| Handle type | Pool | What it identifies |
|---|---|---|
| `TextureKey` | `textures: SlotMap<TextureKey, GpuTexture>` | Uploaded GPU texture |
| `FontKey` | `fonts: SlotMap<FontKey, RasterFont>` | Rasterized font atlas |
| `CanvasKey` | `canvases: SlotMap<CanvasKey, Canvas>` | Off-screen render target |
| `SpriteBatchKey` | `sprite_batches: SlotMap<...>` | Batched sprite geometry |
| `MeshKey` | `meshes: SlotMap<MeshKey, Mesh>` | Raw vertex/index buffer |
| `ShaderKey` | `shaders: SlotMap<ShaderKey, Shader>` | Custom WGSL shader |

Lua scripts receive integer IDs (the slot index). `src/lua_api/` converts them
to typed keys before pushing `RenderCommand`. The renderer resolves keys
against the pool. Stale keys log a warning and skip — never panic.

---

## Module Output Catalogue

**Not every module produces a flat `Vec<RenderCommand>`.** Some modules produce
structured data that dedicated renderer subsystems consume. This is
intentional — it preserves type safety and allows the GPU code to make
rendering decisions that CPU modules should not know about.

### Modules that produce `Vec<RenderCommand>`

These modules have a `generate_render_commands()` method:

| Module | Output commands | Details |
|---|---|---|
| `src/particle/` | `DrawParticleSystem { particles: Vec<ParticleInstance> }` | Already implemented. Single batched command per emitter. Each `ParticleInstance` has position, color, rotation, size, shape, optional texture+quad. |
| `src/ui/` | `Rectangle`, `RoundedRectangle`, `Print`, `DrawImage`, `DrawNineSlice`, `SetScissor` | One or more commands per widget. Requires layout pass first (see §11.5). |
| `src/tilemap/` | `DrawQuad` per visible tile | Frustum-cull against camera rect, then emit one `DrawQuad` per visible tile with atlas coordinates. Per-tile tints via `SetColor`. Layer parallax via `Translate`. |
| `src/parallax/` | `DrawImageEx` per layer | Each layer at scrolled offset. Simple. |
| `src/animation/` | `DrawQuad` per animated object | Sprite-sheet frame selection → quad region. |
| `src/spine/` | `DrawQuad` per mesh attachment slot | Mesh deformation computed on CPU, output as textured quads. |
| `src/camera/` | `PushTransform`, `Translate`, `Scale`, `Rotate`, `PopTransform` | Not a content producer — wraps other content in a transform. |

### Modules that produce structured data (NOT RenderCommands)

These modules give the renderer domain-specific data. The renderer's
subsystems decide *how* to draw them:

| Module | Output type | Consumed by |
|---|---|---|
| `src/light/` (`Light2D`, `Occluder`) | `Vec<Light2D>` + `Vec<Occluder>` | `GpuRenderer` light pass — shadow map generation, light accumulation buffer, blend composite. Uses shaders. |
| `src/effect/` (`PostFxEffect`, `PostFxStack`) | `Vec<PostFxEffect>` with `HashMap<String, f32>` params | `GpuRenderer` post-FX pass — multi-pass WGSL shader pipeline (bloom, blur, CRT, chromatic, custom). |
| `src/minimap/` | Terrain grid + fog + objects + pings + markers | Could produce `Vec<RenderCommand>` (simple rects/images) OR render to a canvas. Design choice depends on complexity. |
| `src/raycaster/` | `RaycasterScene` (wall quads, floor quads, ceiling quads, billboard sprites) | See §11.1. The raycaster model computes perspective-projected textured quads; the GPU renderer draws them. |

### Modules that produce no render output

| Module | Role |
|---|---|
| `src/physics/` | Simulation only. Debug draw (optional) produces `Vec<RenderCommand>` of shapes. |
| `src/audio/` | Audio backend — no visual output. |
| `src/input/` | Input backend — no visual output. |
| `src/ai/` | Decision logic — no visual output. |
| `src/math/` | Foundation math — no visual output. |
| `src/data/` | Foundation data structures — no visual output. |

---

## Design Decisions

### Raycaster — textured-quad 2.5D renderer

**What the raycaster is**: A 2.5D first-person environment renderer built
on a 2D tile grid. Think Minecraft: the world is a grid of tiles. Every
surface — wall face, floor tile, ceiling tile — is a **textured quad**
positioned in perspective-projected space. There are no vertical column
strips or scanline-based rendering.

**World model**: A 2D grid where each cell can have:

- **Wall faces** (north, south, east, west) — each face is a textured quad
  (doors, windows, brick, stone — different textures per face)
- **Floor tile** — a textured quad per tile (stone path, water, grass, wood —
  different textures per tile, not a single flat colour)
- **Ceiling tile** — a textured quad per tile (sky, rafters, cave rock —
  different textures per tile, not a single flat colour)
- **Billboard sprites** — simple flat objects (enemies, items, torches) at
  the same Z level. They move in the XY plane only (left/right/forward/back),
  never up/down. They are always camera-facing.

**Design: textured quads, not columns**

The raycaster does NOT render vertical strips or columns. Instead:

1. For each visible wall face → project the face corners into screen space →
   output a `WallQuad` (four projected vertices + texture coordinates +
   distance-based shading)
2. For each visible floor tile → project the tile corners into screen space →
   output a `FloorQuad` (four projected vertices + texture coordinates)
3. For each visible ceiling tile → project the tile corners → output a
   `CeilingQuad` (four projected vertices + texture coordinates)
4. For each visible sprite → project to screen space → output a
   `BillboardSprite` (position, size, texture, depth)

All quads are **perspective-correct** — the raycaster model computes the
projection math; the GPU renderer just draws textured quads.

**Output types** (CPU-side, no GPU dependency):

```rust
/// Complete raycaster scene output for one frame.
pub struct RaycasterScene {
    pub walls: Vec<WallQuad>,
    pub floors: Vec<FloorQuad>,
    pub ceilings: Vec<CeilingQuad>,
    pub sprites: Vec<BillboardSprite>,
    pub fog_color: Color,
    pub fog_density: f32,
    pub ambient_light: Color,
}

/// A single wall face projected into screen space.
pub struct WallQuad {
    pub corners: [Vec2; 4],   // screen-space projected corners
    pub tex_coords: [Vec2; 4], // UV coordinates
    pub texture_id: u32,       // which wall texture (door, window, brick...)
    pub shade: f32,            // distance-based darkening [0..1]
    pub depth: f32,            // average depth for sorting
    pub light_color: Color,    // per-quad light tint from nearby light sources
}

/// A single floor tile projected into screen space.
pub struct FloorQuad {
    pub corners: [Vec2; 4],
    pub tex_coords: [Vec2; 4],
    pub texture_id: u32,       // floor texture (stone, water, grass...)
    pub shade: f32,
    pub depth: f32,
    pub light_color: Color,
}

/// A single ceiling tile projected into screen space.
pub struct CeilingQuad {
    pub corners: [Vec2; 4],
    pub tex_coords: [Vec2; 4],
    pub texture_id: u32,       // ceiling texture (sky, cave, wood...)
    pub shade: f32,
    pub depth: f32,
    pub light_color: Color,
}

/// A billboard sprite (enemy, item, torch) in the raycaster view.
pub struct BillboardSprite {
    pub screen_pos: Vec2,      // screen-space centre
    pub screen_size: Vec2,     // screen-space width × height
    pub texture_id: u32,
    pub tex_region: Rect,      // sub-region of sprite sheet
    pub depth: f32,            // for depth sorting
    pub light_color: Color,
}
```

**Lighting in the raycaster**: Light and fog colours apply to the raycaster
view just as they do to the 2D world. Each quad carries a `light_color`
tint computed by the raycaster model from nearby `Light2D` sources. The
`fog_color` and `fog_density` fields enable distance-based fog that the GPU
renderer applies during drawing. The raycaster's lighting is compatible with
the engine's 2D lighting system — the same `Light2D` descriptors that
illuminate 2D sprites also affect raycaster quads.

**`draw_to_image()` — model-level CPU testing**

The `draw_to_image()` function lives **in the raycaster model**
(`src/raycaster/draw.rs`), NOT in the renderer. It produces a CPU pixel
buffer (`ImageData`) by software-rasterizing the `RaycasterScene` quads.
This is used for:

- **Headless evidence tests** — verify rendering output without a GPU
- **Golden image comparison** — deterministic pixel output for regression
- **Visual debugging** — save diagnostic images to disk

It is NOT the production rendering path. The GPU renderer handles production
rendering of `RaycasterScene` using textured quads.

**Frame flow (target)**:

```
Lua: lurek.raycaster.render(ray, px, py, angle, fov)
  │
  ▼
src/lua_api/raycaster_api.rs   (thin wrapper)
  │  calls ray.build_scene(px, py, angle, fov) → RaycasterScene
  │  pushes RaycasterScene into SharedState.raycaster_output
  ▼
src/app/app.rs  (coordinator)
  │  passes SharedState.raycaster_output to render_frame()
  ▼
src/render/gpu_renderer.rs
  │  raycaster render path:
  │    - upload wall/floor/ceiling quads as vertex buffers
  │    - draw textured quads with perspective-correct UVs
  │    - GPU applies per-quad light_color tint and fog
  │    - draw billboard sprites depth-sorted
  ▼
screen
```

**Why textured quads, not column strips?**

| Approach | Pros | Cons |
|---|---|---|
| Column strips (vertical scanlines) | Classic technique, simple | Cannot render per-tile floor/ceiling textures; poor quality at high resolution; no perspective-correct walls |
| Textured quads (Minecraft-style) | Per-tile textures for walls/floor/ceiling; perspective-correct; GPU-native; scales to any resolution | More geometry to upload (quads vs columns) |

Column rendering assumes all floor tiles share one colour and all ceiling
tiles share one colour. This is too limited — games need paths on floors,
water tiles, different ceiling materials per tile. Textured quads solve this
naturally: each tile quad has its own texture and UV mapping.

**Module file layout**:

```
src/raycaster/
    mod.rs              ← thin re-exports
    dda.rs              ← core DDA ray traversal, hit detection
    scene.rs            ← RaycasterScene, WallQuad, FloorQuad, CeilingQuad, BillboardSprite
    draw.rs             ← draw_to_image() — CPU pixel rasterizer for testing (model-level)
    AGENT.md            ← AI agent overview
```

---

### Lighting — GPU-side shader system with CPU data

**Problem with the original design**: The previous version described lighting as
`UploadPixels + DrawImage of light canvas`. This is wrong. The 2D lighting
system uses GPU shaders for shadow calculation and light accumulation.

**What the light system actually is**: `Light2D` is a pure data descriptor
with fields for position, radius, color, intensity, falloff curve, light type
(point / directional / spot), shadow configuration (PCF filtering, shadow
color), flicker parameters, and masking (light_mask, shadow_mask). `Occluder`
is a polygon shadow caster (3-512 vertices) with opacity.

This data lives in SharedState (set by Lua via `lurek.light.*`) and is passed
to the renderer as uniform/structured data. The renderer's light subsystem
(`src/render/light/`) does the actual GPU work:

1. **Shadow pass** — for each shadow-enabled light, render occluder geometry
   into a 1D shadow map texture (radial distance from light center). Uses
   `ShadowFilter` (None, PCF5, PCF13) for edge quality.
2. **Light accumulation** — for each light, draw a light quad into a
   light accumulation canvas (additive blending). The fragment shader samples
   the shadow map and applies falloff.
3. **Compositing** — multiply-blend the light accumulation buffer over the
   scene.

**This is a Category B operation (GPU off-screen)**: It uses `CanvasKey`
render targets, not CPU pixel uploads. The CPU module provides data; the GPU
module does rendering.

**Frame flow (target)**:

```
Lua: lurek.light.addPointLight(x, y, radius, color, intensity)
     lurek.light.addOccluder(vertices)
  │
  ▼
src/lua_api/light_api.rs   (thin wrapper, stores in SharedState)
  ▼
src/app/app.rs  (coordinator)
  │  lights = state.light_world.get_active_lights()
  │  occluders = state.light_world.get_occluders()
  │  passes both to render_frame(commands, lights, occluders, ...)
  ▼
src/render/light/   (GPU code, part of renderer)
  │  1. For each shadow-enabled light:
  │     render occluders into 1D shadow map (WGSL shader)
  │  2. For each light:
  │     draw light quad with falloff + shadow lookup (WGSL shader)
  │     additive blend into light accumulation canvas
  │  3. Multiply-blend light canvas over scene
  ▼
screen — scene darkened where no light reaches,
         lit where light sources illuminate
```

**Occluder shadows are GPU-computed, not CPU-computed.** The shadow map
rendering uses GPU fragment shaders for performance. CPU shadow casting
(used by some 2D engines) does not scale beyond ~50 occluders at 60fps.

---

### Modules that produce multiple output types

Some modules produce more than one type of output. This is expected and correct:

| Module | Output 1 | Output 2 | Output 3 |
|---|---|---|---|
| `src/raycaster/` | `RaycasterScene` (wall/floor/ceiling textured quads for GPU) | `Vec<BillboardSprite>` (depth-sorted for GPU) | Testing: `ImageData` via `draw_to_image()` in model |
| `src/minimap/` | `Vec<RenderCommand>` (terrain grid, fog overlay) | Ping animations (ephemeral markers) | Viewport indicator rect |
| `src/effect/` | `Vec<PostFxEffect>` (shader pipeline config) | Overlay state (ambient, weather, fade, shake) | Per-image `ShaderPassDescriptor` |
| `src/tilemap/` | `Vec<RenderCommand>` (visible tile quads) | Collision data (`Vec<SweepResult>`) | Animation frame updates |
| `src/ui/` | `Vec<RenderCommand>` (widget draw primitives) | Hit-test results (which widget was clicked) | Layout data (`computed_rect` per widget) |
| `src/particle/` | `Vec<RenderCommand>` (single `DrawParticleSystem`) | Emitter state (active/stopped/paused) | — |
| `src/physics/` | Nothing (simulation only) | Debug: `Vec<RenderCommand>` (wireframe shapes) | — |

**The architecture must not assume one output type per module.** App collects
each output type through the appropriate channel:
- `Vec<RenderCommand>` → extend the main command buffer
- Light/PostFx data → pass as separate arguments to `render_frame()`
- Collision/hit-test data → consumed by physics or input handling, not rendering

---

### draw_to_image is for testing and debugging only

Several modules have `draw_*_to_image()` functions that produce an `ImageData`
(CPU pixel buffer). These are **NOT the production rendering path**.

**Purpose of `draw_to_image()` functions**:
- Unit testing — assert pixel values without a GPU
- Visual debugging — save diagnostic images to disk
- Screenshot for documentation — one-off image generation
- Headless CI — tests run without a GPU/window

**Where they live**: In a separate file within the module, typically named
`draw.rs` or `debug_draw.rs`:

```
src/raycaster/
    mod.rs          ← thin re-exports
    dda.rs          ← core DDA ray traversal, hit detection
    scene.rs        ← RaycasterScene, WallQuad, FloorQuad, CeilingQuad, BillboardSprite
    draw.rs         ← draw_to_image() — CPU pixel rasteriser for testing (model-level)
```

**Why a separate file?** The `draw_to_image()` functions depend on
`src/image/ImageData` and contain rendering logic (pixel filling, color
interpolation). Keeping them separate from the core algorithm:
- Makes it clear they are not production code
- Prevents the core file from growing too large
- Allows conditional compilation (e.g., `#[cfg(test)]` or a feature flag)
- The public API functions can be tested without pulling in pixel rendering

**Any module** can have a `draw.rs` for CPU pixel debugging. But the production
rendering path always goes through `src/render/` via the GPU.

---

### UI Layout ownership

**Decision: layout is owned entirely by `src/ui/`. The renderer never sees
layout data.**

This matches Flutter, Bevy UI, and Godot 4's Control nodes: the UI module
owns layout computation; the renderer only receives final draw primitives.

**Data model for `src/ui/widget.rs`**:

```rust
pub struct WidgetBase {
    // --- declared (set by Lua or code) ---
    pub x: f32, pub y: f32,          // anchor position (if not in a flex container)
    pub width: f32, pub height: f32,  // declared size (0 = auto)
    pub flex_grow: f32,
    pub flex_shrink: f32,
    pub padding: Edges,
    pub margin: Edges,
    pub z_order: i32,

    // --- computed (written by layout pass, read by render + hit-test) ---
    pub computed_rect: Rect,          // absolute screen position after layout
    pub is_visible: bool,             // false if clipped by parent ScrollPanel
}
```

**Two-pass model inside `generate_render_commands()`**:

```rust
impl GuiContext {
    pub fn generate_render_commands(&self) -> Vec<RenderCommand> {
        // Pass 1: layout
        let mut scratch = LayoutScratch::new();
        self.run_layout_pass(&mut scratch);

        // Pass 2: render
        let mut commands = Vec::with_capacity(self.widgets.len() * 4);
        self.emit_commands(&scratch, &mut commands);
        commands
    }
}
```

Layout runs automatically before rendering — Lua never calls layout manually.
But Lua can read back the computed position for custom overlays:

```lua
local rx, ry, rw, rh = btn:getRect()  -- computed rect after layout
```

---

## Module Internal File Structure Standard

Every `src/<module>/` directory in Lurek2D follows a standard internal
structure. Consistency across all modules is a **binding requirement** —
not a suggestion. This standard flows from Philosophy Rules 7 (split by
reason to change), 12 (bindings are thin), 13 (tests follow responsibility),
and 15 (optimise for readability).

### Required Files

Every module MUST have:

| File | Purpose | Rules |
|---|---|---|
| `mod.rs` | Module declaration and re-exports | **THIN**: only `pub mod`, `pub use`, and `//!` module-level doc comment. No functions, no struct definitions, no logic. Target: ≤30 lines. |
| `AGENT.md` | AI agent overview | Lists source files, purpose, pointer to `docs/specs/<module>.md`. |

### Standard Optional Files

Use these file names when the module needs them. The file name is
**standardised** — do not invent alternatives.

| File | Purpose | When to Use |
|---|---|---|
| `<primary>.rs` | Main logic — algorithms, state, methods | Always, unless mod.rs alone is sufficient (leaf modules with one type). Named after the module's primary concept (e.g., `emitter.rs`, `dda.rs`, `widget.rs`). |
| `types.rs` | Public data types (structs, enums, traits) | When the module exports 5+ public types. If fewer, define them in `<primary>.rs`. |
| `draw.rs` | `draw_to_image()` debug/test CPU pixel utilities | Only for modules that need CPU-side pixel rendering for testing or evidence. May import `crate::image::ImageData`. NOT the production render path (see §11.4). |
| `builder.rs` | Builder pattern for complex struct construction | When a primary type has 5+ fields with defaults. |

### mod.rs — The Thin Declaration Rule

`mod.rs` is a **switchboard**, not a workshop. It declares submodules
and re-exports their public surface. It must never contain:

- Function bodies
- Struct or enum definitions (except zero-variant marker types)
- Business logic of any kind
- Trait implementations

**Correct** mod.rs:

```rust
//! Particle system — CPU-side emitter simulation and instance generation.

pub mod emitter;

pub use emitter::{ParticleSystem, ParticleInstance, ParticleShape};
```

**Wrong** mod.rs:

```rust
pub mod emitter;

// ❌ logic in mod.rs
pub fn default_particle_color() -> Color {
    Color::new(1.0, 1.0, 1.0, 1.0)
}

// ❌ struct definition in mod.rs
pub struct ParticleConfig {
    pub max_count: usize,
}
```

### Testing Within Modules

Private helper functions are tested with inline `#[cfg(test)]` blocks in
the source file where they are defined:

```rust
// src/particle/emitter.rs

fn compute_velocity(angle: f32, speed: f32) -> Vec2 {
    Vec2::new(angle.cos() * speed, angle.sin() * speed)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn compute_velocity_zero_angle_goes_right() {
        let v = compute_velocity(0.0, 10.0);
        assert!((v.x - 10.0).abs() < 1e-5);
        assert!(v.y.abs() < 1e-5);
    }
}
```

**Public methods** are tested via integration tests in `tests/rust/` and
`tests/lua/`. See the test framework document for the full test placement
strategy.

### Docstring Requirements (Binding — Philosophy Rule 15, Q-05)

Every `pub` item requires a `///` doc comment. No exceptions.

| Item | Required content |
|---|---|
| `pub fn` | One-sentence summary. `# Parameters` and `# Returns` for non-trivial signatures. |
| `pub struct` | One-sentence summary. `# Fields` section listing every field. |
| `pub enum` | One-sentence summary. `# Variants` section listing every variant. |
| `pub trait` | One-sentence summary. One-sentence per method. |
| `mod.rs` | `//!` module-level doc — one sentence describing the module's responsibility. |

**Lua API files** (`src/lua_api/`) use inline `@param name : type` and
`@return type` annotations instead of rustdoc `# Parameters` / `# Returns`
sections. Gold standard: `src/lua_api/timer_api.rs`.

### Lua Binding Separation (Binding — Philosophy Rule 12)

| Location | Contains | Must NOT Contain |
|---|---|---|
| `src/<module>/` | Pure Rust logic, algorithms, data types | `mlua` imports, `impl LuaUserData`, `LuaTable`, `LuaFunction` |
| `src/lua_api/<module>_api.rs` | `pub fn register()`, Lua wrapper structs, `impl LuaUserData`, `add_method` calls | Business logic (>10 lines of non-glue code) |

**Thin wrapper test**: If the function body in a `lua_api` closure is more
than ~10 lines, the logic belongs in the domain module. The `lua_api` file
calls a domain method; it does not implement one.

**Public API surface**: Methods that Lua scripts need to call are declared as
`pub fn` on domain types in `src/<module>/`. The `lua_api` file calls these
public methods:

```rust
// src/particle/emitter.rs (domain module — pure Rust)
impl ParticleSystem {
    /// Emit `count` particles at the given world position.
    pub fn emit(&mut self, x: f32, y: f32, count: u32) { ... }
}

// src/lua_api/particle_api.rs (binding — thin glue)
let s = state.clone();
tbl.set("emit", lua.create_function(move |_, (x, y, count): (f32, f32, u32)| {
    s.borrow_mut().particle_sys.emit(x, y, count);
    Ok(())
})?)?;
```

### Example: Well-Structured Module

```
src/particle/
    mod.rs              ← //! doc + pub mod emitter; pub use emitter::*;
    emitter.rs          ← ParticleSystem, ParticleInstance, build_render_commands()
                           + #[cfg(test)] for private helpers
    AGENT.md            ← AI agent overview, file list, spec pointer

src/lua_api/
    particle_api.rs     ← pub fn register(), calls state.particle_sys.method(...)
```

### Anti-Patterns

| Problem | Symptom | Fix |
|---|---|---|
| Fat mod.rs | mod.rs has functions, struct definitions, or >30 lines of non-doc content | Move everything to `<primary>.rs`, keep mod.rs as pure re-export |
| Logic in lua_api | lua_api closure computes, transforms, or makes decisions | Extract logic to domain module, call from lua_api |
| LuaUserData in domain | `impl LuaUserData` appears in `src/<module>/` | Move to `src/lua_api/<module>_api.rs` |
| Missing docstrings | `pub fn` without `///` | Add doc comment — violation of Q-05 |
| No tests | Module has public API but no test coverage | Add tests — violation of Q-03/Q-04 |
| Invented file names | `helpers.rs`, `utils.rs`, `common.rs` | Use standard names: `types.rs`, `draw.rs`, `builder.rs` |
| GPU imports in domain | `use wgpu::*` in a non-render module | Domain modules must be GPU-free (Philosophy Rule 3/9) |

---

## Render Module Refactoring Plan

### Principle

`src/render/` should contain exactly two categories of code:

1. **The render contract** — data types that define what CAN be drawn
   (`RenderCommand`, `DrawMode`, `BlendMode`, resource keys). These are the
   interface between CPU domain modules and the GPU renderer.

2. **The GPU implementation** — code that talks to wgpu (`GpuRenderer`,
   `Shader`). This is the backend that executes the contract.

Types that are **general-purpose CPU data** used by many modules should live
in their natural home, not in `src/render/`. This follows Philosophy Rule 3
("Depend on Contracts, Not Backends") and Rule 9 ("Pure Logic Stays Pure").

### Current State of src/render/

`src/render/` currently contains 18 `.rs` files. Of these:

- **2 are GPU-dependent** (import wgpu): `gpu_renderer.rs`, `shader.rs`
- **16 are pure CPU data**: no wgpu, no winit, no GPU function calls

The 16 CPU files range from render-specific contracts (RenderCommand) to
general-purpose types (Color) to game-domain data (SpriteSheet).

### Extraction Decision Table

| File | Verdict | Proposed Home | Reasoning |
|---|---|---|---|
| `gpu_renderer.rs` | **KEEP** | `src/render/` | Core GPU rendering — wgpu pipelines, render passes, buffer management. The ONLY file that issues draw calls. |
| `shader.rs` | **KEEP** | `src/render/` | WGSL validation via `wgpu::naga`, GPU pipeline integration. Coupled to wgpu internals. |
| `renderer.rs` | **KEEP** | `src/render/` | `RenderCommand` enum IS the render contract. Even though it is pure data, it exists solely for the renderer and is the central interface. |
| `font.rs` | **KEEP** | `src/render/` | Font glyph atlas is tightly coupled to text rendering pipeline. GPU uploads atlas and uses it for all text. No use case for fonts outside rendering. Extracting creates a weak standalone module (Rule 14). |
| `mesh.rs` | **KEEP** | `src/render/` | `MeshVertex` format is defined by the GPU vertex layout. Vertex/index buffers are renderer-specific data. |
| `canvas.rs` | **KEEP** | `src/render/` | Off-screen GPU render target descriptor. Only meaningful in a rendering context. |
| `decal_surface.rs` | **KEEP** | `src/render/` | GPU decal target descriptor. Rendering-specific metadata. |
| `draw_layer.rs` | **KEEP** | `src/render/` | Z-order queue for `RenderCommand` sorting — a rendering pipeline concern. |
| `shape.rs` | **KEEP** | `src/render/` | Vector primitive commands that feed `gpu_renderer` tessellation directly. |
| `image_effect.rs` | **KEEP** | `src/render/` | `ShaderPassDescriptor` configures render passes. Tightly coupled to GPU pipeline. |
| `color.rs` | **EXTRACT** | `src/math/color.rs` | `Color` (RGBA f32) is a math primitive like `Vec2` and `Rect`. Used by particle, ui, light, effect, tilemap, minimap, raycaster, physics (debug draw) — far broader than rendering. Philosophy Rule 9. |
| `sprite.rs` | **EXTRACT** | `src/sprite/sprite.rs` (new) | Pure CPU data: position + transform + texture key reference + tint. Used by animation, tilemap, particle. Game-domain data, not render-specific. |
| `sprite_batch.rs` | **EXTRACT** | `src/sprite/sprite_batch.rs` (new) | CPU sprite collection. Data queue with no GPU calls. Groups naturally with Sprite. |
| `sprite_sheet.rs` | **EXTRACT** | `src/sprite/sprite_sheet.rs` (new) | Frame grid math, animation groups, direction layouts. Pure CPU. Used by animation system for frame lookup. |
| `nine_slice.rs` | **EXTRACT** | `src/sprite/nine_slice.rs` (new) | Nine-slice is a sprite technique (texture key + border insets → quad computation). Groups with sprite types. |
| `texture.rs` | **EXTRACT** | `src/image/texture.rs` | CPU image decode (PNG/JPEG via `image` crate) → `TextureData` (pixel buffer). `src/image/` already handles CPU image operations. GPU texture upload happens in `gpu_renderer.rs`, not here. |
| `texture_atlas.rs` | **EXTRACT** | `src/image/texture_atlas.rs` | Shelf bin-packing algorithm producing UV regions. Pure CPU. Natural companion to texture loading in `src/image/`. |

### Summary

| Action | Files | Count |
|---|---|---|
| **KEEP in src/render/** | gpu_renderer, shader, renderer, font, mesh, canvas, decal_surface, draw_layer, shape, image_effect, mod | 11 |
| **EXTRACT to src/math/** | color | 1 |
| **EXTRACT to src/sprite/** (new module) | sprite, sprite_batch, sprite_sheet, nine_slice | 4 |
| **EXTRACT to src/image/** | texture, texture_atlas | 2 |

### Post-Refactoring: src/render/ Contents

After extraction, `src/render/` contains only render-contract and GPU code:

```
src/render/
    mod.rs              ← re-exports
    renderer.rs         ← RenderCommand enum, DrawMode, BlendMode, TextureData (contract)
    gpu_renderer.rs     ← GpuRenderer — wgpu device, pipelines, render passes (GPU)
    shader.rs           ← Shader, WGSL naga validation (GPU)
    font.rs             ← Font, GlyphInfo — bitmap font atlas (GPU-coupled)
    mesh.rs             ← Mesh, MeshVertex, MeshDrawMode (GPU vertex format)
    canvas.rs           ← Canvas — off-screen render target descriptor
    decal_surface.rs    ← DecalSurface — GPU decal target descriptor
    draw_layer.rs       ← DrawLayer, LayerEntry — z-order queue
    shape.rs            ← ShapeCommand, CompoundShape — vector primitives
    image_effect.rs     ← ShaderPassDescriptor — per-image shader pass config
    AGENT.md
```

### New Module: src/sprite/

**Module group**: Feature Systems
**Dependencies**: `src/math/` (Color, Vec2), engine resource keys (TextureKey)
**Responsibility**: CPU-side sprite data management — frame grids, animation
groups, sprite transforms, batched sprite collections, nine-slice regions.

**Does NOT contain**: GPU rendering code. Sprite drawing goes through
`RenderCommand` variants (`DrawQuad`, `DrawBatch`, `DrawNineSlice`). The
renderer handles GPU execution.

```
src/sprite/
    mod.rs              ← pub mod, pub use, //! doc
    sprite.rs           ← Sprite (position, transform, texture key, tint)
    sprite_sheet.rs     ← SpriteSheet, FrameGroup, DirectionLayout
    sprite_batch.rs     ← SpriteBatch, BatchEntry
    nine_slice.rs       ← NineSlice, Patch
    AGENT.md
```
