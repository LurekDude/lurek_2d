# Match 3 — Lurek2D

**Category:** strategy

Classic match-3 puzzle game. Swap adjacent gems on an 8×8 board to create lines of 3 or more matching colors. Matched gems disappear, new gems fall in, and chain reactions multiply your score.

## Run

```
cargo run -- content/games/strategy/match3
```

## Controls

| Key | Action |
|-----|--------|
| Mouse click | Select / swap gem |
| Escape | Quit |

## Game Modes

| Mode | Goal |
|------|------|
| Timed | 60 seconds — highest score wins |
| Moves | 30 moves — highest score wins |
| Target | Reach score target to advance (10 levels, increasing target) |

## Mechanics

- **Grid**: 8×8 board with 6 gem colors (red, blue, green, yellow, purple, orange).
- **Swapping**: Click a gem, then click an adjacent gem (horizontal/vertical only). If the swap creates a match of 3+, the gems are consumed. Otherwise the swap reverses.
- **Gravity**: After a match, gems above fall to fill gaps. Empty top slots spawn new random gems.
- **Chain reactions**: Cascading matches from falling gems award combo multipliers (2×, 3×, …).
- **Scoring**: 3-match = 100 pts, 4-match = 300 pts, 5-match = 1000 pts. Cascade multiplier applied.
- **Special gems**: 4-match → Bomb (3×3 explosion), 5-match → Rainbow (destroy all of one color), L/T shape → Cross (destroy row + column).
- **Hints**: After 5 seconds of inactivity a valid swap flashes.
- **Reshuffle**: If no valid moves remain the board reshuffles automatically.

## Features

- Three selectable game modes with level progression (Target mode)
- Special gem types with unique destruction effects
- Particle effects on gem destruction, cascades, and special activation
- Tweened gem swaps, gravity falls, score popups, and combo text
- Full render/render_ui split with HUD overlay
