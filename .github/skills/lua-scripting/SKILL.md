---
name: lua-scripting
description: "Load this skill when writing or reviewing Lua game scripts for Luna2D. It owns luna.* API usage patterns, Lua idioms, game script structure, and example code conventions. Skip it for Rust engine code or API design."
---

# Lua Scripting — Luna2D Engine

## Load When

- Writing Lua game scripts in `examples/`
- Reviewing Lua code for correctness and style
- Creating demo or tutorial Lua code
- Debugging Lua runtime errors

## Owns

- Lua game script structure and patterns
- `luna.*` API usage from the Lua side
- Lua coding idioms for game development
- Example game organization (directory structure, main.lua)

## Does Not Cover

- Rust binding implementation → use `rust-coding` skill
- API surface design → use `lua-api-design` skill
- Lua VM configuration → handled by mlua in engine

## Live Repository Contracts

- `examples/hello_world/main.lua` — minimal game example
- `examples/physics_demo/main.lua` — physics usage example
- `examples/sprites/main.lua` — sprite and texture example
- `docs/lua_api_reference.md` — API reference for script authors

## Decision Rules

- **Entry point**: Every game has a `main.lua` in its directory
- **Callbacks**: Define `luna.load()`, `luna.update(dt)`, `luna.draw()` as the game structure
- **API prefix**: Always `luna.*` — never external engine prefixes or globals
- **Local variables**: Use `local` for all variables — avoid globals except luna callbacks
- **Table patterns**: Use tables for game objects: `local player = {x = 100, y = 200, speed = 150}`
- **Delta time**: Always multiply movement by `dt` for frame-rate independence
- **Directory layout**: Each game in its own directory: `examples/my_game/main.lua`
- **No require()**: Luna2D doesn't support module loading yet — single-file scripts
- **Comments**: Use `--` for single-line comments, document non-obvious game logic
