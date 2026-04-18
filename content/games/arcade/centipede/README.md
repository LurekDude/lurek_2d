# Centipede

Classic arcade shooter — blast a segmented centipede as it winds through a mushroom field.

## Run

```
cargo run -- content/games/arcade/centipede
```

## Controls

| Key    | Action                  |
| ------ | ----------------------- |
| A / ←  | Move left               |
| D / →  | Move right              |
| W / ↑  | Move up (player zone)   |
| S / ↓  | Move down (player zone) |
| Space  | Fire                    |
| R      | Restart (game over)     |
| Escape | Quit                    |

## Gameplay

Navigate the bottom 4 rows and shoot upward at the descending centipede chain. Each segment hit becomes a mushroom and splits the centipede into two independent chains. Mushrooms have 4 HP — each hit changes their colour (green → yellow → orange → red) and the 4th hit destroys them.

Three additional enemies appear throughout the game:

- **Spider** — bounces diagonally in the lower screen, worth 300–900 points based on distance when shot.
- **Flea** — drops straight down when mushroom density in the player zone is low, leaving new mushrooms behind.
- **Scorpion** — crosses the screen horizontally, poisoning any mushroom it touches. A poisoned mushroom causes the centipede to drop straight down through it.

Waves add more centipede segments. All mushrooms are restored to full HP on death. 3 lives.

## APIs Used

lurek.window, lurek.render, lurek.input, lurek.time, lurek.signal, lurek.particles, lurek.tween

## Changes from Original Demo

### Replaced
- Raw key polling → action-based input

### Added
- Title screen, game-over screen, state machine
- Particles on mushroom destruction, centipede hit, spider death
- Tween score pop animation
- render/render\_ui split, FPS counter
- Spider, flea, and scorpion enemies with full scoring
- Mushroom 4-HP colour system
- Centipede splitting mechanic

### Removed
- Nothing
