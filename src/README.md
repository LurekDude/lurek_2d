# `src/` — Lurek2D Engine Source Tree

## Overview

This directory contains all Rust source code for the Lurek2D 2D game engine.
Lurek2D loads and executes Lua game scripts, providing a complete `lurek.*` API
for graphics, audio, input, physics, math, data, particles, tilemaps, scenes,
entities, and more.

For full architecture detail and tier rules, see [`docs/architecture.md`](../docs/architecture.md).

## Architecture Principles

1. **The tier system is load-bearing** — every module belongs to exactly one tier
   (1, 2, or 3) plus two foundation layers (`math`, `engine`). The tier of a
   module determines which other modules it may import. Violating tier rules
   creates circular dependencies that are hard to untangle later.
2. **Tiers are logical, not physical folders** — the repository keeps modules in
   flat `src/<module>/` directories rather than `src/tier1/<module>/`,
   `src/tier2/<module>/`, and `src/tier3/<module>/`. The dependency rules carry
   the architecture; the filesystem does not encode the tiers directly.
3. **`math/` is the leaf** — it has no Lurek2D dependencies and may be imported
   by all modules at all tiers.
4. **`engine/` is the orchestrator** — it may import all domain modules. It owns
   the game loop, window, and app lifecycle.
5. **`lua_api/` is the bridge** — it depends on every domain module to expose
   their functionality through a consistent `lurek.*` Lua namespace.
6. **No upward dependencies** — domain modules never import from `lua_api/`.
   Tier N modules never import Tier N+1 modules.

## Dependency Graph

```
                    ┌─────────┐
                    │ main.rs │  CLI entry point
                    └────┬────┘
                         │
                    ┌────▼────┐
                    │ lib.rs  │  Crate root — re-exports all modules
                    └────┬────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
         ┌────▼───┐ ┌───▼────┐ ┌──▼──────┐
         │ engine │ │lua_api │ │  bin/   │
         └───┬────┘ └───┬────┘ │ lurekc   │
             │          │      └─────────┘
             │   imports any tier
             ▼
        ┌─────────┐  ┌────────────┐  ┌────────────┐
        │ Tier 1  │←─│  Tier 2    │←─│  Tier 3    │
        │Basic    │  │ Extensions │  │ Gameplay   │
        │Core     │  │            │  │ Systems    │
        └────┬────┘  └────────────┘  └────────────┘
             │
             ▼
        ┌─────────┐
        │  math   │  Foundation (leaf — no deps)
        └─────────┘
```

**Crossing rules — enforced by code review and Clippy:**
- ✅ Any tier → `math` (always allowed)
- ✅ Tier 1 → `engine` types
- ✅ Tier 2 → Tier 1
- ✅ Tier 3 → Tier 1 and Tier 2
- ❌ Same-tier cross-imports (Tier N → Tier N)
- ❌ Upward imports (Tier 1 → Tier 2, Tier 2 → Tier 3)
- ❌ Any module → `lua_api`

## Module Inventory

### Foundation Layers

| Folder | Tier | Role | May Import |
|--------|------|------|-----------|
| `math/` | Foundation | Vec2, Mat3, Rect, noise, easing | Nothing (leaf) |
| `engine/` | Foundation | App, Config, EngineError, game loop | All modules |
| `lua_api/` | Bridge | Lua VM, SharedState, `lurek.*` bindings | ALL modules |

### Tier 1 — Basic Core

*Self-contained domain modules. Only reference `math` and `engine`.*

| Folder | Role |
|--------|------|
| `graphics/` | GPU rendering pipeline (wgpu), draw commands, textures, fonts, camera |
| `audio/` | Audio playback via rodio, buses, volume |
| `physics/` | Rigid-body simulation via rapier2d, collision, raycasting |
| `input/` | Keyboard, mouse, gamepad, touch state |
| `timer/` | Frame clock, `Clock::tick()`, scheduled callbacks |
| `filesystem/` | Sandboxed VFS, asset loading, path validation |
| `compute/` | N-dimensional numerical arrays (NdArray), pure CPU |
| `data/` | Binary buffers, compression, hashing, TOML parsing |
| `image/` | CPU pixel-level image manipulation (ImageData) |
| `event/` | FIFO event queue, polling API |
| `entity/` | Lightweight ECS with ID recycling and bitmap tags |
| `window/` | Window state abstraction |
| `thread/` | Background Rust threads, `Channel` inter-thread communication |

### Tier 2 — Engine Extensions

*Generic engine capabilities. Reference Tier 1 only. No same-tier cross-imports.*

| Folder | Role |
|--------|------|
| `particle/` | Emitter-based 2D particle effects; builds on `graphics` |
| `tilemap/` | Tilemaps, isometric, autotile, TMX, procedural mapgen |
| `scene/` | Scene stack, transitions, depth sorting |
| `savegame/` | Slot-based save/load, schema versioning |
| `modding/` | Mod discovery, dependency resolution, load ordering |
| `graph/` | Directed graph, flow simulation, Dijkstra |
| `pathfinding/` | Grid pathfinding (A★, HPA★, flow fields) |
| `ai/` | Generic AI — FSM, behaviour trees, steering, GOAP, Q-learning |
| `dataframe/` | Column-major tabular data, SQL-style queries |
| `resource/` | Generic resource pool, reference counting, hot-reload |

### Tier 3 — Gameplay Systems

*Genre-specific systems. Reference Tier 1 and Tier 2 only. No same-tier cross-imports.*

| Folder | Role |
|--------|------|
| `battle/` | Turn-based battles, combatants, actions, statuses, turn order |
| `cardgame/` | Cards, stacks, deck building, slots, history, and card-pool utilities |
| `combat/` | Turn-based and real-time combat, damage resolution |
| `crafting/` | Recipe system, ingredient matching, crafting queues |
| `dialog/` | Dialogue trees, branching narrative, localisation hooks |
| `inventory/` | Inventory slots, stacking, weight limits |
| `item/` | Item definitions, loot tables, rarity |
| `quest/` | Quest tracking, objectives, branching completion states |
| `stats/` | Character attributes, derived stats, modifiers |
| `province_map/` | Province/territory map, ownership, borders |

### Tier 4 — Platform Integrations (Future)

*External SDK wrappers (Steam, Epic, etc.). Not yet implemented. Reserved.*

## Active Vs Extra Directories

The authoritative crate module map is the set of folders exported from `src/lib.rs`.
That means not every top-level folder under `src/` is automatically part of the
active architecture contract.

Some top-level directories currently present, such as `automation/`, `doll/`,
`gui/`, `minimap/`, `network/`, `overlay/`, `pipeline/`, and `terminal/`, are
best treated as additional source-tree content rather than active crate modules
until they are wired into `src/lib.rs`.

## Entry Points

- **`main.rs`** — Binary CLI entry: parses args, loads `conf.lua`, creates `App`, runs game loop.
- **`lib.rs`** — Library crate root: re-exports all modules as `pub mod`.

## Key Patterns

- **SharedState**: `Rc<RefCell<SharedState>>` shared between Lua closures and engine loop.
- **RenderCommand queue**: Lua `lurek.draw()` pushes commands; GPU renderer processes them after callback.
- **SlotMap resource pools**: Generational IDs prevent use-after-free for textures, fonts, etc.
- **register() pattern**: Each lua_api sub-module has `pub fn register(lua, table, state)`.
