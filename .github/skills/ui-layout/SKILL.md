---
name: ui-layout
description: "Load this skill when designing, reviewing, or scaffolding TOML UI layout files for Lurek2D. Use for: authoring content/layouts/ TOML files, grid-snapping coordinates, choosing widget types, creating game or app screen layouts, running render_layout.py, snap_to_grid.py, or fix_layouts.py. Skip it for Rust engine UI code or Lua game-logic scripting."
---

# UI Layout — Lurek2D TOML Layout Design

## Load When

- Creating or editing any `content/layouts/**/*.toml` file
- Designing a new game or app screen (HUD, inventory, menu, dialog, strategy map, etc.)
- Running `tools/ui/render_layout.py` or `tools/ui/snap_to_grid.py`
- Reviewing layout PNGs for visual improvements
- Adding a new widget type to the widget palette

## Owns

- TOML layout file format, section structure, and naming conventions
- 8-pixel grid discipline for all x/y/w/h fields — **no separators, spacing by position only**
- Widget type palette — which widget to use and when
- Spacing hierarchy and minimum size rules
- Layout archetypes per screen type (HUD, inventory, strategy, dialog, etc.)
- Events/callbacks architecture (TOML layout + Lua callbacks hybrid)
- `tools/ui/render_layout.py` rendering and `tools/ui/snap_to_grid.py` grid-snap toolchain
- `tools/ui/fix_layouts.py` — separator removal and sibling overlap detection/fix

## Does Not Cover

- Lua binding of UI widgets → `lua-api-design` + `lua-rust-bridge` skills
- Rust `src/ui/` implementation → `rust-coding` skill
- Gameplay logic that reads UI state → `lua-scripting` skill

---

## Grid System

**Always work on the 8-pixel grid.** Run `snap_to_grid.py` after any manual edit.

| Grid unit | Use for |
|-----------|---------|
| 8 px      | All positions (x, y), most widths/heights |
| 4 px      | Fine-detail subdivisions inside a group (use sparingly) |
| 16 px     | Standard internal padding / gap between siblings |
| 24–32 px  | Section gaps, visual breathing room between groups |

```
# Snap a single file to 8px grid:
python tools/ui/snap_to_grid.py content/layouts/games/my_hud.toml --grid 8

# Snap everything at once:
python tools/ui/snap_to_grid.py content/layouts/ --grid 8 --recursive
```

**Before any commit that changes layout TOML files, always run the snap tool.**
The render pipeline also enforces this visually — misaligned widgets show as
fractional-pixel blurs in the PNG.

---

## Widget Catalogue

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
- **Use `guitable` for tabular data** with ≥ 2 columns — not stacked labels.
- **Do NOT use `separator`** — use 8–16 px positional gap between siblings instead.
- **Nest `panel` → siblings** for grouped sections, not a flat list of all widgets at root.

---

## Spacing & Sizing Conventions

### Margins
| Context | Margin |
|---------|--------|
| Widget to panel edge | 8 px |
| Between sibling labels / progressbars | 8 px |
| Between a label and its associated control | 8 px |
| Between sibling groups | 16 px |
| Between major sections | 24–32 px |

> **No separator widgets.** Create visual breathing room through y-positions on the 8px grid,
> not via an 8px-tall dummy widget. `fix_layouts.py` will remove any separators found.

### Standard heights
| Widget | Recommended h |
|--------|--------------|
| `separator` | 8 |
| `progressbar` | 8–16 |
| `label` (body) | 16 |
| `label` (header) | 24 |
| `textinput` | 24–32 |
| `combobox` | 32 |
| `spinbox` | 32 |
| `button` (small) | 32 |
| `button` (standard) | 40 |
| `button` (prominent CTA) | 48 |
| `header_bar` panel | 40–48 |
| `footer` panel | 40–48 |
| `tab bar` | 32 |
| `toolbar` | 32–40 |
| `statusbar` | 24 |

### Standard widths for sidebars
| Sidebar role | Recommended w |
|--------------|--------------|
| Narrow control panel | 200–240 |
| Standard sidebar | 280–360 |
| Wide content pane | 400–520 |

---

## TOML Layout Format

### File skeleton

```toml
# <screen_name>.toml — <one-line description>
# Viewport: 1280 × 720
# Contains: <bullet list of major regions>

[root]
widget_type = "panel"
id          = "<screen>_root"
x = 0.0
y = 0.0
w = 1280.0
h = 720.0

# ── Section name ──────────────────────────────────────────────────────────────

[[root.children]]
widget_type = "panel"
id = "<section>_panel"
x = 0.0
y = 0.0
w = 1280.0
h = 48.0

[[root.children.children]]
widget_type = "label"
id = "screen_title"
x = 16.0
y = 12.0
w = 400.0
h = 24.0
```

### Naming rules
- `id` uses `snake_case` throughout.
- Panels end in `_panel` or `_bar` (e.g. `header_bar`, `sidebar_panel`).
- Lists end in `_list` or `_scroll`.
- Tables end in `_table`.
- Buttons end in `_btn`.
- Labels end in `_label` or `_title` (for headings).
- Input fields use the thing they capture: `search_input`, `name_field`.
- Do **not** prefix IDs with the screen name — they are already scoped by the file.

### Field ordering convention (per widget block)
```toml
[[...children]]
widget_type = "button"     # 1. type first
id          = "foo_btn"    # 2. id second
x = 0.0                    # 3. geometry block (x y w h together)
y = 0.0
w = 120.0
h = 40.0
tooltip = "…"              # 4. optional semantics last
```

---

## Layout Hierarchy — Godot-Inspired Patterns

Lurek2D layouts follow the same mental model as Godot's **Control → Container → Control** tree:

```
root (panel — full viewport)
  ├── header_bar (panel, full-width, 40–48 px tall)
  │     ├── title (label)
  │     └── close_btn (button)
  ├── content_area (panel or splitpanel, fills remaining height)
  │     ├── left_panel (panel, fixed width sidebar)
  │     │     └── ... widgets
  │     └── right_panel (panel, fills rest)
  │           └── ... widgets
  └── footer (panel, full-width, 40–48 px tall)
        └── ok_btn (button)
```

**Rules:**
1. **Never put content widgets directly on root** — always wrap in a named sub-panel.
2. **Header and footer span the full width** and use fixed heights (40–48 px on 8px grid: pick 40 or 48).
3. **Sidebars use fixed widths** — let the main content panel fill the remainder.
4. **Group related controls inside a `panel`**, not as a flat list of siblings.
5. **Depth limit: 4 levels** of nesting maximum (root → section → group → widget).
   Deeper nesting makes scrollpanel / treeview wrong contexts; break into separate panels instead.

---

## Game UI Archetypes

### HUD (heads-up display)
- Anchor critical info (HP, ammo) to a fixed corner (top-left, bottom-left, or bottom-right).
- Use `progressbar` for HP/MP/stamina, `badge` for ammo count and status effects.
- Mini-map: `panel` 160–200 × 160–200 px, anchored bottom-right.
- Message log: `scrollpanel` 600–900 × 120–160 px, anchored bottom.
- Action buttons: 3–4 rows × 3–4 cols of `button` (48–56 px each, 8 px gap).

### Inventory / Equipment
- Item grid: `guitable` or `scrollpanel` filling the main area.
- Item detail panel: fixed 280–360 px right sidebar.
- Equipment slots: named `panel` blocks for each slot, labelled with tooltip.
- Action row: 2–4 `button` at bottom of detail panel (equip, drop, use, identify).
- Capacity indicator: `progressbar` + `label` below or above the grid.

### Dialog / Conversation
- Portrait: `imagewidget` or `panel`, ~160 × 160 px.
- Speaker name: `label` h=24, bold-style id ends in `_name`.
- Body text: `scrollpanel` or tall `label`.
- Response choices: `button` stack, each h=40 px with 8 px gap.

### Strategy / Simulation
- Main map: large `scrollpanel` taking 60–75 % of viewport.
- Resource bar: full-width `panel` h=40 at top, 8–12 `label` fields spaced evenly.
- Sidebar panels: 200–280 px wide, scrollable lists for units/cities/queue.
- Action buttons: grouped in a 2-column `panel` in the sidebar.
- Minimap: `panel` 160 × 120–160 px bottom-right or lower sidebar.

### Main Menu / Pause Menu
- Centred vertical stack of `button` (full-menu w=280–360, h=48 each, 16 px gap).
- Logo / title: `imagewidget` or `label` above buttons.
- Background: a single root `panel` — no complex nesting needed.

### Settings Screen
- Left: `treeview` or category `button` stack for navigation (w=200–240 px).
- Right: `panel` showing per-category options (labels + controls in 2-col rows).
- Footer: `button` row (Apply / Cancel / OK) h=48 panel.

### Research / Crafting
- Left: `scrollpanel` item/recipe list with `textinput` search bar above (w=320–400).
- Centre: detail panel (image + description + stat list + progress bar).
- Right: optional secondary panel (queue, related items, active orders).
- CTA buttons: prominent `button` h=40–48 below detail (Start / Cancel).

---

## Events & Callbacks — Recommended Architecture

TOML files define **structure and position only**. Behaviour lives in Lua.
This is the canonical Lurek2D hybrid pattern:

### Step 1 — Layout TOML (structure only)

```toml
# combat_hud.toml
[root]
widget_type = "panel"
id          = "combat_hud_root"
x = 0.0
y = 0.0
w = 1280.0
h = 720.0

[[root.children]]
widget_type = "button"
id          = "end_turn_btn"
x = 8.0
y = 568.0
w = 184.0
h = 40.0
tooltip     = "End the current player turn"

[[root.children]]
widget_type = "slider"
id          = "volume_slider"
x = 400.0
y = 680.0
w = 200.0
h = 24.0
min   = 0.0
max   = 1.0
value = 0.8
```

### Step 2 — Lua script (behaviour only)

```lua
-- Load the layout and show it
local hud = lurek.ui.load_layout("content/layouts/games/combat_hud.toml")
lurek.ui.show(hud)

-- Attach callbacks by widget id
lurek.ui.on(hud, "end_turn_btn", "click", function()
    game.end_player_turn()
end)

lurek.ui.on(hud, "volume_slider", "change", function(value)
    lurek.audio.set_master_volume(value)
end)

-- Update widget text / values at runtime
lurek.ui.set_text(hud, "score_label",  tostring(game.score))
lurek.ui.set_value(hud, "hp_bar",      player.hp / player.max_hp)
lurek.ui.set_visible(hud, "ammo_badge", player.has_ranged_weapon)
```

### API surface (what `lurek.ui` needs to expose)

| Lua call | Signature | Notes |
|----------|-----------|-------|
| `load_layout` | `(path: string) -> Layout` | Parses TOML, builds widget tree, returns handle |
| `show` | `(layout: Layout)` | Makes all widgets visible and interactive |
| `hide` | `(layout: Layout)` | Hides without destroying |
| `on` | `(layout, id, event, fn)` | Attach named-event callback to a widget by id |
| `off` | `(layout, id, event)` | Remove a callback |
| `set_text` | `(layout, id, text)` | Update label / button text at runtime |
| `set_value` | `(layout, id, value)` | Update slider / progressbar / spinbox value |
| `set_visible` | `(layout, id, bool)` | Show or hide a single widget |
| `set_enabled` | `(layout, id, bool)` | Enable or disable (greyed-out) |
| `get_value` | `(layout, id) -> any` | Read current value of a stateful widget |

### Supported event names

| Event | Fires on |
|-------|----------|
| `click` | button / imagewidget / checkbox |
| `change` | slider, spinbox, combobox, textinput, switch, radiobutton |
| `submit` | textinput Enter key |
| `hover_enter` / `hover_exit` | any widget |
| `focus` / `blur` | any keyboard-focusable widget |

### Why not put callbacks in TOML?

TOML callbacks (`on_click = "handle_start"`) require **global function registration**
and cannot capture local state. They are harder to test and tightly couple layout
files to Lua global names. The `lurek.ui.on(layout, id, event, fn)` pattern:
- accepts closures that capture local variables
- keeps all game logic in `.lua` files
- makes layouts reusable across different screens
- is consistent with the `lurek.event` and `lurek.input` callback patterns

---

## Responsive Sizing Principles

Even though Lurek2D targets fixed resolutions, design layouts as if the
content might scale:

1. **Use `w = parent_w - margin * 2`** thinking — leave 8–16 px on each side.
2. **Reserve space for scrollbars** — `scrollpanel` items inside a 380 px wide
   panel should use `w = 360` (or `w = 376` for 2 px border room).
3. **Avoid magic numbers** — prefer multiples of 8 for everything, and use the
   closest 8-multiple when a visual size seems "just right" at an odd number.
4. **Do not rely on overlapping** — if two sibling widgets overlap in the TOML,
   that is a design bug. Use `panel` depth or adjust y-positions.

---

## Quality Checklist (before committing a layout file)

- [ ] All x/y/w/h are multiples of 8 (`snap_to_grid.py --dry-run` reports 0 changes).
- [ ] All widgets have a unique, descriptive `id`.
- [ ] No `widget_type = "separator"` entries (`fix_layouts.py` reports 0 separators removed).
- [ ] No sibling widgets overlap (`fix_layouts.py` reports 0 overlaps detected).
- [ ] No widget extends beyond the viewport (x+w ≤ root.w, y+h ≤ root.h).
- [ ] Header and footer panels span the full width (w = 1280 for 1280×720).
- [ ] All interactive widgets have a `tooltip` field with a helpful description.
- [ ] The PNG renders without clipping (all labels visible, no text overflows).
- [ ] PNG has been re-rendered after edits: `render_layout.py <file>`.

---

## Tools Reference

| Tool | Command | Purpose |
|------|---------|---------|
| Render single layout | `python tools/ui/render_layout.py content/layouts/games/my_hud.toml` | Preview PNG |
| Render all layouts | `python tools/ui/render_layout.py --all content/layouts/ --recursive` | Batch preview |
| Snap to grid (all) | `python tools/ui/snap_to_grid.py content/layouts/ --grid 8 --recursive` | Fix all coords |
| Snap dry-run | `python tools/ui/snap_to_grid.py content/layouts/ --recursive --dry-run` | Audit only |
| Fix separators + overlaps | `python tools/ui/fix_layouts.py content/layouts/ --recursive` | Remove seps, report overlaps |
| Fix separators + overlaps (auto-fix) | `python tools/ui/fix_layouts.py content/layouts/ --recursive --fix` | Remove seps, push overlapping siblings |
| Validate TOML | `python -c "import tomllib; tomllib.load(open('file.toml','rb'))"` | Syntax check |

---

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| `h = 22` (odd height) | Snap to 24 — run `snap_to_grid.py` |
| `widget_type = "separator"` | Replace with 8–16 px positional gap — run `fix_layouts.py` |
| Flat root with 30+ sibling widgets | Group into section panels first |
| Using `panel` as a progress indicator | Use `progressbar` |
| Using `label` for interactive status tags | Use `badge` |
| `guitable` for a single-column list | Use `scrollpanel` or `listbox` |
| Buttons overlapping because of tight y-spacing | Add 8-px gap between each button |
| No `id` on widgets | Give every widget a descriptive `id` |
| `w = 0` on a visible widget | Set explicit width; `w = 0` means "fill parent" in render |
| Nesting 5+ levels deep | Flatten — split deep sub-sections into separate top-level panels |
