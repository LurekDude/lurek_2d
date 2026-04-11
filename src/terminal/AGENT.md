# terminal

## Module Info
- Module name: `terminal`
- Module group: `Feature Systems`
- Spec path: `docs/specs/terminal.md`
- Lua API path(s): `src/lua_api/terminal_api.rs`
- Rust test path(s): `tests/rust/unit/terminal_tests.rs`, `tests/rust/ext/terminal_demo_smoke_tests.rs`
- Lua test path(s): `tests/lua/unit/test_terminal.lua`

## Module Purpose
The `terminal` module provides a character-cell UI surface for consoles, debug overlays, roguelike interfaces, and text-driven tools. It owns the terminal grid, cursor state, terminal-native widgets, and the logic that composites widgets into cells before draw output is generated.

It exists to support interfaces that work best as text grids rather than pixel-perfect UI layouts. That keeps terminal behavior, line drawing, widget focus, and cell-level edits separate from the general `ui` module and separate from the renderer's lower-level drawing primitives.

It intentionally does not own font rasterization, filesystem-backed shells, command parsing, or operating-system terminals. It is an in-engine text surface and widget set, not a platform console abstraction.

## Files
- `mod.rs` - Declares the terminal submodules and re-exports the grid, widget, and border types.
- `cell.rs` - Defines the `TCell` character-cell record with foreground and background color data.
- `render.rs` - Converts terminal contents and terminal widgets into render commands or CPU-side image output.
- `terminal_state.rs` - Implements the main `Terminal` state, including the cell grid, cursor, focus, input routing, and terminal events.
- `widget.rs` - Defines terminal-native widget metadata and the concrete widget kinds used inside a terminal surface.

## Key Types
- `Terminal` - The main character-grid surface. It owns cells, cursor state, terminal widgets, and the state needed to route text or pointer input.
- `TCell` - One terminal cell with a character codepoint and foreground or background colors.
- `Widget` - A terminal widget instance combining base geometry and a concrete widget kind.
- `WidgetBase` - Shared widget metadata such as position, size, visibility, enabled state, and tagging.
- `WidgetKind` - Enumerates the built-in terminal widget variants such as label, button, text box, list, border, and panel.
- `BorderStyle` - Selects the line-drawing character set used for borders.
- `TerminalEvent` - Internal event enum used when terminal widget interactions need to report changes.
