# Raycaster FPS

**Category:** retro
**Engine:** Lurek2D

Wolfenstein 3D-style first-person raycaster shooter. A 320x180 logical viewport is raycasted using DDA and scaled up to 960x540. Navigate a 16x16 grid map with 6 wall types, collect items, fight enemies, and toggle weather overlays.

## Run

```bash
cargo run -- content/games/retro/raycaster_fps
```

## Controls

| Key    | Action               |
| ------ | -------------------- |
| W      | Move forward         |
| S      | Move backward        |
| A      | Strafe left          |
| D      | Strafe right         |
| Q      | Rotate camera left   |
| E      | Rotate camera right  |
| Space  | Fire weapon          |
| F1     | Weather: clear       |
| F2     | Weather: rain        |
| F3     | Weather: snow        |
| Enter  | Start game / restart |
| Escape | Quit                 |

## Gameplay

- Raycasting engine casts 320 rays across a 72° FOV with DDA, fish-eye correction, and distance fog
- 6 wall types with procedural textures: stone, brick, blue stone, red stone, mossy, and gold
- 16 gradient bands for floor (brown) and ceiling (blue) shading
- Billboard-rendered items: 3 key types, health packs, and ammo pickups
- Depth buffer ensures items are correctly occluded by walls
- 2 enemy types with line-of-sight chase AI and hitscan attacks
- Hitscan weapon with 0.3s cooldown, muzzle flash particles, and impact sparks
- Minimap overlay in the top-right corner showing walls, player, items, and enemies
- Weather system: rain and snow particle overlays toggled with F1–F3
- Damage flash (red tween overlay) and item pickup text popups
- Player HP starts at 100; enemies deal damage on contact and by shooting
