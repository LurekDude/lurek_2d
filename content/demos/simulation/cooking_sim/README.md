# Cooking Sim

An Overcooked-inspired kitchen simulation where you control a chef navigating between stations — shelf, chop block, stove, plate, and serve counter. Customers place timed orders; match the right combination of prepared ingredients before the timer expires to earn money.

## What It Demonstrates

- `lurek.gfx.rectangle()` — station footprints, plate display, and order timer bars
- `lurek.gfx.setColor()` — per-ingredient colour coding and stove burn state
- `lurek.gfx.print()` — live on-screen feedback messages and score/money HUD
- `lurek.keyboard.isDown()` — four-directional WASD/arrow chef movement
- `lurek.keyboard.isPressed()` — Space to interact with the station the chef is standing on
- `lurek.keyboard.isPressed()` — number keys 1–6 to select an ingredient from the shelf
- `lurek.gfx.circle()` — chef avatar and ingredient held-in-hand indicator
- `lurek.gfx.setBackgroundColor()` — warm kitchen atmosphere

## How to Run

```powershell
cargo run -- content/demos/cooking_sim
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
