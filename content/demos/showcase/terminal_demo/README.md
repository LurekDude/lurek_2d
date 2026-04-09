# Terminal Demo

A demonstration of the `luna.terminal` widget toolkit. The demo renders a Character Creator interface entirely inside an 80 × 25 character-cell terminal grid, using borders, labels, text boxes, a list selector, and a button — all composited through the widget layering system.

## What It Demonstrates

- `luna.terminal.newTerminal(cols, rows)` — creating an 80 × 25 terminal canvas
- `luna.terminal.newBorder(t, x, y, w, h, style, title)` — double-line border with an embedded title string
- `luna.terminal.newLabel(t, x, y, text)` — static text label positioned in the terminal cell grid
- `luna.terminal.newTextbox(t, x, y, w)` — editable single-line text input with cursor
- `luna.terminal.newList(t, x, y, w, h, items)` — scrollable item list with selection highlight
- `luna.terminal.newButton(t, x, y, label, callback)` — clickable button that fires a Lua callback
- Focus management: Tab / click cycle focus between widgets; the active widget receives keyboard input
- Direct cell manipulation: `luna.terminal.setCell(t, x, y, char, fg, bg)` for custom rendering outside widgets

## How to Run

```powershell
cargo run -- demos/terminal_demo
```

## Controls

| Key / Input | Action |
|-------------|--------|
| Click widget | Give focus to that widget |
| `Tab` | Cycle focus to next widget |
| Type in textbox | Edit character name |
| Arrow Up / Down in list | Change class selection |
| Click **Create** button | Print character summary |
| `Escape` | Quit |

## Notes

- The terminal renders inside a scaled viewport; each character cell is drawn as a coloured rectangle with a glyph.
- The double-line border style is specified by passing `"double"` to `newBorder`.
- Callbacks registered on the button receive the terminal table as their first argument.
