# Tetris

_Rotate and stack falling tetrominoes — classic arcade puzzle with hold piece, ghost preview, and line-clear particles._

## Run

```powershell
cargo run -- content/games/arcade/tetris
```

## Controls

| Input        | Action              |
| ------------ | ------------------- |
| A / ←        | Move left           |
| D / →        | Move right          |
| W / ↑        | Rotate (clockwise)  |
| S / ↓ (hold) | Soft drop           |
| Space        | Hard drop           |
| C            | Hold / swap piece   |
| R            | Restart (game over) |
| Escape       | Quit                |

## Gameplay

Stack falling tetrominoes on a 10×20 board. Complete horizontal lines to clear them and score points — 1/2/3/4 lines award 100/300/500/800 points multiplied by your current level. Every 10 lines cleared advances the level and increases drop speed. Use the Hold slot (C key) to save a piece for later — you get one swap per piece drop.

## APIs Used

**`lurek.*` engine bindings**

- `lurek.window` — sets the window title.
- `lurek.render` — draws the board, pieces, ghost preview, sidebar, and overlays.
- `lurek.input` — action-bound keyboard controls (left, right, rotate, soft/hard drop, hold).
- `lurek.tween` — screen flash and shake on line clears.
- `lurek.particles` — sparkle burst along cleared rows.
- `lurek.time` — FPS counter and elapsed time for shake animation.
- `lurek.signal` — clean shutdown on Escape.

**Lunasome (`content/library/`) modules**

_None._

## Changes from Original Demo

### Replaced

- Raw `lurek.input.isKeyDown("down")` polling → `lurek.input.bind()` + `isActionDown("soft_drop")`.
- `lurek.keypressed` callback for movement/rotation → `wasActionPressed` in `lurek.process(dt)`.
- All drawing in single `lurek.render()` → split into `lurek.render()` (board) and `lurek.render_ui()` (HUD/overlays).
- `lurek.signal.restart()` on R → full `reset_game()` with state machine transition.

### Added

- **Hold piece** — press C to swap the current piece with a hold slot (once per drop).
- **Scene states** — TITLE → PLAYING → GAME_OVER with proper transitions and title screen.
- **Particle effects** — sparkle burst along each cleared row via `lurek.particles.newSystem`.
- **Screen shake & flash** — tween-driven white flash and shake offset on line clears.
- **FPS counter** — bottom-left via `lurek.time.getFPS()`.
- **Ghost piece border** — ghost preview now drawn at 25% alpha for clearer drop targeting.
- **Title screen** — blinking "PRESS ENTER TO START" with controls preview.
- **Game over stats** — score, level, and lines displayed on the game-over screen.

### Removed

- Direct `lurek.signal.restart()` call — replaced by internal `reset_game()` for cleaner state management.
- Duplicate next-piece rendering code (consolidated into `draw_piece_preview` helper).

### Open questions

_None._

## Screenshot

![Tetris screenshot](screen.png)
