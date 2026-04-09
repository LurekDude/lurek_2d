# Bullet Hell Demo

A top-down shoot-em-up where the player dodges dense enemy bullet patterns across escalating waves. Enemies fire aimed shots, circular spreads, and spiral patterns.

## What It Demonstrates

- Entity pool pattern: `bullets`, `enemyBullets`, `enemies`, `particles` tables cleaned up each frame
- Wave-based spawning using a `waveTimer` accumulator
- Multiple enemy firing patterns: `aimed` (atan2 toward player), `spread` (circular fan), `spiral` (rotating angle)
- Circular collision detection between player/bullets and enemies/player
- `lurek.keyboard.isDown()` — 8-way movement with delta-time speed scaling
- Particle burst system reused for both player shots and enemy deaths
- Score multiplier and lives system

## How to Run

```powershell
cargo run -- content/demos/bullet_hell
```

## Controls

| Key | Action |
|-----|--------|
| Arrow keys | Move |
| Space | Shoot |
| R | Restart after game over |
| Escape | Quit |

## Notes

- Player hitbox is intentionally smaller than the sprite for fairness.
- Enemy patterns escalate each wave: wave 1 = aimed only, later waves add spread and spiral.
