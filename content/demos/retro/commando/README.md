# Commando

A vertical-scrolling top-down shooter inspired by Capcom's 1985 arcade classic.
Shoot enemy soldiers, throw grenades, and rescue POW prisoners.

## What It Demonstrates

- `lurek.gfx.rectangle()` / `lurek.gfx.circle()` — character sprites without textures
- `lurek.input.isKeyDown()` — 8-directional player movement
- `lurek.keypressed()` — shooting and grenade throwing
- Procedural background tile scrolling
- Basic enemy AI (move toward player + fire bullets)

## Controls

| Key | Action |
|-----|--------|
| WASD or Arrow Keys | Move |
| Space | Shoot |
| Z | Throw Grenade |
| R | Restart |
| Escape | Quit |

## Notes

POW flags award bonus points and an extra life when collected.
Grenades explode after 0.8 seconds and destroy all enemies within range.
Enemy speed scales with distance traveled.
