---
name: logging
description: "Load this skill when adding, tuning, or analysing log output in Lurek2D: setting up the log crate facade, choosing the right log level, controlling output with RUST_LOG, writing structured log messages, logging from Lua scripts, or using log output to debug engine and game behaviour. Use for: engine log instrumentation, RUST_LOG syntax, per-crate/per-module filtering, log-to-file patterns. Skip it for general debugging strategy (use dev-debugging skill) or analytics from collected log files (use analytics skill)."
---

# Logging � Lurek2D

## Load When

- Deciding which log level to use for a new message
- Configuring `RUST_LOG` to filter log output to the relevant module
- Adding structured diagnostic output to a Rust engine module
- Writing Lua-side logging helpers for game scripts
- Capturing engine log output to a file for later analysis
- Diagnosing why expected log output is not appearing

## Owns

- Lurek2D log crate facade: `log::error!`, `warn!`, `info!`, `debug!`, `trace!`
- `RUST_LOG` environment variable syntax and per-module filtering
- Never-use-println rule and its rationale
- Lua-side logging patterns (print, file append, custom logger)
- Log-to-file patterns in Rust and Lua
- Log message content conventions (module prefix, context values)

---

## Rust Log Facade

Lurek2D uses the `log` crate (`log = "0.4"`) as the logging facade. The concrete backend is `env_logger`, initialised at startup in `main.rs`.

**All engine code must use `log::*` macros. Never `println!`.**

```rust
use log::{error, warn, info, debug, trace};

// Error: unrecoverable � frame will abort or session will fail
log::error!("failed to load texture '{}': {}", path, e);

// Warn: recoverable � engine continues with degraded behaviour
log::warn!("audio device not found, running headless");

// Info: lifecycle events � startup, shutdown, resource load
log::info!("Lua VM created with {} API modules", count);

// Debug: per-call detail � disabled in release by default
log::debug!("draw command queue flushed: {} commands", n);

// Trace: per-frame or per-iteration � very hot, use sparingly
log::trace!("vertex buffer updated: {} bytes", size);
```

---

## Log Level Policy

| Level | When to use | Volume | Appears in release? |
|-------|------------|--------|---------------------|
| `error!` | Cannot continue � frame/session will abort | Once per failure | Yes |
| `warn!` | Continuing but something is wrong | Rare | Yes |
| `info!` | Engine lifecycle: init, load, shutdown | < 20/session | Yes (if `RUST_LOG` includes info) |
| `debug!` | Per-call detail: draw flush, resource alloc | Frequent | Only if `RUST_LOG=debug` |
| `trace!` | Per-frame hot path detail | Very frequent | Only if `RUST_LOG=trace` |

**Defaults**: `env_logger` defaults to `warn` level unless `RUST_LOG` is set. Release builds ship with the logger initialised but silent unless the user sets `RUST_LOG`.

---

## RUST_LOG Syntax

```powershell
# Show all output from lurek2d at info level and above
$env:RUST_LOG = "lurek2d=info"
cargo run -- content/demos/hello_world

# Show debug output from one module only
$env:RUST_LOG = "luna2d::graphics=debug"
cargo run -- content/demos/sprites

# Show debug from lurek2d, but silence wgpu noise
$env:RUST_LOG = "lurek2d=debug,wgpu_core=warn,wgpu_hal=warn"

# Show everything (very verbose � wgpu produces thousands of lines)
$env:RUST_LOG = "debug"

# Multiple targets at different levels
$env:RUST_LOG = "luna2d::physics=trace,luna2d::audio=debug,wgpu=error"

# Show nothing (silent mode)
$env:RUST_LOG = "error"
```

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

## Message Content Conventions

```rust
// GOOD: includes module context, key values, and what failed
log::warn!("physics: body {:?} placed outside world bounds ({:.1}, {:.1})", key, x, y);

// GOOD: info lifecycle event with details
log::info!("audio: loaded '{}' ({:.1} KB, {:?})", path, kb, source_type);

// BAD: no context � useless in a log file
log::debug!("done");

// BAD: panic-style � use error! not panic for recoverable errors
log::error!("unexpected state");
panic!("unexpected state");   // don't duplicate with a panic
```

**Format rule**: `"<module>: <what happened> <values>"` � include the module name prefix when the log target is `lurek2d` (all output mixed together): makes grep filtering easy.

---

## Lua-Side Logging

Lua scripts use `print()` for standard output (captured to stdout). For structured game-side logging:

### Simple print-based logging

```lua
-- Log levels via prefix convention
local function logInfo(msg)  print("[INFO]  " .. msg) end
local function logWarn(msg)  print("[WARN]  " .. msg) end
local function logError(msg) print("[ERROR] " .. msg) end

logInfo("Game loaded � level 1")
logWarn("save file missing, starting fresh")
```

### Log to file (persistent across sessions)

```lua
-- Append log lines to a file in the save directory
local LOG_FILE = "game.log"

local function logToFile(level, msg)
    local line = string.format("[%s] %.3f  %s\n", level, lurek.time.getTime(), msg)
    lurek.fs.append(LOG_FILE, line)
end

logToFile("INFO",  "Level 1 started")
logToFile("WARN",  "missing texture: player_jump.png")
logToFile("ERROR", "physics body nil at spawn point")
```

### Conditional verbose mode

```lua
-- conf.lua: expose a debug flag
function lurek.conf(t)
    t.identity.name = "mygame"
end

-- main.lua: enable verbose logging via a flag file
local VERBOSE = lurek.fs.exists("debug.flag")

local function dbg(msg)
    if VERBOSE then print("[DBG] " .. msg) end
end
```

---

## Log to File (Rust Side)

`env_logger` writes to stderr by default. To capture to a file during development:

```powershell
# Redirect both stdout and stderr to a file
$env:RUST_LOG = "lurek2d=debug"
cargo run -- content/demos/hello_world 2>&1 | Tee-Object logs/run.log
```

For production log files, consider adding a `WriteLogger` via the `fern` or `simplelog` crate alongside `env_logger` � but do not add new logging crates to Lurek2D's `Cargo.toml` without a design decision.

---

## During Tests

```powershell
# See log output during a test run
$env:RUST_LOG = "lurek2d=debug"
cargo test --test math_tests -- --nocapture

# See log output from a Lua test
$env:RUST_LOG = "lurek2d=debug"
cargo test lua_test_math -- --nocapture
```

Note: `env_logger` writes to stderr. `--nocapture` shows both stdout and stderr in `cargo test`.

---

## Anti-Patterns

- **`println!` in engine code** � always use `log::info!` / `log::debug!`. `println!` bypasses the log facade and can't be filtered or silenced.
- **`log::error!` + `panic!` on the same condition** � pick one. Use `error!` for recoverable faults; use `panic!` (with `// SAFETY:` comment) only for truly unreachable invariant violations.
- **Per-frame `info!` or `warn!`** � these generate thousands of lines per second. Hot-path messages must be `debug!` or `trace!`.
- **No context in error messages** � always include the resource name, key, or value that caused the error.
- **Silencing all output in tests** � don't set `RUST_LOG=""` in test fixtures. Let tests use the default filter; the developer controls verbosity via the env var at run time.
