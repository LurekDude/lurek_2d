# log

## General Info

- Module group: `Foundations`
- Source path: `src/log/`
- Lua API path(s): `src/lua_api/log_api.rs`
- Primary Lua namespace: `lurek.log`
- Rust test path(s): tests/rust/unit/log_tests.rs
- Lua test path(s): tests/lua/unit/test_log_core_unit.lua

## Summary

The `log` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `runtime`. Its responsibility should stay inside the Foundations group rather than absorb behavior owned by those neighbors.

## Files

- `facade.rs`: Structured logging facade exposed to Lua through `lurek.log.*`.
- `mod.rs`: Defines the small public domain surface for setting and querying the active log level and re-exports sink-related types.
- `sinks.rs`: Implements sink filtering and fan-out, including file-backed sinks, bounded memory sinks backed by `data::RingBuffer<MemoryEntry>`, and the registry that tracks active outputs.

## Types

- `LogFields` (`type`, `facade.rs`): Sorted map of structured key-value log fields.
- `SinkLevel` (`enum`, `sinks.rs`): Severity threshold used by sink filtering. It keeps file and memory sinks consistent even when the Lua caller uses string level names and now includes `Trace`.
- `MemoryEntry` (`struct`, `sinks.rs`): Captured log record stored by memory sinks. It is intentionally small so Lua tooling can inspect recent messages without coupling to the Rust `log` crate.
- `RotatingFileSink` (`struct`, `sinks.rs`): A file sink that rotates the log file when it exceeds a maximum size.
- `SinkKind` (`enum`, `sinks.rs`): Backend enum for the supported sink storage strategies. It distinguishes append-to-file behavior from bounded in-memory buffering and callback sinks.
- `Sink` (`struct`, `sinks.rs`): Single output destination with an id, minimum level, and concrete backend. It is the unit the Lua API creates, lists, flushes, and removes.
- `SinkRegistry` (`struct`, `sinks.rs`): Mutable collection of active sinks for one runtime context. The Lua layer keeps one registry per VM and uses it to fan out every emitted message.

## Functions

- `log_structured` (`facade.rs`): Emits a structured log message with key-value `fields` through the Rust `log` crate.
- `set_level` (`facade.rs`): Sets the active log level to the named value.
- `get_level` (`facade.rs`): Returns the current log level name as a static string (e.g.
- `enabled_for` (`facade.rs`): Returns `true` when messages at `level` would be emitted under the current filter.
- `SinkLevel::as_str` (`sinks.rs`): Return the uppercase string label for this level.
- `RotatingFileSink::open` (`sinks.rs`): Open or create the log file at `path`; returns error if the file cannot be opened.
- `RotatingFileSink::write_with_rotation` (`sinks.rs`): Append `message` to the file, triggering rotation when `max_bytes` is exceeded.
- `RotatingFileSink::flush` (`sinks.rs`): Flush pending OS buffers to disk for the active file.
- `Sink::file` (`sinks.rs`): Create a plain append-only file sink; returns error if the file cannot be opened.
- `Sink::memory` (`sinks.rs`): Create an in-memory ring-buffer sink with `capacity` entries.
- `Sink::rotating_file` (`sinks.rs`): Create a rotating file sink; returns error if `RotatingFileSink::open` fails.
- `Sink::callback` (`sinks.rs`): Create a callback sink that records `callback_id` for Lua dispatch; crate-internal.
- `Sink::configure_output` (`sinks.rs`): Configure output format, timestamp inclusion, color, and tag filter list; crate-internal.
- `Sink::write` (`sinks.rs`): Write an unstructured message if `level >= min_level` and tag is allowed.
- `Sink::write_structured` (`sinks.rs`): Write a structured message with key-value `fields` if `level >= min_level` and tag is allowed.
- `Sink::type_name` (`sinks.rs`): Return a static string naming the sink variant: "file", "memory", "rotating", or "callback".
- `Sink::path` (`sinks.rs`): Return the file path for file and rotating sinks; returns `None` for memory and callback.
- `Sink::read_memory` (`sinks.rs`): Return buffered memory entries; drains the ring buffer when `drain` is true.
- `Sink::flush` (`sinks.rs`): Flush the coalescing buffer and OS buffers for file-backed sinks.
- `SinkRegistry::new` (`sinks.rs`): Create an empty registry with `next_id` starting at 1.
- `SinkRegistry::add` (`sinks.rs`): Add `sink` to the registry, assign a unique id, and return that id.
- `SinkRegistry::remove` (`sinks.rs`): Remove the sink with `id`; returns `true` if a sink was removed.
- `SinkRegistry::clear` (`sinks.rs`): Remove all registered sinks.
- `SinkRegistry::dispatch` (`sinks.rs`): Dispatch an unstructured message to all sinks that accept `level` and `tag`.
- `SinkRegistry::dispatch_structured` (`sinks.rs`): Dispatch a structured message with `fields` to all sinks that accept `level` and `tag`.
- `SinkRegistry::get` (`sinks.rs`): Return a shared reference to the sink with `id`, or `None` if not found.

## Lua API Reference

- Binding path(s): `src/lua_api/log_api.rs`
- Namespace: `lurek.log`

### Module Functions
- `lurek.log.debug`: Logs a debug message with an optional tag.
- `lurek.log.info`: Logs an info message with an optional tag.
- `lurek.log.warn`: Logs a warning message with an optional tag.
- `lurek.log.error`: Logs an error message with an optional tag.
- `lurek.log.print`: Logs a message at a runtime-selected level with an optional tag.
- `lurek.log.setLevel`: Sets the global log level.
- `lurek.log.getLevel`: Returns the global log level string.
- `lurek.log.addSink`: Adds a memory, file, rotating, or callback sink from a config table.
- `lurek.log.removeSink`: Removes a sink by id and releases any callback registry key.
- `lurek.log.clearSinks`: Removes all sinks and releases callback registry keys.
- `lurek.log.listSinks`: Returns metadata for all registered sinks.
- `lurek.log.readMemory`: Reads entries from a memory sink and optionally drains them.
- `lurek.log.flushFile`: Flushes a file-backed sink by id when it exists.
- `lurek.log.struct`: Logs a structured message at a runtime-selected level.
- `lurek.log.debug_fields`: Logs a debug message with structured fields.
- `lurek.log.info_fields`: Logs an info message with structured fields.
- `lurek.log.warn_fields`: Logs a warning message with structured fields.
- `lurek.log.error_fields`: Logs an error message with structured fields.

## References

- `data`: Imports or references `src/data/`. Dependency stays inside `Foundations` and should remain acyclic.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/log/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
