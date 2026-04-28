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

**Grid system:** 8px base grid for positions and most sizes. 4px for fine detail (icon offsets, text padding). 16px for padding and gaps between groups. 24-32px for section gaps. All coordinates should snap to the appropriate grid level.

**Widget types (28 total):** panel, scrollpanel, label, textinput, checkbox, switch, radio, dropdown, slider, button, iconbutton, imagebutton, togglebutton, image, icon, progressbar, healthbar, minimap, separator, spacer, grid, list, tabs, tooltip, modal, context_menu, color_picker, calendar.

**Naming conventions:** snake_case for all IDs. Panels end with _panel or _bar. Lists end with _list or _scroll. Buttons end with _btn. Inputs end with _input or _field.

**Hierarchy rules:** root (window) -> section -> group -> widget. Maximum 4 nesting levels. Each section has a panel as container. Groups organize related widgets within a section.

**No separator widgets:** use positional grid gaps (multiples of 8px) instead of explicit separator widgets. Visual separation comes from spacing, not drawn lines.

**Layout archetypes:** HUD (health/mana bars, minimap, hotbar at screen edges), Inventory (grid of slots with tooltip on hover), Dialog (centered modal with portrait, text, choices), Strategy Map (full-screen map with sidebar info panel), Settings (scrollable list of labeled controls).

**Layout tools:** tools/ui/render_layout.py (render TOML to PNG wireframe preview), tools/ui/snap_to_grid.py (snap coordinates to grid), tools/ui/fix_layouts.py (auto-fix common layout issues).

## Companion File Index

None - all guidance is inline.

## References

- content/layouts/ - TOML layout files
- tools/ui/ - layout tools (render, snap, fix)
- src/ui/ - Rust UI module

