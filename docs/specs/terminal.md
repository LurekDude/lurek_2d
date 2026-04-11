# `terminal` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | `lurek.terminal` |
| **Source** | `src/terminal/` |
| **Rust Tests** | `tests/rust/unit/terminal_tests.rs`, `tests/rust/ext/terminal_demo_smoke_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_terminal.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The `terminal` module provides a character-cell UI surface for consoles, debug overlays, roguelike interfaces, and text-driven tools. It owns the terminal grid, cursor state, terminal-native widgets, and the logic that composites widgets into cells before draw output is generated.

It exists to support interfaces that work best as text grids rather than pixel-perfect UI layouts. That keeps terminal behavior, line drawing, widget focus, and cell-level edits separate from the general `ui` module and separate from the renderer's lower-level drawing primitives.

It intentionally does not own font rasterization, filesystem-backed shells, command parsing, or operating-system terminals. It is an in-engine text surface and widget set, not a platform console abstraction.

**Scope boundary**: This module currently depends on `image`, `render`, `runtime`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.terminal.* (Lua API — src/lua_api/terminal_api.rs)
    |
    v
src/terminal/mod.rs
    |- cell.rs - cell
    |- render.rs - render
    |- terminal_state.rs - terminal_state
    |- widget.rs - widget
```

---

## Source Files

| File | Purpose |
|------|---------|
| `cell.rs` | Defines the `TCell` character-cell record with foreground and background color data. |
| `mod.rs` | Declares the terminal submodules and re-exports the grid, widget, and border types. |
| `render.rs` | Converts terminal contents and terminal widgets into render commands or CPU-side image output. |
| `terminal_state.rs` | Implements the main `Terminal` state, including the cell grid, cursor, focus, input routing, and terminal events. |
| `widget.rs` | Defines terminal-native widget metadata and the concrete widget kinds used inside a terminal surface. |

---

## Submodules

### `terminal::cell`

Defines the `TCell` character-cell record with foreground and background color data.

- **`TCell`** (struct): A single character cell in the terminal grid.

### `terminal::render`

Converts terminal contents and terminal widgets into render commands or CPU-side image output.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `terminal::terminal_state`

Implements the main `Terminal` state, including the cell grid, cursor, focus, input routing, and terminal events.

- **`TerminalEvent`** (enum): Internal terminal event emitted by input routing.
- **`Terminal`** (struct): A grid-based character-cell terminal emulator with widget support.

### `terminal::widget`

Defines terminal-native widget metadata and the concrete widget kinds used inside a terminal surface.

- **`BorderStyle`** (enum): Line-drawing style for [`WidgetKind::Border`] widgets.
- **`WidgetBase`** (struct): Shared base fields for all terminal widgets.
- **`WidgetKind`** (enum): Concrete widget type discriminant.
- **`Widget`** (struct): A terminal widget combining shared [`WidgetBase`] fields with a concrete [`WidgetKind`] variant.

---

## Key Types

### Public Types

#### `Terminal`

The main character-grid surface.

#### `TCell`

One terminal cell with a character codepoint and foreground or background colors.

#### `Widget`

A terminal widget instance combining base geometry and a concrete widget kind.

#### `WidgetBase`

Shared widget metadata such as position, size, visibility, enabled state, and tagging.

#### `WidgetKind`

Enumerates the built-in terminal widget variants such as label, button, text box, list, border, and panel.

#### `BorderStyle`

Selects the line-drawing character set used for borders.

#### `TerminalEvent`

Internal event enum used when terminal widget interactions need to report changes.

---

## Lua API

Exposed under `lurek.terminal.*` by `src/lua_api/terminal_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.terminal.newTerminal` | Creates a new terminal grid with the given dimensions. |
| `lurek.terminal.newLabel` | Creates a new label widget at 1-based coordinates. |
| `lurek.terminal.newButton` | Creates a new button widget at 1-based coordinates. |
| `lurek.terminal.newTextBox` | Creates a new single-line text box widget at 1-based coordinates. |
| `lurek.terminal.newList` | Creates a new scrollable list widget at 1-based coordinates. |
| `lurek.terminal.newBorder` | Creates a new decorative border widget at 1-based coordinates. |
| `lurek.terminal.newPanel` | Creates a new container panel widget at 1-based coordinates. |

### `Terminal` Methods

| Method | Description |
|--------|-------------|
| `terminal:set(...)` | Sets a cell at 1-based coordinates with character FG and BG colours. |
| `terminal:get(...)` | Returns the cell data at 1-based coordinates. |
| `terminal:clear(...)` | Clears all cells to defaults. |
| `terminal:getDimensions(...)` | Returns the terminal grid dimensions. |
| `terminal:getCellSize(...)` | Returns the current cell size in pixels derived from the active font. |
| `terminal:addWidget(...)` | Attaches a widget to this terminal. |
| `terminal:removeWidget(...)` | Detaches a widget from this terminal. |
| `terminal:clearWidgets(...)` | Detaches all widgets from this terminal. |
| `terminal:getWidgetCount(...)` | Returns the number of attached widgets. |
| `terminal:setFocus(...)` | Sets the focused widget, or clears focus if nil is passed. |
| `terminal:getFocused(...)` | Returns the currently focused widget, or nil. |
| `terminal:keypressed(...)` | Routes a key press to the focused widget and fires callbacks. |
| `terminal:textinput(...)` | Routes text input to the focused widget and fires callbacks. |
| `terminal:render(...)` | Renders the terminal grid and widgets as render commands. |
| `terminal:setFont(...)` | Sets the terminal font by pixel height, snapping to the nearest built-in size. |
| `terminal:autoResize(...)` | Resizes the window to exactly fit the terminal grid at the current font size. |

### `Widget` Methods

| Method | Description |
|--------|-------------|
| `widget:setPosition(...)` | Sets the widget position from 1-based coordinates. |
| `widget:getPosition(...)` | Returns the widget position as 1-based coordinates. |
| `widget:setSize(...)` | Sets the widget size in cells. |
| `widget:getSize(...)` | Returns the widget size in cells. |
| `widget:setVisible(...)` | Sets the widget visibility. |
| `widget:isVisible(...)` | Returns whether the widget is visible. |
| `widget:setEnabled(...)` | Sets whether the widget accepts input. |
| `widget:isEnabled(...)` | Returns whether the widget accepts input. |
| `widget:setTag(...)` | Sets the free-form identification tag. |
| `widget:getTag(...)` | Returns the free-form identification tag. |
| `widget:setText(...)` | Sets the text content of a label, button, or text box widget. |
| `widget:getText(...)` | Returns the text content of a label, button, or text box widget. |
| `widget:getColor(...)` | Returns the colour of a label or border widget. |
| `widget:setOnClick(...)` | Registers a click callback for a button widget. |
| `widget:setMaxLength(...)` | Sets the maximum character length of a text box widget. |
| `widget:getMaxLength(...)` | Returns the maximum character length of a text box widget. |
| `widget:setOnChange(...)` | Registers a text change callback for a text box widget. |
| `widget:addItem(...)` | Adds an item to a list widget. |
| `widget:removeItem(...)` | Removes an item from a list widget by 1-based index. |
| `widget:clearItems(...)` | Removes all items from a list widget. |
| `widget:getItemCount(...)` | Returns the number of items in a list widget. |
| `widget:getItem(...)` | Returns a list item by 1-based index. |
| `widget:setSelected(...)` | Sets the selected item in a list widget by 1-based index. |
| `widget:getSelected(...)` | Returns the selected item index (1-based) in a list widget, or nil. |
| `widget:setOnSelect(...)` | Registers a selection change callback for a list widget. |
| `widget:setStyle(...)` | Sets the border style of a border widget. |
| `widget:getStyle(...)` | Returns the border style name of a border widget. |
| `widget:setTitle(...)` | Sets the title of a border widget. |
| `widget:getTitle(...)` | Returns the title of a border widget. |
| `widget:addChild(...)` | Adds a child widget to a panel widget. |
| `widget:removeChild(...)` | Removes a child widget from a panel widget. |
| `widget:clearChildren(...)` | Removes all children from a panel widget. |
| `widget:getChildCount(...)` | Returns the number of children in a panel widget. |
| `widget:getChild(...)` | Returns a child widget from a panel by 1-based index, or nil. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.terminal.
if lurek.terminal then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 4 |
| `enum` | 3 |
| `fn` (Lua API) | 57 |
| **Total** | **64** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `image` | Imports or references `image` from `src/image/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `render` | Imports or references `render` from `src/render/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Feature Systems to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/terminal/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
