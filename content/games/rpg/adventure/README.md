# Point-and-Click Adventure — The Lost Egg

**Category:** rpg
**Engine:** Lurek2D

A room-based point-and-click adventure game. Explore five interconnected rooms, collect items, combine them to solve puzzles, and find the legendary Golden Egg. Features typewriter-style dialog, an inventory system with item combining, and atmospheric per-room color palettes.

## Run

```bash
cargo run -- content/games/rpg/adventure
```

## Controls

| Key    | Action                                          |
| ------ | ----------------------------------------------- |
| W / ↑  | Move to room exit (up)                          |
| S / ↓  | Move to room exit (down)                        |
| A / ←  | Move to room exit (left)                        |
| D / →  | Move to room exit (right)                       |
| Tab    | Cycle through hotspots in room                  |
| E      | Interact with selected hotspot / advance dialog |
| U      | Use selected inventory item on hotspot          |
| C      | Open inventory / combine items                  |
| Escape | Close menu / quit                               |

## Gameplay

- Five rooms to explore: Bedroom, Hallway, Kitchen, Garden, and Attic
- Each room has interactive hotspot objects with descriptions
- Collect items by interacting with hotspots (key, flashlight, knife, rope, golden egg)
- Combine items in the inventory screen (knife + rope = grappling hook)
- Typewriter-style dialog for narration and item descriptions (0.03s per character)
- Puzzle chain: find key → unlock drawer → get flashlight → reveal attic door → get knife & rope → make grappling hook → climb tree → get golden egg → place on pedestal → win
- Room-specific color palettes for atmosphere
- Particle effects: sparkles on item pickup, burst on puzzle solve, dust on door reveal
- Tween animations: item pickup float-up text

## States

`TITLE` → `EXPLORING` → `DIALOG` / `INVENTORY` / `PUZZLE` → `WIN`

## APIs Used

- `lurek.render` — drawRect, drawRectLines, drawCircle, drawLine, print, setColor, setBackgroundColor
- `lurek.render_ui` — inventory bar, dialog box, room name, control hints
- `lurek.input` — addAction, wasActionPressed
- `lurek.particle` — sparkle, burst, dust particle systems
- `lurek.tween` — pickup float animation, tween.update
- `lurek.camera` — setPosition
- `lurek.window` — setTitle
- `lurek.timer` — getFPS, delta
- `lurek.event` — quit
