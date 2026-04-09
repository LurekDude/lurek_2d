# Trajectory Sports (Golf / Artillery)

A three-hole golf/artillery challenge on procedurally generated sine-wave terrain. Aim with the mouse, hold Space to charge your shot power (0–100%), and release to fire. Wind shifts between holes and adds a lateral force to trajectories; shots must reach the hole flag buried in the terrain.

## What It Demonstrates

- Procedural terrain: `terrain_pts` array built from multi-frequency `sin` + `cos` sums, sampled via `terrain_y_at(x)` linear interpolation for per-frame collision
- Projectile physics integrating velocity with gravity + lateral wind force each frame
- Shot charging: `Space` held accumulates `charge` (0–1); release fires with `charge * MAX_SPEED`
- Terrain-normal bounce: surface normal computed from adjacent terrain points to reflect the ball on impact
- Three-hole progression with per-hole increasing wind magnitude
- Shot trail rendered as a polyline of `trail` position samples
- `lurek.mouse.getPosition()` used to aim the launch direction vector

## How to Run

```powershell
cargo run -- content/demos/trajectory_sports
```

## Controls

| Key / Input | Action |
|-------------|--------|
| Move mouse | Aim launch direction |
| Hold `Space` | Charge shot power |
| Release `Space` | Fire |
| `R` | Reset current hole |

## Notes

- The power bar in the HUD fills as you hold `Space`; release early for chip shots.
- Wind direction and strength reset each hole — check the wind indicator before aiming.
- The ball bounces with friction on the terrain; you can use slopes to redirect shots.
