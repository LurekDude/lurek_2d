# Colony Sim

A top-down colony builder where you place farms, beds, and recreation halls to keep your colonists fed, rested, and happy. Colonists evaluate their lowest need every tick and autonomously walk to the relevant building, while a rolling day/night cycle forces them to sleep before exhaustion sets in.

## What It Demonstrates

- `luna.graphics.rectangle()` — tile grid, building footprints, and stat bar rendering
- `luna.graphics.setColor()` — per-colonist colour coding by current state
- `luna.graphics.print()` — HUD overlays showing food, materials, day count, and colonist stats
- `luna.mouse.getPosition()` — placement cursor tracking across the tile grid
- `luna.mouse.isPressed()` — left-click place / right-click assign workflow
- `luna.keyboard.isPressed()` — number keys to switch placement type
- `luna.graphics.setBackgroundColor()` — earthy dark-green world background
- `luna.window.setTitle()` — runtime window title update on load

## How to Run

```powershell
cargo run -- demos/colony_sim
```

## Controls

| Input | Action |
|-------|--------|
| Left-click | Place building of selected type |
| Right-click | Assign nearest idle colonist to clicked tile |
| 1 | Select Farm (costs 5 materials) |
| 2 | Select Bed (costs 5 materials) |
| 3 | Select Rec Hall (costs 5 materials) |
| Escape | Quit |

## Notes

- Each colonist runs a simple priority AI: lowest stat wins, with night-time overriding to force sleep regardless of mood.
- Farms generate 1 food every 8 seconds; each colonist consumes 1 food per in-game day.
- A new colonist spawns automatically when you have enough food surplus, up to a configured cap.
- Day length is 60 seconds; the night phase begins at 70 % through the cycle.
