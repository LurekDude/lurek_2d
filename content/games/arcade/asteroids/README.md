# Asteroids

_Fly, shoot, and survive the asteroid field — classic arcade action with thrust physics, screen wrapping, and particle explosions._

## Run

```powershell
cargo run -- content/games/arcade/asteroids
```

## Controls

| Input  | Action              |
| ------ | ------------------- |
| A / ←  | Rotate left         |
| D / →  | Rotate right        |
| W / ↑  | Thrust forward      |
| Space  | Fire bullet         |
| R      | Restart (game over) |
| Escape | Quit                |

## Gameplay

Pilot a ship through an asteroid field. Rotate with A/D and thrust with W to accelerate — the ship drifts with momentum and drag. Fire bullets (max 4 on screen) to destroy asteroids: large ones split into 2 medium, medium into 2 small. Score points for each destruction (large 25, medium 50, small 100). You have 3 lives; after a hit the ship respawns in the center with 2 seconds of blinking invincibility. Each cleared wave spawns one additional asteroid. All objects wrap around screen edges.

## APIs Used

**`lurek.*` engine bindings**

- `lurek.window` — sets the window title.
- `lurek.render` — draws ship triangle, asteroid polygon outlines, bullets, score pops, and overlays.
- `lurek.input` — action-bound keyboard controls (rotate, thrust, fire).
- `lurek.tween` — floating score pop fade animation.
- `lurek.particle` — explosion bursts on asteroid destruction and thrust exhaust flame.
- `lurek.timer` — FPS counter and elapsed time.
- `lurek.event` — clean shutdown on Escape.
- `lurek.camera` — camera setup for 800×600 viewport.

**Lunasome (`content/library/`) modules**

_None._

## Changes from Original Demo

This is an original game — no prior demo existed. Built from scratch following the arcade game template patterns established in the `content/games/arcade/` collection.
