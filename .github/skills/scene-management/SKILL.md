---
name: scene-management
description: "Load this skill when implementing scene/state machines in Luna2D Lua scripts: title screens, gameplay loops, pause menus, game-over screens, or scene transitions. Skip it for Rust engine internals, physics, audio, or rendering pipeline work."
---

# Scene Management — Luna2D Engine

## Load When

- Implementing a scene or game-state machine in a Lua game script
- Designing title → gameplay → pause → game-over flows
- Adding a scene stack for modal overlays (pause menu, inventory)
- Implementing fade-in/fade-out or other scene transitions
- Debugging mid-frame scene switch artifacts

## Owns

- Lua-side scene table pattern and scene switcher
- Scene stack (push/pop) for modal scenes
- Transition state (fade-in/fade-out) patterns
- Avoiding closure capture issues when switching scenes
- `pending_scene` pattern to prevent mid-frame switches

## Does Not Cover

- Rust engine lifecycle → `src/engine/app.rs` (callback dispatch)
- SharedState struct definition → `src/lua_api/mod.rs`
- Rendering primitives used inside scenes → use `software-rendering` skill
- Physics or audio within a scene → use `physics-engine` or `audio-integration` skill

## Live Repository Contracts

- `src/engine/app.rs` — dispatches `luna.update`, `luna.draw`, and input callbacks each frame
- `src/lua_api/mod.rs` — `SharedState` definition; no built-in scene concept exists here

## Decision Rules

- **Scene table pattern**: Represent each scene as a Lua table with `init()`, `update(dt)`, `draw()`, and optional input handlers; swap `luna.update`/`luna.draw` to point at the active scene's methods
- **No engine-side scenes**: `SharedState` has no scene field — all scene logic lives entirely in Lua
- **Switcher vs stack**: Use a flat switcher (`current_scene`) for linear flows; use a push/pop stack (`scene_stack`) for modal overlays that must resume the scene beneath them
- **Deferred switch**: Never switch scenes inside `luna.update` or an input callback directly; set a `pending_scene` variable and apply it at the top of the next `luna.update` call to avoid mid-frame state corruption
- **Init on entry**: Always call `scene.init()` when a scene becomes active, not when it is defined, so state resets cleanly on re-entry
- **Transition state**: Implement fade-in/fade-out as a thin wrapper scene or a `transition` table with its own `update`/`draw`; the transition scene stores `next_scene` and advances an alpha value each frame, then switches once alpha reaches its target
- **Closure capture safety**: When assigning `luna.update = scene.update`, bind via a local reference captured before the assignment — avoid capturing `current_scene` inside closures that may run after it has changed
- **Input forwarding**: In the top-level `luna.keypressed` callback, delegate to `current_scene.keypressed` only if that field exists (`if current_scene.keypressed then current_scene.keypressed(key) end`)
