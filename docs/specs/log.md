# log

## General Info

- Module group: `Foundations`
- Source path: `src/log/`
- Lua API path(s): `src/lua_api/log_api.rs`
- Primary Lua namespace: `lurek.log`
- Rust test path(s): tests/rust/unit/log_tests.rs
- Lua test path(s): tests/lua/unit/test_log.lua

## Summary

The `log` module provides Lurek2D's Lua-accessible logging interface and its configurable sink system. It wraps the Rust `log` crate facade so that game scripts can emit structured log messages alongside engine log output, controlled by the `RUST_LOG` environment variable.

The public module-level functions (`set_level`, `get_level`, `enabled_for`) delegate to `crate::runtime::log_messages` for global log level management. These are what the `lurek.log.*` Lua API exposes for log filtering.

The `sinks` submodule adds an out-of-band log routing layer on top of the standard `log` crate output. A `Sink` is a trait with a single `write(entry: &MemoryEntry)` method. `SinkRegistry` maintains a list of registered `Sink` implementations. Two built-in sinks are provided: `FileSink` appends formatted log entries to a file path with optional rotation; `MemorySink` keeps a fixed-size ring buffer of the last N `MemoryEntry` records accessible from Lua for in-game debug consoles. Each sink has an independent `SinkLevel` threshold so, for example, the file sink can capture all `debug` output while the in-memory sink captures only `warn` and above.

Log output from game scripts appears alongside engine log output. The separation between the `log` crate global level (controlled by `RUST_LOG`) and the per-sink `SinkLevel` lets developers have fine-grained control over where different severity messages appear.

**Scope boundary**: Core Runtime tier. Depends on `runtime`. Lua bridge in `src/lua_api/log_api.rs`.

## Files

- `mod.rs`: Defines the small public domain surface for setting and querying the active log level and re-exports sink-related types.
- `sinks.rs`: Implements sink filtering and fan-out, including file-backed sinks, bounded memory sinks, and the registry that tracks active outputs.

## Types

- `SinkLevel` (`enum`, `sinks.rs`): Severity threshold used by sink filtering. It keeps file and memory sinks consistent even when the Lua caller uses string level names.
- `MemoryEntry` (`struct`, `sinks.rs`): Captured log record stored by memory sinks. It is intentionally small so Lua tooling can inspect recent messages without coupling to the Rust `log` crate.
- `SinkKind` (`enum`, `sinks.rs`): Backend enum for the supported sink storage strategies. It distinguishes append-to-file behavior from bounded in-memory buffering.
- `Sink` (`struct`, `sinks.rs`): Single output destination with an id, minimum level, and concrete backend. It is the unit the Lua API creates, lists, flushes, and removes.
- `SinkRegistry` (`struct`, `sinks.rs`): Mutable collection of active sinks for one runtime context. The Lua layer keeps one registry per VM and uses it to fan out every emitted message.

## Functions

- `set_level` (`mod.rs`): Sets the active log level to the named value.
- `get_level` (`mod.rs`): Returns the current log level name as a static string (e.g.
- `enabled_for` (`mod.rs`): Returns `true` when messages at `level` would be emitted under the current filter.
- `SinkLevel::from_str` (`sinks.rs`): Parses a level string ("debug", "info", "warn", "error").
- `SinkLevel::as_str` (`sinks.rs`): Returns a short lowercase string representation.
- `Sink::file` (`sinks.rs`): Creates a file sink.
- `Sink::memory` (`sinks.rs`): Creates a memory sink.
- `Sink::write` (`sinks.rs`): Dispatches a log entry to this sink (no-op when below `min_level`).
- `Sink::type_name` (`sinks.rs`): Returns the sink type name string.
- `Sink::path` (`sinks.rs`): Returns the path for a file sink, or `None`.
- `Sink::read_memory` (`sinks.rs`): Reads all memory entries and optionally drains them.
- `Sink::flush` (`sinks.rs`): Flushes a file sink (no-op on memory sinks).
- `SinkRegistry::new` (`sinks.rs`): Creates an empty registry.
- `SinkRegistry::add` (`sinks.rs`): Adds a sink, returning its assigned id.
- `SinkRegistry::remove` (`sinks.rs`): Removes a sink by id.
- `SinkRegistry::clear` (`sinks.rs`): Removes all sinks.
- `SinkRegistry::dispatch` (`sinks.rs`): Dispatches a log entry to all registered sinks.
- `SinkRegistry::get` (`sinks.rs`): Returns a sink by id.

## Lua API Reference

- Binding path(s): `src/lua_api/log_api.rs`
- Namespace: `lurek.log`

### Module Functions
- `lurek.log.debug`: Emits a debug-severity log message. Also dispatches to configured sinks.
- `lurek.log.info`: Emits an info-severity log message. Also dispatches to configured sinks.
- `lurek.log.warn`: Emits a warn-severity log message. Also dispatches to configured sinks.
- `lurek.log.error`: Emits an error-severity log message. Also dispatches to configured sinks.
- `lurek.log.print`: Emits a log message at the specified level. Also dispatches to sinks.
- `lurek.log.setLevel`: Sets the minimum severity level for the default log channel.
- `lurek.log.getLevel`: Returns the name of the currently active minimum log level.
- `lurek.log.addSink`: Registers a new output sink. Returns its numeric id.
- `lurek.log.removeSink`: Removes a sink by id. Returns true if one was removed.
- `lurek.log.clearSinks`: Removes all registered sinks (the default stderr channel is unaffected).
- `lurek.log.listSinks`: Returns a table describing all registered sinks.
- `lurek.log.readMemory`: Reads entries from a memory sink. If drain=true the buffer is cleared.
- `lurek.log.flushFile`: Flushes the OS write buffer for a file sink.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/log/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
