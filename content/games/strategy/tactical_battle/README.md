# Tactical Battle

Turn-based grid squad tactics with 4 unit types, terrain effects, and AI-driven enemy turns.

## Run
```
cargo run -- content/games/strategy/tactical_battle
```

## Controls
| Key | Action |
|-----|--------|
| LMB | Select unit → click blue tile to move → click red tile to attack |
| Enter | End player turn |
| Escape | Quit |

## Gameplay
Command a squad of Soldiers, Archers, Knights, and Mages across a grid map. Forests give +1 defense; water is impassable. Defeat all enemy units to win. After your turn, the enemy AI plans moves and attacks automatically.

## APIs Used
- `lurek.render` — grid, terrain overlay, move/attack highlights, unit icons
- `lurek.particle` — attack sparks, death burst, movement dust
- `lurek.input` — action-bound click and turn-end
- `lurek.window`, `lurek.event`

## Changes from Original Demo
### Replaced
- Primitive rect-filled grid → terrain-colored tiles with forest/water variants
- No feedback → particles on attack, death, and movement
- No AI → full enemy turn with movement + attack logic

### Added
- 4 unit types: Soldier, Archer, Knight, Mage (with AOE flag)
- Terrain defense bonuses
- Turn indicator and combat log
- Greyed-out unit sprites when fully spent

### Removed
- Nothing

### Open questions
- Animated unit movement (tween to destination)
- Multi-tile AOE Mage attacks
