# Galaga

Classic Galaga arcade shooter with formation enemies, dive-bombing attacks, boss capture mechanics, and dual-fire power-ups.

## Run
```
cargo run -- content/games/arcade/galaga
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
Destroy waves of aliens arranged in formation. Enemies periodically break formation and dive-bomb the player with aimed bullets. Boss enemies (top row) take 2 hits — the first changes their color, the second destroys them. A boss can capture your ship with a tractor beam; destroying that boss afterward grants a dual-fire power-up (two ships side by side). Every 3rd wave is a challenging stage where enemies fly in patterns without shooting — bonus points for hitting all of them. Enemy aggression increases each wave.

## APIs Used
lurek.window, lurek.render, lurek.input, lurek.signal, lurek.time, lurek.camera

## Changes from Original Demo
### Replaced
- Raw key polling → action-based input
### Added
- Title screen with star field, particles on explosions, tween score pop, render/render_ui split, FPS counter, camera, challenging stages, boss capture & dual-fire, multi-layer parallax star field
### Removed
- Nothing
