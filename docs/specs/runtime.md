# `runtime` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Core Runtime |
| **Status** | Implemented |
| **Lua API** | Indirect / none |
| **Source** | `src/runtime/` |
| **Rust Tests** | `tests/rust/unit/window_tests.rs`, `tests/rust/ext/graphics_runtime_smoke_tests.rs`, plus runtime-focused unit coverage embedded in `src/runtime/messages.rs` |
| **Lua Tests** | `tests/lua/config/test_config.lua`, `tests/lua/harness.rs` |
| **Architecture** | `docs/architecture/engine-architecture.md § Core Runtime` |

---

## Summary

The runtime module is the engine's shared substrate. It defines startup configuration, the canonical engine error type, stable log message IDs, the embedded human-readable message catalog, and the central `SharedState` object that all Lua bindings and the main loop mutate through `Rc<RefCell<_>>`.

This module exists so the rest of Lurek2D can agree on a single source of truth for engine-wide state and identifiers. Rendering, input, audio, events, timers, filesystem access, and many higher-level systems all meet here through typed resource pools, per-frame timing fields, the event queue, and pending runtime actions such as restart, quit, async loads, and screenshots.

It intentionally does not own subsystem behavior. Rendering logic lives in `render`, audio mixing in `audio`, input device state machines in `input`, sandboxed path policy in `filesystem`, and Lua-facing registration in `src/lua_api/`. If a change is about how a subsystem behaves rather than how global state is stored or shared, that change usually belongs outside `runtime`.

**Scope boundary**: This module currently depends on `audio`, `camera`, `event`, `filesystem`, `input`, `light`, `parallax`, `particle`, and other adjacent modules. It stays within the Core Runtime responsibility boundary defined in the architecture docs.

---

## Architecture

```
No direct Lua namespace — consumed through app/runtime integration or other bindings
    |
    v
src/runtime/mod.rs
    |- config.rs - config
    |- error.rs - error
    |- log_messages.rs - log_messages
    |- messages.rs - messages
    |- resource_keys.rs - resource_keys
    |- shared_state.rs - shared_state
```

---

## Source Files

| File | Purpose |
|------|---------|
| `config.rs` | Engine configuration loaded from `conf.toml` (preferred) or `conf.lua` (legacy). |
| `error.rs` | Structured error types and result alias for the Lurek2D engine. |
| `log_messages.rs` | Structured logging with stable message IDs for the Lurek2D engine. |
| `messages.rs` | TOML-backed message catalog for stable, human-readable engine log messages. |
| `mod.rs` | Core engine runtime: configuration, error handling, shared state, and resource management. |
| `resource_keys.rs` | Typed resource keys for generational ID-based resource pools. |
| `shared_state.rs` | Central shared runtime state for the Lurek2D engine. |

---

## Submodules

### `runtime::config`

Engine configuration loaded from `conf.toml` (preferred) or `conf.lua` (legacy).

- **`Config`** (struct): Top-level engine configuration.
- **`GraphicsConfig`** (struct): GPU backend and power-preference settings resolved once at engine startup.
- **`WindowConfig`** (struct): Window dimensions, title, vsync, fullscreen, and resize settings.
- **`ModulesConfig`** (struct): Flags to enable or disable optional engine subsystems.
- **`PerformanceConfig`** (struct): Frame rate cap and other performance tuning options.

### `runtime::error`

Structured error types and result alias for the Lurek2D engine.

- **`ErrorCategory`** (enum): Error category for grouping related engine errors.
- **`EngineError`** (enum): All possible error conditions that can occur in the Lurek2D engine.
- **`EngineResult`** (type): Convenience alias for `Result<T, EngineError>` used throughout the engine.

### `runtime::log_messages`

Structured logging with stable message IDs for the Lurek2D engine.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `runtime::messages`

TOML-backed message catalog for stable, human-readable engine log messages.

- **`MessageCatalog`** (struct): Immutable map from stable message ID (e.g.

### `runtime::resource_keys`

Typed resource keys for generational ID-based resource pools.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `runtime::shared_state`

Central shared runtime state for the Lurek2D engine.

- **`FullscreenType`** (enum): Fullscreen mode type for window management.
- **`WindowState`** (struct): Tracks window state and queues window operations for the event loop.
- **`ErrorInfo`** (struct): Structured error information for the last engine error.
- **`ScreenshotRequest`** (struct): Pending request to save the next rendered screen frame as a PNG.
- **`SharedState`** (struct): Shared mutable state passed via `Rc<RefCell<SharedState>>` to all Lua API closures and the engine loop.
- **`RendererStats`** (struct): Snapshot of renderer statistics for a single frame.

---

## Key Types

### Public Types

#### `Config`

Top-level engine configuration.

#### `GraphicsConfig`

GPU backend and power-preference settings resolved once at engine startup.

#### `WindowConfig`

Window dimensions, title, vsync, fullscreen, and resize settings.

#### `ModulesConfig`

Flags to enable or disable optional engine subsystems.

#### `PerformanceConfig`

Frame rate cap and other performance tuning options.

#### `ErrorCategory`

Error category for grouping related engine errors.

#### `EngineError`

All possible error conditions that can occur in the Lurek2D engine.

#### `EngineResult`

Convenience alias for `Result<T, EngineError>` used throughout the engine.

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
| `struct` | 11 |
| `enum` | 3 |
| `fn` (Lua API) | 0 |
| **Total** | **14** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `audio` | Imports or references `audio` from `src/audio/`. | Cross-group dependency from Core Runtime to Platform Services. |
| `camera` | Imports or references `camera` from `src/camera/`. | Cross-group dependency from Core Runtime to Platform Services. |
| `event` | Imports or references `event` from `src/event/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |
| `filesystem` | Imports or references `filesystem` from `src/filesystem/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |
| `input` | Imports or references `input` from `src/input/`. | Cross-group dependency from Core Runtime to Platform Services. |
| `light` | Imports or references `light` from `src/light/`. | Cross-group dependency from Core Runtime to Platform Services. |
| `parallax` | Imports or references `parallax` from `src/parallax/`. | Cross-group dependency from Core Runtime to Feature Systems. |
| `particle` | Imports or references `particle` from `src/particle/`. | Cross-group dependency from Core Runtime to Feature Systems. |
| `raycaster` | Imports or references `raycaster` from `src/raycaster/`. | Cross-group dependency from Core Runtime to Feature Systems. |
| `render` | Imports or references `render` from `src/render/`. | Cross-group dependency from Core Runtime to Platform Services. |
| `sprite` | Imports or references `sprite` from `src/sprite/`. | Cross-group dependency from Core Runtime to Feature Systems. |
| `tilemap` | Imports or references `tilemap` from `src/tilemap/`. | Cross-group dependency from Core Runtime to Feature Systems. |
| `timer` | Imports or references `timer` from `src/timer/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |
| `ui` | Imports or references `ui` from `src/ui/`. | Cross-group dependency from Core Runtime to Feature Systems. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/runtime/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
- **Lua surface**: This module has no dedicated direct `lurek.*` namespace and is typically consumed through higher integration layers.
