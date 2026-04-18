# Sniper

A ballistics puzzle sniper game built with Lurek2D.

## Description

Line up your shots through a swaying scope, compensate for wind and bullet drop, and hit targets at increasing distances across three rounds of escalating difficulty. Hold your breath to steady the crosshair — but only for a few seconds.

## Features

- **Scope sway** — crosshair drifts in a sinusoidal pattern; hold Shift to steady aim
- **Ballistics simulation** — bullet drop (gravity) and wind deflection affect every shot
- **3 rounds** — stationary close-range targets → wind at medium range → strong shifting wind with moving targets
- **Scoring** — bullseye (100), inner ring (70), outer ring (40), miss (0); final rating based on total

## Controls

| Key               | Action                          |
| ----------------- | ------------------------------- |
| WASD / Arrow keys | Move crosshair                  |
| Space             | Fire                            |
| Shift             | Hold breath (steady scope, 3 s) |
| Escape            | Quit                            |

## Running

```bash
cargo run -- content/games/action/sniper
```

## Category

Action
