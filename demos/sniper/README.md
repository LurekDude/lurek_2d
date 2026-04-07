# Sniper / Ballistics Puzzle

A side-view precision shooting game with realistic bullet physics. Wind pushes bullets horizontally, the scope sways continuously, and headshots award a score bonus. Three escalating rounds increase wind speed, target distance, and target count.

## What It Demonstrates

- Bullet physics: position integrated with gravity + lateral wind force each frame, stored as a polyline trail
- Procedural terrain using a multi-frequency sine wave sampled via `terrain_y_at()` for bullet collision
- Scope sway implemented as a circular oscillator (`sin(t * 2.1) + cos(t * 1.7)`) with `Shift` damping
- Headshot detection: separate hit zones for body rectangle and head circle with different score values
- Round configuration table: `{ wind, dist_min, dist_max, target_count }` drives difficulty scaling
- `luna.mouse.getPosition()` mapped from screen space to sniper scope space for aiming

## How to Run

```powershell
cargo run -- demos/sniper
```

## Controls

| Key / Input | Action |
|-------------|--------|
| Move mouse | Aim |
| Left Click | Fire |
| Hold Left Shift | Steady aim (reduces scope sway) |

## Notes

- You have 5 shots per round. Shots remaining are shown in the HUD.
- Wind direction changes between rounds; watch the wind indicator before each shot.
- Aim slightly into the wind to compensate for bullet drift over long distances.
