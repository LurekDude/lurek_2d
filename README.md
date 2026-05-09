<p align="center">
  <img src="assets/splash.png" alt="Lurek2D" width="720" />
</p>

<p align="center">
        <strong>A small desktop 2D runtime for Lua games.</strong> Rust core - Lua scripting - GPU rendering - AI-first tooling.
</p>

---

One binary. One scripting language. Put `lurek2d` next to `main.lua` and run your game. No installer, no DLLs, no editor lock-in.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture Overview](#architecture-overview)
3. [What Ships](#what-ships)
4. [Tech Stack](#tech-stack)
5. [Project Identity](#project-identity)
6. [License](#license)

### Architecture Contents

1. [Runtime Modules (described)](#runtime-modules-described)
2. [Full Lua API Surface](#full-lua-api-surface)
3. [Example Games Categories](#example-games-categories)
4. [Use Cases (where to use Lurek2D)](#use-cases-where-to-use-lurek2d)
5. [AI-First Engineering (how AI is used)](#ai-first-engineering-how-ai-is-used)
6. [Key Architecture Notes](#key-architecture-notes)

---

## Quick Start

```bash
cargo run                               # Splash screen (no game)
cargo run -- content/examples/render.lua # Run an API example
```

Create `main.lua` anywhere:

```lua
function lurek.init()
    lurek.render.setBackgroundColor(0.1, 0.1, 0.2)
end

function lurek.draw()
    lurek.render.print("Hello, Lurek2D!", 100, 100)
end
```

```bash
cargo run -- path/to/your/game   # No project files. No config required.
```

An empty `main.lua` is valid. With no game argument, the engine shows a built-in splash screen - drag and drop a folder onto the window to load it.

---
## Architecture Overview

Lurek2D is a small desktop runtime for 2D Lua games. You write `main.lua`, call `lurek.*`, and the Rust engine handles rendering, physics, audio, files, threads, and platform integration underneath.

The runtime is intentionally separate from IDE tooling. The VS Code extension is optional and lives outside the engine binary.

### Runtime Modules (described)

Below is the full runtime module set from `src/lib.rs`, grouped by responsibility.

#### Foundations

| Module | Description |
|---|---|
| `math` | Provides core math primitives like vectors, matrices, and rectangles used across the engine. It also ships helpers for interpolation, easing, geometry, and general numeric operations needed by gameplay code. |
| `data` | Implements low-level binary data buffers and transformation helpers. It supports compression, hashing, and encoding utilities used by save systems, assets, and tooling paths. |
| `serial` | Exposes format-agnostic serialization built around shared value representations. It handles JSON, TOML, CSV, MessagePack, XML, and conversion flows between them. |
| `graph` | Provides graph structures and traversal utilities for directed and undirected relationships. It is used for dependency-like flows, path-style queries, and simulation-style data propagation. |
| `dataframe` | Implements in-memory tabular data with column-oriented access patterns. It is useful for game analytics, AI tuning tables, and structured datasets loaded by scripts. |
| `procgen` | Contains procedural generation utilities for maps, layouts, and noise-driven content. It provides reusable algorithms so generation logic stays consistent across modules. |
| `patterns` | Hosts reusable gameplay and architecture patterns like state machines and command-style flows. It reduces per-project boilerplate by shipping tested building blocks. |
| `i18n` | Manages localization catalogs, key lookup, and language switching at runtime. It also handles pluralization and formatting rules so script code can stay locale-agnostic. |

#### Core Runtime

| Module | Description |
|---|---|
| `app` | Owns the top-level application lifecycle and main run loop orchestration. It wires initialization, frame updates, and shutdown flow around the configured runtime. |
| `runtime` | Defines core runtime contracts like configuration, shared state, and error surfaces. It is the central coordination layer used by other modules to stay consistent. |
| `event` | Provides the internal event queue and dispatch primitives. It supports polling and message-driven integration between systems without tight coupling. |
| `thread` | Implements worker-thread integration and typed inter-thread channels. It enables background workloads while keeping Lua VM state isolated and safe. |
| `timer` | Provides frame-time tracking and scheduled callback primitives. It supports both immediate loop timing and delayed/repeating tasks. |
| `log` | Exposes runtime logging utilities and level-based output control. It gives scripts and engine internals a unified diagnostics path. |

#### Platform Services

| Module | Description |
|---|---|
| `render` | Owns the GPU rendering pipeline, command processing, and draw pass execution. It is responsible for translating script draw intent into backend GPU operations. |
| `audio` | Handles sound source loading, mixing, and playback routing. It provides runtime controls like volume, bus grouping, and stream management. |
| `input` | Tracks keyboard, mouse, gamepad, and touch state across frames. It normalizes platform-specific signals into stable queryable runtime state. |
| `window` | Wraps window lifecycle and platform event loop integration. It controls size, mode, and other host-window level behavior required by runtime startup. |
| `filesystem` | Implements sandboxed game IO and path-safe file access. It provides read/write primitives used by assets, save data, and script tooling. |
| `image` | Provides CPU-side image and pixel manipulation helpers. It supports loading, transforming, and preparing image data used by rendering paths. |
| `physics` | Implements rigid-body simulation, collision queries, and event reporting. It gives scripts deterministic motion and contact behavior for 2D games. |
| `camera` | Manages view transforms between world space and screen space. It supports panning, zoom, and viewport logic used by rendering and gameplay systems. |
| `compute` | Exposes compute-oriented operations and data processing utilities. It supports heavier numerical workloads that do not fit simple script loops. |

#### Feature Systems

| Module | Description |
|---|---|
| `ai` | Provides gameplay AI tooling such as behavior control structures and planning helpers. It enables scripted agents to use reusable decision logic instead of ad-hoc code. |
| `animation` | Manages timeline and clip-based animation playback for entities and visuals. It coordinates frame progression, playback states, and transitions. |
| `tween` | Handles eased interpolation of values over time. It is used for UI motion, gameplay transitions, and smooth scripted state changes. |
| `sprite` | Provides sprite-level handling including frames, sheets, and batching helpers. It is a core 2D visual layer on top of the render backend. |
| `ui` | Implements retained-mode widget structures and interaction logic. It supports common controls and layout behavior needed for in-game interfaces. |
| `effect` | Hosts visual effect composition layers used for atmosphere and presentation. It allows game-level overlays and style-driven rendering passes. |
| `light` | Manages 2D lighting data and shadow-relevant scene state. It supports dynamic light setups for richer 2D scenes. |
| `minimap` | Generates minimap views from world and camera-related data. It provides compact spatial feedback systems for larger maps. |
| `scene` | Owns scene stack management, transitions, and active scene switching. It provides structured lifecycle control for game states and screens. |
| `tilemap` | Provides tile-based map structures, utilities, and traversal helpers. It is used by top-down, side-scroller, and grid-driven gameplay. |
| `particle` | Implements emitter-driven particle behavior and update flows. It is used for effects like smoke, sparks, trails, and impact feedback. |
| `pathfind` | Provides pathfinding algorithms and navigation helpers for grid-like spaces. It allows AI and scripted agents to move using reusable route logic. |
| `network` | Exposes multiplayer/network transport integration for runtime sessions. It handles packet-oriented communication surfaces used by game logic. |
| `save` | Implements save/load primitives with slot and format support. It keeps gameplay persistence separated from scene and script code. |
| `mods` | Manages mod discovery, metadata, and integration hooks. It enables controlled extension of game behavior by external content. |
| `raycaster` | Implements pseudo-3D raycast-style rendering on top of 2D runtime concepts. It supports retro FPS and dungeon-style visual pipelines. |
| `spine` | Integrates skeletal animation data and runtime state for Spine assets. It handles pose updates and animation playback control. |
| `parallax` | Manages layered scrolling backgrounds with depth illusion. It is used to create richer camera motion perception in 2D scenes. |
| `province` | Provides province-level world structures and spatial grouping logic. It supports map-scale gameplay where regions are first-class entities. |
| `globe` | Implements globe-like world representation and interaction helpers. It is aimed at strategy-style views and region navigation scenarios. |
| `ecs` | Provides entity-component data organization and iteration patterns. It helps structure gameplay state with explicit component ownership. |
| `terminal` | Implements in-game terminal-style UI and command interaction layers. It is useful for debug views, script consoles, and text-heavy tools. |
| `pipeline` | Provides orchestration for multi-step runtime processing flows. It helps compose feature behavior into predictable ordered execution paths. |

#### Edge And Integration

| Module | Description |
|---|---|
| `lua_api` | Registers and exposes the `lurek.*` API surface to Lua scripts. It is intentionally thin and delegates business logic to domain modules. |
| `automation` | Provides automation hooks for scripted workflows and repetitive tasks. It is primarily used for tooling and validation scenarios around runtime behavior. |
| `devtools` | Exposes developer diagnostics like overlays, counters, and runtime inspection helpers. It improves visibility while tuning performance and correctness. |
| `debugbridge` | Provides bridge endpoints for external debug and inspection tooling. It allows remote or attached tools to query runtime state safely. |
| `docs` | Hosts runtime-facing documentation metadata and discovery helpers. It supports documentation-aware workflows from inside the development environment. |
| `html` | Implements lightweight HTML/CSS-based layout integration for runtime UI flows. It allows document-like composition where widget APIs are not enough. |

### Full Lua API Surface

All game-facing scripting lives under `lurek.*`. A minimal game can be as small as this:

```lua
function lurek.init()
  lurek.render.setBackgroundColor(0.1, 0.1, 0.2)
end

function lurek.draw()
  lurek.render.print("Hello, Lurek2D!", 100, 100)
end
```

Every callback is optional. For full API details:

- Lua API reference: [docs/api/lurek.md](docs/api/lurek.md)
- API examples: [content/examples/README.md](content/examples/README.md)
- Architecture docs: [docs/architecture/philosophy.md](docs/architecture/philosophy.md)

### Example Games Categories

`content/games/` is organized into these categories:

- `action` - combat-heavy and fast-paced gameplay
- `arcade` - score-driven classic loops
- `retro` - old-school mechanics and presentation
- `rpg` - progression, quests, dialog, systems
- `simulation` - economy, systems, management flows
- `strategy` - tactical and planning-driven gameplay
- `sports` - competitive and score/rules-based gameplay
- `showcase` - feature demos and cross-system examples

Use the full catalog here: [content/games/README.md](content/games/README.md)

### Use Cases (where to use Lurek2D)

- Indie 2D game development with Lua-first workflow
- Rapid gameplay prototyping without editor lock-in
- Mod-friendly games with script-level extensibility
- Educational projects for Lua and game architecture
- AI-assisted development with docs/tests/examples in one repo
- Building game-adjacent tools: UI apps, simulation tools, scripting sandboxes

### AI-First Engineering (how AI is used)

Lurek2D is AI-first not only in marketing, but in repository workflow and architecture rules.

- **Engine development runs on CAG in `.github/`**. The CAG layer (agents, skills, prompts, validators) is the contract used to build and evolve the engine itself. The architecture docs explicitly describe the engine as built by humans prompting agents.
- **AI engineering is part of how the engine was created**. `docs/architecture/cag-system.md` states that games, levels, scripts, assets, tests, and engine source are produced in an agent-assisted workflow.
- **The binary is exposed to agents through MCP tooling**. The VS Code extension starts an MCP server and exposes tools like run example, API lookup, build check, test runner, logs, and example listing, so agents can operate against real runtime behavior.
- **API docs are treated as AI input surface**. The API docs are generated from source and kept in sync through the docs pipeline, so agents can use `lurek.*` from authoritative references instead of inferred behavior.
- **Examples and demos are part of agent workflow**. The repository keeps both API-level examples and full games as runnable context that agents use when generating or validating code.
- **Test coverage is built in an agent-driven process**. The testing architecture is Lua-first for `lurek.*`, and coverage audits are part of the standard quality pipeline used in AI-assisted sessions.
- **The VS Code extension ships separate game-dev CAG**. The extension contains a bundled `cag/game-dev/` layer focused on making games with Lurek2D, while the root repository CAG covers engine engineering.

AI-first in Lurek2D means three things at once: the engine is developed with agents, the tooling exposes runtime operations to agents, and the docs/tests/examples are structured so agents can execute end-to-end work predictably.

### Key Architecture Notes

- `src/lua_api/` is a thin bridge. Domain modules do not depend on bindings.
- Rendering stays queued: Lua records draw commands, Rust executes GPU passes.
- Runtime resources use typed pools instead of ad-hoc string lookups.
- `library/` stays pure Lua and consumes only public `lurek.*` APIs.
- The VS Code extension is optional and separate from the engine binary.

---

## What Ships

| Component | Location | Description |
|---|---|---|
| **Engine binary** | `src/` | The `lurek2d` executable - the runtime itself |
| **Lua API reference** | `docs/api/lurek.md` | Full `lurek.*` function signatures and descriptions |
| **Rust API reference** | `docs/api/rust.md` | Engine internals for contributors |
| **VS Code extension** | `extensions/vscode/` | IntelliSense, MCP server, CAG tooling, debug workflows |
| **Games** | `content/games/` | Playable projects across action, arcade, retro, RPG, simulation, sports, and strategy |
| **API examples** | `content/examples/` | Single-file scripts demonstrating one `lurek.*` module each |
| **Lua libraries** | `library/` | Pure-Lua game-mechanics modules for inventory, quest, dialog, combat, economy, and more |
| **Plugins** | `content/plugins/` | In-progress third-party plugin layer (future) |
| **CAG system** | `.github/` | 20 Copilot agents, 30 skills, and prompts for AI-assisted development |

### VS Code Extension

[`extensions/vscode/`](extensions/vscode/README.md) provides:
- IntelliSense and hover docs for all `lurek.*` functions
- One-click demo runner
- MCP server exposing engine context to Copilot
- CAG layer (agents, skills, prompts) for AI-first game development

### Lua Libraries (Lunasome)

`library/` ships production-ready pure-Lua modules - no Rust required:

| Library | Description |
|---|---|
| `battle` | Turn-based battle system |
| `cardgame` | Card game mechanics and deck management |
| `combat` | Real-time combat: hit detection, damage, status effects |
| `crafting` | Recipe-based crafting system |
| `dialog` | Branching dialogue trees with conditions and triggers |
| `doll` | Paper-doll character equipment and layered rendering |
| `economy` | Market simulation, shop, pricing |
| `inventory` | Inventory slots, stacks, drag-and-drop |
| `item` | Item definitions, properties, and rarity |
| `province_map` | Province-based strategy map |
| `quest` | Quest tracker with objectives, stages, and rewards |
| `stats` | Attribute and derived-stat system |

### CAG - AI-First Development

Lurek2D's `.github/` layer is a complete Copilot Agent Graph (CAG):

- **20 agents** cover every role: Manager, Developer, Renderer, Physicist, Audio-Eng, Tester, Reviewer, Doc-Writer, Security, and more
- **30+ skills** provide domain knowledge: GPU programming, Lua API design, physics, audio, threading, testing, and more
- **Prompts and instructions** ensure every agent uses the engine correctly without clarifying questions

If you develop with GitHub Copilot, the CAG turns your AI assistant into a specialized Lurek2D co-developer.

---

## Tech Stack

| Component | Library | Version |
|---|---|---|
| Language | Rust stable | >= 1.78 |
| Scripting | LuaJIT via mlua | 0.9 |
| Rendering | wgpu | 22 |
| Windowing + input | winit | 0.30 |
| Physics | rapier2d | 0.32 |
| Audio | rodio | 0.17 |
| Font rasterization | fontdue | 0.9 |
| Gamepad | gilrs | 0.11 |
| Networking | rusty_enet | 0.4 |

---

## Project Identity

Lurek2D's visual identity tells a story:

- **Moon** - Lua means "moon" in Portuguese. The crescent represents the scripting layer.
- **Gear** - The Rust engine core. Industrial strength and memory safe.
- **Open circular mark** - The engine consumes scripts and turns them into a running game.
- **Cube** - The project positions itself against larger industry stacks without copying them.

---

## License

Lurek2D is **MIT-licensed**. All first-party code, docs, demos, examples, and tools are covered by the root [LICENSE](LICENSE).

| Artifact | License |
|---|---|
| Engine (`src/`) | MIT |
| Lua libraries (`library/`) | MIT |
| Games and examples (`content/games/`, `content/examples/`) | MIT |
| VS Code extension (`extensions/vscode/`) | MIT |
| Tools and docs (`tools/`, `docs/`) | MIT |

### Cargo Dependency Licenses

All direct Cargo dependencies are permissive (MIT, Apache-2.0, Zlib, or Unlicense). No GPL, LGPL, or AGPL dependency is present.

| Crate | Version | License |
|---|---:|---|
| winit | 0.30.13 | Apache-2.0 |
| bytemuck | 1.25.0 | Zlib OR Apache-2.0 OR MIT |
| pollster | 0.3.0 | Apache-2.0 OR MIT |
| mlua | 0.9.9 | MIT |
| image | 0.24.9 | MIT OR Apache-2.0 |
| ddsfile | 0.5.2 | MIT |
| rodio | 0.17.3 | MIT OR Apache-2.0 |
| fontdue | 0.9.3 | MIT OR Apache-2.0 OR Zlib |
| log | 0.4.29 | MIT OR Apache-2.0 |
| env_logger | 0.10.2 | MIT OR Apache-2.0 |
| thiserror | 1.0.69 | MIT OR Apache-2.0 |
| fastrand | 2.3.0 | Apache-2.0 OR MIT |
| rapier2d | 0.32.0 | Apache-2.0 |
| gilrs | 0.11.1 | Apache-2.0 OR MIT |
| rusty_enet | 0.4.0 | MIT |
| slotmap | 1.1.1 | Zlib |
| flate2 | 1.1.9 | MIT OR Apache-2.0 |
| lz4_flex | 0.11.6 | MIT |
| sha2 | 0.10.9 | MIT OR Apache-2.0 |
| sha1 | 0.10.6 | MIT OR Apache-2.0 |
| md-5 | 0.10.6 | MIT OR Apache-2.0 |
| base64 | 0.22.1 | MIT OR Apache-2.0 |
| hex | 0.4.3 | MIT OR Apache-2.0 |
| roxmltree | 0.20.0 | MIT OR Apache-2.0 |
| serde | 1.0.228 | MIT OR Apache-2.0 |
| serde_json | 1.0.149 | MIT OR Apache-2.0 |
| csv | 1.4.0 | Unlicense OR MIT |
| indexmap | 2.13.0 | Apache-2.0 OR MIT |
| toml | 0.8.23 | MIT OR Apache-2.0 |
| directories | 5.0.1 | MIT OR Apache-2.0 |
| sysinfo | 0.30.13 | MIT |
| sys-locale | 0.3.2 | MIT OR Apache-2.0 |
| arboard | 3.6.1 | MIT OR Apache-2.0 |
| rfd | 0.14.1 | MIT |
| zip | 2.4.2 | MIT |
| tempfile | 3.27.0 | MIT OR Apache-2.0 |
| wgpu | 22.1.0 | MIT OR Apache-2.0 |
| windows-sys | 0.59.0 | MIT OR Apache-2.0 |
| winresource | 0.1.31 | MIT |
| @modelcontextprotocol/sdk | 1.29.0 | MIT |

> **Note**: `gilrs` bundles SDL_GameControllerDB internally. The crate license is permissive; confirm notice handling for release packaging.

---

[Contributing](CONTRIBUTING.md) - [Security](SECURITY.md) - [License](LICENSE)


