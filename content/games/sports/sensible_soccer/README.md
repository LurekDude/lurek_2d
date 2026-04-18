# Sensible Soccer

Arcade top-down football inspired by Sensible Soccer (Amiga 1997). 5-a-side with aftertouch shooting, CPU opponents, and a 90-second match clock.

## What It Demonstrates

- `lurek.input.bind()` / `lurek.input.isActionDown()` — action-mapped keyboard input
- `lurek.input.wasActionPressed()` — discrete kick event
- `lurek.gfx.circle()` / `lurek.gfx.rectangle()` / `lurek.gfx.line()` — pitch and player rendering
- `lurek.gfx.print()` — score HUD and match clock
- `lurek.gfx.setColor()` — team colour coding
- `lurek.signal.quit()` — clean exit

## How to Run

```bash
cargo run -- content/games/sports/sensible_soccer
```

## Controls

| Key | Action |
|-----|--------|
| W / A / S / D | Move controlled player |
| Space | Kick / shoot (with aftertouch) |
| Escape | Quit |

## Notes

- The yellow-ringed player is auto-selected as the one nearest the ball.
- Aftertouch: lateral velocity of the kicker adds a slight curve to shots.
- CPU team uses a simple nearest-attacker + support-position AI.
- Match length is 90 seconds (fast mode); final score screen shown at full time.
