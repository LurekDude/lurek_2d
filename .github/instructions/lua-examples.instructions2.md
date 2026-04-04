---
applyTo: "examples/**/*.lua"
---

# Lua Examples Instructions

All files in `examples/` are runnable Lua demos and smoke fixtures for Luna2D. They demonstrate public `luna.*` APIs and, when appropriate, shipped Lunasome modules under `library/`. They must run with `cargo run -- examples/<name>`.

## Core Rules

- **`luna.*` namespace only for engine APIs** — never external engine prefixes or bare globals
- **Must be runnable**: every example must work with `cargo run -- examples/<name>` immediately after checkout
- **All callbacks optional but conventional**: define `luna.load()`, `luna.update(dt)`, `luna.draw()` as the primary structure
- **No external assets unless committed**: if an example loads an image or audio file, it must be in the same example directory
- **Demonstrate one concept clearly**: `hello_world` → basic shapes + text; `physics_demo` → physics world; `sprites` → movement/input
- **Official examples may use `require("library.*")`** when they intentionally depend on shipped Lunasome modules

## Lua Style Rules

- Use `local` for all variables — avoid globals except the `luna.*` callbacks
- Numeric literals: use `0.0` for floats when clarity helps
- Comments explaining non-obvious API behaviour are welcome
- Keep examples focused; small demos are preferred over framework-sized examples

## Compliance

- Key names must match the engine key map: `"space"`, `"escape"`, `"up"`, `"down"`, `"left"`, `"right"`, `"w"`, `"a"`, `"s"`, `"d"`
- Colors are `r, g, b` in `[0.0, 1.0]` range — never `[0, 255]`
- `luna.graphics.rectangle(mode, x, y, w, h)` — first arg is `"fill"` or `"line"`, not a boolean
- Physics body types: `"dynamic"` or `"static"` lowercase strings
- If using `require()`, it must target shipped `library.*` modules or committed helper code within the example itself

## Avoid

- External package imports or deep repo imports outside `library/` or the current example directory
- `os.*`, `io.*` system calls — use `luna.filesystem.*` if file access is needed
- Hardcoded window size assumptions — use `luna.graphics.getWidth()` / `luna.graphics.getHeight()`
- External engine-prefixed function names even if they seem similar to Luna2D equivalents
- Treating examples as a dedicated automated test suite; they are validated by smoke runs
