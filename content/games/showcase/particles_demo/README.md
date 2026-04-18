# Particles Demo

**Category:** showcase

Interactive particle systems showcase with 8 presets demonstrating the `lurek.particle` API. Each preset highlights a different visual effect: fire, water, smoke, magic, explosions, snow, fireflies, and confetti. Emitter follows the mouse with real-time toggle controls.

## Run

```
cargo run -- content/games/showcase/particles_demo
```

## Controls

| Key    | Action                       |
| ------ | ---------------------------- |
| 1–8    | Switch particle preset       |
| Space  | Burst emit 50 particles      |
| C      | Toggle continuous emission   |
| G      | Toggle gravity on/off        |
| R      | Toggle rainbow color cycling |
| W      | Toggle horizontal wind       |
| Mouse  | Move particle emitter        |
| Escape | Quit                         |

## Presets

1. **Fire** — Orange/red/yellow flames rising upward with flicker.
2. **Water Splash** — Blue/cyan droplets arcing up then falling.
3. **Smoke** — Gray expanding circles with slow rise and alpha decay.
4. **Magic Sparkle** — Purple/pink/white particles orbiting in all directions.
5. **Explosion** — Fast burst in all directions with red→orange→yellow gradient.
6. **Snow** — White circles drifting gently downward from the top.
7. **Fireflies** — Yellow/green dots with pulsing alpha and random wander.
8. **Confetti** — Multi-colored particles falling with spin.
