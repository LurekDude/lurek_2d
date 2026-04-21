# Dungeon Eye

First-person dungeon crawler inspired by Eye of the Beholder (PC 1992). Navigate a hand-crafted grid dungeon using a raycaster renderer, fight enemies in melee, pick up items, and manage your inventory to escape alive.

## What It Demonstrates

- `lurek.raycaster.new()` — first-person perspective raycaster viewport
- `library.item` — item type definitions (`health_potion`, `sword`, `shield`, `magic_key`)
- `library.inventory` — slot-based inventory management with `add`, `remove`, `getSlots`
- `lurek.render.rectangle()` / `lurek.render.circle()` / `lurek.render.print()` — minimap, UI panels, HUD
- `lurek.render.draw()` — raycaster frame output
- `lurek.event.quit()` — clean exit

## How to Run

```bash
cargo run -- content/games/rpg/dungeon_eye
```

## Controls

| Key | Action |
|-----|--------|
| W / Up | Move forward |
| S / Down | Move backward |
| A / Left | Turn left |
| D / Right | Turn right |
| I | Open / close inventory |
| Up / Down (in inventory) | Navigate items |
| U / Enter (in inventory) | Use selected item |
| Space / E | Interact / inspect facing tile |
| Escape | Close inventory / quit |

## Notes

- Enemies block movement — walking into them triggers melee combat automatically.
- Health potions restore 12 HP when used from the inventory panel.
- The minimap in the top-right corner of the viewport shows walls, the player (yellow), and enemies (red dots).
- The exit tile is shown in green on the minimap; reach it to win.
