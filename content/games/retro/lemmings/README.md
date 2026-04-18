# Lemmings

**Category:** retro
**Engine:** Lurek2D

A puzzle game inspired by DMA Design's 1991 classic. Guide mindless lemmings from the entrance to the exit by assigning them jobs before they walk off cliffs or into hazards.

## Gameplay

- 12 lemmings spawn from a trap-door entrance, 2 seconds apart
- Lemmings walk automatically, turning at walls, falling with gravity
- Assign jobs by hovering the cursor near a lemming and pressing a number key
- Save at least 8 lemmings per level to advance
- Terrain is fully destructible — diggers and bashers carve through it

## Job Types

| Key | Job     | Effect                                       |
| --- | ------- | -------------------------------------------- |
| 1   | Blocker | Stops in place, acts as a wall for others    |
| 2   | Digger  | Digs straight down through terrain           |
| 3   | Builder | Builds a diagonal staircase upward (8 steps) |
| 4   | Basher  | Digs horizontally in the facing direction    |

## Controls

| Input         | Action       |
| ------------- | ------------ |
| Mouse         | Hover cursor |
| 1 / 2 / 3 / 4 | Assign job   |
| Escape        | Quit         |

## Levels

Three levels with increasing difficulty, each with unique terrain layouts and limited job supplies.

## Running

```bash
cargo run -- content/games/retro/lemmings
```
