# Particles Demo

A showcase of the Luna2D particle system featuring six hand-crafted presets covering every available particle shape (square, spark, circle, point). Cycle through fire, explosion, snow, galaxy, magic, and fountain effects, toggle gravity, and trigger burst emissions to explore the full range of `luna.particles` parameters.

## What It Demonstrates

- `luna.particles.newSystem()` with a full parameter table: `maxParticles`, `emissionRate`, `lifetimeMin/Max`, `speedMin/Max`, `direction`, `spread`, `gravityX/Y`, `spinMin/Max`, `turbulence`, `sizes`, `colors`
- All four particle shapes: `"square"` (fire), `"spark"` (explosion), `"circle"` (snow, magic, fountain), `"point"` (galaxy)
- Colour gradient arrays: each preset defines 4-5 RGBA keyframes that particles interpolate across their lifetime
- Burst emission vs continuous emission: explosion preset uses `emissionRate=0` and fires only on `Space`
- Per-preset gravity toggle: the `G` key reads the stored `on`/`off` state so each preset remembers its gravity setting independently
- Mouse-follow: all systems update their emitter position to `luna.mouse.getPosition()` every frame

## How to Run

```powershell
cargo run -- demos/particles_demo
```

## Controls

| Key | Action |
|-----|--------|
| `1` – `6` | Switch to preset: fire / explosion / snow / galaxy / magic / fountain |
| Arrow Left / Right | Cycle presets |
| `Space` | Burst-fire at mouse position |
| `G` | Toggle gravity on/off for the current preset |
| Move mouse | Move the emitter |

## Notes

- The explosion preset (`2`) has `emissionRate=0` — particles only appear on `Space` bursts.
- Galaxy (`4`) uses point-shaped particles at low emission with wide spread for a constellation effect.
- Window is 900 × 600 to give horizontal room to move the emitter left and right.
