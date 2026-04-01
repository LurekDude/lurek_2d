---
applyTo: "examples/**/*.lua"
---

# Lua Examples Instructions

All files in `examples/` are self-contained Lua game demos that demonstrate the `luna.*` API. They must run with `cargo run -- examples/<name>` and serve as both documentation and acceptance tests for the API.

## Core Rules

- **`luna.*` namespace only** — never external engine prefixes, `lg.*`, or any other prefix; this is Luna2D, with its own `luna.*` namespace
- **Must be runnable**: every example must work with `cargo run -- examples/<name>` immediately after checkout
- **All callbacks optional but conventional**: define `luna.load()`, `luna.update(dt)`, `luna.draw()` as the primary structure
- **No external assets unless committed**: if an example loads an image or audio file, it must be in the same example directory
- **Demonstrate one concept clearly**: `hello_world` → basic shapes + text; `physics_demo` → physics world; `sprites` → movement/input

## Lua Style Rules

- Use `local` for all variables — avoid globals except the `luna.*` callbacks
- Numeric literals: use `0.0` for floats, not `0` — Lua is dynamically typed but clarity matters
- Comments explaining non-obvious API behaviour are welcome
- Keep examples under 100 lines — they are demos, not full games

## Compliance

- Key names must match the engine key map: `"space"`, `"escape"`, `"up"`, `"down"`, `"left"`, `"right"`, `"w"`, `"a"`, `"s"`, `"d"`
- Colors are `r, g, b` in `[0.0, 1.0]` range — never `[0, 255]`
- `luna.graphics.rectangle(mode, x, y, w, h)` — first arg is `"fill"` or `"line"`, not a boolean
- Physics body types: `"dynamic"` or `"static"` lowercase strings

## Avoid

- `require()` — examples are single-file
- `os.*`, `io.*` system calls — use `luna.filesystem.*` if file access is needed
- Hardcoded window size assumptions — use `luna.graphics.getWidth()` / `luna.graphics.getHeight()`
- External engine-prefixed function names even if they seem similar to Luna2D equivalents
- Printing FPS with `print()` — use `luna.graphics.print()` on screen
