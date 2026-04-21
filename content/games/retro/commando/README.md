# Commando

Vertical-scrolling top-down shooter inspired by Capcom's 1985 arcade classic. Fight through dense jungle, rescue POW prisoners, hurl grenades at bunkers, and face off against fortified bosses.

## Run
```
cargo run -- content/games/retro/commando
```

## Controls
| Key     | Action                         |
| ------- | ------------------------------ |
| W/A/S/D | Move soldier                   |
| Space   | Fire rifle                     |
| G       | Throw grenade (limited supply) |
| Enter   | Start / Restart                |
| Escape  | Quit                           |

## Gameplay
- Vertical scrolling jungle at 60px/s — advance through enemy territory
- Three enemy types: Infantry (walks & shoots), Bunkers (3-bullet spread), Officers (fast, 2 HP)
- Grenades explode in a 60px radius, destroying all nearby enemies and cover
- Rescue POW prisoners by walking near them for +300 bonus points
- Cover objects: sandbags and barrels (destructible), trees (indestructible)
- Boss encounter every 2000 distance — large fortified bunker with multiple gun positions
- 3 lives with checkpoint respawn every 1000 distance scrolled
- Distance-based scoring: +1 per pixel scrolled plus enemy kill bonuses

## APIs Used
lurek.window, lurek.render, lurek.input, lurek.event, lurek.timer, lurek.particle, lurek.tween, lurek.camera
