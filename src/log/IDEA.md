# IDEA.md — `log` module

> No `ideas/features/` file. Assembled from `src/log/` directory listing.
> This is a Foundations-tier module — log facade and sink implementations.
> Lua namespace: via `lurek.devtools` log controls (see `src/devtools/IDEA.md`).

---

## Purpose

Logging infrastructure for the engine. Provides the `log` crate facade registration
and custom sink implementations (`sinks.rs`).

---

## Implemented

| File       | Contents                                                      |
| ---------- | ------------------------------------------------------------- |
| `mod.rs`   | Logger initialization, `init_logger()`, log level from config |
| `sinks.rs` | Custom sinks: file sink, in-game console pipeline             |

---

## Features

### ✅ DONE — RUST_LOG Controlled Log Level Filtering
**Source**: Architecture / copilot-instructions critical rules

`RUST_LOG=lurek2d=debug cargo run` — per-crate and per-module filtering.

---

### ✅ DONE — Console Sink (Engine Debug Overlay)
**Source**: `sinks.rs` — custom sink for in-game console

Log messages routed to both stdout and the in-game console pipeline.

---

### ✅ DONE — Log Levels: error / warn / info / debug
**Source**: Architecture critical rules

- `error!` — unrecoverable, aborts frame
- `warn!` — recoverable, degraded behavior
- `info!` — lifecycle events (startup, script load)
- `debug!` — per-frame detail, disabled in release

---

### ✅ DONE — Lua `lurek.log.*` Namespace
**Source**: General completeness

`lurek.log.debug/info/warn/error(msg, tag?)`, `lurek.log.print(level, msg, tag?)`,
`lurek.log.setLevel(level)` / `lurek.log.getLevel()`, plus configurable sinks
(`addSink`, `removeSink`, `clearSinks`, `listSinks`, `readMemory`, `flushFile`).
All log calls routed through Rust `log` crate macros with a `[Lua]` prefix tag.
Invalid `setLevel` values return a descriptive `LuaError`.

---

### ❌ TODO — Structured Log Fields
**Source**: General observability

All log messages are plain strings. No structured key/value fields for machine-readable
analysis (e.g., `log::info!("frame"; "draw_calls" => 42, "fps" => 60.0)`).

---

### ✅ DONE — Log File Rotation
**Source**: Long-running game session support

`RotatingFileSink` in `src/log/sinks.rs`: configurable `max_bytes` (default 10 MiB)
and `keep_files` (default 3). Rotation renames `.log` → `.log.1` → `.log.2` … and
deletes the oldest backup when count would exceed `keep_files`. Exposed to Lua via
`lurek.log.addSink({ type="rotating", path=..., max_bytes=..., keep_files=... })`.

---

### 🔇 LOW — Color Output Toggle
**Source**: CI/CD compatibility

ANSI color in log output is always on. `NO_COLOR` env var or `conf.toml` toggle
would improve CI log readability.
