# Changelog

All notable changes to the Luna Toolkit extension will be documented in this file.

## [1.0.0] — 2025-07-19

### Added
- **Core Commands**: Run/build Luna2D games from VS Code (Alt+L run, Shift+Alt+L stop)
- **Sidebar**: ProjectTools, DevTools, AiCopilot tree views in dedicated activity bar panel
- **Status Bar**: Game running indicator with project name
- **IntelliSense Baseline**: Code completion, hover docs, signature help, go-to-definition, find references, document/workspace symbols, diagnostics, color provider, asset path completion, inlay hints, code actions
- **IntelliSense Enhanced**: LuaJIT bit/jit completions, type inference from factory functions, contextual string completions, require graph with cycle detection, workspace symbol index
- **Visual Editors (27)**: Tile Map, Scene Flow, Entity Designer, Pixel Art, Dialog, Particle, Database Browser, Procedural Map, Quest/Tech Tree, GUI Widget, AI Behavior Tree, Graph/Node, Tilemap Script, Voxel, Test Runner, API Reference, Sprite Animation, Tileset, Audio Mixer, Color Palette, Input Mapper, Timeline, Shader Preview, Font Preview, Localization, Physics Materials, World Map
- **Pattern Library**: 12 drop-in Lua modules (class, state machine, event bus, object pool, camera, FSM, grid, signal, stack, timer, tween, component system)
- **Testing Tools**: Test generator, test runner, coverage tracking, per-module Rust test commands
- **Debug Bridge**: TCP debug connection (port 19740), hot-reload, Lua expression evaluation, performance stats, variable inspection, screenshot capture, call stack
- **Game Jam**: Quick-start wizard with genre templates, module installer, countdown timer
- **Snippet Library**: 26 categorized game code snippets (Graphics, Physics, Input, Audio, UI, Data, General)
- **Game-Dev CAG Layer**: 11 AI agents, 26 skills, 15 prompts, 8 instructions, 12 project templates
- **CAG Deployment**: Deploy/update game-dev AI layer to project `.github/`
- **Project Scaffolding**: 12 game templates (minimal, game-loop, platformer, top-down-rpg, shoot-em-up, puzzle, roguelike, visual-novel, arcade, tower-defense, game-jam, demo-scene)
- **Lua Snippets**: 9 core luna.* API snippets (game loop, load, update, draw, physics, sprite, class, keypressed, conf)
- **MCP Server**: JSON-RPC server with 6 tool handlers (runExample, getApiDoc, listExamples, runLuaTest, checkBuild, getLogs)
- **Packaging**: Game packaging commands for Windows and Linux (.zip output)
