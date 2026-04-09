# Colony Sim

A top-down colony builder where you place farms, beds, and recreation halls to keep your colonists fed, rested, and happy. Colonists evaluate their lowest need every tick and autonomously walk to the relevant building, while a rolling day/night cycle forces them to sleep before exhaustion sets in.

## What It Demonstrates

- `lurek.gfx.rectangle()` — tile grid, building footprints, and stat bar rendering
- `lurek.gfx.setColor()` — per-colonist colour coding by current state
- `lurek.gfx.print()` — HUD overlays showing food, materials, day count, and colonist stats
- `lurek.mouse.getPosition()` — placement cursor tracking across the tile grid
- `lurek.mouse.isPressed()` — left-click place / right-click assign workflow
- `lurek.keyboard.isPressed()` — number keys to switch placement type
- `lurek.gfx.setBackgroundColor()` — earthy dark-green world background
- `lurek.window.setTitle()` — runtime window title update on load

## How to Run

```powershell
cargo run -- content/demos/colony_sim
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
