# `terminal` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.terminal`                                      |
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

## Key Types

| Type | Description |
|------|-------------|
| `TCell` | Principal type for the `terminal` module. |
| `Terminal` | Principal type for the `terminal` module. |
| `BorderStyle` | Principal type for the `terminal` module. |
| `WidgetBase` | Principal type for the `terminal` module. |
| `WidgetKind` | Principal type for the `terminal` module. |
| `Widget` | Principal type for the `terminal` module. |

## Lua API Summary

| Function | Description |
|----------|-------------|
| `lurek.terminal.newTerminal()` | See `docs/specs/terminal.md`. |
| `lurek.terminal.newLabel()` | See `docs/specs/terminal.md`. |
| `lurek.terminal.newButton()` | See `docs/specs/terminal.md`. |
| `lurek.terminal.newTextBox()` | See `docs/specs/terminal.md`. |
| `lurek.terminal.newList()` | See `docs/specs/terminal.md`. |
| `lurek.terminal.newBorder()` | See `docs/specs/terminal.md`. |
| `lurek.terminal.newPanel()` | See `docs/specs/terminal.md`. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/terminal.md`](../../docs/specs/terminal.md)

_Update both this file **and** `docs/specs/terminal.md` whenever source files, public types, or Lua bindings change._
