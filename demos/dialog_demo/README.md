# Dialog Demo

A dialog sequencer: typewriter text rendering, branching choices, and scripted event callbacks. Shows how to drive story-style dialogue from Lua.

## What It Demonstrates

- `luna.dialog.newSequencer()` — create a dialog sequence runner
- `luna.dialog.newNode()` — text, choice, event, and call node types
- Typewriter effect: revealing text character by character per frame
- Choice menus: rendering option lists and handling selection
- `luna.dialog.onEvent()` — callback when an event node fires
- Integrating dialog output into game state (log lines)

## How to Run

```powershell
cargo run -- examples/dialog_demo
```

## Controls

| Key | Action |
|-----|--------|
| Space / Enter | Advance text / confirm choice |
| Up / Down arrows | Navigate choices |

## Notes

- Uses `conf.lua` to configure the window
- Good foundation for visual-novel or RPG dialogue systems
