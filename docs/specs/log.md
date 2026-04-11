# `log` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Foundations |
| **Status** | Implemented |
| **Lua API** | `lurek.log` |
| **Source** | `src/log/` |
| **Rust Tests** | `tests/rust/unit/log_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_log.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Foundations` |

---

## Summary

The `log` module owns the engine-facing logging domain that Lua scripts and other code can target without talking directly to the global logging backend. It provides a thin, stable layer for log level control and for dispatching script-originated messages into additional sinks such as files and in-memory ring buffers.

This module exists to separate logging policy from Lua registration code. The domain types in `src/log/` define what a sink is, how entries are filtered, and how sink fan-out works, while `src/lua_api/log_api.rs` decides how that functionality is exposed under `lurek.log` for a single VM.

`log` intentionally does not own engine-wide logger initialization, formatting, `RUST_LOG` parsing, or the general diagnostic UI story. It delegates level storage to `runtime::log_messages`, and it does not replace `devtools` or `debugbridge`, which serve different debugging and capture workflows.

**Scope boundary**: This module currently depends on `runtime`. It stays within the Foundations responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.log.* (Lua API — src/lua_api/log_api.rs)
    |
    v
src/log/mod.rs
    |- sinks.rs - sinks
```

---

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | Defines the small public domain surface for setting and querying the active log level and re-exports sink-related types. |
| `sinks.rs` | Implements sink filtering and fan-out, including file-backed sinks, bounded memory sinks, and the registry that tracks active outputs. |

---

## Submodules

### `log::sinks`

Implements sink filtering and fan-out, including file-backed sinks, bounded memory sinks, and the registry that tracks active outputs.

- **`SinkLevel`** (enum): Minimum log level that a sink will accept.
- **`MemoryEntry`** (struct): A single log entry retained by a [`SinkKind::Memory`] sink.
- **`SinkKind`** (enum): The dispatching strategy for a registered sink.
- **`Sink`** (struct): A registered log output destination.
- **`SinkRegistry`** (struct): Thread-local registry of active log sinks.

---

## Key Types

### Public Types

#### `SinkLevel`

Severity threshold used by sink filtering.

#### `MemoryEntry`

Captured log record stored by memory sinks.

#### `SinkKind`

Backend enum for the supported sink storage strategies.

#### `Sink`

Single output destination with an id, minimum level, and concrete backend.

#### `SinkRegistry`

Mutable collection of active sinks for one runtime context.

---

## Lua API

Exposed under `lurek.log.*` by `src/lua_api/log_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.log.debug` | Emits a debug-severity log message. Also dispatches to configured sinks. |
| `lurek.log.info` | Emits an info-severity log message. Also dispatches to configured sinks. |
| `lurek.log.warn` | Emits a warn-severity log message. Also dispatches to configured sinks. |
| `lurek.log.error` | Emits an error-severity log message. Also dispatches to configured sinks. |
| `lurek.log.print` | Emits a log message at the specified level. Also dispatches to sinks. |
| `lurek.log.setLevel` | Sets the minimum severity level for the default log channel. |
| `lurek.log.getLevel` | Returns the name of the currently active minimum log level. |
| `lurek.log.addSink` | Registers a new output sink. Returns its numeric id. |
| `lurek.log.removeSink` | Removes a sink by id. Returns true if one was removed. |
| `lurek.log.clearSinks` | Removes all registered sinks (the default stderr channel is unaffected). |
| `lurek.log.listSinks` | Returns a table describing all registered sinks. |
| `lurek.log.readMemory` | Reads entries from a memory sink. If drain=true the buffer is cleared. |
| `lurek.log.flushFile` | Flushes the OS write buffer for a file sink. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.log.
if lurek.log then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 3 |
| `enum` | 2 |
| `fn` (Lua API) | 13 |
| **Total** | **18** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Foundations to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/log/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
