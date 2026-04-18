# Hotel Manager

**Category:** Simulation
**Engine:** Lurek2D

## Description

A side-view hotel management simulation where you build rooms, hire staff, and grow your hotel empire from a small three-room inn to a five-star luxury resort.

## How to Play

- **Build rooms**: Click an empty slot, then press **1** (Standard), **2** (Deluxe), or **3** (Suite)
- **Clean rooms**: Press **C** then click a dirty room (costs 5 gold)
- **Upgrade rooms**: Press **U** then click a room to upgrade its tier
- **Hire staff**: Press **H** to hire an auto-cleaner (20 gold each)
- **Goal**: Reach a 5-star rating with 1000 gold

## Room Types

| Type     | Color | Cost | Income/Night |
| -------- | ----- | ---- | ------------ |
| Standard | Green | 50g  | 10g          |
| Deluxe   | Blue  | 100g | 20g          |
| Suite    | Gold  | 200g | 40g          |

## Features

- 8-floor hotel with 5 rooms per floor
- Guest satisfaction and star rating system
- Staff hiring and automated cleaning
- Room upgrades and elevator construction
- Particle effects for arrivals, cleaning, and upgrades
- Tweened animations for guests and UI elements

## Running

```bash
cargo run -- content/games/simulation/hotel_manager
```
