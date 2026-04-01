---
applyTo: "src/engine/**"
---

# Engine Module Instructions

`src/engine/` is the top-level orchestrator. It owns the `App` struct, the main game loop, `Config`, and `EngineError`. This is the only module allowed to import from all other modules simultaneously.

## Core Rules

- **`App::run()` is the sole game loop** — all coordination (Window creation, GpuRenderer, Clock, SharedState, Lua VM) happens here; no other module may create a winit `Window`
- **SharedState lives here conceptually but is defined in `lua_api/mod.rs`** — `app.rs` creates it and passes `Rc<RefCell<SharedState>>` to `create_lua_vm()`
- **Callback pattern**: call `luna.load()` once; call `luna.update(dt)` and `luna.draw()` every frame. All callbacks are optional — check if the function exists before calling
- **Splash screen**: when no game directory is given, push `DrawCommand`s for the Luna2D splash screen rather than loading a Lua script
- **Frame timing**: use `Clock::tick()` at the top of the loop; delta time is `f64` seconds

## Layer / Boundary Rules

- `engine/` is the only module that may import from all other modules
- `engine/error.rs` defines `EngineError` — all modules surface their errors via this type or `String`
- `engine/config.rs` owns window dimensions, title, vsync, FPS target — no hardcoded literals in `app.rs`
- Never import winit types outside `engine/app.rs` and `src/window/`

## Compliance

- `EngineError` variants must cover: `Init`, `Render`, `Input`, `Audio`, `Physics`, `FileSystem`, `Lua`
- Game loop order per frame: tick clock → update input → fire event callbacks → `luna.update(dt)` → clear draw commands → `renderer.clear()` → `luna.draw()` → `execute_commands()` → `update_with_buffer()`
- Frame pacing handled by wgpu present mode — do not implement manual sleep-based frame limiting

## Avoid

- Hardcoded window dimensions or titles — use `Config`
- Direct wgpu imports in `app.rs` — go through `GpuRenderer`
- Calling raw winit key events outside `engine/app.rs` — route through `KeyboardState`
- Blocking the game loop with file I/O — use `GameFS` which sandboxes I/O
- Parsing CLI arguments anywhere other than `src/main.rs`
