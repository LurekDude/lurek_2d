# Tactical Battle

A chess-inspired turn-based strategy game on an 8 × 8 grid. Click a unit to select it, then click a highlighted blue tile to move it or a red enemy to attack. Three unit types (warrior, archer, mage) each have different movement ranges, attack damage, and attack range. An AI opponent takes its turn after you press Enter.

## What It Demonstrates

- BFS reachable-tile calculation bounded by `unit.move` range, respecting friendly-occupied cells
- Attack range check: distinct `unit.range` for melee (1) vs ranged (2/3) units
- Turn phases: `"select"` → `"move"` → `"attack"` → `"enemy_turn"` cycle driven by `Enter` and mouse clicks
- AI turn: enemy units iterate through targets in range and attack or move toward the nearest player unit
- Unit type table: warrior / archer / mage defined as data, not separate code paths
- Tile highlight rendering: blue for reachable tiles, red for attackable enemies from current position
- Grid-to-screen coordinate mapping with `OX` and `OY` offsets

## How to Run

```powershell
cargo run -- content/demos/tactical_battle
```

## Controls

| Key / Input | Action |
|-------------|--------|
| Left Click friendly unit | Select unit |
| Left Click blue tile | Move selected unit |
| Left Click red enemy | Attack with selected unit |
| `Enter` | End your turn |
| `Escape` | Quit |

## Notes

- Archers (range 2) can attack diagonally adjacent tiles; mages (range 3) can fire across most of the board.
- Attacking ends the unit's action for that turn even if it has unused movement.
- The enemy AI acts on a small delay so you can see each of its moves clearly.
