# Hex Strategy

Turn-based hex-grid expansion game — claim territory, build cities, and accumulate resources over successive turns.

## Run
```
cargo run -- content/games/strategy/hex_strategy
```

## Controls
| Key | Action |
|-----|--------|
| LMB | Select hex; if adjacent to owned + affordable, expand there |
| C | Build city on the selected owned hex |
| N | End turn and collect resources |
| Escape | Quit |

## Gameplay
You start at the center hex. Each turn you collect resources from all owned hexes (Gold, Wood, Food). Click any unowned hex adjacent to your territory to claim it for 30 gold + 10 wood. Build cities (50g + 20w + 20f) to double a hex's resource yield. Score increases each turn proportional to territory size.

## Terrain
| Terrain | Gold | Wood | Food |
|---------|------|------|------|
| Grass | 1 | 0 | 3 |
| Forest | 0 | 3 | 1 |
| Water | 0 | 0 | 2 |
| Mountain | 3 | 0 | 0 |
| Desert | 2 | 0 | 0 |

## APIs Used
- `lurek.render` — hex grid using rect approximation, city markers, ownership tint
- `lurek.particles` — expansion burst, city sparkle
- `lurek.input` — click selection and action bindings
- `lurek.window`, `lurek.signal`

## Changes from Original Demo
### Replaced
- `lurek.render.polygon` (not in API) → flat-hex approximation using drawRect
- Single resource → three-resource economy (gold, wood, food)
- No particle feedback → expansion burst and city sparkle particles

### Added
- Food resource and food-cost for cities
- City doubling mechanic
- Procedurally generated terrain (randomized each run)
- Info toast messages with fade-out
- Per-turn scoring

### Removed
- Nothing

### Open questions
- Enemy faction expanding from opposite edge
- Resource trading / diplomacy
