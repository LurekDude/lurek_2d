---
name: lua-scripting
description: "Load this skill when writing or reviewing Lua game scripts for Lurek2D. It owns lurek.* API usage patterns, Lua idioms, game script structure, and example code conventions. Skip it for Rust engine code or API design."
---

# Lua Scripting — Lurek2D Engine

## Load When

- Writing Lua game scripts in `content/examples/`
- Reviewing Lua code for correctness and style
- Creating demo or tutorial Lua code
- Debugging Lua runtime errors

## Owns

- Lua game script structure and patterns
- `lurek.*` API usage from the Lua side
- Lua coding idioms for game development
- Example game organization (directory structure, main.lua)

## Does Not Cover

- Rust binding implementation → use `rust-coding` skill
- API surface design → use `lua-api-design` skill
- Lua VM configuration → handled by mlua in engine

## Live Repository Contracts

- `content/demos/hello_world/main.lua` — minimal game example
- `content/demos/physics_demo/main.lua` — physics usage example
- `content/demos/sprites/main.lua` — sprite and texture example
- `docs/API/lua_api_reference_generated.md` — API reference for script authors

## Decision Rules

- **Entry point**: Every game has a `main.lua` in its directory
- **Callbacks**: Define `lurek.init()`, `lurek.ready()`, `lurek.process(dt)`, `lurek.process_physics(dt)`, `lurek.process_late(dt)`, `lurek.render()`, `lurek.render_ui()` as the game structure (all optional — see engine-architecture.md § Callback Contract)
- **API prefix**: Always `lurek.*` — never external engine prefixes or globals
- **Local variables**: Use `local` for all variables — avoid globals except luna callbacks
- **Table patterns**: Use tables for game objects: `local player = {x = 100, y = 200, speed = 150}`
- **Delta time**: Always multiply movement by `dt` for frame-rate independence
- **Directory layout**: Each game in its own directory: `content/demos/hello_world/main.lua`
- **No require()**: Lurek2D doesn't support module loading yet — single-file scripts
- **Comments**: Use `--` for single-line comments, document non-obvious game logic
