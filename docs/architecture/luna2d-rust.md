# Luna2D (Rust) — Architectural Analysis

> **Language**: Rust (stable ≥1.78) | **Scripting**: Lua (LuaJIT via mlua; Lua 5.4 fallback) | **Rendering**: wgpu 22 | **License**: MIT

## Overview

Luna2D is a 2D game engine written in Rust that loads and executes Lua game scripts. Inspired by the Love2D callback model (`luna.load`, `luna.update(dt)`, `luna.draw`), it ships as a single executable that runs a `main.lua` from a game directory. The engine targets desktop platforms (Windows, Linux, macOS) with WASM and mobile on the roadmap. The Lua API surface is exposed under a `luna.*` namespace across 26 modules totaling 100+ functions, backed by mature Rust crates: wgpu for GPU rendering, rapier2d for physics, rodio for audio, gilrs for gamepads, and fontdue for font rasterization.

The project is approximately 28,000 lines of production Rust code across 22 core modules, with an additional 16 integration test files and a Lua-side test framework.

## Core Design Principles

1. **Love2D-Inspired Callback Model** — Global Lua functions (`luna.load`, `luna.update(dt)`, `luna.draw`) are called by the engine in a fixed sequence. Games start with a single `main.lua`. No mandatory class instantiation or framework boilerplate.

2. **Rust-Owned Game Loop** — Unlike Love2D's Lua-side `love.run()`, the game loop is implemented in Rust via winit 0.30's `ApplicationHandler` trait. Lua receives callbacks but does not control frame timing. This provides deterministic ordering and crash safety.

3. **Draw Command Queue** — Lua calls during `luna.draw()` push `DrawCommand` variants into a queue. The engine processes and submits them to the GPU after the callback returns. Drawing never happens inside a Lua closure — it always happens in Rust after Lua yields.

4. **SharedState via Interior Mutability** — A single `Rc<RefCell<SharedState>>` struct holds all engine state (GPU resources, input, audio, physics, timers). Lua closures capture `Rc` clones. No `unsafe`, no raw pointers — RefCell bridges Rust's borrow checker with single-threaded Lua access.

5. **Flat Procedural Namespace** — All API calls live under `luna.module.function()`. OOP-style method calls on userdata objects (Image, Font, Canvas, Mesh, Shader) are available but optional. The primary surface is procedural.

6. **GPU-First Rendering** — wgpu 22 provides the rendering backend with cross-platform support (DirectX 12, Vulkan, Metal, WebGPU).

7. **Generational Resource Management** — All GPU resources (textures, fonts, sprites, canvases, meshes, shaders) are stored in SlotMaps with type-safe generational keys. Handles persist across frames without dangling reference risk.

8. **Sandboxed Filesystem** — `luna.filesystem` confines all I/O to the game directory and a per-game save directory. Path traversal via `../` is blocked. No raw OS path access from Lua.

9. **Configuration via `conf.lua`** — Window dimensions, vsync, fullscreen, audio/physics module toggles, and target FPS are declared in a `conf.lua` file processed before the engine starts.

10. **Error Recovery, Not Crash** — Runtime errors display an in-engine error screen with the Lua traceback and recovery hints rather than crashing to desktop. The engine defines 12 `EngineError` variants with stable error codes (E1001–E1012) and human-readable descriptions.

11. **Module Independence** — Domain modules (graphics, physics, audio, input, timer, math, filesystem) do not depend on each other except through the foundational `math` module. Only `engine` and `lua_api` are allowed to import across domains.

12. **Lua-Agnostic Domain Layer** — The `src/graphics/`, `src/physics/`, `src/audio/` modules are pure Rust with no Lua dependencies. Lua bindings are a separate layer in `src/lua_api/`. This keeps the engine testable from Rust without a Lua VM.

## Core Architecture

```
┌──────────────────────────────────────────────────────┐
│  User Game (main.lua + conf.lua)                      │
│  luna.load() / luna.update(dt) / luna.draw()          │
└──────────────┬───────────────────────────────────────┘
               │
┌──────────────▼───────────────────────────────────────┐
│  Lua VM (mlua — LuaJIT or Lua 5.4)                    │
│  luna.* namespace tables ← register() per module      │
│  Closures capture Rc<RefCell<SharedState>>             │
└──────────────┬───────────────────────────────────────┘
               │
┌──────────────▼───────────────────────────────────────┐
│  Lua API Layer (src/lua_api/ — 26 files)              │
│  ┌──────────┬──────────┬──────────┬──────────────┐   │
│  │graphics  │ audio    │ physics  │ input        │   │
│  │(50+ fn)  │ (15 fn)  │ (20 fn)  │ (20 fn)      │   │
│  ├──────────┼──────────┼──────────┼──────────────┤   │
│  │math      │ timer    │filesystem│ window       │   │
│  │(30+ fn)  │ (5 fn)   │ (10 fn)  │ (15 fn)      │   │
│  ├──────────┼──────────┼──────────┼──────────────┤   │
│  │particle  │ tilemap  │ ai       │ data/df/     │   │
│  │(10 fn)   │ (10 fn)  │ (20 fn)  │ graph/compute│   │
│  └──────────┴──────────┴──────────┴──────────────┘   │
└──────────────┬───────────────────────────────────────┘
               │
┌──────────────▼───────────────────────────────────────┐
│  Engine Layer (src/engine/ — 8 files)                 │
│  LunaApp (ApplicationHandler) │ Config │ EngineError  │
│  ErrorScreen │ DebugOverlay │ SharedState             │
│  RunState: Running | Error(ErrorScreen) | Restarting  │
└──────────────┬───────────────────────────────────────┘
               │
┌──────────────▼───────────────────────────────────────┐
│  Domain Modules (no cross-dependencies)               │
│  ┌──────────┬──────────┬──────────┬──────────────┐   │
│  │ graphics │  audio   │ physics  │   input      │   │
│  │ (wgpu)   │ (rodio)  │(rapier2d)│(winit+gilrs) │   │
│  ├──────────┼──────────┼──────────┼──────────────┤   │
│  │  math    │  timer   │filesystem│   event      │   │
│  │ (Vec2,   │ (Clock)  │ (GameFS) │ (EventQueue) │   │
│  │  Mat3)   │          │          │              │   │
│  ├──────────┼──────────┼──────────┼──────────────┤   │
│  │ particle │ tilemap  │   ai     │data/df/graph │   │
│  │(Emitter) │(TileMap) │(FSM, BT)│ compute/img  │   │
│  └──────────┴──────────┴──────────┴──────────────┘   │
└──────────────────────────────────────────────────────┘
```

### Binding Registration Pattern

```rust
// Every src/lua_api/<module>_api.rs follows this pattern
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let gfx = lua.create_table()?;

    let state_clone = state.clone();
    gfx.set("rectangle", lua.create_function(move |_, (mode, x, y, w, h): (String, f32, f32, f32, f32)| {
        let mut s = state_clone.borrow_mut();
        s.draw_commands.push(DrawCommand::Rectangle { mode, x, y, w, h });
        Ok(())
    })?)?;

    luna.set("graphics", gfx)?;
    Ok(())
}
```

### Game Loop (Rust-side ApplicationHandler)

```rust
impl ApplicationHandler for LunaApp {
    fn resumed(&mut self, event_loop: &ActiveEventLoop) {
        // Create window, initialize GPU, load conf.lua, call luna.load()
    }

    fn window_event(&mut self, event_loop: &ActiveEventLoop, _id: WindowId, event: WindowEvent) {
        match event {
            WindowEvent::KeyboardInput { .. } => { /* update input → call luna.keypressed */ }
            WindowEvent::CursorMoved { .. } => { /* update mouse state */ }
            WindowEvent::RedrawRequested => {
                // 1. Clock tick → dt
                // 2. Call luna.update(dt)
                // 3. Call luna.draw()
                // 4. Process DrawCommand queue → GPU submission
                // 5. Present swapchain frame
            }
            _ => {}
        }
    }

    fn about_to_wait(&mut self, _event_loop: &ActiveEventLoop) {
        self.window.request_redraw(); // continuous rendering
    }
}
```

## Focus & Target Audience

- **Indie game developers** who want a Love2D-like experience with Rust's safety and performance
- **Hobbyists and learners** — minimal boilerplate, one file to start
- **Desktop 2D games** (Windows, Linux, macOS) — mobile and web on the roadmap
- **Developers seeking batteries-included** — AI, particles, tilemaps, physics, and data structures built in rather than requiring third-party libraries

## Module Inventory

| Module | Files | LOC (est.) | Backend | Purpose |
|--------|-------|-----------|---------|---------|
| graphics | 25 | ~5,000 | wgpu 22 | GPU rendering pipeline, sprites, fonts, cameras, shaders, effects |
| lua_api | 26 | ~8,000 | mlua | All Lua ↔ Rust bindings |
| engine | 8 | ~3,000 | winit 0.30 | App lifecycle, config, errors, debug overlay |
| math | 22 | ~4,000 | — | Vec2, Mat3, easing, noise, bezier, pathfinding, procgen, spatial hash |
| ai | 15 | ~2,000 | — | FSM, behavior tree, steering, GOAP, Q-learning, influence maps |
| physics | 4 | ~1,500 | rapier2d | Rigid bodies, collision detection, raycasting |
| audio | 4 | ~1,000 | rodio | Playback, mixer, buses, MIDI synthesis |
| input | 4 | ~800 | gilrs | Keyboard, mouse, gamepad, touch |
| tilemap | 5 | ~800 | — | TileSet, TileMap, autotile, procedural generation |
| data | 4 | ~600 | flate2/sha2 | ByteData, compression, hashing, encoding |
| dataframe | 4 | ~600 | — | Column-major tabular data, SQL-like queries |
| graph | 9 | ~800 | — | Directed graphs, item flow, supply/demand simulation |
| compute | 3 | ~400 | — | N-dimensional arrays (NumPy-style) |
| filesystem | 3 | ~400 | — | Sandboxed I/O, async loading |
| particle | 1 | ~500 | — | Emitter-based particle system |
| timer | 1 | ~150 | — | Clock (delta, FPS, elapsed) |
| image | 1 | ~200 | — | Pixel-level CPU manipulation |
| sound | 1 | ~150 | — | Raw PCM buffers |
| event | 1 | ~100 | — | Custom event queue |
| window | 2 | ~100 | — | Placeholder (actual loop in engine) |
| **Total** | **~140** | **~28,000** | | |

## Strong Points

| # | Strength | Details |
|---|----------|---------|
| 1 | **Memory safety without GC** | Rust's ownership model eliminates use-after-free, double-free, and buffer overflow classes entirely. No garbage collector pauses affecting frame timing. |
| 2 | **GPU-first rendering** | wgpu 22 abstracts DirectX 12, Vulkan, Metal, and WebGPU behind a single API. No OpenGL legacy path to maintain. Cross-platform GPU rendering from a single codebase. |
| 3 | **Production-grade physics** | rapier2d is the same physics engine used by Bevy and Fyrox. Supports rigid bodies, collision detection, raycasting, joints, kinematic bodies, and CCD — far beyond simple AABB checks. |
| 4 | **Generational resource handles** | SlotMap-based GPU resource management prevents dangling handles. A texture handle from frame N can't accidentally reference a different texture in frame N+100. |
| 5 | **Error recovery at runtime** | Lua errors display an in-engine error screen with traceback and recovery hints instead of crashing to desktop. 12 typed error variants with stable codes. |
| 6 | **Massive API surface** | 26 Lua API modules with 100+ functions. Covers graphics, audio, physics, input, AI, particles, tilemaps, data structures, and math. Most competing Rust engines offer bare rendering only. |
| 7 | **AI toolkit built-in** | FSM, behavior trees, steering behaviors, GOAP, Q-learning, pathfinding, influence maps, flocking, and squad formations — available from Lua without external libraries. No other 2D engine in this class includes AI primitives. |
| 8 | **Sandboxed filesystem** | Path traversal blocked, per-game save directories via identity system, no raw OS path access from Lua. Security by design. |
| 9 | **Professional audio system** | rodio-backed mixer with per-source volume/pitch/pan, audio buses for grouping, fade-in support, and MIDI synthesis. Graceful fallback when no audio device is present. |
| 10 | **Gamepad and touch support** | Cross-platform gamepad via gilrs (14+ buttons, 6 axes, GUID identification) and multi-touch with pressure and delta tracking. Most Lua engines lack this out of the box. |
| 11 | **Configuration system** | `conf.lua` supports window dimensions, vsync, fullscreen, module toggles, target FPS, identity for save directories — processed before engine startup. |
| 12 | **DrawCommand queue architecture** | Decouples Lua rendering intent from GPU submission. Enables debug overlays, error screens, and frame analysis without interfering with game rendering. |
| 13 | **Shader system** | Custom WGSL fragment shaders with parameter passing. Shaders are compiled and cached. Enables post-processing effects without leaving the Lua API. |
| 14 | **Comprehensive math library** | 22 submodules: Vec2, Mat3, easing (30+ functions), Bezier curves, Perlin/Simplex noise, procedural generation (cellular automata, Voronoi, Poisson), spatial hashing, and raycasting. |
| 15 | **Tilemap system with autotile** | Built-in TileSet, TileMap, auto-tiling (47-pattern Tiled/RPG Maker compatible), and procedural map generation. Most engines require third-party libraries for this. |
| 16 | **Particle system with rich config** | Emitter-based particles with lifetime, speed, direction, spread, gravity, color/size interpolation, area distributions (uniform, normal, ellipse), and insertion ordering. |
| 17 | **Font rendering with caching** | fontdue-based TTF/OTF rasterization with glyph caching. Print DrawCommand supports arbitrary fonts at any size. |
| 18 | **Canvas (render-to-texture)** | Offscreen rendering to canvas textures that can be drawn as images. Enables post-processing, UI layers, and minimap rendering. |
| 19 | **Sprite batching** | SpriteBatch groups draws of the same texture into a single GPU draw call, reducing state changes for tile-based or sprite-heavy games. |
| 20 | **Structured error codes** | EngineError enum with categories (Init, Runtime, Resource, Script, System) and per-variant recovery hints. Errors are actionable, not just stack traces. |
| 21 | **Transform stack** | Push/pop transform state for nested coordinate systems. Translate, rotate, scale operations accumulate on a matrix stack processed during GPU submission. |
| 22 | **Async asset loading** | Background file I/O with load-handle polling prevents frame-rate stalls during asset loads. |
| 23 | **Render statistics** | Tracks draw calls, texture switches, canvas switches, shader switches, and batched draws per frame — useful for profiling and optimization. |
| 24 | **Separation of bindings and domain** | Graphics, physics, and audio modules are pure Rust with no Lua dependency. They can be tested, benchmarked, and reused independently of the Lua layer. |
| 25 | **Modern windowing** | winit 0.30 ApplicationHandler trait-based event loop — the modern Rust windowing pattern. Handles display scaling, multi-monitor, and platform-specific quirks. |
| 26 | **Data processing modules** | ByteData, compression (deflate, gzip, lz4, zlib), hashing (MD5, SHA-256, SHA-512), encoding (base64, hex) — useful for save file management and asset packaging. |
| 27 | **Graph simulation** | Directed graph module with supply/demand flow, item conversion, decay, transit delays, and pathfinding algorithms (Dijkstra, BFS, DFS, topological sort). Unique among 2D engines. |
| 28 | **Dataframe module** | Column-major tabular data with SQL-like queries (select, where, group_by, join) and JSON/CSV serialization. Unusual for a game engine but useful for data-driven games. |
| 29 | **Single-binary distribution** | `cargo build --release` produces one executable. No shared library dependencies, no runtime installation needed on the target machine. |
| 30 | **Love2D API familiarity** | Developers who know Love2D can transfer their knowledge. Callback names, function signatures, and module organization are deliberately aligned. |

## Weak Points

| # | Weakness | Details |
|---|----------|---------|
| 1 | **Monolithic renderer file** | `gpu_renderer.rs` is ~3,100 lines — a single file handling buffer management, pipeline creation, batch submission, texture operations, canvas management, text rendering, shape rasterization, and shader switching. Difficult to navigate, test in isolation, or extend. |
| 2 | **Monolithic app file** | `app.rs` is ~2,100 lines handling window creation, GPU init, Lua VM setup, input dispatch, callback invocation, error handling, game restart, and debug overlay. This file does everything the engine does. |
| 3 | **RefCell borrow panic risk** | `Rc<RefCell<SharedState>>` in a single-threaded context is safe, but if a Lua callback triggers a re-entrant borrow (e.g., luna.draw() while the engine holds a mutable borrow), the process panics. No static compile-time guarantee against this. |
| 4 | **~~Legacy dependencies~~** | ~~tiny-skia 0.11 and minifb 0.27 were kept for a "CPU fallback" renderer.~~ **Resolved** — removed in the legacy renderer cleanup. |
| 5 | **LuaJIT platform fragmentation** | LuaJIT is x86_64-only. ARM and WASM targets must fall back to Lua 5.4, creating a two-tier API surface where LuaJIT-specific optimizations (FFI, bit operations) may not work on all platforms. |
| 6 | **No scene management** | No built-in scene/state machine, scene transitions, or scene stacking. Every game must implement its own scene graph or state machine from scratch. |
| 7 | **No networking** | No built-in networking, HTTP, WebSocket, or multiplayer support. Multiplayer games require external integration that the engine provides no hooks for. |
| 8 | **No hot reload** | Changing `main.lua` requires restarting the engine. There is no live-reload file watcher or Lua-side module reloading capability. |
| 9 | **Scope creep in module surface** | Dataframes with SQL queries, graph simulation with supply/demand flow, N-dimensional compute arrays, and Q-learning are unusual for a 2D game engine. They increase compile time, binary size, and maintenance burden without clear game-development use cases. |
| 10 | **No automated draw batching** | Each texture/shader/canvas switch creates a new draw call. The engine doesn't automatically atlas textures or merge compatible consecutive draws. Developers must manually use SpriteBatch for performance. |
| 11 | **Test coverage gaps** | Integration tests exist for most modules, but Lua API tests are minimal. Many of the 100+ exposed functions lack dedicated test cases. The Lua test framework exists but coverage is thin. |
| 12 | **No built-in UI toolkit** | No buttons, text inputs, layout containers, or HUD system. UI-heavy games must build their own or embed an external solution. |
| 13 | **GPU buffer sizing is hardcoded** | Color vertex buffer holds 131K vertices, texture vertex buffer holds 16K vertices. These are compile-time constants. Games exceeding these limits would need a source code change — no runtime configuration. |
| 14 | **Documentation is code-adjacent** | Public items have `///` doc comments, but there's no standalone tutorial, getting-started guide, or cookbook. The wiki/documentation ecosystem present in Love2D (16 years of community contributions) does not exist here. |
| 15 | **No video playback** | No support for playing video files, cutscenes, or animated backgrounds from common video formats. |
| 16 | **Unwrap usage in renderer** | The GPU renderer uses `.unwrap()` in several places where wgpu operations could theoretically fail (device creation, texture creation). These would panic rather than displaying the error screen. |
| 17 | **No ECS or entity management** | No built-in entity-component-system. Object lifecycle, spatial partitioning, and component queries are entirely the game author's responsibility. |
| 18 | **MIDI synthesis is basic** | MIDI playback uses sine-wave additive synthesis — functional but produces low-fidelity audio compared to samplers or SoundFont-based synthesis. |
| 19 | **2D only — no 3D capability** | The engine is exclusively 2D. Games requiring even basic 3D elements (2.5D perspective, 3D model previews) cannot use this engine. |
| 20 | **No plugin/extension system** | There's no mechanism for loading native Rust plugins at runtime or extending the `luna.*` namespace from external crates. All features must be compiled into the main binary. |
| 21 | **50+ crate dependency tree** | The Cargo.toml lists 50+ direct dependencies. Full transitive closure is larger. This increases compile times (clean builds likely 2+ minutes) and attack surface for supply chain vulnerabilities. |
| 22 | **No overridable game loop** | Unlike Love2D's `love.run()`, the Lua side cannot override the frame timing, fixed-timestep, or update order. The engine controls the loop — games must work within its constraints. |
| 23 | **Window module is a stub** | `src/window/` contains a placeholder module. The actual windowing logic is embedded deep in `src/engine/app.rs`. This architectural inconsistency means window-related queries must be answered by the engine module. |
| 24 | **No audio effects pipeline** | No built-in reverb, echo, EQ, or spatialization. Audio routing through buses supports volume and pitch only. |
| 25 | **Animation system is basic** | Frame-based sprite animation exists, but there's no skeletal animation, tweened property animation system, or animation blending. |
| 26 | **Canvas lifecycle ambiguity** | It's unclear from the API whether GPU-backed canvas textures are fully cleaned up when their SlotMap entries are removed, or whether there's a potential for GPU memory leaks in long-running sessions with frequent canvas creation/destruction. |
| 27 | **No built-in debug tooling** | Beyond the error screen and render stats, there's no inspector, console, performance profiler, or entity viewer accessible from within the running game. |
| 28 | **Event system is minimal** | The EventQueue supports custom string events, but there's no typed event system, event filtering, priority ordering, or event-driven component communication pattern. |
| 29 | **Tilemap format proprietary** | The tilemap system uses its own data format for tile definitions. There's no built-in Tiled (.tmx) or LDtk import — games must convert externally or build custom loaders. |
| 30 | **No asset packaging format** | Unlike Love2D's `.love` files (zip archives), there's no single-file game archive format. Games are distributed as a directory alongside the executable. |

## Architecture Deep Dive

### Graphics Pipeline

The GPU rendering pipeline uses two wgpu render pipelines:

1. **Color Pipeline** — Flat-colored geometry (rectangles, circles, triangles, polygons, lines)
   - Vertex format: `ColorVertex { x, y, r, g, b, a }` (24 bytes)
   - Buffer: 131,072 vertices / 524,288 indices

2. **Texture Pipeline** — Textured quads (images, sprites, fonts, canvases)
   - Vertex format: `TexVertex { x, y, u, v, r, g, b, a }` (32 bytes)
   - Buffer: 16,384 vertices / 65,536 indices

Draw commands are processed sequentially from the queue. A pipeline/texture switch triggers a flush of the current batch. Render statistics (draw_calls, texture_switches, batched_draws) are tracked per frame.

### Resource Lifecycle

```
newImage() → load PNG → upload to wgpu::Texture → store in SlotMap → return TextureKey
                                                                    ↓
                                                          Lua holds UserData wrapping key
                                                          Engine accesses via SlotMap lookup
                                                          Removal: SlotMap.remove(key)
                                                          wgpu::Texture dropped when last ref gone
```

Resources are stored in typed SlotMaps inside SharedState:
- `textures: SlotMap<TextureKey, Texture>`
- `fonts: SlotMap<FontKey, Font>`
- `sprites: SlotMap<SpriteKey, Sprite>`
- `canvases: SlotMap<CanvasKey, Canvas>`
- `meshes: SlotMap<MeshKey, Mesh>`
- `shaders: SlotMap<ShaderKey, Shader>`
- `sprite_batches: SlotMap<SpriteBatchKey, SpriteBatch>`

### Error Handling Model

```
Lua error → mlua::Error → EngineError::LuaError(msg, traceback)
                        → RunState::Error(ErrorScreen)
                        → Display blue error screen with message + hint
                        → User presses Escape → RunState::Restarting
```

12 error variants:
- Init: `InitializationError`, `WindowError`, `ConfigError`
- Runtime: `RenderError`, `InputError`, `AudioError`, `PhysicsError`
- Resource: `ResourceNotFound`, `ResourceNotLoaded`
- Script: `LuaError`
- System: `FileSystemError`, `IoError`

### Physics Integration

rapier2d is wrapped behind a custom `World` struct:
- `World.new_body()` → creates a rapier RigidBody + Collider pair
- `World.step(dt)` → advances the simulation, collects contacts
- Body types: Dynamic, Static, KinematicPositionBased, KinematicVelocityBased
- Shapes: Circle, Rectangle, Polygon, Edge, Chain
- Queries: Raycast with hit point, normal, time-of-impact

### AI Subsystem

15 files implementing game AI primitives:
- **FSM**: State transitions with enter/exit/update callbacks
- **Behavior Tree**: Sequence, Selector, Parallel nodes with status tracking
- **Steering**: 8 behaviors — seek, flee, arrive, wander, pursuit, evasion, obstacle avoidance, flocking
- **GOAP**: Goal-Oriented Action Planning with preconditions and effects
- **Q-Learning**: Discrete state-action reinforcement learning
- **Pathfinding**: A*, Dijkstra, BFS on 2D grids + flow fields
- **Influence Maps**: 2D heat maps for strategic AI decisions
- **Squad Formations**: Group movement with formation positions

## Dependency Graph

```
                    ┌──────────┐
                    │  main.rs │
                    └────┬─────┘
                         │
                    ┌────▼─────┐
                    │  engine  │ ← depends on ALL modules
                    └────┬─────┘
                         │
                 ┌───────▼────────┐
                 │    lua_api      │ ← depends on engine + ALL domain modules
                 └───────┬────────┘
                         │
    ┌────────┬───────────┼──────────┬─────────┬────────┐
    │        │           │          │         │        │
┌───▼──┐ ┌──▼──┐ ┌──────▼──┐ ┌────▼──┐ ┌───▼──┐ ┌──▼──┐
│graph.│ │audio│ │physics  │ │input  │ │timer │ │filsys│
│      │ │     │ │         │ │       │ │      │ │      │
└──────┘ └─────┘ └─────────┘ └───────┘ └──────┘ └──────┘
    ↑        ↑        ↑          ↑         ↑        ↑
    └────────┴────────┴──────────┴─────────┴────────┘
                    │ (may depend on) │
                ┌───▼──────────────▼──┐
                │       math          │ ← foundational, no deps
                └─────────────────────┘
```

## Technology Stack

| Layer | Technology | Version | Role |
|-------|-----------|---------|------|
| Rendering | wgpu | 22 | GPU abstraction (DX12/Vulkan/Metal/WebGPU) |
| Windowing | winit | 0.30 | Window creation, input events, event loop |
| Scripting | mlua | 0.9 | LuaJIT binding (Lua 5.4 fallback) |
| Physics | rapier2d | 0.32 | 2D rigid body simulation |
| Audio | rodio | 0.17 | Audio playback and decoding |
| Gamepads | gilrs | 0.11 | Cross-platform gamepad support |
| Fonts | fontdue | 0.9 | TTF/OTF rasterization |
| Images | image | 0.24 | PNG/JPEG/BMP loading |
| Resources | slotmap | 1 | Generational arena for handles |
| Errors | thiserror | 1 | Error derive macros |
| Serialization | serde + serde_json | — | Config, save data |
| Compression | flate2, lz4_flex | — | deflate, gzip, lz4 |
| Hashing | sha2, md-5 | — | MD5, SHA-256, SHA-512 |
| RNG | fastrand | 2 | Seeded pseudo-random numbers |
| MIDI | midly | 0.5 | MIDI file parsing |
| Directories | directories | 5 | Cross-platform save paths |
| System info | sysinfo | — | OS/CPU/RAM queries |
| Build (Windows) | winresource | 0.1 | Embed .ico and version info |

## Comparison Notes

### vs. Love2D
Luna2D aligns closely with Love2D's API philosophy but provides Rust's safety guarantees, GPU-first rendering via wgpu (vs. Love2D's GL/Vk/Metal multi-backend), and built-in systems (AI, particles, tilemaps) that Love2D delegates to community libraries. Luna2D lacks Love2D's 16-year ecosystem, overridable game loop, and cross-platform maturity (especially mobile).

### vs. ggez
Both are Rust 2D engines using wgpu, but Luna2D adds Lua scripting on top — games are written in Lua, not Rust. Luna2D has a dramatically larger API surface (26 modules vs. ggez's ~8) but lacks ggez's Rust-side type safety for game logic. ggez is a library; Luna2D is a runtime.

### vs. macroquad
macroquad uses `unsafe` global state for simplicity; Luna2D uses `Rc<RefCell<>>` for safety. macroquad has better WASM support today. Luna2D's Lua scripting layer adds runtime overhead but enables non-Rust game development. macroquad is minimal by design; Luna2D is batteries-included.

### vs. Solar2D
Both target Lua game developers, but Solar2D uses a scene graph / display tree model while Luna2D uses Love2D-style immediate draws. Solar2D has superior mobile support and 10+ years of production use. Luna2D has modern rendering (wgpu vs. Solar2D's GL/Vk/Metal) and Rust's safety story.

### vs. Gideros
Gideros provides an OOP scene graph with sprite hierarchy, while Luna2D is procedural. Gideros has a built-in IDE; Luna2D integrates with VS Code via an MCP extension. Both target Lua developers, but Luna2D's architecture is fundamentally different (immediate-mode rendering vs. retained scene graph).

### vs. Luna2D Original (C++)
The original Luna2D was a mobile-first engine with GLES 2.0 rendering. The Rust rewrite shifts to desktop-first with wgpu GPU rendering, adds 22 core modules (vs. the original's ~8), replaces manual C++ memory management with Rust ownership, and introduces rapier2d physics (the original had none).
