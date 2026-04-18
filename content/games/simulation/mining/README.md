# Mining

**Category:** Simulation
**Engine:** Lurek2D

## Description

A mining depth exploration game. Dig through layers of earth to find valuable ores and gems, upgrade your equipment at the surface shop, and accumulate 500 gold to win. Watch out for cave-ins deep underground!

## How to Play

| Control        | Action            |
| -------------- | ----------------- |
| W/A/S/D        | Move miner        |
| Space          | Dig adjacent tile |
| S (at surface) | Open shop         |
| L              | Place ladder (5g) |
| Escape         | Quit              |

## Features

- 20×30 tile mine with vertical scrolling
- 5 tile types: dirt, stone, iron ore, gold ore, gem
- Depth-based ore distribution (gems only below depth 20)
- Equipment upgrades: pickaxe, headlamp, cart
- Carrying capacity with surface selling
- Cave-in hazards below depth 15
- Headlamp visibility radius
- Ladder placement for climbing back up
- Particle effects for digging, sparkles, cave-ins
- Tween animations for UI elements

## Running

```bash
cargo run -- content/games/simulation/mining
```
