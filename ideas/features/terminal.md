# terminal — Feature Analysis

**Tier**: 2 (Extension)
**Spec**: `specs/terminal.md`
**Files**: Grid-based character-cell terminal emulator with widget toolkit

## Purpose

Grid-based terminal emulator: character cells with foreground/background colors, plus a 6-type widget toolkit for building text-UI applications, debug consoles, and retro-style interfaces.

## Current Feature Summary

- `Terminal`: grid of `TCell` (character + fg/bg colors), default 80×40
- 6 widget types: Label, Button, TextBox, List, Border, Panel
- `WidgetBase`: shared state (position, size, visible, enabled, focused)
- Fixed 8×14 pixel cell size
- Color per cell (foreground and background)
- Text output: print, clear, scroll
- Widget events: click, text change, selection change
- Border styles: single, double, rounded, heavy, ASCII
- Panel as container for other widgets
- ~30+ Lua API methods

## Feature Gaps

1. **No scrollback buffer**: Terminal output scrolls off-screen and is lost. No history buffer for scroll-back.
2. **No command history**: TextBox input has no up/down arrow history recall. Essential for command-line interfaces.
3. **No syntax highlighting**: No way to colorize text by patterns (keywords, numbers, strings). Important for debug terminals.
4. **No tab completion**: No autocomplete for typed commands.
5. **No clickable links/hotspots**: Can't make text regions clickable within the terminal grid.
6. **No color themes**: No preset color schemes (solarized, monokai, etc.). Must set colors per cell.
7. **No copy/paste**: Can't select and copy text from the terminal.
8. **Fixed cell size**: 8×14 is hardcoded. Can't use different font sizes or custom fonts.
9. **No ANSI escape codes**: Can't process standard terminal escape sequences for color/cursor control.
10. **No cursor blinking**: Cursor visibility but no blink animation.

## Structural Issues

- **Widget toolkit inside terminal**: The terminal combines two concepts: a character-cell display AND a widget toolkit. These could be separate (terminal + terminal_widgets). However, the widgets are terminal-specific (grid-aligned), so keeping them together is reasonable.
- **Clean tier placement**: Depends on graphics (Tier 1) for rendering. Correct as Tier 2.
- **Overlap with GUI module**: Both terminal and GUI provide interactive widgets. Terminal widgets are grid-based; GUI widgets are pixel-based. Clear distinction but users might be confused about which to use.

## Suggestions

1. **Add scrollback buffer**: `terminal:setScrollback(lines)` — store N lines of history. Support scroll up/down.
2. **Add command history**: `textBox:enableHistory(maxEntries)` — up/down arrows recall previous inputs.
3. **Add syntax highlighting**: `terminal:printHighlighted(text, rules)` — colorize by pattern matching rules.
4. **Add ANSI escape code support**: `terminal:printAnsi(ansiString)` — process `\033[31m` style color codes. Enables compatibility with standard terminal output.
5. **Add configurable cell size**: `terminal:setCellSize(w, h)` or `terminal:setFont(font)` — allow different font sizes.
6. **Add color themes**: `terminal:setTheme("solarized")` — preset themes with named color mappings.
7. **Document use cases**: Clarify when to use Terminal vs GUI: Terminal for retro/console UIs, debug tools, MUD-style games. GUI for modern menus, HUDs, settings.

## Competitor Comparison

No competitor 2D Lua engine has a built-in terminal emulator. This is unique to Lurek2D.

| Feature | Lurek2D | Engine A | Engine B | a terminal rendering library |
|---|---|---|---|---|
| Character grid | ✅ | ❌ | ❌ | ✅ |
| Widgets | ✅ (6 types) | N/A | N/A | ❌ |
| Color per cell | ✅ | N/A | N/A | ✅ |
| Scrollback | ❌ | N/A | N/A | ❌ |
| ANSI codes | ❌ | N/A | N/A | ❌ |
| Custom fonts | ❌ | N/A | N/A | ✅ |

The terminal module is a genuine differentiator for roguelike and retro game development. a terminal rendering library is the closest equivalent, but Lurek2D integrates it with a full game engine.

## Priority

**MEDIUM** — Scrollback and command history are the most impactful. ANSI support and configurable cell size improve versatility. The module is already unique and functional.
