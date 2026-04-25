# Lurek2D Toolkit - VS Code Extension

Full-featured IDE support for the [Lurek2D](https://github.com/lurek2d/lurek2d) 2D game engine.

## Overview

Lurek2D is a 2D game engine written in Rust that loads and executes Lua game scripts. This extension turns VS Code into the primary development environment for Lurek2D games with **85 commands**, covering Lurek-specific diagnostics, type inference, CodeLens markers, debugging, testing, build/run, visual editors, and AI-assisted development.

> **Works alongside sumneko.lua (Lua Language Server)** — this extension adds only Lurek-unique features (engine API diagnostics, factory-type inference, callback markers, asset path completion). General Lua features (completion, hover, signature help, symbol outline, find references, rename, formatting, folding, LuaCATS) are handled by sumneko.lua to avoid duplication.

## Features

### Lurek-Specific IntelliSense (what this extension adds)

- **4000+ lurek.* API items** — 1201 module functions and 2960 class methods across 50 modules and 223 types (e.g. `Body`, `Image`, `World`, `Card`, `Entity`)
- **Type inference** — Tracks `local img = lurek.graphics.newImage(...)` and suggests `Image` methods on `img:` — works even for module aliases (`local gfx = lurek.graphics`)
- **Go to definition** — Navigate to `lurek.*` virtual API definitions
- **Semantic highlighting** — Color-codes `lurek.*` calls, callbacks (⚡), deprecated functions distinctly from generic Lua
- **Inlay hints** — Inline type annotations for `lurek.*` return values
- **13 Lurek diagnostic rules** — Warns about deprecated APIs, wrong enum values, per-frame allocations, missing `lurek.load` callback, incorrect conf.lua fields, thread RNG misuse, and more
- **Code actions** — Quick fixes for Lurek-specific issues: missing scaffold, color picker integration
- **CodeLens markers** — ⚡ callbacks, ▶ test functions, 📦 library files, 🎮 demo files, 📖 examples, 🧪 test files
- **LuaJIT hints** — Warns about LuaJIT pitfalls (64-bit integers, goto scoping, bitwise ops)
- **Asset path completion** — Autocompletes file paths in `lurek.graphics.newImage()` and similar

> **Note:** General Lua features (completion, hover, signature help, symbol outline, find references, rename, formatting, folding, LuaCATS `---@class`/`---@param`) are provided by **sumneko.lua / Lua Language Server**. This extension deliberately does not duplicate those to avoid double completions and conflicting hover popups.

### Debugging (16 commands)

- **Debug adapter (DAP)** - Launch or attach to a running Lurek2D game with breakpoints
- **Debug bridge** - Connect/disconnect to engine debug socket for live inspection
- **Hot reload** - Push code changes to a running game without restarting
- **Evaluate expressions** - Run Lua expressions in the engine context
- **Variable inspector** - Inspect Lua variables and tables in a live game
- **Call stack** - View the current Lua call stack
- **Performance dashboard** - Live engine stats (FPS, draw calls, memory) in a webview
- **Screenshot capture** - Save a screenshot from the running engine

### Build, Run and Package (10 commands)

- **Run game** - Launch the current project with the Lurek2D engine
- **Run with arguments** - Launch with custom CLI arguments
- **Stop game** - Kill the running engine process
- **Run example** - Pick and run any content/examples/ or content/demos/ project
- **Quick build** - cargo build from the command palette
- **Build check** - cargo check with diagnostics
- **Package** - Build release binaries and distribution archives

### Testing (30 commands)

- **Run all tests** - cargo test from the command palette
- **Run Lua tests** - Execute individual .lua test files
- **Generate tests** - Auto-generate test scaffolding from `lurek.*` API usage
- **Test coverage** - API coverage report showing tested vs untested functions
- **Test runner editor** - Webview panel for browsing and running test suites

### Visual Editors (29 editors)

Webview-based editors for visual game asset authoring including animation, audio mixer, color palette, entity/ECS, font preview, GUI layout, keybinding, particle system, post-FX overlay, shader preview, sound DSP, sprite/spritesheet, state machine, tilemap, tween, API reference, and more.

### AI-Assisted Development

- **MCP Server** - Exposes 6 tools to GitHub Copilot agents (run example, API lookup, build check, test runner, log viewer, example listing)
- **CAG bundling** - Ships .instructions.md, .skill.md, .prompt.md, and .agent.md files for Copilot context
- **Pattern library** - Browse and insert common `lurek.*` code patterns
- **Game jam starter** - Scaffold a new game project from genre templates

### Other

- **Asset explorer** - Tree view of project assets (images, sounds, scripts)
- **Dependency graph** - Visualize module dependencies
- **System monitor** - Live CPU/RAM monitoring of the engine process
- **API coverage** - Report which `lurek.*` functions your project uses
- **Scaffold** - Generate main.lua + conf.lua project templates

## Installation

### From VSIX

```bash
cd extensions/vscode
npm install
node esbuild.config.mjs --production
npx @vscode/vsce package --no-dependencies
code --install-extension lurek2d-toolkit-1.0.0.vsix
```

### From Source (Development)

```bash
cd extensions/vscode
npm install
node esbuild.config.mjs --watch
# Then press F5 in VS Code to launch Extension Development Host
```

## Activation

The extension activates when a workspace contains main.lua, conf.lua, or Cargo.toml, or when you open any .lua file.

## Settings

| Setting | Default | Description |
|---|---|---|
| `lurek.enginePath` | `""` | Path to the lurek2d binary (auto-detected if on PATH) |
| `lurek.luaVersion` | `"luajit"` | Lua runtime: luajit or lua54 |

## Requirements

- VS Code 1.90.0+
- For game development: lurek2d binary (built from engine source or installed)
- For engine development: Rust toolchain + Cargo

## License

MIT - same as the Lurek2D engine.
