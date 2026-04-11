# `runtime` — Agent Reference

| Property         | Value                                                                         |
|------------------|-------------------------------------------------------------------------------|
| **Tier**         | Baseline — always-on runtime substrate                                        |
| **Status**       | Implemented — Full                                                            |
| **Lua API**      | — (foundation module; no dedicated `lurek.runtime` namespace)                 |
| **Source**       | `src/runtime/`                                                                |
| **Rust Tests**   | `tests/rust/unit/engine_tests.rs`                                             |
| **Lua Tests**    | —                                                                             |
| **Architecture** | `docs/architecture/engine-architecture.md` § Baseline Tier                   |

## Purpose

`src/runtime/` is the foundational substrate of Lurek2D. It owns configuration loading,
the central shared mutable state (`SharedState`), the structured error taxonomy
(`EngineError`), stable log-message IDs, a TOML-backed message catalog, and the 14 typed
`SlotMap` resource keys that identify every GPU and audio object in the engine. It sits at
the Baseline tier alongside `src/math/`, meaning every other module may freely import from
it. The runtime itself has no incoming engine-module dependencies.

## Source Files

| File                | Purpose                                                                       |
|---------------------|-------------------------------------------------------------------------------|
| `mod.rs`            | Re-exports `Config`, `SharedState`, `EngineError`, all resource key types.    |
| `config.rs`         | `Config`, `WindowConfig`, `GraphicsConfig`, `ModulesConfig`, `PerformanceConfig`. |
| `error.rs`          | `EngineError` (12 variants, stable codes `E001`–`E012`), `ErrorCategory`, `EngineResult<T>`. |
| `log_messages.rs`   | Stable message ID constants (`L001`–`L082`, `A001`–`A004`), `log_msg!` macro. |
| `messages.rs`       | `MessageCatalog` — TOML-backed message lookup via `init()`, `get_message()`.  |
| `resource_keys.rs`  | 14 typed `SlotMap` key newtypes for every resource category.                  |
| `shared_state.rs`   | `SharedState`, `WindowState`, `FullscreenType`, `ErrorInfo`, `ScreenshotRequest`. |
| `cfg/messages.toml` | TOML message strings, embedded at compile time via `include_str!`.            |

## Full Specification

Full spec: [`docs/specs/runtime.md`](../../../docs/specs/runtime.md)
