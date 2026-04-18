# Dungeon Crawler

**Category:** retro
**Engine:** Lurek2D

First-person grid-based dungeon crawler inspired by Eye of the Beholder and Dungeon Master. Navigate a 12x12 dungeon rendered with raycasting pseudo-3D, collect orbs, and explore by torchlight.

## Run

```bash
cargo run -- content/games/retro/dungeon_crawler
```

## Controls

| Key    | Action          |
| ------ | --------------- |
| W      | Move forward    |
| S      | Move backward   |
| Q      | Turn 90° left   |
| E      | Turn 90° right  |
| F1     | Weather: clear  |
| F2     | Weather: rain   |
| F3     | Weather: snow   |
| Enter  | Start / confirm |
| Escape | Quit            |

## Gameplay

- Grid-based movement with smooth lerp transitions between cells
- Raycasting renders a first-person pseudo-3D viewport on the left half of the screen
- Four wall types (stone, brick, mossy, magic) with distinct colors and procedural patterns
- Floor and ceiling rendered with depth-shaded gradient bands
- Distance fog darkens walls further from the player
- Flickering torches at fixed positions illuminate nearby walls
- Collect all 8 orbs scattered through the dungeon (+100 score each)
- Minimap on the right panel reveals explored cells, orb locations, and player direction
- Compass indicator shows current facing direction (N/E/S/W)
- Weather overlays: clear skies, rain particles, or snow particles (F1–F3)
- Three states: TITLE → PLAYING → COMPLETE (all orbs collected)

## APIs Used

- `lurek.render` — rectangle, circle, line, print, setColor, setBackgroundColor
- `lurek.input` — bind, wasActionPressed, isActionDown
- `lurek.camera` — viewport management
- `lurek.window` — setTitle
- `lurek.time` — getFPS, getTime, delta
- `lurek.signal` — quit

## Changes from Original Demo

- Full rewrite with action-based input system
- Added raycasting pseudo-3D viewport with four wall types
- Gradient floor/ceiling with 16 depth bands
- Procedural wall textures (brick lines, mossy spots, magic pulse)
- Smooth lerp movement and turning animations
- Minimap with fog-of-war exploration
- Compass indicator
- Weather overlay system (rain/snow particles)
- Torch flicker particles and orb collect sparkle effects
- Three-state flow: TITLE → PLAYING → COMPLETE
- Separated render/render_ui callbacks
