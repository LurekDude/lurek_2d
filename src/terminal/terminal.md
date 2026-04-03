# terminal — Text-Mode Terminal Emulator & Widget System

> **Lua namespace:** `luna.terminal`
> **C++ module:** `src/modules/terminal/`
> **Purpose:** Grid-based terminal emulator with a widget toolkit for building text-mode UIs (roguelikes, retro consoles, debug overlays). Provides a character-cell grid (`Terminal`) with foreground/background colours per cell, font rendering, keyboard/mouse input routing, and a hierarchy of interactive widgets (labels, buttons, text boxes, lists, borders, panels).

## Reimplementation Notes

- `Terminal` is a 2D grid of `TCell` structures. Each cell holds a Unicode codepoint (`uint32_t ch`) plus foreground and background `Colorf` (RGBA floats).
- Grid dimensions are capped: cols [1, 512], rows [1, 256].
- **All Lua-facing coordinates are 1-based.** The C++ layer subtracts 1 internally.
- The terminal uses a Luna2D `graphics::Font` for rendering. `setFont()`/`getFont()` manages the font used for cell rendering.
- `draw(x, y)` renders the full terminal grid at pixel position (x, y) using the graphics module.
- Widgets are a hierarchy: `TWidget` is the abstract base, with concrete subtypes `TLabel`, `TButton`, `TTextBox`, `TList`, `TBorder`, `TPanel`.
- All widget subtypes inherit `TWidget` base methods (position, size, visible, enabled, tag) via variadic `luax_register_type()`.
- `TPanel` is a container widget that can hold child widgets — enables nested layouts.
- Input routing: `keypressed()`, `textinput()`, and `mousepressed()` are called from the game's input callbacks and return boolean for consumed status. The terminal routes input to the focused widget.
- Focus management: `setFocus(widget)` / `getFocused()` controls which widget receives keyboard input.
- Widget callbacks (`setOnClick`, `setOnChange`, `setOnSelect`) store Lua function references.
- `TBorder` has three line-drawing styles: `"single"`, `"double"`, `"ascii"`.

## Dependencies

- `luna.graphics` (Font type for rendering, draw calls)

## Module Functions

| Function | Signature | Returns | Description |
|----------|-----------|---------|-------------|
| `newTerminal` | `newTerminal([cols, rows])` | `Terminal` | Create a terminal grid. Defaults: 80×40. Range: cols [1,512], rows [1,256]. |
| `newLabel` | `newLabel(col, row [, text])` | `TLabel` | Create a text label widget at grid position (1-based). |
| `newButton` | `newButton(col, row, width [, height, text])` | `TButton` | Create a button widget. Width [1,512], height [1,256], defaults to 1. |
| `newTextBox` | `newTextBox(col, row, width)` | `TTextBox` | Create a text input box at grid position. Width [1,512]. |
| `newList` | `newList(col, row, width, height)` | `TList` | Create a selectable list widget. Width [1,512], height [1,256]. |
| `newBorder` | `newBorder(col, row, width, height)` | `TBorder` | Create a decorative border frame. Width [1,512], height [1,256]. |
| `newPanel` | `newPanel(col, row [, width, height])` | `TPanel` | Create a container panel. Width/height default to 1. Width [1,512], height [1,256]. |

## Type: Terminal

The character-cell grid and widget host.

### Cell Operations

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `set` | `set(col, row, char [, fr,fg,fb,fa, br,bg,bb,ba])` | — | Set a cell. `char` is a string (first byte) or codepoint integer. fg RGBA defaults to (1,1,1,1), bg RGBA defaults to (0,0,0,0). All colours are floats [0,1]. |
| `get` | `get(col, row)` | `int, r,g,b,a, r,g,b,a` | Get cell data: codepoint, fg RGBA, bg RGBA (9 return values). |
| `clear` | `clear()` | — | Clear all cells to defaults. |

### Grid Properties

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `getDimensions` | `getDimensions()` | `int, int` | Returns cols, rows. |
| `getCellSize` | `getCellSize()` | `number, number` | Returns cell width and height in pixels (based on font). |

### Font

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setFont` | `setFont(font)` | — | Set the `Font` object used for rendering cells. |
| `getFont` | `getFont()` | `Font\|nil` | Get the current font, or nil if none set. |

### Widget Management

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `addWidget` | `addWidget(widget)` | — | Add a `TWidget` (or subtype) to the terminal's widget list. |
| `removeWidget` | `removeWidget(widget)` | — | Remove a widget from the terminal. |
| `clearWidgets` | `clearWidgets()` | — | Remove all widgets. |
| `getWidgetCount` | `getWidgetCount()` | `int` | Get number of attached widgets. |

### Focus & Input

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setFocus` | `setFocus(widget\|nil)` | — | Set the focused widget (receives keyboard input). Pass nil to clear focus. |
| `getFocused` | `getFocused()` | `TWidget\|nil` | Get the currently focused widget. |
| `keypressed` | `keypressed(key)` | `boolean` | Route a key press to the focused widget. Returns true if consumed. |
| `textinput` | `textinput(text)` | `boolean` | Route text input to the focused widget. Returns true if consumed. |
| `mousepressed` | `mousepressed(px, py, button)` | — | Route a mouse press (pixel coordinates + button index) to widgets. |

### Rendering

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `draw` | `draw([x, y])` | — | Draw the terminal grid and all widgets at pixel position (x, y). Defaults to (0, 0). |

## Type: TWidget (Base)

Abstract base class for all terminal widgets. These methods are inherited by all widget subtypes.

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setPosition` | `setPosition(col, row)` | — | Set widget position in grid coordinates (1-based). |
| `getPosition` | `getPosition()` | `int, int` | Get widget position (1-based col, row). |
| `setSize` | `setSize(width, height)` | — | Set widget size in cells. |
| `getSize` | `getSize()` | `int, int` | Get widget size (width, height). |
| `setVisible` | `setVisible(visible)` | — | Show or hide the widget. |
| `isVisible` | `isVisible()` | `boolean` | Check visibility. |
| `setEnabled` | `setEnabled(enabled)` | — | Enable or disable the widget. |
| `isEnabled` | `isEnabled()` | `boolean` | Check enabled state. |
| `setTag` | `setTag(tag)` | — | Set a string tag for identification. |
| `getTag` | `getTag()` | `string` | Get the tag string. |

## Type: TLabel

Text label widget. Inherits all `TWidget` methods.

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setText` | `setText(text)` | — | Set label text. |
| `getText` | `getText()` | `string` | Get label text. |
| `setColor` | `setColor(r, g, b [, a])` | — | Set text colour (RGBA floats, alpha defaults to 1.0). |
| `getColor` | `getColor()` | `r, g, b, a` | Get text colour. |

## Type: TButton

Clickable button widget. Inherits all `TWidget` methods.

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setText` | `setText(text)` | — | Set button label text. |
| `getText` | `getText()` | `string` | Get button label text. |
| `setOnClick` | `setOnClick(fn)` | — | Set click callback function. Called when button is activated. |

## Type: TTextBox

Single-line text input field. Inherits all `TWidget` methods.

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setText` | `setText(text)` | — | Set text content. |
| `getText` | `getText()` | `string` | Get text content. |
| `setMaxLength` | `setMaxLength(max)` | — | Set maximum character count (must be ≥ 0). |
| `getMaxLength` | `getMaxLength()` | `int` | Get maximum character count. |
| `setOnChange` | `setOnChange(fn)` | — | Set change callback function. Called when text is modified. |

## Type: TList

Selectable list widget with scrolling support. Inherits all `TWidget` methods.

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `addItem` | `addItem(text)` | — | Add an item string to the list. |
| `removeItem` | `removeItem(index)` | — | Remove item at index (1-based). |
| `clearItems` | `clearItems()` | — | Remove all items. |
| `getItemCount` | `getItemCount()` | `int` | Get number of items. |
| `getItem` | `getItem(index)` | `string` | Get item text at index (1-based). |
| `setSelected` | `setSelected(index\|nil)` | — | Set selected item by index (1-based). Pass nil to deselect. |
| `getSelected` | `getSelected()` | `int\|nil` | Get selected item index (1-based), or nil if nothing selected. |
| `setOnSelect` | `setOnSelect(fn)` | — | Set selection callback function. Called when selection changes. |

## Type: TBorder

Decorative border/frame widget with line-drawing characters. Inherits all `TWidget` methods.

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `setStyle` | `setStyle(style)` | — | Set border line style: `"single"`, `"double"`, or `"ascii"`. |
| `getStyle` | `getStyle()` | `string` | Get current border style. |
| `setTitle` | `setTitle(title)` | — | Set title text displayed in the top border. |
| `getTitle` | `getTitle()` | `string` | Get title text. |
| `setColor` | `setColor(r, g, b [, a])` | — | Set border colour (RGBA floats, alpha defaults to 1.0). |
| `getColor` | `getColor()` | `r, g, b, a` | Get border colour. |

### Border Styles

| Style | Description |
|-------|-------------|
| `"single"` | Single-line box drawing characters (default). |
| `"double"` | Double-line box drawing characters. |
| `"ascii"` | ASCII characters (`+`, `-`, `|`). |

## Type: TPanel

Container widget that holds child widgets. Inherits all `TWidget` methods.

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `addChild` | `addChild(widget)` | — | Add a child widget to this panel. |
| `removeChild` | `removeChild(widget)` | — | Remove a child widget. |
| `clearChildren` | `clearChildren()` | — | Remove all child widgets. |
| `getChildCount` | `getChildCount()` | `int` | Get number of child widgets. |
| `getChild` | `getChild(index)` | `TWidget` | Get child widget at index (1-based). |

## Usage Example

```lua
-- Create a terminal
local term = luna.terminal.newTerminal(80, 25)
term:setFont(luna.graphics.newFont("monospace.ttf", 14))

-- Direct cell manipulation
term:set(1, 1, "@", 0,1,0,1, 0,0,0,1)  -- green @ at top-left

-- Build a UI with widgets
local border = luna.terminal.newBorder(5, 3, 30, 10)
border:setStyle("double")
border:setTitle("Character")

local nameLabel = luna.terminal.newLabel(7, 5, "Name: Hero")
nameLabel:setColor(1, 1, 0)

local attackBtn = luna.terminal.newButton(7, 8, 10, 1, "Attack")
attackBtn:setOnClick(function()
    print("Attack!")
end)

local input = luna.terminal.newTextBox(7, 10, 20)
input:setMaxLength(32)
input:setOnChange(function()
    print("Input: " .. input:getText())
end)

local skills = luna.terminal.newList(40, 3, 20, 10)
skills:addItem("Fireball")
skills:addItem("Heal")
skills:addItem("Shield")
skills:setOnSelect(function()
    local sel = skills:getSelected()
    if sel then print("Selected: " .. skills:getItem(sel)) end
end)

-- Add widgets to terminal
term:addWidget(border)
term:addWidget(nameLabel)
term:addWidget(attackBtn)
term:addWidget(input)
term:addWidget(skills)

-- Focus the text box for keyboard input
term:setFocus(input)

-- Input routing
function luna.keypressed(key)
    term:keypressed(key)
end

function luna.textinput(text)
    term:textinput(text)
end

function luna.mousepressed(x, y, button)
    term:mousepressed(x, y, button)
end

-- Render
function luna.draw()
    term:draw(10, 10)
end
```
