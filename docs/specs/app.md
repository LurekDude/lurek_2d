# `app` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Edge/Integration |
| **Status** | Implemented |
| **Lua API** | Indirect / none |
| **Source** | `src/app/` |
| **Rust Tests** | tests/rust/unit/engine_tests.rs; tests/rust/ext/graphics_runtime_smoke_tests.rs |
| **Lua Tests** | None dedicated |
| **Architecture** | `docs/architecture/engine-architecture.md § Edge / Integration` |

---

## Summary

The app module is the engine composition root. It exists to turn configuration, platform services, shared runtime state, and the Lua VM into a running desktop application with a winit event loop, GPU renderer, input processing, and frame lifecycle callbacks.

This is where engine startup policy lives: window creation, renderer initialization, splash behavior when no game is loaded, SharedState ownership, frame pacing, restart or error-screen transitions, and routing of OS events into engine systems. If a change affects the overall boot sequence or the order in which runtime systems come alive, it usually lands here.

The module intentionally does not own the underlying domain logic for rendering, input, audio, physics, or Lua bindings. It wires those systems together and drives them at runtime, but their actual behavior lives in their own modules. App is orchestration, not a place for subsystem-specific business logic.

**Scope boundary**: This module currently depends on `event`, `image`, `input`, `light`, `lua_api`, `math`, `render`, `runtime`, and other adjacent modules. It stays within the Edge/Integration responsibility boundary defined in the architecture docs.

---

## Architecture

```
No direct Lua namespace — consumed through app/runtime integration or other bindings
    |
    v
src/app/mod.rs
    |- app.rs - app
    |- app_winit.rs - app_winit
    |- debug_overlay.rs - debug_overlay
    |- error_screen.rs - error_screen
```

---

## Source Files

| File | Purpose |
|------|---------|
| `app.rs` | Defines the public App entry point and the internal runtime implementation that owns the window, event loop integration, renderer, Lua VM, and frame lifecycle. This is the main file for startup flow, event handling, splash mode, and run-state transitions. |
| `app_winit.rs` | Contains alternate or parked winit-specific app code that is not part of the active module export surface. Treat it as implementation context, not the first place to extend live behavior unless it is reconnected deliberately. |
| `debug_overlay.rs` | Defines DebugOverlay, the lightweight in-engine overlay for frame and draw statistics. It exists so app-level runtime state can expose quick visual diagnostics without dragging in the full devtools stack. |
| `error_screen.rs` | Defines ErrorScreen, the structured presentation for runtime and Lua failures. This file owns how fatal problems become user-visible render commands instead of raw crashes or console output. |
| `mod.rs` | Module root that exposes the public app-facing types. It keeps the external surface small while hiding most of the runtime wiring details. |

---

## Submodules

### `app::app`

Defines the public App entry point and the internal runtime implementation that owns the window, event loop integration, renderer, Lua VM, and frame lifecycle. This is the main file for startup flow, event handling, splash mode, and run-state transitions.

- **`App`** (struct): Entry point for the Lurek2D engine.

### `app::app_winit`

Contains alternate or parked winit-specific app code that is not part of the active module export surface. Treat it as implementation context, not the first place to extend live behavior unless it is reconnected deliberately.

- **`App`** (struct): Entry point for the Lurek2D engine.

### `app::debug_overlay`

Defines DebugOverlay, the lightweight in-engine overlay for frame and draw statistics. It exists so app-level runtime state can expose quick visual diagnostics without dragging in the full devtools stack.

- **`DebugOverlay`** (struct): Debug overlay showing FPS and render statistics.

### `app::error_screen`

Defines ErrorScreen, the structured presentation for runtime and Lua failures. This file owns how fatal problems become user-visible render commands instead of raw crashes or console output.

- **`ErrorScreen`** (struct): Visual error screen that generates `RenderCommand` sequences for the GPU renderer.

---

## Key Types

### Public Types

#### `App`

Public entry point used to launch the engine with loaded configuration and optional startup error context.

#### `LunaApp`

Internal winit application handler that owns most live runtime state during execution.

#### `RunState`

Internal state machine that distinguishes normal execution from error display and restart transitions.

#### `DebugOverlay`

Small runtime overlay for FPS and draw-call visibility.

#### `ErrorScreen`

Structured error presentation model that converts failures into readable render commands.

---

## Lua API

This module does not expose a dedicated direct Lua namespace. It is consumed indirectly through higher-level engine callbacks, shared state, or other `lurek.*` surfaces.

---

## Lua Examples

```lua
-- This module has no dedicated direct Lua namespace.
-- It is used indirectly through other engine systems.
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 4 |
| `enum` | 0 |
| `fn` (Lua API) | 0 |
| **Total** | **4** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `event` | Imports or references `event` from `src/event/`. | Cross-group dependency from Edge/Integration to Core Runtime. |
| `image` | Imports or references `image` from `src/image/`. | Cross-group dependency from Edge/Integration to Platform Services. |
| `input` | Imports or references `input` from `src/input/`. | Cross-group dependency from Edge/Integration to Platform Services. |
| `light` | Imports or references `light` from `src/light/`. | Cross-group dependency from Edge/Integration to Platform Services. |
| `lua_api` | Imports or references `lua_api` from `src/lua_api/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |
| `math` | Imports or references `math` from `src/math/`. | Cross-group dependency from Edge/Integration to Foundations. |
| `render` | Imports or references `render` from `src/render/`. | Cross-group dependency from Edge/Integration to Platform Services. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Edge/Integration to Core Runtime. |
| `sprite` | Imports or references `sprite` from `src/sprite/`. | Cross-group dependency from Edge/Integration to Feature Systems. |
| `timer` | Imports or references `timer` from `src/timer/`. | Cross-group dependency from Edge/Integration to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/app/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
- **Lua surface**: This module has no dedicated direct `lurek.*` namespace and is typically consumed through higher integration layers.
