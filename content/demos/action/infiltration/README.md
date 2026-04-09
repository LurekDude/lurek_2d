# Infiltration

A stealth puzzle game where you navigate a multi-room facility, avoid sweeping security cameras, and reach the vault before the mission timer expires. Three door types — keycard, hackable, and mechanical — require different gadgets or a wire-matching mini-puzzle to open. An EMP item can temporarily blind cameras, and the alert level rises whenever a camera catches you in its cone.

## What It Demonstrates

- `lurek.keyboard.isDown()` — WASD and arrow-key movement with per-axis wall-slide collision
- `lurek.keyboard.wasPressed()` — gadget use (E to interact, Q to cycle gadget)
- `lurek.mouse.getPosition()` / `lurek.mousepressed()` — clicking wire targets in the hack mini-puzzle
- `lurek.gfx.polygon()` — camera vision-cone rendered as a filled triangle fan
- `lurek.gfx.rectangle()` — tile map, door overlays, alert bar, gadget HUD
- `lurek.gfx.setColor()` — alert-level colour interpolation from green → yellow → red
- `lurek.gfx.print()` — mission timer countdown, door labels, and win/caught overlays
- Sweep-camera logic — `angle` oscillates between `startAngle ± sweepRange/2`; player detection uses dot-product cone test

## How to Run

```powershell
cargo run -- content/demos/infiltration
```

## Controls

| Input | Action |
|-------|--------|
| W / A / S / D or Arrow Keys | Move |
| E | Interact with door / terminal / vault |
| Q | Cycle active gadget |
| Space | Use active gadget (EMP, lockpick, keycard) |
| Escape | Quit |

## Notes

- EMP disables all cameras in range for 8 s; `disabledCams` is a timer table keyed by camera index
- The wire hack mini-puzzle has a 15-second timer; failure adds 20 alert and cancels the hack
- Alert level at 100 triggers "caught" — the game over state
- The level grid uses numeric tile IDs: `0`=wall, `1`=floor, `2`=keycard door, `3`=hack door, `4`=mechanical door, `5`=terminal, `6`=vault, `7`=exit
