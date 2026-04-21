# Stealth

Top-down stealth game — sneak past patrolling guards, collect keycards, and reach the exit unseen.

## Run

```
cargo run -- content/games/action/stealth
```

## Controls

| Key    | Action                            |
| ------ | --------------------------------- |
| W / ↑  | Move up                           |
| S / ↓  | Move down                         |
| A / ←  | Move left                         |
| D / →  | Move right                        |
| Shift  | Crouch (slower, harder to detect) |
| E      | Interact (enter/exit hide spots)  |
| Escape | Quit                              |

## Gameplay

Navigate tile-based maps while avoiding detection by patrolling guards with vision cones.

- **Vision cones** — each guard has a 60° field of view extending 5 tiles. Green = calm, yellow = suspicious, red = alert.
- **Suspicion system** — guards build suspicion (0–100) when you're in their cone with line of sight. At 50 they investigate; at 100 they chase — get caught and it's game over.
- **Crouch** — hold Shift to move at half speed, reducing guard detection range.
- **Noise** — walking without crouching generates noise ripples that attract nearby guards.
- **Hide spots** — press E near crates or bushes to hide inside, becoming invisible to guards.
- **Keycards** — collect all 3 keycards scattered across the map to unlock the exit.
- **3 levels** of increasing difficulty with more guards and tighter patrol routes.

## APIs Used

lurek.window, lurek.render, lurek.input, lurek.timer, lurek.event, lurek.particle, lurek.tween, lurek.camera
