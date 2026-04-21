# RTS

Real-time strategy game — build a base, train units, harvest resources, and survive 5 enemy waves.

## Run
```
cargo run -- content/games/strategy/rts
```

## Controls
| Key | Action |
|-----|--------|
| LMB | Select unit(s) |
| RMB | Order selected units to move/attack |
| T | Train unit at barracks (50 gold) |
| WASD | Scroll camera |
| Escape | Quit |

## Gameplay
Harvest gold and wood from resource nodes on the map. Train soldiers from your barracks. Enemy waves arrive every 20–30 seconds from the top-right. Defend your base through 5 waves to win.

## APIs Used
- `lurek.render` — map, units, buildings, resource nodes
- `lurek.particle` — death explosions, selection feedback
- `lurek.input` — action bindings for selection, ordering, training
- `lurek.camera` (via manual cam offset)
- `lurek.window`, `lurek.event`

## Changes from Original Demo
### Replaced
- Static single-screen → scrollable map (1800×1200)
- No resource system → gold + wood with auto-harvesting when near nodes
- Hardcoded enemy → unit AI that attacks nearest player unit

### Added
- Barracks building with train cooldown
- Wave system (5 waves with scaling difficulty)
- Score counter per enemy kill
- Selection ring particle effect

### Removed
- Nothing

### Open questions
- Multiple building types (towers, walls)
- Fog of war
