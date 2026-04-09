# Rhythm Game

A four-lane note highway where coloured notes scroll downward and the player taps the corresponding keys as each note reaches the hit line. Notes are procedurally generated from BPM-aligned beat patterns using additive sine functions, giving varied rhythmic density across a 30-second song.

## What It Demonstrates

- Note-generation using `generateBeat()` with `sin()` beat patterns and per-lane offsets
- Scroll-speed-based timing: `note.y = (gameTime - note.spawnTime) * scrollSpeed − noteHeight`
- Three-tier timing windows: Perfect (< 30 ms), Good (< 80 ms), Miss (anything later)
- Combo multiplier accumulation that resets on a miss
- `luna.keyboard.isDown()` polled per frame to detect fresh key presses with a "just pressed" tracker
- Lane flash and floating feedback text spawned on each hit/miss event
- Summary screen showing Perfect / Good / Miss counts, max combo, and accuracy percentage

## How to Run

```powershell
cargo run -- demos/rhythm_game
```

## Controls

| Key | Action |
|-----|--------|
| `D` | Hit lane 1 (red) |
| `F` | Hit lane 2 (green) |
| `J` | Hit lane 3 (blue) |
| `K` | Hit lane 4 (yellow) |
| `Space` | Start game / restart after song ends |
| `Escape` | Quit |

## Notes

- Notes are auto-generated; the same seed is used every run so the chart is deterministic.
- `scrollSpeed = 350` px/s at BPM 120 — adjusting either value changes chart feel significantly.
- A missed note breaks your combo but does not end the game.
