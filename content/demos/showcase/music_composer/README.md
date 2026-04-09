# Music Composer

A piano-roll DAW simulator with three independent tracks spanning two octaves (C3–B4). Click cells on the grid to toggle notes, right-click to stamp multi-beat notes, and press Space to play back the composition at the chosen BPM. Tracks can be individually muted, and the full composition can be exported to a human-readable text format.

## What It Demonstrates

- `lurek.mousepressed()` — left-click to toggle single notes, right-click to stamp random-length notes
- `lurek.mouse.isDown()` — drag-to-paint note fills across columns
- `lurek.keyboard.wasPressed()` — track switching (1–3), BPM adjustment, loop, mute, clear, export
- `lurek.gfx.rectangle()` — piano-roll grid cells with per-track color and sharp-key shading
- `lurek.gfx.setColor()` — active/inactive note state and muted-track greying
- `lurek.gfx.print()` — note labels (C3, D#4 etc.), beat numbers, BPM counter, and track names
- `lurek.gfx.line()` — playback cursor scrolling across the grid
- Beat-to-time conversion — `beats_per_sec()` maps BPM to a `play_cursor` float updated each frame

## How to Run

```powershell
cargo run -- content/demos/music_composer
```

## Controls

| Input | Action |
|-------|--------|
| Left Click | Toggle a note on / off |
| Right Click | Stamp a 2–4 beat note starting at that cell |
| Space | Play / stop playback (resets cursor) |
| 1 / 2 / 3 | Select Melody / Bass / Drums track |
| Up / Down Arrow | Increase / decrease BPM by 5 |
| L | Toggle loop mode |
| M | Mute / unmute current track |
| C | Clear all notes on current track |
| E | Export composition to text view |
| Escape | Quit |

## Notes

- The grid is 32 beats × 24 rows; rows map to pitch with row 1 = C5 and row 24 = C3
- Rows representing sharp notes (C#, D#, F#, G#, A#) are rendered with a darker fill to mirror a piano keyboard
- `export_notes()` scans the grid left-to-right and merges consecutive filled cells into a single note with a length field
- BPM is clamped to [60, 200]; the playback cursor wraps to zero in loop mode or stops at the last beat
