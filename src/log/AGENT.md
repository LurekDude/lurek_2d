# `log` — Agent Reference

| Property         | Value                                                  |
|------------------|--------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                        |
| **Status**       | Implemented — Full                                     |
| **Lua API**      | `luna.log`                                             |
| **Source**       | `src/log/`                                             |
| **Rust Tests**   | —                                                      |
| **Lua Tests**    | `tests/lua/unit/test_log.lua`                          |
| **Architecture** | —                                                      |

## Purpose

The `log` module provides structured log level management for Lua game scripts. It exposes `set_level()`, `get_level()`, and `enabled_for()` on the Rust side, delegating to `crate::engine::log_messages`. The Lua API at `luna.log.*` allows scripts to emit messages at specific severity levels (`debug`, `info`, `warn`, `error`, `trace`), to emit at a caller-specified level via `log.print(level, message)`, and to query or change the active minimum log level at runtime with `setLevel`/`getLevel`.

`src/lua_api/log_api.rs` calls `crate::log::set_level()` and `crate::log::get_level()` (the domain module) for level management, then emits actual log output directly via the `log` crate's macros (`log::debug!`, `log::info!`, etc.). All log output flows through the Rust `log` crate and appears alongside engine messages under the `RUST_LOG` environment variable filter. Messages are prefixed with `[Lua]` to distinguish them from engine-originated output.

**Separation from `devtools`**: `luna.log` routes to stdout via `env_logger` — it is the **operational engine log**. `luna.devtools.logger` is an **in-memory ring buffer** used for in-game diagnostic panels. These serve different consumers and must not be conflated.

## Source Files

| File     | Purpose                                                                                 |
|----------|-----------------------------------------------------------------------------------------|
| `mod.rs` | `set_level()`, `get_level()`, `enabled_for()` — delegates to `engine::log_messages`     |

## Full Specification

See [`specs/log.md`](../../../specs/log.md) for full architecture, type details, Lua API, examples, and notes.
