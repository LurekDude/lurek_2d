# Devtools Demo

Demonstrates `luna.devtools`: runtime diagnostics including a performance profiler, memory tracker, variable watcher, and log viewer.

## What It Demonstrates

- `luna.devtools.start()` — activate the diagnostics overlay
- `luna.devtools.profile()` — begin / end named profiling regions
- `luna.devtools.watch()` — register variables for live display
- `luna.devtools.log()` — send messages to the devtools log viewer
- `luna.devtools.getFrameStats()` — frame time, draw calls, physics steps
- Overlay rendering: toggling the HUD with a keypress

## How to Run

```powershell
cargo run -- examples/devtools_demo
```

## Controls

| Key | Action |
|-----|--------|
| F1 | Toggle devtools overlay |
| F2 | Cycle overlay panels (profile / memory / log) |

## Notes

- The overlay has zero overhead when closed
- Profiling regions nest — each region tracks its own min/max/avg frame time
- Not intended for production builds
