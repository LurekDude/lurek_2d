# conf.toml Templates

Reference for the `conf.toml` file used in `content/games/<name>/conf.toml`.

## Standard (800×600) — Use for Most Demos

```toml
[window]
title      = "<Demo Title>"
width      = 800
height     = 600

[performance]
target_fps = 60
```

Use for: puzzle, card game, idle, roguelike, RPG, strategy (small), shooter, survival.

---

## Widescreen (960×540) — Use for Platformers / Side-Scrollers

```toml
[window]
title      = "<Demo Title>"
width      = 960
height     = 540  # 16:9 for wide level view

[performance]
target_fps = 60
```

Use for: platformer, endless runner, drift racing, metroidvania, fighting game.

---

## Taller (800×640) — Use for Message Logs / Status Strips

```toml
[window]
title      = "<Demo Title>"
width      = 800
height     = 640  # taller for message log strip

[performance]
target_fps = 60
```

Use for: roguelite, dialog-heavy games, terminal/hacking demos, text adventure hybrids.

---

## Strategy (1024×768) — Use for Maps / Tactical Overviews

```toml
[window]
title      = "<Demo Title>"
width      = 1024
height     = 768  # larger canvas for tactical overview

[performance]
target_fps = 60
```

Use for: RTS, hex strategy, province map, wargame, tower defense with large maps.

---

## With Module Flags

Add module flags only when the demo actually requires them. Flags that are `true` by default
do not need to be repeated; only include overrides.

```toml
[window]
title      = "<Demo Title>"
width      = 800
height     = 600

[performance]
target_fps = 60

[modules]
# Optional: disable audio init for demos that are explicitly silent
audio   = false
# Optional: only needed if the module is disabled by default
physics = true
```

**Rule**: Only add `[modules]` entries when the demo's behavior would break without them or when suppressing an unnecessary subsystem for performance. The engine enables most modules by default.

---

## Common Pitfalls

- Do **not** add `resizable = true` under `[window]` — demos are fixed-resolution
- Do **not** set `target_fps` < 30 or > 120
- Do **not** leave the title as a placeholder — must match the demo's actual name
- If using a non-standard resolution, always add an inline comment explaining why
