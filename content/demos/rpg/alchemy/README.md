# Alchemy Demo

An alchemy workshop where you grind ingredients in a mortar, transfer them to a cauldron, control the temperature, brew potions, bottle the results, and sell them for gold.

## What It Demonstrates

- Multi-step pipeline UI: mortar → grind → cauldron → bottle → sell
- Recipe matching by element totals (`fire`, `water`, `earth`, `air`) and temperature range
- `luna.mouse.getPosition()` + AABB testing for all click targets
- `luna.mousepressed` callback for drag-free click interactions
- Accumulator-based cooldown timer for the grinding animation
- Discovery tracking: first successful brew reveals a recipe name in the log
- `luna.gfx.circle()`, `rectangle()`, and `print()` for all UI

## How to Run

```powershell
cargo run -- demos/alchemy
```

## Controls

| Input | Action |
|-------|--------|
| Left click ingredient | Add to mortar (max 3) |
| Left click mortar | Start grinding (1.5 s) |
| Left click cauldron | Pour ground ingredients in |
| ↑ / ↓ Arrow keys | Raise / lower cauldron temperature |
| Space | Brew (apply recipe matching) |
| Left click bottle | Pour result into bottle |
| B | Bottle the brewed result |
| S | Sell the bottled potion |
| R | Clear workbench |
| Escape | Quit |

## Notes

- 12 unique recipes with overlapping element ranges — experimenting is part of the fun.
- Out-of-range temperature produces Toxic Sludge or Murky Water instead of a real potion.
- The `panacea` recipe requires balanced 1–3 of all four elements at exactly 45–55 °C.
