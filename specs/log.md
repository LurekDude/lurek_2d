# `log` — Full Specification

| Property         | Value                                                  |
|------------------|--------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                        |
| **Status**       | Implemented — Full                                     |
| **Lua API**      | `luna.log`                                             |
| **Source**       | `src/log/`                                             |
| **Rust Tests**   | —                                                      |
| **Lua Tests**    | `tests/lua/unit/test_log.lua`                          |
| **Architecture** | —                                                      |

## Summary

The `log` module provides structured log level management for Lua game scripts. It is a thin adapter over `crate::engine::log_messages` that exposes `set_level()`, `get_level()`, and `enabled_for()` as Rust functions, and binds them — along with per-severity emit functions — to the `luna.log.*` Lua namespace.

The Lua API exposes five severity levels: `debug`, `info`, `warn`, `error`, and `trace`. Game scripts can emit at a fixed level (`luna.log.debug`, `luna.log.info`, etc.) or at a caller-specified level (`luna.log.print(level, message)`). The active minimum level can be read and changed at runtime with `luna.log.getLevel()` and `luna.log.setLevel(level)`.

All messages are routed through the Rust `log` crate and appear in the engine's standard output alongside engine-originated log lines. Lua-originated messages are prefixed with `[Lua]` to distinguish them. Runtime filtering is controlled by the `RUST_LOG` environment variable (e.g., `RUST_LOG=luna2d=debug`).

This module intentionally does **not** provide:
- Structured JSON log output — messages are strings only
- Per-script log level overrides — one global level applies to all Lua output
- Log persistence or file output — that is a concern for the engine's `env_logger` configuration

## Architecture

```
src/log/
└── mod.rs    set_level(), get_level(), enabled_for() — thin delegates to engine

src/engine/
└── log_messages.rs    set_log_level(level), get_log_level() → &'static str

src/lua_api/
└── log_api.rs    Registers luna.log.* functions:
                  debug, info, warn, error, print, setLevel, getLevel
```

## Source Files

| File     | Purpose                                                                                |
|----------|----------------------------------------------------------------------------------------|
| `mod.rs` | `set_level()`, `get_level()`, `enabled_for()` — delegates to `engine::log_messages`    |

## Submodules

### `log` (root)

- `set_level(level: &str)` — pass-through to `log_messages::set_log_level`; unrecognised values are silently ignored
- `get_level() → String` — returns the current level name (e.g., `"info"`)
- `enabled_for(level: &str) → bool` — compares against `log::max_level()`; accepts `"error"`, `"warn"`, `"warning"`, `"info"`, `"debug"`, `"trace"`; returns `false` for `"off"` and unrecognised values

## Key Types

### Structs

No public structs. The module contains only free functions.

### Enums

No public enums.

## Lua API

The Lua API is registered in `src/lua_api/log_api.rs` under `luna.log.*`. There are no UserData objects. All functions are simple closures with no shared state.

| Function | Signature | Description |
|---|---|---|
| `luna.log.debug(message)` | `(string)` | Emit a `debug`-severity log message prefixed with `[Lua]`. |
| `luna.log.info(message)` | `(string)` | Emit an `info`-severity log message. |
| `luna.log.warn(message)` | `(string)` | Emit a `warn`-severity log message. |
| `luna.log.error(message)` | `(string)` | Emit an `error`-severity log message. |
| `luna.log.print(level, message)` | `(string, string)` | Emit at the named level. Accepts `"debug"`, `"info"`, `"warn"` / `"warning"`, `"error"`, `"trace"`. Unknown values fall back to `info`. |
| `luna.log.setLevel(level)` | `(string)` | Set the minimum runtime log level. Accepted values: `"off"`, `"error"`, `"warn"`, `"info"`, `"debug"`, `"trace"`. |
| `luna.log.getLevel()` | `→ string` | Return the current minimum log level name. |

## Lua Examples

```lua
-- Basic level-specific logging
luna.log.info("Game initialised")
luna.log.debug("Player position: " .. tostring(player.x) .. ", " .. tostring(player.y))
luna.log.warn("Texture not found, using fallback")
luna.log.error("Save file corrupted — starting fresh")

-- Dynamic level selection
local function log_event(severity, msg)
    luna.log.print(severity, msg)
end
log_event("debug", "tick processed")

-- Runtime level control (useful for in-game debug menus)
luna.log.setLevel("debug")     -- enable verbose output
-- ... do detailed diagnostics ...
luna.log.setLevel("warn")      -- quiet back down

-- Query active level
print("Active log level:", luna.log.getLevel())
```

## Item Summary

| Kind      | Count |
|-----------|-------|
| `struct`  | 0     |
| `enum`    | 0     |
| `fn`      | 7     |
| **Total** | **7** |

## References

| Module          | Relationship | Notes                                                                    |
|-----------------|--------------|--------------------------------------------------------------------------|
| `engine`        | Imports from | `set_level` and `get_level` delegate to `engine::log_messages`           |
| `lua_api`       | Imported by  | `log_api.rs` registers the `luna.log.*` surface                          |
| `debugbridge`   | Related      | `debugbridge.capturePrint` captures Lua print output; `luna.log` emits via the Rust `log` crate — two separate channels |

## Notes

- `luna.log.setLevel` delegates to `log_messages::set_log_level`, which uses a `OnceLock` or equivalent mechanism. The actual filtering behavior at runtime is controlled by the `log` crate's `max_level()` and the initialised logger's filter — calling `setLevel` at runtime may not override a hard `max_level` if the logger was compiled with a level ceiling (LuaJIT builds use `RUST_LOG`).
- All Lua log messages are prefixed with `[Lua]` by the binding, so they are distinguishable in log output from engine-originated messages.
- `luna.log.print` with an unknown `level` string falls back to `info` — it does not return a Lua error. This is intentional to avoid crashing games that use dynamic level strings.
- There are no Rust unit tests for this module because all behaviour is a pass-through to `engine::log_messages`; the Lua test in `tests/lua/unit/test_log.lua` validates the Lua API surface.
