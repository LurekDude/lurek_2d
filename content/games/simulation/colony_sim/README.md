# Colony Sim

**Category:** simulation
**Engine:** Lurek2D

## Description

A colony management simulation where you build a settlement, assign colonist jobs, gather resources, and defend against raiders. Place buildings, manage food and materials, and grow your colony to 20 colonists to win.

## How to Play

- **Click** a colonist to select, then press **B/F/M/G** to assign a job (Builder/Farmer/Miner/Guard)
- **H** — Place House (10 wood, +2 max colonists)
- **A** — Place Farm (5 wood, produces 2 food/cycle)
- **N** — Place Mine (5 wood + 5 stone, produces 3 stone/cycle)
- **K** — Place Barracks (15 wood + 10 stone, +1 guard capacity)
- **1/2/3** — Set game speed (1×/2×/4×)
- **Escape** — Quit

## Features

- 25×18 tile grid map with grass, water, rock, and forest terrain
- 5 starting colonists with assignable jobs
- Resource production cycles every 10 seconds
- Food consumption and starvation mechanics
- Raider attacks every 60 seconds — assign guards to defend
- Win condition: reach 20 colonists
- Particle effects for construction, gathering, and raid warnings
- Tweened resource bars and colonist arrival animations

## Running

```
cargo run -- content/games/simulation/colony_sim
```
