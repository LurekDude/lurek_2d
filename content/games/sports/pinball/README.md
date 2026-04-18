# Pinball

**Category:** Sports  
**Complexity:** Advanced  
**Engine features:** Physics, Particles, Tween, Input Bindings, Camera, State Machine

## Description

A classic vertical pinball table with flippers, bumpers, targets, ramps, and a spring plunger. Charge the plunger with Space, flip with A/D, and rack up points through bumper combos and target completions. Features a score multiplier system, extra ball rewards, and tilt nudge.

## How to Play

| Key          | Action                            |
| ------------ | --------------------------------- |
| Space (hold) | Charge plunger, release to launch |
| A / Left     | Left flipper                      |
| D / Right    | Right flipper                     |
| T            | Tilt / nudge table                |
| Escape       | Quit                              |

## Running

```bash
cargo run -- content/games/sports/pinball
```

## Features

- Spring-loaded plunger with charge meter
- Two flippers with smooth rotation via tween
- 3 bumpers with hit flash and combo multiplier (2x→3x→4x)
- 5 targets — clear all for 500pt bonus
- 2 ramps for 200pt each
- 3 balls per game, extra ball at 5000pts
- Particle effects on bumper hits, target clears, drain, and plunge
- High score tracking across rounds
