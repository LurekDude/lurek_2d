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
- content/layouts/ currently splits into apps/ and games/ layout trees, so layout authoring should keep those content roles distinct instead of merging every screen into one folder style.
- Use tools/ui/render_layout.py, snap_to_grid.py, and fix_layouts.py before hand-tuning screenshots or pixel offsets by eye; the tooling is the intended feedback loop for this format.
- The project grid baseline is 8px, with 4px for fine offsets and larger multiples for grouping, so spacing choices should feel systematic rather than ad hoc.
- Choose widget patterns already supported by src/ui/ loaders and renderers; unsupported schema ideas belong in engine work, not in speculative TOML files.
- Keep layout hierarchy shallow, IDs snake_case, and screen purpose obvious so scripts and tools can refer to elements without brittle naming.
- TOML layouts here should follow the supported widget, hierarchy, and data rules from the current layout system instead of importing HTML or generic UI-builder conventions.
- Prefer a small number of well-grouped containers over deeply nested structures that make alignment and maintenance harder.
- IDs should be stable and semantic because layout files often become the anchor for script wiring, screenshots, and bug reports.
- This skill is for declarative TOML layout authoring and its tooling loop, not HTML screens, CSS styling, or Rust widget implementation.
- Good layout work here produces screens that snap cleanly to the grid, render predictably with the repo tools, and remain easy to read as plain text.
- If a screen needs dynamic document behavior, reconsider whether it belongs in the HTML path rather than stretching the TOML format beyond its intended use.
## Companion File Index

None - all guidance is inline.

## References
- content/layouts/
- tools/ui/
- src/ui/
