# Donkey Kong

Classic platform climber — navigate sloped girders, dodge rolling barrels, and rescue Pauline at the top.

## Run

```
cargo run -- content/games/arcade/donkey_kong
```

## Controls

| Key            | Action                                 |
| -------------- | -------------------------------------- |
| A / D or ← / → | Walk left / right along platform slope |
| W / S or ↑ / ↓ | Climb up / down ladders                |
| Space          | Jump (over barrels or off ladders)     |
| Escape         | Quit                                   |

## Gameplay

Six horizontal platforms with alternating left/right slopes span the screen. Donkey Kong stands at the top-left and periodically hurls barrels that roll downhill following each platform's slope, drop off edges to the platform below, and occasionally descend ladders (30 % chance). Mario starts at the bottom-left and must climb ladders and traverse platforms to reach Pauline at the top-right.

Jumping over a barrel scores 100 points. A hammer power-up appears on the third platform — collecting it grants 5 seconds of hammer mode where touching barrels smashes them for 300 points each. Reaching Pauline awards 1 000 points and advances to the next wave with a faster barrel throw rate. The player has 3 lives; contact with a barrel costs one life.

Window size is 960 × 540 to give the tall level layout room to breathe.

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.timer`, `lurek.event`, `lurek.camera`, `lurek.particle`, `lurek.tween`

## Changes from Original Demo

### Replaced
- Raw key polling → action-based input (`lurek.input.bind` / `wasActionPressed` / `isActionDown`)

### Added
- Title screen with DK silhouette art
- Four game states: TITLE → PLAYING → WIN_ANIM → GAME_OVER
- `lurek.render()` / `lurek.render_ui()` split
- Particle effects (barrel smash explosion, landing dust)
- Tween animations (DK arm swing on throw, victory heart)
- Hammer power-up with timed status bar
- Wave progression with increasing barrel frequency
- FPS counter, camera setup
