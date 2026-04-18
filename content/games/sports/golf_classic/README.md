# Golf Classic

**Category:** Sports  
**Complexity:** Advanced  
**Engine features:** Physics, Particles, Tween, Input Bindings, Camera, State Machine

## Description

A complete 9-hole top-down mini golf game. Aim with the mouse, hold Space or mouse button to charge your shot, and release to hit the ball. Each hole features unique terrain including fairways, rough, sand bunkers, water hazards, and walls. Wind varies per hole and affects ball trajectory. Track your strokes against par across all 9 holes and try to finish under par.

## How to Play

| Key                      | Action             |
| ------------------------ | ------------------ |
| Mouse                    | Aim shot direction |
| Space / Mouse1 (hold)    | Charge shot power  |
| Space / Mouse1 (release) | Hit ball           |
| Escape                   | Quit               |

## Running

```bash
cargo run -- content/games/sports/golf_classic
```

## Features

- 9 progressively harder holes with unique layouts
- Terrain types: fairway, rough, sand bunker, water hazard, walls
- Mouse aiming with trajectory preview line
- Power bar with charge-and-release mechanic
- Wind system with per-hole random direction and strength
- Ball physics with friction, wall bouncing, and deceleration
- Stroke counter and par tracking per hole
- Full scorecard at end of round
- Particle effects: ball trail, hole sink, sand spray, water splash
- Tween animations for power bar, transitions, and ball sink
