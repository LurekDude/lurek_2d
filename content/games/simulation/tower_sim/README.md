# Tower Sim

**Category:** simulation
**Engine:** Lurek2D

## Description

A SimTower-style vertical building simulation. Construct floors, place rooms (offices, apartments, shops, restaurants, gyms), manage elevators, and keep tenants satisfied. Collect rent every 15 seconds and grow your tower to 8+ floors with 2000 gold to win.

## Controls

| Key       | Action                 |
| --------- | ---------------------- |
| F + Click | Add new floor above    |
| O         | Place office (50g)     |
| A         | Place apartment (40g)  |
| S         | Place shop (60g)       |
| R         | Place restaurant (80g) |
| G         | Place gym (70g)        |
| E         | Buy elevator (100g)    |
| Mouse1    | Place selected room    |
| Escape    | Quit                   |

## Features

- Side-view tower that grows upward (max 10 floors)
- 5 room types with unique income and satisfaction effects
- Elevator system with capacity limits and visible queues
- Tenant satisfaction system influenced by amenities
- Revenue cycle every 15 seconds
- Construction particles, revenue sparkles, elevator glow effects
- Tweened build animations, gold counter, satisfaction bars
- Title screen → Playing → Victory states

## Running

```bash
cargo run -- content/games/simulation/tower_sim
```
