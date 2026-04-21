# Worms Artillery

Turn-based artillery game inspired by Worms (Amiga 1998). Two teams take turns firing bazookas across procedurally generated terrain, with wind drift, blast craters, and HP tracking.

## What It Demonstrates

- `lurek.math.newNoiseGenerator()` — fractal terrain generation using Perlin noise
- `lurek.math.newRandomGenerator()` — seeded RNG for team placement
- `lurek.math.distance()` / `lurek.math.lerp()` — blast radius damage and explosion scaling
- `lurek.particle.newSystem()` — spark burst on explosion
- `lurek.render.circle()` / `lurek.render.rectangle()` / `lurek.render.line()` — worms, terrain, aim indicator
- `lurek.render.print()` — HUD (team name, power, wind, timer)
- `lurek.input.isDown()` — hold keys to adjust aim angle and power
- `lurek.event.quit()` — clean exit

## How to Run

```bash
cargo run -- content/games/strategy/worms_artillery
```

## Controls

| Key | Action |
|-----|--------|
| Left / Right | Rotate aim direction |
| Up / Down | Increase / decrease fire power |
| Space | Fire projectile |
| R | Restart match |
| Escape | Quit |

## Notes

- Terrain is deformable: explosions carve craters using column-height subtraction.
- Wind changes every turn and is shown as a horizontal arrow at the bottom.
- Worms that take lethal blast damage are removed from their team; last team standing wins.
