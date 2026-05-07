# Dungeon Crawler

**Category:** retro
**Engine:** Lurek2D

First-person dungeon crawler inspired by Eye of the Beholder and Dungeon Master. Navigate a larger 36x36 dungeon rendered with the raycaster `buildScene` GPU path, collect orbs, and explore by torchlight.

## Run

```bash
python tools/dev/parallel_cargo.py run debug -- content/games/retro/dungeon_crawler
```

## Controls

| Key    | Action          |
| ------ | --------------- |
| W      | Move forward    |
| S      | Move backward   |
| A      | Strafe left     |
| D      | Strafe right    |
| Q      | Turn left       |
| E      | Turn right      |
| Escape | Quit            |

## Gameplay

- No splash or start-click screen; the run starts immediately.
- Continuous `dt`-based movement and turning (no tile-step jumps).
- Larger map with wider open regions and multiple loops.
- Six PNG textures are used for walls/floor/ceiling (`assets/textures/*.png`, no logo textures).
- `buildScene` scene generation with point lights and distance dimming.
- Floor and ceiling per-cell texture overrides, including cells that intentionally clear to color fallback.
- Minimap reveals visibility from raycast/FOV traces instead of revealing only the immediate neighbor cells.
- Uses generic engine helpers for reuse:
	- `revealCellsFromRays` for fog-of-war cell reveal
	- `buildMinimapWindow` for LOS-aware minimap tile lighting
- Collect all 10 orbs scattered through the dungeon (+100 score each).
- Two states: `PLAYING` -> `COMPLETE`.

## APIs Used

- `lurek.render` — rectangle, circle, line, print, setColor, setBackgroundColor
- `lurek.input` — bind, wasActionPressed, isActionDown
- `lurek.window` — setTitle
- `lurek.timer` — getFPS, getTime, delta
- `lurek.event` — quit

## Changes from Original Demo

- Migrated rendering path from `drawView` image blit to `buildScene` textured quads.
- Added per-cell floor/ceiling texture overrides using image userdata.
- Replaced tile-step movement with continuous physics-style movement and collision.
- Reworked minimap exploration to use raycast visibility data.
- Migrated reveal/minimap calculations from Lua loops to reusable engine-level raycaster APIs.
