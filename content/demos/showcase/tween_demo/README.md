# Tween Demo

Demonstrates `lurek.math.newTween()` with multiple easing curves. Rectangles animate across the screen each with a different interpolation style.

## What It Demonstrates

- `lurek.math.newTween()` — create a tween instance
- Tween easing types: `linear`, `ease_in`, `ease_out`, `ease_in_out`, `bounce`, `elastic`, `back`
- `tween:update(dt)` — advancing a tween each frame
- `tween:isFinished()` — detecting tween completion
- Looping and reversed playback
- Visual comparison of easing curves side by side

## How to Run

```powershell
cargo run -- content/demos/tween_demo
```

## Controls

| Key | Action |
|-----|--------|
| R | Reset all tweens to start |
| Space | Pause / resume all tweens |

## Notes

- Each row corresponds to one easing function
- Uses `conf.lua` to set 900×600 window for wider view
