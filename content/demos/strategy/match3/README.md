# Match-3 Puzzle

A classic match-three gem-swapping puzzle on an 8×8 grid. Click two adjacent gems to swap them; matches of three or more are cleared, gems fall to fill gaps, and cascade combos multiply your score. Matching four in a row creates a bomb gem that clears a 3×3 area; five in a row creates a wiper gem that removes every gem of the same colour.

## What It Demonstrates

- `lurek.gfx.rectangle()` — drawing the grid cells, UI panels, and gem backgrounds
- `lurek.gfx.circle()` — rendering circular gem shapes with highlight rings
- `lurek.gfx.print()` — score, combo counter, and move display
- `lurek.mousepressed()` — selecting and swapping adjacent gems
- `lurek.gfx.setColor()` — six distinct gem colours plus special-gem overlays
- `lurek.time.getTime()` — swap and fall animation timing

## How to Run

```powershell
cargo run -- content/demos/match3
```

## Controls

| Input | Action |
|-------|--------|
| Left-click gem | Select first gem |
| Left-click adjacent gem | Swap and trigger match check |
| R | Reset board |
| Escape | Quit |

## Notes

- The initial board is generated with a rejection loop that prevents horizontal or vertical three-in-a-row from forming at spawn time.
- `find_matches()` runs two separate linear sweeps (horizontal and vertical) and tags matched cells in a boolean grid, enabling clean diagonal-free detection.
- `apply_specials()` expands the matched set after detection — bomb gems add a 3×3 neighbourhood, wipers add all cells of the same colour.
- Cascade combos are tracked with a `combo` counter that resets only when no matches are found after a fall, rewarding chain reactions with a multiplier.
