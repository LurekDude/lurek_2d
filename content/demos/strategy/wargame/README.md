# Wargame

A hex-adjacent grid wargame with three unit types, terrain modifiers, and command points. Each side gets four command points per turn; spending one point lets you move or attack with a single unit. Terrain (open, forest, hill) provides defence and attack bonuses.

## What It Demonstrates

- Hex-adjacent movement on a square grid: units move to any of the eight neighbours within `unit.move` range
- Three unit types defined as data: infantry (hp 4, atk 2, move 3, range 1), cavalry (hp 3, atk 3, move 5, range 1), artillery (hp 2, atk 4, move 2, range 4)
- Command-point economy: 4 points per turn; each unit action (move or attack) costs 1 point
- Terrain effect table: forest `+1 defence`, hill `+1 attack`; applied during combat resolution
- Turn phases: `"select"` → `"move"` → `"attack"` loop gated by `Enter` to end turn
- Combat log: last several exchanges recorded and displayed in a side panel
- AI turn: enemy iterates units, calculates nearest player target, moves into range, and attacks

## How to Run

```powershell
cargo run -- demos/wargame
```

## Controls

| Key / Input | Action |
|-------------|--------|
| Left Click friendly unit | Select unit |
| Left Click highlighted tile | Move selected unit to that tile |
| Left Click enemy in range | Attack with selected unit |
| `Enter` | End your turn |
| `Escape` | Quit |

## Notes

- Artillery has range 4 — position it on a hill tile to maximise both its attack bonus and its reach.
- Cavalry's move-5 range lets it flank across the map in a single turn.
- Command points do not carry over between turns — use all four or lose them.
