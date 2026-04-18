# Tower Defense

Classic grid-based tower defense — place towers on a pre-laid path, survive 6 enemy waves.

## Run
```
cargo run -- content/games/strategy/tower_defense
```

## Controls
| Key | Action |
|-----|--------|
| LMB | Place selected tower (non-path tile) |
| Tab | Cycle to next tower type |
| Q | Cycle to previous tower type |
| Space | Send next wave |
| Escape | Quit |

## Tower Types
| Type | Cost | Damage | Range | Rate |
|------|------|--------|-------|------|
| Basic | 50g | 8 | 90 | 1/s |
| Rapid | 80g | 4 | 70 | 3/s |
| Sniper | 120g | 25 | 160 | 0.5/s |
| Splash | 150g | 12 | 80 (AoE 60px) | 0.8/s |

## Gameplay
Enemies walk the pre-drawn path from left to right. Place towers on any non-path tile. Each wave sends more enemies with more HP. Survive all 6 waves to win. You earn gold per kill and a bonus after each wave.

## APIs Used
- `lurek.render` — hex grid, towers, enemies, bullets, HP bars
- `lurek.particles` — hit sparks, death burst, tower placement flash
- `lurek.input` — action bindings for placement, type cycling, wave start
- `lurek.window`, `lurek.signal`

## Changes from Original Demo
### Replaced
- Two tower types → four (basic, rapid, sniper, splash with AoE)
- Demo used manual projectile tables → unified bullets array with smooth lerp
- No particle feedback → sparks on hit, burst on kill, flash on placement

### Added
- Rapid tower and Sniper tower types
- Splash (AoE) tower that damages all enemies in radius
- Build phase vs combat phase with Space to launch wave
- Post-wave gold bonus

### Removed
- Nothing

### Open questions
- Tower upgrade system
- Tower selling
