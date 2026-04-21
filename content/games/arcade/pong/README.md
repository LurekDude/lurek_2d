# Pong

Classic two-player paddle game. First to 7 wins.

## Run
```
cargo run -- content/games/arcade/pong
```

## Controls
| Key       | Action                  |
| --------- | ----------------------- |
| W / S     | Player 1 up/down        |
| Up / Down | Player 2 up/down        |
| Enter     | Start game              |
| R         | Restart after game over |
| Escape    | Quit                    |

## Gameplay
Two paddles, one ball. Ball speeds up on each hit. Angle varies based on where the ball hits the paddle.

## APIs Used
lurek.window, lurek.render, lurek.input, lurek.event, lurek.timer, lurek.particle, lurek.tween

## Changes from Original Demo
### Replaced
- Raw `lurek.input.isKeyDown("w")` → action-based `lurek.input.isActionDown("p1_up")`

### Added
- Title screen with state machine (TITLE → PLAYING → GAME_OVER)
- Particle sparks on paddle collisions
- Tween-based score pop animation
- Separate render/render_ui split
- FPS counter

### Removed
- Nothing — all original gameplay preserved
