# Lurek2D — Engine Architecture

> **Source of truth** for runtime module structure, boot sequence, frame model,
> state management, and subsystem pipelines.
>
> Companion documents:
> [philosophy.md](philosophy.md) (binding constraints, Zen rules) ·
> [render-command-architecture.md](render-command-architecture.md) (rendering
> pipeline, module file structure standard, render extraction plan) ·
> [test-framework.md](test-framework.md) (test architecture)
>
> **Relationship to other documents**: `philosophy.md` defines *why* and
> *what constraints*. This document defines *how the engine is structured*.
> `render-command-architecture.md` defines the rendering pipeline in detail.
> `test-framework.md` defines the testing strategy. All four documents must
> remain in sync.

---

## Table of Contents

- [Lurek2D — Engine Architecture](#lurek2d--engine-architecture)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Module Group Model](#module-group-model)
    - [Group Responsibilities](#group-responsibilities)
  - [Module Group Dependency Rules](#module-group-dependency-rules)
  - [Complete Module Inventory](#complete-module-inventory)
    - [Foundations](#foundations)
    - [Core Runtime](#core-runtime)
    - [Platform Services](#platform-services)
    - [Feature Systems](#feature-systems)
    - [Edge / Integration](#edge--integration)
    - [Lunasome (library/)](#lunasome-contentlibrary)
  - [Module Internal File Structure Standard](#module-internal-file-structure-standard)
    - [Required Files](#required-files)
    - [Standard Optional Files](#standard-optional-files)
    - [Key Rules](#key-rules)
    - [mod.rs — The Thin Declaration Rule](#modrs--the-thin-declaration-rule)
    - [Anti-Patterns](#anti-patterns)
  - [Boot Sequence](#boot-sequence)
    - [Boot Invariants](#boot-invariants)
  - [Game Loop and Frame Model](#game-loop-and-frame-model)
    - [Timing](#timing)
  - [Callback Contract](#callback-contract)
    - [Callback Ordering Within a Frame](#callback-ordering-within-a-frame)
  - [State Architecture](#state-architecture)
    - [Design Rules (from Zen Rule 10)](#design-rules-from-zen-rule-10)
    - [SharedState Contents](#sharedstate-contents)
    - [Access Pattern](#access-pattern)
  - [Resource Management](#resource-management)
    - [Resource Key Types](#resource-key-types)
    - [Lifecycle](#lifecycle)
    - [Stale Key Safety](#stale-key-safety)
  - [Rendering Pipeline](#rendering-pipeline)
    - [Summary: Three-Layer Model](#summary-three-layer-model)
    - [Key Facts](#key-facts)
    - [Render Module Refactoring (Planned)](#render-module-refactoring-planned)
  - [Lua Binding Architecture](#lua-binding-architecture)
    - [Design Rules (from Zen Rule 12, constraints C-01 through C-05)](#design-rules-from-zen-rule-12-constraints-c-01-through-c-05)
    - [File Organisation](#file-organisation)
    - [Thin Wrapper Pattern](#thin-wrapper-pattern)
    - [Registration Flow](#registration-flow)
    - [Lua API Docstring Format](#lua-api-docstring-format)
  - [Input Pipeline](#input-pipeline)
  - [Audio Pipeline](#audio-pipeline)
    - [Key Concepts](#key-concepts)
  - [Physics Pipeline](#physics-pipeline)
    - [Frame Integration](#frame-integration)
    - [Key Concepts](#key-concepts-1)
  - [Threading Model](#threading-model)
    - [Rules (from constraint B-04)](#rules-from-constraint-b-04)
  - [Filesystem and Virtual FS](#filesystem-and-virtual-fs)
    - [Security (path traversal guards)](#security-path-traversal-guards)
    - [Lua API](#lua-api)
  - [Window Management](#window-management)
    - [Scale Modes (Camera)](#scale-modes-camera)
  - [Configuration System](#configuration-system)
    - [conf.toml / conf.lua (game-authored configuration)](#conftoml--conflua-game-authored-configuration)
    - [Config Struct](#config-struct)
    - [Fallback](#fallback)
    - [Format Rule (B-05)](#format-rule-b-05)
  - [Error Handling and Recovery](#error-handling-and-recovery)
    - [Error Types](#error-types)
    - [Error Flow](#error-flow)
    - [Rules](#rules)
  - [Quality Gates](#quality-gates)
    - [Full Quality Gate Command](#full-quality-gate-command)
  - [Technology Stack](#technology-stack)
    - [Cargo Feature Flags](#cargo-feature-flags)
  - [Repository File Structure](#repository-file-structure)
  - [Planned Build Variants](#planned-build-variants)

---

## Overview

Lurek2D is a 2D game engine written in Rust that loads and executes Lua game
scripts. A game is a `main.lua` file. The engine owns the GPU, the physics
solver, the audio mixer, and the threading model. The developer writes Lua;
the engine handles everything else.

**One binary. One scripting language. One afternoon to learn.**

The engine is designed with AI copilots as first-class users. Every API is
shaped so an AI agent can use it correctly from the docs alone. The CAG layer,
the VS Code extension, and the documentation pipeline are all optimised for
AI-assisted workflow.

**Key design principles** (from [philosophy.md](philosophy.md)):

- Runtime only — no embedded visual editor (A-01)
- Desktop only — Windows / Linux / macOS (A-02)
- 2D graphics only — no 3D scene graph (A-03)
- LuaJIT scripting (B-01), wgpu 22 rendering (B-02)
- Module import graph is always a DAG — no cycles, ever (Zen Rule 1)
- Lua bindings are thin and one-directional (Zen Rule 12)
- Every public item has a doc comment (Zen Rule 15)

---

## Module Group Model

Lurek2D organises its Rust source into **five responsibility groups**. The
binding invariant is **no cycles, ever** — the module import graph must be a
DAG (Zen Rule 1, constraint T-03).

The grouping is **loose and practical**. It does not say "never import from
the same group." It says: "you know what each module belongs to and what it
should not be doing." Same-group imports are allowed when they are stable and
acyclic (Zen Rule 6).

```
┌─────────────────────────────────────────────────────────────────────┐
│  EDGE / INTEGRATION                                                 │
│  app · lua_api · devtools · debugbridge · docs · pipeline · bin     │
│  ↓ can import everything below, nothing below imports these         │
├─────────────────────────────────────────────────────────────────────┤
│  FEATURE SYSTEMS                                                    │
│  ecs · scene · animation · tween · particle · tilemap · parallax ·  │
│  minimap · raycaster · ui · terminal · ai · pathfind · save · mods ·│
│  i18n · automation · sprite · spine                                 │
│  ↓ may import: Foundations, Core Runtime, Platform Services         │
│    same-group imports allowed when acyclic (Zen Rule 6)             │
├─────────────────────────────────────────────────────────────────────┤
│  PLATFORM SERVICES                                                  │
│  render · audio · physics · input · image · window · camera ·       │
│  light · effect                                                     │
│  ↓ may import: Foundations, Core Runtime                            │
│    expose pure-Rust contracts — backend is implementation detail     │
├─────────────────────────────────────────────────────────────────────┤
│  CORE RUNTIME                                                       │
│  runtime · event · timer · thread · network · filesystem            │
│  ↓ may import: Foundations only                                     │
├─────────────────────────────────────────────────────────────────────┤
│  FOUNDATIONS                                                        │
│  math · log · data · serial · compute · dataframe · graph ·         │
│  procgen · patterns                                                 │
│  No render, audio, input, physics, or Lua imports (Zen Rule 9)      │
└─────────────────────────────────────────────────────────────────────┘

   library/ (LUNASOME)
   Pure-Lua standard libraries — consume only public lurek.* APIs.
   No Rust engine internals. No require() of engine source files.
```

### Group Responsibilities

| Group                 | Responsibility                                                                        | May Import                                   | Must NOT Import                                      |
| --------------------- | ------------------------------------------------------------------------------------- | -------------------------------------------- | ---------------------------------------------------- |
| **Foundations**       | Pure algorithms, data structures, math, serialisation                                 | Nothing (leaf modules)                       | render, audio, input, physics, Lua, any higher group |
| **Core Runtime**      | Engine lifecycle, resource registry, I/O, timing, events, concurrency                 | Foundations                                  | Platform Services, Feature Systems, Edge             |
| **Platform Services** | OS-facing backends behind pure-Rust contracts (GPU, audio, physics, input, windowing) | Foundations, Core Runtime                    | Feature Systems, Edge                                |
| **Feature Systems**   | Game-domain services: sprites, scenes, particles, UI, AI, tilemaps                    | Foundations, Core Runtime, Platform Services | Edge/Integration                                     |
| **Edge/Integration**  | Composition root (`app`), scripting bridge (`lua_api`), devtools                      | Everything below                             | (nothing — these are top of the DAG)                 |
| **Lunasome**          | Pure-Lua gameplay libraries                                                           | Public `lurek.*` API only                    | Rust engine internals                                |

---

## Module Group Dependency Rules

The binding dependency constraints **T-01 through T-08** are defined in
[philosophy.md § Active Module Group Constraints](philosophy.md#active-module-group-constraints).
They are the source of truth for import direction between the five groups
(Foundations → Core Runtime → Platform Services → Feature Systems → Edge/Integration),
for `lua_api` placement, for the no-cycles-ever rule, and for the Lunasome
and Steam-SDK boundaries. Consult philosophy.md directly — this document
does not restate them.

---

## Complete Module Inventory

Every `src/<module>/` directory with its group assignment, responsibility,
and key types. Modules are listed alphabetically within each group.

### Foundations

| Module      | Responsibility                                              | Key Types                                                              |
| ----------- | ----------------------------------------------------------- | ---------------------------------------------------------------------- |
| `math`      | Vectors, matrices, rects, color, interpolation, easing, RNG | `Vec2`, `Vec3`, `Vec4`, `Mat3`, `Mat4`, `Rect`, `Color`, `Transform2D` |
| `log`       | Logging facade (`log` crate), RUST_LOG filtering            | Log macros re-export                                                   |
| `data`      | Generic data containers, bin-packing, data views            | `DataView`, `BinPack`                                                  |
| `serial`    | Serialisation: TOML, JSON, CSV, YAML (read-only)            | `toml::from_str`, `json::parse`                                        |
| `compute`   | GPU-free numerical computation, data processing             | Compute pipelines                                                      |
| `dataframe` | Tabular data, SQL-like queries, column operations           | `DataFrame`, `Column`                                                  |
| `graph`     | Graph data structures, traversal algorithms                 | `Graph`, `Node`, `Edge`                                                |
| `procgen`   | Procedural generation: noise, Voronoi, L-systems            | `Noise`, `Voronoi`                                                     |
| `patterns`  | Design patterns: state machines, observer, command          | `StateMachine`, `Observer`                                             |

### Core Runtime

| Module       | Responsibility                                                     | Key Types                                                  |
| ------------ | ------------------------------------------------------------------ | ---------------------------------------------------------- |
| `runtime`    | Engine lifecycle, shared state, config, resource keys, error types | `SharedState`, `Config`, `EngineError`, resource key types |
| `event`      | Event bus, typed event dispatch                                    | `EventBus`, `EventId`                                      |
| `timer`      | Frame timing, delta time, fixed timestep, timers                   | `Timer`, `TimerHandle`                                     |
| `thread`     | Thread pool, worker VMs, Channel for inter-VM comms                | `ThreadPool`, `Channel`                                    |
| `network`    | HTTP client, WebSocket, networking utilities                       | `HttpRequest`, `HttpResponse`                              |
| `filesystem` | GameFS sandbox, virtual filesystem, path traversal guards          | `GameFS`, `VirtualPath`                                    |

### Platform Services

| Module    | Responsibility                                                            | Key Types                                                                                   |
| --------- | ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `render`  | GPU rendering: wgpu pipelines, render passes, RenderCommand contract      | `GpuRenderer`, `RenderCommand`, `DrawMode`, `BlendMode`, `Mesh`, `Font`, `Canvas`, `Shader` |
| `audio`   | Audio playback: rodio integration, mixer, sources, volume/pitch/pan       | `AudioMixer`, `AudioSource`, `AudioBus`                                                     |
| `physics` | Physics simulation: rapier2d, rigid bodies, colliders, raycasts           | `PhysicsWorld`, `RigidBody`, `Collider`                                                     |
| `input`   | Keyboard, mouse, gamepad input state and events                           | `InputState`, `Key`, `MouseButton`                                                          |
| `image`   | CPU image loading/decoding, pixel operations, texture data, atlas packing | `ImageData`, `Texture`, `TextureAtlas`                                                      |
| `window`  | Window management: winit integration, fullscreen, cursor                  | `WindowConfig`, `WindowHandle`                                                              |
| `camera`  | Viewport transforms, scale modes, coordinate mapping                      | `Camera2D`, `ScaleMode`                                                                     |
| `light`   | 2D lighting data: light descriptors, occluder polygons                    | `Light2D`, `Occluder`, `ShadowFilter`                                                       |
| `effect`  | Post-processing effect descriptors, overlay systems                       | `PostFxEffect`, `PostFxEffectType`, `ShaderPassDescriptor`                                  |

### Feature Systems

| Module       | Responsibility                                                                                         | Key Types                                                                                            |
| ------------ | ------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| `ecs`        | Entity-component-system: entities with components, queries                                             | `Entity`, `Component`, `System`                                                                      |
| `scene`      | Scene stack: push/pop/switch scene management                                                          | `Scene`, `SceneManager`, `Transition`                                                                |
| `animation`  | Sprite animation: frame sequences, playback control                                                    | `Animation`, `AnimationPlayer`                                                                       |
| `tween`      | Value interpolation: tweens, easing, sequencing                                                        | `Tween`, `Easing`, `TweenSequence`                                                                   |
| `particle`   | Particle systems: emitters, instances, render command generation                                       | `ParticleSystem`, `ParticleInstance`, `ParticleShape`                                                |
| `tilemap`    | Tile-based maps: tile layers, tile sets, collision                                                     | `TileMap`, `TileLayer`, `TileSet`                                                                    |
| `parallax`   | Parallax scrolling: multi-layer backgrounds                                                            | `ParallaxLayer`                                                                                      |
| `minimap`    | Minimap rendering: terrain, fog-of-war, markers                                                        | `Minimap`, `MinimapObject`                                                                           |
| `raycaster`  | 2.5D raycasting: DDA traversal, textured-quad scene generation for first-person tile worlds            | `Raycaster2D`, `RayHit`, `RaycasterScene`, `WallQuad`, `FloorQuad`, `CeilingQuad`, `BillboardSprite` |
| `ui`         | GUI widgets: buttons, panels, text, layout                                                             | `Widget`, `GuiContext`, `WidgetBase`                                                                 |
| `terminal`   | In-game terminal: command history, text rendering                                                      | `Terminal`, `TerminalState`                                                                          |
| `ai`         | Game AI: FSM, behaviour trees, steering, blackboard                                                    | `FSM`, `BehaviourTree`, `Blackboard`                                                                 |
| `pathfind`   | Pathfinding: A*, graph search, HPA                                                                     | `AStar`, `PathResult`                                                                                |
| `save`       | Save/load game state: serialisation, slots                                                             | `SaveManager`, `SaveSlot`                                                                            |
| `mods`       | Mod loading: mod manifests, sandboxed execution                                                        | `ModManager`, `Mod`                                                                                  |
| `i18n`       | Internationalisation: string tables, locale switching                                                  | `I18n`, `Locale`                                                                                     |
| `automation` | Test automation: simulated input, scripted sequences                                                   | `Simulator`, `AutoAction`                                                                            |
| `sprite`     | CPU sprite data: sprite sheets, batches, nine-slice (planned — see render-command-architecture.md §13) | `Sprite`, `SpriteSheet`, `SpriteBatch`, `NineSlice`                                                  |
| `spine`      | Spine animation runtime integration                                                                    | `SpineInstance`                                                                                      |

### Edge / Integration

| Module        | Responsibility                                                | Key Types                    |
| ------------- | ------------------------------------------------------------- | ---------------------------- |
| `app`         | Composition root: boot, winit event loop, frame orchestration | `App`, `AppBuilder`          |
| `lua_api`     | Scripting bridge: registers all `lurek.*` Lua APIs            | `register()` per sub-module  |
| `devtools`    | Developer overlay: FPS counter, debug draw, inspector         | `DevTools`                   |
| `debugbridge` | Remote debug server: TCP/WebSocket debug protocol             | `DebugBridge`, `DebugServer` |
| `docs`        | Documentation generation support                              | `DocEntry`, `DocReport`      |
| `pipeline`    | Asset pipeline utilities                                      | Pipeline stages              |
| `bin`         | Binary entry points, CLI arg parsing                          | `main()`                     |

### Lunasome (library/)

Pure-Lua gameplay libraries. Each consumes only public `lurek.*` APIs:

`battle` · `cardgame` · `combat` · `crafting` · `dialog` · `doll` ·
`economy` · `inventory` · `item` · `province_map` · `quest` · `stats`

---

## Module Internal File Structure Standard

Every `src/<module>/` directory in Lurek2D follows a standard internal
structure. Consistency across all modules is a **binding requirement** —
not a suggestion. This standard flows from Philosophy Rules 7 (split by
reason to change), 12 (bindings are thin), 13 (tests follow responsibility),
and 15 (optimise for readability). This document is the canonical home;
render-command-architecture.md links here for render-module specifics.

### Required Files

Every module MUST have:

| File                                    | Purpose                         | Rule                                                                                                                                        |
| --------------------------------------- | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `mod.rs`                                | Module declaration + re-exports | **THIN** — only `pub mod`, `pub use`, and `//!` module-level doc comment. No functions, no struct definitions, no logic. Target: ≤30 lines. |
| `AGENT.md` *(retired — see note below)* | Historical AI agent overview    | Retired; per-module context lives in [docs/specs/<module>.md](../specs/).                                                                   |

> **Note:** `AGENT.md` files under `src/<module>/` are retired. Module
> context now lives in [docs/specs/<module>.md](../specs/). The validator
> `tools/validate/validate_module_coverage.py` flags any remaining
> `AGENT.md` as a legacy failure.

### Standard Optional Files

Use these names when needed. The file name is **standardised** — do not
invent alternatives (`helpers.rs`, `utils.rs`, `misc.rs` are banned).

| File           | Purpose                                          | When to Use                                                                                                                                                    |
| -------------- | ------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `<primary>.rs` | Main logic — algorithms, state, methods          | Always, unless `mod.rs` alone is sufficient (leaf modules with one type). Named after the module's primary concept (e.g. `emitter.rs`, `dda.rs`, `widget.rs`). |
| `types.rs`     | Public data types (structs, enums, traits)       | When the module exports 5+ public types. Fewer → define in `<primary>.rs`.                                                                                     |
| `draw.rs`      | `draw_to_image()` debug/test CPU pixel utilities | Only for modules that need CPU-side pixel rendering for testing or evidence. May import `crate::image::ImageData`. NOT the production render path.             |
| `builder.rs`   | Builder pattern for complex construction         | When a primary type has 5+ fields with defaults.                                                                                                               |

### Key Rules

1. **mod.rs is a switchboard, not a workshop** — only `pub mod`, `pub use`, `//!` doc.
2. **No `impl LuaUserData` in domain modules** — all Lua bindings live in `src/lua_api/`.
3. **No `use wgpu::*` in domain modules** — only `src/render/gpu_renderer.rs` and `src/render/shader.rs` touch wgpu.
4. **Every `pub` item has a `///` doc comment** — verified by `python tools/docs/collect_docs.py --report-missing` (constraint Q-05).
5. **Private helpers tested inline** — `#[cfg(test)] mod tests { ... }` in the source file where the helper is defined.
6. **Integration/contract tests in `tests/`** — not inside the module.

### mod.rs — The Thin Declaration Rule

**Correct** `mod.rs`:

```rust
//! Particle system — CPU-side emitter simulation and instance generation.

pub mod emitter;

pub use emitter::{ParticleSystem, ParticleInstance, ParticleShape};
```

**Wrong** `mod.rs`:

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

### Anti-Patterns

| Problem                                            | Fix                                                      |
| -------------------------------------------------- | -------------------------------------------------------- |
| Fat `mod.rs` (functions, structs, >30 lines)       | Move to `<primary>.rs`, keep `mod.rs` as re-export.      |
| Business logic in `lua_api` (>10 lines per method) | Extract to domain module, call from `lua_api`.           |
| `impl LuaUserData` in `src/<module>/`              | Move to `src/lua_api/<module>_api.rs`.                   |
| Missing docstrings                                 | Add `///` — violation of Q-05.                           |
| `use wgpu::*` in non-render module                 | Domain modules are GPU-free (Zen Rules 3, 9).            |
| Invented file names (`helpers.rs`, `utils.rs`)     | Use standard names: `types.rs`, `draw.rs`, `builder.rs`. |

---

## Boot Sequence

```
CLI args
  │
  ▼
Config::load_from_conf_lua()
  │  ← conf.toml (preferred) or conf.lua (legacy fallback)
  │     Reads: window size, title, modules, vsync, physics settings
  │     Returns: Config struct
  ▼
App::new(config)
  │  ├─ winit: create window (EventLoop + Window)
  │  ├─ wgpu:  request adapter → device → surface → GpuRenderer
  │  ├─ rodio: create OutputStream → AudioMixer
  │  ├─ GameFS: mount game directory, set up sandbox
  │  └─ SharedState: initialise all resource pools (empty SlotMaps)
  ▼
create_lua_vm(shared_state)
  │  ├─ Create LuaJIT VM (mlua::Lua::new())
  │  ├─ Create `lurek` global table
  │  ├─ Register 35+ API modules via lua_api::register_all()
  │  │   Each calls: pub fn register(lua, lurek_table, state) -> LuaResult<()>
  │  └─ Load + execute main.lua
  ▼
Callbacks fire:
  │  ├─ lurek.init(config)     ← game initialisation
  │  └─ lurek.ready()          ← first-frame resources loaded
  ▼
winit event loop starts
  │  └─ Frame loop runs until quit (see Game Loop below)
```

### Boot Invariants

- No GPU draw calls before `GpuRenderer` is fully initialised
- No Lua execution before all `lurek.*` modules are registered
- `conf.toml` is read first; if absent, `conf.lua` runs in a temporary sandboxed Lua VM (legacy fallback)
- If neither `conf.toml` nor `conf.lua` is present, defaults apply (800×600 window, all modules enabled)
- If no game directory is provided, the engine shows the splash screen

---

## Game Loop and Frame Model

Every frame follows a fixed callback sequence. All callbacks are **optional**
— an empty `main.lua` is a valid game.

```
┌─ FRAME START ─────────────────────────────────────────────────┐
│                                                                │
│  1. Input polling (winit events → InputState)                  │
│     ├─ lurek.keypressed(key, scancode, isrepeat)               │
│     ├─ lurek.keyreleased(key, scancode)                        │
│     ├─ lurek.mousepressed(x, y, button)                        │
│     ├─ lurek.mousereleased(x, y, button)                       │
│     ├─ lurek.mousemoved(x, y, dx, dy)                          │
│     ├─ lurek.wheelmoved(dx, dy)                                │
│     └─ lurek.textinput(text)                                   │
│                                                                │
│  2. lurek.process(dt)                                          │
│     Game logic, animation updates, AI ticks                    │
│                                                                │
│  3. lurek.process_physics(dt)       [fixed timestep]           │
│     Physics stepping, collision response                       │
│     May fire multiple times per frame to catch up              │
│                                                                │
│  4. lurek.process_late(dt)                                     │
│     Post-physics logic: camera follow, constraint resolution   │
│                                                                │
│  5. lurek.draw()                                               │
│     Push RenderCommands for WORLD layer                        │
│     Domain modules auto-collect: particle, tilemap, etc.       │
│                                                                │
│  6. lurek.draw_ui()                                            │
│     Push RenderCommands for UI layer (drawn on top of world)   │
│     UI auto-collect: gui widgets, terminal overlay             │
│                                                                │
│  7. Auto-collect from domain modules                           │
│     ├─ particle.build_render_commands()                         │
│     ├─ tilemap.generate_render_commands() (planned)             │
│     ├─ ui.generate_render_commands() (planned)                  │
│     └─ ... other modules                                       │
│                                                                │
│  8. GpuRenderer::render_frame(commands, lights, postfx, ...)   │
│     Single GPU submission point                                │
│                                                                │
│  9. lurek.resize(w, h)              [on window resize only]    │
│  10. lurek.focus(focused)           [on focus change only]     │
│                                                                │
└─ FRAME END ───────────────────────────────────────────────────┘
```

### Timing

- `dt` is wall-clock delta time in seconds (f64)
- `process_physics` uses **fixed timestep** accumulation — the physics
  callback may fire 0, 1, or multiple times per frame
- Frame limiting is handled by wgpu present mode (VSync) or manual cap

---

## Callback Contract

Every callback is **optional**. The engine checks whether the Lua global
function exists before calling it. An empty `main.lua` is valid.

| Callback                | Signature                   | When Called                              | Purpose                                        |
| ----------------------- | --------------------------- | ---------------------------------------- | ---------------------------------------------- |
| `lurek.init`            | `(config)`                  | Once, after VM creation                  | Game initialisation: load assets, set up state |
| `lurek.ready`           | `()`                        | Once, after init                         | First-frame resources are ready                |
| `lurek.process`         | `(dt)`                      | Every frame                              | Game logic, animation, AI                      |
| `lurek.process_physics` | `(dt)`                      | Fixed timestep (may fire 0..N per frame) | Physics stepping, collision response           |
| `lurek.process_late`    | `(dt)`                      | Every frame, after physics               | Camera follow, constraint resolution           |
| `lurek.draw`            | `()`                        | Every frame                              | Push RenderCommands for world layer            |
| `lurek.draw_ui`         | `()`                        | Every frame                              | Push RenderCommands for UI layer               |
| `lurek.keypressed`      | `(key, scancode, isrepeat)` | On key down                              | Keyboard input                                 |
| `lurek.keyreleased`     | `(key, scancode)`           | On key up                                | Keyboard release                               |
| `lurek.mousepressed`    | `(x, y, button)`            | On mouse button down                     | Mouse click                                    |
| `lurek.mousereleased`   | `(x, y, button)`            | On mouse button up                       | Mouse release                                  |
| `lurek.mousemoved`      | `(x, y, dx, dy)`            | On mouse movement                        | Mouse tracking                                 |
| `lurek.wheelmoved`      | `(dx, dy)`                  | On scroll wheel                          | Scroll input                                   |
| `lurek.textinput`       | `(text)`                    | On text entry                            | Text input (IME-aware)                         |
| `lurek.resize`          | `(w, h)`                    | On window resize                         | Layout recalculation                           |
| `lurek.focus`           | `(focused)`                 | On focus change                          | Pause/resume                                   |
| `lurek.quit`            | `() → bool`                 | On close request                         | Return `true` to cancel quit                   |

### Callback Ordering Within a Frame

Input callbacks fire first (in the order events arrive from winit), then
`process(dt)` → `process_physics(dt)` → `process_late(dt)` → `render()` →
`render_ui()`. Resize and focus callbacks fire between frames when the
relevant winit event occurs.

---

## State Architecture

All engine state is centralised in a single `SharedState` struct, shared
between Lua closures and the engine loop via `Rc<RefCell<SharedState>>`.

### Design Rules (from Zen Rule 10)

- **CPU state and runtime resources must stay separate.**
  Serialisable game state must not require a GPU handle, OS window, or VM
  reference. State types belong in domain modules; runtime resources belong
  in `SharedState` resource pools.

- **No GPU handles in SharedState fields.** The renderer accesses GPU
  resources through its own internal state. SharedState holds CPU-side
  descriptors (e.g., `Canvas` metadata, `Light2D` descriptors) and resource
  keys (handles into the renderer's pools).

### SharedState Contents

```rust
pub struct SharedState {
    // Configuration
    pub config: Config,

    // Resource pools (typed SlotMaps)
    pub textures:       SlotMap<TextureKey, Texture>,
    pub fonts:          SlotMap<FontKey, Font>,
    pub meshes:         SlotMap<MeshKey, Mesh>,
    pub canvases:       SlotMap<CanvasKey, Canvas>,
    pub shaders:        SlotMap<ShaderKey, Shader>,
    pub sprite_batches: SlotMap<SpriteBatchKey, SpriteBatch>,
    pub particles:      SlotMap<ParticleKey, ParticleSystem>,

    // Subsystem state
    pub input:        InputState,
    pub audio_mixer:  AudioMixer,
    pub physics:      PhysicsWorld,
    pub timer_state:  TimerState,
    pub scene_stack:  SceneManager,

    // Rendering data (CPU side)
    pub camera:       Camera2D,
    pub lights:       Vec<Light2D>,
    pub occluders:    Vec<Occluder>,
    pub postfx_stack: Vec<PostFxEffect>,

    // Game filesystem
    pub game_fs:      GameFS,
}
```

### Access Pattern

```rust
// Clone Rc before moving into Lua closures
let state = state.clone();
tbl.set("doThing", lua.create_function(move |_, args| {
    let s = state.borrow();      // immutable borrow
    // or
    let mut s = state.borrow_mut(); // mutable borrow
    Ok(())
})?)?;
```

**Borrow rules**: Never hold a `borrow()` or `borrow_mut()` across a Lua
callback invocation — this will panic due to re-entrant borrowing.

---

## Resource Management

All engine resources (textures, fonts, meshes, canvases, shaders, sprite
batches, particle systems) are stored in typed `SlotMap` pools inside
`SharedState`.

### Resource Key Types

Defined in `src/runtime/resource_keys.rs`:

| Key Type         | Resource                          | Stored In                     |
| ---------------- | --------------------------------- | ----------------------------- |
| `TextureKey`     | GPU texture handle + CPU metadata | `SharedState::textures`       |
| `FontKey`        | Font atlas + glyph metrics        | `SharedState::fonts`          |
| `MeshKey`        | Vertex + index buffers            | `SharedState::meshes`         |
| `CanvasKey`      | Off-screen render target          | `SharedState::canvases`       |
| `ShaderKey`      | Custom WGSL shader                | `SharedState::shaders`        |
| `SpriteBatchKey` | Batched sprite collection         | `SharedState::sprite_batches` |
| `ParticleKey`    | Particle emitter system           | `SharedState::particles`      |

### Lifecycle

1. **Create** — Lua calls `lurek.renders.newImage("path")` →
   `lua_api` loads image via `src/image/`, creates GPU texture via renderer,
   stores in SlotMap, returns key to Lua as userdata.
2. **Use** — Lua passes key to draw functions → `RenderCommand` stores key →
   renderer resolves key to GPU resource at draw time.
3. **Destroy** — Lua drops the key (GC or explicit `release()`) →
   SlotMap slot freed, GPU resource released next frame.

### Stale Key Safety

SlotMap keys include a generation counter. If a key is used after its
resource was freed, the SlotMap returns `None` rather than a dangling
reference. The engine logs a warning and skips the draw call.

---

## Rendering Pipeline

The rendering pipeline is defined in full detail in
[render-command-architecture.md](render-command-architecture.md).

### Summary: Three-Layer Model

1. **Layer 1 — CPU Domain Modules**: Prepare data and push `RenderCommand`
   variants into a queue. No GPU calls.
2. **Layer 2 — App Coordinator** (`src/app/`): Orchestrates the frame —
   polls input, runs callbacks, collects commands, passes everything to the
   renderer.
3. **Layer 3 — GPU Renderer** (`src/render/gpu_renderer.rs`): The ONLY code
   that issues wgpu draw calls. Receives `Vec<RenderCommand>` plus structured
   data (lights, post-FX) and produces the frame.

### Key Facts

- `RenderCommand` is a flat enum with 46+ variants (draw primitives,
  transform stack, batching, stencil, post-FX, etc.)
- GPU code is confined to `src/render/gpu_renderer.rs` and
  `src/render/shader.rs` — no other module imports wgpu
- Light data (`Light2D`, `Occluder`) and post-FX data (`PostFxEffect`)
  flow as structured data alongside the command list — they are NOT
  `RenderCommand` variants
- `camera/`, `effect/`, `light/` are **top-level CPU domain modules**,
  not subdirectories of `src/render/`

### Render Module Refactoring (Planned)

See [render-command-architecture.md §13 — Render Module Refactoring
Plan](render-command-architecture.md#render-module-refactoring-plan) for the
extraction of CPU-only types from `src/render/`:

- `Color` → `src/math/` (math primitive used by all modules)
- `Sprite`, `SpriteSheet`, `SpriteBatch`, `NineSlice` → `src/sprite/` (new)
- `Texture`, `TextureAtlas` → `src/image/` (CPU decode/packing)

---

## Lua Binding Architecture

### Design Rules (from Zen Rule 12, constraints C-01 through C-05)

1. **All bindings under `lurek.*`** — no bare globals, no alternative
   top-level tables (C-01)
2. **One register function per module** with standard signature (C-02):
   ```rust
   pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>
   ```
3. **Sensible defaults** — never require params a beginner would always pass
   the same value (C-03)
4. **All callbacks optional** — empty `main.lua` is valid (C-04)
5. **Synchronous from Lua's perspective** — async work in Rust threads via
   `Channel` (C-05)

### File Organisation

| Location                      | Contains                                                                         | Must NOT Contain                              |
| ----------------------------- | -------------------------------------------------------------------------------- | --------------------------------------------- |
| `src/<module>/`               | Pure Rust: algorithms, data types, state                                         | `mlua` imports, `impl LuaUserData`, Lua types |
| `src/lua_api/<module>_api.rs` | `pub fn register()`, Lua wrapper structs, `impl LuaUserData`, `add_method` calls | Business logic (>10 lines), algorithms        |

### Thin Wrapper Pattern

The `lua_api` file is **glue code only**. It:
1. Clones `Rc<RefCell<SharedState>>`
2. Creates a namespace table
3. Registers functions that call domain module methods
4. Returns `Ok(())`

```rust
// src/lua_api/particle_api.rs (CORRECT — thin wrapper)
let s = state.clone();
tbl.set("emit", lua.create_function(move |_, (x, y, count): (f32, f32, u32)| {
    s.borrow_mut().particle_sys.emit(x, y, count);
    Ok(())
})?)?;
```

**Thin wrapper test**: If a closure body exceeds ~10 lines, the logic belongs
in the domain module. Extract a `pub fn` on the domain type and call it.

### Registration Flow

```
App::new() → create_lua_vm()
  └─ lua_api::register_all(lua, lurek_table, state)
       ├─ graphics_api::register()      → lurek.renders.*
       ├─ physics_api::register()       → lurek.physics.*
       ├─ audio_api::register()         → lurek.audio.*
       ├─ input_api::register()         → lurek.input.*
       ├─ camera_api::register()        → lurek.camera.*
       ├─ timer_api::register()         → lurek.timer.*
       ├─ particle_api::register()      → lurek.particle.*
       ├─ tilemap_api::register()       → lurek.tilemap.*
       ├─ ui_api::register()            → lurek.ui.*
       ├─ scene_api::register()         → lurek.scene.*
       ├─ ai_api::register()            → lurek.ai.*
       ├─ ... (35+ modules total)
       └─ core callbacks registered:
            lurek.init, lurek.ready, lurek.process, etc.
```

### Lua API Docstring Format

Lua API files use inline annotations, NOT rustdoc `# Parameters` sections:

```rust
// ── funcName ─────
/// One-sentence description.
/// @param name : type
/// @return type
let s = state.clone();
tbl.set("funcName", lua.create_function(move |_, arg: Type| {
    Ok(s.borrow().method(arg))
})?)?;
```

Gold standard: `src/lua_api/timer_api.rs`.

---

## Input Pipeline

```
winit::Event::WindowEvent
  │
  ├─ KeyboardInput → InputState.keys
  │   └─ Fire lurek.keypressed / lurek.keyreleased
  │
  ├─ MouseInput → InputState.mouse_buttons
  │   └─ Fire lurek.mousepressed / lurek.mousereleased
  │
  ├─ CursorMoved → InputState.mouse_position
  │   └─ Fire lurek.mousemoved(x, y, dx, dy)
  │
  ├─ MouseWheel → Fire lurek.wheelmoved(dx, dy)
  │
  └─ ReceivedCharacter → Fire lurek.textinput(text)
```

`InputState` stores current-frame and previous-frame state for every key
and mouse button — enabling `isDown()`, `isPressed()` (just pressed this
frame), and `isReleased()` queries from Lua.

Gamepad input uses the same pattern: poll → update state → fire callbacks.

---

## Audio Pipeline

```
Lua: lurek.audio.play("sound.ogg")
  │
  ▼
audio_api.rs → AudioMixer::play(path)
  │
  ├─ GameFS resolves path → load audio file (OGG/WAV/MP3/FLAC)
  ├─ rodio::Decoder decodes → PCM samples
  ├─ Route to AudioBus (master / music / sfx)
  └─ rodio::Sink plays samples through OutputStream
```

### Key Concepts

- **AudioBus**: Named output channel (master, music, sfx, voice). Each has
  independent volume. Master bus applies final gain.
- **Static source**: Fully decoded in memory. For short SFX.
- **Streaming source**: Decoded on-the-fly. For music/ambient.
- **Volume/Pitch/Pan**: Per-source controls, composited with bus volume.

---

## Physics Pipeline

```
Lua: lurek.physics.newBody("dynamic", x, y)
  │
  ▼
physics_api.rs → PhysicsWorld::create_body(...)
  │
  └─ rapier2d: RigidBodyBuilder + ColliderBuilder → add to RigidBodySet
```

### Frame Integration

1. `lurek.process_physics(dt)` fires (fixed timestep)
2. `PhysicsWorld::step(dt)` advances rapier2d simulation
3. Collision events collected → fire Lua collision callbacks
4. `lurek.process_late(dt)` fires — game reads updated positions

### Key Concepts

- **Body types**: Static (immovable), Dynamic (simulated), Kinematic (script-controlled)
- **Collider shapes**: Circle, Rectangle, Polygon, Capsule, Segment
- **Joints**: RevoluteJoint, PrismaticJoint, FixedJoint, SpringJoint
- **Raycasting**: `lurek.physics.raycast(x1, y1, x2, y2)` → hit results
- **Collision events**: `lurek.physics.onCollision(callback)` → begin/end

---

## Threading Model

```
Main Thread (LuaJIT VM + engine loop)
  │
  ├─ lurek.thread.spawn("worker.lua", channel)
  │   └─ Creates new OS thread with its own LuaJIT VM
  │      Worker VM has LIMITED lurek.* API (no GPU, no audio, no input)
  │      Communication via Channel (typed MPMC)
  │
  └─ lurek.thread.channel() → Channel userdata
       ├─ channel:push(value)   [Lua-serialisable values only]
       └─ channel:pop() → value or nil
```

### Rules (from constraint B-04)

- LuaJIT VMs are **single-threaded** — never share VM state across threads
- Worker VMs get their own fresh `Lua::new()` with limited API surface
- `Channel` is the ONLY communication mechanism between VMs
- Values sent through Channel must be Lua-serialisable (no userdata, no functions)
- Main thread polls channels during `process(dt)` — no blocking

---

## Filesystem and Virtual FS

```
GameFS mount structure:
  /game/        ← game directory (main.lua lives here)
  /engine/      ← engine embedded assets (splash, fonts)
  /save/        ← per-game save directory
  /temp/        ← temporary files (cleared on exit)
```

### Security (path traversal guards)

- All file operations go through `GameFS`, never raw `std::fs`
- Paths are normalised and validated — `../` traversal is rejected
- Writes are restricted to `/save/` and `/temp/` — game code cannot
  write to `/game/` or `/engine/`
- Symlinks are not followed outside the sandbox

### Lua API

```lua
lurek.filesystem.read("data/levels.json")     -- read from /game/
lurek.filesystem.write("save/progress.dat", data)  -- write to /save/
lurek.filesystem.exists("sprites/hero.png")   -- check /game/
lurek.filesystem.list("levels/")              -- directory listing
```

---

## Window Management

```
App::new(config)
  └─ winit::WindowBuilder
       ├─ title: config.window.title
       ├─ size: config.window.width × config.window.height
       ├─ resizable: config.window.resizable
       ├─ fullscreen: config.window.fullscreen
       └─ icon: assets/icon.png (embedded)
```

### Scale Modes (Camera)

| Mode            | Behaviour                                          |
| --------------- | -------------------------------------------------- |
| `stretch`       | Fill window, ignore aspect ratio                   |
| `letterbox`     | Fit to window, black bars to preserve aspect ratio |
| `pixel_perfect` | Integer scaling only, centred                      |
| `expand`        | Design resolution fills, extra space visible       |

Scale mode is set via `conf.toml` (or legacy `conf.lua`) or `lurek.camera.setScaleMode()`.

---

## Configuration System

### conf.toml / conf.lua (game-authored configuration)

```lua
function lurek.conf(config)
    config.window.title = "My Game"
    config.window.width = 1280
    config.window.height = 720
    config.window.vsync = true
    config.window.resizable = true

    config.modules.physics = true
    config.modules.audio = true
    config.modules.network = false
end
```

`conf.toml` is parsed at startup (preferred format). `conf.lua` is a legacy alternative executed in a temporary Lua VM.
It returns a `Config` struct that drives engine initialisation.

### Config Struct

Defined in `src/runtime/config.rs`. Fields include:

- `window` — title, width, height, fullscreen, vsync, resizable, min_size
- `modules` — boolean flags for optional subsystems (physics, audio, network, etc.)
- `render` — MSAA samples, max texture size, target FPS
- `physics` — gravity, fixed timestep, iterations

### Fallback

If no configuration file is found, all defaults apply: 800×600 window, all modules
enabled, 60 FPS target.

### Format Rule (B-05)

TOML is the human-authored config format for engine tools and project
manifests. JSON for external interop. No YAML anywhere.

---

## Error Handling and Recovery

### Error Types

```rust
pub enum EngineError {
    Lua(mlua::Error),       // Lua runtime error
    Render(wgpu::Error),    // GPU/wgpu error
    Audio(rodio::Error),    // Audio playback error
    Physics(String),        // Physics engine error
    Io(std::io::Error),     // File I/O error
    Config(String),         // Configuration error
    Asset(String),          // Asset loading error
}
```

### Error Flow

1. **Domain modules** return `Result<T, EngineError>` or domain-specific errors
2. **lua_api** converts to `LuaError` at the boundary:
   `result.map_err(LuaError::external)`
3. **Lua scripts** receive error as a Lua error (pcall-catchable)
4. **Uncaught Lua errors** are logged and the frame continues (engine does
   not crash on a single Lua error)

### Rules

- Never `panic!` in engine code — convert to `Result` or log + skip
- Never `unwrap()` on fallible operations — use `?` or match
- `// SAFETY:` comment required for every `unsafe` block
- Descriptive error messages that include the failing path/key/value

---

## Quality Gates

These are **binding constraints** from [philosophy.md](philosophy.md) §
Quality Gate Constraints:

| ID       | Gate                                   | Command                                              |
| -------- | -------------------------------------- | ---------------------------------------------------- |
| **Q-01** | All tests pass                         | `cargo test`                                         |
| **Q-02** | No clippy warnings                     | `cargo clippy -- -D warnings`                        |
| **Q-03** | New public Rust API → integration test | Manual review                                        |
| **Q-04** | New `lurek.*` function → Lua BDD test  | Manual review                                        |
| **Q-05** | No undocumented public items           | `python tools/docs/collect_docs.py --report-missing` |

### Full Quality Gate Command

```bash
cargo test && cargo clippy -- -D warnings
```

This must pass before every merge.

---

## Technology Stack

| Component      | Crate    | Version      | Purpose                                    |
| -------------- | -------- | ------------ | ------------------------------------------ |
| Language       | Rust     | stable ≥1.78 | Engine implementation                      |
| Scripting      | mlua     | 0.9          | LuaJIT binding (primary), Lua 5.4 fallback |
| Rendering      | wgpu     | 22           | GPU abstraction (Vulkan/DX12/Metal)        |
| Windowing      | winit    | 0.30         | Window creation and event loop             |
| Physics        | rapier2d | 0.32         | 2D rigid body simulation                   |
| Audio          | rodio    | 0.17         | Audio playback and mixing                  |
| Font rendering | fontdue  | 0.9          | Font rasterisation                         |
| Image loading  | image    | latest       | PNG/JPEG/GIF decode                        |

### Cargo Feature Flags

| Flag                | Effect                                            |
| ------------------- | ------------------------------------------------- |
| `lua-jit` (default) | Link LuaJIT via mlua — primary runtime            |
| `lua54`             | Link Lua 5.4 via mlua — non-shipping dev fallback |

---

## Repository File Structure

```
lurek2d/
├── src/                    Rust source — all five module groups
│   ├── lib.rs              Crate root (mod declarations)
│   ├── main.rs             Binary entry point (CLI → App)
│   ├── <module>/           One directory per module
│   │   ├── mod.rs          Thin declarations + re-exports
│   │   ├── <primary>.rs    Main logic
│   │   └── AGENT.md        AI agent overview
│   └── lua_api/            Scripting bridge (one <module>_api.rs per module)
│
├── content/
│   ├── demos/              Playable Lua game demos
│   ├── examples/           Single-file API usage scripts
│   ├── library/            Lunasome — pure-Lua standard libraries
│   └── plugins/            Plugin examples
│
├── tests/
│   ├── rust/               Rust tests (unit, stress, golden, config, security, ext)
│   └── lua/                Lua BDD tests (unit, integration, content, stress, security)
│
├── docs/
│   ├── architecture/       philosophy.md, engine-architecture.md, render-command-architecture.md, test-framework.md
│   ├── specs/              One <module>.md per src/<module>/
│   ├── API/                Generated API references (lua-api.md, rust-api.md)
│   └── CHANGELOG.md        Version history
│
├── tools/                  Permanent CLI scripts (docs, audit, fix, validate, dist)
├── assets/                 Engine assets (splash, icon, fonts)
├── extensions/vscode/      VS Code extension (MCP, IntelliSense, webview)
├── .github/                CAG layer (agents, skills, prompts, system prompt)
├── work/                   Session folders (current + archive)
├── Cargo.toml              Crate manifest
└── build.rs                Build script (asset watching)
```

---

## Planned Build Variants

Future Cargo feature flag work to enable modular builds:

| Variant      | Contents                                                                    |
| ------------ | --------------------------------------------------------------------------- |
| **baseline** | Foundations + Core Runtime + Edge/Integration (lua_api, app)                |
| **core**     | baseline + Platform Services (render, audio, physics, input, image, window) |
| **extended** | core + Feature Systems (all game-domain modules)                            |
| **lunasome** | extended + shipped `library/` Lua libraries                         |

Purpose: Users who only need rendering and input can build `core`.
Users who want the full engine experience use `extended` or `lunasome`.

These variants are **planned, not yet implemented.** Current builds include
all modules.
