# `log` — Full Specification

| Property         | Value                                                  |
|------------------|--------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                        |
| **Status**       | Implemented — Full                                     |
| **Lua API**      | `lurek.log`                                             |
| **Source**       | `src/log/`                                             |
| **Rust Tests**   | —                                                      |
| **Lua Tests**    | `tests/lua/unit/test_log.lua`                          |
| **Architecture** | —                                                      |

## Summary

The `log` module is the **game developer's logging tool** for Lua scripts. It lets Lua game code emit structured messages at configurable severity levels, so developers can trace game logic, fire debug output, and monitor runtime state without touching Rust code or engine internals.

Internally, `log` is a thin adapter over `crate::engine::log_messages` that exposes `set_level()`, `get_level()`, and `enabled_for()` as Rust functions, and binds them — along with per-severity emit functions — to the `lurek.log.*` Lua namespace.

The Lua API exposes five severity levels: `debug`, `info`, `warn`, `error`, and `trace`. Game scripts can emit at a fixed level (`lurek.log.debug`, `lurek.log.info`, etc.) or at a caller-specified level (`lurek.log.print(level, message)`). The active minimum level can be read and changed at runtime with `lurek.log.getLevel()` and `lurek.log.setLevel(level)`.

All messages are routed through the Rust `log` crate and appear in the engine's standard output alongside engine-originated log lines. Lua-originated messages are prefixed with `[Lua]` to distinguish them. Runtime filtering is controlled by the `RUST_LOG` environment variable (e.g., `RUST_LOG=lurek2d=debug`).

This module intentionally does **not** provide:
- Structured JSON log output — messages are strings only
- Per-script log level overrides — one global level applies to all Lua output
- Log persistence or file output — that is a concern for the engine's `env_logger` configuration

## Architecture

```
src/log/
└── mod.rs    set_level(), get_level(), enabled_for() — domain layer over engine::log_messages

src/engine/
└── log_messages.rs    set_log_level(level), get_log_level() → &'static str

src/lua_api/
└── log_api.rs    Registers lurek.log.* functions:
                  debug, info, warn, error, trace, print → emit via log crate macros
                  setLevel → crate::log::set_level()
                  getLevel → crate::log::get_level()
```

## Source Files

| File     | Purpose                                                                                |
|----------|----------------------------------------------------------------------------------------|
| `mod.rs` | `set_level()`, `get_level()`, `enabled_for()` — delegates to `engine::log_messages`    |

## Submodules

### `log` (root)

- `set_level(level: &str)` — pass-through to `log_messages::set_log_level`; unrecognised values are silently ignored
- `get_level() → String` — returns the current level name (e.g., `"info"`)
- `enabled_for(level: &str) → bool` — compares against `log::max_level()`; accepts `"error"`, `"warn"`, `"warning"`, `"info"`, `"debug"`, `"trace"`; returns `false` for `"off"` and unrecognised values.

> **Architecture note**: `src/lua_api/log_api.rs` calls `crate::log::set_level()` and `crate::log::get_level()` so that the `lua_api` layer uses the domain module as intended.

### `log::sinks` — Configurable Sink Dispatch

`src/log/sinks.rs` adds the **sink system** — a `SinkRegistry` that log functions dispatch to in addition to the default `env_logger` stderr output. This mirrors the `logging.Handler` model from Python: game code and tools can register file sinks (UTF-8 append) or memory sinks (bounded ring buffer) without touching the Rust `log` crate configuration.

#### Key types

| Type | Description |
|---|---|
| `SinkLevel` | `Debug \| Info \| Warn \| Error` — minimum level for a sink |
| `MemoryEntry` | `{ level: String, message: String, tag: String }` — one ring-buffer entry |
| `SinkKind` | `File { file: Mutex<File>, path: String }` or `Memory { entries: Mutex<VecDeque<MemoryEntry>>, capacity: usize }` |
| `Sink` | `{ id: u64, min_level: SinkLevel, kind: SinkKind }` — single output destination |
| `SinkRegistry` | `Vec<Sink>` + `next_id: u64`; `add()`, `remove()`, `clear()`, `dispatch()`, `get()` |

`SinkRegistry` is wrapped in `Rc<RefCell<SinkRegistry>>` at the Lua API layer and captured by every log-function closure.

## Key Types

### Structs

| Type | Location | Description |
|---|---|---|
| `MemoryEntry` | `sinks.rs` | A single ring-buffer log record |
| `Sink` | `sinks.rs` | A configured output destination |
| `SinkRegistry` | `sinks.rs` | Ordered collection of active sinks |

### Enums

| Type | Location | Description |
|---|---|---|
| `SinkLevel` | `sinks.rs` | Min-level filter for a sink |
| `SinkKind` | `sinks.rs` | File vs memory dispatch variant |

## Lua API

The Lua API is registered in `src/lua_api/log_api.rs` under `lurek.log.*`. All emit functions accept an optional second string argument `tag` (defaults to `"Lua"`).

| Function | Signature | Description |
|---|---|---|
| `lurek.log.debug(message, tag?)` | `(string, string?)` | Emit a `debug`-severity message. |
| `lurek.log.info(message, tag?)` | `(string, string?)` | Emit an `info`-severity message. |
| `lurek.log.warn(message, tag?)` | `(string, string?)` | Emit a `warn`-severity message. |
| `lurek.log.error(message, tag?)` | `(string, string?)` | Emit an `error`-severity message. |
| `lurek.log.print(level, message)` | `(string, string)` | Emit at a named level. |
| `lurek.log.setLevel(level)` | `(string)` | Set minimum runtime log level. |
| `lurek.log.getLevel()` | `→ string` | Return current level name. |
| `lurek.log.addSink(cfg) → id` | `(table) → integer` | Add a file or memory sink. `cfg.type = "file"` requires `cfg.path`; `"memory"` accepts `cfg.capacity` (default 200). `cfg.level` sets `SinkLevel` (default `"debug"`). |
| `lurek.log.removeSink(id) → bool` | `(integer) → boolean` | Remove a sink by id. |
| `lurek.log.clearSinks()` | `()` | Remove all sinks. |
| `lurek.log.listSinks() → table` | `() → table` | Returns `{id, type, level, path?}[]`. |
| `lurek.log.readMemory(id, drain?) → table?` | `(integer, boolean?) → table?` | Read memory sink entries. `drain = true` clears after reading. Returns `nil` if not a memory sink. |
| `lurek.log.flushFile(id)` | `(integer)` | Flush OS write buffers for a file sink. No-op if not a file sink. |

## Lua Examples

```lua
-- Basic level-specific logging with optional tag
lurek.log.info("Game initialised")
lurek.log.debug("Player position: x=" .. x, "PlayerSys")  -- tagged
lurek.log.warn("Texture not found, using fallback")

-- Dynamic level selection
lurek.log.print("warn", "fallback asset activated")

-- Runtime level control
lurek.log.setLevel("debug")
lurek.log.setLevel("warn")
print("Active log level:", lurek.log.getLevel())

-- Add a memory sink (ring buffer, capacity 100)
local mem_id = lurek.log.addSink({ type = "memory", capacity = 100 })

-- Read entries from the memory sink
local entries = lurek.log.readMemory(mem_id)      -- non-destructive
local drained = lurek.log.readMemory(mem_id, true) -- clears after read

-- Add a file sink (UTF-8 append)
local ok, file_id = pcall(function()
    return lurek.log.addSink({ type = "file", path = "save/game.log", level = "info" })
end)
if ok then
    lurek.log.flushFile(file_id)
end

-- Inspect active sinks
for _, s in ipairs(lurek.log.listSinks()) do
    print(s.id, s.type, s.level, s.path or "")
end

-- Clean up
lurek.log.clearSinks()
```

## Item Summary

| Kind      | Count |
|-----------|-------|
| `struct`  | 3     |
| `enum`    | 2     |
| `fn`      | 13    |
| **Total** | **18** |

## References

| Module          | Relationship | Notes                                                                    |
|-----------------|--------------|--------------------------------------------------------------------------|
| `engine`        | Imports from | `set_level` and `get_level` delegate to `engine::log_messages`           |
| `lua_api`       | Imported by  | `log_api.rs` registers the `lurek.log.*` surface and owns the `SinkRegistry` |
| `debugbridge`   | Related      | `debugbridge.capturePrint` captures Lua `print()` output; `lurek.log` emits via `log` crate — two separate channels |
| `devtools`      | Related      | `devtools.Logger` is a structured in-game history buffer; `lurek.log` is the engine-level operational log. **Boundary**: three separate channels by design. |

## Notes

- All Lua log messages are prefixed with `[Lua]` in the stdlib `log` crate output.
- `lurek.log.print` with an unknown `level` string falls back to `info`.
- Sinks are dispatched **after** the `log!` macro, so `RUST_LOG` filtering does not suppress sink output.
- `SinkKind::File` uses `Mutex<File>` internally; creating a file sink will fail with a Lua error if the path is not writable — always wrap `addSink` in `pcall`.
- There are no Rust unit tests for this module because all behaviour is a pass-through to `engine::log_messages`; the Lua test in `tests/lua/unit/test_log.lua` validates the Lua API surface.
