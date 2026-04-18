# Tennis Classic

Complete top-down tennis game with serve/return mechanics, topspin/slice, AI opponent, and full tennis scoring (games, sets, match).

## Run

```
cargo run -- content/games/sports/tennis_classic
```

## Controls

| Key                   | Action                |
| --------------------- | --------------------- |
| W / A / S / D         | Move player           |
| Space                 | Serve toss / hit ball |
| A / D (while hitting) | Aim left / right      |
| W (while hitting)     | Topspin shot          |
| S (while hitting)     | Slice shot            |
| Escape                | Quit                  |

## What It Demonstrates

- Top-down court rendering with white line markings (singles court)
- Serve mechanics: toss + hit, service box targeting, fault/double-fault
- Shot types: topspin (fast dip), slice (slow float), power (hold Space)
- Full tennis scoring: 0/15/30/40, deuce, advantage, games, sets (tiebreak at 6-6), best-of-3 match
- AI opponent with reaction delay that scales per set
- `lurek.input.bind()` — action-based input for move/hit/quit
- `lurek.particles.newSystem()` — ball impact dust, ace flash, net shake
- `lurek.tween.to()` — score popup, serve toss arc, ball speed trail
- `lurek.camera.new()` — camera for court view
- `lurek.time.getFPS()` / `lurek.time.getDelta()` — frame-rate display and delta timing
- `lurek.window.setTitle()` — dynamic window title with score
- `lurek.render.setBackgroundColor()` — grass-green background
- `lurek.signal.quit()` — clean exit on Escape
- Render/render_ui split — court/players/ball in `render()`, score/HUD in `render_ui()`
- TITLE → SERVING → PLAYING → POINT → SET_END → MATCH_END state machine

## Gameplay

Move your player (blue) on the bottom half of the court with WASD. Press Space to serve: first press tosses the ball, second press hits it into the diagonal service box. During rallies, press Space when the ball is near to return it. Hold Space longer for a power shot, press W while hitting for topspin, or S for slice. The AI opponent (red) tracks the ball with increasing skill each set. Rally counter tracks consecutive hits. Win games (0-15-30-40), sets (first to 6, tiebreak at 6-6), and the match (best of 3 sets).
