# `runtime` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Baseline — always-on runtime substrate               |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | — (foundation module; no dedicated `lurek.runtime` namespace) |
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

| File               | Purpose                                                                       |
|--------------------|-------------------------------------------------------------------------------|
| `mod.rs`           | Re-exports `Config`, `SharedState`, `EngineError`, resource key types, and the `create_lua_vm` entry point. |
| `config.rs`        | `Config`, `WindowConfig`, `GraphicsConfig`, `ModulesConfig`, `PerformanceConfig` — loaded from `conf.lua` via a temporary Lua VM. |
| `error.rs`         | `EngineError` (12 variants with stable codes), `ErrorCategory`, `EngineResult<T>`. |
| `log_messages.rs`  | Stable message ID constants (`L001`–`L082`, `A001`–`A004`, etc.), `set_log_level`/`get_log_level`, `log_msg!` macro. |
| `messages.rs`      | `MessageCatalog` — TOML-backed message lookup via `init()`, `get_message()`, `catalog()`. |
| `resource_keys.rs` | 14 typed SlotMap key newtypes: `TextureKey`, `FontKey`, `CanvasKey`, `SoundKey`, `ParticleKey`, `SpriteBatchKey`, `ShaderKey`, `MeshKey`, `ShapeKey`, `BusKey`, `MidiPlayerKey`, `QueueableKey`, `LightKey`, `OccluderKey`. |
| `shared_state.rs`  | `SharedState`, `WindowState`, `FullscreenType`, `ErrorInfo`, `ScreenshotRequest`. |
| `cfg/messages.toml`| TOML catalog of human-readable log message strings, embedded at compile time. |

## Key Types

| Type               | Description                                                                          |
|--------------------|--------------------------------------------------------------------------------------|
| `Config`           | Full engine configuration loaded from `conf.lua`; contains `WindowConfig`, `GraphicsConfig`, `ModulesConfig`, `PerformanceConfig`. |
| `SharedState`      | Central mutable state shared between the engine loop and all Lua closures via `Rc<RefCell<SharedState>>`. |
| `EngineError`      | 12-variant error enum with stable codes; all engine errors convert to `LuaError` at the Lua boundary. |
| `ModulesConfig`    | Feature-flag struct controlling which `lurek.*` namespaces are registered.          |
| `ResourceKey types`| 14 typed `SlotMap` key newtypes identifying GPU resources (`TextureKey`, `FontKey`, `CanvasKey`, etc.). |
| `MessageCatalog`   | TOML-backed string lookup for all engine log messages.                              |

## Lua API Summary

_No `lurek.*` bindings registered for this module._  It is the runtime substrate
consumed by every other module.

## Full Specification

→ [`docs/specs/app.md`](../../docs/specs/app.md)

_Update both `src/runtime/AGENT.md` **and** `docs/specs/app.md` whenever config fields, resource keys, or shared-state fields change._
