# Pong

Classic two-player paddle game — the one that started the video game industry.
First player to reach 7 points wins.

## What It Demonstrates

- `lurek.gfx.rectangle()` — drawing paddles, ball, and score dividers
- `lurek.input.isKeyDown()` — real-time two-player simultaneous input
- `lurek.gfx.print()` — scoreboard display
- `lurek.signal.quit()` — clean exit

## Controls

| Key | Action |
|-----|--------|
| W | Player 1 paddle up |
| S | Player 1 paddle down |
| Up Arrow | Player 2 paddle up |
| Down Arrow | Player 2 paddle down |
| R | Restart after game over |
| Escape | Quit |

## Notes

Ball accelerates slightly on each paddle hit, adding tension as rallies progress.
The deflection angle changes based on where the ball hits the paddle.
