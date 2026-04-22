# `<module>` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier N — Description |
| **Status** | Implemented — Full / Partial / Stub |
| **Lua API** | `lurek.<module>` (or `—` if none) |
| **Source** | `src/<module>/` |
| **Rust Tests** | `tests/rust/unit/<module>_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_<module>.lua` (or `—` if none) |
| **Architecture** | `docs/reports/<module>-design.md` (if exists, else `—`) |

## Purpose

2–5 sentences. What the module does and its scope boundary. Should let an
agent decide whether to enter this module or a different one.

## Source Files

| File | Purpose |
|------|---------|
| `file.rs` | One-line description |

## Full Specification

→ [`docs/specs/<module>.md`](../../docs/specs/<module>.md)

_Update both this file and `docs/specs/<module>.md` whenever source files,
public types, or Lua bindings change._
