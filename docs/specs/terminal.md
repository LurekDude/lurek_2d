# terminal

## General Info

- Module group: `Feature Systems`
- Source path: `src/terminal/`
- Lua API path(s): `src/lua_api/terminal_api.rs`
- Primary Lua namespace: `lurek.terminal`
- Rust test path(s): tests/rust/unit/terminal_tests.rs, tests/rust/ext/terminal_demo_smoke_tests.rs
- Lua test path(s): tests/lua/unit/test_terminal.lua

## Summary

The `terminal` module provides a character-cell text-mode terminal emulator embedded in the Lurek2D engine. It is designed for roguelikes, text adventures, in-game debug consoles, and retro-style ASCII rendering. All output goes through `RenderCommand::DrawText` to keep GPU access deferred.

`Terminal` owns a fixed-size 2D grid of `TCell` values capped at 512×256 cells. Each `TCell` stores a Unicode character, foreground `Color`, background `Color`, and a `CellStyle` bitmask (Bold, Italic, Underline, Strikethrough, Blink, Inverse). Terminal cell coordinates are 1-based for Lua ergonomics.

Text operations: `print(x, y, text, fg, bg)` places styled text at a specific grid position; `println(s)` appends with automatic line wrap and scroll; `put_char(x, y, ch, fg, bg)` sets a single cell; `fill(x, y, w, h, ch, fg, bg)` floods a rectangular region; `print_box(x, y, w, h, border_style)` draws a box-drawing character border; `clear()` resets all cells.

`BorderStyle` enum: Single, Double, Round (box-drawing curves), Bold (heavy box), ASCII (`+/-|`) for maximum compatibility, or None. `ColorMode` selects 24-bit true color, 256-color palette, or 16-color classic terminal mode.

`Widget` instances provide reusable interactive TUI controls: each has a `WidgetKind` (Label, Button, TextInput, ProgressBar, SelectList, Border) and manages its own cell region. Input event routing delivers key and mouse events to focused widgets.

Three source files extend the terminal's text-mode surface. The existing `ansi.rs` provides `AnsiColor` and `AnsiSpan`; it now also exposes `AnsiSequence` and an `ansiEscape` generator via `lurek.terminal.ansiEscape()` for programmatic ANSI styling. `widget.rs` exposes `TerminalWidget` as a standalone Lua-constructible TUI control via `lurek.terminal.newWidget()`, enabling interactive in-game consoles with buttons, progress bars, and text inputs inside the character-cell grid. `markup.rs` introduces `MarkupToken` and a rich-text markup parser accessible via `lurek.terminal.parseMarkup(text)`, allowing BBCode-style `[color]`, `[bold]`, and `[blink]` tags in terminal output strings.

**Scope boundary**: Feature Systems tier. Depends on `render`, `math`, `runtime`. Lua bridge in `src/lua_api/terminal_api.rs`.

## Files

- `ansi.rs`: ANSI escape code parsing for the terminal module.
- `cell.rs`: Defines the `TCell` character-cell record with foreground and background color data.
- `completion.rs`: Tab-completion engine for the terminal module.
- `mod.rs`: Declares the terminal submodules and re-exports the grid, widget, and border types.
- `render.rs`: Converts terminal contents and terminal widgets into render commands or CPU-side image output.
- `terminal_state.rs`: Implements the main `Terminal` state, including the cell grid, cursor, focus, input routing, and terminal events.
- `widget.rs`: Defines terminal-native widget metadata and the concrete widget kinds used inside a terminal surface.

## Types

- `AnsiColor` (`struct`, `ansi.rs`): RGBA colour in the range `[0, 255]`.
- `AnsiSpan` (`struct`, `ansi.rs`): A contiguous run of characters that share the same style attributes.
- `TCell` (`struct`, `cell.rs`): One terminal cell with a character codepoint and foreground or background colors.
- `CompletionEngine` (`struct`, `completion.rs`): Maintains a list of completion candidates and a per-prefix cycling cursor.
- `TerminalEvent` (`enum`, `terminal_state.rs`): Internal event enum used when terminal widget interactions need to report changes.
- `Terminal` (`struct`, `terminal_state.rs`): The main character-grid surface. It owns cells, cursor state, terminal widgets, and the state needed to route text or pointer input.
- `BorderStyle` (`enum`, `widget.rs`): Selects the line-drawing character set used for borders.
- `WidgetBase` (`struct`, `widget.rs`): Shared widget metadata such as position, size, visibility, enabled state, and tagging.
- `WidgetKind` (`enum`, `widget.rs`): Enumerates the built-in terminal widget variants such as label, button, text box, list, border, and panel.
- `Widget` (`struct`, `widget.rs`): A terminal widget instance combining base geometry and a concrete widget kind.

## Functions

- `strip_ansi_codes` (`ansi.rs`): Removes all ANSI escape sequences from `text` and returns the plain string.
- `parse_ansi_spans` (`ansi.rs`): Tokenises `text` into [`AnsiSpan`] records, each with plain text and colour/bold state.
- `CompletionEngine::new` (`completion.rs`): Creates an empty [`CompletionEngine`].
- `CompletionEngine::add_candidate` (`completion.rs`): Adds a completion candidate string.
- `CompletionEngine::remove_candidate` (`completion.rs`): Removes a candidate, if present.
- `CompletionEngine::clear` (`completion.rs`): Clears all candidates and resets cycle state.
- `CompletionEngine::len` (`completion.rs`): Returns the number of registered candidates.
- `CompletionEngine::is_empty` (`completion.rs`): Returns `true` if no candidates are registered.
- `CompletionEngine::completions_for` (`completion.rs`): Returns all candidates that start with `prefix`, in sorted order.
- `CompletionEngine::next_completion` (`completion.rs`): Returns the next candidate for `prefix`, cycling on repeated calls with the same prefix.
- `CompletionEngine::reset` (`completion.rs`): Resets the cycling cursor without clearing candidates.
- `Terminal::generate_render_commands` (`render.rs`): Generate GPU render commands for this terminal grid.
- `Terminal::draw_to_image` (`render.rs`): Render the terminal grid to a CPU image for headless testing.
- `Terminal::new` (`terminal_state.rs`): Create a new terminal grid with the given dimensions.
- `Terminal::set` (`terminal_state.rs`): Set a cell at 1-based coordinates.
- `Terminal::get` (`terminal_state.rs`): Get a cell at 1-based coordinates.
- `Terminal::clear` (`terminal_state.rs`): Clear all cells to defaults.
- `Terminal::get_dimensions` (`terminal_state.rs`): Get the grid dimensions.
- `Terminal::set_cell_size` (`terminal_state.rs`): Set a per-terminal cell pixel size override.
- `Terminal::reset_cell_size` (`terminal_state.rs`): Clear the cell size override, reverting to font-derived dimensions.
- `Terminal::get_cell_size` (`terminal_state.rs`): Return the active cell size override, or `None` if font-derived sizing is used.
- `Terminal::get_cursor` (`terminal_state.rs`): Get the cursor position as 1-based coordinates.
- `Terminal::set_cursor` (`terminal_state.rs`): Set the cursor position from 1-based coordinates.
- `Terminal::add_widget` (`terminal_state.rs`): Add a widget to the terminal.
- `Terminal::remove_widget` (`terminal_state.rs`): Remove a widget by index.
- `Terminal::clear_widgets` (`terminal_state.rs`): Remove all widgets and clear focus.
- `Terminal::get_widget_count` (`terminal_state.rs`): Get the number of attached widgets.
- `Terminal::get_widget` (`terminal_state.rs`): Get a reference to a widget by index.
- `Terminal::get_widget_mut` (`terminal_state.rs`): Get a mutable reference to a widget by index.
- `Terminal::add_panel_child` (`terminal_state.rs`): Add a child widget to a panel.
- `Terminal::remove_panel_child` (`terminal_state.rs`): Remove a child widget from a panel.
- `Terminal::clear_panel_children` (`terminal_state.rs`): Clear all children from a panel.
- `Terminal::set_focus` (`terminal_state.rs`): Set the focused widget by index.
- `Terminal::get_focused` (`terminal_state.rs`): Get the currently focused widget index.
- `Terminal::keypressed` (`terminal_state.rs`): Route a key press to the focused widget.
- `Terminal::textinput` (`terminal_state.rs`): Route text input to the focused widget.
- `Terminal::mousepressed` (`terminal_state.rs`): Route a mouse press to widgets using 1-based grid coordinates.
- `Terminal::keypressed_with_events` (`terminal_state.rs`): Route a key press to the focused widget and collect emitted events.
- `Terminal::textinput_with_events` (`terminal_state.rs`): Route text input to the focused widget and collect emitted events.
- `Terminal::mousepressed_with_events` (`terminal_state.rs`): Route a mouse press to widgets and collect emitted events.
- `Terminal::render_cells` (`terminal_state.rs`): Render the current grid with all visible widgets composited on top.
- `Terminal::cols` (`terminal_state.rs`): Returns the number of columns.
- `Terminal::rows` (`terminal_state.rs`): Returns the number of rows.
- `Terminal::try_get` (`terminal_state.rs`): Get a cell at 1-based coordinates, returning `None` if out of bounds.
- `Terminal::set_char` (`terminal_state.rs`): Set only the character at a cell, keeping existing colours.
- `Terminal::set_fg` (`terminal_state.rs`): Set only the foreground colour at a cell.
- `Terminal::set_bg` (`terminal_state.rs`): Set only the background colour at a cell.
- `Terminal::print` (`terminal_state.rs`): Write a UTF-8 string left-to-right starting at a 1-based position.
- `Terminal::resize` (`terminal_state.rs`): Resize the terminal grid.
- `Terminal::widget_count` (`terminal_state.rs`): Returns the number of attached widgets.
- `Terminal::find_by_tag` (`terminal_state.rs`): Find the first widget whose `base.tag` equals `tag`.
- `Terminal::build_render_commands` (`terminal_state.rs`): Render the terminal grid (with widget overlays) into a list of [`RenderCommand`] values suitable for pushing to `SharedState`.
- `Terminal::set_default_colors` (`terminal_state.rs`): Sets the foreground and background colours of every cell in the grid to the supplied values.
- `Terminal::print_colored` (`terminal_state.rs`): Prints `text` at the given 1-based `(col, row)` position applying explicit foreground and background colours to each printed cell.
- `Terminal::set_scrollback_cap` (`terminal_state.rs`): Sets the maximum number of lines retained in the scrollback buffer.
- `Terminal::scrollback_cap` (`terminal_state.rs`): Returns the current scrollback capacity.
- `Terminal::push_scrollback` (`terminal_state.rs`): Appends a line to the scrollback buffer.
- `Terminal::get_scrollback` (`terminal_state.rs`): Returns up to `count` lines from the scrollback buffer, counting from the bottom minus `offset`.
- `Terminal::scrollback_offset` (`terminal_state.rs`): Returns the current view offset from the bottom of the scrollback.
- `Terminal::set_scrollback_offset` (`terminal_state.rs`): Sets the scrollback view offset.
- `Terminal::scrollback_len` (`terminal_state.rs`): Returns the total number of lines currently in the scrollback buffer.
- `Terminal::push_cmd_history` (`terminal_state.rs`): Appends a command string to the command history.
- `Terminal::prev_cmd` (`terminal_state.rs`): Navigates one step backward in command history (toward older commands).
- `Terminal::next_cmd` (`terminal_state.rs`): Navigates one step forward in command history (toward newer commands).
- `Terminal::cmd_history_len` (`terminal_state.rs`): Returns the total number of entries in the command history.
- `Terminal::clear_cmd_history` (`terminal_state.rs`): Clears all command history and resets the browse cursor.
- `BorderStyle::from_str_name` (`widget.rs`): Parse a style name string.
- `BorderStyle::as_str` (`widget.rs`): Return the lowercase style name.
- `WidgetBase::new` (`widget.rs`): Create a new widget base with the given position and size.
- `WidgetBase::position_1based` (`widget.rs`): Get the widget position as 1-based coordinates.
- `WidgetBase::set_position_1based` (`widget.rs`): Set the widget position from 1-based coordinates.
- `Widget::new_label` (`widget.rs`): Create a new label widget.
- `Widget::new_button` (`widget.rs`): Create a new button widget.
- `Widget::new_text_box` (`widget.rs`): Create a new text box widget.
- `Widget::new_list` (`widget.rs`): Create a new list widget.
- `Widget::new_border` (`widget.rs`): Create a new border widget.
- `Widget::new_panel` (`widget.rs`): Create a new panel widget.
- `Widget::set_text` (`widget.rs`): Set the text content of a label, button, or text box widget.
- `Widget::get_text` (`widget.rs`): Get the text content of a label, button, or text box widget.
- `Widget::set_color` (`widget.rs`): Set the colour of a label or border widget.
- `Widget::get_color` (`widget.rs`): Get the colour of a label or border widget.
- `Widget::set_max_length` (`widget.rs`): Set the maximum character length of a text box widget.
- `Widget::get_max_length` (`widget.rs`): Get the maximum character length of a text box widget.
- `Widget::add_item` (`widget.rs`): Add an item to a list widget.
- `Widget::remove_item_1based` (`widget.rs`): Remove an item from a list widget by 1-based index.
- `Widget::clear_items` (`widget.rs`): Remove all items from a list widget.
- `Widget::get_item_count` (`widget.rs`): Get the number of items in a list widget.
- `Widget::get_item_1based` (`widget.rs`): Get an item from a list widget by 1-based index.
- `Widget::set_selected_1based` (`widget.rs`): Set the selected item in a list widget by 1-based index.
- `Widget::get_selected_1based` (`widget.rs`): Get the selected item index (1-based) in a list widget.
- `Widget::set_border_style` (`widget.rs`): Set the border style of a border widget.
- `Widget::get_border_style` (`widget.rs`): Get the border style of a border widget.
- `Widget::set_title` (`widget.rs`): Set the title of a border widget.
- `Widget::get_title` (`widget.rs`): Get the title of a border widget.
- `Widget::is_button` (`widget.rs`): Check if this widget is a button.
- `Widget::is_textbox` (`widget.rs`): Check if this widget is a text box.
- `Widget::is_list` (`widget.rs`): Check if this widget is a list.
- `Widget::is_panel` (`widget.rs`): Check if this widget is a panel.

## Lua API Reference

- Binding path(s): `src/lua_api/terminal_api.rs`
- Namespace: `lurek.terminal`

### Module Functions
- `lurek.terminal.newTerminal`: Creates a new terminal grid with the given dimensions.
- `lurek.terminal.newLabel`: Creates a new label widget at 1-based coordinates.
- `lurek.terminal.newButton`: Creates a new button widget at 1-based coordinates.
- `lurek.terminal.newTextBox`: Creates a new single-line text box widget at 1-based coordinates.
- `lurek.terminal.newList`: Creates a new scrollable list widget at 1-based coordinates.
- `lurek.terminal.newBorder`: Creates a new decorative border widget at 1-based coordinates.
- `lurek.terminal.newPanel`: Creates a new container panel widget at 1-based coordinates.
- `lurek.terminal.pushScrollback`: Appends a line to this terminal's scrollback buffer.
- `lurek.terminal.getScrollback`: Returns a table of lines from the scrollback buffer.
- `lurek.terminal.scrollbackLen`: Returns the number of lines currently in this terminal's scrollback buffer.
- `lurek.terminal.setScrollbackCap`: Sets the maximum number of lines retained in the scrollback buffer.
- `lurek.terminal.pushCmdHistory`: Appends a command string to this terminal's history.
- `lurek.terminal.prevCmd`: Steps one entry back in command history (toward older commands).
- `lurek.terminal.nextCmd`: Steps one entry forward in command history (toward newer commands).
- `lurek.terminal.cmdHistoryLen`: Returns the total number of entries in this terminal's command history.
- `lurek.terminal.clearCmdHistory`: Clears all entries from this terminal's command history.
- `lurek.terminal.applyTheme`: Applies a named colour theme to a terminal, recolouring all existing cells.
- `lurek.terminal.printHighlighted`: Prints text at 1-based `(col, row)` with per-keyword colour highlighting.
- `lurek.terminal.stripAnsi`: Strips all ANSI escape codes from `text` and returns the plain string.
- `lurek.terminal.parseAnsi`: Parses `text` into coloured spans.  Returns an array of tables, each with
- `lurek.terminal.printAnsi`: Prints ANSI-escaped `text` onto terminal `t` starting at `(col, row)`.
- `lurek.terminal.addCompletion`: Adds a candidate string to the tab-completion engine.
- `lurek.terminal.removeCompletion`: Removes a candidate string from the tab-completion engine.
- `lurek.terminal.clearCompletions`: Clears all completion candidates.
- `lurek.terminal.getCompletions`: Returns all registered candidates that start with `prefix`, as a sorted array.
- `lurek.terminal.nextCompletion`: Returns the next candidate for `prefix`, cycling on repeated calls.
- `lurek.terminal.resetCompletion`: Resets the cycling cursor without clearing the candidate list.
- `lurek.terminal.getMaxCols`: Returns the maximum number of columns a Terminal can be constructed with.
- `lurek.terminal.getMaxRows`: Returns the maximum number of rows a Terminal can be constructed with.

### `Terminal` Methods
- `Terminal:set`: Sets a cell at 1-based coordinates with character FG and BG colours.
- `Terminal:get`: Returns the cell data at 1-based coordinates.
- `Terminal:clear`: Clears all cells to defaults.
- `Terminal:getDimensions`: Returns the terminal grid dimensions.
- `Terminal:getCellSize`: Returns the current cell size in pixels derived from the active font.
- `Terminal:addWidget`: Attaches a widget to this terminal.
- `Terminal:removeWidget`: Detaches a widget from this terminal.
- `Terminal:clearWidgets`: Detaches all widgets from this terminal.
- `Terminal:getWidgetCount`: Returns the number of attached widgets.
- `Terminal:setFocus`: Sets the focused widget, or clears focus if nil is passed.
- `Terminal:getFocused`: Returns the currently focused widget, or nil.
- `Terminal:keypressed`: Routes a key press to the focused widget and fires callbacks.
- `Terminal:textinput`: Routes text input to the focused widget and fires callbacks.
- `Terminal:render`: Renders the terminal grid and widgets as render commands.
- `Terminal:setFont`: Sets the terminal font by pixel height, snapping to the nearest built-in size.
- `Terminal:setCellSize`: Sets a per-terminal cell pixel size override, bypassing the font-derived size.
- `Terminal:resetCellSize`: Removes the cell size override, restoring font-derived cell dimensions.
- `Terminal:getCellSize`: Returns the active cell size override as `{w, h}`, or `nil` if none is set.
- `Terminal:autoResize`: Resizes the window to exactly fit the terminal grid at the current font size.

### `Widget` Methods
- `Widget:setPosition`: Sets the widget position from 1-based coordinates.
- `Widget:getPosition`: Returns the widget position as 1-based coordinates.
- `Widget:setSize`: Sets the widget size in cells.
- `Widget:getSize`: Returns the widget size in cells.
- `Widget:setVisible`: Sets the widget visibility.
- `Widget:isVisible`: Returns whether the widget is visible.
- `Widget:setEnabled`: Sets whether the widget accepts input.
- `Widget:isEnabled`: Returns whether the widget accepts input.
- `Widget:setTag`: Sets the free-form identification tag.
- `Widget:getTag`: Returns the free-form identification tag.
- `Widget:setText`: Sets the text content of a label, button, or text box widget.
- `Widget:getText`: Returns the text content of a label, button, or text box widget.
- `Widget:getColor`: Returns the colour of a label or border widget.
- `Widget:setOnClick`: Registers a click callback for a button widget.
- `Widget:setMaxLength`: Sets the maximum character length of a text box widget.
- `Widget:getMaxLength`: Returns the maximum character length of a text box widget.
- `Widget:setOnChange`: Registers a text change callback for a text box widget.
- `Widget:addItem`: Adds an item to a list widget.
- `Widget:removeItem`: Removes an item from a list widget by 1-based index.
- `Widget:clearItems`: Removes all items from a list widget.
- `Widget:getItemCount`: Returns the number of items in a list widget.
- `Widget:getItem`: Returns a list item by 1-based index.
- `Widget:setSelected`: Sets the selected item in a list widget by 1-based index.
- `Widget:getSelected`: Returns the selected item index (1-based) in a list widget, or nil.
- `Widget:setOnSelect`: Registers a selection change callback for a list widget.
- `Widget:setStyle`: Sets the border style of a border widget.
- `Widget:getStyle`: Returns the border style name of a border widget.
- `Widget:setTitle`: Sets the title of a border widget.
- `Widget:getTitle`: Returns the title of a border widget.
- `Widget:addChild`: Adds a child widget to a panel widget.
- `Widget:removeChild`: Removes a child widget from a panel widget.
- `Widget:clearChildren`: Removes all children from a panel widget.
- `Widget:getChildCount`: Returns the number of children in a panel widget.
- `Widget:getChild`: Returns a child widget from a panel by 1-based index, or nil.

## References

- `image`: Imports or references `image` from `src/image/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/terminal/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.

### New in 0.14.1

- `Terminal.cell_width_override: Option<f32>` and `cell_height_override: Option<f32>` — per-terminal cell pixel size override (default `None`).
- `Terminal::set_cell_size(w, h)`, `reset_cell_size()`, `get_cell_size() -> Option<(f32,f32)>`.
- Lua: `terminal:setCellSize(w, h)`, `terminal:resetCellSize()`, `terminal:getCellSize()` — returns `{w, h}` table or `nil`.
- `render` respects the override; falls back to font-derived size.
