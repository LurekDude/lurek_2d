# God Game

**Category:** Simulation
**Engine:** Lurek2D

## Description

A Populous-style god game where you shape terrain, guide villagers, perform divine miracles, and defend against a rival faction. Raise and lower land, grow forests with rain, smite enemies with lightning, and lead your people to prosperity.

## How to Play

- **Left Click + Hold**: Raise terrain under cursor
- **Right Click + Hold**: Lower terrain under cursor
- **R**: Rain miracle — grows grass to forest, boosts food (10 faith)
- **E**: Earthquake — lowers terrain in 5×5 area around cursor (20 faith)
- **L**: Lightning — strikes location, clears forest to grass (15 faith)
- **B**: Blessing — selected village gains +3 population (5 faith)
- **W**: Place wall to block rival expansion (5 faith)
- **1/2/3**: Set game speed
- **Escape**: Quit

## Objectives

- **Win**: Reach 50 population
- **Lose**: Population reaches 0

## Features

- Top-down 30×22 tile grid with five terrain types
- Terrain sculpting with smooth color transitions
- Autonomous villager AI with pathfinding preferences
- Rival faction with auto-expansion and territory competition
- Four divine miracles with particle effects
- Faith system tied to villager count
- Housing and population growth mechanics
- Camera controls and HUD overlay

## Running

```bash
cargo run -- content/games/simulation/god_game
```
