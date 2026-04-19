---
name: logging
description: "Load this skill when adding, tuning, or analysing log output in Lurek2D: setting up the log crate facade, choosing the right log level, controlling output with RUST_LOG, writing structured log messages, logging from Lua scripts, or using log output to debug engine and game behaviour. Use for: engine log instrumentation, RUST_LOG syntax, per-crate/per-module filtering, log-to-file patterns. Skip it for general debugging strategy (use dev-debugging skill) or analytics from collected log files (use analytics skill)."
---
# logging

## Mission

# Logging � Lurek2D

## When To Load

- Deciding which log level to use for a new message
- Configuring `RUST_LOG` to filter log output to the relevant module
- Adding structured diagnostic output to a Rust engine module
- Writing Lua-side logging helpers for game scripts
- Capturing engine log output to a file for later analysis
- Diagnosing why expected log output is not appearing

## When To Skip

- Skip it for general debugging strategy (use dev-debugging skill) or analytics from collected log files (use analytics skill).

## Domain Knowledge

### Owns
- Lurek2D log crate facade: `log::error!`, `warn!`, `info!`, `debug!`, `trace!`
- `RUST_LOG` environment variable syntax and per-module filtering
- Never-use-println rule and its rationale
- Lua-side logging patterns (print, file append, custom logger)
- Log-to-file patterns in Rust and Lua
- Log message content conventions (module prefix, context values)

---

### Rust Log Facade
Lurek2D uses the `log` crate (`log = "0.4"`) as the logging facade. The concrete backend is `env_logger`, initialised at startup in `main.rs`.

**All engine code must use `log::*` macros. Never `println!`.**

> See [examples/rust-log-facade.rs](examples/rust-log-facade.rs) for the example.

---

### Log Level Policy
| Level | When to use | Volume | Appears in release? |
|-------|------------|--------|---------------------|
| `error!` | Cannot continue � frame/session will abort | Once per failure | Yes |
| `warn!` | Continuing but something is wrong | Rare | Yes |
| `info!` | Engine lifecycle: init, load, shutdown | < 20/session | Yes (if `RUST_LOG` includes info) |
| `debug!` | Per-call detail: draw flush, resource alloc | Frequent | Only if `RUST_LOG=debug` |
| `trace!` | Per-frame hot path detail | Very frequent | Only if `RUST_LOG=trace` |

**Defaults**: `env_logger` defaults to `warn` level unless `RUST_LOG` is set. Release builds ship with the logger initialised but silent unless the user sets `RUST_LOG`.

---

### RUST_LOG Syntax
> See [snippets/rustlog-syntax.ps1](snippets/rustlog-syntax.ps1) for the example.

### Module path format

`RUST_LOG` filter strings use the Rust module path. Lurek2D module paths follow the pattern `luna2d::<module>`:

| Module | Filter string |
|--------|--------------|
| All engine code | `lurek2d=debug` |
| Graphics renderer | `luna2d::graphics=debug` |
| Physics | `luna2d::physics=trace` |
| Audio | `luna2d::audio=debug` |
| Lua API layer | `luna2d::lua_api=debug` |
| Filesystem | `luna2d::filesystem=debug` |
| Particle system | `luna2d::particle=debug` |

---

### Message Content Conventions
> See [examples/message-content-conventions.rs](examples/message-content-conventions.rs) for the example.

**Format rule**: `"<module>: <what happened> <values>"` � include the module name prefix when the log target is `lurek2d` (all output mixed together): makes grep filtering easy.

---

### Lua-Side Logging
Lua scripts use `print()` for standard output (captured to stdout). For structured game-side logging:

### Simple print-based logging

> See [examples/simple-print-based-logging.lua](examples/simple-print-based-logging.lua) for the example.

### Log to file (persistent across sessions)


> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [examples/rust-log-facade.rs](examples/rust-log-facade.rs) — Rust Log Facade
- [snippets/rustlog-syntax.ps1](snippets/rustlog-syntax.ps1) — RUST_LOG Syntax
- [examples/message-content-conventions.rs](examples/message-content-conventions.rs) — Message Content Conventions
- [examples/simple-print-based-logging.lua](examples/simple-print-based-logging.lua) — Simple print-based logging
- [examples/log-to-file-persistent-across-sessions.lua](examples/log-to-file-persistent-across-sessions.lua) — Log to file (persistent across sessions)
- [examples/conditional-verbose-mode.lua](examples/conditional-verbose-mode.lua) — Conditional verbose mode
- [snippets/log-to-file-rust-side.ps1](snippets/log-to-file-rust-side.ps1) — Log to File (Rust Side)
- [snippets/during-tests.ps1](snippets/during-tests.ps1) — During Tests
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
