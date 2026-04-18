# Trajectory Sports

**Category:** sports

A collection of four projectile-based sports minigames: Archery, Basketball, Bowling, and Darts. Each sport features unique physics, scoring, and controls. Play all four and earn a combined medal ranking.

## Run

```
cargo run -- content/games/sports/trajectory_sports
```

## Controls

| Key          | Action                                 |
| ------------ | -------------------------------------- |
| 1–4          | Select sport from menu                 |
| Space (hold) | Charge power / throw                   |
| W / S        | Aim up / down                          |
| A / D        | Move left / right (bowling) / position |
| Escape       | Quit                                   |

## Sports

1. **Archery** — Side-view bow & target. Hold Space to draw, W/S to adjust angle, release to fire. Wind varies each shot. Bullseye = 10 pts, outer rings less. 10 arrows per round.
2. **Basketball** — Side-view court. Hold Space for power, W/S for arc angle. Swish = 3 pts, rim bounce = 2 pts. 10 shots per round.
3. **Bowling** — Top-down lane. A/D to position, hold Space for power, A/D during roll for spin. Pins knock other pins. 10 frames with standard scoring.
4. **Darts** — Front-view board with figure-8 wobbling crosshair. Press Space to throw. Standard dartboard scoring with 301 countdown. 3 darts per turn, 5 turns.

## Scoring

Each sport awards a medal (Gold / Silver / Bronze) based on performance thresholds. Combined medal points determine the final ranking.
