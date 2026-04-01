---
name: game-loop
description: "Load this skill when working on the Luna2D game loop, frame timing, callback sequencing, or delta time handling. It owns the update/draw cycle, fixed timestep patterns, and state synchronization. Skip it for rendering details or physics algorithms."
---

# Game Loop — Luna2D Engine

## Load When

- Modifying the main game loop in `src/engine/app.rs`
- Changing callback sequencing (load → update → draw)
- Working with delta time or fixed timestep
- Debugging frame timing issues

## Owns

- Main loop structure: input → update → draw → present
- Callback sequencing and error handling
- Delta time calculation and distribution
- Frame rate targeting and vsync interaction
- State synchronization between Lua and engine

## Does Not Cover

- Rendering pipeline internals → use `software-rendering` skill
- Physics step algorithm → use `physics-engine` skill
- Input event handling details → use `input-handling` skill

## Live Repository Contracts

- `src/engine/app.rs` — `App::run()` main game loop
- `src/timer/clock.rs` — `Clock` struct for delta time
- `src/lua_api/mod.rs` — Lua callback invocation

## Decision Rules

- **Loop order**: Process input → call `luna.update(dt)` → call `luna.draw()` → process DrawCommands → present buffer
- **Delta time**: Calculated by `Clock`, passed as `dt` parameter to `luna.update(dt)` in seconds
- **DrawCommand lifecycle**: Queue is cleared at start of `luna.draw()`, filled during callback, processed after callback returns
- **Error handling**: Lua callback errors are caught and logged — engine continues running unless fatal
- **State access**: `SharedState` is borrowed mutably during update, immutably during draw command processing
- **Frame timing**: Target 60fps (16.6ms per frame); `Clock` tracks actual delta for variable timestep
- **Callback guards**: Check if callback exists before calling — missing callbacks are not errors
