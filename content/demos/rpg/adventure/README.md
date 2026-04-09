# Adventure Demo

A point-and-click adventure game spanning three rooms. Click objects to examine them, collect an inventory item, and unlock a locked door to reach the win state.

## What It Demonstrates

- `luna.mouse.getPosition()` — per-frame cursor position for hover detection
- `luna.mousepressed` callback — left-click interaction dispatch
- AABB hit-testing against rectangular hotspots entirely in Lua
- Typewriter text reveal using a character-per-second accumulator
- Inventory system: item presence checked before allowing state transitions
- Room-graph navigation: each door object carries an `exit` key that drives the room switch
- `luna.window.setTitle()` — changing the window title at runtime

## How to Run

```powershell
cargo run -- demos/adventure
```

## Controls

| Input | Action |
|-------|--------|
| Left click object | Examine / pick up / go through door |
| Left click (mid-dialog) | Skip typewriter animation |
| Escape | Quit |

## Puzzle Walkthrough

1. Click the **Dresser** in the bedroom → pick up the key.
2. Go through the **Door to Hallway**.
3. Click the **Garden Door** → the key unlocks it.
4. Pick up the **Shiny Gem** from the fountain to win.

## Notes

- Objects react differently based on which fields they have: `exit` (room change), `action` (scripted callback), or `look` (passive text).
- The typewriter dialog system and click-to-skip pattern is reusable in any Lua game.
