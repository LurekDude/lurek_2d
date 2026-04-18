# Idle Game

**Category:** Simulation
**Engine:** Lurek2D

## Description

A complete idle/clicker game where you click your way to riches. Start by manually clicking for gold, then invest in automated producers that generate gold over time. Purchase upgrades to boost click power, unlock achievements, and prestige for permanent multipliers.

## Features

- **Manual clicking** — press Space to earn gold with satisfying particle effects
- **5 auto-clicker tiers** — Cursor, Worker, Factory, Robot, AI with escalating costs and production
- **Click power upgrades** — Better Click and Super Click boost manual earnings
- **Prestige system** — reset progress at 1M gold for permanent 2x production multipliers
- **Achievements** — unlock badges for milestones like first click, gold thresholds, and production rates
- **Visual polish** — coin burst particles, button pulse tweens, smooth gold counter animation
- **Stats tracking** — total gold earned, total clicks, gold/second, prestige level

## Controls

| Key    | Action                       |
| ------ | ---------------------------- |
| Space  | Click for gold               |
| C      | Buy Cursor (+0.1/s)          |
| W      | Buy Worker (+1/s)            |
| F      | Buy Factory (+10/s)          |
| R      | Buy Robot (+100/s)           |
| A      | Buy AI (+1000/s)             |
| B      | Buy Better Click (+1/click)  |
| S      | Buy Super Click (+10/click)  |
| P      | Prestige (requires 1M+ gold) |
| Escape | Quit                         |

## How to Run

```bash
cargo run -- content/games/simulation/idle_game
```
