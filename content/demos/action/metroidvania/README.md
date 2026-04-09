# Metroidvania Exploration

A side-scrolling platformer spread across multiple interconnected rooms. The player starts with only jump and must navigate to unlock the Dash ability, which is required to pass special dash-gate tiles. Each room is defined by a tile grid keyed on its grid coordinates, and moving off any edge transitions to the neighbouring room.

## What It Demonstrates

- Room-management pattern: rooms stored in a `roomData` table keyed by `"x,y"` string, loaded on transition
- Tile-type system: `1`=solid, `2`=platform (pass-through from below), `3`=dash-gate, `4`=dash unlock, `5`=HP pickup, `6`=enemy-spawn
- Ability gating: dash-gate tiles are blocking until `player.hasDash` is true
- Two-jump system with variable gravity and delta-time physics
- Camera follows the player inside each fixed-size room frame
- Enemy patrol and bump-to-damage collision

## How to Run

```powershell
cargo run -- demos/metroidvania
```

## Controls

| Key | Action |
|-----|--------|
| `A` / `D` or Arrow Left / Right | Move |
| `W` / Arrow Up or `Space` | Jump (double-jump available) |
| `Left Shift` | Dash (requires dash item) |
| Walk off a room edge | Transition to adjacent room |

## Notes

- Collect the glowing item in room `[1,0]` to unlock Dash — it is needed to cross the dash-gate block in room `[0,-1]`.
- Health pickups (yellow diamonds) restore one HP and despawn on contact.
- If there is no room data for a neighbouring grid coordinate the player simply cannot exit in that direction.
