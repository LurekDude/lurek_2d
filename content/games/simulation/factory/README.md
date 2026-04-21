# Factory

Factory automation game inspired by Factorio-lite: place conveyor belts, miners, smelters, and assemblers to build a production line that turns raw ore into products for gold.

## Run

```
cargo run -- content/games/simulation/factory
```

## Controls

| Key              | Action                                                          |
| ---------------- | --------------------------------------------------------------- |
| W / A / S / D    | Set conveyor direction (up/left/down/right) then click to place |
| M                | Select Miner placement (10 gold, place on ore tiles)            |
| S (hold) + click | Select Smelter placement (20 gold)                              |
| A (hold) + click | Select Assembler placement (30 gold)                            |
| D + click        | Delete placed item (no refund)                                  |
| 1 / 2 / 3        | Game speed: 1x / 2x / 4x                                        |
| Left click       | Place selected item                                             |
| Escape           | Quit                                                            |

## Gameplay

Start with 50 gold. Place miners on ore tiles to extract raw materials, route them via conveyor belts to smelters that produce ingots, then to assemblers that turn ingots into products. Products reaching storage auto-sell for 15 gold every 10 seconds. Conveyors cost 1 gold each; machines cost more. Reach 500 gold to win.

### Machines
- **Miner** (M, 10 gold) — produces 1 raw material every 3s from ore tiles
- **Smelter** (S, 20 gold) — converts raw material → ingot in 5s
- **Assembler** (A, 30 gold) — converts 2 ingots → product in 8s

### Items
- Items travel along conveyor belts at 32px/s (one tile per second)
- Auto-enter machines when a conveyor leads into them
- Auto-exit onto the conveyor on the machine output side

### Production Stats
- Items produced per minute, active machines, total conveyors placed

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.particle`, `lurek.tween`, `lurek.timer`, `lurek.event`

## Changes from Original Demo

### Replaced
- Raw key polling → action-based input (`lurek.input.bind` / `isActionDown` / `wasActionPressed`)

### Added
- Title screen with instructions, victory screen at 500 gold
- Particle effects (machine processing sparks, item creation glow, product sold flash)
- Tween animations (item belt movement, gold counter smooth animation)
- `render` / `render_ui` split with HUD overlay (gold, stats, placement mode, FPS)
- Camera support, setTitle, setBackgroundColor
