# Boulder Dash

_Dig through a cave, collect sparkling diamonds, dodge falling boulders, and escape before the clock runs out._

## Run

```powershell
cargo run -- content/games/retro/boulder_dash
```

## Controls

| Key        | Action                                     |
| ---------- | ------------------------------------------ |
| Arrow keys | Move player (digs Earth tiles on contact)  |
| Escape     | Quit                                       |

## Gameplay

Navigate a 40 x 26 grid cave filled with Earth, Walls, Boulders, and Diamonds. Moving into an Earth cell clears it; pushing a Boulder sideways works if the adjacent cell is free. Boulders and Diamonds obey gravity — they fall into empty cells and slide off rounded surfaces, creating chain reactions. Collect the required number of Diamonds per level to open the exit tile; reach the exit before the countdown timer expires.

You have three lives — a falling Boulder kills you, as does running out of time. Exits pulse with a glow animation to help you spot them after clearing the diamond quota. There are three progressively harder levels with increasing diamond requirements, tighter time limits, and denser boulder fields.

## APIs Used

**`lurek.*` engine bindings**

- `lurek.render` — draws all cave tiles (Earth, Wall, Boulder, Diamond, Exit, Player) as coloured rectangles with detail highlights.
- `lurek.input` — action-bound arrow key controls for player movement and UI confirmation.
- `lurek.window` — sets the window title on startup.
- `lurek.event` — signals clean engine shutdown on Escape.
- `lurek.timer` — queries elapsed time to drive diamond pulse and exit glow animations.

**Lunasome (`library/`) modules**

_None._

## Changes from Original Demo

Inspired by First Star Software's 1984 Boulder Dash. This implementation is built from scratch in Lua using the Lurek2D render API — no sprites or audio, geometry-only rendering. Level generation is procedural rather than using original game maps. Boulder and diamond sliding physics are implemented as a custom Lua simulation stepping at 0.18-second intervals.
