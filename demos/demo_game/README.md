# Demo Game — Shooting Gallery

A complete mini-game: physics-based shooting gallery where you aim with the mouse, fire balls at targets, and score points. Demonstrates how multiple Luna2D systems integrate in a playable loop.

## What It Demonstrates

- `luna.physics` — cannon ball projectiles, target rect bodies, raycasting for aiming
- `luna.physics.getCollisionEvents()` — detecting ball-target hits
- `luna.mouse.getPosition()` — aim direction from cursor
- `luna.mousepressed` callback — fire on click
- `luna.graphics` — rendering cannon, trajectory line, targets, score
- `luna.timer.getTime()` — countdown timer
- Score and combo system with on-screen feedback

## How to Run

```powershell
cargo run -- examples/demo_game
```

## Controls

| Input | Action |
|-------|--------|
| Mouse move | Aim cannon |
| Left click | Fire a ball |
| R | Reset game |

## Notes

- Maximum 10 balls on screen at once — oldest ball is removed on overflow
- Targets respawn after a short delay
- Good reference for integrating input, physics, and scoring in one game loop
