# Restaurant Tycoon

A grid-based restaurant management simulation. Place counters, tables, and kitchens on a 15 × 12 tile grid; hire cooks and waiters; and serve customers as they arrive, order, and pay. Track daily satisfaction to grow your revenue.

## What It Demonstrates

- Grid-based building placement with tile type validation (only open tiles can receive buildings)
- Customer AI state machine: `"enter"` → `"seat"` (navigate to empty table) → `"wait"` → `"eating"` → `"pay"` → `"leave"`
- Staff assignment: cooks serve adjacent kitchens, waiters route orders between tables and kitchens
- Satisfaction score that rises on fast service and drops on long waits
- Day cycle timer (`DAY_LENGTH = 45 s`) ending the day and tallying revenue
- Build mode toggle (`B`): separates placement input from the simulation update
- `lurek.gfx.drawRect` + `drawText` for the entire grid and HUD, no sprites needed

## How to Run

```powershell
cargo run -- content/demos/tycoon
```

## Controls

| Key / Input | Action |
|-------------|--------|
| `B` | Toggle build mode |
| `1` | Select Counter tile |
| `2` | Select Table tile |
| `3` | Select Kitchen tile |
| Left Click (build mode) | Place selected tile |
| `H` | Hire staff (cook $20 / waiter $15, alternating) |
| `Escape` | Quit |

## Notes

- Customers will not sit if there are no empty tables — place several tables before opening.
- Kitchens must be adjacent to a counter to receive orders from waiters.
- Satisfaction below 30 starts reducing revenue per customer; keep service fast.
