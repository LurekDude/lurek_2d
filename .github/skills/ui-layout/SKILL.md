---
name: ui-layout
description: "Load this skill when designing or reviewing TOML UI layouts in content/layouts/ and related layout tools. Skip it for Rust UI code or Lua game logic."
---
# ui-layout

## Mission

Own the TOML UI layout format: grid system, widget types, naming conventions, hierarchy rules, and the layout tooling pipeline.

## When To Load

- Creating or editing content/layouts/*.toml files
- Choosing widget types or layout structure for a game screen
- Running layout validation or rendering tools
- Snapping coordinates to the grid system

## When To Skip

- Rust engine UI code -> see src/ui/
- Lua game-logic scripting -> use lua-scripting skill

## Domain Knowledge
- content/layouts/ currently splits into apps/ and games/ layout trees.
- Use tools/ui/render_layout.py, snap_to_grid.py, and fix_layouts.py before hand-tuning screenshots.
- The project grid baseline is 8px, with 4px for fine offsets and larger multiples for grouping.
- Choose widget patterns already supported by src/ui/ loaders and renderers.
- Keep layout hierarchy shallow, IDs snake_case, and screen purpose obvious.
- This skill is for TOML layout authoring, not HTML UI or Rust widget internals.
- content/layouts/apps and content/layouts/games are the concrete layout roots, and tools/ui already provides render, snap, and fix helpers for this format.
- TOML layouts here should follow supported widget and hierarchy rules from the existing UI loaders instead of importing generic web or game UI schemas.
- The skill owns declarative TOML layout authoring, not HTML screens or Rust widget logic.
## Companion File Index

None - all guidance is inline.

## References
- content/layouts/
- tools/ui/
- src/ui/
