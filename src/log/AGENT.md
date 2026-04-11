# log

## Module Info
- Module name: `log`
- Module group: `Foundations`
- Spec path: `docs/specs/log.md`
- Lua API path(s): `src/lua_api/log_api.rs`
- Rust test path(s): `tests/rust/unit/log_tests.rs`
- Lua test path(s): `tests/lua/unit/test_log.lua`

## Module Purpose
The `log` module owns the engine-facing logging domain that Lua scripts and other code can target without talking directly to the global logging backend. It provides a thin, stable layer for log level control and for dispatching script-originated messages into additional sinks such as files and in-memory ring buffers.

This module exists to separate logging policy from Lua registration code. The domain types in `src/log/` define what a sink is, how entries are filtered, and how sink fan-out works, while `src/lua_api/log_api.rs` decides how that functionality is exposed under `lurek.log` for a single VM.

`log` intentionally does not own engine-wide logger initialization, formatting, `RUST_LOG` parsing, or the general diagnostic UI story. It delegates level storage to `runtime::log_messages`, and it does not replace `devtools` or `debugbridge`, which serve different debugging and capture workflows.

## Files
- `mod.rs`: Defines the small public domain surface for setting and querying the active log level and re-exports sink-related types.
- `sinks.rs`: Implements sink filtering and fan-out, including file-backed sinks, bounded memory sinks, and the registry that tracks active outputs.

## Key Types
- `SinkLevel`: Severity threshold used by sink filtering. It keeps file and memory sinks consistent even when the Lua caller uses string level names.
- `MemoryEntry`: Captured log record stored by memory sinks. It is intentionally small so Lua tooling can inspect recent messages without coupling to the Rust `log` crate.
- `SinkKind`: Backend enum for the supported sink storage strategies. It distinguishes append-to-file behavior from bounded in-memory buffering.
- `Sink`: Single output destination with an id, minimum level, and concrete backend. It is the unit the Lua API creates, lists, flushes, and removes.
- `SinkRegistry`: Mutable collection of active sinks for one runtime context. The Lua layer keeps one registry per VM and uses it to fan out every emitted message.
