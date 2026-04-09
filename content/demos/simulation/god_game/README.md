# God Game

An ecosystem god-game where you watch over tribes, predators, and prey on a procedurally generated tile world. Faith accumulates when tribes worship at temples you place, and you spend faith on miracles — rain, lightning, healing, and food drops — to steer the simulation. A day/night cycle affects tribe movement speed and a storm system provides dramatic weather events.

## What It Demonstrates

- `luna.gfx.rectangle()` — tile world rendering with terrain-color lookup table
- `luna.mouse.getPosition()` / `luna.mousepressed()` — miracle targeting and temple placement
- `luna.keyboard.wasPressed()` — miracle selection cycling
- `luna.gfx.setColor()` — day/night ambient blending and entity coloring
- `luna.gfx.print()` — faith counter, day count, and population HUD
- `luna.gfx.setBackgroundColor()` — base sky color
- Entity AI — tribe hunger/HP state machine, predator hunt-nearest logic, prey reproduce/wander
- Day/night cycle — 30-second oscillation gate that modifies entity movement speeds

## How to Run

```powershell
cargo run -- demos/god_game
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
