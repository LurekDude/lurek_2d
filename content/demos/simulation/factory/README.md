# Factory

A grid-based factory automation demo in the style of Factorio. Place miners on ore patches to extract raw ore, route it along conveyor belts to smelters that smelt ingots, and feed those ingots into assemblers that produce finished products. Items move tile-by-tile at a configurable belt speed.

## What It Demonstrates

- `lurek.gfx.rectangle()` — grid cell backgrounds, building footprints, and item dots
- `lurek.gfx.polygon()` — directional arrows drawn on each machine to show output direction
- `lurek.gfx.line()` — grid line overlay over the entire play area
- `lurek.gfx.setColor()` — distinct colours per machine type and item type
- `lurek.gfx.print()` — product and ingot counters, placement HUD, and input queue display
- `lurek.mouse.getPosition()` — grid cursor calculation from pixel coordinates
- `lurek.mouse.isPressed()` — left-click place, right-click delete
- `lurek.keyboard.isPressed()` — 1–4 to select machine, R to rotate output direction

## How to Run

```powershell
cargo run -- content/demos/factory
```

## Controls

| Input | Action |
|-------|--------|
| 1 | Select Conveyor Belt |
| 2 | Select Miner |
| 3 | Select Smelter |
| 4 | Select Assembler |
| R | Rotate output direction (right → down → left → up) |
| Left-click | Place selected machine on grid cell |
| Right-click | Delete machine from grid cell |
| Escape | Quit |

## Notes

- Miners produce 1 ore every 2 seconds but only when placed on an ore patch (highlighted brown).
- Smelters convert 1 ore → 1 ingot every 3 seconds; assemblers convert 2 ingots → 1 product every 4 seconds.
- Items that reach the grid boundary are consumed: products increment the global counter.
- The belt `progress` value (0→1) tracks sub-tile position; machines only accept items when their input queue has capacity.
