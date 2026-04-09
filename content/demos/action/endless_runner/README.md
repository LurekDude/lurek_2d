# Endless Runner

A side-scrolling infinite runner where your character auto-moves right through an obstacle course. Jump over tall barriers, slide under low beams, and collect coins for bonus points as the world continuously speeds up. The run ends the moment you collide with any obstacle.

## What It Demonstrates

- `luna.gfx.rectangle()` — ground, obstacle, and player body rendering
- `luna.gfx.circle()` — coin pickups with radius-based collection detection
- `luna.gfx.setColor()` — parallax layer tinting and death-flash effect
- `luna.gfx.print()` — live score, high score, and game-over overlay text
- `luna.keyboard.isDown()` — held Space for jump, held Down for slide
- `luna.gfx.setBackgroundColor()` — night-sky dark blue atmosphere

## How to Run

```powershell
cargo run -- demos/endless_runner
```

## Controls

| Input | Action |
|-------|--------|
| Space | Jump (while grounded) |
| Down arrow | Slide (halves hitbox height while grounded) |
| Enter | Restart after death |
| Escape | Quit |

## Notes

- Three parallax background layers scroll at 0.2×, 0.5×, and 0.8× game speed to create depth.
- World speed ramps up continuously: `speed = 300 + distance × 0.05`, making infinite survival impossible by design.
- Particle bursts fire on coin collection (gold) and on death (red), using a simple velocity + lifetime system.
- Obstacle and coin spawners use independent random timers to avoid predictable clustering.
