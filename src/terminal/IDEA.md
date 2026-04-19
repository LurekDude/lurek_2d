# IDEA.md — `terminal` module

| Field      | Value           |
| ---------- | --------------- |
| **Module** | `terminal`      |
| **Path**   | `src/terminal/` |
| **Date**   | 2026-04-18      |
| **Tier**   | Feature Systems |

---

## Mission

Provide a grid-based character-cell terminal emulator for roguelikes, text adventures, in-game debug consoles, and retro ASCII rendering. All output deferred through `RenderCommand`.

## Strengths

- Clean grid model: fixed-size `TCell` array with 1-based Lua coordinates, capped at 512×256.
- Full ANSI SGR colour parsing (`strip_ansi_codes`, `parse_ansi_spans`) covering standard + bright 16-colour palette.
- Built-in widget system (Label, Button, TextBox, List, Border, Panel) with focus routing and event dispatch.
- Tab-completion engine with sorted candidate cycling.
- Scrollback buffer and command history for console UIs.

## Gaps

- No cursor blink animation (cosmetic).
- No 256-colour or true-colour (24-bit) ANSI parsing — only 16-colour SGR codes.
- No keyboard shortcut bindings (Ctrl+C, Ctrl+V) at the terminal level.

## Features — Competitor Reference

| Feature                        | Status    | Competitor                                                         |
| ------------------------------ | --------- | ------------------------------------------------------------------ |
| 256-colour / true-colour ANSI  | ❌ Missing | BearLibTerminal — full 24-bit colour support                       |
| Rich-text markup (BBCode tags) | ❌ Missing | Textual (Python TUI) — inline markup, tcod — TCOD_console_print_ex |
| Mouse hover highlighting       | ❌ Missing | BearLibTerminal — TK_MOUSE_MOVE events with cell highlighting      |

## Performance / Quality

- Grid stored as flat `Vec<TCell>` — cache-friendly for row-major iteration.
- `render_cells` creates a temporary clone of the grid per frame for widget compositing — could reuse a scratch buffer.
- `generate_render_commands` pre-allocates `cols*rows*2` capacity — adequate.

## Test Gaps

- `cell.rs` — newly added inline tests (4 tests); exhaustive.
- `widget.rs` — newly added inline tests (8 tests); Panel child operations untested.
- `terminal_state.rs` — has tests; scrollback and command history edge cases could use more coverage.

## TODO(dedup)

- `set_render_cell` / `clear_render_rect` / `write_render_text` in `terminal_state.rs` duplicate cell-write logic; could use a `CellWriter` helper.
- `Widget::set_text` / `get_text` have repeated `match` arms for Label/Button/TextBox.

## TODO(helper)

- `char_count` / `byte_index` / `truncate_chars` string helpers in `terminal_state.rs` are generic utilities — could move to a shared `text_utils` module.
- `text_width` in `widget.rs` duplicates `char_count`.

## TODO(plugin)

- Terminal is a plugin candidate — many games don't need a character-cell subsystem.
- ANSI parser (`ansi.rs`) + completion engine (`completion.rs`) are independently useful and could be split into a utility crate.

## References

- `docs/specs/terminal.md`
- `src/lua_api/terminal_api.rs`
- `tests/rust/unit/terminal_tests.rs`
- `tests/lua/unit/test_terminal.lua`
