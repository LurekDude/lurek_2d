# Cannon Fodder

_Command a squad of soldiers through five escalating jungle missions — move, shoot, and use grenades wisely, because every casualty is permanent._

## Run

```powershell
cargo run -- content/games/retro/cannon_fodder
```

## Controls

| Key    | Action                                              |
| ------ | --------------------------------------------------- |
| WASD   | Set squad movement direction                        |
| Space  | All living soldiers fire in facing direction        |
| G      | Throw grenade (3 per mission, 60 px blast radius)   |
| Escape | Quit                                                |

## Gameplay

Lead a squad of up to three soldiers across a scrolling top-down jungle map. Hold a direction key to march the squad, then tap Space to make every living soldier fire in the direction they face. Enemies patrol fixed routes and open fire when a soldier enters their detection range. Reach the flag at the top of the map after eliminating all enemies to complete the mission.

Soldiers killed in action are gone permanently — entering the next mission with fewer soldiers makes every fight harder. Five missions escalate from 6 to 22 enemies. Grenades deal area damage across a 60-pixel radius and are the fastest way to clear clustered enemies; use them sparingly. Score +100 per enemy kill, +50 per grenade kill, and +500 per completed mission.

## APIs Used

**`lurek.*` engine bindings**

- `lurek.render` — draws the scrolling jungle terrain, tree canopy, soldiers, enemies, bullets, grenades, particles, and all HUD overlays.
- `lurek.input` — action bindings for directional movement, fire, grenade throw, and quit.
- `lurek.window` — sets the window title on startup.
- `lurek.event` — signals clean engine shutdown on Escape.

**Lunasome (`library/`) modules**

_None._

## Changes from Original Demo

Inspired by Sensible Software's 1993 Amiga classic. This implementation uses geometry-only rendering (no sprites or audio) and a simplified ballistic model. Permanent soldier death and mission escalation mechanics are faithful to the original concept; map layout is procedurally constructed rather than hand-authored level data.
