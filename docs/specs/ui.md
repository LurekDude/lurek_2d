# `ui` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 2 — Reusable Engine Extensions |
| **Status** | Implemented — Full |
| **Lua API** | `lurek.ui` |
| **Source** | `src/ui/` |
| **Rust Tests** | `tests/rust/unit/gui_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_gui.lua` |
| **Architecture** | Retained-mode flat widget pool with type-erased `WidgetKind` enum |

## Summary

The `ui` module provides a retained-mode 2D widget system for building in-game menus, HUDs,
dialog boxes, inventory screens, and developer tool panels. It is a Tier 2 Engine Extension
that depends only on `math` and `engine` (Baseline).

All widgets are stored in a flat `Vec<WidgetKind>` pool inside `GuiContext`, indexed by `usize`.
The root panel is always at index 0. Container widgets (`Panel`, `Layout`, `ScrollPanel`,
`GUIWindow`, `SplitPanel`, `DockPanel`) store their children's indices as `Vec<usize>`.
Every concrete widget embeds a `WidgetBase` that provides shared properties: position, size,
visibility, enable state, padding, margin, z-order, min/max size constraints, anchor edges,
and flexbox layout settings (`flex_grow`, `flex_shrink`).

The module provides **32 widget types** across four categories:
- **Controls** (11): `Button`, `Label`, `TextInput`, `CheckBox`, `Slider`, `ProgressBar`,
  `ComboBox`, `ListBox`, `TabBar`, `RadioButton`, `ScrollBar`
- **Containers** (7): `Panel`, `Layout`, `ScrollPanel`, `NinePatch`, `GUIWindow`, `SplitPanel`,
  `DockPanel`
- **Extras** (14): `Toast`, `Separator`, `Spacer`, `TreeView`, `Toolbar`, `MenuBar`, `MenuItem`,
  `Dialog`, `StatusBar`, `Accordion`, `TooltipPanel`, `ColorPicker`, `GUITable`, `ImageWidget`
- **Data Visualization**: `GraphRenderer` with `GraphSeries` (Line, Scatter, Bar) and `chart.rs`
  for CPU-rendered chart images (line, bar, scatter, pie, area)

A `Theme` maps `(WidgetType, WidgetState)` pairs to `WidgetStyle` records containing background
colour, foreground colour, border colour, border width, corner radius, and font size. Style
lookup falls back from the exact state to `Normal`, then to a hard-coded default.

Input events are forwarded manually from `lurek.mousepressed` / `lurek.keypressed` etc., giving
scripts full control over which GUI instance is active. `GuiContext` manages focus cycling
(`focus_next`, `focus_prev`), a toast notification queue with timer-based expiration, and
mouse/keyboard hit-testing against widget bounds.

**Scope boundary**: This module is a pure CPU data layer. It has no GPU, audio, window, or
physics dependencies. Rendering is delegated to `lurek.graphic` draw calls in `ui_api.rs` and
`graphic_api.rs`. The module depends only on `math` and `engine` (Baseline). The `chart.rs`
submodule additionally imports `image::ImageData` for CPU-rendered chart output.

## Architecture

```
lurek.ui.*  (Lua API — src/lua_api/ui_api.rs)
    │
    ▼
src/ui/mod.rs  (re-exports all submodules)
    │
    ├── widget.rs ────────── WidgetBase (24 fields), WidgetState (5 variants),
    │                        WidgetType (32 variants)
    │
    ├── theme.rs ─────────── Theme (style map) + WidgetStyle (6 fields)
    │                        └── fallback: exact → Normal → hard-coded default
    │
    ├── containers.rs ────── Panel, Layout (flexbox), ScrollPanel, NinePatch,
    │                        GUIWindow, SplitPanel, DockPanel
    │                        └── LayoutDirection enum (Vertical/Horizontal/Grid)
    │
    ├── controls.rs ──────── Button, Label, TextInput, CheckBox, Slider,
    │                        ProgressBar, ComboBox, ListBox, TabBar,
    │                        RadioButton, ScrollBar
    │
    ├── extras.rs ────────── Toast, Separator, Spacer, TreeView/TreeNode,
    │                        Toolbar/ToolbarButton, MenuBar, MenuItem,
    │                        Dialog, StatusBar, Accordion/AccordionSection,
    │                        TooltipPanel, ColorPicker, GUITable/TableColumn,
    │                        ImageWidget
    │
    ├── context.rs ───────── GuiContext (flat widget pool + focus + toasts)
    │                        WidgetKind (32-variant type-erased enum)
    │                        GuiEvent (widget state change events)
    │
    ├── data_graph_renderer.rs ── GraphRenderer (viewport ↔ world mapping)
    │                             GraphSeries (Line/Scatter/Bar data)
    │
    └── chart.rs ─────────── ChartConfig, ChartMargin + draw_to_image()
                             for CPU-rendered charts (line/bar/scatter/pie/area)

Lua API layer (src/lua_api/ui_api.rs):
    ├── GuiCallbacks ─── per-widget callback registry (on_click, on_change,
    │                    on_close, on_select, on_draw)
    ├── create_widget_table() ─── shared base methods for every widget
    ├── add_*_methods() ───────── 28 per-widget-type method helpers
    └── LuaTheme ──────────────── Theme UserData with setStyle()
```

### Data Flow

```
Lua script                     ui module (CPU data)                   lua_api/ui_api.rs
───────────                    ────────────────────                   ──────────────────
lurek.ui.newButton("OK")  →    GuiContext.add_button() → pool[idx]   → create_widget_table()
btn:setPosition(10, 20)   →    pool[idx].base.x/y = 10/20           → borrow_mut GuiContext
lurek.ui.mousepressed(…)  →    GuiContext.mouse_pressed() → hit test → returns bool (consumed)
lurek.ui.update(dt)       →    GuiContext.update(dt) → expire toasts
                                                                      → lurek.graphic.* draws
```

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | Module root — re-exports all public types from submodules. |
| `widget.rs` | Shared widget base fields (`WidgetBase`, 24 fields), visual state enum (`WidgetState`, 5 variants), and type tag enum (`WidgetType`, 32 variants). |
| `theme.rs` | Per-widget-type, per-state styling system: `Theme` maps `(WidgetType, WidgetState)` to `WidgetStyle` (bg/fg/border colour, border width, corner radius, font size) with fallback chain. |
| `containers.rs` | Container and layout widgets: `Panel`, `Layout` (vertical/horizontal/grid with flexbox spacing, alignment, wrapping), `ScrollPanel`, `NinePatch` (nine-slice), `GUIWindow`, `SplitPanel`, `DockPanel`. Also `LayoutDirection` enum and `NineSlice` type alias. |
| `controls.rs` | Interactive control widgets: `Button`, `Label`, `TextInput` (with cursor, placeholder, max length), `CheckBox`, `Slider` (range + step snap), `ProgressBar`, `ComboBox`, `ListBox`, `TabBar`, `RadioButton`, `ScrollBar`. |
| `extras.rs` | Utility and advanced widgets: `Toast` (timed notifications), `Separator`, `Spacer`, `TreeView`/`TreeNode`, `Toolbar`/`ToolbarButton`, `MenuBar`/`MenuItem`, `Dialog`, `StatusBar`, `Accordion`/`AccordionSection`, `TooltipPanel`, `ColorPicker`, `GUITable`/`TableColumn`, `ImageWidget`. |
| `context.rs` | Central coordinator: `GuiContext` (widget pool, child management, focus cycling, toast queue, input routing), `WidgetKind` (type-erased 32-variant enum), `GuiEvent` (widget state change events). |
| `data_graph_renderer.rs` | Data visualization: `GraphRenderer` for line/scatter/bar charts with viewport ↔ world mapping, `GraphSeries` enum. Data-only — actual draw calls issued externally by `graphic_api.rs`. |
| `chart.rs` | CPU-rendered chart images: `ChartConfig`, `ChartMargin`, and `draw_to_image()` functions for line, bar, scatter, pie, and area chart types. Outputs `ImageData` with no GPU dependency. |

## Submodules

### `ui::widget`

Shared widget base fields, state enum, and type tag. Every concrete widget embeds a `WidgetBase`
that provides position, size, visibility, enable state, padding, margin, z-order, min/max size
constraints, anchor edges, and flexbox layout properties. `WidgetState` models the five visual
states a widget can be in, and `WidgetType` tags each concrete kind for theme style lookup.

- **`WidgetBase`** (struct): Shared properties embedded in every widget — position (`x`, `y`), size (`width`, `height`), `visible`, `enabled`, `state`, `tooltip`, `z_order`, `padding`/`margin` arrays `[f32;4]`, min/max constraints, anchor edges (`anchor_left`/`top`/`right`/`bottom`, `anchor_center_x`/`center_y`), and flex factors (`flex_grow`, `flex_shrink`). Methods: `new(WidgetType)`, `contains_point(px, py)`, `clear_anchors()`.
- **`WidgetState`** (enum): Five visual states — `Normal`, `Hovered`, `Pressed`, `Focused`, `Disabled`. Supports `parse_str`/`as_str` round-tripping.
- **`WidgetType`** (enum): 32-variant type tag identifying widget kind for theme lookups. Supports `as_str` conversion. Variants: Button, Label, TextInput, CheckBox, Slider, ProgressBar, ComboBox, ListBox, Panel, Layout, ScrollPanel, NinePatch, TabBar, Toast, Separator, Spacer, TreeView, RadioButton, ScrollBar, GUIWindow, SplitPanel, DockPanel, Toolbar, MenuBar, MenuItem, Dialog, StatusBar, Accordion, TooltipPanel, ColorPicker, GUITable, ImageWidget.

### `ui::theme`

Per-widget-type, per-state styling system. A `Theme` maps `(WidgetType, WidgetState)` pairs to
`WidgetStyle` records. Style lookup falls back: exact → Normal state → hard-coded default. The
Lua API exposes `lurek.ui.newTheme()`, `theme:setStyle()`, and `lurek.ui.setTheme()`.

- **`WidgetStyle`** (struct): Visual style record with `bg_color`, `fg_color`, `border_color` (all `[f32;4]`), `border_width`, `corner_radius`, and `font_size` (all `f32`). Default: dark gray bg, white fg, gray border, 1px border, 0 radius, 14px font.
- **`Theme`** (struct): Style map `HashMap<(WidgetType, WidgetState), WidgetStyle>`. Methods: `new()`, `set_style(widget_type, state, style)`, `get_style(widget_type, state)` with fallback chain.

### `ui::containers`

Container and layout widgets that hold child widgets and optionally apply layout rules. `Panel`
is the simplest container. `Layout` adds flexbox-inspired positioning (vertical, horizontal,
grid with spacing, alignment, wrapping). `ScrollPanel` provides a scrollable viewport.
`NinePatch` computes nine-slice rectangles for scalable panel borders. `GUIWindow` adds a titled,
draggable, resizable frame. `SplitPanel` divides into two resizable areas. `DockPanel` docks
children to edges.

- **`Panel`** (struct): Basic container with optional title and scrollable flag, holding children by index.
- **`Layout`** (struct): Flexbox-like container with direction (vertical/horizontal/grid), spacing, columns, wrap, align, and justify. Has `perform_layout()` for child positioning.
- **`LayoutDirection`** (enum): `Vertical`, `Horizontal`, or `Grid`. Supports `parse_str`/`as_str`.
- **`ScrollPanel`** (struct): Scrollable viewport with `content_width`/`content_height`, scroll position, speed, and `clamp_scroll()`/`max_scroll()`.
- **`NinePatch`** (struct): Nine-slice border widget with pixel insets and `get_slices()` returning 9 source/dest rectangle tuples.
- **`NineSlice`** (type alias): `(f32, f32, f32, f32, f32, f32, f32, f32)` — (sx, sy, sw, sh, dx, dy, dw, dh).
- **`GUIWindow`** (struct): Windowed container with title, closeable, draggable, and resizable flags.
- **`SplitPanel`** (struct): Two-area resizable container with orientation, split position, and minimum panel size.
- **`DockPanel`** (struct): Edge-docking container with docked child/side pairs and split sizes.

### `ui::controls`

Interactive and display control widgets. Each widget embeds a `WidgetBase` for shared properties
and adds type-specific data fields. Controls are leaf widgets that users interact with or display
information.

- **`Button`** (struct): Clickable button with `text` label.
- **`Label`** (struct): Static text display with `text` field.
- **`TextInput`** (struct): Single-line text field with cursor, placeholder, max length, `insert_text()`, and `backspace()`.
- **`CheckBox`** (struct): Toggle with `text` label and `checked` state.
- **`Slider`** (struct): Range slider with `value`, `min`, `max`, `step`. `set_value()` clamps and snaps to step.
- **`ProgressBar`** (struct): Progress display with `value`, `min`, `max`. `progress()` returns 0.0–1.0 fraction.
- **`ComboBox`** (struct): Drop-down selector with items list, selected index, open state. Methods: `add_item()`, `remove_item()`, `clear()`, `selected_item()`.
- **`ListBox`** (struct): Scrollable list with items, selected index, item height. Methods: `add_item()`, `remove_item()`, `clear()`, `selected_item()`.
- **`TabBar`** (struct): Tab strip with tabs list and active tab index. Methods: `add_tab()`, `remove_tab()`.
- **`RadioButton`** (struct): Grouped radio with `text`, `selected`, and `group` name for mutual exclusion.
- **`ScrollBar`** (struct): Scroll bar with `position`, `content_size`, `view_size`, and `vertical` orientation.

### `ui::extras`

Utility and advanced widgets for auxiliary UI roles — visual dividers, empty spacing, timed
notifications, collapsible trees, toolbars, menus, dialogs, data tables, and more.

- **`Toast`** (struct): Auto-expiring notification with message, duration, and elapsed time. Methods: `progress()`, `is_expired()`, `update(dt)`.
- **`Separator`** (struct): Visual divider line with vertical flag and thickness.
- **`Spacer`** (struct): Empty spacing widget with fixed width and height.
- **`TreeNode`** (struct): Node in a tree hierarchy with text, optional icon, children indices, expanded state, and parent index.
- **`TreeView`** (struct): Collapsible tree widget with nodes, root indices, and selected node. 15+ methods for node management.
- **`ToolbarButton`** (struct): Button entry in a `Toolbar` with id, tooltip, enabled, and toggled state.
- **`Toolbar`** (struct): Horizontal or vertical toolbar with buttons and child widgets. Methods: `add_button()`, `add_separator()`, `add_spacer()`.
- **`MenuBar`** (struct): Top-level menu bar holding menu widget indices.
- **`MenuItem`** (struct): Menu item with text, shortcut, checked state, and child items for submenus.
- **`Dialog`** (struct): Modal or modeless dialog with title, open state, content widget index, and footer buttons.
- **`StatusBar`** (struct): Status bar with named sections as `(text, width)` pairs.
- **`AccordionSection`** (struct): Single collapsible section with title, content widget index, and expanded state.
- **`Accordion`** (struct): Collapsible accordion container with sections and exclusive mode (only one section open).
- **`TooltipPanel`** (struct): Rich tooltip with text, hover delay, and target widget index.
- **`ColorPicker`** (struct): Colour picker with RGBA components, alpha toggle, and mode (`"rgb"`, `"hsv"`, `"hsl"`).
- **`TableColumn`** (struct): Column definition with header text and pixel width.
- **`GUITable`** (struct): Data table with sortable columns, row data, and selected row index.
- **`ImageWidget`** (struct): Image display with scale mode (`"fit"`, `"fill"`, `"stretch"`, `"none"`) and RGBA tint.

### `ui::context`

Central coordinator for the GUI system. `GuiContext` owns the flat widget pool, provides factory
methods for all 32 widget types, and handles child management, focus cycling, toast queue, and
input event dispatch.

- **`WidgetKind`** (enum): 32-variant type-erased widget storage. Provides `base()`/`base_mut()` and `children()`/`children_mut()` accessors.
- **`GuiContext`** (struct): Root context holding `widgets` pool, `focused_widget`, `toasts` queue, and `theme`. Factory methods `add_*()` for every widget type. Child management: `add_child()`, `remove_child()`, `child_count()`. Focus: `set_focus()`, `focus_next()`, `focus_prev()`. Input: `mouse_pressed()`, `mouse_released()`, `mouse_moved()`, `key_pressed()`, `text_input()`, `wheel_moved()`. Toast: `add_toast()`, `toast_count()`, `update(dt)`. Search: `find_by_id()`.
- **`GuiEvent`** (enum): Event emitted by `GuiContext` when a widget changes state (button clicked, text changed, list selection changed, etc.).

### `ui::data_graph_renderer`

Data-only chart renderer managing named data series with viewport ↔ world coordinate mapping.
Actual draw calls are issued externally by `graphic_api.rs`.

- **`GraphSeries`** (enum): `Line` (points + colour), `Scatter` (points + colour + size), or `Bar` (values + colour) data series.
- **`GraphRenderer`** (struct): Chart renderer with viewport, range, named series, grid/axis/label toggles, colours, title, axis labels, and cursor. Methods: `add_line/scatter/bar_series()`, `auto_range()`, `world_to_screen()`, `screen_to_world()`.

### `ui::chart`

CPU-rendered chart images with configurable styling. Outputs `ImageData` directly — no GPU
required. Supports line, bar, scatter, pie, and area chart types.

- **`ChartConfig`** (struct): Shared configuration for all chart types — `width`, `height`, `title`, `bg_color`, `axis_color`, `grid_color`, `label_color`, `show_grid`, `margin`.
- **`ChartMargin`** (struct): Pixel margins around the plot area — `left`, `top`, `right`, `bottom`.

## Key Types

### Structs

#### `ui::widget::WidgetBase`

Shared properties embedded in every widget. 24 fields: `id` (String), `widget_type` (WidgetType),
`x`/`y`/`width`/`height` (f32), `visible`/`enabled` (bool), `state` (WidgetState), `tooltip`
(String), `z_order` (i32), `padding`/`margin` ([f32;4]), `min_width`/`min_height`/`max_width`/
`max_height` (f32), `anchor_left`/`anchor_top`/`anchor_right`/`anchor_bottom` (Option<f32>),
`anchor_center_x`/`anchor_center_y` (Option<f32>), `flex_grow`/`flex_shrink` (f32). Methods:
`new(WidgetType)`, `contains_point(px, py)`, `clear_anchors()`.

#### `ui::theme::WidgetStyle`

Visual style record: `bg_color`, `fg_color`, `border_color` (all `[f32;4]`), `border_width`,
`corner_radius`, `font_size` (all `f32`). Default: dark gray bg, white fg, gray border, 1px
border, 0 radius, 14px font.

#### `ui::theme::Theme`

Style map `HashMap<(WidgetType, WidgetState), WidgetStyle>`. Methods: `new()`,
`set_style(widget_type, state, style)`, `get_style(widget_type, state)` with fallback chain
(exact → Normal → default).

#### `ui::containers::Panel`

Basic container with `base`, `children` (Vec<usize>), `title` (String), `scrollable` (bool).

#### `ui::containers::Layout`

Flexbox-like container with `direction` (LayoutDirection), `spacing`, `columns`, `wrap`, `align`,
`justify`. `perform_layout()` positions children.

#### `ui::containers::ScrollPanel`

Scrollable viewport with `content_width`/`content_height`, `scroll_x`/`scroll_y`, `scroll_speed`.
Methods: `max_scroll()`, `clamp_scroll()`.

#### `ui::containers::NinePatch`

Nine-slice border widget with pixel insets (`inset_left`/`top`/`right`/`bottom`), image
dimensions. `get_slices()` returns 9 source/dest tuples.

#### `ui::containers::GUIWindow`

Windowed container with `title`, `closeable`, `draggable`, `resizable`, and `children`.

#### `ui::containers::SplitPanel`

Two-area resizable container with `orientation`, `split_position`, `min_panel_size`, and
first/second child indices.

#### `ui::containers::DockPanel`

Edge-docking container with `docked` pairs `(child_idx, side_string)` and `split_sizes`.

#### `ui::context::GuiContext`

Central coordinator: `widgets` (Vec<WidgetKind>), `focused_widget` (Option<usize>), `toasts`
(Vec<Toast>), `theme` (Option<Theme>). 32 factory methods (`add_button`, `add_label`, etc.),
child management, focus cycling, toast queue, input dispatch, widget search.

#### `ui::controls::Button`

Clickable button: `base` (WidgetBase), `text` (String).

#### `ui::controls::Label`

Static text display: `base` (WidgetBase), `text` (String).

#### `ui::controls::TextInput`

Single-line text field: `text`, `placeholder`, `max_length`, `cursor_pos`, `focused`. Methods:
`insert_text()` (returns bool for max length check), `backspace()`.

#### `ui::controls::CheckBox`

Toggle control: `base`, `text`, `checked` (bool).

#### `ui::controls::Slider`

Range slider: `value`, `min`, `max`, `step` (all f64). `set_value()` clamps to range and snaps
to step.

#### `ui::controls::ProgressBar`

Progress display: `value`, `min`, `max` (all f64). `progress()` returns 0.0–1.0 normalized
fraction.

#### `ui::controls::ComboBox`

Drop-down selector: `items` (Vec<String>), `selected_index` (Option<usize>), `open` (bool).
Methods: `add_item()`, `remove_item()`, `clear()`, `selected_item()`.

#### `ui::controls::ListBox`

Scrollable list: `items`, `selected_index`, `item_height`. Methods: `add_item()`,
`remove_item()`, `clear()`, `selected_item()`.

#### `ui::controls::TabBar`

Tab strip: `tabs` (Vec<String>), `active_tab` (usize). `add_tab()`, `remove_tab()`.

#### `ui::controls::RadioButton`

Grouped radio: `text`, `selected`, `group` (String) for mutual exclusion.

#### `ui::controls::ScrollBar`

Scroll bar: `position`, `content_size`, `view_size` (f32), `vertical` (bool).

#### `ui::extras::Toast`

Timed notification: `message`, `duration`, `elapsed`. `progress()` returns 0.0–1.0,
`is_expired()`, `update(dt)`.

#### `ui::extras::Separator`

Visual divider: `vertical` (bool), `thickness` (f32).

#### `ui::extras::Spacer`

Empty spacing: width and height set at construction via `WidgetBase`.

#### `ui::extras::TreeNode`

Tree hierarchy node: `text`, `icon` (Option), `children` (Vec<usize>), `expanded`, `parent`
(Option<usize>).

#### `ui::extras::TreeView`

Collapsible tree: `nodes` (Vec<TreeNode>), `root_nodes`, `selected_node`. 15+ methods for node
CRUD, expand/collapse, selection, and hierarchy queries.

#### `ui::extras::ToolbarButton`

Toolbar entry: `id`, `tooltip`, `enabled`, `toggled`.

#### `ui::extras::Toolbar`

Toolbar container: `orientation`, `children`, `buttons` (Vec<ToolbarButton>). `add_button()`,
`add_separator()`, `add_spacer()`.

#### `ui::extras::MenuBar`

Top-level menu bar: `menus` (Vec<usize>) referencing MenuItem indices.

#### `ui::extras::MenuItem`

Menu item: `text`, `shortcut`, `checked`, `items` (Vec<usize>) for submenus.

#### `ui::extras::Dialog`

Modal/modeless dialog: `title`, `modal`, `open`, `content_idx` (Option<usize>), `footer_buttons`
(Vec<String>).

#### `ui::extras::StatusBar`

Status bar: `sections` (Vec<(String, f32)>) — (text, width) pairs.

#### `ui::extras::AccordionSection`

Single collapsible section: `title`, `content_idx` (Option<usize>), `expanded`.

#### `ui::extras::Accordion`

Collapsible accordion: `sections` (Vec<AccordionSection>), `exclusive` (bool).

#### `ui::extras::TooltipPanel`

Rich tooltip: `text`, `delay` (f32 seconds), `target_idx` (Option<usize>).

#### `ui::extras::ColorPicker`

Colour picker: `r`/`g`/`b`/`a` (f32), `show_alpha`, `color_mode` ("rgb"/"hsv"/"hsl").

#### `ui::extras::TableColumn`

Table column definition: `header` (String), `width` (f32).

#### `ui::extras::GUITable`

Data table: `columns` (Vec<TableColumn>), `rows` (Vec<Vec<String>>), `selected_row`, `sortable`.

#### `ui::extras::ImageWidget`

Image display: `scale_mode` ("fit"/"fill"/"stretch"/"none"), `tint` (f32, f32, f32, f32).

#### `ui::data_graph_renderer::GraphRenderer`

Chart renderer: viewport/range as `(f32,f32,f32,f32)`, `series` (HashMap), grid/axis/label
toggles, colours, title, axis labels, cursor. Methods: `add_line/scatter/bar_series()`,
`auto_range()`, `world_to_screen()`, `screen_to_world()`.

#### `ui::chart::ChartConfig`

Common chart configuration: `width`, `height` (u32), `title` (Option<String>), `bg_color`,
`axis_color`, `grid_color`, `label_color` (all `(u8,u8,u8)` RGB tuples), `show_grid` (bool),
`margin` (ChartMargin).

#### `ui::chart::ChartMargin`

Pixel margins around the chart plot area: `left`, `top`, `right`, `bottom` (all `i32`).

### Enums

#### `ui::widget::WidgetState`

Visual state: `Normal`, `Hovered`, `Pressed`, `Focused`, `Disabled`. `parse_str(&str)` and
`as_str()` for string conversion.

#### `ui::widget::WidgetType`

Type tag with 32 variants: Button, Label, TextInput, CheckBox, Slider, ProgressBar, ComboBox,
ListBox, Panel, Layout, ScrollPanel, NinePatch, TabBar, Toast, Separator, Spacer, TreeView,
RadioButton, ScrollBar, GUIWindow, SplitPanel, DockPanel, Toolbar, MenuBar, MenuItem, Dialog,
StatusBar, Accordion, TooltipPanel, ColorPicker, GUITable, ImageWidget.

#### `ui::containers::LayoutDirection`

Layout direction: `Vertical`, `Horizontal`, `Grid`. `parse_str(&str)` and `as_str()` for string
conversion.

#### `ui::data_graph_renderer::GraphSeries`

Data series: `Line { name, points, color }`, `Scatter { name, points, color, size }`,
`Bar { name, values, color }`.

#### `ui::context::WidgetKind`

Type-erased widget storage with 32 variants wrapping all concrete widget types. Provides
`base()`/`base_mut()` for accessing the embedded `WidgetBase`, and `children()`/`children_mut()`
for container child access.

#### `ui::context::GuiEvent`

Event emitted by `GuiContext` when a widget changes state (button clicked, text changed, list
selection changed, etc.).

## Lua API

Exposed under `lurek.ui.*` by `src/lua_api/ui_api.rs`. The API provides **52 module-level
functions**, **39 base widget methods** shared by all widgets, **248 widget-specific methods**
across 28 widget types, and **1 Theme UserData method** — totalling **340 function registrations**.

### Widget Constructors (33 functions)

| Function | Description |
|----------|-------------|
| `lurek.ui.newButton(text?)` | Creates a button widget with optional text label. |
| `lurek.ui.newLabel(text?)` | Creates a label widget with optional text. |
| `lurek.ui.newTextInput()` | Creates a text input field. |
| `lurek.ui.newCheckbox(text?)` | Creates a checkbox with optional label. |
| `lurek.ui.newSlider(min?, max?)` | Creates a slider with optional range (default 0–1). |
| `lurek.ui.newProgressBar(min?, max?)` | Creates a progress bar with optional range (default 0–1). |
| `lurek.ui.newComboBox()` | Creates a combo box (drop-down selector). |
| `lurek.ui.newList()` | Creates a list box. |
| `lurek.ui.newPanel()` | Creates a panel container. |
| `lurek.ui.newLayout(direction?)` | Creates a layout container (default `"vertical"`). |
| `lurek.ui.newScrollPanel()` | Creates a scrollable panel. |
| `lurek.ui.newNinePatch()` | Creates a nine-patch (nine-slice) widget. |
| `lurek.ui.newTabBar()` | Creates a tab bar. |
| `lurek.ui.newSeparator(vertical?)` | Creates a separator (default horizontal). |
| `lurek.ui.newSpacer(w?, h?)` | Creates a spacer with optional size. |
| `lurek.ui.newToast(message?, duration?)` | Creates a toast notification (default 3s). |
| `lurek.ui.newTreeView()` | Creates a tree view. |
| `lurek.ui.newRadioButton(text?, group?)` | Creates a radio button with optional group. |
| `lurek.ui.newScrollBar(vertical?)` | Creates a scroll bar. |
| `lurek.ui.newWindow(title?)` | Creates a GUI window container. |
| `lurek.ui.newSplitPanel(orientation?)` | Creates a split panel. |
| `lurek.ui.newDockPanel()` | Creates a dock panel. |
| `lurek.ui.newToolbar(orientation?)` | Creates a toolbar. |
| `lurek.ui.newMenuBar()` | Creates a menu bar. |
| `lurek.ui.newMenuItem(text?)` | Creates a menu item. |
| `lurek.ui.newDialog(title?)` | Creates a dialog. |
| `lurek.ui.newStatusBar()` | Creates a status bar. |
| `lurek.ui.newAccordion()` | Creates an accordion. |
| `lurek.ui.newTooltipPanel(text?)` | Creates a tooltip panel. |
| `lurek.ui.newColorPicker()` | Creates a colour picker. |
| `lurek.ui.newTable()` | Creates a data table. |
| `lurek.ui.newImageWidget()` | Creates an image display widget. |
| `lurek.ui.newTheme()` | Creates a new Theme UserData. |

### Context & Management Functions (10 functions)

| Function | Description |
|----------|-------------|
| `lurek.ui.getRoot()` | Returns the root panel widget table. |
| `lurek.ui.setFocus(widget?)` | Sets keyboard focus to a widget or clears it. |
| `lurek.ui.getFocus()` | Returns the focused widget index or nil. |
| `lurek.ui.focusNext()` | Moves focus to the next focusable widget. |
| `lurek.ui.focusPrev()` | Moves focus to the previous focusable widget. |
| `lurek.ui.clearFocus()` | Clears keyboard focus. |
| `lurek.ui.getWidgetCount()` | Returns the total widget count in the context. |
| `lurek.ui.setTheme(theme)` | Sets the active GUI theme. |
| `lurek.ui.getTheme()` | Returns whether a theme is set. |
| `lurek.ui.draw()` | Headless compatibility stub for GUI draw. |

### Toast Management (2 functions)

| Function | Description |
|----------|-------------|
| `lurek.ui.addToast(tbl)` | Queues a toast `{message=, duration=}`. |
| `lurek.ui.getToastCount()` | Returns the active toast count. |

### Input Forwarding (7 functions)

| Function | Description |
|----------|-------------|
| `lurek.ui.mousepressed(x, y, btn?)` | Forwards mouse press, returns whether consumed. |
| `lurek.ui.mousereleased(x, y, btn?)` | Forwards mouse release, returns whether consumed. |
| `lurek.ui.mousemoved(x, y)` | Forwards mouse move, returns whether consumed. |
| `lurek.ui.keypressed(key)` | Forwards key press, returns whether consumed. |
| `lurek.ui.textinput(text)` | Forwards text input to focused text input, returns whether consumed. |
| `lurek.ui.wheelmoved(x, y)` | Forwards mouse wheel, returns whether consumed. |
| `lurek.ui.update(dt)` | Advances toast timers, removes expired, dispatches pending events. |

### Base Widget Methods (39 methods — shared by ALL widgets)

Every widget returned by a constructor carries these methods via `create_widget_table()`:

| Method | Description |
|--------|-------------|
| `widget:setPosition(x, y)` | Sets widget position. |
| `widget:getPosition()` | Returns x, y. |
| `widget:setSize(w, h)` | Sets widget size. |
| `widget:getSize()` | Returns width, height. |
| `widget:setVisible(bool)` | Sets visibility. |
| `widget:isVisible()` | Returns visibility. |
| `widget:setEnabled(bool)` | Sets enabled state. |
| `widget:isEnabled()` | Returns enabled state. |
| `widget:setId(string)` | Sets widget string identifier. |
| `widget:getId()` | Returns widget string identifier. |
| `widget:setTooltip(string)` | Sets tooltip text. |
| `widget:getTooltip()` | Returns tooltip text. |
| `widget:getState()` | Returns widget state string (`"normal"`, `"hovered"`, etc.). |
| `widget:addChild(child)` | Adds a child widget to this container. |
| `widget:removeChild(child)` | Removes a child widget from this container. |
| `widget:getChildCount()` | Returns number of children. |
| `widget:findById(id)` | Recursively searches for widget by id. |
| `widget:setOnClick(fn)` | Registers click callback. |
| `widget:setOnChange(fn)` | Registers value-change callback. |
| `widget:setOnDraw(fn)` | Registers custom draw callback. |
| `widget:containsPoint(x, y)` | Hit test — returns boolean. |
| `widget:setPadding(t, r?, b?, l?)` | Sets CSS-like padding (1–4 args). |
| `widget:getPadding()` | Returns top, right, bottom, left padding. |
| `widget:setMargin(t, r?, b?, l?)` | Sets CSS-like margin (1–4 args). |
| `widget:getMargin()` | Returns top, right, bottom, left margin. |
| `widget:setZOrder(z)` | Sets z-order for draw sorting. |
| `widget:getZOrder()` | Returns z-order. |
| `widget:setMinSize(w, h)` | Sets minimum size. |
| `widget:getMinSize()` | Returns min width, height. |
| `widget:setMaxSize(w, h)` | Sets maximum size. |
| `widget:getMaxSize()` | Returns max width, height. |
| `widget:setAnchor(l?, t?, r?, b?)` | Sets anchor edges. |
| `widget:setAnchorCenter(cx?, cy?)` | Sets center anchor offsets. |
| `widget:clearAnchor()` | Removes all anchor constraints. |
| `widget:setFlexGrow(n)` | Sets flex grow factor. |
| `widget:getFlexGrow()` | Returns flex grow factor. |
| `widget:setFlexShrink(n)` | Sets flex shrink factor. |
| `widget:getFlexShrink()` | Returns flex shrink factor. |

### Button Methods (2 methods)

| Method | Description |
|--------|-------------|
| `btn:setText(text)` | Sets the button text label. |
| `btn:getText()` | Returns the button text label. |

### Label Methods (2 methods)

| Method | Description |
|--------|-------------|
| `lbl:setText(text)` | Sets the label text. |
| `lbl:getText()` | Returns the label text. |

### TextInput Methods (7 methods)

| Method | Description |
|--------|-------------|
| `ti:setText(text)` | Sets the input text content. |
| `ti:getText()` | Returns the input text content. |
| `ti:setPlaceholder(text)` | Sets the placeholder text. |
| `ti:getPlaceholder()` | Returns the placeholder text. |
| `ti:setMaxLength(n)` | Sets the maximum character length. |
| `ti:isFocused()` | Returns whether the input has focus. |
| `ti:getCursorPosition()` | Returns the cursor position. |

### CheckBox Methods (4 methods)

| Method | Description |
|--------|-------------|
| `cb:setChecked(bool)` | Sets the checked state. |
| `cb:isChecked()` | Returns the checked state. |
| `cb:setText(text)` | Sets the checkbox label text. |
| `cb:getText()` | Returns the checkbox label text. |

### Slider Methods (6 methods)

| Method | Description |
|--------|-------------|
| `sl:setValue(n)` | Sets the slider value (clamped and step-snapped). |
| `sl:getValue()` | Returns the slider value. |
| `sl:setRange(min, max)` | Sets the slider range. |
| `sl:setStep(n)` | Sets the step increment. |
| `sl:getMin()` | Returns the minimum value. |
| `sl:getMax()` | Returns the maximum value. |

### ProgressBar Methods (6 methods)

| Method | Description |
|--------|-------------|
| `pb:setValue(n)` | Sets the progress value. |
| `pb:getValue()` | Returns the progress value. |
| `pb:getProgress()` | Returns the normalized progress (0.0–1.0). |
| `pb:setRange(min, max)` | Sets the progress range. |
| `pb:getMin()` | Returns the minimum value. |
| `pb:getMax()` | Returns the maximum value. |

### ComboBox Methods (8 methods)

| Method | Description |
|--------|-------------|
| `cx:addItem(text)` | Adds an item to the drop-down. |
| `cx:removeItem(index)` | Removes an item by 1-based index. |
| `cx:clearItems()` | Removes all items. |
| `cx:getItemCount()` | Returns the number of items. |
| `cx:getItem(index)` | Returns item text at 1-based index. |
| `cx:setSelectedIndex(index)` | Sets the selected 1-based index. |
| `cx:getSelectedIndex()` | Returns the selected 1-based index (0 = none). |
| `cx:getSelectedItem()` | Returns the selected item text or nil. |

### ListBox Methods (8 methods)

| Method | Description |
|--------|-------------|
| `lb:addItem(text)` | Adds an item to the list. |
| `lb:removeItem(index)` | Removes an item by 1-based index. |
| `lb:clearItems()` | Removes all items. |
| `lb:getItemCount()` | Returns the number of items. |
| `lb:getItem(index)` | Returns item text at 1-based index. |
| `lb:setSelectedIndex(index)` | Sets the selected 1-based index. |
| `lb:getSelectedIndex()` | Returns the selected 1-based index (0 = none). |
| `lb:setItemHeight(h)` | Sets the height of each list item. |

### TabBar Methods (6 methods)

| Method | Description |
|--------|-------------|
| `tb:addTab(text)` | Adds a tab with the given label. |
| `tb:removeTab(index)` | Removes a tab by 1-based index. |
| `tb:getTab(index)` | Returns tab text at 1-based index. |
| `tb:getTabCount()` | Returns the number of tabs. |
| `tb:setActiveTab(index)` | Sets the active tab by 1-based index. |
| `tb:getActiveTab()` | Returns the active tab 1-based index. |

### Panel Methods (3 methods)

| Method | Description |
|--------|-------------|
| `pnl:setTitle(text)` | Sets the panel title. |
| `pnl:getTitle()` | Returns the panel title. |
| `pnl:setScrollable(bool)` | Sets whether the panel is scrollable. |

### Layout Methods (11 methods)

| Method | Description |
|--------|-------------|
| `lay:setDirection(dir)` | Sets direction (`"vertical"`, `"horizontal"`, `"grid"`). |
| `lay:getDirection()` | Returns the direction string. |
| `lay:setSpacing(n)` | Sets spacing between children. |
| `lay:getSpacing()` | Returns spacing. |
| `lay:setColumns(n)` | Sets grid column count. |
| `lay:setWrap(bool)` | Sets whether layout wraps overflow. |
| `lay:getWrap()` | Returns whether layout wraps. |
| `lay:setAlign(str)` | Sets cross-axis alignment. |
| `lay:getAlign()` | Returns cross-axis alignment. |
| `lay:setJustify(str)` | Sets main-axis justification. |
| `lay:getJustify()` | Returns main-axis justification. |

### ScrollPanel Methods (7 methods)

| Method | Description |
|--------|-------------|
| `sp:setContentSize(w, h)` | Sets the scrollable content dimensions. |
| `sp:getContentSize()` | Returns content width, height. |
| `sp:setScrollPosition(x, y)` | Sets the scroll offset. |
| `sp:getScrollPosition()` | Returns scroll x, y. |
| `sp:getMaxScroll()` | Returns the maximum scroll offset (x, y). |
| `sp:setScrollSpeed(n)` | Sets the scroll speed multiplier. |
| `sp:getScrollSpeed()` | Returns the scroll speed multiplier. |

### NinePatch Methods (5 methods)

| Method | Description |
|--------|-------------|
| `np:setInsets(l, t, r, b)` | Sets the nine-slice pixel insets. |
| `np:getInsets()` | Returns left, top, right, bottom insets. |
| `np:setImageDimensions(w, h)` | Sets the source image dimensions. |
| `np:getImageDimensions()` | Returns the source image width, height. |
| `np:getSlices()` | Returns 9 slice tables `{sx, sy, sw, sh, dx, dy, dw, dh}`. |

### Toast Methods (6 methods)

| Method | Description |
|--------|-------------|
| `tst:setMessage(text)` | Sets the toast message text. |
| `tst:getMessage()` | Returns the toast message text. |
| `tst:setDuration(n)` | Sets the display duration in seconds. |
| `tst:getDuration()` | Returns the display duration. |
| `tst:getProgress()` | Returns the elapsed progress (0.0–1.0). |
| `tst:isExpired()` | Returns whether the toast has expired. |

### Separator Methods (4 methods)

| Method | Description |
|--------|-------------|
| `sep:setVertical(bool)` | Sets whether the separator is vertical. |
| `sep:isVertical()` | Returns whether the separator is vertical. |
| `sep:setThickness(n)` | Sets the separator thickness in pixels. |
| `sep:getThickness()` | Returns the separator thickness. |

### RadioButton Methods (7 methods)

| Method | Description |
|--------|-------------|
| `rb:getText()` | Returns the radio button label. |
| `rb:setText(text)` | Sets the radio button label. |
| `rb:isSelected()` | Returns whether this radio is selected. |
| `rb:setSelected(bool)` | Sets the selected state. |
| `rb:getGroup()` | Returns the mutual-exclusion group name. |
| `rb:setGroup(name)` | Sets the mutual-exclusion group name. |
| `rb:setOnChange(fn)` | Registers a change callback. |

### ScrollBar Methods (8 methods)

| Method | Description |
|--------|-------------|
| `sb:getScrollPosition()` | Returns the scroll position. |
| `sb:setScrollPosition(n)` | Sets the scroll position. |
| `sb:getContentSize()` | Returns the total content size. |
| `sb:setContentSize(n)` | Sets the total content size. |
| `sb:getViewSize()` | Returns the visible viewport size. |
| `sb:setViewSize(n)` | Sets the visible viewport size. |
| `sb:isVertical()` | Returns whether the scroll bar is vertical. |
| `sb:setOnChange(fn)` | Registers a change callback. |

### GUIWindow Methods (9 methods)

| Method | Description |
|--------|-------------|
| `win:getTitle()` | Returns the window title. |
| `win:setTitle(text)` | Sets the window title. |
| `win:isCloseable()` | Returns whether the close button is shown. |
| `win:setCloseable(bool)` | Sets whether the close button is shown. |
| `win:isDraggable()` | Returns whether the window is draggable. |
| `win:setDraggable(bool)` | Sets whether the window is draggable. |
| `win:isResizable()` | Returns whether the window is resizable. |
| `win:setResizable(bool)` | Sets whether the window is resizable. |
| `win:setOnClose(fn)` | Registers a close callback. |

### SplitPanel Methods (10 methods)

| Method | Description |
|--------|-------------|
| `spl:getOrientation()` | Returns the split orientation string. |
| `spl:setOrientation(str)` | Sets the split orientation. |
| `spl:getSplitPosition()` | Returns the split position (pixels). |
| `spl:setSplitPosition(n)` | Sets the split position. |
| `spl:getMinPanelSize()` | Returns the minimum panel size. |
| `spl:setMinPanelSize(n)` | Sets the minimum panel size. |
| `spl:setFirstChild(widget)` | Sets the first child widget. |
| `spl:setSecondChild(widget)` | Sets the second child widget. |
| `spl:getFirstChild()` | Returns the first child index or nil. |
| `spl:getSecondChild()` | Returns the second child index or nil. |

### DockPanel Methods (5 methods)

| Method | Description |
|--------|-------------|
| `dp:dock(widget, side)` | Docks a child to a side (`"left"`, `"right"`, `"top"`, `"bottom"`). |
| `dp:undock(widget)` | Undocks a child widget. |
| `dp:getDockedCount()` | Returns the number of docked children. |
| `dp:setSplitSize(index, size)` | Sets the size of a docked split. |
| `dp:getSplitSize(index)` | Returns the size of a docked split. |

### Toolbar Methods (9 methods)

| Method | Description |
|--------|-------------|
| `tb:getOrientation()` | Returns the toolbar orientation. |
| `tb:setOrientation(str)` | Sets the toolbar orientation. |
| `tb:addButton(tbl)` | Adds a button `{id=, tooltip=}` to the toolbar. |
| `tb:addSeparator()` | Adds a separator to the toolbar. |
| `tb:addSpacer()` | Adds a spacer to the toolbar. |
| `tb:getButton(id)` | Returns button info table by id. |
| `tb:setButtonEnabled(id, bool)` | Sets whether a toolbar button is enabled. |
| `tb:setButtonToggled(id, bool)` | Sets the toggled state of a toolbar button. |
| `tb:isButtonToggled(id)` | Returns whether a toolbar button is toggled. |

### MenuBar Methods (4 methods)

| Method | Description |
|--------|-------------|
| `mb:addMenu(menuItem)` | Adds a top-level menu (MenuItem widget). |
| `mb:removeMenu(index)` | Removes a menu by 1-based index. |
| `mb:getMenus()` | Returns a table of menu widget indices. |
| `mb:getMenuCount()` | Returns the number of menus. |

### MenuItem Methods (9 methods)

| Method | Description |
|--------|-------------|
| `mi:getText()` | Returns the menu item text. |
| `mi:setText(text)` | Sets the menu item text. |
| `mi:getShortcut()` | Returns the keyboard shortcut string. |
| `mi:setShortcut(str)` | Sets the keyboard shortcut string. |
| `mi:isChecked()` | Returns whether the item is checked. |
| `mi:setChecked(bool)` | Sets the checked state. |
| `mi:addSubItem(menuItem)` | Adds a child sub-menu item. |
| `mi:getSubItems()` | Returns a table of sub-item widget indices. |
| `mi:setOnClick(fn)` | Registers a click callback for this menu item. |

### Dialog Methods (11 methods)

| Method | Description |
|--------|-------------|
| `dlg:getTitle()` | Returns the dialog title. |
| `dlg:setTitle(text)` | Sets the dialog title. |
| `dlg:isModal()` | Returns whether the dialog is modal. |
| `dlg:setModal(bool)` | Sets whether the dialog is modal. |
| `dlg:isOpen()` | Returns whether the dialog is open. |
| `dlg:open()` | Opens the dialog. |
| `dlg:close()` | Closes and removes the dialog. |
| `dlg:setOnClose(fn)` | Registers a close callback. |
| `dlg:setContent(widget)` | Sets the content widget for the dialog body. |
| `dlg:getContent()` | Returns the content widget index or nil. |
| `dlg:addButton(text)` | Adds a footer button with the given label. |

### StatusBar Methods (6 methods)

| Method | Description |
|--------|-------------|
| `sb:addSection(text, width)` | Adds a section with text and pixel width. |
| `sb:setSectionText(index, text)` | Sets the text of a section by 1-based index. |
| `sb:getSectionText(index)` | Returns the text of a section by 1-based index. |
| `sb:getSectionCount()` | Returns the number of sections. |
| `sb:setSectionCount(n)` | Resizes the section list. |
| `sb:setSectionWidget(index, widget)` | Compatibility shim — assigns a widget to a section. |

### Accordion Methods (7 methods)

| Method | Description |
|--------|-------------|
| `acc:addSection(tbl)` | Adds a section `{title=, content=, expanded=}`. |
| `acc:getSectionCount()` | Returns the number of sections. |
| `acc:toggleSection(index)` | Toggles a section expanded/collapsed by 1-based index. |
| `acc:isSectionExpanded(index)` | Returns whether a section is expanded. |
| `acc:isExclusive()` | Returns whether exclusive mode is active. |
| `acc:setExclusive(bool)` | Sets exclusive mode (only one section open). |
| `acc:getSectionTitle(index)` | Returns the title of a section. |

### TooltipPanel Methods (6 methods)

| Method | Description |
|--------|-------------|
| `tt:getText()` | Returns the tooltip text. |
| `tt:setText(text)` | Sets the tooltip text. |
| `tt:getDelay()` | Returns the hover delay in seconds. |
| `tt:setDelay(n)` | Sets the hover delay in seconds. |
| `tt:getTarget()` | Returns the target widget index or nil. |
| `tt:setTarget(widget)` | Sets the target widget to attach to. |

### ColorPicker Methods (7 methods)

| Method | Description |
|--------|-------------|
| `cp:getColor()` | Returns r, g, b, a (each 0.0–1.0). |
| `cp:setColor(r, g, b, a?)` | Sets the colour (alpha defaults to 1.0). |
| `cp:getShowAlpha()` | Returns whether the alpha slider is shown. |
| `cp:setShowAlpha(bool)` | Sets whether the alpha slider is shown. |
| `cp:getColorMode()` | Returns the colour mode (`"rgb"`, `"hsv"`, `"hsl"`). |
| `cp:setColorMode(str)` | Sets the colour mode. |
| `cp:setOnChange(fn)` | Registers a change callback. |

### GUITable Methods (11 methods)

| Method | Description |
|--------|-------------|
| `gt:addColumn(header, width)` | Adds a column with header text and pixel width. |
| `gt:getColumnCount()` | Returns the number of columns. |
| `gt:addRow(...)` | Adds a row of cell values (varargs or table). |
| `gt:getRowCount()` | Returns the number of rows. |
| `gt:getCell(row, col)` | Returns the cell value at 1-based row/col. |
| `gt:setCell(row, col, value)` | Sets the cell value at 1-based row/col. |
| `gt:getSelectedRow()` | Returns the selected row 1-based index (0 = none). |
| `gt:setSelectedRow(index)` | Sets the selected row by 1-based index. |
| `gt:isSortable()` | Returns whether column sorting is enabled. |
| `gt:setSortable(bool)` | Sets whether column sorting is enabled. |
| `gt:setOnSelect(fn)` | Registers a row-selection callback. |

### ImageWidget Methods (4 methods)

| Method | Description |
|--------|-------------|
| `img:getScaleMode()` | Returns the scale mode (`"fit"`, `"fill"`, `"stretch"`, `"none"`). |
| `img:setScaleMode(str)` | Sets the scale mode. |
| `img:getTint()` | Returns r, g, b, a tint values. |
| `img:setTint(r, g, b, a?)` | Sets the tint colour (alpha defaults to 1.0). |

### TreeView Methods (19 methods)

| Method | Description |
|--------|-------------|
| `tv:addNode(text, parent?, icon?)` | Adds a node, returns 1-based node index. |
| `tv:toggleNode(index)` | Toggles expanded/collapsed state. |
| `tv:isExpanded(index)` | Returns whether a node is expanded (deprecated — use `isNodeExpanded`). |
| `tv:getNodeCount()` | Returns the total number of nodes. |
| `tv:removeNode(index)` | Removes a node by 1-based index. |
| `tv:clearNodes()` | Removes all nodes. |
| `tv:getNodeText(index)` | Returns a node's text. |
| `tv:setNodeText(index, text)` | Sets a node's text. |
| `tv:setNodeIcon(index, icon)` | Sets a node's icon string. |
| `tv:expandNode(index)` | Expands a node. |
| `tv:collapseNode(index)` | Collapses a node. |
| `tv:isNodeExpanded(index)` | Returns whether a node is expanded. |
| `tv:expandAll()` | Expands all nodes. |
| `tv:collapseAll()` | Collapses all nodes. |
| `tv:setSelectedNode(index)` | Sets the selected node by 1-based index. |
| `tv:getSelectedNode()` | Returns the selected node 1-based index (0 = none). |
| `tv:getChildNodes(index)` | Returns a table of child node 1-based indices. |
| `tv:getParentNode(index)` | Returns the parent node 1-based index (0 = root). |
| `tv:getNodeDepth(index)` | Returns the depth of a node (0 = root level). |

### Theme Methods (1 method)

The `LuaTheme` UserData returned by `lurek.ui.newTheme()`:

| Method | Description |
|--------|-------------|
| `theme:setStyle(widgetType, state, style)` | Sets a style for a `(widgetType, state)` pair. `widgetType` is a lowercase string (`"button"`, `"slider"`, `"textinput"`, etc.). `state` is `"normal"`, `"hovered"`, `"pressed"`, `"focused"`, or `"disabled"`. `style` is a table with optional keys: `bg_color`, `fg_color`, `border_color` (each `{r,g,b,a}`), `border_width`, `corner_radius`, `font_size`. |

## Lua Examples

```lua
-- ── Basic button with click handler ─────────────────────
local btn = lurek.ui.newButton("Click Me")
btn:setPosition(100, 50)
btn:setSize(120, 40)
btn:setOnClick(function() print("clicked!") end)

local root = lurek.ui.getRoot()
root:addChild(btn)

-- ── Vertical layout with controls ───────────────────────
local layout = lurek.ui.newLayout("vertical")
layout:setPosition(10, 10)
layout:setSpacing(8)

local label = lurek.ui.newLabel("Volume:")
local slider = lurek.ui.newSlider(0, 100)
slider:setValue(75)

layout:addChild(label)
layout:addChild(slider)
root:addChild(layout)

-- ── Themed widgets ──────────────────────────────────────
local theme = lurek.ui.newTheme()
theme:setStyle("button", "normal", {
    bg_color   = {0.2, 0.4, 0.8, 1.0},
    fg_color   = {1, 1, 1, 1},
    border_width = 2,
    corner_radius = 6,
    font_size  = 16,
})
theme:setStyle("button", "hovered", {
    bg_color = {0.3, 0.5, 0.9, 1.0},
})
lurek.ui.setTheme(theme)

-- ── ComboBox with selection ─────────────────────────────
local combo = lurek.ui.newComboBox()
combo:setPosition(200, 100)
combo:setSize(150, 30)
combo:addItem("Easy")
combo:addItem("Normal")
combo:addItem("Hard")
combo:setSelectedIndex(2) -- "Normal"

-- ── Tree view with hierarchy ────────────────────────────
local tree = lurek.ui.newTreeView()
tree:setPosition(10, 200)
tree:setSize(200, 300)
local root_node = tree:addNode("Project")
tree:addNode("src/", root_node)
tree:addNode("docs/", root_node)
tree:addNode("tests/", root_node)
tree:expandAll()

-- ── Data table ──────────────────────────────────────────
local tbl = lurek.ui.newTable()
tbl:setPosition(300, 200)
tbl:setSize(400, 200)
tbl:addColumn("Name", 150)
tbl:addColumn("Score", 100)
tbl:addColumn("Rank", 100)
tbl:addRow("Alice", "95", "#1")
tbl:addRow("Bob", "87", "#2")
tbl:setSortable(true)

-- ── Dialog with content ─────────────────────────────────
local dlg = lurek.ui.newDialog("Confirm")
local msg = lurek.ui.newLabel("Save changes?")
dlg:setContent(msg)
dlg:addButton("Yes")
dlg:addButton("No")
dlg:setModal(true)
dlg:open()

-- ── Forward input events ────────────────────────────────
function lurek.mousepressed(x, y, btn)
    lurek.ui.mousepressed(x, y, btn)
end

function lurek.keypressed(key)
    lurek.ui.keypressed(key)
end

function lurek.textinput(text)
    lurek.ui.textinput(text)
end

function lurek.wheelmoved(x, y)
    lurek.ui.wheelmoved(x, y)
end

function lurek.process(dt)
    lurek.ui.update(dt)
end
```

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 41 (WidgetBase, WidgetStyle, Theme, 7 containers, 11 controls, 14 extras, GuiContext, GraphRenderer, ChartConfig, ChartMargin, GuiCallbacks, LuaTheme) |
| `enum` | 6 (WidgetState, WidgetType, LayoutDirection, GraphSeries, WidgetKind, GuiEvent) |
| `fn` (Rust pub) | ~80 |
| Lua module functions | 52 (33 constructors + 10 context + 2 toast + 7 input) |
| Lua base methods | 39 (shared by all widgets) |
| Lua widget-specific methods | 248 (across 28 widget types) |
| Lua Theme methods | 1 |
| **Lua total** | **340** |

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `engine` | Imports from | Uses `SharedState` via `Rc<RefCell<>>` in the Lua API registration |
| `math` | Imports from | Baseline dependency — `Color` used by `GraphSeries` and `chart.rs` |
| `image` | Imports from | `chart.rs` imports `ImageData` for CPU-rendered chart output |
| `lua_api` | Imported by | `ui_api.rs` binds all public types and functions to `lurek.ui.*` |

**Similar modules**:

| Module | Differentiation |
|--------|-----------------|
| `terminal` | The `terminal` module also has widget types named `Button`, `Label`, `TextBox`, `Panel`. The shared names are **intentional design** — `ui` renders them as pixel-space graphics; `terminal` renders them as character-cell text. Same conceptual interface, different renderers. They share no types. |

## Notes

- **No GPU dependency**: The ui module is pure CPU data. Rendering is delegated to `lurek.graphic` calls in `ui_api.rs` and `graphic_api.rs`.
- **Flat pool indexing**: All widgets are stored in a single `Vec<WidgetKind>` and referenced by `usize` index. Index 0 is always the root panel. This avoids lifetime complexity but means widget indices are invalidated if widgets are removed (currently removal is not supported — widgets are added only).
- **Input forwarding pattern**: Unlike auto-dispatched input, GUI input must be explicitly forwarded from `lurek.mousepressed`/`lurek.keypressed` callbacks. This lets scripts control which GUI instance receives events — useful for multiple GUI panels, pause menus, etc.
- **1-based Lua indices**: List/combo/tab/tree/table methods use 1-based indices on the Lua side, converting to 0-based internally.
- **Callbacks**: `setOnClick`, `setOnChange`, `setOnClose`, `setOnSelect`, and `setOnDraw` store Lua function references in a per-widget `GuiCallbacks` registry keyed by widget index. The `update()` function dispatches pending `GuiEvent`s to registered callbacks.
- **GraphRenderer**: The chart/graph system stores data only. Actual rendering of lines, bars, and axes is done by draw functions in `graphic_api.rs`, not in this module.
- **chart.rs**: The CPU chart renderer (`ChartConfig` + draw functions) outputs `ImageData` directly for line, bar, scatter, pie, and area charts. This is separate from `GraphRenderer` which is a viewport-mapped data store for GPU-rendered charts.
- **Theme fallback chain**: `get_style(widget_type, state)` tries the exact `(type, state)` pair first, falls back to `(type, Normal)`, then to a hard-coded default style. This means setting a single `"normal"` style per widget type is sufficient for basic theming.
- **Widget type strings for Theme**: The `parse_widget_type()` function accepts lowercase strings: `"button"`, `"label"`, `"textinput"`, `"checkbox"`, `"slider"`, `"progressbar"`, `"combobox"`, `"listbox"`, `"panel"`, `"layout"`, `"scrollpanel"`, `"ninepatch"`, `"tabbar"`, `"toast"`, `"separator"`, `"spacer"`, `"treeview"`, `"radiobutton"`, `"scrollbar"`, `"guiwindow"`, `"splitpanel"`, `"dockpanel"`, `"toolbar"`, `"menubar"`, `"menuitem"`, `"dialog"`, `"statusbar"`, `"accordion"`, `"tooltippanel"`, `"colorpicker"`, `"guitable"`, `"imagewidget"`.
