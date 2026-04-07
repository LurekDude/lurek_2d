# conf.lua Templates

Reference for the `conf.lua` file used in `demos/<name>/conf.lua`.

## Standard (800×600) — Use for Most Demos

```lua
function luna.conf(t)
    t.window.title  = "<Demo Title>"
    t.window.width  = 800
    t.window.height = 600
    t.performance.target_fps = 60
end
```

Use for: puzzle, card game, idle, roguelike, RPG, strategy (small), shooter, survival.

---

## Widescreen (960×540) — Use for Platformers / Side-Scrollers

```lua
function luna.conf(t)
    t.window.title  = "<Demo Title>"
    t.window.width  = 960
    t.window.height = 540
    t.performance.target_fps = 60
end
```

Use for: platformer, endless runner, drift racing, metroidvania, fighting game.
Comment required in conf.lua: `-- 16:9 for wide level view`

---

## Taller (800×640) — Use for Message Logs / Status Strips

```lua
function luna.conf(t)
    t.window.title  = "<Demo Title>"
    t.window.width  = 800
    t.window.height = 640
    t.performance.target_fps = 60
end
```

Use for: roguelite, dialog-heavy games, terminal/hacking demos, text adventure hybrids.
Comment required in conf.lua: `-- taller for message log strip`

---

## Strategy (1024×768) — Use for Maps / Tactical Overviews

```lua
function luna.conf(t)
    t.window.title  = "<Demo Title>"
    t.window.width  = 1024
    t.window.height = 768
    t.performance.target_fps = 60
end
```

Use for: RTS, hex strategy, province map, wargame, tower defense with large maps.
Comment required in conf.lua: `-- larger canvas for tactical overview`

---

## With Module Flags

Add module flags only when the demo actually requires them. Flags that are `true` by default
do not need to be repeated; only include overrides.

```lua
function luna.conf(t)
    t.window.title  = "<Demo Title>"
    t.window.width  = 800
    t.window.height = 600
    t.performance.target_fps = 60

    -- Optional: disable audio init for demos that are explicitly silent
    t.modules.audio    = false

    -- Optional: but only needed if the module is disabled by default
    t.modules.physics  = true
end
```

**Rule**: Only add `t.modules.*` lines when the demo's behavior would break without them or when suppressing an unnecessary subsystem for performance. The engine enables most modules by default.

---

## Common Pitfalls

- Do **not** use `t.window.resizable = true` — demos are fixed-resolution
- Do **not** set `t.performance.target_fps` < 30 or > 120
- Do **not** leave the title as a placeholder — must match the demo's actual name
- If using a non-standard resolution, always add an inline comment explaining why
