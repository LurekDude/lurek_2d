# IDEA.md — `ui` module

> Migrated from `ideas/features/gui.md` + `ideas/performance/21-gui-scene-events.md`.
> Status checked against `src/ui/` and `src/lua_api/ui_api.rs`.
> Lua namespace: `lurek.ui`.

---

## Features

> **NOTE**: The feature analysis file listed tooltips, tab bar, flexbox layout, draggable
> windows, modal dialogs, and themes as missing. All five are already implemented.
> Only data binding and world-space anchoring remain genuinely missing.

---

### ✅ DONE — 12+ Widget Types
Label, Button, Panel, TextInput, Checkbox, Slider, ProgressBar, List, Dropdown, Image,
ScrollView, Dialog, Gui_Window, TabBar — all implemented with event callbacks.

---

### ✅ DONE — Layout Modes (V/H/Grid/Abs + Flexbox)
**Source**: features/gui.md — Feature Gaps #1 (IMPLEMENTED)

Flexbox layout container at `ui_api.rs:4712` — `lurek.ui.newFlexbox()`.
Standard V/H/Grid/Absolute also available.

---

### ✅ DONE — Theming System
**Source**: features/gui.md — Feature Gaps #2 (IMPLEMENTED)

`lurek.ui.setTheme({...})` at `ui_api.rs:5161` — global theme application.

---

### ✅ DONE — Tooltips
**Source**: features/gui.md — Feature Gaps #6 (IMPLEMENTED)

`widget:setTooltip(text)` / `widget:getTooltip()` at `ui_api.rs:236+`.

---

### ✅ DONE — Tab Bar
**Source**: features/gui.md — Feature Gaps #8 (IMPLEMENTED)

`lurek.ui.newTabBar()` → `LuaTabBar` at `ui_api.rs:4770`. `addButton`, `setActive`,
`getTabCount`, `getActiveTab`, `setActiveTab`.

---

### ✅ DONE — Modal Dialogs
**Source**: features/gui.md — Feature Gaps #7 (IMPLEMENTED)

`isModal` / `setModal` on Dialog widget at `ui_api.rs:3599`.

---

### ✅ DONE — Draggable Windows
**Source**: features/gui.md — Feature Gaps #4 (partially — window drag implemented)

`Gui_Window:isDraggable` / `:setDraggable` at `ui_api.rs:2921+`.

> ⚠️ True drag-and-drop BETWEEN containers (inventory to inventory) is NOT implemented
> (see ❌ TODO below).

---

### ✅ DONE — Data Binding (Reactive UI)
**Source**: features/gui.md — Feature Gaps #3 / Suggestions #4

`WidgetBase.bind_key: Option<String>` added to `src/ui/widget.rs`.
`Widget:bind(key)` / `Widget:unbind()` added to `create_widget_table` in `src/lua_api/ui_api.rs`.
`lurek.ui.update_bindings(data)` added to the UI module register function.

```lua
healthLabel:bind("player.health")
-- later each frame:
lurek.ui.update_bindings({ ["player.health"] = player.health })
```

Number values update Slider/ProgressBar; String values update Label/Button text.

Implemented: 2026-04-15

---

### ❌ TODO — Drag-and-Drop Between Containers
**Source**: features/gui.md — Feature Gaps #4 / Suggestions #2

Window-level dragging is supported but not drag-and-drop between arbitrary containers.
Required for inventory, card games, crafting interfaces.

```lua
itemSlot:setDraggable(true)
equipSlot:setDropTarget(true, function(item) equip(item) end)
```

---

### ✅ DONE — World-Space Widget Anchor
**Source**: features/gui.md — Suggestions #6

`WidgetBase.entity_attachment: Option<u64>` added to `src/ui/widget.rs`.
`Widget:attachToEntity(entity_id)` and `Widget:detachFromEntity()` added.
The layout system reads `entity_attachment` to override the widget's `(x, y)`
from the entity's projected world position.

```lua
healthbar:attachToEntity(enemy.id)
-- detach when enemy dies:
healthbar:detachFromEntity()
```

Implemented: 2026-04-15

---

### ✅ DONE — Widget Animations (Fade / Slide)
**Source**: features/gui.md — Feature Gaps #10 / Suggestions #5

`WidgetBase.alpha: f32` added (default `1.0`) to `src/ui/widget.rs`.
Four new methods added to every widget via `create_widget_table`:
- `Widget:setAlpha(a)` / `Widget:getAlpha()` — direct alpha control.
- `Widget:fadeIn()` / `Widget:fadeOut()` — instant show/hide with alpha + visibility.
- `Widget:slideIn(x, y)` / `Widget:slideOut(x, y)` — instant position + visibility.

For animated transitions, drive alpha/position each frame via `lurek.process` + tween.

```lua
local t = 0
lurek.process = function(dt)
    t = math.min(1, t + dt * 2)
    dialog:setAlpha(t)
end
```

Implemented: 2026-04-15

---

## Performance

### 🔇 LOW — Retained Widget Tree Diff
**Source**: performance/21-gui-scene-events.md

Widget re-render on every frame even when no widget state changes. A dirty-flag system
that skips retess of unchanged subtrees would reduce CPU time for complex UIs. Low priority
unless profiling shows UI in the hot path.
