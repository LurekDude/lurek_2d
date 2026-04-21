# Another World

Cinematic puzzle-platformer inspired by Eric Chahi's 1991 classic. Navigate interconnected alien scenes, fight hostile creatures with a three-mode energy gun, and survive through atmosphere and wits.

## Run
```
cargo run -- content/games/retro/another_world
```

## Controls
| Key            | Action                    |
| -------------- | ------------------------- |
| A / D          | Move left / right         |
| Space / W      | Jump                      |
| F (tap)        | Fire energy shot          |
| F (hold short) | Create energy shield wall |
| F (hold long)  | Fire super-shot           |
| Enter          | Start / Advance           |
| Escape         | Quit                      |

## Gameplay
- 5 interconnected side-scrolling scenes with platform puzzles
- Energy gun with 3 firing modes: normal shot, shield wall, and super-shot
- Shield walls block alien projectiles for 2.5 seconds (max 3 active)
- Super-shot destroys shields and kills through cover
- Alien enemies patrol and shoot projectiles in each scene
- Walking to scene edges transitions to the next area
- Cinematic intro sequence with scrolling story text
- 3 lives with scene-based respawn
- Atmospheric purple/dark palette with moon and silhouettes

## APIs Used
lurek.window, lurek.render, lurek.input, lurek.event, lurek.timer, lurek.particle, lurek.tween, lurek.camera
