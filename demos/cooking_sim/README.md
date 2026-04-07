# Cooking Sim

An Overcooked-inspired kitchen simulation where you control a chef navigating between stations — shelf, chop block, stove, plate, and serve counter. Customers place timed orders; match the right combination of prepared ingredients before the timer expires to earn money.

## What It Demonstrates

- `luna.graphics.rectangle()` — station footprints, plate display, and order timer bars
- `luna.graphics.setColor()` — per-ingredient colour coding and stove burn state
- `luna.graphics.print()` — live on-screen feedback messages and score/money HUD
- `luna.keyboard.isDown()` — four-directional WASD/arrow chef movement
- `luna.keyboard.isPressed()` — Space to interact with the station the chef is standing on
- `luna.keyboard.isPressed()` — number keys 1–6 to select an ingredient from the shelf
- `luna.graphics.circle()` — chef avatar and ingredient held-in-hand indicator
- `luna.graphics.setBackgroundColor()` — warm kitchen atmosphere

## How to Run

```powershell
cargo run -- demos/cooking_sim
```

## Controls

| Input | Action |
|-------|--------|
| WASD / Arrow keys | Move chef |
| Space | Interact with current station |
| 1–6 | Select ingredient from shelf |
| Escape | Quit |

## Notes

- Stove items progress through `raw → cooked → burnt` states based on elapsed time; burnt food cannot be served.
- The chopping station requires four Space presses to fully chop an ingredient.
- Orders expire after a fixed countdown; expired orders are removed and no points are awarded.
- Recipe matching is order-agnostic — the plate just needs to contain all required ingredient-state tokens.
