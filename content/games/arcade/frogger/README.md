# Frogger

Classic Frogger arcade game — guide the frog across busy roads and treacherous rivers to reach the home slots.

## Run
```
cargo run -- content/games/arcade/frogger
```

## Controls
| Key       | Action          |
| --------- | --------------- |
| Up / W    | Hop forward     |
| Down / S  | Hop backward    |
| Left / A  | Hop left        |
| Right / D | Hop right       |
| Enter     | Start / Restart |
| Escape    | Quit            |

## Gameplay
Navigate a frog from the bottom safe zone across 5 lanes of traffic, through a middle safe zone, then across 5 river lanes to reach one of 5 home slots at the top. Cars and trucks on the road kill the frog on contact. On the river, the frog must ride logs or turtle groups — falling in the water is fatal. Turtles periodically submerge, dumping the frog into the water. A bonus fly appears randomly in home slots for extra points. A countdown timer adds urgency — running out of time costs a life. Fill all 5 home slots to complete the level; each new level increases speeds. Three lives to start.

## APIs Used
lurek.window, lurek.render, lurek.input, lurek.signal, lurek.time, lurek.camera, lurek.tween, lurek.particles

## Changes from Original Demo
### Replaced
- Raw key polling → action-based input
### Added
- Title screen with ASCII frog art, particles (splash/poof), tweened hop animation, render/render_ui split, FPS counter
### Removed
- Nothing
