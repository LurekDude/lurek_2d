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

The `log` module provides structured log level management and configurable output sinks for Lua game scripts. It exposes `set_level()`, `get_level()`, and `enabled_for()` on the Rust side, delegating to `crate::engine::log_messages`.

The Lua API at `luna.log.*` allows scripts to emit messages at specific severity levels (`debug`, `info`, `warn`, `error`) with an optional _tag_ string (second argument). Every log function also dispatches to any registered `Sink` destinations beyond the default stderr channel. Game developers can add **file sinks** (append to disk, UTF-8) and **memory sinks** (bounded ring buffer) to route log output to custom destinations — similar to Python's `logging.Handler` model.

`src/lua_api/log_api.rs` maintains a `Rc<RefCell<SinkRegistry>>` that is captured by all log-function closures. `src/log/sinks.rs` provides the `SinkLevel`, `SinkKind`, `Sink`, and `SinkRegistry` types. All Rust `log` crate output still flows through `env_logger` and the `RUST_LOG` environment variable.

**Separation from `devtools`**: `luna.log` routes to stderr via `env_logger` + optional sinks — it is the **operational engine log**. `luna.devtools.logger` is an **in-memory ring buffer** used for in-game diagnostic panels.

## Source Files

| File        | Purpose                                                                                      |
|-------------|----------------------------------------------------------------------------------------------|
| `mod.rs`    | `set_level()`, `get_level()`, `enabled_for()` — delegates to `engine::log_messages`; re-exports `sinks` |
| `sinks.rs`  | `SinkLevel`, `MemoryEntry`, `SinkKind`, `Sink`, `SinkRegistry` — configurable sink dispatch  |

## Lua API additions (v0.5.x)

| Function | Signature | Description |
|---|---|---|
| `debug` | `(msg, tag?)` | Emits debug message; tag defaults to "Lua" |
| `info` | `(msg, tag?)` | Emits info message |
| `warn` | `(msg, tag?)` | Emits warn message |
| `error` | `(msg, tag?)` | Emits error message |
| `addSink` | `(config) → id` | Adds a file or memory sink |
| `removeSink` | `(id) → bool` | Removes a sink by id |
| `clearSinks` | `()` | Removes all sinks |
| `listSinks` | `() → table` | Lists active sinks |
| `readMemory` | `(id, drain?) → table?` | Reads entries from a memory sink |
| `flushFile` | `(id)` | Flushes OS buffer for a file sink |

## Full Specification

See [`specs/log.md`](../../../specs/log.md) for full architecture, type details, Lua API, examples, and notes.
