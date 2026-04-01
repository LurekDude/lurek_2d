# `src/` — Luna2D Engine Source Tree

## Overview

This directory contains all Rust source code for the Luna2D 2D game engine.
Luna2D loads and executes Lua game scripts, providing a complete `luna.*` API
for graphics, audio, input, physics, math, data, particles, tilemaps, scenes,
entities, and more.

## Architecture Principles

1. **Domain modules are independent** — each subfolder (audio, graphics, physics,
   etc.) is a self-contained domain module with no cross-dependencies except
   through `math/` (the foundational layer).
2. **Engine sits at the top** — `engine/` may depend on all modules. It owns
   the game loop, window, and app lifecycle.
3. **lua_api is the bridge** — `lua_api/` depends on every domain module to
   expose their functionality through a consistent `luna.*` Lua namespace.
4. **No upward dependencies** — domain modules never import from `lua_api/` or
   `engine/`. The dependency graph is strictly one-directional.

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
         └───┬────┘ └───┬────┘ │ lunec  │
             │          │      └─────────┘
    ┌────────┼──────────┤
    │        │          │
    ▼        ▼          ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│graphics│ │ audio  │ │ input  │ │physics │ │ timer  │
└───┬────┘ └────────┘ └────────┘ └────────┘ └────────┘
    │
    ▼          Also independent:
┌────────┐    ai, compute, data, dataframe, entity, event,
│  math  │    filesystem, graph, image, modding, particle,
└────────┘    savegame, scene, sound, tilemap, window
(foundation)
```

## Module Inventory

| Folder | Files | Role | Dependencies |
|--------|-------|------|-------------|
| `ai/` | 15 | Game AI: FSM, BT, steering, GOAP, Q-learning | None (pure CPU) |
| `audio/` | 5 | Audio playback via rodio, buses, MIDI | None |
| `bin/` | 1 | Console-less launcher (`lunec`) | lib.rs |
| `compute/` | 4 | N-dimensional numerical arrays | None |
| `data/` | 6 | Binary data, compression, hashing, TOML | None |
| `dataframe/` | 5 | Column-major tabular data, SQL queries | None |
| `engine/` | 8 | App lifecycle, config, error handling | audio, graphics, input, physics, timer, event |
| `entity/` | 2 | Lightweight ECS with ID recycling | None |
| `event/` | 1 | Event queue (FIFO polling) | None |
| `filesystem/` | 4 | Sandboxed VFS, async loading | None |
| `graph/` | 9 | Directed graph, flow simulation | None |
| `graphics/` | 26 | GPU rendering pipeline (wgpu) | math, engine |
| `image/` | 2 | CPU pixel-level image manipulation | None |
| `input/` | 5 | Keyboard, mouse, gamepad, touch state | None |
| `lua_api/` | 31 | Lua VM, SharedState, all `luna.*` bindings | ALL modules |
| `math/` | 21+ | Vec2, Mat3, Rect, noise, easing, pathfinding | None (foundation) |
| `modding/` | 1 | Mod management, dependency resolution | None |
| `particle/` | 1 | Emitter-based 2D particle effects | engine, graphics |
| `physics/` | 5 | Rigid-body physics via rapier2d | None |
| `savegame/` | 1 | Slot-based save/load, schema versioning | None |
| `scene/` | 4 | Scene stack, transitions, depth sorting | None |
| `sound/` | 3 | PCM sample manipulation, MIDI state | None |
| `tilemap/` | 9 | Tilemaps, isometric, autotile, TMX, mapgen | None |
| `timer/` | 3 | Frame clock, scheduled callbacks | None |
| `window/` | 2 | Window state (placeholder) | None |

## Entry Points

- **`main.rs`** — Binary CLI entry: parses args, loads `conf.lua`, creates `App`, runs game loop.
- **`lib.rs`** — Library crate root: re-exports all modules as `pub mod`.
- **`bin/lunec.rs`** — Windows console-less launcher (same behavior, no terminal window).

## Key Patterns

- **SharedState**: `Rc<RefCell<SharedState>>` shared between Lua closures and engine loop.
- **DrawCommand queue**: Lua `luna.draw()` pushes commands; GPU renderer processes them after callback.
- **SlotMap resource pools**: Generational IDs prevent use-after-free for textures, fonts, etc.
- **register() pattern**: Each lua_api sub-module has `pub fn register(lua, table, state)`.
