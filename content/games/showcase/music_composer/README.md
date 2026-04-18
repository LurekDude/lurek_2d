# Music Composer

Visual piano roll music sequencer. Place and remove notes on a 32-beat × 24-note grid across three colored tracks, then play back in a looping sweep with smooth cursor animation and particle effects.

## Run

```
cargo run -- content/games/showcase/music_composer
```

## Controls

| Input      | Action                                                     |
| ---------- | ---------------------------------------------------------- |
| 1 / 2 / 3  | Switch to Track 1 (blue) / Track 2 (green) / Track 3 (red) |
| Left Click | Place or remove a note on the grid                         |
| Space      | Play / Pause playback                                      |
| + / -      | Increase / Decrease BPM (60–240, default 120)              |
| C          | Clear current track                                        |
| X          | Clear all tracks                                           |
| P          | Cycle through preset patterns                              |
| V          | Toggle mute on current track                               |
| Escape     | Quit                                                       |

## Features

- **Piano roll grid** — 32 columns (beats) × 24 rows (notes C2–B3)
- **3 tracks** — each with a distinct color; switch instantly with number keys
- **Playback** — cursor sweeps left-to-right with smooth tween movement; loops at beat 32
- **BPM control** — adjustable 60–240 BPM with live HUD readout
- **Preset patterns** — bass line, chord progression, and melody preloaded with P
- **Per-track mute** — press V to toggle mute on the active track
- **Visual metronome** — flashing beat indicator during playback
- **Particles** — sparkle on note placement, pulse on each beat, glow trail on cursor
- **Note count** — per-track note totals shown in the HUD
- **No audio** — purely visual sequencer; all feedback is graphical
