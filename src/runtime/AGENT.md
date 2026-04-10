# `engine` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Baseline — always-on runtime substrate               |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | — (foundation module; no dedicated `lurek.engine` namespace) |
| **Source**     | `src/runtime/`                                        |
| **Rust Tests** | `tests/rust/unit/engine_tests.rs`                    |
| **Lua Tests**  | —                                                    |
| **Architecture** | `docs/architecture/engine-architecture.md`          |

## Purpose

The engine module is the foundational layer of Lurek2D — it owns the application
lifecycle, the main game loop, configuration loading, shared mutable state, error
handling, structured logging, and the typed resource keys that identify every GPU
object in the engine.  It sits at the Baseline tier alongside `math`, meaning every
other module in the system may import from it.  No domain module imports `lua_api`;
engine is the only upward-facing dependency root.

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | Module declaration, re-exports of `App`, `Config`, `SharedState`, `EngineError`, etc. |
| `app.rs` | Application lifecycle: `App`, private `LunaApp` (winit `ApplicationHandler`), `RunState`, game loop, GPU init, Lua VM init, input routing, PNG-branded splash screen, drag-and-drop, window title state |
| `app_winit.rs` | **Dead file** — not declared in `mod.rs`, not compiled. Preserved for historical reference only. |
| `config.rs` | `Config`, `WindowConfig`, `GraphicsConfig`, `ModulesConfig`, `PerformanceConfig`, `conf.lua` loading |
| `debug_overlay.rs` | `DebugOverlay` — FPS and draw-call counter rendered in the top-right corner |
| `error.rs` | `EngineError` (12 variants with stable codes), `ErrorCategory`, `EngineResult<T>` |
| `error_screen.rs` | `ErrorScreen` — blue error display with word-wrap, traceback, TTF/bitmap text rendering |
| `log_messages.rs` | Stable message ID constants (`L001`–`L082`, `A001`–`A004`, `G001`–`G005`, `P001`–`P002`, etc.), `set_log_level`/`get_log_level`, `log_msg!` macro |
| `messages.rs` | `MessageCatalog` — TOML-backed message lookup; `init()`, `get_message()`, `catalog()` functions |
| `resource_keys.rs` | 14 typed SlotMap key newtypes: `TextureKey`, `FontKey`, `CanvasKey`, `SoundKey`, `ParticleKey`, `SpriteBatchKey`, `ShaderKey`, `MeshKey`, `ShapeKey`, `BusKey`, `MidiPlayerKey`, `QueueableKey`, `LightKey`, `OccluderKey` |
| `shared_state.rs` | `SharedState`, `WindowState`, `FullscreenType`, `ErrorInfo`, `ScreenshotRequest` |
| `temp_test.rs` | Placeholder file — contains only the text `testing`, not compiled |
| `cfg/messages.toml` | TOML catalog of human-readable log message strings, embedded at compile time |

## Key Types

| Type | Description |
|------|-------------|
| `App` | Principal type for the `engine` module. |
| `Config` | Principal type for the `engine` module. |
| `GraphicsConfig` | Principal type for the `engine` module. |
| `WindowConfig` | Principal type for the `engine` module. |
| `ModulesConfig` | Principal type for the `engine` module. |
| `PerformanceConfig` | Principal type for the `engine` module. |
| `DebugOverlay` | Principal type for the `engine` module. |
| `ErrorCategory` | Principal type for the `engine` module. |
| `EngineError` | Principal type for the `engine` module. |
| `ErrorScreen` | Principal type for the `engine` module. |
| `MessageCatalog` | Principal type for the `engine` module. |
| `FullscreenType` | Principal type for the `engine` module. |

## Lua API Summary

_No `lurek.*` bindings registered for this module._

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/engine.md`](../../docs/specs/engine.md)

_Update both this file **and** `docs/specs/engine.md` whenever source files, public types, or Lua bindings change._
