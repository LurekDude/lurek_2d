# Boulder Dash

**Category:** Retro
**Engine:** Lurek2D

A classic cave exploration game inspired by the 1984 original. Dig through earth, collect diamonds, avoid falling boulders, and reach the exit before time runs out.

## How to Play

- **Arrow keys** — Move player (dig through earth automatically)
- **Escape** — Quit

## Features

- Grid-based cave system (40×26 cells) with procedurally generated layouts
- Boulder physics: gravity, cascading falls, sliding off rounded surfaces
- Falling boulders and diamonds crush anything beneath them
- Collect the required number of diamonds to open the exit
- 3 progressively harder levels with increasing diamond requirements
- Countdown timer per level — reach the exit before time expires
- 3 lives — falling boulders kill you, running out of time costs a life
- Particle effects for digging, collecting, boulder impacts, and death
- Tween animations on diamond counter and level transitions

## Running

```bash
cargo run -- content/games/retro/boulder_dash
```
