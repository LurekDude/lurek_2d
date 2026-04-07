# Roguelite Action

A real-time action roguelite inspired by Hades. The player clears rooms of enemies, picks a perk from three randomly drawn options between rooms, and fights a boss every fifth room. Rooms escalate in enemy count and HP; the perk system lets the player gradually power up across each run.

## What It Demonstrates

- Real-time melee arc attack: the attack hitbox is a forward-facing arc computed via `atan2` and angular spread
- Invincibility frames (i-frames) on dash: `player.iframes > 0` blocks all damage during the dodge window
- Perk selection screen implemented as a state transition: `state = "perkSelect"` pauses combat and shows three choices
- Perk pool draw: three unique perks drawn from a shared pool table without replacement
- Boss room detection: `roomNum % 5 == 0` spawns a scaled boss + normal enemy combination
- Enemy spawn-from-edge pattern: enemy start positions are randomised along the four arena boundary edges
- Score tracking with a `bestScore` persistent across runs within the session

## How to Run

```powershell
cargo run -- demos/roguelite
```

## Controls

| Key / Input | Action |
|-------------|--------|
| `W` `A` `S` `D` | Move |
| Left Click | Attack (melee arc toward cursor) |
| Left Shift | Dash with invincibility frames |
| `1` `2` `3` | Select perk after clearing a room |
| `R` | Restart after death |

## Notes

- Dash cooldown prevents spam; the dodge direction is the current movement direction at dash time.
- Boss rooms have no waves — defeat the boss to clear the room and advance.
- Perks stack across rooms; picking attack upgrades multiple times is valid.
