# Logic Game

Robot programming puzzle — write a program of movement commands to guide your robot to the goal in limited steps.

## Run
```
cargo run -- content/games/strategy/logic_game
```

## Controls
| Key | Action |
|-----|--------|
| W/A/S/D | Set selected slot to Up/Left/Down/Right |
| Space | Set selected slot to Wait |
| ←/→ | Move slot cursor |
| Enter | Run program |
| R | Reset level |
| N | Next level |
| Escape | Quit |

## Gameplay
Fill the program slots with movement commands, then run to see your robot follow them step-by-step. Reach the green goal cell using only the allowed number of commands. Two maze levels included.

## APIs Used
- `lurek.render` — grid, robot, animated program bar
- `lurek.particles` — step trail, win burst
- `lurek.input` — action-bound commands
- `lurek.window`, `lurek.signal`

## Changes from Original Demo
### Replaced
- Hand-drawn rectangle robot → styled colored block with particle trail
- Hardcoded key checks → `lurek.input` action bindings

### Added
- BFS valid-path enforcement
- Particle step trail and victory burst
- Slot cursor and in-place program editor

### Removed
- Nothing

### Open questions
- Font-based command glyphs (UP/DN arrows) would improve readability
