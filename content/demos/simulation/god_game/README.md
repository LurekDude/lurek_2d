# God Game

An ecosystem god-game where you watch over tribes, predators, and prey on a procedurally generated tile world. Faith accumulates when tribes worship at temples you place, and you spend faith on miracles — rain, lightning, healing, and food drops — to steer the simulation. A day/night cycle affects tribe movement speed and a storm system provides dramatic weather events.

## What It Demonstrates

- `lurek.gfx.rectangle()` — tile world rendering with terrain-color lookup table
- `lurek.mouse.getPosition()` / `lurek.mousepressed()` — miracle targeting and temple placement
- `lurek.keyboard.wasPressed()` — miracle selection cycling
- `lurek.gfx.setColor()` — day/night ambient blending and entity coloring
- `lurek.gfx.print()` — faith counter, day count, and population HUD
- `lurek.gfx.setBackgroundColor()` — base sky color
- Entity AI — tribe hunger/HP state machine, predator hunt-nearest logic, prey reproduce/wander
- Day/night cycle — 30-second oscillation gate that modifies entity movement speeds

## How to Run

```powershell
cargo run -- content/demos/god_game
```

## Controls

| Input | Action |
|-------|--------|
| Left Click | Place temple / perform miracle at cursor |
| Q / E | Cycle selected miracle |
| 1–4 | Direct miracle hotkeys (rain, lightning, heal, spawn food) |
| Escape | Quit |

## Notes

- Faith regenerates passively when tribe members are within 40 px of a temple; each miracle drains faith based on `MIRACLE_COST`
- Predator/prey populations self-regulate: predators starve when prey is scarce, prey multiply when few predators remain
- The night phase sets tribe `speed` to 30 % of day speed, making them shelter and conserve food
- Storm entities are visual overlays; they also damage tribe HP and reset their hunger timer
