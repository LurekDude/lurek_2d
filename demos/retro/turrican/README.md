# Turrican

A run-and-gun platformer inspired by Manfred Trenz's legendary Turrican (1990).
Blast enemies with your cannon or sweep them away with your energy beam weapon.
Collect power crystals and reach the exit to advance.

## What It Demonstrates

- `luna.gfx.rectangle()` / `luna.gfx.circle()` — character and environment rendering
- `luna.input.isKeyDown()` — movement and held beam activation
- `luna.keypressed()` — jumping and shooting
- Full tile collision resolution with wall bounce
- Hold-to-fire beam weapon with real-time enemy damage

## Controls

| Key | Action |
|-----|--------|
| A / D or Left / Right | Move |
| Space or W or Up | Jump |
| X | Shoot bullet |
| Z (hold) | Fire energy beam |
| R | Restart |
| Escape | Quit |

## Notes

The energy beam does 2 damage per second and has limited range.
Collect `+` power crystals to restore 2 health. Health is shown as segmented
boxes in the top right.
