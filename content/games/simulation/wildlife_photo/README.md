# Wildlife Photo

Explore a scrolling nature landscape, frame wildlife in your camera viewfinder, and snap photos to fill your species journal. Photograph all 8 species to complete the game.

## Run

```
cargo run -- content/games/simulation/wildlife_photo
```

## Controls

| Key           | Action                                 |
| ------------- | -------------------------------------- |
| W / A / S / D | Pan camera across landscape            |
| Space         | Take photo (or reload film when empty) |
| Q             | Zoom out                               |
| E             | Zoom in                                |
| Tab           | Open / close photo album & journal     |
| Escape        | Quit (or close album)                  |

## Gameplay

Navigate a 2400×600 scrolling landscape with forests, open ground, and a water zone. Frame animals in your viewfinder and press Space to photograph them. Scores depend on animal rarity, zoom level, centering in the frame, and whether the animal is feeding. Time cycles through dawn, day, dusk, and night — some animals only appear at certain times (owl at night, butterfly at dawn/day). Staying still for 5 seconds activates the patience meter, attracting shy animals closer.

### Animals

| Animal    | Rarity | Habitat | Notes                |
| --------- | ------ | ------- | -------------------- |
| Butterfly | 5      | Ground  | Dawn/Day only        |
| Fish      | 7      | Water   | All times            |
| Rabbit    | 8      | Ground  | Flees when near      |
| Deer      | 10     | Ground  | Flees when near      |
| Bird      | 12     | Ground  | Arc flight pattern   |
| Fox       | 15     | Ground  | Dawn/Day/Dusk        |
| Bear      | 20     | Ground  | Slow, Day/Dusk only  |
| Eagle     | 25     | Sky     | Soars, Dawn/Day/Dusk |
| Owl       | 30     | Sky     | Night only           |

### Scoring

- Base score = animal rarity value
- Zoom bonus: ×5 per zoom level (close-up = +15)
- Centering bonus: up to +15 for perfect center
- Feeding bonus: +10 if animal is feeding

### Film

12 shots per roll. When empty, press Space to get a new roll (resets camera position).

## APIs Used

`lurek.window`, `lurek.render`, `lurek.input`, `lurek.camera`, `lurek.particle`, `lurek.tween`, `lurek.timer`, `lurek.event`
