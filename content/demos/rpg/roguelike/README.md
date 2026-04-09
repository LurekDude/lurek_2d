# Classic Grid Roguelike

A turn-based dungeon crawler with procedural BSP room generation, fog-of-war, bump-to-attack combat, health potions, and permadeath. Each floor is a new dungeon; finding the stairs (`>`) descends to the next level where enemies are tougher.

## What It Demonstrates

- BSP-style room generation: random room rectangles connected by L-shaped corridors
- Fog-of-war using a `VIEW_RADIUS` BFS that marks tiles as revealed but dims previously seen tiles
- Turn-based update: player and enemy moves alternate — enemies only act on player turns
- Bump-to-attack combat: moving into an occupied cell triggers a melee exchange
- Entity lists for enemies and pickups with dead-entity cleanup each turn
- Message log: most recent 5 messages displayed as a scrolling list
- `luna.input.keypressed` callback driving single-step movement

## How to Run

```powershell
cargo run -- demos/roguelike
```

## Controls

| Key | Action |
|-----|--------|
| Arrow keys | Move one tile (also attacks adjacent enemies) |
| `R` | Restart after death |
| `Escape` | Quit |

## Notes

- The map is 30 × 24 tiles at 24 px each; the viewport fits the entire map on screen.
- Enemies scale with floor number — goblins appear on floor 1, orcs on floor 2+, trolls on floor 3+.
- Purple `!` tiles are health potions; walk into them to collect.
