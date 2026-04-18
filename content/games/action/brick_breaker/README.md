# Brick Breaker

Classic Arkanoid-style brick breaking game. Bounce the ball off your paddle to destroy rows of bricks, collect power-ups, and advance through increasingly difficult levels.

## Run

```bash
cargo run -- content/games/action/brick_breaker
```

## Controls

| Key            | Action                            |
| -------------- | --------------------------------- |
| A / D or ← / → | Move paddle left / right          |
| Space          | Launch ball                       |
| Enter          | Start game / next level / restart |
| Escape         | Quit                              |

## Power-Ups

Power-ups drop from destroyed bricks (30% chance). Catch them with the paddle to activate.

| Symbol         | Effect                                 | Duration  |
| -------------- | -------------------------------------- | --------- |
| **W** (orange) | Widens the paddle                      | 8 seconds |
| **M** (cyan)   | Splits every ball into two extra balls | Instant   |
| **S** (green)  | Slows ball speed by ~45%               | 8 seconds |

## Mechanics

- 10-column brick grid with 4–8 rows depending on level
- Bricks have 1–3 HP; colour changes with remaining HP (green → blue → purple)
- Ball angle varies based on where it hits the paddle (edge shots = sharper angles)
- Ball speed increases slightly each level
- 3 lives — ball below paddle costs one life
- Clear all bricks to advance to the next level

## lurek.* APIs Used

- `lurek.window` — setTitle
- `lurek.render` — setBackgroundColor, rectangle, circle, print (world + UI split)
- `lurek.input` — bind, isActionDown, wasActionPressed
- `lurek.time` — getFPS
- `lurek.signal` — quit
- `lurek.particles` — newSystem, emit, setColors, setSizes, setLifetime, setSpeed, setSpread
- `lurek.tween` — to (level-complete flash)
- `lurek.camera` — new
