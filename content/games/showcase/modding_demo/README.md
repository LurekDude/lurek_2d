# Modding Demo

**Category:** showcase

Mod loading and management showcase with a simulated mod system. Browse, toggle, and preview six built-in mods, then enter a live test scene where active mods affect gameplay in real time. Demonstrates mod conflict detection, load-order display, and configuration export.

## Run

```
cargo run -- content/games/showcase/modding_demo
```

## Controls

| Key       | Action                           |
| --------- | -------------------------------- |
| Up / Down | Navigate mod list                |
| Enter     | Toggle selected mod on/off       |
| T         | Enter / exit test scene          |
| E         | Export mod configuration summary |
| Escape    | Quit                             |

## Mods

| Mod              | Effect                               |
| ---------------- | ------------------------------------ |
| Extra Colors     | Adds 5 new colors to palette         |
| Speed Boost      | Doubles player movement speed        |
| Big Enemies      | Increases enemy size 2×              |
| Night Mode       | Dark background + reduced visibility |
| Score Multiplier | 3× score                             |
| Chaos Mode       | Random effects every 5 seconds       |

## Features

- Toggle mods with visual feedback (green = active, gray = inactive)
- Load order display — mods applied in list order
- Conflict warning for Speed Boost + Chaos Mode
- Right-panel preview of selected mod changes
- Test scene: move character, collect coins with active mods
- Particle effects on mod activation and coin collection
- Tweened UI transitions
