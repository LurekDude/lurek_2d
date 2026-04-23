---
name: lua-scripting
description: "Load this skill when writing or reviewing Lua game scripts for Lurek2D. It owns lurek.* API usage patterns, Lua idioms, game script structure, and example code conventions. Skip it for Rust engine code or API design."
---
# lua-scripting

## Mission

# Lua Scripting — Lurek2D Engine

## When To Load

- Writing Lua game scripts in `content/examples/`
- Reviewing Lua code for correctness and style
- Creating demo or tutorial Lua code
- Debugging Lua runtime errors

## When To Skip

- Rust binding implementation → use `rust-coding` skill
- API surface design → use `lua-api-design` skill
- Lua VM configuration → handled by mlua in engine

## Domain Knowledge

### Owns
- Lua game script structure and patterns
- `lurek.*` API usage from the Lua side
- Lua coding idioms for game development
- Example game organization (directory structure, main.lua)

### Live Repository Contracts
- `content/games/action/platformer/main.lua` — minimal game example
- `content/games/action/brick_breaker/main.lua` — physics usage example
- `content/games/action/bullet_hell/main.lua` — sprite and texture example
- `docs/api/lurek.md` — API reference for script authors

### Decision Rules
- **Entry point**: Every game has a `main.lua` in its directory
- **Callbacks**: Define `lurek.init()`, `lurek.ready()`, `lurek.process(dt)`, `lurek.process_physics(dt)`, `lurek.process_late(dt)`, `lurek.render()`, `lurek.render_ui()` as the game structure (all optional — see engine-architecture.md § Callback Contract)
- **API prefix**: Always `lurek.*` — never external engine prefixes or globals
- **Local variables**: Use `local` for all variables — avoid globals except lurek callbacks
- **Table patterns**: Use tables for game objects: `local player = {x = 100, y = 200, speed = 150}`
- **Delta time**: Always multiply movement by `dt` for frame-rate independence
- **Directory layout**: Each game in its own directory: `content/games/action/platformer/main.lua`
- **No require()**: Lurek2D doesn't support module loading yet — single-file scripts
- **Comments**: Use `--` for single-line comments, document non-obvious game logic

## Companion File Index

- (no companion files extracted)

## References

- See related skills in `.github/skills/`.
