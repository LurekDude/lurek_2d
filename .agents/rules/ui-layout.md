---
description: "Load when designing or reviewing TOML UI layouts in content/layouts/ and related layout tools. Skip for Rust UI code or Lua game logic."
alwaysApply: false
---

# ui-layout

## Mission
- Own the TOML UI layout format: grid system, widget types, naming conventions, hierarchy rules, and the layout tooling pipeline.

## When To Load
- Creating or editing content/layouts/*.toml files.
- Choosing widget types or layout structure for a game screen.
- Running layout validation or rendering tools.
- Snapping coordinates to the grid system.

## When To Skip
- Rust engine UI code → see src/ui/.
- Lua game-logic scripting → use lua-scripting skill.

## Domain Knowledge
- content/layouts/ splits into apps/ and games/ layout trees.
- Use tools/ui/render_layout.py, snap_to_grid.py, and fix_layouts.py before hand-tuning pixel offsets.
- The project grid baseline is 8px, with 4px for fine offsets and larger multiples for grouping.
- Choose widget patterns already supported by src/ui/ loaders and renderers.
- Keep layout hierarchy shallow, IDs snake_case, and screen purpose obvious.
- TOML layouts should follow the supported widget, hierarchy, and data rules from the current layout system.
- Prefer a small number of well-grouped containers over deeply nested structures.
- IDs should be stable and semantic.

## References
- content/layouts/
- tools/ui/
- src/ui/
