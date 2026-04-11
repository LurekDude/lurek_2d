# Lurek2D — Engine Architecture

> **Source of truth** for the runtime module structure, rendering pipeline, and internal subsystem design.
> Companion documents: [philosophy.md](philosophy.md) (principles + design assumptions) · [test-framework.md](test-framework.md) (test architecture).

---

## Table of Contents

1. [Overview](#overview)
2. [Project Identity](#project-identity)
3. [Module Group Model](#module-group-model)
4. [Module Group Dependency Graph](#module-group-dependency-graph)
5. [Foundations Group](#foundations-group)
6. [Core Runtime Group](#core-runtime-group)
7. [Platform Services Group](#platform-services-group)
8. [Feature Systems Group](#feature-systems-group)
9. [Edge and Integration Layer](#edge-and-integration-layer)
10. [Lunasome — content/library/](#lunasome--contentlibrary)
11. [Boot Sequence](#boot-sequence)
12. [Game Loop and Frame Model](#game-loop-and-frame-model)
13. [State Architecture](#state-architecture)
14. [Resource Management](#resource-management)
15. [Rendering Pipeline](#rendering-pipeline)
16. [Lua Binding Architecture](#lua-binding-architecture)
17. [Input Pipeline](#input-pipeline)
18. [Audio Pipeline](#audio-pipeline)
19. [Physics Pipeline](#physics-pipeline)
20. [Particle System](#particle-system)
21. [Data and Image Modules](#data-and-image-modules)
22. [Filesystem and Virtual FS](#filesystem-and-virtual-fs)
23. [Window Management](#window-management)
24. [Threading Model](#threading-model)
25. [Error Handling and Recovery](#error-handling-and-recovery)
26. [Configuration System](#configuration-system)
27. [Callback Contract](#callback-contract)
28. [RenderCommand Queue Reference](#rendercommand-queue-reference)
29. [Dependencies](#dependencies)
30. [File Structure](#file-structure)
31. [Migration Notes](#migration-notes)

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

## Module Group Model

Lurek2D organises its Rust source into **five responsibility groups**. This is a **logical dependency model** — most modules live in flat `src/<module>/` directories. Group membership is determined by what a module imports and what reasons it has to change.

The central invariant is **Principle 1 of the Zen of Lurek 2.0**: the module import graph must be a DAG — no cycles, ever. Same-group imports are allowed when they are stable and acyclic (see Principle 6).

| Group | Path | Role |
|---|---|---|
| **Foundations** | `src/math/`, `src/log/`, `src/data/`, `src/serial/`, `src/compute/`, `src/dataframe/`, `src/graph/`, `src/procgen/`, `src/patterns/` | Pure algorithms and data types — no render, no audio, no input, no Lua |
| **Core Runtime** | `src/engine/` (→ `core` + `world`), `src/filesystem/`, `src/timer/`, `src/event/`, `src/thread/`, `src/network/` | Engine lifecycle, resource registry, sandboxed I/O, timing, events, concurrency |
| **Platform Services** | `src/window/`, `src/input/`, `src/render/`, `src/image/`, `src/audio/`, `src/physics/` | OS-facing backends — each exposes a pure-Rust contract, not a backend-specific type |
| **Feature Systems** | `src/ecs/`, `src/scene/`, `src/animation/`, `src/tween/`, `src/particle/`, `src/tilemap/`, `src/parallax/`, `src/minimap/`, `src/raycaster/`, `src/gui/`, `src/terminal/`, `src/ai/`, `src/pathfind/`, `src/save/`, `src/mods/`, `src/i18n/`, `src/automation/` | Game-domain services built on the layers below |
| **Edge/Integration** | `src/lua_api/`, `src/app/` (boot + event loop), `src/devtools/`, `src/debugbridge/` | Composition root, scripting bridge, tooling — nothing in the engine imports these |

### Boundary Rules

- **Foundations** modules must never import Platform Services, Feature Systems, or Edge/Integration.
- **Core Runtime** may import Foundations. Must not import Platform Services, Feature Systems, or Edge/Integration.
- **Platform Services** may import Foundations and Core Runtime. Must not import Feature Systems or Edge/Integration.
- **Feature Systems** may import any group below them. Same-group imports are allowed when acyclic.
- **`lua_api`** (scripting) and **`app`** sit in the Edge/Integration group. They may import all lower groups. No lower group may import them.
- **Lunasome** (`content/library/`) is pure-Lua. It consumes only the public `lurek.*` API — no Rust internals.
- The main rule: **no cycles**. If adding an import creates a cycle, the design is wrong.

---

## Module Group Dependency Graph

The five groups form a DAG. Arrows show the **only allowed import direction** (←). Same-group imports (dashed) are allowed when stable and acyclic.

```
     game scripts / content/examples/
                  │
                  ▼
    content/library/  (Lunasome — pure Lua)
                  │ consumes public lurek.* API
                  ▼
  ┌───────────────────────────────────────────────────────────┐
  │            EDGE / INTEGRATION LAYER                       │
  │   src/lua_api/  (scripting bridge, registers lurek.*)     │
  │   src/app/      (boot sequence + event loop — top-level)  │
  │   src/devtools/ src/debugbridge/  (tooling, edge only)    │
  └───────────────────────────┬───────────────────────────────┘
                              │ imports
                              ▼
  ┌───────────────────────────────────────────────────────────┐
  │              FEATURE SYSTEMS GROUP                        │
  │   ecs, scene, animation, tween, particle, tilemap,        │
  │   parallax, minimap, raycaster, gui, terminal, ai,        │
  │   nav, save, mods, i18n, automation                       │
  └───────────────────────────┬───────────────────────────────┘
                              │ imports
                              ▼
  ┌───────────────────────────────────────────────────────────┐
  │             PLATFORM SERVICES GROUP                       │
  │   window, input, render, image, audio, physics            │
  └───────────────────────────┬───────────────────────────────┘
                              │ imports
                              ▼
  ┌───────────────────────────────────────────────────────────┐
  │              CORE RUNTIME GROUP                           │
  │   engine (→core + world), filesystem, time, event,       │
  │   task, network                                           │
  └───────────────────────────┬───────────────────────────────┘
                              │ imports
                              ▼
  ┌───────────────────────────────────────────────────────────┐
  │               FOUNDATIONS GROUP                           │
  │   math, log, data, serial, compute, dataframe, graph,     │
  │   procgen, patterns                    (leaf — no deps)   │
  └───────────────────────────────────────────────────────────┘
```

Same-group (horizontal) imports are **allowed when stable and acyclic**. The one absolute rule: **no cycles anywhere in the graph**.

### Import Rules Summary

| Source Group | May Import | Must Never Import |
|---|---|---|
| Foundations | nothing (leaf) | everything else |
| Core Runtime | Foundations | Platform Services, Feature Systems, Edge |
| Platform Services | Foundations, Core Runtime | Feature Systems, Edge/Integration |
| Feature Systems | Foundations, Core Runtime, Platform Services; same-group when acyclic | Edge/Integration |
| Edge/Integration (`lua_api`, `app`) | All lower groups | — (nothing imports Edge) |
| Lunasome (`content/library/`) | Public `lurek.*` API only | Any Rust engine internals |
| Any domain module | Its group + lower groups | `lua_api` or `app` (Edge/Integration) |

**The one rule that subsumes all others**: the module graph is a DAG. No cycles, ever.
---

## Foundations Group

Foundations modules are **pure algorithms and data types**. They import nothing from Platform Services, Feature Systems, or Edge/Integration. They are the most reusable, most stable, and most test-friendly modules in the engine.

| Module | Path | What it provides |
|---|---|---|
| `math` | `src/math/` | Vec2, Vec3, Mat3, Rect, Color, noise, easing, interpolation, random, bezier, triangulation |
| `log` | `src/log/` | Structured Lua-script logging at configurable severity levels |
| `data` | `src/data/` | Binary data (ByteData), compression, hashing, base64 encoding |
| `serial` | `src/serial/` | Format-agnostic serialization: JSON, TOML, MessagePack |
| `compute` | `src/compute/` | Dense numerical arrays (NdArray) and CPU-side compute helpers |
| `dataframe` | `src/dataframe/` | Column-major tabular data structures |
| `graph` | `src/graph/` | Directed graphs, flow simulation, graph algorithms |
| `procgen` | `src/procgen/` | Procedural content generation: dungeons, terrain, noise, L-systems |
| `patterns` | `src/patterns/` | Pure-Rust game-programming design patterns (FSM, observer, service locator) |

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

---

## Core Runtime Group

Core Runtime modules own the **engine lifecycle, resource registry, sandboxed I/O, timing, events, and concurrency**. They may import Foundations. They must not import Platform Services, Feature Systems, or Edge/Integration.

> **Architectural note**: `src/engine/` currently combines config, errors, typed handles, `SharedState`, and boot logic in one crate. The target split is `core` (pure types — errors, config, resource keys, traits) and `world` (runtime state — SharedState, resource pools, registries). `app/` (boot sequence and event loop) moves to the Edge/Integration group. This migration is in progress.

| Module | Path | Responsibility |
|---|---|---|
| `engine` → `core` | `src/engine/` | `EngineError`, `Config`, typed SlotMap key types (`TextureKey`, `FontKey`, etc.) |
| `engine` → `world` | `src/engine/` | `SharedState` (resource pools, render commands, subsystem handles) |
| `filesystem` | `src/filesystem/` | Sandboxed game filesystem (GameFS), VirtualFS, archive mounting |
| `time` | `src/timer/` | Frame timing (Clock), FPS tracking, scheduled callbacks |
| `event` | `src/event/` | Event queue and polling primitives |
| `task` | `src/thread/` | Background Rust threads and typed MPMC Channel communication |
| `network` | `src/network/` | UDP networking via ENet: peer-to-peer and client-server multiplayer |

### `engine/` — Runtime Types and SharedState

`engine` currently provides both pure types (errors, config, resource keys) and runtime state (SharedState). Key files:

| File | Responsibility |
|---|---|
| `error.rs` | `EngineError` (12+ variants), `EngineResult<T>` |
| `config.rs` | `Config`, `WindowConfig`, `ModulesConfig`, `PerformanceConfig` |
| `resource_keys.rs` | 14 typed SlotMap key newtypes (`TextureKey`, `FontKey`, `CanvasKey`, etc.) |
| `shared_state.rs` | `SharedState`, `WindowState`, `FullscreenType`, `ErrorInfo`, `ScreenshotRequest` |
| `app.rs` | `App` struct, `RunState` machine, game loop, error mode loop (→ will move to Edge) |
| `error_screen.rs` | `ErrorScreen` — blue error display with built-in font |

`SharedState` is shared between Lua closures and the engine loop via `Rc<RefCell<SharedState>>`.

---

## Edge and Integration Layer — lua_api

`lua_api` sits above the engine layers. It imports runtime modules and exposes them through the `lurek.*` namespace.

- It is **not** a numbered tier.
- It may import Foundations, Core Runtime, Platform Services, Feature Systems, and migration-state modules.
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
| `lurek.event` | `event_api.rs` | Event queue, quit, push/poll/clear |
| `lurek.platform` | `system_api.rs` | OS info, processor count, openURL, locales |
| `lurek.particles` | `particle_api.rs` | Particle emitters, configuration, rendering |
| `lurek.data` | `data_api.rs` | Binary data, compression, hashing, encoding |
| `lurek.img` | `image_api.rs` | CPU pixel buffers, pixel manipulation |
| `lurek.task` | `thread_api.rs` | Worker threads, channels |
| `lurek.animation` | `animation_api.rs` | Frame-based sprite animation, named clips, speed control |
| `lurek.camera` | `camera_api.rs` | Camera2D, viewport transforms |
| `lurek.simulator` | `automation_api.rs` | Automated input simulation and replay |
| `lurek.ecs` | `entity_api.rs` | Lightweight ECS primitives |
| `lurek.scene` | `scene_api.rs` | Scene stack management and transitions |
| `lurek.gpu` | `compute_api.rs` | Dense numerical arrays, CPU-side compute |
| `lurek.save` | `savegame_api.rs` | Slot-based save/load, schema versioning |
| `lurek.codec` | `serial_api.rs` | JSON, TOML, MessagePack serialization |
| `lurek.dataframe` | `dataframe_api.rs` | Column-major tabular data structures |
| `lurek.light` | `light_api.rs` | 2D dynamic lighting and shadow casting |
| `lurek.mods` | `modding_api.rs` | Mod discovery, dependency resolution, load ordering |
| `lurek.raycaster` | `raycaster_api.rs` | DDA grid raycasting for retro rendering |
| `lurek.spine` | `spine_api.rs` | Spine 2D skeletal animation runtime |
| `lurek.procgen` | `procgen_api.rs` | Procedural content generation algorithms |
| `lurek.network` | `network_api.rs` | UDP networking, packet framing |
| `lurek.minimap` | `minimap_api.rs` | Grid-based minimap extraction and FOV masking |
| `lurek.nav` | `pathfinding_api.rs` | Navigation grids, A★, HPA★, flow fields — powered by `src/pathfind/` |
| `lurek.terminal` | `terminal_api.rs` | In-game developer terminal / REPL |
| `lurek.pipeline` | `pipeline_api.rs` | DAG pipeline orchestration and caching |
| `lurek.patterns` | `patterns_api.rs` | Game programming design patterns toolkit |
| `lurek.graph` | `graph_api.rs` | Directed graphs, flow simulation |
| `lurek.ai` | `ai_api.rs` | FSMs, behaviour trees, GOAP, steering |
| `lurek.fx` | `fx_api.rs` | Post-processing effects, screen overlays |
| `lurek.ui` | `gui_api.rs` | Retained-mode widget UI |
| `lurek.tilemap` | `tilemap_api.rs` | Tilemaps, tilesets, coordinate helpers |
| `lurek.devtools` | `devtools_api.rs` | Developer diagnostics and runtime profiling |
| `lurek.debugbridge` | `debugbridge_api.rs` | JSON-over-TCP debug server for remote inspection |
| `lurek.i18n` | `localization_api.rs` | Multi-locale string catalogs with plural rules |
| `lurek.log` | `log_api.rs` | Structured game-script logging |
| `lurek.docs` | `docs_api.rs` | API documentation reference management |

---

## Platform Services Group

Platform Services modules are the engine's OS-facing backends — rendering, audio, physics, windowing, and input. Each exposes a pure-Rust contract type. Feature Systems modules import the contract, not the backend.

**Import rule**: may import Foundations and Core Runtime. Must not import Feature Systems or Edge/Integration.

> **Note**: `animation`, `tween`, `compute`, `data`, `devtools`, `debugbridge`, `log`, `patterns` listed below have been reclassified into their correct groups (Foundations, Core Runtime, or Edge/Integration) in the new model. The table below shows the **current source state** including transition-state modules.

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
| `ecs` | `src/ecs/` | Lightweight ECS primitives and entity helpers |
| `event` | `src/event/` | Event queue and polling primitives |
| `filesystem` | `src/filesystem/` | Sandboxed game filesystem (GameFS), VirtualFS, archive mounting |
| `render` | `src/render/` | GPU rendering pipeline, draw commands, textures, fonts, batching, shaders |
| `image` | `src/image/` | CPU-side image manipulation (ImageData) |
| `input` | `src/input/` | Keyboard, mouse, gamepad, and touch state management |
| `i18n` | `src/i18n/` | Multi-locale string catalog with variable substitution and plural form selection |
| `log` | `src/log/` | Structured Lua-script logging at configurable severity levels |
| `patterns` | `src/patterns/` | Pure-Rust game-programming design patterns (FSM, observer, service locator, etc.) |
| `physics` | `src/physics/` | Rigid bodies, shapes, collisions, joints, raycasting via rapier2d |
| `task` | `src/thread/` | Background Rust threads and Channel communication |
| `time` | `src/timer/` | Frame timing (Clock), FPS tracking, scheduled callbacks |
| `tween` | `src/tween/` | Property animation system: tweens, sequences, parallel groups, and easing functions |
| `window` | `src/window/` | Window lifecycle and state abstraction |

---

## Feature Systems Group

Feature Systems modules are game-domain services built on the groups below them. Same-group imports are allowed when stable and acyclic (no cycles allowed).

**Import rule**: may import Foundations, Core Runtime, and Platform Services. Same-group (Feature Systems) imports allowed when acyclic.

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
| `mods` | `src/mods/` | Mod discovery, dependency resolution, load ordering |
| `network` | `src/network/` | UDP networking via ENet: peer-to-peer and client-server multiplayer |
| `parallax` | `src/parallax/` | CPU-driven multi-layer parallax background system with tiling, autoscroll, and per-layer blend modes |
| `particle` | `src/particle/` | Emitter-based 2D particle systems |
| `nav` | `src/pathfind/` | Navigation grids, A★, HPA★, flow fields |
| `pipeline` | `src/pipeline/` | DAG-based data pipeline orchestration and caching |
| `procgen` | `src/procgen/` | Procedural content generation: dungeons, terrain, noise, L-systems |
| `raycaster` | `src/raycaster/` | DDA grid raycasting for Wolfenstein-style retro rendering |
| `save` | `src/save/` | Save/load orchestration and schema versioning |
| `scene` | `src/scene/` | Scene stack management and transitions |
| `serial` | `src/serial/` | Format-agnostic serialization: JSON, TOML, MessagePack |
| `spine` | `src/spine/` | Spine 2D skeletal animation: bone hierarchies, slots, world transforms |
| `terminal` | `src/terminal/` | In-game developer terminal / REPL with widget toolkit |
| `tilemap` | `src/tilemap/` | Tilemaps, tilesets, map generation, coordinate helpers |

---

## Lunasome — content/library/

**Lunasome** is the pure-Lua standard library shipped alongside the engine. It is **not** embedded in the Rust binary. It lives under `content/library/` and consumes only the public `lurek.*` API.

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
  │     ├── Register 40+ API modules (render, input, audio, timer, math, physics,
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

When no game directory is provided, the engine displays a built-in splash screen — the Lurek2D logo and project identity rendered through the same RenderCommand system. The splash screen runs at 60 FPS until the user closes the window. **Drag-and-drop** is supported: drop a game folder onto the splash window to load it immediately.

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
│ 8a. Call lurek.render()         → game pushes RenderCommands       │
│ 8b. Call lurek.render_ui()      → UI/HUD overlay RenderCommands    │
│ 9. GpuRenderer::render_frame()                                 │
│    ├── Flush pending resource removals (deferred destruction)   │
│    ├── Update auto-uniforms (time, screen size)                 │
│    ├── Acquire swapchain texture                                │
│    ├── Process RenderCommand queue → wgpu render passes           │
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
    pub render_commands:    Vec<RenderCommand>,
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
Rust: push DrawImage { texture_key, ... } into render_commands
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
| `lurek.render()` | — | Once per frame (push RenderCommands here) |
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
    [render_commands cleared]
    render()                    -- once (push RenderCommands)
    render_ui()                 -- once (UI overlay RenderCommands)
    [debug overlay appended]
    [GPU render pass]
```

---

## RenderCommand Queue Reference

The `RenderCommand` enum defines all rendering operations that Lua can request:

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
├── engine/                          Core Runtime: lifecycle and shared state (→ `core` + `world` split planned)
│   ├── mod.rs, app.rs, config.rs, error.rs, error_screen.rs,
│   ├── debug_overlay.rs, resource_keys.rs
│
├── math/                            Foundations: foundational algorithms
│   ├── mod.rs, vec2.rs, mat3.rs, rect.rs, easing.rs, noise.rs,
│   ├── random.rs, transform.rs, bezier.rs, triangulate.rs, color_space.rs
│
├── render/                          Platform Services: GPU rendering pipeline (canonical, 42 files)
│   └── (see src/render/ — GpuRenderer, RenderCommand, pipelines, textures, fonts, shaders)
│
├── graphics/                        [legacy stub — orphaned, not in active lib.rs pub mod list]
│
├── audio/                           Platform Services: audio playback
│   ├── mod.rs, mixer.rs, source.rs
│
├── input/                           Platform Services: input state
│   ├── mod.rs, keyboard.rs, mouse.rs, gamepad.rs, touch.rs
│
├── physics/                         Platform Services: rigid-body physics
│   ├── mod.rs, world.rs, body.rs, shape.rs, fixture.rs, joint.rs, contact.rs
│
├── timer/                           Core Runtime: frame timing (lurek.time)
│   ├── mod.rs, clock.rs
│
├── filesystem/                      Core Runtime: sandboxed I/O
│   ├── mod.rs, vfs.rs, file_handle.rs, virtual_fs.rs
│
├── data/                            Foundations: binary data processing
│   ├── mod.rs, byte_data.rs, compress.rs, hash.rs, encode.rs
│
├── image/                           Platform Services: CPU pixel manipulation
│   ├── mod.rs, image_data.rs
│
├── particle/                        Feature Systems: particle systems
│   └── mod.rs
│
├── ai/                              Feature Systems: game AI
├── scene/                           Feature Systems: scene management
├── tilemap/                         Feature Systems: tilemap rendering
├── nav/                             Feature Systems: navigation and pathfinding (pathfind)
├── ...                              (other Feature Systems modules)
│
└── lua_api/                         Edge/Integration: Lua API registration (scripting bridge)
    ├── mod.rs, userdata.rs
    ├── graphics_api.rs, audio_api.rs, input_api.rs, timer_api.rs,
    ├── math_api.rs, physics_api.rs, filesystem_api.rs, window_api.rs,
    ├── event_api.rs, system_api.rs, particle_api.rs, data_api.rs,
    ├── image_api.rs, thread_api.rs, terminal_api.rs,
    ├── thread_channel.rs, thread_worker.rs

content/library/                             Lunasome (pure Lua — consumes public lurek.* API)
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

## Migration Notes

Several gameplay-oriented Rust modules still exist under `src/`. They remain buildable and testable but are **not** the active architecture target. The canonical gameplay-library location is `content/library/` (Lunasome — pure Lua).

| Module | Status | Notes |
|---|---|---|
| `src/battle/`, `src/cardgame/`, `src/combat/`, `src/crafting/` | Migration-state | Being superseded by `content/library/` equivalents |
| `src/dialog/`, `src/economy/`, `src/inventory/`, `src/item/` | Migration-state | Keep buildable, do not document as active API |
| `src/province_map/`, `src/quest/`, `src/stats/` | Migration-state | Future: may be removed when Lunasome equivalents are mature |

---

## Planned Build Variants

The layer model supports future build variants (not yet implemented at the Cargo feature level):

| Variant | Groups Included | Target Use Case |
|---|---|---|
| **Minimal** | Foundations + Core Runtime + Edge | Headless runtime substrate |
| **Core** | Foundations + Core Runtime + Platform Services + Edge | Core engine without Feature Systems |
| **Standard** | All five groups | General-purpose runtime |
| **Full** | Standard + `content/library/` | Full runtime + Lunasome standard libraries |
