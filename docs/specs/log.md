# log

## General Info

- Module group: `Foundations`
- Source path: `src/log/`
- Lua API path(s): `src/lua_api/log_api.rs`
- Primary Lua namespace: `lurek.log`
- Rust test path(s): tests/rust/unit/log_tests.rs
- Lua test path(s): tests/lua/unit/test_log.lua

## Summary

The `log` module is Lurek2D's Foundations-tier logging façade exposed to game
scripts through `lurek.log.*`. It wraps the Rust `log` crate so that
game-script output appears alongside engine diagnostic output, all controlled
by `RUST_LOG` and by a per-VM sink routing layer on top of the standard log
channel.

**Global level management**: `set_level(level)`, `get_level()`, and
`enabled_for(level)` delegate to `crate::runtime::log_messages`, giving Lua
scripts a single knob for the global log filter. `enabled_for` lets callers
cheaply check whether a level is active before building an expensive message
string. The four severity helpers — `debug`, `info`, `warn`, `error` — emit
through the standard Rust `log` crate and fan out to any registered sinks.

**Structured logging**: `log_structured(level, msg, fields)` emits a
`msg { k1=v1, … }` formatted record using a `LogFields` sorted map of
string key-value pairs. `debug_fields`, `info_fields`, `warn_fields`, and
`error_fields` are Lua shorthand helpers combining level selection and field
emission in one call, useful for analytics and telemetry pipelines that
need machine-parseable key-value output.

**Sink routing layer**: The `sinks` submodule adds an out-of-band routing
layer on top of the `log` crate output. A `Sink` pairs a `SinkKind` backend
— `File` (append), `Memory` (bounded ring buffer of `MemoryEntry` records), or
`RotatingFile` (rotation by byte count with configurable backup count) — with
an independent `SinkLevel` minimum threshold. This allows capturing all
`debug` output to a rotating log file while keeping only `warn` and above in
the in-memory ring, entirely independently of the global `RUST_LOG` filter.

**SinkRegistry**: Maintains a per-VM ordered list of sinks. `add(sink)`
assigns a numeric ID used for later `remove(id)`, `flush(id)`, or
`read_memory(id, drain)` calls. `dispatch(level, msg)` and
`dispatch_structured(level, msg, fields)` fan out every emitted message to all
registered sinks whose `min_level` is satisfied.

**Memory sinks for in-game UIs**: `read_memory(id, drain)` returns all
buffered `MemoryEntry` records, optionally clearing the buffer, making memory
sinks the natural backing store for in-game log-viewer panels, REPL consoles,
and developer overlays. `listSinks()` in Lua returns a descriptive table for
each registered sink so tooling can display active log destinations at runtime.

**Scope boundary**: Core Runtime tier. Depends on `runtime`. Lua bridge in
`src/lua_api/log_api.rs` as `lurek.log.*`.

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
- `lurek.log.struct`: Emits a structured log message with key-value fields.
- `lurek.log.debug_fields`: Emits a debug structured log message. Shorthand for `struct("debug", ...)`.
- `lurek.log.info_fields`: Emits an info structured log message. Shorthand for `struct("info", ...)`.
- `lurek.log.warn_fields`: Emits a warn structured log message. Shorthand for `struct("warn", ...)`.
- `lurek.log.error_fields`: Emits an error structured log message. Shorthand for `struct("error", ...)`.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/log/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
