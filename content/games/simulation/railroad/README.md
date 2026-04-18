# Railroad

**Category:** Simulation
**Engine:** Lurek2D

## Description

A top-down railroad management game. Build tracks, place stations in towns, buy trains, and deliver goods to earn gold. Connect all four towns and reach 1000 gold to win.

## How to Play

- **Left Click** — Place rail track on a tile (5 gold)
- **S + Click** — Build a station on a town (50 gold)
- **T** — Buy a train and assign it a route between two stations (100 gold)
- **G + Click** — Place a signal on a track tile (10 gold)
- **1 / 2 / 3** — Set game speed
- **Escape** — Quit

## Mechanics

- 25×18 grid map with grass, water, mountain, and town terrain
- 4 towns that produce and consume goods (Coal, Wood, Iron)
- Trains travel at 64 px/s along track tiles, picking up and delivering goods
- Each successful delivery earns 10 gold
- Up to 5 trains can run simultaneously
- Signals prevent train collisions on shared track

## Goal

Connect all 4 towns with rail and stations, and earn 1000 gold.

## Run

```bash
cargo run -- content/games/simulation/railroad
```
