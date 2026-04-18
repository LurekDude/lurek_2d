# Terminal Demo

Full-screen terminal UI character creation wizard with box-drawing borders, colored text, stat allocation, and multi-page navigation — all rendered on an 80×25 character grid.

## What It Demonstrates

- `lurek.render.drawText()` — monospace terminal grid rendering with colored text
- `lurek.render.drawRect()` — box-drawing borders and progress bars
- `lurek.render.drawLine()` — CRT-style scanline overlay
- `lurek.input.bind()` — action-based navigation (up/down/confirm/back/next_stat/quit)
- `lurek.textinput()` — character-by-character name entry
- `lurek.particles.newSystem()` — page-complete flash and celebration effects
- `lurek.tween.to()` — cursor blink, page transitions, stat bar fill animation
- `lurek.camera.new()` — world-space rendering with camera attach/detach
- `lurek.window.setTitle()` — dynamic window title
- `lurek.render.setBackgroundColor()` — black terminal background
- `lurek.signal.quit()` — escape to exit
- `lurek.time.getFPS()` — FPS counter in HUD

## How to Run

```bash
cargo run -- content/games/showcase/terminal_demo
```

## Controls

| Key       | Action                           |
| --------- | -------------------------------- |
| Up / Down | Navigate selections              |
| Enter     | Confirm selection / advance page |
| Backspace | Go back to previous page         |
| Tab       | Next stat (stat allocation page) |
| +/-       | Adjust stat value                |
| 1–6       | Select color (appearance page)   |
| Escape    | Quit                             |

## Notes

- The 80×25 grid is purely visual — characters are drawn with `drawText` at calculated positions
- Box-drawing uses ASCII `+-|` characters for maximum terminal authenticity
- Stat allocation enforces a 20-point budget with real-time feedback
- All selections persist when navigating between pages
