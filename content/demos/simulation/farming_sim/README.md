# Farming Sim

A top-down life and farming simulation with a full seasonal calendar and day/night lighting. Plant wheat, tomatoes, or pumpkins on your soil tiles, wait the appropriate number of days for them to mature, then sell the harvest at the shop to buy more seeds. Seasons affect crop growth speed, and winter slows everything down.

## What It Demonstrates

- `lurek.gfx.rectangle()` — tile map, soil plots, crop stems, and HUD panel rendering
- `lurek.gfx.circle()` — ripe crop icons and growth-stage seedling indicators
- `lurek.gfx.setColor()` — dynamic day/night factor applied to every colour each frame
- `lurek.gfx.setBackgroundColor()` — season-tinted background that updates in `lurek.draw()`
- `lurek.gfx.print()` — day, season, money, seed inventory, and harvest count HUD
- `lurek.keyboard.isDown()` — WASD tile-grid farmer movement
- `lurek.keyboard.isPressed()` — N to advance day, B to buy, S to sell, 1–3 select crop
- `lurek.mouse.isPressed()` — left-click to plant selected crop on soil, right-click to harvest

## How to Run

```powershell
cargo run -- content/demos/farming_sim
```

## Controls

| Input | Action |
|-------|--------|
| WASD / Arrow keys | Move farmer |
| Left-click on soil | Plant selected crop (costs seeds) |
| Right-click on grown crop | Harvest into inventory |
| 1 / 2 / 3 | Select Wheat / Tomato / Pumpkin |
| B | Buy seeds for selected crop ($5 / $8 / $12) |
| S | Sell all harvested crops |
| N | Advance to the next day (manual mode) |
| T | Toggle automatic day timer |
| Escape | Quit |

## Notes

- Seasons cycle every 12 in-game days (Spring → Summer → Autumn → Winter) and wrap back to Spring.
- Winter doubles all crop `growTime` values, making planting high-value pumpkins risky late in the year.
- The day/night factor is computed from `dayTimer / dayDuration` using a dawn/midday/dusk curve that scales every drawn colour by the same multiplier.
- Growth progress is displayed as a scaled seedling circle so you can visually gauge time remaining without checking numbers.
