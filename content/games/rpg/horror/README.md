# Horror — Psychological Horror Survival

**Category:** rpg
**Engine:** Lurek2D

A top-down psychological horror survival game. Navigate a dark tile-mapped facility armed only with a flashlight. Find 5 keycards to unlock the exit while managing your battery and sanity. A patrolling enemy stalks the corridors — shine your flashlight at it to force a retreat, but every second of light drains your battery. Stay in the dark too long and your sanity crumbles, triggering hallucinations and screen distortion until madness claims you.

## Run

```bash
cargo run -- content/games/rpg/horror
```

## Controls

| Key    | Action                                 |
| ------ | -------------------------------------- |
| W / ↑  | Move up                                |
| S / ↓  | Move down                              |
| A / ←  | Move left                              |
| D / →  | Move right                             |
| F      | Toggle flashlight                      |
| E      | Interact / advance dialog / close note |
| Escape | Quit                                   |

## Gameplay

- **Flashlight**: Cone-shaped beam (0.6 radian spread, 200px range) that follows your movement direction. Battery drains at 15/s when on; recharge at green recharge stations by walking over them
- **Sanity**: Drains at 5/s when flashlight is off or battery is empty. Below 50: screen distortion (color shift, offset). Below 25: hallucination enemies appear briefly. At 0: game over
- **Keys**: 5 keycards scattered across the map — collect all to unlock the exit in the south-east corner
- **Enemy**: Patrols a predetermined path. Detects you if in line of sight and not hidden in shadow. Contact is instant death. Shining the flashlight at the enemy forces it to retreat
- **Notes**: 3 readable lore notes found in the corridors, displayed as popup overlays
- **Scare events**: Random ambient text messages with screen shake and particle flash
- **Atmosphere**: Only tiles within the flashlight cone are brightly lit; everything else is near-black

## States

`TITLE` → `PLAYING` → `NOTE_READING` / `DEAD` / `WON`

## APIs Used

- `lurek.render` — drawRect, drawRectLines, drawCircle, drawLine, print, setColor, setBackgroundColor
- `lurek.render_ui` — sanity bar, battery bar, key/note counters, messages, note overlay
- `lurek.input` — addAction, wasActionPressed, isActionDown
- `lurek.particles` — dust motes (flashlight), scare flash, key pickup glow
- `lurek.tween` — tween.update for animation timing
- `lurek.camera` — setPosition for player-following camera with shake offset
- `lurek.window` — setTitle with FPS display
- `lurek.signal` — quit on escape
- `lurek.time` — getFPS
