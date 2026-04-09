# Post-FX Demo

Demonstrates Luna2D's post-processing effects stack. Effects are toggled, reordered, and parameter-tuned at runtime using keyboard controls.

## What It Demonstrates

- `luna.postfx.newEffect()` — create a named post-processing effect
- `luna.postfx.newStack()` — compose multiple effects in order
- `stack:addEffect()` / `removeEffect()` — dynamic pipeline editing
- `stack:setEnabled()` — toggle effects without removing them
- `stack:setParam()` — adjust effect parameters at runtime
- `stack:apply()` — apply the full stack to the current frame
- Available effects: vignette, chromatic aberration, blur, scanlines, colour grading

## How to Run

```powershell
cargo run -- demos/postfx_demo
```

## Controls

| Key | Action |
|-----|--------|
| 1–5 | Toggle individual effects |
| Up / Down | Adjust selected effect parameter |
| Left / Right | Select parameter to adjust |
| R | Reset all parameters |

## Notes

- Effects are processed in stack order — order matters for the final look
- Parameters are displayed on-screen for each active effect
