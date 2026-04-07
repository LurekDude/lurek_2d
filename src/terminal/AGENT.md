# `terminal` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.terminal`                                      |
| **Source**      | `src/terminal/`                                      |
| **Rust Tests** | `tests/unit/terminal_tests.rs`                       |
| **Lua Tests**  | `tests/lua/unit/test_terminal.lua`                   |
| **Architecture** | `docs/API/terminal-design.md`                      |

## Purpose

The `terminal` module provides a grid-based character-cell terminal emulator with an integrated widget toolkit for building in-game developer consoles, debug overlays, roguelike interfaces, and text-mode REPL panels. It is a Tier 2 Engine Extension gated by the `modules.terminal` configuration flag (which requires graphics to be enabled).

## Source Files

| File                 | Purpose                                              |
|----------------------|------------------------------------------------------|
| `cell.rs`            | `TCell` struct and default colour/character constants |
| `terminal_state.rs`  | `Terminal` grid state, input routing, widget compositing, draw command generation |
| `widget.rs`          | `WidgetBase`, `Widget`, `WidgetKind` enum, `BorderStyle` enum, widget constructors and mutation methods |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`specs/terminal.md`](../../specs/terminal.md)

_Update both this file **and** `specs/terminal.md` whenever source files, public types, or Lua bindings change._
