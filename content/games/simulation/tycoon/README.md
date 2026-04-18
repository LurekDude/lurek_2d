# Tycoon

Business empire tycoon — buy ventures, hire managers, upgrade revenue, and prestige your way to a million gold.

## Run

```
cargo run -- content/games/simulation/tycoon
```

## Controls

| Key       | Action                                        |
| --------- | --------------------------------------------- |
| 1–6       | Buy business (Lemonade Stand → Tech Company)  |
| Space     | Collect gold from ready business              |
| M + Click | Hire manager for a business (auto-collect)    |
| U + Click | Upgrade a business (double revenue)           |
| P         | Prestige (reset with 2× permanent multiplier) |
| Escape    | Quit                                          |

## Gameplay

Start with 500 gold and a single lemonade stand. Purchase six tiers of businesses — from a humble lemonade stand earning 1 gold per second to a tech company generating 5 000 gold every 20 seconds. Each business shows a progress bar that fills over its cycle time; when full, press Space to collect the earnings (or hire a manager to auto-collect). Upgrade businesses to double their revenue, and level them up to five times for a cumulative +50 % bonus per level. Once you hit 100 000 gold you can prestige, resetting all businesses but gaining a permanent 2× income multiplier. Goal: reach 1 000 000 gold.

## Features

- Six business tiers with escalating cost, revenue, and cycle time
- Manager system for automatic gold collection
- Revenue upgrades and five-level business progression
- Prestige loop with permanent multiplier stacking
- Gold-burst particles on collection, flash on upgrade, explosion on prestige
- Tweened progress bars, gold counter animation, and business unlock slides
- Title screen, prestige confirmation, and real-time stats HUD
