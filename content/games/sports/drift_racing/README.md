# Drift Racing

**Category:** Sports
**Engine:** Lurek2D

## Description

Top-down drift racing game where sliding is the key to victory. Race against AI opponents across 3 tracks of increasing difficulty, accumulate drift points by sliding through corners at high speed, and use boost pads to gain an edge.

## Features

- Top-down car physics with realistic drift mechanics
- 3 tracks of increasing difficulty with checkpoint validation
- 2 AI opponents with varying speed and wobble behavior
- Drift scoring system — earn points while sliding sideways
- Boost pad collection and activation for temporary speed bursts
- Tire smoke particles when drifting, boost flames, checkpoint flashes
- Lap timer with best lap tracking
- Race results: position, total time, best lap, drift score

## Controls

| Key              | Action     |
| ---------------- | ---------- |
| W / Up           | Accelerate |
| S / Down         | Brake      |
| A/D / Left/Right | Steer      |
| Space            | Use boost  |
| Escape           | Quit       |

## How to Play

1. Select a track (Easy, Medium, Hard)
2. Complete 3 laps before the AI opponents
3. Drift through corners at high speed to earn drift points
4. Collect yellow boost pads and press Space to activate
5. View your results: finishing position, total time, best lap, and drift score

## Running

```bash
cargo run -- content/games/sports/drift_racing
```
