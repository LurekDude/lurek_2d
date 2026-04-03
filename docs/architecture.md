# Luna2D — Architecture

> **Source of truth** for module structure, dependency rules, and the tier system.
> Consult this before creating new modules, adding cross-module imports, or designing new subsystems.

---

## Design Philosophy

Luna2D is a **single-executable, Lua-driven 2D game engine**. Rust owns the platform, the GPU, the physics simulation, and all threading. Lua scripts orchestrate gameplay through the `luna.*` API. The engine never exposes internal Rust types to game scripts — only clean, consistent Lua-facing APIs.

See [`docs/zen-of-luna.md`](zen-of-luna.md) for first principles.
See [`docs/design-assumptions.md`](design-assumptions.md) for binding constraints.

---

## Module Tier System

Luna2D organises its source modules into **four tiers** plus two always-available foundation layers. The tier of a module determines which other modules it may import.

The tier system is a **logical dependency model**, not a filesystem grouping scheme. The current repository convention keeps domain modules as flat top-level folders such as `src/graphics/`, `src/particle/`, and `src/battle/`. Do not reorganise them into `src/tier1/`, `src/tier2/`, or `src/tier3/` unless the architecture contract itself changes.

### Foundation Layers (not tier-numbered)

These two layers sit outside the tier numbering because every tier can reference them:

| Layer | Path | Rule |
|-------|------|------|
| **`math`** | `src/math/` | No Luna2D dependencies. Pure algorithms. All modules may freely import it. |
| **`engine`** | `src/engine/` | Application lifecycle (`App`, `Config`, `EngineError`, `SharedState`, `WindowState`, `FullscreenType`). Tier 1 modules may import engine types. Engine itself may import ALL modules including `lua_api` (exclusively for the `create_lua_vm` bootstrap call). |

### Tier 1 — Basic Core

**Definition**: Self-contained domain modules. May only reference `math` and `engine`. No cross-imports between Tier 1 modules.

**Purpose**: Platform-level capabilities (rendering, audio, input, physics, storage). If you add a new first-class capability (e.g., 3D low-level rendering), it belongs here.

| Module | Path | Responsibility |
|--------|------|----------------|
| `graphics` | `src/graphics/` | GPU rendering pipeline (wgpu), draw commands, textures, fonts, camera |
| `audio` | `src/audio/` | Audio playback via rodio, buses, volume, spatial audio |
| `physics` | `src/physics/` | Rigid-body simulation via rapier2d, collision, raycasting |
| `input` | `src/input/` | Keyboard, mouse, gamepad, touch state |
| `timer` | `src/timer/` | Frame clock, `Clock::tick()`, scheduled callbacks |
| `filesystem` | `src/filesystem/` | Sandboxed VFS, asset loading, path validation |
| `compute` | `src/compute/` | N-dimensional numerical arrays (NdArray), pure CPU |
| `data` | `src/data/` | Binary buffers, compression, hashing, TOML parsing |
| `image` | `src/image/` | CPU pixel-level image manipulation (ImageData) |
| `event` | `src/event/` | FIFO event queue, polling API |
| `entity` | `src/entity/` | Lightweight ECS with ID recycling and bitmap tags |
| `window` | `src/window/` | Window state abstraction |
| `thread` | `src/thread/` | Background Rust threads, `Channel` inter-thread communication |
| `postfx` | `src/postfx/` | Post-processing effects data model: bloom, blur, color grading, screen-space shaders. Pure CPU config; GPU application handled in `lua_api`. Extracted from `graphics`. |
| `minimap` | `src/minimap/` | Minimap content extraction, FOV mask, and tile sampling. Pure CPU data model. Extracted from `graphics`. |

**Import rule**: Tier 1 modules may only import `crate::math::*` and `crate::engine::*`.

### Tier 2 — Engine Extensions

**Definition**: Generic engine capabilities that build on Tier 1. Not gameplay-specific. May reference Tier 1 and foundation layers. **Must NOT import other Tier 2 modules.**

**Purpose**: Reusable subsystems that most game genres will use (particles, tilemaps, AI, pathfinding, save games). Not tied to any particular genre.

| Module | Path | Responsibility |
|--------|------|----------------|
| `particle` | `src/particle/` | Emitter-based 2D particle effects; builds on `graphics` |
| `tilemap` | `src/tilemap/` | Tilemaps, isometric, autotile, TMX, procedural mapgen; builds on `graphics` |
| `scene` | `src/scene/` | Scene stack, transitions, depth sorting |
| `savegame` | `src/savegame/` | Slot-based save/load, schema versioning; builds on `filesystem` + `data` |
| `modding` | `src/modding/` | Mod discovery, dependency resolution, load ordering; builds on `filesystem` |
| `graph` | `src/graph/` | Directed graph, flow simulation, Dijkstra |
| `pathfinding` | `src/pathfinding/` | Grid pathfinding (A★, HPA★, flow fields); builds on `math` |
| `dataframe` | `src/dataframe/` | Column-major tabular data, SQL-style queries |

**Import rule**: Tier 2 modules may import `math`, `engine`, and any **Tier 1** module. They must NOT import each other.

### Tier 3 — Gameplay Systems

**Definition**: Genre-specific systems designed around specific gameplay domains. Build on Tier 1 and Tier 2. **Must NOT import other Tier 3 modules.**

**Purpose**: RPG combat, inventory, dialogue, crafting, quests, etc. These contain gameplay opinion — not all games will use all of these.

| Module | Path | Responsibility |
|--------|------|----------------|
| `ai` | `src/ai/` | Game AI: FSM, behaviour trees, GOAP planning, Q-learning, influence maps, steering, and squads |
| `battle` | `src/battle/` | Turn-based battles, combatants, actions, statuses, turn order |
| `cardgame` | `src/cardgame/` | Cards, stacks, deck building, slots, history, and card-pool utilities |
| `combat` | `src/combat/` | Vehicle combat minigame: chassis, turrets, weapons, projectiles |
| `crafting` | `src/crafting/` | Recipe system, ingredient matching, crafting queues |
| `dialog` | `src/dialog/` | Dialogue trees, branching narrative, localisation hooks |
| `economy` | `src/economy/` | Named resource economy: capacity, flow rates, decay, interest, reservations, conversions, and overflow policies |
| `inventory` | `src/inventory/` | Inventory slots, stacking, weight limits |
| `item` | `src/item/` | Item definitions, attributes, and loot-table rarity — shared by `inventory`, `crafting`, and loot systems |
| `quest` | `src/quest/` | Quest tracking, objectives, branching completion states |
| `stats` | `src/stats/` | Character attributes, derived stats, modifiers |
| `province_map` | `src/province_map/` | Province/territory map, ownership, borders |

**Import rule**: Tier 3 modules may import `math`, `engine`, Tier 1, and Tier 2 modules. They must NOT import each other.

### Tier 4 — Platform Integrations (Future)

**Definition**: External platform SDK wrappers. Not gameplay logic; integration glue for distribution platforms and external services.

**Purpose**: Steam achievements, Epic Games Store, itch.io store API, platform-specific OS integrations, cloud saves-as-a-service. These are **opt-in extensions**, not part of the core engine binary.

**Import rule**: Tier 4 modules may import any lower tier. They must NOT be imported by any tier below them.

**Status**: Not yet implemented. Reserved for future shipping builds.

---

## Dependency Graph (Summary)

```
                    ┌─────────┐
                    │ lua_api │  Integration layer — imports ALL modules
                    └────┬────┘
                         │ may import any module
        ┌────────────────┼───────────────────┐
        │                │                   │
   ┌────▼────┐    ┌──────▼──────┐    ┌──────▼──────┐
   │ Tier 3  │    │   Tier 2    │    │   Tier 1    │
   │Gameplay │    │  Extensions │    │  Basic Core │
   └─────────┘    └─────────────┘    └──────┬──────┘
        │                │                  │ may import
        └────────────────┴──────────────────┤
                                       ┌────▼────┐
                                       │ engine  │  Foundation
                                       │  math   │  Foundation
                                       └─────────┘
```

**Crossing rules**:
- ✅ Any tier may import `math` and `engine`
- ✅ Tier 2 may import Tier 1
- ✅ Tier 3 may import Tier 1 and Tier 2
- ❌ No same-tier cross-imports (Tier 1 ↔ Tier 1, Tier 2 ↔ Tier 2, Tier 3 ↔ Tier 3)
- ❌ No upward imports (Tier 1 importing Tier 2, etc.)
- ❌ Domain modules never import `lua_api`
- `engine` may import all modules (it is the top-level orchestrator)
- `lua_api` may import all modules (it is the Lua binding integration layer)

---

## Always-Available Layers

### `math/` — Foundation

`math` is the leaf of the dependency graph. It has no Luna2D dependencies and provides:
- Vectors (`Vec2`, `Vec3`), matrices (`Mat3`), `Rect`
- Noise, easing, interpolation
- Color space utilities (sRGB ↔ linear conversion)

All modules at all tiers may freely import `math`.

### `engine/` — App Lifecycle

`engine` provides the application skeleton: `App`, `Config`, `EngineError`, `Clock`, `SharedState`, `WindowState`, and `FullscreenType`. It is the only module that may import from all other modules simultaneously (it orchestrates them in the game loop). Tier 1 modules may expose their types to `engine` for wiring during startup.

`SharedState` is the central shared runtime state — an `Rc<RefCell<SharedState>>` shared between the engine event loop and all Lua API closures. It is defined in `engine` (not `lua_api`) and re-exported from `lua_api` for sub-module convenience. `engine::app` imports `lua_api` exclusively for the `create_lua_vm` bootstrap call.

### `lua_api/` — Lua Binding Bridge

`lua_api` sits above all tiers. It imports every module to expose its functionality through the `luna.*` namespace. It must never be imported by domain modules. `lua_api` re-exports `SharedState`, `WindowState`, `FullscreenType`, and `ErrorInfo` from `engine` for use by all sub-module register functions.

---

## Physical Layout Convention

The architecture contract distinguishes between:

- **Active crate modules**: directories declared in `src/lib.rs` and therefore part of the Rust crate surface.
- **Additional top-level source directories**: folders that may contain design notes, incubating work, or dormant implementations but are not currently part of the crate contract unless they are wired into `src/lib.rs`.

Today, the active module inventory is defined by the flat `src/<module>/` layout exported from `src/lib.rs`, not by nested tier folders.

### Design-Stage Modules (not yet active)

The following `src/` directories contain only design documents (`.md` files and `AGENT.md`). They have **no Rust source** and are **not declared in `src/lib.rs`**. They are placeholders for planned future modules and should not be treated as part of the active tier inventory until they are explicitly integrated into the crate module map.

| Folder | Planned Tier | Intended Purpose |
|--------|--------------|------------------|
| `src/automation/` | T2 | Macro/script-driven game automation, triggers, and scheduled actions |
| `src/doll/` | T3 | Paper-doll character equipment layering and sprite compositing |
| `src/gui/` | T2 | Retained-mode widget UI system: buttons, panels, text fields |
| `src/network/` | T2 | Peer-to-peer and client/server networking primitives |
| `src/overlay/` | T2 | Composable per-frame screen-effect layer: weather particles, ambient lighting |
| `src/pipeline/` | T2 | Data transformation pipelines: ETL chains, filter/map/reduce nodes |
| `src/terminal/` | T2 | In-game developer terminal / REPL console |

> When a design-stage module gains Rust source and is wired into `src/lib.rs`, move it to its proper tier table above and remove it from this list.

---

## Boot Sequence

1. Parse CLI args → game directory path
2. `Config::load_from_conf_lua(game_dir)` — temporary Lua VM executes `conf.lua`
3. `App::new(config)` — windowing (winit), GPU init (wgpu), audio (rodio), filesystem (GameFS)
4. `create_lua_vm()` — LuaJIT VM, `luna` global table, `lua_api` modules registered
5. Load and execute `main.lua` → call `luna.load()`
6. Enter `winit` event loop → `luna.update(dt)` / `luna.draw()` each frame

---

## Key Patterns

- **`SharedState`**: `Rc<RefCell<SharedState>>` shared between Lua closures and the engine loop. Never use raw pointers or `unsafe` for state sharing.
- **DrawCommand queue**: Lua `luna.draw()` pushes `DrawCommand` variants; the GPU renderer processes them after the callback returns. Never render inside a Lua closure.
- **SlotMap resource pools**: Generational IDs (`TextureKey`, `FontKey`, etc.) prevent use-after-free.
- **`register()` pattern**: Each `lua_api` sub-module has `pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()>`.

---

## Planned Build Variants (Future)

The tier system enables opt-in build configurations:

| Variant | Tiers Included | Target Use Case |
|---------|----------------|-----------------|
| **Light** | Foundation + Tier 1 | Minimal engine; custom game systems only |
| **Standard** | Foundation + Tier 1 + Tier 2 | General-purpose games; no genre systems |
| **Extended** | Foundation + Tier 1 + Tier 2 + Tier 3 | Full RPG/simulation game support |
| **Platform** | All tiers + Tier 4 | Shipping builds with store integration |

These variants are **not yet implemented** at the `Cargo.toml` feature level. They are documented as a design intent for future Cargo feature flag work.
