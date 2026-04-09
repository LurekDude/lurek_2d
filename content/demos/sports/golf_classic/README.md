# Golf Classic

A full 9-hole top-down golf game with wind, hazards, and realistic ball physics.
Aim with A/D, build power with the oscillating bar, and release at the right moment.

## What It Demonstrates

- `lurek.keypressed()` — aim adjustment and shot release
- Oscillating power bar mechanic
- Rolling physics with wind drift and friction
- Obstacle types: trees (bounce), water (penalty), bunkers (slow)
- Full stroke-play golf scoring (eagle/birdie/par/bogey) with 9-hole totals

## Controls

| Phase | Key | Action |
|-------|-----|--------|
| Aim | A / D or Left / Right | Rotate aim direction |
| Aim | Space | Start power bar swing |
| Swing | Space | Release — shoots at current power |
| Holed | Space | Advance to next hole |
| Any | R | Restart round |
| Any | Escape | Quit |

## Holes

9 unique holes with increasing difficulty. Each has par 3–5, wind affecting every
shot, and a mix of water, bunker, and tree obstacles. Score displayed as over/under
par (E = even, +2 = double bogey, -1 = birdie).
