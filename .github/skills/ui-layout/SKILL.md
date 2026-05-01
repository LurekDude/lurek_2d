---
name: ui-layout
description: "Load this skill when designing or reviewing TOML UI layouts in content/layouts/ and related layout tools. Skip it for Rust UI code or Lua game logic."
---
# ui-layout

## Mission
- Own the TOML UI layout format: grid system, widget types, naming conventions, hierarchy rules, and the layout tooling pipeline.

## When To Load
- Creating or editing `content/layouts/*.toml` files.
- Choosing widget types or layout structure for a game screen.
- Running layout validation or rendering tools.
- Snapping coordinates to the grid system.

## When To Skip
- Rust engine UI code — see `src/ui/`.
- Lua game-logic scripting — use `lua-scripting` skill.

## Domain Knowledge
- TOML layout schema: every file has a `[root]` table with `widget_type`, `id`, `x`, `y`, `w`, `h` fields, then `[[root.children]]` array entries for child widgets. Supported `widget_type` values are: `panel`, `label`, `button`, `progressbar`, `checkbox`, `image`, `slider`, `list`. Each type has additional optional fields (`text` for labels, `min/max/value` for progressbar, `src` for image). Check `content/layouts/games/fps_hud.toml` for a minimal real example.
- Coordinate system: x and y are top-left pixel offsets from the parent's top-left corner, not the screen origin. For root-level widgets, `x` and `y` are screen-absolute. Viewport comment at the top of each file (e.g., `# Viewport: 1280 × 720`) documents the design canvas size — coordinates must fit within it.
- Grid discipline: run `python tools/ui/snap_to_grid.py content/layouts/ --grid 8 --recursive` to snap `x`, `y`, `w`, `h` to 8-pixel multiples. Run this before committing any layout change. Fine adjustments use `--grid 4`. The tool only modifies geometry fields — `min`, `max`, `value`, and other semantic fields are untouched.
- How to validate a layout: run `python tools/ui/render_layout.py content/layouts/games/my_layout.toml` to produce a PNG preview. Compare against the `.png` reference file that lives beside each `.toml` file (e.g., `fps_hud.png`). If the rendered output differs from the reference, the layout change is a visual regression. Update the reference PNG in the same commit as the layout change.
- How to run `fix_layouts.py`: `python tools/ui/fix_layouts.py content/layouts/` normalises field ordering, strips extra whitespace, and enforces TOML array formatting. Run it after hand-editing to avoid diff noise from formatting differences.
- ID naming rules: `snake_case`, prefixed by widget role (e.g., `hp_bar`, `score_label`, `pause_btn`). IDs must be unique within a file. IDs are referenced from Lua scripts via `lurek.ui.getElementById("id")` — changing an ID after a script has been written breaks the wiring silently.
- `apps/` layouts are for standalone UI demos (calculator, login form, dashboard). `games/` layouts are in-game HUDs and menus. Keep these folders distinct in meaning: a games/ layout should assume a game is running; an apps/ layout should not. Do not add game-specific IDs (e.g., `hp_bar`) to apps/ layouts.
## Companion File Index
- None.

## References
- content/layouts/
- tools/ui/
- src/ui/
