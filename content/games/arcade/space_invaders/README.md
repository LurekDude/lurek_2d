# Space Invaders

Defend Earth from descending alien formations. Shoot them before they reach you.

## Run
```
cargo run -- content/games/arcade/space_invaders
```

## Controls
| Key               | Action     |
| ----------------- | ---------- |
| A/D or Left/Right | Move ship  |
| Space             | Fire       |
| Enter             | Start game |
| R                 | Restart    |
| Escape            | Quit       |

## Gameplay
11×5 alien grid marches across the screen and descends. Destroy all aliens to advance waves. Use shields for cover. Watch for the UFO bonus!

## APIs Used
lurek.window, lurek.render, lurek.input, lurek.signal, lurek.time, lurek.particles, lurek.tween, lurek.camera

## Changes from Original Demo
### Replaced
- Raw key polling → action-based input
### Added
- Title screen with point value table, particles on explosions, tween score pop, render/render_ui split, FPS counter, camera
### Removed
- Nothing
