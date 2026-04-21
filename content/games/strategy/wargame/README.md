# Wargame

Hex-grid turn-based wargame with infantry, tanks, artillery, and recon across terrain-varied battlefields.

## Run
```
cargo run -- content/games/strategy/wargame
```

## Controls
| Key | Action |
|-----|--------|
| LMB | Select unit → click blue hex to move → click red hex to attack |
| Enter | End player turn |
| Escape | Quit |

## Unit Types
| Unit | HP | ATK | DEF | MOV | RNG |
|------|-----|-----|-----|-----|-----|
| Infantry | 10 | 5 | 1 | 2 | 1 |
| Tank | 16 | 9 | 2 | 3 | 1 |
| Artillery | 8 | 12 | 0 | 1 | 3 |
| Recon | 6 | 3 | 0 | 4 | 2 |

## Terrain
| Terrain | Defense Bonus | Notes |
|---------|--------------|-------|
| Plain | +0 | No effect |
| Forest | +1 | Movement -1 for all |
| Mountain | +2 | Impassable for tanks |
| City | +2 | Supply source |

## Gameplay
Command a combined-arms force across a hex grid. Move and attack with each unit per turn, then press Enter to give the enemy its turn. Terrain and unit matchups matter — use Artillery from range, Recon for scouting, and Tanks for rapid advances. Destroy all enemy units to win.

## APIs Used
- `lurek.render` — hex grid with terrain tinting, unit icons, move/attack overlays
- `lurek.particle` — attack sparks, unit death burst, movement dust
- `lurek.input` — action bindings for click and turn-end
- `lurek.window`, `lurek.event`

## Changes from Original Demo
### Replaced
- Square grid → hex grid using offset coordinates (more authentic wargame feel)
- Primitive rectangles → unit icons (INF/TNK/ART/RCN) with HP bars

### Added
- 4 unit types with distinct stats (tank, recon, artillery, infantry)
- Terrain defense bonuses and tank impassability for mountains
- Particle effects: attack sparks, death burst, movement dust
- Combat log with fading message history
- Enemy AI with targeting priority

### Removed
- Nothing

### Open questions
- Fog of war / line of sight
- Resupply mechanics at cities
