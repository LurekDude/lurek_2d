# Zoo Tycoon

**Category:** Simulation
**Engine:** Lurek2D

## Description

A top-down zoo management tycoon where you lay paths, build enclosures, buy animals, and keep visitors happy. Balance animal welfare, amenities, and finances to reach a 5-star rating.

## How to Play

- **Build**: Press **1–6** to select a build tool, then click the grid to place
- **Animals**: Press **A** to open the animal shop, then **1–5** to buy
- **Delete**: Press **D** then click to remove a placed tile
- **Goal**: Reach a 5-star zoo rating with 500 gold saved

## Build Tools

| Key | Item         | Cost | Notes                           |
| --- | ------------ | ---- | ------------------------------- |
| 1   | Path         | 5g   | Visitors walk only on paths     |
| 2   | Fence        | 10g  | Encloses animal exhibits        |
| 3   | Water        | 15g  | Required for aquatic animals    |
| 4   | Food Station | 20g  | Feeds animals in a 5×5 area     |
| 5   | Gift Shop    | 50g  | Generates +5g per visitor cycle |
| 6   | Bench        | 10g  | Increases visitor satisfaction  |

## Animals

| Key | Animal   | Cost | Enclosure        | Attraction   |
| --- | -------- | ---- | ---------------- | ------------ |
| 1   | Lion     | 200g | 4×4 fenced grass | +10 visitors |
| 2   | Penguin  | 150g | 3×3 fenced+water | +8 visitors  |
| 3   | Monkey   | 100g | 3×3 fenced grass | +5 visitors  |
| 4   | Bear     | 250g | 5×5 fenced grass | +15 visitors |
| 5   | Elephant | 300g | 6×4 fenced area  | +20 visitors |

## Features

- 20×14 tile grid with terrain types (path, grass, water, fence)
- Animal welfare system: fed → happy, hungry → sad, starving → sick
- Visitor economy with revenue cycles every 15 seconds
- 1–5 star rating based on variety, welfare, paths, and amenities
- Particle effects for visitors, feeding, and construction
- Tweened animations for ratings, gold counter, and animal hops

## Running

```bash
cargo run -- content/games/simulation/zoo_tycoon
```
