# Demo Game

Physics-based shooting gallery with moving targets, combo scoring, and power-ups. Aim with the mouse and fire balls at swaying targets across three increasingly difficult rounds.

## Run

```
cargo run -- content/games/showcase/demo_game
```

## Controls

| Input      | Action        |
| ---------- | ------------- |
| Mouse      | Aim crosshair |
| Left Click | Fire ball     |
| Escape     | Quit          |

## Gameplay

Fire balls from the bottom of the screen toward moving rectangular targets arranged in five rows. Gravity pulls each ball downward while targets sway left and right with increasing speed per row and per round. Score points based on target size: small (3 pts), medium (2 pts), large (1 pt). Build combos by hitting consecutive targets for multiplied scores up to 4×. Collect power-ups dropped by every 5th target: triple shot, big ball, and slow motion.

Ten balls per round across three rounds. Targets reset each round with faster sway. The end screen shows total score, accuracy, and best combo.

### Target Types
- **Small** (20×20) — 3 points, hardest to hit
- **Medium** (40×40) — 2 points
- **Large** (60×40) — 1 point, easiest to hit

### Power-Ups
- **Triple Shot** (red) — fires three balls in a spread
- **Big Ball** (green) — doubled ball radius for 3 shots
- **Slow-Mo** (blue) — halves target sway speed for 5 seconds

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.particles`, `lurek.tween`, `lurek.time`, `lurek.signal`
