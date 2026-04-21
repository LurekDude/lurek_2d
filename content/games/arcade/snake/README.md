# Snake

_Eat, grow, avoid yourself — classic arcade snake with particles and tweened score._

## Run

```powershell
cargo run -- content/games/arcade/snake
```

## Controls

| Input  | Action          |
| ------ | --------------- |
| W / ↑  | Turn up         |
| S / ↓  | Turn down       |
| A / ←  | Turn left       |
| D / →  | Turn right      |
| Enter  | Start / restart |
| Escape | Quit            |

## Gameplay

Guide the snake around a 32×28 grid collecting food. Each food item adds a segment to the snake and increases the score. Three food items are always on screen. Speed increases every 5 points. The snake wraps around screen edges. Colliding with your own body ends the game. High score is tracked within the session.

## APIs Used

**`lurek.*` engine bindings**

- `lurek.window` — sets the window title.
- `lurek.render` — draws the grid, snake body, food, and overlay text.
- `lurek.input` — action-bound WASD / arrow key controls.
- `lurek.camera` — static viewport (good practice pattern).
- `lurek.tween` — smooth score counter animation on food pickup.
- `lurek.particle` — burst effect when eating food.
- `lurek.timer` — FPS counter in the HUD.
- `lurek.event` — clean shutdown on Escape.

**Lunasome (`content/library/`) modules**

_(none)_

## Changes from Original Demo

| Area          | Original demo                     | This rewrite                                           |
| ------------- | --------------------------------- | ------------------------------------------------------ |
| Input         | Raw `lurek.keypressed` key checks | `lurek.input.bind()` + `wasActionPressed` actions      |
| Scene states  | `"playing"` / `"dead"` strings    | `STATE.TITLE → PLAYING → DEAD` enum with title screen  |
| Rendering     | Everything in `lurek.render()`    | Game grid in `render()`, HUD/overlays in `render_ui()` |
| Effects       | None                              | Particle burst on food pickup                          |
| Score display | Instant update                    | Tweened counter animation via `lurek.tween.to()`       |
| Camera        | None                              | `lurek.camera.new()` (static, good practice)           |
| HUD           | Header bar only                   | Header + FPS counter + controls hint                   |
| Snake eyes    | Single eye dot                    | Two eyes that track direction                          |
| Restart       | R key only                        | Enter key (action-bound)                               |
| Window        | No title set                      | `lurek.window.setTitle()` called in init               |
