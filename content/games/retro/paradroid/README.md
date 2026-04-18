# Paradroid

**Category:** retro
**Engine:** Lurek2D

A top-down droid shooter inspired by Andrew Braybrook's 1985 C-64 masterpiece. Navigate a space station as the weakest droid (001) and take over stronger enemies using the iconic transfer mini-game.

## How to Play

- **Arrow keys** — Move droid
- **Space** — Fire weapon in facing direction
- **E** — Initiate transfer when near an enemy droid
- **Escape** — Quit

## Mechanics

### Droid Classes
- **100s** — Maintenance droids (1 HP, minimal threat)
- **200s** — Security droids (2 HP, moderate firepower)
- **500s** — Combat droids (3 HP, heavy weapons)
- **900s** — Command droids (5 HP, devastating firepower)

### Transfer Mechanic
Get close to an enemy droid and press **E** to enter the transfer mini-game. Two progress bars race across the screen — press **WASD** rapidly to boost your bar. Win the transfer to take control of the enemy droid, gaining its HP, firepower, and class number. Lose and your current droid is destroyed.

### Energy Management
Every droid has energy that slowly drains over time. Higher-class droids drain faster. When energy runs low, you must transfer to a new droid or face destruction. Strategic transfers are the key to survival.

### Levels
Four increasingly difficult levels with more droids and higher-class enemies. Clear all droids (destroy or transfer) to advance.

## Run

```bash
cargo run -- content/games/retro/paradroid
```

## Screenshot

*(not yet captured)*
