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

## Summary

The `terminal` module provides a grid-based character-cell terminal emulator with an integrated widget toolkit for building in-game developer consoles, debug overlays, roguelike interfaces, and text-mode REPL panels. It is a Tier 2 Engine Extension gated by the `modules.terminal` configuration flag (which requires graphics to be enabled).

At its core, `Terminal` owns a 2D grid of `TCell` records — each cell stores a Unicode codepoint plus foreground and background RGBA colours. Grid dimensions are capped at 512 columns by 256 rows. All public coordinate parameters exposed to callers use 1-based indexing while internal storage is 0-based, following the Lua convention. The terminal supports direct cell manipulation (`set`, `get`, `set_char`, `set_fg`, `set_bg`), cursor positioning, string printing, grid clearing, and dynamic resizing while preserving existing content.

On top of the raw grid, the module provides a compositing widget system. `Widget` combines a `WidgetBase` (shared position, size, visibility, enabled, tag fields) with a `WidgetKind` discriminant that covers six widget types: `Label` (static text), `Button` (clickable, fires `on_click` callbacks), `TextBox` (single-line editable text input with cursor navigation, max-length enforcement, and `on_change` callbacks), `List` (scrollable selectable item list with `on_select` callbacks), `Border` (decorative frame with title and three line-drawing styles — single, double, ASCII), and `Panel` (container that groups child widgets by index). Widgets are attached to terminals via `add_widget()`, composited into the cell grid during rendering via `render_cells()`, and receive routed keyboard, text, and mouse input through the terminal's event system.

The rendering pipeline converts composited cells into `DrawCommand::Print` sequences grouped by colour runs, suitable for pushing directly into `SharedState::draw_commands`. The module does not own any GPU resources — it relies entirely on the graphics module's text rendering through `DrawCommand`. The Lua API wraps terminals and widgets as UserData objects with a binding layer that tracks widget attachment state, manages callback registries, and supports detach/reattach workflows with snapshot preservation.

**Scope boundary**: `terminal` is a Tier 2 module; it may import `math`, `engine`, and Tier 1 modules but must not import other Tier 2 modules. It does not perform font rasterisation (handled by `graphics`), file I/O, or audio playback.

## Architecture

```
luna.terminal.newTerminal(cols, rows)
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│  Terminal (terminal_state.rs)                                │
│  ┌──────────────────┐  ┌─────────────────────────────────┐  │
│  │ grid: Vec<TCell>  │  │ widgets: Vec<Widget>            │  │
│  │ (cols × rows)     │  │  ├── Label   (text, color)      │  │
│  │                   │  │  ├── Button  (text, on_click)   │  │
│  │ cursor_col/row    │  │  ├── TextBox (text, cursor)     │  │
│  └──────────────────┘  │  ├── List    (items, selected)   │  │
│                         │  ├── Border  (style, title)     │  │
│                         │  └── Panel   (children[])       │  │
│                         └─────────────────────────────────┘  │
│                                                              │
│  render_cells() ─► composite widgets onto grid snapshot      │
│  build_draw_commands(ox, oy, cell_w, cell_h)                 │
│       │                                                      │
│       ▼                                                      │
│  Vec<DrawCommand::Print + SetColor>                          │
│       │  (colour runs per row)                               │
└───────┼──────────────────────────────────────────────────────┘
        │
        ▼
  SharedState.draw_commands ─► GpuRenderer
```

### Input Flow

```
luna.keypressed(key) ─► Terminal:keypressed(key)
                            │
                            ▼
                   focused widget routing
                   ├── TextBox: backspace/delete/left/right/home/end
                   ├── List: up/down selection
                   ├── Button: return/space → ButtonClicked event
                   └── TerminalEvent → callback dispatch

luna.textinput(text) ─► Terminal:textinput(text)
                            └── TextBox: insert at cursor

luna.mousepressed(x, y) ─► Terminal:mousepressed(px, py)
                            └── pixel → grid coord conversion
                                └── hit test widgets (reverse order)
```

## Source Files

| File                 | Purpose                                              |
|----------------------|------------------------------------------------------|
| `cell.rs`            | `TCell` struct and default colour/character constants |
| `terminal_state.rs`  | `Terminal` grid state, input routing, widget compositing, draw command generation |
| `widget.rs`          | `WidgetBase`, `Widget`, `WidgetKind` enum, `BorderStyle` enum, widget constructors and mutation methods |

## Submodules

### `terminal::cell`

Cell data types for the terminal grid.

- **`TCell`** (struct): A single character cell storing a Unicode codepoint and two RGBA float colours (foreground and background).

### `terminal::terminal_state`

Terminal grid state, input handling, and rendering.

- **`Terminal`** (struct): Grid-based character-cell terminal emulator with a 2D `TCell` grid, cursor, widget list, and focus management.
- **`TerminalEvent`** (enum, `pub(crate)`): Internal event discriminant — `ButtonClicked`, `TextChanged`, `SelectionChanged` — emitted by input routing and consumed by the Lua binding layer's callback dispatch.

### `terminal::widget`

Widget types for the terminal UI system.

- **`WidgetBase`** (struct): Shared base fields for all widgets — position, size, visibility, enabled state, and free-form tag.
- **`Widget`** (struct): Combines a `WidgetBase` with a `WidgetKind` variant; provides constructors and kind-specific mutation methods.
- **`BorderStyle`** (enum): Line-drawing style for border widgets — `Single` (Unicode box-drawing), `Double`, or `Ascii` (`+`, `-`, `|`).
- **`WidgetKind`** (enum): Concrete widget type discriminant with six variants: `Label`, `Button`, `TextBox`, `List`, `Border`, `Panel`.

## Key Types

### Structs

#### `terminal::cell::TCell`

A single character cell in the terminal grid. Each cell stores a Unicode codepoint (`ch: u32`, default U+0020 space) and two RGBA float colours — `fg` (foreground, default white) and `bg` (background, default transparent black). Implements `Default`, `Clone`, `Copy`, `PartialEq`, and `Debug`.

#### `terminal::terminal_state::Terminal`

Grid-based character-cell terminal emulator with widget support. Maintains a 2D grid of `TCell` records (`cols × rows`, capped at 512 × 256), a cursor position, a flat `Vec<Widget>` list, and an optional focused widget index. Key operations:

- **Grid**: `new`, `set`, `get`, `try_get`, `clear`, `resize`, `print`, `set_char`, `set_fg`, `set_bg`, `get_dimensions`, `get_cursor`, `set_cursor`, `cols`, `rows`.
- **Widgets**: `add_widget`, `remove_widget`, `clear_widgets`, `get_widget`, `get_widget_mut`, `get_widget_count`, `widget_count`, `find_by_tag`, `set_focus`, `get_focused`.
- **Input**: `keypressed`, `textinput`, `mousepressed` (plus `pub(crate)` `*_with_events` variants that return `TerminalEvent` vectors).
- **Rendering**: `build_draw_commands(ox, oy, cell_w, cell_h)` composites widgets onto the grid and emits `DrawCommand::Print` + `DrawCommand::SetColor` sequences.

Implements `Default` (80 × 40 grid).

#### `terminal::widget::WidgetBase`

Shared base fields for all terminal widgets: `x` and `y` (0-based internal position), `width` and `height` (cells), `visible` (default `true`), `enabled` (default `true`), and `tag` (empty string). Provides `new()`, `position_1based()`, and `set_position_1based()`.

#### `terminal::widget::Widget`

Combines a `WidgetBase` with a `WidgetKind` variant. Provides six constructors (`new_label`, `new_button`, `new_text_box`, `new_list`, `new_border`, `new_panel`) that accept 1-based coordinates. Kind-specific mutation methods include:

- **Label/Button/TextBox**: `set_text`, `get_text`.
- **Label/Border**: `set_color`, `get_color`.
- **TextBox**: `set_max_length`, `get_max_length`.
- **List**: `add_item`, `remove_item_1based`, `clear_items`, `get_item_count`, `get_item_1based`, `set_selected_1based`, `get_selected_1based`.
- **Border**: `set_border_style`, `get_border_style`, `set_title`, `get_title`.
- **Type checks**: `is_button`, `is_textbox`, `is_list`, `is_panel`.

### Enums

#### `terminal::widget::BorderStyle`

Line-drawing style for `Border` widgets. Three variants:

- `Single` (default) — Unicode single-line box-drawing characters (`┌`, `─`, `│`, etc.).
- `Double` — Unicode double-line box-drawing characters (`╔`, `═`, `║`, etc.).
- `Ascii` — Plain ASCII characters (`+`, `-`, `|`).

Methods: `from_str_name(&str) -> Option<Self>`, `as_str() -> &'static str`.

#### `terminal::widget::WidgetKind`

Concrete widget type discriminant with six variants:

- `Label { text, color }` — Static or dynamic text label with RGBA colour.
- `Button { text }` — Clickable button; activates on `return` or `space` key, or mouse click.
- `TextBox { text, max_length, cursor_pos }` — Single-line editable text input with cursor navigation (backspace, delete, left, right, home, end).
- `List { items, selected, scroll_offset }` — Scrollable list of selectable strings; navigated with up/down keys or mouse click.
- `Border { style, title, color }` — Decorative border frame with optional title rendered in the top border.
- `Panel { children }` — Container grouping child widgets by their indices in the parent terminal's widget list.

## Lua API

Exposed under `luna.terminal.*` by `src/lua_api/terminal_api.rs`. The API provides two UserData types — `Terminal` and `Widget` — with method-based interfaces. Widgets can be created independently and then attached to terminals, or detached and reattached later while preserving their state via snapshot binding.

### Factory Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `luna.terminal.newTerminal` | `(cols?, rows?) → Terminal` | Create a terminal grid (default 80×40) |
| `luna.terminal.newLabel` | `(col, row, text?) → Widget` | Create a label widget |
| `luna.terminal.newButton` | `(col, row, width, height?, text?) → Widget` | Create a button widget |
| `luna.terminal.newTextBox` | `(col, row, width) → Widget` | Create a text box widget |
| `luna.terminal.newList` | `(col, row, width, height) → Widget` | Create a list widget |
| `luna.terminal.newBorder` | `(col, row, width, height) → Widget` | Create a border widget |
| `luna.terminal.newPanel` | `(col, row, width?, height?) → Widget` | Create a panel widget |

### Terminal Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `Terminal:set` | `(col, row, ch, fr, fg, fb, fa, br, bg, bb, ba)` | Set cell at 1-based coords with character and colours |
| `Terminal:get` | `(col, row) → ch, fr, fg, fb, fa, br, bg, bb, ba` | Get cell data at 1-based coords |
| `Terminal:clear` | `()` | Clear all cells to defaults |
| `Terminal:getDimensions` | `() → cols, rows` | Get grid dimensions |
| `Terminal:getCellSize` | `() → width, height` | Get default cell size in pixels (8×14) |
| `Terminal:addWidget` | `(widget)` | Attach a widget to this terminal |
| `Terminal:removeWidget` | `(widget)` | Detach a widget from this terminal |
| `Terminal:clearWidgets` | `()` | Detach all widgets |
| `Terminal:getWidgetCount` | `() → integer` | Count attached widgets |
| `Terminal:setFocus` | `(widget?)` | Focus a widget or clear focus |
| `Terminal:getFocused` | `() → Widget?` | Get focused widget or nil |
| `Terminal:keypressed` | `(key) → boolean` | Route key press to focused widget |
| `Terminal:textinput` | `(text) → boolean` | Route text input to focused widget |
| `Terminal:mousepressed` | `(px, py, button?)` | Route mouse press via pixel coords |
| `Terminal:draw` | `(x?, y?)` | Render grid and widgets as draw commands |

### Widget Methods (all types)

| Method | Signature | Description |
|--------|-----------|-------------|
| `Widget:setPosition` | `(col, row)` | Set position (1-based) |
| `Widget:getPosition` | `() → col, row` | Get position (1-based) |
| `Widget:setSize` | `(width, height)` | Set size in cells |
| `Widget:getSize` | `() → width, height` | Get size in cells |
| `Widget:setVisible` | `(visible)` | Set visibility |
| `Widget:isVisible` | `() → boolean` | Check visibility |
| `Widget:setEnabled` | `(enabled)` | Set input acceptance |
| `Widget:isEnabled` | `() → boolean` | Check input acceptance |
| `Widget:setTag` | `(tag)` | Set identification tag |
| `Widget:getTag` | `() → string` | Get identification tag |

### Widget Methods (kind-specific)

| Method | Applies To | Signature | Description |
|--------|------------|-----------|-------------|
| `Widget:setText` | Label, Button, TextBox | `(text)` | Set text content |
| `Widget:getText` | Label, Button, TextBox | `() → string` | Get text content |
| `Widget:setColor` | Label, Border | `(r, g, b, a?)` | Set colour |
| `Widget:getColor` | Label, Border | `() → r, g, b, a` | Get colour |
| `Widget:setOnClick` | Button | `(callback?)` | Register click callback |
| `Widget:setMaxLength` | TextBox | `(max)` | Set max character length |
| `Widget:getMaxLength` | TextBox | `() → integer` | Get max character length |
| `Widget:setOnChange` | TextBox | `(callback?)` | Register text change callback |
| `Widget:addItem` | List | `(item)` | Add a list item |
| `Widget:removeItem` | List | `(index)` | Remove item by 1-based index |
| `Widget:clearItems` | List | `()` | Remove all items |
| `Widget:getItemCount` | List | `() → integer` | Count items |
| `Widget:getItem` | List | `(index) → string` | Get item by 1-based index |
| `Widget:setSelected` | List | `(index?)` | Set selected item (1-based) |
| `Widget:getSelected` | List | `() → integer?` | Get selected item (1-based) |
| `Widget:setOnSelect` | List | `(callback?)` | Register selection callback |
| `Widget:setStyle` | Border | `(style)` | Set border style name |
| `Widget:getStyle` | Border | `() → string` | Get border style name |
| `Widget:setTitle` | Border | `(title)` | Set border title |
| `Widget:getTitle` | Border | `() → string` | Get border title |
| `Widget:addChild` | Panel | `(child)` | Add child widget |
| `Widget:removeChild` | Panel | `(child)` | Remove child widget |
| `Widget:clearChildren` | Panel | `()` | Remove all children |
| `Widget:getChildCount` | Panel | `() → integer` | Count children |
| `Widget:getChild` | Panel | `(index) → Widget?` | Get child by 1-based index |

## Lua Examples

```lua
-- Debug console with text input and command list

local term, input, output, border

function luna.load()
    -- Create a 60×20 terminal grid
    term = luna.terminal.newTerminal(60, 20)

    -- Decorative border around the entire grid
    border = luna.terminal.newBorder(1, 1, 60, 20)
    border:setTitle("Debug Console")
    border:setStyle("double")
    term:addWidget(border)

    -- Scrollable output list
    output = luna.terminal.newList(2, 2, 56, 16)
    output:addItem("Welcome to Luna2D debug console.")
    output:addItem("Type a command and press Enter.")
    term:addWidget(output)

    -- Text input box at the bottom
    input = luna.terminal.newTextBox(2, 19, 56)
    input:setMaxLength(80)
    input:setOnChange(function()
        -- Fires on every keystroke
    end)
    term:addWidget(input)
    term:setFocus(input)
end

function luna.keypressed(key)
    if key == "return" then
        local cmd = input:getText()
        if #cmd > 0 then
            output:addItem("> " .. cmd)
            input:setText("")
        end
    else
        term:keypressed(key)
    end
end

function luna.textinput(text)
    term:textinput(text)
end

function luna.draw()
    term:draw(20, 20)
end
```

```lua
-- Menu with buttons and a selection callback

local term, btn_start, btn_quit

function luna.load()
    term = luna.terminal.newTerminal(30, 10)

    local title = luna.terminal.newLabel(8, 2, "== Main Menu ==")
    term:addWidget(title)

    btn_start = luna.terminal.newButton(8, 5, 14, 1, "Start Game")
    btn_start:setOnClick(function()
        print("Starting game!")
    end)
    term:addWidget(btn_start)
    term:setFocus(btn_start)

    btn_quit = luna.terminal.newButton(8, 7, 14, 1, "Quit")
    btn_quit:setOnClick(function()
        luna.event.quit()
    end)
    term:addWidget(btn_quit)
end

function luna.keypressed(key)
    term:keypressed(key)
end

function luna.draw()
    term:draw(100, 80)
end
```

## Item Summary

| Kind     | Count |
|----------|-------|
| `struct` | 4     |
| `enum`   | 2     |
| `fn`     | 61    |
| **Total** | **67** |

## References

| Module     | Relationship | Notes                                                        |
|------------|-------------|--------------------------------------------------------------|
| `math`     | Imports from | Uses `Vec2` and colour constants                            |
| `engine`   | Imports from | Uses `SharedState` for draw command output                   |
| `graphics` | Imports from | Uses `DrawCommand` (`Print`, `SetColor`) from `renderer.rs`  |
| `lua_api`  | Imported by  | `terminal_api.rs` binds `Terminal` and `Widget` as UserData  |

**Similar modules and differentiation:**

- **`gui`** (Tier 2): Retained-mode widget UI with pixel-level layout; `terminal` uses character-cell grid addressing and is oriented towards text-mode interfaces (roguelikes, consoles, REPL). They share no types.
- **`graphics`**: Owns GPU resources, font rasterisation, and the render pipeline. `terminal` produces `DrawCommand` values but never touches GPU textures or surfaces directly.

## Notes

- **Config gate**: The terminal module is gated by `modules.terminal = true` in `conf.lua` and requires `modules.graphics = true` (since it emits `DrawCommand` values).
- **Grid limits**: Maximum grid size is 512 columns × 256 rows (constants `MAX_COLS`, `MAX_ROWS` in `terminal_state.rs`). Requests beyond these are clamped silently.
- **Coordinate convention**: All Lua-facing and public Rust APIs use 1-based coordinates. Internal storage is 0-based. The Lua binding converts pixel coordinates to grid positions using fixed cell dimensions (8 × 14 pixels) for `mousepressed`.
- **Widget attachment model**: Widgets can exist in a detached state (created but not added to a terminal) or an attached state. The Lua binding layer tracks attachment via `WidgetAttachment` and preserves widget state through snapshot copies when widgets are detached. A widget cannot be attached to two terminals simultaneously.
- **Callback dispatch**: Button clicks, text changes, and list selection changes produce `TerminalEvent` values internally. The Lua binding layer dispatches these through stored `LuaRegistryKey` callback functions. Callbacks fire synchronously during `keypressed`, `textinput`, or `mousepressed` calls.
- **Rendering output**: `build_draw_commands()` groups cells into colour runs per row, emitting one `DrawCommand::SetColor` + `DrawCommand::Print` pair per run. The final command resets colour to white. The cell size (8 × 14 pixels) is a constant in `terminal_api.rs`, not configurable per-terminal.
- **Panel children by index**: `Panel` children are stored as indices into the parent terminal's widget list. When widgets are removed, all panels in the terminal have their child indices adjusted via `adjust_panel_children_after_removal()`.
- **No GPU ownership**: The module creates zero GPU resources. It depends on whichever font is currently active in `SharedState` for text rendering resolution.
- **Unicode support**: Cells store full `u32` codepoints. Box-drawing characters (used by `BorderStyle::Single` and `Double`) are UTF-8 encoded in the source file.
- **Breaking change surface**: Renaming or removing any `luna.terminal.*` factory function or `Terminal:*` / `Widget:*` method will break Lua scripts that use the terminal widget system. The `demos/terminal_demo/` example exercises the full API.
