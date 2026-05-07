# log

## General Info

- Module group: `Foundations`
- Source path: `src/log/`
- Lua API path(s): `src/lua_api/log_api.rs`
- Primary Lua namespace: `lurek.log`
- Rust test path(s): tests/rust/unit/log_tests.rs
- Lua test path(s): tests/lua/unit/test_log.lua

## Summary

The `log` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `runtime`. Its responsibility should stay inside the Foundations group rather than absorb behavior owned by those neighbors.

## Files

- `facade.rs`: Structured logging facade exposed to Lua through `lurek.log.*`.
- `mod.rs`: Defines the small public domain surface for setting and querying the active log level and re-exports sink-related types.
- `sinks.rs`: Implements sink filtering and fan-out, including file-backed sinks, bounded memory sinks, and the registry that tracks active outputs.

## Types

- `LogFields` (`type`, `facade.rs`): Sorted map of structured key-value log fields.
- `SinkLevel` (`enum`, `sinks.rs`): Severity threshold used by sink filtering. It keeps file and memory sinks consistent even when the Lua caller uses string level names.
- `MemoryEntry` (`struct`, `sinks.rs`): Captured log record stored by memory sinks. It is intentionally small so Lua tooling can inspect recent messages without coupling to the Rust `log` crate.
- `RotatingFileSink` (`struct`, `sinks.rs`): A file sink that rotates the log file when it exceeds a maximum size.
- `SinkKind` (`enum`, `sinks.rs`): Backend enum for the supported sink storage strategies. It distinguishes append-to-file behavior from bounded in-memory buffering.
- `Sink` (`struct`, `sinks.rs`): Single output destination with an id, minimum level, and concrete backend. It is the unit the Lua API creates, lists, flushes, and removes.
- `SinkRegistry` (`struct`, `sinks.rs`): Mutable collection of active sinks for one runtime context. The Lua layer keeps one registry per VM and uses it to fan out every emitted message.

## Functions

- `log_structured` (`facade.rs`): Emits a structured log message with key-value `fields` through the Rust `log` crate.
- `set_level` (`facade.rs`): Sets the active log level to the named value.
- `get_level` (`facade.rs`): Returns the current log level name as a static string (e.g.
- `enabled_for` (`facade.rs`): Returns `true` when messages at `level` would be emitted under the current filter.
- `SinkLevel::from_str` (`sinks.rs`): Parses a level string (case-insensitive).
- `SinkLevel::as_str` (`sinks.rs`): Returns the canonical uppercase display string (`"DEBUG"`, `"INFO"`, `"WARN"`, `"ERROR"`).
- `RotatingFileSink::open` (`sinks.rs`): Opens or creates a rotating file sink at `path`.
- `RotatingFileSink::write_with_rotation` (`sinks.rs`): Appends `message` to the active log file, rotating if the size threshold is exceeded.
- `RotatingFileSink::flush` (`sinks.rs`): Flushes the underlying OS write buffer.
- `Sink::file` (`sinks.rs`): Creates a file sink.
- `Sink::memory` (`sinks.rs`): Creates a memory sink.
- `Sink::rotating_file` (`sinks.rs`): Creates a rotating file sink that rotates at `max_bytes` and keeps `keep_files` backups.
- `Sink::write` (`sinks.rs`): Dispatches a log entry to this sink (no-op when below `min_level`).
- `Sink::write_structured` (`sinks.rs`): Dispatches a structured log entry with key-value `fields` to this sink.
- `Sink::type_name` (`sinks.rs`): Returns the sink type name string.
- `Sink::path` (`sinks.rs`): Returns the path for a file sink, or `None`.
- `Sink::read_memory` (`sinks.rs`): Reads all entries from a memory sink and optionally drains them.
- `Sink::flush` (`sinks.rs`): Flushes a file sink (no-op on memory sinks).
- `SinkRegistry::new` (`sinks.rs`): Creates an empty registry.
- `SinkRegistry::add` (`sinks.rs`): Adds a sink, returning its assigned id.
- `SinkRegistry::remove` (`sinks.rs`): Removes a sink by id.
- `SinkRegistry::clear` (`sinks.rs`): Removes all sinks.
- `SinkRegistry::dispatch` (`sinks.rs`): Dispatches a log entry to all registered sinks.
- `SinkRegistry::dispatch_structured` (`sinks.rs`): Dispatches a structured log entry to all registered sinks.
- `SinkRegistry::get` (`sinks.rs`): Returns a sink by id.

## Lua API Reference

- Binding path(s): `src/lua_api/log_api.rs`
- Namespace: `lurek.log`

### Module Functions
- `lurek.log.debug`: Emits a message at debug severity to the engine log and all registered sinks.
- `lurek.log.info`: Emits a message at info severity to the engine log and all registered sinks.
- `lurek.log.warn`: Emits a message at warning severity to the engine log and all registered sinks.
- `lurek.log.error`: Emits a message at error severity to the engine log and all registered sinks.
- `lurek.log.print`: Emits a log message at an arbitrary severity level specified as a string.
- `lurek.log.setLevel`: Sets the global minimum severity threshold for the engine log backend.
- `lurek.log.getLevel`: Returns the name of the current global minimum severity threshold as a lowercase string (e.g.
- `lurek.log.addSink`: Creates and registers a new log output sink from the given configuration table.
- `lurek.log.removeSink`: Removes a previously registered log sink by its numeric identifier.
- `lurek.log.clearSinks`: Removes every registered log sink, returning the logging system to its default state where messages go only to the engine log backend (stderr).
- `lurek.log.listSinks`: Returns an array-like table where each entry is a table describing one registered sink.
- `lurek.log.readMemory`: Reads log entries stored in a memory-type sink.
- `lurek.log.flushFile`: Forces the operating system to write any buffered data for a file-type sink to disk.
- `lurek.log.struct`: Emits a structured log message that includes arbitrary key-value metadata alongside the human-readable text.
- `lurek.log.debug_fields`: Emits a structured log message at debug severity with key-value metadata.
- `lurek.log.info_fields`: Emits a structured log message at info severity with key-value metadata.
- `lurek.log.warn_fields`: Emits a structured log message at warning severity with key-value metadata.
- `lurek.log.error_fields`: Emits a structured log message at error severity with key-value metadata.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/log/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
