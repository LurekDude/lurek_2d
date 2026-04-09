# Physics Puzzle

A puzzle game where the player places static shapes to create a ramp that guides a falling ball into a goal zone. Each of the three levels has pre-existing platform geometry and a different ball starting position; the player has up to 8 placement pieces per attempt.

## What It Demonstrates

- `luna.physics.newWorld()` with gravity and full step/draw loop
- `luna.physics.newCircleBody()` for the dynamic ball and static circle pieces
- `luna.physics.newBody()` + `luna.physics.setBodySize()` for rectangular platforms and placed pieces
- `luna.physics.setBodyRestitution()` for tunable bounciness on the ball
- `luna.physics.getBody()` to read back simulated positions each frame
- Goal-zone AABB win detection independent of the physics engine
- Level reset: destroys the entire physics world and recreates it via `loadLevel()`

## How to Run

```powershell
cargo run -- demos/physics_puzzle
```

## Controls

| Key / Input | Action |
|-------------|--------|
| Left Click | Place a piece at the cursor position |
| `1` | Switch placement to circle (radius 20) |
| `2` | Switch placement to rectangle (60 × 16) |
| `R` | Reset current level (removes all placed pieces) |
| `Escape` | Quit |

## Notes

- Pieces are placed as **static** bodies — they do not move once placed.
- The ball resets to the start position after 8 pieces are placed or on `R`.
- Winning a level auto-advances to the next; level 3 loops back to level 1.
