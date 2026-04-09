# Lurek2D — Engine Architecture

> **Source of truth** for the runtime module structure, rendering pipeline, and internal subsystem design.
> Companion documents: [philosophy.md](philosophy.md) (principles + design assumptions) · [test-framework.md](test-framework.md) (test architecture).

---

## Table of Contents

1. [Overview](#overview)
2. [Project Identity](#project-identity)
3. [Active Layer Model](#active-layer-model)
4. [Module Dependency Graph](#module-dependency-graph)
5. [Baseline Layer](#baseline-layer)
6. [Bridge Layer — lua_api](#bridge-layer--lua_api)
7. [Tier 1 — Core Engine Subsystems](#tier-1--core-engine-subsystems)
8. [Tier 2 — Reusable Engine Extensions](#tier-2--reusable-engine-extensions)
9. [Tier 3 — Lunasome (content/library/)](#tier-3--lunasome-library)
10. [Boot Sequence](#boot-sequence)
11. [Game Loop and Frame Model](#game-loop-and-frame-model)
12. [State Architecture](#state-architecture)
13. [Resource Management](#resource-management)
14. [Rendering Pipeline](#rendering-pipeline)
15. [Lua Binding Architecture](#lua-binding-architecture)
16. [Input Pipeline](#input-pipeline)
17. [Audio Pipeline](#audio-pipeline)
18. [Physics Pipeline](#physics-pipeline)
19. [Particle System](#particle-system)
20. [Data and Image Modules](#data-and-image-modules)
21. [Filesystem and Virtual FS](#filesystem-and-virtual-fs)
22. [Window Management](#window-management)
23. [Threading Model](#threading-model)
24. [Error Handling and Recovery](#error-handling-and-recovery)
25. [Configuration System](#configuration-system)
26. [Callback Contract](#callback-contract)
27. [DrawCommand Queue Reference](#drawcommand-queue-reference)
28. [Dependencies](#dependencies)
29. [File Structure](#file-structure)
30. [Legacy and Migration-State Modules](#legacy-and-migration-state-modules)
31. [Planned Build Variants](#planned-build-variants)

---

## Overview

Lurek2D is a 2D game engine written in **Rust** that loads and executes **Lua** game scripts. It is an **AI-first** project — every API, every module, and every document is designed so that both humans and AI agents can use the engine effectively.

The engine provides a complete `lurek.*` Lua API for graphics, audio, input, physics, windowing, filesystems, math, data processing, particles, multi-threading, scenes, tilemaps, pathfinding, and more. Games consist of a `main.lua` (and optionally `conf.lua`) loaded at startup from a game directory.

**Runtime stack**: winit 0.30 (event loop + windowing) → wgpu 22 (GPU rendering via Vulkan/DX12/Metal) → mlua 0.9 (Lua scripting, vendored) → rapier2d 0.32 (physics) → rodio 0.17 (audio).

**Binary size target**: ~20 MB. One executable, no DLL dependencies, no installer required.

---

## Project Identity

Lurek2D is a rebellion against bloated game engines. The project symbol tells the story:

- **🌙 Moon (Luna/Lua)** — The scripting language is the heart. Lua means "moon" in Portuguese. The crescent moon in the logo represents the lightweight, elegant scripting layer that game creators interact with.
- **⚙️ Gear (Rust)** — "Rdza" means "rust" in Polish. The gear symbolizes the Rust engine core — industrial-strength, memory-safe, zero-cost abstractions powering the runtime beneath the Lua surface.
- **🟡 Pacman (Game Engine)** — The gear is shaped like a Pacman, representing the game engine that *consumes* game scripts and produces interactive experiences. It eats `main.lua` and runs your game.
- **🤖 AI (Holistic Integration)** — Lurek2D is an AI-first project. Every API is designed so a Copilot agent can use it correctly without a clarifying question. The VS Code extension, CAG layer, and documentation pipeline all serve AI-assisted development.
- **🧊 Cube (The Goliath)** — The small cube orbiting the gear represents the industry giants — Engine G, Engine H, Engine C. Lurek2D is David: a 20 MB engine that, powered by AI, can compete with multi-gigabyte engines. The cube orbits Lurek2D, not the other way around.

**The thesis**: A single-binary game engine weighing 20 MB, powered by Lua scripting and Rust performance, augmented by AI at every layer, can deliver features that rival engines 100× its size. This is the fight: small, sharp, AI-augmented vs. large, sprawling, manual.

---

## Active Layer Model

Lurek2D uses an **active four-layer runtime model** plus one bridge layer. This is a **logical dependency model**, not a filesystem grouping scheme. Most Rust engine modules live in flat `src/<module>/` directories. The layer contract is carried by import direction, not by nested folders.

| Layer | Path | Role |
|---|---|---|
| **Baseline** | `src/math/`, `src/engine/` | Always-on runtime substrate — foundational algorithms and lifecycle |
| **Tier 1** | `src/<module>/` | Core engine subsystems built directly on Baseline |
| **Tier 2** | `src/<module>/` | Reusable engine extensions built on Baseline + Tier 1 |
| **Bridge** | `src/lua_api/` | Registers the public `lurek.*` API; not a numbered tier |
| **Tier 3** | `content/library/` | **Lunasome**: pure-Lua gameplay libraries consuming the public API |

### Boundary Rules

- **Baseline** (`math`, `engine`) is always available to all layers.
- **Tier 1** modules may depend **only** on Baseline. No Tier 1 ↔ Tier 1 cross-imports.
- **Tier 2** modules may depend on Baseline + Tier 1. No Tier 2 ↔ Tier 2 cross-imports.
- **`lua_api`** (bridge) imports engine layers and exposes `lurek.*`. Domain Rust modules must **never** import it.
- **Tier 3 Lunasome** lives in `content/library/` and consumes only public Lua-facing APIs. Lower engine layers do not depend on Tier 3.
- **Examples** consume the public Lua surface but are not part of the numbered layer model.

---

## Module Dependency Graph

```
game scripts and content/examples/
            │
            ▼
content/library/  (Tier 3: Lunasome, pure Lua)
            │ consumes public lurek.* API
            ▼
      src/lua_api/  (bridge layer)
            │ binds runtime to Lua
            ▼
      Tier 2 extensions (particle, tilemap, scene, ai, pathfinding, ...)
            │ may import Tier 1
            ▼
   Tier 1 core subsystems (graphics, audio, physics, input, timer, ...)
            │ may import only Baseline
            ▼
Baseline: src/math/ (leaf, no deps) + src/engine/ (lifecycle, SharedState)
```

### Import Rules Summary

| Source Module | May Import |
|---|---|
| `math` | Nothing (leaf module) |
| `engine` | `math` |
| Tier 1 modules | `math`, `engine` only |
| Tier 2 modules | `math`, `engine`, any Tier 1 module |
| `lua_api` (bridge) | Everything above |
| `content/library/` (Tier 3) | Public `lurek.*` API only |
| Domain modules | **Never** `lua_api` |

**No circular dependencies** — the graph is always a DAG.

---

## Baseline Layer

### `math/` — Foundational Algorithms

`math` is the leaf of the dependency graph. It has zero internal Lurek2D dependencies and provides:

- **Vectors**: `Vec2`, `Vec3`
- **Matrices**: `Mat3` (affine transforms)
- **Geometry**: `Rect` (AABB)
- **Color**: `Color` (sRGB `[f32; 4]`) — a pure math value type with no rendering dependency
- **Noise**: Perlin, simplex, fractal Brownian motion
- **Easing**: 22 easing functions for animation and tweening
- **Interpolation**: linear, bezier, and catmull-rom
- **Random**: `RandomGenerator` (fastrand wrapper, Box-Muller normal distribution)
- **Transform**: `Transform` — `Mat3` UserData wrapper for Lua
- **Bezier**: `BezierCurve` — De Casteljau evaluation, rendering, derivatives
- **Triangulation**: Ear-clipping polygon triangulation
- **Color Space**: sRGB ↔ linear conversion

All other layers may freely import `math`.

### `engine/` — Runtime Lifecycle

`engine` provides the application skeleton and is the top-level Rust orchestrator:

| File | Responsibility |
|---|---|
| `app.rs` | `App` struct, `RunState` machine, game loop, error mode loop |
| `config.rs` | `Config`, `WindowConfig`, `ModulesConfig`, `PerformanceConfig` |
| `error.rs` | `EngineError` (12+ variants), `EngineResult<T>` |
| `error_screen.rs` | `ErrorScreen` — blue error display with built-in font |
| `debug_overlay.rs` | Debug HUD (FPS, draw calls, memory) |
| `resource_keys.rs` | All SlotMap key type definitions |

`SharedState` is defined here as the central runtime state shared with Lua closures via `Rc<RefCell<SharedState>>`.

---

## Bridge Layer — lua_api

`lua_api` sits above the engine layers. It imports runtime modules and exposes them through the `lurek.*` namespace.

- It is **not** a numbered tier.
- It may import Baseline, Tier 1, Tier 2, and migration-state gameplay Rust modules.
- Domain Rust modules must **never** import `lua_api`.

Every binding module follows the registration pattern:

```rust
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>
```

### API Namespaces

| Namespace | API File | Scope |
|---|---|---|
| `lurek.gfx` | `graphics_api.rs` | Drawing, images, fonts, canvases, meshes, shaders, sprite batches |
| `lurek.audio` | `audio_api.rs` | Sound loading, playback, volume, pitch, panning, buses |
| `lurek.keyboard` | `input_api.rs` | Key state, scancodes, text input |
| `lurek.mouse` | `input_api.rs` | Position, buttons, cursor, scroll, grab |
| `lurek.gamepad` | `input_api.rs` | Joystick state, buttons, axes, vibration |
| `lurek.touch` | `input_api.rs` | Touch points, pressure |
| `lurek.time` | `timer_api.rs` | Delta time, FPS, sleep |
| `lurek.math` | `math_api.rs` | Trig, random, noise, transforms, Bezier, triangulation |
| `lurek.physics` | `physics_api.rs` | Worlds, bodies, shapes, joints, raycasting |
| `lurek.fs` | `filesystem_api.rs` | Sandboxed I/O, directories, archive mounting |
| `lurek.window` | `window_api.rs` | Fullscreen, VSync, display info, DPI, clipboard |
| `lurek.signal` | `event_api.rs` | Event queue, quit, push/poll/clear |
| `lurek.platform` | `system_api.rs` | OS info, processor count, openURL, locales |
| `lurek.particles` | `particle_api.rs` | Particle emitters, configuration, rendering |
| `lurek.data` | `data_api.rs` | Binary data, compression, hashing, encoding |
| `lurek.img` | `image_api.rs` | CPU pixel buffers, pixel manipulation |
| `lurek.thread` | `thread_api.rs` | Worker threads, channels |
| `lurek.tween` | `animation_api.rs` | Frame-based sprite animation, named clips, speed control |
| `lurek.camera` | `camera_api.rs` | Camera2D, viewport transforms |
| `lurek.simulator` | `automation_api.rs` | Automated input simulation and replay |
| `lurek.entity` | `entity_api.rs` | Lightweight ECS primitives |
| `lurek.scene` | `scene_api.rs` | Scene stack management and transitions |
| `lurek.gpu` | `compute_api.rs` | Dense numerical arrays, CPU-side compute |
| `lurek.savegame` | `savegame_api.rs` | Slot-based save/load, schema versioning |
| `lurek.codec` | `serial_api.rs` | JSON, TOML, MessagePack serialization |
| `lurek.dataframe` | `dataframe_api.rs` | Column-major tabular data structures |
| `lurek.light` | `light_api.rs` | 2D dynamic lighting and shadow casting |
| `lurek.modding` | `modding_api.rs` | Mod discovery, dependency resolution, load ordering |
| `lurek.raycaster` | `raycaster_api.rs` | DDA grid raycasting for retro rendering |
| `lurek.spine` | `spine_api.rs` | Spine 2D skeletal animation runtime |
| `lurek.procgen` | `procgen_api.rs` | Procedural content generation algorithms |
| `lurek.network` | `network_api.rs` | UDP networking, packet framing |
| `lurek.minimap` | `minimap_api.rs` | Grid-based minimap extraction and FOV masking |
| `lurek.pathfinding` | `pathfinding_api.rs` | Navigation grids, A★, HPA★, flow fields |
| `lurek.terminal` | `terminal_api.rs` | In-game developer terminal / REPL |
| `lurek.pipeline` | `pipeline_api.rs` | DAG pipeline orchestration and caching |
| `lurek.patterns` | `patterns_api.rs` | Game programming design patterns toolkit |
| `lurek.graph` | `graph_api.rs` | Directed graphs, flow simulation |
| `lurek.ai` | `ai_api.rs` | FSMs, behaviour trees, GOAP, steering |
| `lurek.postfx` | `fx_api.rs` | Post-processing effects, screen overlays |
| `lurek.ui` | `gui_api.rs` | Retained-mode widget UI |
| `lurek.tilemap` | `tilemap_api.rs` | Tilemaps, tilesets, coordinate helpers |
| `lurek.devtools` | `devtools_api.rs` | Developer diagnostics and runtime profiling |
| `lurek.debugbridge` | `debugbridge_api.rs` | JSON-over-TCP debug server for remote inspection |
| `lurek.localization` | `localization_api.rs` | Multi-locale string catalogs with plural rules |
| `lurek.log` | `log_api.rs` | Structured game-script logging |
| `lurek.docs` | `docs_api.rs` | API documentation reference management |

---

## Tier 1 — Core Engine Subsystems

Tier 1 modules are engine-owned capabilities that sit directly on Baseline. **Import rule**: may only import `crate::math::*` and `crate::engine::*`.

| Module | Path | Responsibility |
|---|---|---|
| `animation` | `src/animation/` | Sprite animation: named clips, frame pools, speed control, frame-level events |
| `audio` | `src/audio/` | Audio playback via rodio: mixer, buses, static/stream sources, volume, pitch, pan |
| `camera` | `src/camera/` | Camera, Camera2D, Viewport, ViewportScale types |
| `compute` | `src/compute/` | Dense numerical arrays (NdArray) and CPU-side compute helpers |
| `data` | `src/data/` | Binary data (ByteData), compression, hashing, encoding |
| `debugbridge` | `src/debugbridge/` | JSON-over-TCP debug server for VS Code extension and MCP remote inspection |
| `devtools` | `src/devtools/` | Engine and game diagnostics: structured runtime monitoring and performance analysis |
| `docs` | `src/docs/` | API documentation catalog powering IntelliSense, MCP tools, and doc generators |
| `entity` | `src/entity/` | Lightweight ECS primitives and entity helpers |
| `event` | `src/event/` | Event queue and polling primitives |
| `filesystem` | `src/filesystem/` | Sandboxed game filesystem (GameFS), VirtualFS, archive mounting |
| `graphics` | `src/graphics/` | GPU rendering pipeline, draw commands, textures, fonts, batching, shaders |
| `image` | `src/image/` | CPU-side image manipulation (ImageData) |
| `input` | `src/input/` | Keyboard, mouse, gamepad, and touch state management |
| `localization` | `src/localization/` | Multi-locale string catalog with variable substitution and plural form selection |
| `log` | `src/log/` | Structured Lua-script logging at configurable severity levels |
| `patterns` | `src/patterns/` | Pure-Rust game-programming design patterns (FSM, observer, service locator, etc.) |
| `physics` | `src/physics/` | Rigid bodies, shapes, collisions, joints, raycasting via rapier2d |
| `thread` | `src/thread/` | Background Rust threads and Channel communication |
| `timer` | `src/timer/` | Frame timing (Clock), FPS tracking, scheduled callbacks |
| `window` | `src/window/` | Window lifecycle and state abstraction |

---

## Tier 2 — Reusable Engine Extensions

Tier 2 modules build on Baseline + Tier 1 and remain broadly useful across many game types. **Import rule**: may import Baseline and any Tier 1 module, but must **not** import other Tier 2 modules.

| Module | Path | Responsibility |
|---|---|---|
| `ai` | `src/ai/` | Generic AI: FSMs, behaviour trees, GOAP, steering behaviours |
| `automation` | `src/automation/` | Automated input simulation and replay scripts (debug-gated) |
| `dataframe` | `src/dataframe/` | Column-major tabular data structures |
| `fx` | `src/fx/` | Composable post-processing visual effects pipeline |
| `graph` | `src/graph/` | Directed graphs, flow simulation, graph algorithms |
| `gui` | `src/gui/` | Retained-mode widget UI primitives |
| `light` | `src/light/` | CPU-side 2D dynamic lighting data model (point, spot, directional) |
| `minimap` | `src/minimap/` | Minimap extraction, FOV masking, tile sampling |
| `modding` | `src/modding/` | Mod discovery, dependency resolution, load ordering |
| `network` | `src/network/` | UDP networking via ENet: peer-to-peer and client-server multiplayer |
| `particle` | `src/particle/` | Emitter-based 2D particle systems |
| `pathfinding` | `src/pathfinding/` | Navigation grids, A★, HPA★, flow fields |
| `pipeline` | `src/pipeline/` | DAG-based data pipeline orchestration and caching |
| `procgen` | `src/procgen/` | Procedural content generation: dungeons, terrain, noise, L-systems |
| `raycaster` | `src/raycaster/` | DDA grid raycasting for Wolfenstein-style retro rendering |
| `savegame` | `src/savegame/` | Save/load orchestration and schema versioning |
| `scene` | `src/scene/` | Scene stack management and transitions |
| `serial` | `src/serial/` | Format-agnostic serialization: JSON, TOML, MessagePack |
| `spine` | `src/spine/` | Spine 2D skeletal animation: bone hierarchies, slots, world transforms |
| `terminal` | `src/terminal/` | In-game developer terminal / REPL with widget toolkit |
| `tilemap` | `src/tilemap/` | Tilemaps, tilesets, map generation, coordinate helpers |

---

## Tier 3 — Lunasome (content/library/)

Tier 3 is **Lunasome**: the pure-Lua standard library shipped alongside the engine. It is **not** embedded in the Rust binary. It lives under `content/library/` and consumes only the public `lurek.*` API.

Lunasome is the target home for genre-specific and gameplay-domain-specific libraries. When functionality can live as pure Lua on top of the engine API, it belongs here.

| Library | Path | Responsibility |
|---|---|---|
| `battle` | `content/library/battle/` | Turn-based battle helpers |
| `cardgame` | `content/library/cardgame/` | Cards, decks, slots, and card pools |
| `combat` | `content/library/combat/` | Combat-oriented gameplay helpers |
| `crafting` | `content/library/crafting/` | Recipes, queues, and crafting logic |
| `dialog` | `content/library/dialog/` | Dialogue sequencing and branching |
| `doll` | `content/library/doll/` | Paper-doll character compositing |
| `economy` | `content/library/economy/` | Gameplay resource economy helpers |
| `inventory` | `content/library/inventory/` | Inventory logic and container management |
| `item` | `content/library/item/` | Item definitions and stack logic |
| `province_map` | `content/library/province_map/` | Province-map gameplay helpers |
| `quest` | `content/library/quest/` | Quest log and objective tracking |
| `stats` | `content/library/stats/` | Gameplay stat and modifier systems |

---

## Boot Sequence

```
main.rs
  │
  ├── Parse CLI arguments (game directory path)
  │
  ├── Config::load_from_conf_lua(game_dir)
  │     └── Temporary Lua VM → execute conf.lua → call lurek.conf(t) → read back → Config struct
  │
  ├── App::new(config)
  │     ├── Create winit Window (title, size, min size, decorations, icon, display index)
  │     ├── Create GpuRenderer (wgpu Instance → Adapter → Device → Surface → pipeline cache)
  │     ├── Create Clock (frame timing)
  │     ├── Create Mixer (rodio OutputStream — headless fallback if no audio device)
  │     ├── Create GameFS (sandboxed to game directory + user save directory)
  │     ├── Create VirtualFS (mount points: game dir, save dir, archives)
  │     └── Create SharedState (Rc<RefCell<SharedState>>)
  │
  ├── create_lua_vm()
  │     ├── Create mlua::Lua VM (StdLib subset — no os, io, loadfile, dofile)
  │     ├── Create `luna` global table
  │     ├── Register 40+ API modules (graphics, input, audio, timer, math, physics,
  │     │                             filesystem, window, event, system, particle,
  │     │                             data, image, thread, terminal, ai, animation,
  │     │                             camera, compute, scene, tilemap, gui, ...)
  │     └── Each module: register(lua, luna_table, Rc<RefCell<SharedState>>)
  │
  ├── Load game_dir/main.lua (or display splash screen if no game directory)
  │
  ├── Call lurek.load()
  │
  └── Enter RunState::Running → game loop
```

If any step fails, the engine transitions to `RunState::Error(ErrorScreen)`.

### No-Game Behaviour

When no game directory is provided, the engine displays a built-in splash screen — the Lurek2D logo and project identity rendered through the same DrawCommand system. The splash screen runs at 60 FPS until the user closes the window. **Drag-and-drop** is supported: drop a game folder onto the splash window to load it immediately.

---

## Game Loop and Frame Model

The game loop runs inside `App::run()` using winit's `ApplicationHandler` trait. Each frame follows a strict phase sequence:

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRAME START                              │
├─────────────────────────────────────────────────────────────────┤
│ 1. Clock::tick()               → compute dt, update FPS        │
│ 2. Poll input events           → update KeyboardState,         │
│                                   MouseState, GamepadState,     │
│                                   TouchState                    │
│ 3. Fire input callbacks        → keypressed, keyreleased,      │
│                                   textinput, mousepressed,      │
│                                   mousereleased, mousemoved,    │
│                                   wheelmoved, gamepadpressed,   │
│                                   gamepadreleased, gamepadaxis, │
│                                   touchpressed, touchmoved,     │
│                                   touchreleased                 │
│ 4. Fire window callbacks       → focus, visible, resize         │
│ 5. Fire gamepad hotplug        → joystickadded, joystickremoved │
│ 6a. Call lurek.process_physics(fixed_dt) [0–N fixed steps]       │
│ 6b. Call lurek.process(dt)      → game logic                     │
│ 6c. Call lurek.process_late(dt) → post-logic update              │
│ 7.  Clear draw command queue                                    │
│ 8a. Call lurek.render()         → game pushes DrawCommands       │
│ 8b. Call lurek.render_ui()      → UI/HUD overlay DrawCommands    │
│ 9. GpuRenderer::render_frame()                                 │
│    ├── Flush pending resource removals (deferred destruction)   │
│    ├── Update auto-uniforms (time, screen size)                 │
│    ├── Acquire swapchain texture                                │
│    ├── Process DrawCommand queue → wgpu render passes           │
│    └── Present surface                                          │
│10. Reset per-frame state       → scroll deltas, pressed/        │
│                                   released arrays, events       │
├─────────────────────────────────────────────────────────────────┤
│                         FRAME END                               │
└─────────────────────────────────────────────────────────────────┘
```

### RunState Machine

```
        ┌──────────┐
        │ Running  │ ◄── normal gameplay
        └────┬─────┘
             │ uncaught error / panic
             ▼
        ┌──────────────────┐
        │ Error(ErrorScreen)│ ◄── blue error screen
        └────┬────────┬────┘
             │        │
     [Escape]│        │[R key]
             ▼        ▼
        ┌────────┐ ┌────────────┐
        │Quitting│ │ Restarting │ → re-run game_dir/main.lua → Running
        └────────┘ └────────────┘
```

- **Running**: Normal game loop — update, draw, present.
- **Error(ErrorScreen)**: Renders a blue error screen with the error message using a built-in font. Escape quits, R restarts.
- **Quitting**: Clean shutdown — resource release, audio stop, window close.
- **Restarting**: Tear down Lua VM, re-create SharedState, reload main.lua.

---

## State Architecture

### SharedState

All mutable engine state lives in a single `SharedState` struct, shared between Lua closures and the engine loop via `Rc<RefCell<SharedState>>`.

```rust
pub struct SharedState {
    // ── Resource Pools (SlotMap) ──────────────────────
    pub textures:         SlotMap<TextureKey, TextureData>,
    pub fonts:            SlotMap<FontKey, Font>,
    pub canvases:         SlotMap<CanvasKey, Canvas>,
    pub sprite_batches:   SlotMap<SpriteBatchKey, SpriteBatch>,
    pub meshes:           SlotMap<MeshKey, Mesh>,
    pub shaders:          SlotMap<ShaderKey, Shader>,
    pub particle_systems: SlotMap<ParticleKey, ParticleSystem>,

    // ── Rendering State ──────────────────────────────
    pub draw_commands:      Vec<DrawCommand>,
    pub current_color:      Color,
    pub background_color:   Color,
    pub current_font:       Option<FontKey>,
    pub current_canvas:     Option<CanvasKey>,
    pub current_shader:     Option<ShaderKey>,
    pub camera:             Camera,
    pub scissor:            Option<Rect>,
    pub color_mask:         (bool, bool, bool, bool),
    pub wireframe:          bool,
    pub point_size:         f32,
    pub default_filter:     FilterMode,

    // ── Input State ──────────────────────────────────
    pub keyboard:   KeyboardState,
    pub mouse:      MouseState,
    pub gamepads:   Vec<GamepadState>,
    pub touch:      TouchState,

    // ── Subsystems ───────────────────────────────────
    pub mixer:        Mixer,
    pub clock:        Clock,
    pub game_fs:      GameFS,
    pub virtual_fs:   VirtualFS,
    pub window_state: WindowState,
    pub event_queue:  Vec<EventKind>,
}
```

**Why `Rc<RefCell<>>`**: Lua closures require `'static` lifetimes. `Rc<RefCell<>>` provides shared ownership with runtime borrow checking, eliminating the need for `unsafe`.

**Why not `Arc<Mutex<>>`**: The main game loop is single-threaded. `Rc<RefCell<>>` has zero synchronization overhead. The threading module uses separate Lua VMs per thread — they do not share SharedState.

---

## Resource Management

### Generational IDs via SlotMap

All engine resources are stored in typed `SlotMap<K, V>` pools:

- **O(1) insert, remove, lookup** with generation checking
- **Use-after-free prevention**: stale keys return `None`, never access wrong data
- **Dense iteration**: cache-friendly for per-frame operations
- **No hash overhead**: keys are plain integers + generation counter

### Typed Resource Keys

Defined in `src/engine/resource_keys.rs`:

```rust
new_key_type! {
    pub struct TextureKey;
    pub struct FontKey;
    pub struct CanvasKey;
    pub struct SoundKey;
    pub struct ParticleKey;
    pub struct SpriteBatchKey;
    pub struct MeshKey;
    pub struct ShaderKey;
    pub struct PhysicsWorldKey;
    pub struct PhysicsBodyKey;
}
```

Compile-time type safety: a `TextureKey` cannot be passed where a `FontKey` is expected.

### Resource Lifecycle

```
Lua: local img = lurek.gfx.newImage("player.png")
  │
  ▼
Rust: load pixels → insert into textures SlotMap → upload to GPU
      → return LuaImage(TextureKey) as UserData to Lua
  │
  ▼
Lua: lurek.gfx.draw(img, 100, 200)
  │
  ▼
Rust: push DrawImage { texture_key, ... } into draw_commands
  │
  ▼
Lua: img:release()    OR    garbage collection
  │
  ▼
Rust: remove from SlotMap → queue GPU resource for deferred destruction
```

### Deferred GPU Destruction

GPU resources cannot be freed during an active render pass. When `release()` is called, the key is added to a pending removal queue. At the start of the next frame, `GpuRenderer::flush_pending_removals()` processes the queue.

---

## Rendering Pipeline

### GPU Renderer (wgpu)

The primary renderer uses wgpu to submit draw commands to the system GPU (Vulkan, DX12, Metal).

```
GpuRenderer
├── wgpu::Instance
├── wgpu::Adapter
├── wgpu::Device + Queue
├── wgpu::Surface (swapchain)
├── Pipeline Cache
│   ├── Color pipelines       (5 blend modes × 2 wireframe states)
│   ├── Texture pipelines     (5 blend modes × 2 wireframe states)
│   ├── Stencil pipelines     (write mode, test mode)
│   ├── Color mask variants   (lazily created, cached)
│   └── Custom shader pipelines (per Shader object)
├── Depth/Stencil Texture     (Depth24PlusStencil8, window-sized)
├── gpu_textures              SlotMap<TextureKey, GpuTexture>
├── canvas_gpu_textures       SlotMap<CanvasKey, GpuTexture>
├── font_atlas_textures       SlotMap<FontKey, GpuTexture>
└── Vertex Buffer (dynamic)
```

### Embedded Shaders (WGSL)

Two WGSL shaders are embedded in the binary:

- **COLOR_SHADER** — Solid-color geometry (position + color per vertex)
- **TEXTURE_SHADER** — Textured sprites (position + UV + color tint)

### Custom Shaders

Users can provide custom fragment shaders (or vertex + fragment pairs) in WGSL:

1. Engine prepends a standard header with auto-updated globals (`luna_ScreenSize`, `luna_Time`)
2. Validates the source with naga (bundled in wgpu)
3. Creates a dedicated `wgpu::RenderPipeline`
4. Manages a uniform buffer and bind group per shader

### Blend Modes

Five blend modes, each with a pre-built pipeline:

| Mode | Operation |
|---|---|
| `alpha` | Standard alpha blending (default) |
| `add` | Additive blending (particles, glow) |
| `multiply` | Multiplicative blending (shadows) |
| `replace` | No blending (overwrite) |
| `screen` | Screen blending (lightening) |

### Canvas (Render-to-Texture)

```
SetCanvas(Some(canvas_key))  → end screen pass, begin canvas pass
     ↓ (subsequent draws render to canvas)
SetCanvas(None)              → end canvas pass, resume screen pass
     ↓
DrawImage(canvas_key, ...)   → draw canvas as a textured quad on screen
```

### Transform Stack

Affine transforms managed via a push/pop stack. Each entry stores translation, rotation, scale, shear, and scissor state.

---

## Lua Binding Architecture

### UserData Object Model

All major resource types are exposed to Lua as `mlua::UserData` objects, providing an object-oriented API:

```lua
local img = lurek.gfx.newImage("player.png")
img:getWidth()
img:getHeight()
img:release()

local source = lurek.audio.newSource("music.ogg", "stream")
source:play()
source:setVolume(0.8)
source:setLooping(true)
```

### UserData Types

| Lua Type | Rust Struct | Key Type | Module |
|---|---|---|---|
| Image | `LuaImage` | `TextureKey` | graphics |
| Font | `LuaFont` | `FontKey` | graphics |
| Canvas | `LuaCanvas` | `CanvasKey` | graphics |
| SpriteBatch | `LuaSpriteBatch` | `SpriteBatchKey` | graphics |
| Mesh | `LuaMesh` | `MeshKey` | graphics |
| Shader | `LuaShader` | `ShaderKey` | graphics |
| Quad | `LuaQuad` | — (value type) | graphics |
| Source | `LuaSource` | `SoundKey` | audio |
| World | `LuaWorld` | `PhysicsWorldKey` | physics |
| Body | `LuaBody` | `PhysicsBodyKey` | physics |
| ParticleSystem | `LuaParticleSystem` | `ParticleKey` | particle |
| RandomGenerator | `LuaRandomGenerator` | — (owned) | math |
| Transform | `LuaTransform` | — (owned) | math |
| BezierCurve | `LuaBezierCurve` | — (owned) | math |
| ByteData | `LuaByteData` | — (owned) | data |
| ImageData | `LuaImageData` | — (owned) | image |
| SoundData | `LuaSoundData` | — (owned) | audio |
| FileHandle | `LuaFileHandle` | — (owned) | filesystem |
| Channel | `LuaChannel` | — (shared) | thread |

### LunaType Trait

All UserData types implement a shared `LunaType` trait:

```rust
pub trait LunaType {
    fn type_name() -> &'static str;
}
```

This provides `type()`, `typeOf()`, and `__tostring` metamethods automatically.

### Drawable Protocol

Types that implement the Drawable protocol can be passed to `lurek.gfx.draw()`:
Image, Canvas, SpriteBatch, Mesh, ParticleSystem.

---

## Input Pipeline

```
winit WindowEvent
  │
  ├── KeyEvent → KeyboardState (logical + physical keys) → lurek.keypressed/keyreleased
  ├── Ime(Commit) → lurek.textinput(text)
  ├── CursorMoved → MouseState → lurek.mousemoved(x, y, dx, dy, istouch)
  ├── MouseInput → MouseState.buttons → lurek.mousepressed/mousereleased
  ├── MouseWheel → MouseState.scroll → lurek.wheelmoved(x, y)
  ├── Touch → TouchState → lurek.touchpressed/moved/released
  ├── Focused → lurek.focus(focused)
  ├── Occluded → lurek.visible(!occ)
  └── Resized → lurek.resize(w, h)

gilrs events (polled per frame)
  ├── ButtonChanged → lurek.gamepadpressed/released
  ├── AxisChanged → lurek.gamepadaxis
  ├── Connected → lurek.joystickadded(id)
  └── Disconnected → lurek.joystickremoved(id)
```

---

## Audio Pipeline

```
lurek.audio.newSource("file.ogg", "stream")
  │
  ▼
AudioSource: path, source_type (Static|Stream), volume, pitch, pan, looping
  │
  ▼
Mixer: rodio OutputStream + SlotMap<SoundKey, AudioEntry>
       master_volume, headless fallback if no audio device
```

| Source Type | Loading | Memory | Latency | Use Case |
|---|---|---|---|---|
| **Static** | Decode entire file to `Vec<u8>` via `Arc` | Higher | Low | Short SFX |
| **Stream** | Open file, decode on-the-fly | Low | Slight | Music, ambience |

---

## Physics Pipeline

```
lurek.physics.newWorld(gx, gy)
  │
  ▼
World: rapier2d PhysicsPipeline + RigidBodySet + ColliderSet
       + ImpulseJointSet + BroadPhase + NarrowPhase + CCDSolver
       gravity, contact_events, bodies SlotMap
```

### Body Sync-Buffer Pattern

The `Body` struct decouples Lua from rapier2d internals:

```
Lua sets body position/velocity → Body buffer → sync to rapier at World::step()
                                                → simulate → read back → Body buffer → Lua reads
```

### Features

- **Shapes**: Rectangle (Cuboid), Circle (Ball), Polygon (ConvexPolygon), Edge (Segment), Chain (Polyline)
- **Joints**: 11 types — Distance, Revolute, Prismatic, Weld, Wheel, Pulley, Gear, Friction, Motor, Rope, Mouse
- **Queries**: rayCast, rayCastClosest, rayCastAny, queryBoundingBox
- **Callbacks**: beginContact, endContact, preSolve, postSolve

---

## Particle System

```rust
pub struct ParticleSystem {
    config:    ParticleConfig,    // ~35 configurable fields
    particles: Vec<Particle>,
    texture:   Option<TextureKey>,
    position:  Vec2,
    state:     EmitterState,      // Playing | Paused | Stopped
}
```

~35 config fields covering: emission rate/burst, lifetime, speed, direction/spread, size start/end + keyframes, color start/end + keyframes, rotation/spin, physics (acceleration, damping, gravity), area distribution (Point, Uniform, Normal, Ellipse, BorderRect, BorderEllipse).

---

## Data and Image Modules

### lurek.data — Binary Data Processing

- **ByteData**: `Vec<u8>` accessible from Lua for binary manipulation
- **Compression**: deflate/gzip/lz4/zlib via flate2 + lz4_flex
- **Hashing**: MD5/SHA-1/SHA-256/SHA-512 via sha2 + md-5
- **Encoding**: Base64/hex encoding and decoding

### lurek.img — CPU Pixel Manipulation

`ImageData`: RGBA8 pixel buffer with `getPixel`, `setPixel`, `mapPixel`, `paste`, `encode("png")`. Can be uploaded to GPU: `lurek.gfx.newImage(imageData)`.

> **Note**: `SoundData` (interleaved PCM `Vec<f32>`) previously lived in a separate `sound` module. It has been merged into `src/audio/` and is accessible through `lurek.audio`.

---

## Filesystem and Virtual FS

### GameFS (Sandboxed I/O)

Path-traversal-protected file operations. All paths resolve relative to the game directory or save directory, with `..` traversal blocked.

### VirtualFS (Archive Mounting)

```rust
pub enum MountPoint {
    Directory(PathBuf),
    Archive(PathBuf, ZipArchive),
}
```

File reads search mount points in reverse order (last mounted = highest priority). This enables mod support and DLC patterns.

### FileHandle

`lurek.fs.newFile(path, mode)` → FileHandle UserData with `read()`, `write()`, `lines()`, `close()`, `isOpen()`, `getMode()`.

---

## Window Management

| Feature | Implementation |
|---|---|
| Fullscreen toggle | `winit::Window::set_fullscreen()` (borderless or exclusive) |
| VSync control | wgpu `PresentMode` (Fifo / Immediate / Mailbox) |
| DPI scaling | `window.scale_factor()`, `toPixels()`/`fromPixels()` |
| Window icon | Load image → `winit::window::Icon` |
| Clipboard | `arboard` crate — get/set clipboard text |
| Display info | `EventLoop::available_monitors()` → count, dimensions, video modes |

---

## Threading Model

The main game loop and all Lua callbacks run on a single thread. Worker threads get **separate Lua VMs** — they do not share SharedState.

```
Main Thread                          Worker Thread N
├── Lua VM (full lurek.* API)         ├── Separate Lua VM
├── SharedState (Rc<RefCell<>>)      ├── Thread-safe modules ONLY:
├── GpuRenderer                      │   math, thread, timer (read),
└── Game Loop                        │   filesystem (read), system
                                     └── Channel ◄────────► Main Thread
```

### Channel

Inter-thread communication via typed, thread-safe MPMC channels:

```rust
pub enum ChannelValue { Nil, Bool(bool), Number(f64), String(String) }
```

Operations: `push`, `pop`, `demand` (blocking), `peek`, `getCount`, `clear`.

---

## Error Handling and Recovery

### EngineError

12+ variants covering: Config, Lua, Graphics, Audio, Physics, IO, Image, Window, Font, Timer, Filesystem, ResourceNotLoaded.

### Error Flow

```
Lua runtime error during lurek.process()/lurek.render()/lurek.render_ui()
  │
  ├── lurek.errorhandler(msg) defined? → call it → use returned message
  │
  ▼
RunState::Error(ErrorScreen)
  ├── Blue background (#1e3a5f)
  ├── Error heading + formatted stack trace
  ├── "Press Escape to quit or R to restart"
  │
  ├── [Escape] → Quitting → clean shutdown
  └── [R]      → Restarting → reload main.lua → Running
```

### Safety

- `conf.lua` errors → error screen, not crash
- Missing `main.lua` → "No game found" message on splash
- Windows panic hook → message box before exit

---

## Configuration System

### conf.lua Processing

```lua
function lurek.conf(t)
    t.window.title = "My Game"
    t.window.width = 1280
    t.window.height = 720
    t.modules.physics = true
end
```

The engine creates a temporary Lua VM, builds a defaults table, executes `conf.lua`, reads values back into a `Config` struct, then destroys the temporary VM.

### Config Fields

- `window`: title, width, height, vsync, fullscreen, resizable, min_width, min_height, borderless, icon, display_index
- `modules`: audio, physics, graphics, input, timer, filesystem (boolean toggles)
- `performance`: target_fps
- `identity`: save directory name
- `version`: target engine version

---

## Callback Contract

All callbacks are optional — the engine checks if the function exists before calling it. See [philosophy.md](philosophy.md) for the "blank main.lua" principle.

### Lifecycle Callbacks

| Callback | Arguments | When Fired |
|---|---|---|
| `lurek.conf(t)` | config table | During conf.lua processing |
| `lurek.init()` | — | Once after main.lua loads |
| `lurek.ready()` | — | Once before the first `process` frame (after init, after window is fully set up) |
| `lurek.exit()` | — | Engine shutdown |
| `lurek.quit()` | — | Close requested (return `true` to cancel) |
| `lurek.errorhandler(msg)` | error message | Uncaught Lua error |

### Frame Pipeline Callbacks (per-frame order)

| Callback | Arguments | When Fired |
|---|---|---|
| `lurek.process_physics(dt)` | fixed delta (seconds) | 0–N times per frame at fixed timestep (default 1/60s) |
| `lurek.process(dt)` | delta time (seconds) | Once per frame (variable timestep) |
| `lurek.process_late(dt)` | delta time (seconds) | Once per frame, after `process`, before `render` |
| `lurek.render()` | — | Once per frame (push DrawCommands here) |
| `lurek.render_ui()` | — | Once per frame, after `render` (UI/HUD overlay) |

### Input Callbacks

| Callback | Arguments | When Fired |
|---|---|---|
| `lurek.keypressed(key, scancode, isrepeat)` | key name, scancode, repeat flag | Key press |
| `lurek.keyreleased(key, scancode)` | key name, scancode | Key release |
| `lurek.textinput(text)` | Unicode text | Character input |
| `lurek.mousepressed(x, y, btn, istouch, presses)` | position, button, touch flag, click count | Mouse down |
| `lurek.mousereleased(x, y, btn, istouch, presses)` | position, button, touch flag, click count | Mouse up |
| `lurek.mousemoved(x, y, dx, dy, istouch)` | position, delta, touch flag | Mouse move |
| `lurek.wheelmoved(x, y)` | scroll deltas | Scroll wheel |
| `lurek.gamepadpressed(id, button)` | gamepad ID, button name | Gamepad button down |
| `lurek.gamepadreleased(id, button)` | gamepad ID, button name | Gamepad button up |
| `lurek.gamepadaxis(id, axis, value)` | gamepad ID, axis name, value | Gamepad axis change |
| `lurek.joystickadded(id)` | gamepad ID | Gamepad connected |
| `lurek.joystickremoved(id)` | gamepad ID | Gamepad disconnected |
| `lurek.touchpressed(id, x, y, dx, dy, pressure)` | touch ID, position, delta, pressure | Touch start |
| `lurek.touchmoved(id, x, y, dx, dy, pressure)` | touch ID, position, delta, pressure | Touch move |
| `lurek.touchreleased(id, x, y, dx, dy, pressure)` | touch ID, position, delta, pressure | Touch end |
| `lurek.focus(focused)` | boolean | Window focus change |
| `lurek.visible(visible)` | boolean | Window visibility change |
| `lurek.resize(w, h)` | new dimensions | Window resize |

### Frame Pipeline Execution Order

```
ready()                         -- once, first frame only
loop:
    process_physics(fixed_dt)   -- 0..N times (fixed 1/60s default)
    process(dt)                 -- once (variable dt)
    process_late(dt)            -- once (variable dt)
    [draw_commands cleared]
    render()                    -- once (push DrawCommands)
    render_ui()                 -- once (UI overlay DrawCommands)
    [debug overlay appended]
    [GPU render pass]
```

---

## DrawCommand Queue Reference

The `DrawCommand` enum defines all rendering operations that Lua can request:

### Shape Drawing

`Rectangle`, `RoundedRectangle`, `Circle`, `Ellipse`, `Triangle`, `Arc`, `Polygon`, `Line`, `Polyline`, `Points`

### Resource Drawing

`DrawImage`, `DrawCanvas`, `DrawMesh`, `DrawSpriteBatch`, `DrawParticleSystem`

### Text

`Print`, `PrintFormatted`

### State Changes

`SetColor`, `SetBackgroundColor`, `SetCanvas`, `SetShader`, `SetScissor`, `SetColorMask`, `SetLineWidth`, `SetPointSize`, `SetWireframe`

### Stencil

`StencilBegin`, `StencilEnd`, `SetStencilTest`

### Transforms

`PushTransform`, `PopTransform`, `Translate`, `Rotate`, `Scale`, `Shear`, `Origin`, `ApplyTransform`

### Other

`Clear`

---

## Dependencies

| Crate | Version | Purpose |
|---|---|---|
| wgpu | 22 | GPU rendering (Vulkan/DX12/Metal) |
| winit | 0.30 | Cross-platform windowing, event loop, input |
| mlua | 0.9 | Lua scripting (vendored, lua54 + send) |
| rapier2d | 0.32 | 2D rigid-body physics simulation |
| rodio | 0.17 | Audio playback (WAV, OGG, MP3, FLAC) |
| image | 0.24 | Image loading (PNG, JPEG, BMP) |
| fontdue | 0.9 | TTF/OTF font parsing and glyph rasterization |
| gilrs | 0.11 | Gamepad input (cross-platform) |
| slotmap | 1 | Generational ID resource pools |
| bytemuck | 1 | Safe POD casts for GPU vertex data |
| pollster | 0.3 | Blocking executor for wgpu async init |
| thiserror | 1 | Derive macros for error types |
| fastrand | 2 | Fast random number generation |
| serde | 1 | Serialization framework |
| serde_json | 1 | JSON serialization |
| directories | 5 | Platform-specific directory paths |
| log | 0.4 | Logging facade |
| env_logger | 0.10 | Environment-based log configuration |
| flate2 | 1 | Deflate/gzip/zlib compression |
| lz4_flex | 0.11 | LZ4 compression |
| sha2 | 0.10 | SHA-256/SHA-512 hashing |
| md-5 | 0.10 | MD5 hashing |
| arboard | 3 | Clipboard access |
| zip | 2 | ZIP archive reading (VFS mounting) |

---

## File Structure

```
src/
├── main.rs                          CLI entry point, arg parsing
├── lib.rs                           Library re-exports
│
├── engine/                          Baseline: lifecycle and shared state
│   ├── mod.rs, app.rs, config.rs, error.rs, error_screen.rs,
│   ├── debug_overlay.rs, resource_keys.rs
│
├── math/                            Baseline: foundational algorithms
│   ├── mod.rs, vec2.rs, mat3.rs, rect.rs, easing.rs, noise.rs,
│   ├── random.rs, transform.rs, bezier.rs, triangulate.rs, color_space.rs
│
├── graphics/                        Tier 1: GPU rendering pipeline
│   ├── mod.rs, gpu_renderer.rs, renderer.rs, shader.rs, mesh.rs,
│   ├── texture.rs, color.rs, sprite.rs, sprite_batch.rs, camera.rs,
│   ├── animation.rs, canvas.rs, font.rs
│
├── audio/                           Tier 1: audio playback
│   ├── mod.rs, mixer.rs, source.rs
│
├── input/                           Tier 1: input state
│   ├── mod.rs, keyboard.rs, mouse.rs, gamepad.rs, touch.rs
│
├── physics/                         Tier 1: rigid-body physics
│   ├── mod.rs, world.rs, body.rs, shape.rs, fixture.rs, joint.rs, contact.rs
│
├── timer/                           Tier 1: frame timing
│   ├── mod.rs, clock.rs
│
├── filesystem/                      Tier 1: sandboxed I/O
│   ├── mod.rs, vfs.rs, file_handle.rs, virtual_fs.rs
│
├── data/                            Tier 1: binary data processing
│   ├── mod.rs, byte_data.rs, compress.rs, hash.rs, encode.rs
│
├── image/                           Tier 1: CPU pixel manipulation
│   ├── mod.rs, image_data.rs
│
├── particle/                        Tier 2: particle systems
│   └── mod.rs
│
├── ai/                              Tier 2: game AI
├── scene/                           Tier 2: scene management
├── tilemap/                         Tier 2: tilemap rendering
├── pathfinding/                     Tier 2: navigation and pathfinding
├── ...                              (other Tier 2 modules)
│
└── lua_api/                         Bridge: Lua API registration
    ├── mod.rs, userdata.rs
    ├── graphics_api.rs, audio_api.rs, input_api.rs, timer_api.rs,
    ├── math_api.rs, physics_api.rs, filesystem_api.rs, window_api.rs,
    ├── event_api.rs, system_api.rs, particle_api.rs, data_api.rs,
    ├── image_api.rs, thread_api.rs, terminal_api.rs,
    ├── thread_channel.rs, thread_worker.rs

content/library/                             Tier 3: Lunasome (pure Lua)
├── battle/, cardgame/, combat/, crafting/, dialog/, doll/,
├── economy/, inventory/, item/, province_map/, quest/, stats/

content/examples/                            Lua game examples (27+ demos)
tests/                               Test suite (see test-framework.md)
docs/                                Documentation
tools/                               CLI scripts and build tools
.github/                             CAG layer (AI agents, skills, prompts, instructions)
extensions/vscode/                    First-party VS Code extension
assets/                              Engine assets (splash, icon, fonts)
```

---

## Legacy and Migration-State Modules

Several gameplay-oriented Rust modules still exist under `src/`. They remain buildable and testable but are **not** the active Tier 3 architecture target. The canonical Tier 3 location is `content/library/` (pure Lua).

| Module | Status | Notes |
|---|---|---|
| `src/battle/`, `src/cardgame/`, `src/combat/`, `src/crafting/` | Migration-state | Being superseded by `content/library/` equivalents |
| `src/dialog/`, `src/economy/`, `src/inventory/`, `src/item/` | Migration-state | Keep buildable, do not document as current Tier 3 |
| `src/province_map/`, `src/quest/`, `src/stats/` | Migration-state | Future: may be removed when Lunasome equivalents are mature |

---

## Planned Build Variants

The layer model supports future build variants (not yet implemented at the Cargo feature level):

| Variant | Layers Included | Target Use Case |
|---|---|---|
| **Baseline** | Baseline + bridge | Minimal runtime substrate |
| **Core** | Baseline + Tier 1 + bridge | Core engine without extensions |
| **Extended** | Baseline + Tier 1 + Tier 2 + bridge | General-purpose runtime |
| **Lunasome** | Extended + `content/library/` | Full runtime + standard Lua libraries |
