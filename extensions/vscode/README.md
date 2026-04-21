# Lurek2D Toolkit - VS Code Extension

Full-featured IDE support for the [Lurek2D](https://github.com/lurek2d/lurek2d) 2D game engine.

## Overview

Lurek2D is a 2D game engine written in Rust that loads and executes Lua game scripts. This extension turns VS Code into the primary development environment for Lurek2D games with **126 commands**, covering IntelliSense, debugging, testing, build/run, visual editors, and AI-assisted development.

## Features

### IntelliSense

- **778+ API completions** - Full `lurek.*` namespace with parameter types, descriptions, and return values
- **Hover documentation** - Inline docs for every `lurek.*` function with signatures and examples
- **Signature help** - Parameter hints as you type function arguments
- **Go to definition** - Navigate to `lurek.*` API virtual definitions
- **Find references** - Locate all usages of functions and variables
- **Symbol outline** - Document symbols for functions, callbacks, and locals
- **Semantic highlighting** - Color-coded `lurek.*` API calls, callbacks, and deprecated functions
- **Inlay hints** - Inline type annotations for `lurek.*` return values
- **Code lens** - Quick links on `lurek.*` callbacks (load, update, draw, etc.)
- **Diagnostics** - Warns about unknown `lurek.*` functions, deprecated APIs, missing callbacks
- **Code actions** - Quick fixes for common issues, missing scaffolding, color picker integration
- **Rename symbol** - Safe rename across the project (guards `lurek.*` API names)
- **LuaJIT hints** - Warns about LuaJIT-specific pitfalls (64-bit integers, goto scoping, etc.)
- **Type inference** - Infers return types from `lurek.*` constructors (newImage, newBody, etc.)
- **LuaCATS support** - Parses `---@class`, `---@param`, `---@return` annotations for user types
- **Asset path completion** - Autocomplete file paths in `lurek.renders.newImage()` and similar

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
code --install-extension lurek2d-toolkit-0.9.0.vsix
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
