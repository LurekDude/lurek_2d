# Luna Toolkit

> The official VS Code extension for Luna2D game engine development.

Luna Toolkit turns VS Code into a complete, AI-first IDE for Luna2D games — from live IntelliSense and diagnostics to visual designers, a debug bridge, module dependency analysis, an integrated test runner, and a full CAG AI layer.

---

## Features

### IntelliSense & Language Support

Luna Toolkit provides deep Lua language intelligence tuned to the `luna.*` API:

- **Code Completion** — 100+ `luna.*` function completions with typed parameter info, return-value awareness, and string enum suggestions (key names, blend modes, body types, font IDs)
- **Hover Documentation** — Inline API docs with function signatures, parameter descriptions, and usage examples pulled from `docs/lua_api_reference_generated.md`
- **Signature Help** — Active parameter highlighting as you type any `luna.*` call
- **Go to Definition** — Jump from a `require` or `luna.*` call to the implementing Lua file or API doc
- **Find All References** — Cross-file reference search across the entire workspace
- **Rename Symbol** — Safe rename across all files in the project
- **Document & Workspace Symbols** — File outline (⌘/Ctrl+Shift+O) and global symbol search (⌘/Ctrl+T)
- **Type Inference** — Infer return types of `luna.graphics.newImage`, `luna.physics.newBody`, etc. to provide follow-on completions on the result
- **LuaJIT Intelligence** — Completions and performance hints for `bit.*`, `jit.*`, and FFI patterns
- **Require Graph** — On-save circular dependency detection across all `require` chains
- **Inlay Hints** — Lightweight parameter name labels for `luna.*` call sites
- **Color Provider** — Inline color swatches for `luna.graphics.setColor(r, g, b, a)` calls
- **Asset Path Completion** — `newImage`, `newSource`, `loadFont`, etc. complete asset paths relative to the game directory with broken-path detection
- **LuaCats / EmmyLua Types** — Full `.d.lua` annotation generation for use with any Lua LSP
- **Code Lens** — Reference counts and callback labels on `luna.load`, `luna.update`, `luna.draw`, and event handlers
- **Semantic Tokens** — Custom highlighting of `luna.*` namespaces, callbacks, and engine primitives
- **Snippets** — 26 auto-expanding snippets in 7 categories: graphics primitives, physics bodies, input handling, audio playback, UI elements, data structures, and general game patterns

### Live Diagnostics (12+ rules)

| Rule | Description |
|---|---|
| Deprecated API | Flags removed or renamed `luna.*` functions |
| Common Mistakes | Wrong argument order, missing `self`, bad callback signatures |
| Unused Requires | `require(...)` results never accessed |
| Asset Validation | Image/sound/font paths that do not exist on disk |
| Type Mismatch | Passing a number where a Color/Vec2 is expected |
| Missing Callbacks | `luna.draw()` missing while `luna.update()` uses rendering |
| Unclosed Resources | `luna.graphics.newCanvas()` that is never released |
| Circular Requires | Detected at save time across all Lua files |
| Infinite Loop Risk | Tight loops without a `break` or `return` |
| Non-local Function | Public function inside a module that should be `local` |
| Bad Body Type | String arg to `luna.physics.newBody` not in `{"static","dynamic","kinematic"}` |
| Missing Return | Function branch with no return in a callback that expects one |

### Visual Editors (27 built-in)

| Category | Editors |
|---|---|
| **Map & Level** | Tile Map, World Map, Procedural Map, Tileset Atlas |
| **Game Objects** | Entity Designer, Physics Materials, Particle Designer |
| **Scripting** | Tilemap Script, Dialog Tree, Quest / Tech Tree |
| **Visuals** | Pixel Art, Sprite Animation, Shader Preview, Font Preview, Color Palette |
| **Audio** | Audio Mixer, Sound DSP Panel |
| **PostFX** | PostFX & Overlay Designer (weather, time-of-day, screen effects, camera shake) |
| **UI & Flow** | GUI Widget Builder, Scene Flow, Timeline / Sequencer |
| **Data** | Database Browser, Input Mapper, Localization Table |
| **AI** | AI Behavior Tree |
| **3D Utility** | Voxel Model Editor |
| **Graph** | Graph / Node Editor |
| **Reference** | API Reference Browser |
| **Testing** | Test Runner with per-suite and per-function granularity |

### Testing

- **Test Runner** — Discover and run all 37+ Rust integration test suites from the sidebar. Displays per-function status (pass / fail / pending). Quick buttons for **Run All**, **Run Lua Tests**, **Run Golden Tests**, and **Run Selected Suite**.
- **Generate Tests for File** — Scaffolds a test file skeleton for any open `.lua` or `.rs` file, placed in the correct `tests/` location.
- **Lua Tests** — `cargo run -- tests/lua/` integration tests with headless safety.
- **Golden Tests** — Screenshot regression tests against baseline images.

### Debug Bridge

Full two-way TCP bridge to a running Luna2D game (port 19740):

| Feature | Description |
|---|---|
| Connect / Disconnect | One-click connection to a running game process |
| Hot-Reload | Push changed Lua files without restarting |
| Evaluate | Run arbitrary Lua in the game's VM and see the result |
| Variable Inspector | Browse the Lua global table and local variables |
| Call Stack | View the current Lua call stack |
| Performance Panel | Live frame time, draw calls, memory, and physics stats |
| Screenshot | Capture a PNG from the running game |
| Live Stats | Real-time CPU/RAM/GPU metrics fed into the system monitor |

### System Monitor

Time-series charts for **CPU**, **RAM**, **Disk I/O**, **Network**, and **GPU** updated every second. Tracks the Luna2D process separately from the OS load. All charts are zoomable and exportable.

### Dependency Analysis

- **Dependency Graph** — Interactive force-directed graph of all Luna2D Rust modules. Reads actual `use crate::` imports from `src/*/mod.rs` to build real edges. Drag nodes, zoom, click for per-node edge summary.
- **Find Circular Dependencies** — Runs Tarjan SCC analysis on the module import graph; results in the **Luna Circular Deps** output channel.
- **Find Orphan Modules** — Scans `src/` against `lib.rs` and cross-imports to identify unreferenced modules.

### Performance Tooling

- **Performance Dashboard** — Per-frame breakdown: render time, physics step, Lua update, draw calls, batch size, memory pressure
- **Hot-Reload History** — Live file-system watcher that records every Lua file save with timestamp, file path, and event type

### Assets Panel

- **Generate Splash** — Regenerate `assets/splash.png` via Python tool
- **Generate Icon** — Regenerate `assets/icon.ico` and `assets/icon.png`
- **Open Assets Folder** — Jump directly to the `assets/` directory

### Project Scaffolding & Packaging

- **New Game** — Choose from 12 templates (minimal, platformer, top-down RPG, puzzle, roguelike, visual novel, arcade, game jam, and more)
- **Package for Windows** — `cargo build --release` + ZIP with assets, runs `tools/dist.ps1`
- **Package for Linux** — `cargo build --release` + tar.gz, runs `tools/dist.sh`
- **Build Release** / **Build Debug** — Triggered from the Run sidebar

### AI-First Workflow — Game-Dev CAG Layer

Deploy a complete AI configuration layer into any Luna2D game project:

#### Agents (11)
Game Architect, Lua Scripter, Level Designer, Gameplay Designer, UI Designer, Visual Artist, Audio Designer, Animator, Optimizer, Game Tester, Narrative Writer

#### Skills (26)
Platformer movement, camera systems, combat, crafting, dialogue trees, pathfinding, save/load, tilemap rendering, UI/HUD, animation, inventory, input handling, AI behavior, audio integration, particle effects, shader patterns, scene management, ECS architecture, event systems, data encoding, image manipulation, threading, error handling, performance profiling, cross-platform, CI/CD

#### Prompts (15)
New Game, Add Player, Add Enemy, Add Level, Add Animation, Add Audio, Add Dialog, Add Quest, Add Save, Add UI, Add Localization, Game Jam Kickstart, Optimize Performance, Post-Mortem, Write README

#### Instructions (8)
Auto-loaded per file type: Lua files, entity definitions, asset references, audio, physics, save data, UI layouts, test files

#### Project Templates (12)
Minimal, game-loop, platformer, top-down RPG, shoot-em-up, puzzle, roguelike, visual novel, arcade, tower defense, game jam, demo scene

Deploy with: **Luna: Deploy Game Dev AI Layer**

### MCP Server

Exposes 6 tools to Copilot agents via the Model Context Protocol:

| Tool | Description |
|---|---|
| `runExample` | Build and run a named example, capture output |
| `getApiDoc` | Return docs for a `luna.*` function or module |
| `listExamples` | List available example projects |
| `runLuaTest` | Run a Lua test file on a debug build |
| `checkBuild` | Run `cargo check` and return diagnostics |
| `getLogs` | Return last N lines of engine log output |

---

## Sidebar Sections

The Luna Toolkit sidebar has 8 sections, each with actionable items:

| Section | What's inside |
|---|---|
| **Run** | Run game, run with args, stop, hot-reload, build debug, build release, create new game, package Windows/Linux |
| **Testing** | Open Test Runner, Run All Tests, Run Lua Tests, Run Golden Tests, Generate Tests for File, per-module test commands |
| **Editors** | All 27 visual editors grouped by category |
| **Debug** | Connect bridge, disconnect, evaluate Lua, variable inspector, call stack, performance panel, screenshot, live stats |
| **Reference** | Browse API docs, open wiki for symbol, quick-insert `luna.*`, dependency graph, API coverage report, view changelog |
| **Assets** | Generate splash, generate icon, open assets folder |
| **Dependencies** | Lock file status, find circular deps, find orphan modules, check outdated crates |
| **Performance** | Open performance dashboard, hot-reload history, system monitor, Luna2D process tracker |

---

## Quick Start

1. Install from VSIX or Marketplace
2. Open a Luna2D project folder (must contain `main.lua`)
3. Press `Alt+L` to run
4. Open the Luna Toolkit sidebar (`⌘/Ctrl+Shift+P` → "Luna: Focus on Luna Toolkit View")

---

## Requirements

- VS Code 1.90+
- Luna2D engine binary available (set path in `luna.lunaPath` if not on PATH)
- Rust toolchain for test running and project builds

---

## Extension Settings

| Setting | Default | Description |
|---|---|---|
| `luna.lunaPath` | `""` | Path to luna2d executable |
| `luna.srcDir` | `""` | Game source subdirectory |
| `luna.saveOnRun` | `true` | Save all files before running |
| `luna.diagnostics.deprecationWarnings` | `true` | Show deprecated API warnings |
| `luna.diagnostics.commonMistakes` | `true` | Detect common Luna2D mistakes |
| `luna.diagnostics.unusedRequires` | `true` | Flag unused requires |
| `luna.diagnostics.assetValidation` | `true` | Validate asset paths |
| `luna.inlayHints.parameterNames` | `true` | Show parameter name hints |
| `luna.test.testDir` | `"tests"` | Rust test directory |
| `luna.test.luaTestDir` | `"tests/lua"` | Lua test directory |
| `luna.cag.installOnScaffold` | `true` | Auto-deploy AI layer on new project |
| `luna.package.outputDir` | `"dist"` | Build output directory |
| `luna.debugBridge.port` | `19740` | Debug bridge TCP port |
| `luna.debugBridge.autoConnect` | `true` | Auto-connect on game start |

---

## License

MIT


### IntelliSense

- **Code Completion** — `luna.*` API completions with parameter info
- **Hover Documentation** — Inline API docs with examples
- **Signature Help** — Parameter hints as you type
- **Go to Definition** — Navigate to function definitions
- **Find References** — Find all usages across workspace
- **Document & Workspace Symbols** — Outline and global symbol search
- **LuaJIT Intelligence** — `bit.*`/`jit.*` completions and performance hints
- **Type Inference** — Method completions on `luna.*` factory return values
- **Contextual Strings** — Key names, blend modes, body types in string arguments
- **Require Graph** — Circular dependency detection
- **Code Actions** — Extract function, convert to local, generate stubs, and more
- **Diagnostics** — Deprecation warnings, common mistakes, unused requires, asset path validation
- **Inlay Hints** — Parameter name hints for `luna.*` calls
- **Color Provider** — Color swatches for `luna.graphics.setColor` calls
- **Asset Path Completion** — Auto-complete file paths in `newImage`, `newSource`, etc.

### Visual Editors (27)

| Editor | Purpose |
|---|---|
| Tile Map | Design tile-based game levels |
| Scene Flow | Scene/state connection editor |
| Entity Designer | Entity composition editor |
| Pixel Art | Sprite pixel editor |
| Dialog | Branching dialog tree editor |
| Particle | Visual particle effect designer |
| Database Browser | Game data table viewer |
| Procedural Map | Procedural level generator |
| Quest / Tech Tree | Quest and tech tree editor |
| GUI Widget | UI layout editor |
| AI Behavior Tree | AI decision tree editor |
| Graph / Node | Generic node graph editor |
| Tilemap Script | Lua tilemap script editor |
| Voxel | Voxel model editor |
| Test Runner | Test execution and results |
| API Reference | Searchable `luna.*` API docs |
| Sprite Animation | Animation timeline and playback |
| Tileset | Tileset atlas management |
| Audio Mixer | Multi-channel mixing console |
| Color Palette | Game color palette management |
| Input Mapper | Action-to-key binding editor |
| Timeline | Cutscene sequencer |
| Shader Preview | Live shader code preview |
| Font Preview | Font specimen display |
| Localization | Translation table editor |
| Physics Materials | Material property library |
| World Map | Room/level connection editor |

### Game Development Tools

- **Test Generator** — Auto-generate Lua tests from API usage
- **Test Runner** — Run Rust and Lua tests with per-module granularity
- **Debug Bridge** — TCP connection (port 19740) for hot-reload, Lua evaluation, variable inspection, performance stats, screenshots, and call stack
- **Game Jam Wizard** — Genre templates, countdown timer, module installer, submission checklist
- **Snippet Library** — 26 game code snippets in 7 categories (Graphics, Physics, Input, Audio, UI, Data, General)
- **Pattern Library** — 12 drop-in Lua modules (class, state machine, event bus, object pool, camera, FSM, grid, signal, stack, timer, tween, component system)
- **Packaging** — Package games for Windows and Linux distribution

### AI-First Workflow (Game-Dev CAG)

The extension bundles a complete AI layer for Copilot-powered game development:

- **11 AI Agents** — Game Architect, Lua Scripter, Level Designer, Gameplay Designer, UI Designer, Visual Artist, Audio Designer, Animator, Optimizer, Game Tester, Narrative Writer
- **26 Skills** — Platformer movement, camera systems, combat, crafting, dialogue, pathfinding, input handling, save/load, tilemap, UI/HUD, and more
- **15 Prompts** — New Game, Add Player, Add Enemy, Add Level, Add Animation, Add Audio, Add Dialog, Add Quest, Add Save, Add UI, Add Localization, Game Jam Kickstart, Optimize Performance, Post-Mortem, Write README
- **8 Instructions** — Auto-loaded rules for Lua files, entities, assets, audio, physics, saves, UI
- **12 Project Templates** — Minimal, game-loop, platformer, top-down RPG, shoot-em-up, puzzle, roguelike, visual novel, arcade, tower defense, game jam, demo scene

Deploy the CAG layer to any project with **Luna: Deploy Game Dev AI Layer**.

### MCP Server

Exposes engine capabilities to Copilot agents via the Model Context Protocol:

| Tool | Description |
|---|---|
| `runExample` | Build and run a named example, capture output |
| `getApiDoc` | Return docs for a `luna.*` function or module |
| `listExamples` | List available example projects |
| `runLuaTest` | Run a Lua test file on a debug build |
| `checkBuild` | Run `cargo check` and return diagnostics |
| `getLogs` | Return last N lines of engine log output |

## Quick Start

1. Install the extension from VSIX or Marketplace
2. Open a Luna2D game project folder (must contain `main.lua`)
3. Press `Alt+L` to run your game
4. Use the Command Palette (`Ctrl+Shift+P`) and type "Luna:" to see all commands

## Installation

### From VSIX

```bash
cd vscode-extension
npm install
npm run build
npm run package
code --install-extension luna-toolkit-1.0.0.vsix
```

### From Marketplace

Search for "Luna Toolkit" in the VS Code Extensions panel (when published).

## Requirements

- VS Code 1.90+
- Luna2D engine binary on PATH (or set `luna.lunaPath`)

## Extension Settings

| Setting | Default | Description |
|---|---|---|
| `luna.lunaPath` | `""` | Path to luna2d executable |
| `luna.srcDir` | `""` | Game source subdirectory |
| `luna.saveOnRun` | `true` | Save files before running |
| `luna.diagnostics.deprecationWarnings` | `true` | Show deprecated API warnings |
| `luna.diagnostics.commonMistakes` | `true` | Detect common Luna2D mistakes |
| `luna.diagnostics.unusedRequires` | `true` | Flag unused require statements |
| `luna.diagnostics.assetValidation` | `true` | Validate asset file paths |
| `luna.inlayHints.parameterNames` | `true` | Show parameter name hints |
| `luna.test.testDir` | `"tests"` | Test directory path |
| `luna.test.luaTestDir` | `"tests/lua"` | Lua test directory |
| `luna.cag.installOnScaffold` | `true` | Auto-install AI config on scaffold |
| `luna.package.outputDir` | `"dist"` | Build output directory |
| `luna.debugBridge.port` | `19740` | Debug bridge TCP port |
| `luna.debugBridge.autoConnect` | `true` | Auto-connect on debug run |

## Commands

All commands are prefixed with `Luna:` in the command palette.

## License

MIT
