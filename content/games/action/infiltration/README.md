# Infiltration

Top-down stealth puzzle — sneak through a guarded facility using gadgets, avoid cameras, hack terminals, and escape with the data.

## Run

```
cargo run -- content/games/action/infiltration
```

## Controls

| Key    | Action                                        |
| ------ | --------------------------------------------- |
| W / ↑  | Move up                                       |
| A / ←  | Move left                                     |
| S / ↓  | Move down                                     |
| D / →  | Move right                                    |
| 1      | Use Keycard (opens keycard doors)             |
| 2      | Use EMP (disables cameras for 8s)             |
| 3      | Use Lockpick (opens mechanical doors)         |
| E      | Interact (hack terminal / hack door sequence) |
| Escape | Quit                                          |

## Gameplay

Navigate a 20×15 grid facility with rooms, corridors, and multiple door types. You have 180 seconds to reach the data terminal, hack it, and escape through the exit.

### Gadgets

Three gadget types with limited uses:

- **Keycard** (3 uses) — opens electronic keycard doors instantly.
- **EMP** (2 uses) — emits a pulse that disables all cameras for 8 seconds.
- **Lockpick** (3 uses) — opens mechanical locked doors.

### Cameras

Rotating cameras sweep the corridors with visible vision cones. If a camera spots you, the alert level rises rapidly. Stay out of sight or use the EMP to disable them temporarily.

### Alert System

Alert level ranges from 0 to 100. Cameras raise it when they detect the player. It decays slowly when you are hidden. At high alert, some doors become reinforced. At 100, you are caught — mission failed.

### Hack Mini-Game

Hack doors (type 3) require a wire-matching sequence — press the correct number keys in order to bypass the lock.

### Objectives

- **Primary**: Hack the data terminal (type 5) and reach the exit (type 7).
- **Bonus**: Access the vault (type 6) by using all 3 gadget types on adjacent tiles.

## APIs Used

lurek.window, lurek.render, lurek.input, lurek.timer, lurek.event, lurek.particle, lurek.tween
