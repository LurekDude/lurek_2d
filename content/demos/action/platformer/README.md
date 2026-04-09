# Platformer Demo

A side-scrolling platformer with physics-based movement, jump mechanics, platform collision, and easing-based animations. A complete mini-game loop.

## What It Demonstrates

- `lurek.physics` — character controller using rigid bodies
- `lurek.keyboard.isDown()` — real-time movement and jump input
- `lurek.math.lerp()` / easing functions for camera smoothing
- `lurek.scene` — integrating the engine scene system
- `lurek.gfx.rectangle()` for world geometry rendering
- Simple camera follow with offset easing
- Game-over detection and restart flow

## How to Run

```powershell
cargo run -- content/demos/platformer
```

## Controls

| Key | Action |
|-----|--------|
| Arrow Left / A | Move left |
| Arrow Right / D | Move right |
| Space / Arrow Up / W | Jump |
| R | Restart |

## Notes

- The character uses a physics rect body — coyote time is not implemented
- Platforms are static rect bodies
- Good starting point for a full platformer project
