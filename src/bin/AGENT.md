# `bin` — Agent Reference

| Property       | Value                                            |
|----------------|--------------------------------------------------|
| **Tier**       | Special — CLI entry point (not a numbered tier)  |
| **Status**     | Implemented — Full                               |
| **Lua API**    | —                                                |
| **Source**      | `src/bin/`                                       |
| **Rust Tests** | —                                                |
| **Lua Tests**  | —                                                |
| **Architecture** | —                                              |

## Purpose

The `bin` module contains the `lunec` binary entry point — a console-less launcher for
Luna2D on Windows. Setting `#![cfg_attr(windows, windows_subsystem = "windows")]` suppresses
the black terminal window that would otherwise appear alongside the game window, providing a
polished experience for distributed games. On Linux and macOS the attribute is ignored and
`lunec` behaves identically to the standard `luna2d` binary.

## Source Files

| File       | Purpose                                                                              |
|------------|--------------------------------------------------------------------------------------|
| `lunec.rs` | Console-less binary entry point; sets `windows_subsystem = "windows"` and calls `luna_run()` |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`specs/bin.md`](../../specs/bin.md)

_Update both this file **and** `specs/bin.md` whenever source files, public types, or Lua bindings change._
