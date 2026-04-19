---
name: ui-layout
description: "Load this skill when designing, reviewing, or scaffolding TOML UI layout files for Lurek2D. Use for: authoring content/layouts/ TOML files, grid-snapping coordinates, choosing widget types, creating game or app screen layouts, running render_layout.py, snap_to_grid.py, or fix_layouts.py. Skip it for Rust engine UI code or Lua game-logic scripting."
---
# ui-layout

## Mission

# UI Layout — Lurek2D TOML Layout Design

## When To Load

- Creating or editing any `content/layouts/**/*.toml` file
- Designing a new game or app screen (HUD, inventory, menu, dialog, strategy map, etc.)
- Running `tools/ui/render_layout.py` or `tools/ui/snap_to_grid.py`
- Reviewing layout PNGs for visual improvements
- Adding a new widget type to the widget palette

## When To Skip

- Lua binding of UI widgets → `lua-api-design` + `lua-rust-bridge` skills
- Rust `src/ui/` implementation → `rust-coding` skill
- Gameplay logic that reads UI state → `lua-scripting` skill
---

## Domain Knowledge

### Owns
- TOML layout file format, section structure, and naming conventions
- 8-pixel grid discipline for all x/y/w/h fields — **no separators, spacing by position only**
- Widget type palette — which widget to use and when
- Spacing hierarchy and minimum size rules
- Layout archetypes per screen type (HUD, inventory, strategy, dialog, etc.)
- Events/callbacks architecture (TOML layout + Lua callbacks hybrid)
- `tools/ui/render_layout.py` rendering and `tools/ui/snap_to_grid.py` grid-snap toolchain
- `tools/ui/fix_layouts.py` — separator removal and sibling overlap detection/fix

### Grid System
**Always work on the 8-pixel grid.** Run `snap_to_grid.py` after any manual edit.

| Grid unit | Use for |
|-----------|---------|
| 8 px      | All positions (x, y), most widths/heights |
| 4 px      | Fine-detail subdivisions inside a group (use sparingly) |
| 16 px     | Standard internal padding / gap between siblings |
| 24–32 px  | Section gaps, visual breathing room between groups |

> See [snippets/grid-system.txt](snippets/grid-system.txt) for the example.

**Before any commit that changes layout TOML files, always run the snap tool.**
The render pipeline also enforces this visually — misaligned widgets show as
fractional-pixel blurs in the PNG.

---

### Widget Catalogue
Only use types from this table. Add new types only after they are registered in
`src/lua_api/ui_api.rs` and documented in `docs/specs/ui.md`.

| Type | Purpose | Minimum size |
|------|---------|-------------|
| `panel` | Container / background / card. Low-alpha fill so children show through. | 32 × 24 |
| `scrollpanel` | Large scrollable content area (lists, maps, code) | 64 × 64 |
| `label` | Read-only text line or multi-line block | any × 16 |
| `button` | Primary or secondary action trigger | 64 × 32 |
| `textinput` | Single-line text entry | 80 × 24 |
| `checkbox` | Boolean toggle with visible tick box | 80 × 24 |
| `switch` | On/off toggle styled as a pill slider | 48 × 24 |
| `radiobutton` | One-of-N selection | 80 × 24 |
| `combobox` | Drop-down selector / enum picker | 80 × 32 |
| `spinbox` | Integer/float stepped input with +/− buttons | 80 × 32 |
| `slider` | Continuous range input (volume, brightness…) | 80 × 24 |
| `progressbar` | Read-only fill gauge (HP, XP, loading…) | 64 × 8 |
| `scrollbar` | Manual scroll handle | 16 × 64 (vertical) |
| `guitable` | Sortable rows-and-columns data grid | 200 × 80 |
| `treeview` | Collapsible hierarchy list | 160 × 80 |
| `imagewidget` | Static sprite / texture display | 32 × 32 |
| `ninepatch` | Scalable bordered image frame | 32 × 32 |
| `badge` | Small coloured pill label (status, counter, tag) | 32 × 16 |
| `menubar` | Top-of-screen File/Edit/… bar | full-width × 24 |
| `toolbar` | Icon-button row below menubar | full-width × 32 |
| `tabbar` | Horizontal tab selector | full-width × 32 |
| `statusbar` | Bottom info strip | full-width × 24 |
| `dialog` | Floating modal window | 240 × 120 |
| `tooltippanel` | Hover tooltip overlay | 120 × 32 |
| `accordion` | Collapsible section group | full-width × 40 |
| `colorpicker` | RGBA colour well + picker | 200 × 200 |
| `spacer` | Invisible flex gap (zero alpha) | any |

### Widget selection rules

- **Prefer `scrollpanel` over `panel`** for any list longer than ~8 items.
- **Use `progressbar` for read-only gauges** — never a slider set to read-only.
- **Use `badge` for status indicators** (HP red, level, ammo count) — not a label.

> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [snippets/grid-system.txt](snippets/grid-system.txt) — Grid System
- [templates/file-skeleton.toml](templates/file-skeleton.toml) — File skeleton
- [templates/field-ordering-convention-per-widget-block.toml](templates/field-ordering-convention-per-widget-block.toml) — Field ordering convention (per widget block)
- [snippets/layout-hierarchy-godot-inspired-patterns.txt](snippets/layout-hierarchy-godot-inspired-patterns.txt) — Layout Hierarchy — Godot-Inspired Patterns
- [templates/step-1-layout-toml-structure-only.toml](templates/step-1-layout-toml-structure-only.toml) — Step 1 — Layout TOML (structure only)
- [examples/step-2-lua-script-behaviour-only.lua](examples/step-2-lua-script-behaviour-only.lua) — Step 2 — Lua script (behaviour only)
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
