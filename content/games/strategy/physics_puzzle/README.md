# Physics Puzzle

Place planks, ramps, and blocks to guide a falling ball into the goal — with a limited shape budget.

## Run
```
cargo run -- content/games/strategy/physics_puzzle
```

## Controls
| Key | Action |
|-----|--------|
| LMB | Place selected shape |
| Tab | Cycle shape type |
| E / Q | Rotate shape clockwise / counter-clockwise |
| Space | Launch ball |
| R | Reset level |
| N | Next level |
| Escape | Quit |

## Gameplay
You have a limited budget of shapes per level. Place them strategically to redirect the rolling ball into the green goal circle. 3 levels of increasing difficulty included.

## APIs Used
- `lurek.render` — shapes, ball, goal, walls, preview ghost
- `lurek.particles` — ball trail, bounce sparks, win burst
- `lurek.input` — action bindings for placement, rotation, launch
- `lurek.window`, `lurek.signal`

## Changes from Original Demo
### Replaced
- Rectangle stand-ins → distinct shape types (plank, ramp, block, wedge)
- No feedback → particle trail on ball, sparks on bounce, burst on win
- Hardcoded key polling → `lurek.input` action bindings

### Added
- Ghost preview while placing
- Shape budget per level
- Score based on time-to-solve
- 3 selectable levels

### Removed
- Nothing

### Open questions
- `lurek.physics` (rapier2d) integration for proper rigid body simulation
