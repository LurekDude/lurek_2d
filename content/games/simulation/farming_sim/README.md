# Farming Sim

Grow crops, trade at the market, and earn 200 gold to win. Manage your farm through day/night cycles and weather events.

## Run

```
cargo run -- content/games/simulation/farming_sim
```

## Controls

| Key           | Action                                    |
| ------------- | ----------------------------------------- |
| W / A / S / D | Move between plots                        |
| Space         | Use current tool on plot                  |
| 1             | Equip Hoe (till empty plots)              |
| 2             | Equip Seeds (plant on tilled plots)       |
| 3             | Equip Watering Can (water planted crops)  |
| 4             | Equip Sickle (harvest ready crops)        |
| Q / E / R     | Select seed type: Wheat / Carrot / Tomato |
| M             | Open / close market                       |
| Escape        | Quit (or close market)                    |

## Gameplay

Manage a 12x8 farm grid. Till soil with the hoe, plant seeds, water crops to halve grow time, and harvest when ready. Sell crops at the market for gold and buy more seeds to expand your operation. A day/night cycle controls crop growth (crops only grow during daytime), and random rain events water all your crops automatically.

### Crops

| Crop   | Grow Time          | Sell Price | Seed Cost |
| ------ | ------------------ | ---------- | --------- |
| Wheat  | 15s (7.5s watered) | 5g         | 2g        |
| Carrot | 10s (5s watered)   | 8g         | 3g        |
| Tomato | 20s (10s watered)  | 12g        | 5g        |

### Weather

Each dawn has a 20% chance of rain. Rain waters all planted and growing crops automatically, halving their remaining grow time.

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.particle`, `lurek.tween`, `lurek.timer`, `lurek.event`

## Changes from Original Demo

### Replaced
- Raw key polling → action-based input (`lurek.input.bind` / `wasActionPressed`)

### Added
- Title screen, victory screen, market overlay (4 game states)
- Particle effects (harvest sparkle, rain drops, growth shimmer, planting poof)
- Tween-animated gold counter display
- `render` / `render_ui` split with top HUD bar and bottom inventory bar
- Day/night cycle with visual overlay transition
- Random rain weather system
- Camera setup via `lurek.camera.new`
- FPS counter, `setTitle`, `setBackgroundColor`, `signal.quit`

### Removed
- Nothing
