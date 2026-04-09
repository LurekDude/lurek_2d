# Drift Racing

A top-down arcade racing game on a procedurally generated oval track. Compete against three AI drivers across three laps, using boost zones for bursts of speed and exploiting the car's drift physics to carry momentum through corners.

## What It Demonstrates

- `luna.gfx.polygon()` — tessellated track outer edge and car body rendering
- `luna.gfx.rectangle()` — boost zone highlight and HUD panels
- `luna.gfx.setColor()` — per-car colour differentiation and skid-mark fade
- `luna.gfx.print()` — lap counter, race time, best lap, and position HUD
- `luna.keyboard.isDown()` — analogue-style throttle, brake, and steering input each frame
- `luna.gfx.line()` — skid mark trail drawn as point history
- `luna.gfx.circle()` — checkpoint and boost zone radius indicators
- `luna.gfx.setBackgroundColor()` — dark asphalt track background

## How to Run

```powershell
cargo run -- demos/drift_racing
```

## Controls

| Input | Action |
|-------|--------|
| W | Accelerate |
| S | Brake / reverse |
| A | Steer left |
| D | Steer right |
| Escape | Quit |

## Notes

- Drift is simulated by lerping the car's velocity toward the forward direction; a lower grip factor during hard steering at speed produces the characteristic slide.
- Skid marks are stored as a capped list of 500 points and fade over 3 seconds.
- Boost zones grant a 1.5-second speed cap increase from 250 to 400 units/s; they deactivate after use.
- AI cars follow the nearest track waypoint using a simple closest-index pursuit algorithm.
