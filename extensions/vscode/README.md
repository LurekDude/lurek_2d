# Luna2D — VS Code Extension

AI-first IDE support for the [Luna2D](https://github.com/luna2d/luna2d) game engine.

## What This Extension Does

Luna2D is a 2D game engine written in Rust that loads and executes Lua game scripts. This extension turns VS Code into the primary development environment for Luna2D games by providing:

- **MCP Server** — Exposes engine capabilities (example runner, API lookup, build checking) to GitHub Copilot agents via the Model Context Protocol
- **CAG Documentation Bundling** — Ships `.instructions.md`, `.skill.md`, `.prompt.md`, and `.agent.md` files so Copilot agents automatically understand Luna2D conventions
- **Example Runner** — Browse and run Luna2D examples directly from VS Code
- **API Documentation** — Search and view `luna.*` API reference without leaving the editor

## Features

### MCP Tools (for Copilot Agents)

| Tool | Description |
|---|---|
| `luna2d.runExample` | Build and run a named example, capture output |
| `luna2d.getApiDoc` | Return docs for a `luna.*` function or module |
| `luna2d.listExamples` | List available example projects |
| `luna2d.runLuaTest` | Run a Lua test file on a debug build |
| `luna2d.checkBuild` | Run `cargo check` and return diagnostics |
| `luna2d.getLogs` | Return last N lines of engine log output |

### VS Code Commands

- **Luna2D: Run Example** — Pick an example from a quick-pick menu and run it
- **Luna2D: List Examples** — Show available examples in an information message
- **Luna2D: Check Build** — Run `cargo check` and display results
- **Luna2D: Get API Documentation** — Search the `luna.*` API reference

## Installation

### From VSIX

```bash
cd vscode-extension
npm install
npm run compile
npm run package
code --install-extension luna2d-vscode-0.1.0.vsix
```

### From Marketplace

Search for "Luna2D" in the VS Code Extensions panel (when published).

## Usage

### For Game Developers

1. Open a folder containing a `main.lua` file — the extension activates automatically
2. Use the Command Palette (`Ctrl+Shift+P`) and type "Luna2D" to see available commands
3. The status bar shows "Luna2D" when the extension is active

### AI-First Workflow

The primary workflow for Luna2D is **human design, AI implementation**:

1. **You** design the game logic, mechanics, and structure
2. **Copilot agents** implement the Lua scripts using the bundled CAG documentation
3. Agents call MCP tools to run examples, check builds, and look up API docs
4. You iterate on the design while agents handle the implementation details

The extension bundles all CAG context (instructions, skills, agents) so Copilot understands Luna2D conventions without any additional setup.

## Requirements

- VS Code 1.90.0 or later
- Rust toolchain (for building Luna2D)
- Luna2D engine source (Cargo.toml in workspace)

## Extension Settings

This extension does not contribute any VS Code settings at this time.

## License

MIT — same as Luna2D engine.
