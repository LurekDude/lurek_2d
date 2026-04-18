# Maze Defense

Hybrid tower defense where YOU build the maze. Place walls to extend the enemy path, then add towers to mow them down — but you can never fully block the route.

## Run
```
cargo run -- content/games/strategy/maze_defense
```

## Controls
| Key | Action |
|-----|--------|
| LMB | Place wall (10 gold) |
| RMB | Place tower (25 gold) |
| Space | Start next wave |
| Escape | Quit |

## Gameplay
Enemies spawn from the left and march to the green base on the right. Build walls to force them into longer paths, place towers to deal damage. Survive 5 waves to win. Killing enemies earns gold for more defenses.

## APIs Used
- `lurek.render` — grid, enemy HP bars, bullet projectiles
- `lurek.particles` — enemy death explosions
- `lurek.input` — mouse placement, action bindings
- `lurek.window`, `lurek.signal`

## Changes from Original Demo
### Replaced
- Static pre-built path → dynamic BFS path forced through placed walls
- Manual bullet tracking → dedicated bullets table with progress lerp
- No enemy HP bars → scaled rect HP display per enemy

### Added
- BFS maze validation (can never completely block path)
- Tower range-based targeting with cooldown
- 5-wave progression with gold rewards
- Build / combat phase split

### Removed
- Nothing

### Open questions
- Tower upgrade tiers
- Multiple tower types (slow, area, pierce)
