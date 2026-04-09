# Tetris

The classic falling-block puzzle game. Rotate and place tetrominoes to
clear horizontal lines and rack up points.

## What It Demonstrates

- `lurek.gfx.rectangle()` — board grid, tetromino cells, ghost preview
- `lurek.keypressed()` — rotation with wall-kick, hard drop
- `lurek.input.isKeyDown()` — soft drop for continuous downward pressure
- `lurek.gfx.print()` — score, level, and lines counter sidebar

## Controls

| Key | Action |
|-----|--------|
| Left / Right Arrows | Move piece horizontally |
| Up Arrow | Rotate clockwise (with wall-kick) |
| Down Arrow | Soft drop (accelerate fall) |
| Space | Hard drop (instant placement) |
| R | Restart after game over |
| Escape | Quit |

## Notes

Ghost piece shows the projected landing position. Clearing multiple lines at once
scores a multiplier (Tetris = 4 lines for maximum points). Speed increases each 10 lines.
