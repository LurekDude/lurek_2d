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

### ✅ DONE — Structured Log Fields
**Source**: General observability — Added 2026-04-16

`lurek.log.struct(level, msg, fields_table)` emits a structured log entry.
Memory sinks store the raw `BTreeMap<String, String>` fields in `MemoryEntry.fields`.
File/rotating sinks format as `"msg { k1=v1, k2=v2 }"`.

Convenience shorthands: `lurek.log.debug_fields`, `info_fields`, `warn_fields`, `error_fields`.

`lurek.log.readMemory(id)` rows now include a `fields` table (or `nil` for plain entries).

**Rust API**: `crate::log::log_structured(level, tag, msg, fields)` +
`SinkRegistry::dispatch_structured` + `Sink::write_structured`.
`LogFields = BTreeMap<String, String>` type alias in `src/log/mod.rs`.

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
