# Luna2D — Architecture

> **Source of truth** for module structure, dependency rules, and the active layer model.
> Consult this before creating new modules, changing cross-module imports, or documenting subsystem boundaries.

---

## Design Philosophy

Luna2D is a **single-executable, Lua-driven 2D game engine**. Rust owns the platform, GPU, physics simulation, threading, and other engine-managed resources. Lua scripts own game logic through the public `luna.*` API.

See [`docs/zen-of-luna.md`](zen-of-luna.md) for first principles.
See [`docs/design-assumptions.md`](design-assumptions.md) for binding constraints.

---

## Active Layer Model

Luna2D uses an active **four-layer runtime model** plus one bridge layer:

| Layer | Path | Role |
|---|---|---|
| **Baseline** | `src/math/`, `src/engine/` | Always-on runtime substrate |
| **Bridge** | `src/lua_api/` | Registers the public `luna.*` API; not a numbered tier |
| **Tier 1** | `src/` | Core engine subsystems built on Baseline |
| **Tier 2** | `src/` | Reusable engine extensions built on Baseline + Tier 1 |
| **Tier 3** | `library/` | Lunasome: pure-Lua gameplay libraries built on the public Lua API |

This is a **logical dependency model**, not a filesystem grouping scheme. Most Rust engine modules still live in flat `src/<module>/` directories. The layer contract is carried by import direction, not by nested folders.

### Boundary Rules

- **Baseline** is always available. `math` remains the leaf; `engine` owns app lifecycle and shared runtime state.
- **Tier 1 Rust modules** may depend only on Baseline. No Tier 1 ↔ Tier 1 cross-imports.
- **Tier 2 Rust modules** may depend on Baseline + Tier 1. No Tier 2 ↔ Tier 2 cross-imports.
- **`lua_api`** is the bridge that imports engine layers and exposes `luna.*`. Domain Rust modules must never import it.
- **Tier 3 Lunasome** lives in `library/` and consumes only public Lua-facing APIs. Lower engine layers do not depend on Tier 3.
- **Examples** consume the public Lua surface but are not part of the numbered layer model.

### Dependency Graph

```
game scripts and examples/
            │
            ▼
library/  (Tier 3: Lunasome, pure Lua)
            │ consumes public API
            ▼
      src/lua_api/  (bridge layer)
            │ binds runtime to Lua
            ▼
      Tier 2 extensions
            │
            ▼
   Tier 1 core subsystems
            │
            ▼
Baseline: src/math/ + src/engine/
```

### Lunasome Contract

Tier 3 is **Lunasome**, the pure-Lua standard-library layer in `library/`.

- It is shipped alongside the engine, not embedded in the Rust binary.
- It is intended for **genre-specific or gameplay-domain-specific** libraries.
- It consumes public `luna.*` APIs rather than Rust internals.
- It should stay as self-contained as practical; avoid unnecessary cross-library dependency chains.

---

## Baseline

### `math/` — Foundational Algorithms

`math` is the leaf of the dependency graph. It has no Luna2D dependencies and provides:

- Vectors (`Vec2`, `Vec3`), matrices (`Mat3`), `Rect`
- Noise, easing, interpolation
- Color-space utilities and geometry helpers
- `Color` (sRGB `[f32; 4]`) — moved here from `src/graphics/srgb.rs` during the graphics-module-split session as a pure math value type with no rendering dependency

All other layers may import `math`.

### `engine/` — Runtime Lifecycle

`engine` provides the application skeleton: `App`, `Config`, `EngineError`, `SharedState`, `WindowState`, and `FullscreenType`.

- It owns startup, bootstrapping, and the main event loop.
- It is the top-level Rust orchestrator.
- `SharedState` is defined here as the central runtime state shared with Lua closures.

---

## Bridge Layer

### `lua_api/` — Public Lua Surface

`lua_api` sits above the engine layers. It imports runtime modules and exposes them through the `luna.*` namespace.

- It is **not** a numbered tier.
- It may import Baseline, Tier 1, Tier 2, and migration-state gameplay Rust modules when needed.
- Domain Rust modules must never import `lua_api`.

Every binding module follows the registration pattern:

```rust
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>
```

---

## Tier 1 — Core Engine Subsystems

Tier 1 modules are engine-owned capabilities that sit directly on Baseline.

| Module | Path | Responsibility |
|---|---|---|
| `animation` | `src/animation/` | Sprite animation: named clips, frame pools, speed control, frame-level events |
| `audio` | `src/audio/` | Audio playback, mixers, buses, decoding |
| `automation` | `src/automation/` | Automated input / replay helpers |
| `camera` | `src/camera/` | Camera and viewport types: Camera, Camera2D, Viewport, ViewportScale |
| `compute` | `src/compute/` | Dense numerical arrays and CPU-side compute helpers |
| `data` | `src/data/` | Binary data, compression, hashing, encoding, TOML helpers |
| `entity` | `src/entity/` | Lightweight ECS primitives and entity helpers |
| `event` | `src/event/` | Event queue and polling primitives |
| `filesystem` | `src/filesystem/` | Sandboxed game filesystem and path validation |
| `graphics` | `src/graphics/` | GPU rendering pipeline, draw commands, textures, fonts, sprite batching |
| `image` | `src/image/` | CPU-side image manipulation |
| `input` | `src/input/` | Keyboard, mouse, gamepad, and touch state |
| `physics` | `src/physics/` | Rigid bodies, shapes, collisions, and queries |
| `thread` | `src/thread/` | Background Rust threads and `Channel` communication |
| `timer` | `src/timer/` | Frame timing and scheduled callback primitives |
| `window` | `src/window/` | Window lifecycle and state abstraction |

**Import rule**: Tier 1 modules may import only `crate::math::*` and `crate::engine::*`.

---

## Tier 2 — Reusable Engine Extensions

Tier 2 modules build on Baseline + Tier 1 and remain broadly useful across many game types.

| Module | Path | Responsibility |
|---|---|---|
| `ai` | `src/ai/` | Generic AI helpers: FSMs, behaviour trees, GOAP, steering |
| `dataframe` | `src/dataframe/` | Column-major tabular data structures |
| `graph` | `src/graph/` | Directed graphs, flow simulation, graph algorithms |
| `gui` | `src/gui/` | Retained-mode widget UI primitives |
| `minimap` | `src/minimap/` | Minimap extraction, FOV masking, tile sampling |
| `modding` | `src/modding/` | Mod discovery, dependency resolution, load ordering |
| `overlay` | `src/overlay/` | Per-frame overlays such as weather and ambient layers |
| `particle` | `src/particle/` | Emitter-based 2D particle systems |
| `pathfinding` | `src/pathfinding/` | Navigation grids, A*, HPA*, flow fields |
| `postfx` | `src/postfx/` | Post-processing effect data models |
| `savegame` | `src/savegame/` | Save/load orchestration and schema versioning |
| `scene` | `src/scene/` | Scene stack management and transitions |
| `tilemap` | `src/tilemap/` | Tilemaps, tilesets, map generation, coordinate helpers |

**Import rule**: Tier 2 modules may import Baseline and any Tier 1 module, but must not import other Tier 2 modules.

---

## Tier 3 — Lunasome in `library/`

Tier 3 is the **Lunasome** layer: pure-Lua gameplay libraries that live under `library/`.

Current shipped library families include:

| Library | Path | Responsibility |
|---|---|---|
| `battle` | `library/battle/` | Turn-based battle helpers |
| `cardgame` | `library/cardgame/` | Cards, decks, slots, and card pools |
| `combat` | `library/combat/` | Combat-oriented gameplay helpers |
| `crafting` | `library/crafting/` | Recipes, queues, and crafting logic |
| `dialog` | `library/dialog/` | Dialogue sequencing |
| `economy` | `library/economy/` | Gameplay resource economy helpers |
| `inventory` | `library/inventory/` | Inventory gameplay logic |
| `item` | `library/item/` | Item helpers and stack logic |
| `province_map` | `library/province_map/` | Province-map gameplay helpers |
| `quest` | `library/quest/` | Quest log and objective helpers |
| `stats` | `library/stats/` | Gameplay stat and modifier helpers |

Tier 3 is the target home for genre-specific and gameplay-specific libraries. When something can live as pure Lua on top of the public engine API, it belongs here instead of in new Rust gameplay modules.

---

## Legacy / Migration-State Rust Gameplay Modules

Several gameplay-oriented Rust modules still exist under `src/`. They remain buildable and testable, but they are **not** the active Tier 3 architecture target.

| Module | Path | Current Framing |
|---|---|---|
| `battle` | `src/battle/` | Migration-state Rust gameplay module |
| `cardgame` | `src/cardgame/` | Migration-state Rust gameplay module |
| `combat` | `src/combat/` | Migration-state Rust gameplay module |
| `crafting` | `src/crafting/` | Migration-state Rust gameplay module |
| `dialog` | `src/dialog/` | Migration-state Rust gameplay module |
| `economy` | `src/economy/` | Migration-state Rust gameplay module |
| `inventory` | `src/inventory/` | Migration-state Rust gameplay module |
| `item` | `src/item/` | Migration-state Rust gameplay module |
| `province_map` | `src/province_map/` | Migration-state Rust gameplay module |
| `quest` | `src/quest/` | Migration-state Rust gameplay module |
| `stats` | `src/stats/` | Migration-state Rust gameplay module |

Documentation should describe these as **legacy** or **migration-state** gameplay Rust code, not as the current Tier 3 layer.

---

## Physical Layout Convention

The architecture contract distinguishes between:

- **Active crate modules**: directories exported from `src/lib.rs`
- **Additional source-tree directories**: folders that may contain notes, incubating work, or future modules but are not yet part of the crate contract

Today, the active Rust module inventory is still defined by the flat `src/<module>/` layout exported from `src/lib.rs`.

### Design-Stage Directories Not Exported From `src/lib.rs`

| Folder | Intended Purpose |
|---|---|
| `src/doll/` | Paper-doll character compositing |
| `src/network/` | Networking primitives |
| `src/pipeline/` | Data transformation pipelines |
| `src/terminal/` | In-game developer terminal / REPL |

If a directory is not exported from `src/lib.rs`, it is not part of the active Rust crate surface yet.

---

## Testing and Validation Surface

Luna2D validation is split by responsibility:

### Engine Rust tests

- Registered test binaries live under `tests/unit/`, `tests/ext/`, `tests/game/`, and `tests/stress/`
- Golden coverage is registered through `tests/golden/harness.rs`
- A small number of legacy root-level Rust tests may still exist during migration; keep docs and `Cargo.toml` in sync

### Lua API and Lunasome tests

- `tests/lua/harness.rs` dispatches committed Lua test files
- `tests/lua/unit/` covers both `luna.*` bindings and `library/` modules such as `test_library_dialog.lua`
- `tests/lua/integration/`, `tests/lua/stress/`, and `tests/lua/validation/` cover broader Lua behavior

### Example validation

- `examples/` are smoke and acceptance artifacts
- Validate them with targeted runs such as `cargo run -- examples/hello_world`
- There is no dedicated `tests/examples/` Cargo harness today

---

## Boot Sequence

1. Parse CLI args → game directory path
2. `Config::load_from_conf_lua(game_dir)` — temporary Lua VM executes `conf.lua`
3. `App::new(config)` — windowing (`winit`), GPU init (`wgpu`), audio (`rodio`), filesystem (`GameFS`)
4. `create_lua_vm()` — LuaJIT VM, `luna` global table, and binding registration
5. Load and execute `main.lua` → call `luna.load()`
6. Enter the `winit` event loop → `luna.update(dt)` / `luna.draw()` each frame

---

## Key Patterns

- **`SharedState`**: `Rc<RefCell<SharedState>>` shared between Lua closures and the engine loop. Never use raw pointers or `unsafe` for state sharing.
- **DrawCommand queue**: Lua `luna.draw()` pushes `DrawCommand` variants; the renderer processes them after the callback returns.
- **SlotMap resource pools**: Generational IDs (`TextureKey`, `FontKey`, and related keys) prevent use-after-free.
- **`register()` pattern**: Each `lua_api` sub-module exposes `pub fn register(lua, luna, state)`.

---

## Planned Build Variants (Future)

The layer model supports future build variants, though they are not yet implemented at the Cargo feature level.

| Variant | Layers Included | Target Use Case |
|---|---|---|
| **Baseline** | Baseline + bridge | Minimal runtime substrate |
| **Core** | Baseline + Tier 1 + bridge | Core engine without reusable extensions |
| **Extended** | Baseline + Tier 1 + Tier 2 + bridge | General-purpose engine runtime |
| **Lunasome** | Extended + shipped `library/` content | Full runtime plus standard Lua libraries |

These variants are design intent only for now.