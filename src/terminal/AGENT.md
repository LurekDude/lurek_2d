# `terminal` — Agent Reference

| Property | Value |
|----------|-------|
| Tier | Tier 2 — Engine Extension |
| Status | Implemented — Full |
| Lua API | `luna.terminal` |
| Source | `src/terminal/` |
| Lua bindings | `src/lua_api/terminal_api.rs` |
| Rust tests | `tests/rust/unit/terminal_tests.rs` |
| Lua tests | `tests/lua/unit/test_terminal.lua` |
| Design spec | `docs/API/terminal-design.md` |

## Summary

Grid-based character-cell terminal emulator and widget toolkit for text-mode
UIs. Lua uses userdata handles throughout:

- `newTerminal(...)` returns terminal userdata.
- `newLabel/newButton/...` return detached widget userdata handles.
- `term:addWidget(widget)` attaches a handle without invalidating it.
- `term:removeWidget(widget)` and `term:clearWidgets()` detach handles back to
  standalone snapshots.
- `term:setFocus(widget)` and `term:getFocused()` operate on attached handles
  from that terminal.
- `panel:addChild(widget)` follows the same repaired handle model for child
  attachment.
- Widget callbacks are stored by Lua registry key and invoked from routed
  input events as zero-argument Lua calls.

All Lua-facing coordinates are 1-based. The grid is capped at 512 by 256 cells.

## Key Types

| Type | Role |
|------|------|
| `TCell` | Single character cell: codepoint plus fg/bg RGBA colours |
| `Terminal` | 2D grid host with widget attachment, focus, input routing, and draw composition |
| `WidgetBase` | Shared widget fields: position, size, visible, enabled, tag |
| `WidgetKind` | Enum discriminant: Label, Button, TextBox, List, Border, Panel |
| `Widget` | Combines `WidgetBase` and `WidgetKind` |
| `BorderStyle` | Line-drawing style enum: Single, Double, Ascii |

## Lua API Summary

### Module functions

- `newTerminal([cols, rows])` → terminal handle
- `newLabel(col, row [, text])` → detached label handle
- `newButton(col, row, width [, height, text])` → detached button handle
- `newTextBox(col, row, width)` → detached text box handle
- `newList(col, row, width, height)` → detached list handle
- `newBorder(col, row, width, height)` → detached border handle
- `newPanel(col, row [, width, height])` → detached panel handle

### Terminal methods

- `set`, `get`, `clear` — cell read and write
- `getDimensions`, `getCellSize` — grid info
- `addWidget`, `removeWidget`, `clearWidgets`, `getWidgetCount` — attachment management
- `setFocus`, `getFocused` — focus control
- `keypressed`, `textinput`, `mousepressed` — routed input (`keypressed` and `textinput` return a consumed flag; `mousepressed` uses terminal-local pixel coordinates)
- `draw` — render the composited grid and widgets

### Base widget methods

- `setPosition`, `getPosition`
- `setSize`, `getSize`
- `setVisible`, `isVisible`
- `setEnabled`, `isEnabled`
- `setTag`, `getTag`

### Type-specific widget methods

- TLabel: `setText`, `getText`, `setColor`, `getColor`
- TButton: `setText`, `getText`, `setOnClick`
- TTextBox: `setText`, `getText`, `setMaxLength`, `getMaxLength`, `setOnChange`
- TList: `addItem`, `removeItem`, `clearItems`, `getItemCount`, `getItem`, `setSelected`, `getSelected`, `setOnSelect`
- TBorder: `setStyle`, `getStyle`, `setTitle`, `getTitle`, `setColor`, `getColor`
- TPanel: `addChild`, `removeChild`, `clearChildren`, `getChildCount`, `getChild`

## Callback Behavior

- `setOnClick` fires for focused button activation via `return` or `space`, and for button mouse clicks.
- `setOnChange` fires when a text box changes through `setText`, `textinput`, `backspace`, or `delete`.
- `setOnSelect` fires when a list selection changes through `setSelected`, `up` or `down`, or mouse clicks.

See `docs/API/terminal-design.md` for the full API tables and usage example.
