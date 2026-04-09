# Brick Breaker Demo

Classic Arkanoid / Breakout clone with multi-ball, wide-paddle and slow-ball power-ups, combo scoring, and multiple levels.

## What It Demonstrates

- `lurek.mouse.getPosition()` — mouse-driven paddle following with clamped AABB boundary
- Axis-aligned ball physics using velocity reflection (no physics engine needed)
- AABB collision with overlap-axis heuristic to decide horizontal vs. vertical bounce direction
- Angle-steering: paddle hit position maps to a reflected bounce angle
- Power-up drops with a per-power-up timer system
- Particle burst system using an angle+speed explosion pattern
- Combo multiplier that resets on a paddle hit
- Automatic level progression: ball speed increases each level

## How to Run

```powershell
cargo run -- content/demos/brick_breaker
```

## Controls

| Input | Action |
|-------|--------|
| Mouse move | Steer paddle |
| Space | Launch ball when serving |
| R | Restart |
| Escape | Quit |

## Power-ups

| Colour | Type | Effect |
|--------|------|--------|
| Green | WIDE | Paddle widens for 8 seconds |
| Purple | MULTI | Spawns 2 extra balls |
| Blue | SLOW | Halves ball speed for 6 seconds |

## Notes

- Bricks in the top two rows start with 3 HP; next two rows have 2 HP.
- Combo counter resets each time the ball touches the paddle.
- Ball speed increases each level; levels cap brick rows at 8.
