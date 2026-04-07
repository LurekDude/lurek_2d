# `gui` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 2 — Reusable Engine Extensions |
| **Status** | Implemented — Full |
| **Lua API** | `luna.ui` |
| **Source** | `src/gui/` |
| **Rust Tests** | `tests/rust/unit/gui_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_gui.lua` |
| **Architecture** | Retained-mode flat widget pool with type-erased `WidgetKind` enum |

## Summary

The `gui` module provides a retained-mode 2D widget system for building in-game menus, HUDs,
dialog boxes, inventory screens, and developer tool panels. It is a Tier 2 Engine Extension
that depends only on `math` and `engine` (Baseline).

All widgets are stored in a flat `Vec<WidgetKind>` pool inside `GuiContext`, indexed by `usize`.
The root panel is always at index 0. Container widgets (`Panel`, `Layout`, `ScrollPanel`,
`GUIWindow`, `SplitPanel`, `DockPanel`) store their children\'s indices as `Vec<usize>`.
Every concrete widget embeds a `WidgetBase` that provides shared properties: position, size,
visibility, enable state, padding, margin, z-order, min/max size constraints, anchor edges,
and flexbox layout settings (`flex_grow`, `flex_shrink`).

The module provides 32 widget types across four categories:
- **Controls** (11): `Button`, `Label`, `TextInput`, `CheckBox`, `Slider`, `ProgressBar`,
  `ComboBox`, `ListBox`, `TabBar`, `RadioButton`, `ScrollBar`
- **Containers** (7): `Panel`, `Layout`, `ScrollPanel`, `NinePatch`, `GUIWindow`, `SplitPanel`,
  `DockPanel`
- **Extras** (14): `Toast`, `Separator`, `Spacer`, `TreeView`, `Toolbar`, `MenuBar`, `MenuItem`,
  `Dialog`, `StatusBar`, `Accordion`, `TooltipPanel`, `ColorPicker`, `GUITable`, `ImageWidget`
- **Data Visualization**: `GraphRenderer` with `GraphSeries` (Line, Scatter, Bar)

A `Theme` maps `(WidgetType, WidgetState)` pairs to `WidgetStyle` records containing background
colour, foreground colour, border colour, border width, corner radius, and font size. Style
lookup falls back from the exact state to `Normal`, then to a hard-coded default.

Input events are forwarded manually from `luna.mousepressed` / `luna.keypressed` etc., giving
scripts full control over which GUI instance is active. `GuiContext` manages focus cycling
(`focus_next`, `focus_prev`), a toast notification queue with timer-based expiration, and
mouse/keyboard hit-testing against widget bounds.

**Scope boundary**: The `gui` module holds layout and state as CPU data only. Actual rendering
is done via `luna.gfx` draw calls issued by `lua_api/gui_api.rs`. No GPU resources live here.

## Architecture

```
gui (module root)
  ├── widget.rs           — WidgetBase (24 fields), WidgetState (5 variants), WidgetType (32 variants)
  ├── theme.rs            — Theme (style map) + WidgetStyle (6 fields)
  ├── containers.rs       — Panel, Layout (flexbox), ScrollPanel, NinePatch, GUIWindow, SplitPanel, DockPanel
  ├── controls.rs         — Button, Label, TextInput, CheckBox, Slider, ProgressBar, ComboBox, ListBox, TabBar, RadioButton, ScrollBar
  ├── extras.rs           — Toast, Separator, Spacer, TreeView, Toolbar, MenuBar, MenuItem, Dialog, StatusBar, Accordion, TooltipPanel, ColorPicker, GUITable, ImageWidget
  ├── context.rs          — GuiContext (flat widget pool), WidgetKind (32-variant enum), focus, input, toasts
  └── data_graph_renderer.rs — GraphRenderer + GraphSeries (line/scatter/bar chart data)
```

### Data Flow

```
Lua script                     gui module (CPU data)                  lua_api/gui_api.rs
───────────                    ────────────────────                   ──────────────────
luna.ui.newButton("OK")  →    GuiContext.add_button() → pool[idx]   → create_widget_table()
btn:setPosition(10, 20)   →    pool[idx].base.x/y = 10/20           → borrow_mut GuiContext
luna.ui.mousepressed(…)  →    GuiContext.mouse_pressed() → hit test → returns bool (consumed)
luna.ui.update(dt)       →    GuiContext.update(dt) → expire toasts
                                                                      → luna.gfx.* draws
```

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | Module root — re-exports all public types from submodules |
| `widget.rs` | Shared widget base fields (`WidgetBase`), visual state enum (`WidgetState`), and type tag enum (`WidgetType`) |
| `theme.rs` | Per-widget-type, per-state styling system: `Theme` maps `(WidgetType, WidgetState)` to `WidgetStyle` with fallback chain |
| `containers.rs` | Container and layout widgets: `Panel`, `Layout` (vertical/horizontal/grid with flexbox), `ScrollPanel`, `NinePatch` (nine-slice), `GUIWindow`, `SplitPanel`, `DockPanel` |
| `controls.rs` | Interactive control widgets: `Button`, `Label`, `TextInput` (with cursor), `CheckBox`, `Slider` (range + step snap), `ProgressBar`, `ComboBox`, `ListBox`, `TabBar`, `RadioButton`, `ScrollBar` |
| `extras.rs` | Utility and advanced widgets: `Toast` (timed notifications), `Separator`, `Spacer`, `TreeView`/`TreeNode`, `Toolbar`/`ToolbarButton`, `MenuBar`/`MenuItem`, `Dialog`, `StatusBar`, `Accordion`/`AccordionSection`, `TooltipPanel`, `ColorPicker`, `GUITable`/`TableColumn`, `ImageWidget` |
| `context.rs` | Central coordinator: `GuiContext` (widget pool, child management, focus cycling, toast queue, input routing), `WidgetKind` (type-erased enum wrapping all 32 widget types) |
| `data_graph_renderer.rs` | Data visualization: `GraphRenderer` for line/scatter/bar charts with viewport ↔ world mapping, `GraphSeries` enum |

## Submodules

### `gui::widget`

Shared widget base fields, state enum, and type tag. Every concrete widget embeds a `WidgetBase` that provides position, size, visibility, enable state, padding, margin, z-order, min/max size constraints, anchor edges, and flexbox layout properties. `WidgetState` models the five visual states a widget can be in, and `WidgetType` tags each concrete kind for theme style lookup.

- **`WidgetBase`** (struct): Shared properties embedded in every widget — position, size, visibility, enabled, state, tooltip, z-order, padding/margin arrays, min/max constraints, anchor edges, and flex factors.
- **`WidgetState`** (enum): Five visual states — Normal, Hovered, Pressed, Focused, Disabled. Supports `parse_str`/`as_str` round-tripping.
- **`WidgetType`** (enum): 32-variant type tag identifying widget kind for theme lookups. Supports `as_str` conversion.

### `gui::theme`

Per-widget-type, per-state styling system. A `Theme` maps `(WidgetType, WidgetState)` pairs to `WidgetStyle` records. Style lookup falls back: exact → Normal state → hard-coded default. The Lua API exposes `luna.ui.newTheme()`, `theme:setStyle()`, and `luna.ui.setTheme()`.

- **`WidgetStyle`** (struct): Visual style record with `bg_color`, `fg_color`, `border_color` (all `[f32;4]`), `border_width`, `corner_radius`, and `font_size`.
- **`Theme`** (struct): Style map with `set_style(type, state, style)` and `get_style(type, state)` with fallback chain.

### `gui::containers`

Container and layout widgets that hold child widgets and optionally apply layout rules. `Panel` is the simplest container. `Layout` adds flexbox-inspired positioning (vertical, horizontal, grid with spacing, alignment, wrapping). `ScrollPanel` provides a scrollable viewport. `NinePatch` computes nine-slice rectangles for scalable panel borders. `GUIWindow` adds a titled, draggable, resizable frame. `SplitPanel` divides into two resizable areas. `DockPanel` docks children to edges.

- **`Panel`** (struct): Basic container with optional title and scrollable flag, holding children by index.
- **`Layout`** (struct): Flexbox-like container with direction (vertical/horizontal/grid), spacing, columns, wrap, align, and justify. Has `perform_layout()` for child positioning.
- **`LayoutDirection`** (enum): Vertical, Horizontal, or Grid. Supports `parse_str`/`as_str`.
- **`ScrollPanel`** (struct): Scrollable viewport with `content_width`/`content_height`, scroll position, speed, and `clamp_scroll()`/`max_scroll()`.
- **`NinePatch`** (struct): Nine-slice border widget with pixel insets and `get_slices()` returning 9 source/dest rectangle tuples.
- **`NineSlice`** (type alias): `(f32, f32, f32, f32, f32, f32, f32, f32)` — (sx, sy, sw, sh, dx, dy, dw, dh).
- **`GUIWindow`** (struct): Windowed container with title, closeable, draggable, and resizable flags.
- **`SplitPanel`** (struct): Two-area resizable container with orientation, split position, and minimum panel size.
- **`DockPanel`** (struct): Edge-docking container with docked child/side pairs and split sizes.

### `gui::controls`

Interactive and display control widgets. Each widget embeds a `WidgetBase` for shared properties and adds type-specific data fields. Controls are leaf widgets that users interact with or display information.

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

### `gui::extras`

Utility and advanced widgets for auxiliary UI roles — visual dividers, empty spacing, timed notifications, collapsible trees, toolbars, menus, dialogs, data tables, and more.

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
- **`ColorPicker`** (struct): Color picker with RGBA components, alpha toggle, and mode (`"rgb"`, `"hsv"`, `"hsl"`).
- **`TableColumn`** (struct): Column definition with header text and pixel width.
- **`GUITable`** (struct): Data table with sortable columns, row data, and selected row index.
- **`ImageWidget`** (struct): Image display with scale mode (`"fit"`, `"fill"`, `"stretch"`, `"none"`) and RGBA tint.

### `gui::context`

Central coordinator for the GUI system. `GuiContext` owns the flat widget pool, provides factory methods for all 32 widget types, and handles child management, focus cycling, toast queue, and input event dispatch.

- **`WidgetKind`** (enum): 32-variant type-erased widget storage. Provides `base()`/`base_mut()` and `children()`/`children_mut()` accessors.
- **`GuiContext`** (struct): Root context holding `widgets` pool, `focused_widget`, `toasts` queue, and `theme`. Factory methods `add_*()` for every widget type. Child management: `add_child()`, `remove_child()`, `child_count()`. Focus: `set_focus()`, `focus_next()`, `focus_prev()`. Input: `mouse_pressed()`, `mouse_released()`, `mouse_moved()`, `key_pressed()`, `text_input()`, `wheel_moved()`. Toast: `add_toast()`, `toast_count()`, `update(dt)`. Search: `find_by_id()`.

### `gui::data_graph_renderer`

Data-only chart renderer managing named data series with viewport ↔ world coordinate mapping. Actual draw calls are issued externally by `graphics_api.rs`.

- **`GraphSeries`** (enum): Line (points + color), Scatter (points + color + size), or Bar (values + color) data series.
- **`GraphRenderer`** (struct): Chart renderer with viewport, range, named series, grid/axis/label toggles, colors, title, axis labels, and cursor. Methods: `add_line/scatter/bar_series()`, `auto_range()`, `world_to_screen()`, `screen_to_world()`.

## Key Types

### Structs

#### `gui::widget::WidgetBase`

Shared properties embedded in every widget. 24 fields: `id` (String), `widget_type` (WidgetType), `x`/`y`/`width`/`height` (f32), `visible`/`enabled` (bool), `state` (WidgetState), `tooltip` (String), `z_order` (i32), `padding`/`margin` ([f32;4]), `min_width`/`min_height`/`max_width`/`max_height` (f32), `anchor_left`/`anchor_top`/`anchor_right`/`anchor_bottom` (Option<f32>), `anchor_center_x`/`anchor_center_y` (Option<f32>), `flex_grow`/`flex_shrink` (f32). Methods: `new(WidgetType)`, `contains_point(px, py)`, `clear_anchors()`.

#### `gui::theme::WidgetStyle`

Visual style record: `bg_color`, `fg_color`, `border_color` (all `[f32;4]`), `border_width`, `corner_radius`, `font_size` (all `f32`). Default: dark gray bg, white fg, gray border, 1px border, 0 radius, 14px font.

#### `gui::theme::Theme`

Style map `HashMap<(WidgetType, WidgetState), WidgetStyle>`. Methods: `new()`, `set_style(widget_type, state, style)`, `get_style(widget_type, state)` with fallback chain (exact → Normal → default).

#### `gui::containers::Panel`

Basic container with `base`, `children` (Vec<usize>), `title` (String), `scrollable` (bool).

#### `gui::containers::Layout`

Flexbox-like container with `direction` (LayoutDirection), `spacing`, `columns`, `wrap`, `align`, `justify`. `perform_layout()` positions children.

#### `gui::containers::ScrollPanel`

Scrollable viewport with `content_width`/`content_height`, `scroll_x`/`scroll_y`, `scroll_speed`. Methods: `max_scroll()`, `clamp_scroll()`.

#### `gui::containers::NinePatch`

Nine-slice border widget with pixel insets (`inset_left`/`top`/`right`/`bottom`), image dimensions. `get_slices()` returns 9 source/dest tuples.

#### `gui::containers::GUIWindow`

Windowed container with `title`, `closeable`, `draggable`, `resizable`, and `children`.

#### `gui::containers::SplitPanel`

Two-area resizable container with `orientation`, `split_position`, `min_panel_size`, and first/second child indices.

#### `gui::containers::DockPanel`

Edge-docking container with `docked` pairs `(child_idx, side_string)` and `split_sizes`.

#### `gui::context::GuiContext`

Central coordinator: `widgets` (Vec<WidgetKind>), `focused_widget` (Option<usize>), `toasts` (Vec<Toast>), `theme` (Option<Theme>). 32 factory methods (`add_button`, `add_label`, etc.), child management, focus cycling, toast queue, input dispatch, widget search.

#### `gui::controls::Button`

Clickable button: `base` (WidgetBase), `text` (String).

#### `gui::controls::Label`

Static text display: `base` (WidgetBase), `text` (String).

#### `gui::controls::TextInput`

Single-line text field: `text`, `placeholder`, `max_length`, `cursor_pos`, `focused`. Methods: `insert_text()` (returns bool for max length check), `backspace()`.

#### `gui::controls::CheckBox`

Toggle control: `base`, `text`, `checked` (bool).

#### `gui::controls::Slider`

Range slider: `value`, `min`, `max`, `step` (all f64). `set_value()` clamps to range and snaps to step.

#### `gui::controls::ProgressBar`

Progress display: `value`, `min`, `max` (all f64). `progress()` returns 0.0–1.0 normalized fraction.

#### `gui::controls::ComboBox`

Drop-down selector: `items` (Vec<String>), `selected_index` (Option<usize>), `open` (bool). List management methods.

#### `gui::controls::ListBox`

Scrollable list: `items`, `selected_index`, `item_height`. List management methods.

#### `gui::controls::TabBar`

Tab strip: `tabs` (Vec<String>), `active_tab` (usize). `add_tab()`, `remove_tab()`.

#### `gui::controls::RadioButton`

Grouped radio: `text`, `selected`, `group` (String) for mutual exclusion.

#### `gui::controls::ScrollBar`

Scroll bar: `position`, `content_size`, `view_size` (f32), `vertical` (bool).

#### `gui::extras::Toast`

Timed notification: `message`, `duration`, `elapsed`. `progress()` returns 0.0–1.0, `is_expired()`, `update(dt)`.

#### `gui::extras::Separator`

Visual divider: `vertical` (bool), `thickness` (f32).

#### `gui::extras::Spacer`

Empty spacing: width and height set at construction via `WidgetBase`.

#### `gui::extras::TreeNode`

Tree hierarchy node: `text`, `icon` (Option), `children` (Vec<usize>), `expanded`, `parent` (Option<usize>).

#### `gui::extras::TreeView`

Collapsible tree: `nodes` (Vec<TreeNode>), `root_nodes`, `selected_node`. 15+ methods for node CRUD, expand/collapse, selection, and hierarchy queries.

#### `gui::extras::ToolbarButton`

Toolbar entry: `id`, `tooltip`, `enabled`, `toggled`.

#### `gui::extras::Toolbar`

Toolbar container: `orientation`, `children`, `buttons` (Vec<ToolbarButton>). `add_button()`, `add_separator()`, `add_spacer()`.

#### `gui::extras::MenuBar`

Top-level menu bar: `menus` (Vec<usize>) referencing MenuItem indices.

#### `gui::extras::MenuItem`

Menu item: `text`, `shortcut`, `checked`, `items` (Vec<usize>) for submenus.

#### `gui::extras::Dialog`

Modal/modeless dialog: `title`, `modal`, `open`, `content_idx` (Option<usize>), `footer_buttons` (Vec<String>).

#### `gui::extras::StatusBar`

Status bar: `sections` (Vec<(String, f32)>) — (text, width) pairs.

#### `gui::extras::AccordionSection`

Single collapsible section: `title`, `content_idx` (Option<usize>), `expanded`.

#### `gui::extras::Accordion`

Collapsible accordion: `sections` (Vec<AccordionSection>), `exclusive` (bool).

#### `gui::extras::TooltipPanel`

Rich tooltip: `text`, `delay` (f32 seconds), `target_idx` (Option<usize>).

#### `gui::extras::ColorPicker`

Color picker: `r`/`g`/`b`/`a` (f32), `show_alpha`, `color_mode` ("rgb"/"hsv"/"hsl").

#### `gui::extras::TableColumn`

Table column definition: `header` (String), `width` (f32).

#### `gui::extras::GUITable`

Data table: `columns` (Vec<TableColumn>), `rows` (Vec<Vec<String>>), `selected_row`, `sortable`.

#### `gui::extras::ImageWidget`

Image display: `scale_mode` ("fit"/"fill"/"stretch"/"none"), `tint` (f32, f32, f32, f32).

#### `gui::data_graph_renderer::GraphRenderer`

Chart renderer: viewport/range as `(f32,f32,f32,f32)`, `series` (HashMap), grid/axis/label toggles, colors, title, axis labels, cursor. Methods for series management, `auto_range()`, `world_to_screen()`, `screen_to_world()`.

### Enums

#### `gui::widget::WidgetState`

Visual state: `Normal`, `Hovered`, `Pressed`, `Focused`, `Disabled`. `parse_str(&str)` and `as_str()` for string conversion.

#### `gui::widget::WidgetType`

Type tag with 32 variants: Button, Label, TextInput, CheckBox, Slider, ProgressBar, ComboBox, ListBox, Panel, Layout, ScrollPanel, NinePatch, TabBar, Toast, Separator, Spacer, TreeView, RadioButton, ScrollBar, GUIWindow, SplitPanel, DockPanel, Toolbar, MenuBar, MenuItem, Dialog, StatusBar, Accordion, TooltipPanel, ColorPicker, GUITable, ImageWidget.

#### `gui::containers::LayoutDirection`

Layout direction: `Vertical`, `Horizontal`, `Grid`. `parse_str(&str)` and `as_str()` for string conversion.

#### `gui::data_graph_renderer::GraphSeries`

Data series: `Line { name, points, color }`, `Scatter { name, points, color, size }`, `Bar { name, values, color }`.

#### `gui::context::WidgetKind`

Type-erased widget storage with 32 variants wrapping all concrete widget types. Provides `base()`/`base_mut()` for accessing the embedded `WidgetBase`, and `children()`/`children_mut()` for container child access.

## Lua API

### `luna.ui` — Retained-mode widget UI system

Registered in `src/lua_api/gui_api.rs`.

#### Widget Constructors

| Function | Description |
|----------|-------------|
| `luna.ui.newButton(text?)` | Creates a button widget with optional text label |
| `luna.ui.newLabel(text?)` | Creates a label widget with optional text |
| `luna.ui.newTextInput()` | Creates a text input field |
| `luna.ui.newCheckbox(text?)` | Creates a checkbox with optional label |
| `luna.ui.newSlider(min?, max?)` | Creates a slider with optional range (default 0–1) |
| `luna.ui.newProgressBar(min?, max?)` | Creates a progress bar with optional range (default 0–1) |
| `luna.ui.newComboBox()` | Creates a combo box (drop-down selector) |
| `luna.ui.newList()` | Creates a list box |
| `luna.ui.newPanel()` | Creates a panel container |
| `luna.ui.newLayout(direction?)` | Creates a layout container (default `"vertical"`) |
| `luna.ui.newScrollPanel()` | Creates a scrollable panel |
| `luna.ui.newNinePatch()` | Creates a nine-patch (nine-slice) widget |
| `luna.ui.newTabBar()` | Creates a tab bar |
| `luna.ui.newSeparator(vertical?)` | Creates a separator (default horizontal) |
| `luna.ui.newSpacer(w?, h?)` | Creates a spacer with optional size |
| `luna.ui.newToast(message?, duration?)` | Creates a toast notification (default 3s) |
| `luna.ui.newTreeView()` | Creates a tree view |
| `luna.ui.newRadioButton(text?, group?)` | Creates a radio button with optional group |
| `luna.ui.newScrollBar(vertical?)` | Creates a scroll bar |
| `luna.ui.newWindow(title?)` | Creates a GUI window container |
| `luna.ui.newSplitPanel(orientation?)` | Creates a split panel |
| `luna.ui.newDockPanel()` | Creates a dock panel |
| `luna.ui.newToolbar(orientation?)` | Creates a toolbar |
| `luna.ui.newMenuBar()` | Creates a menu bar |
| `luna.ui.newMenuItem(text?)` | Creates a menu item |
| `luna.ui.newDialog(title?)` | Creates a dialog |
| `luna.ui.newStatusBar()` | Creates a status bar |
| `luna.ui.newAccordion()` | Creates an accordion |
| `luna.ui.newTooltipPanel(text?)` | Creates a tooltip panel |
| `luna.ui.newColorPicker()` | Creates a color picker |
| `luna.ui.newTable()` | Creates a data table |
| `luna.ui.newImageWidget()` | Creates an image display widget |
| `luna.ui.newTheme()` | Creates a new Theme userdata |

#### Base Widget Methods (all widgets)

| Method | Description |
|--------|-------------|
| `widget:setPosition(x, y)` | Sets widget position |
| `widget:getPosition()` | Returns x, y |
| `widget:setSize(w, h)` | Sets widget size |
| `widget:getSize()` | Returns width, height |
| `widget:setVisible(bool)` | Sets visibility |
| `widget:isVisible()` | Returns visibility |
| `widget:setEnabled(bool)` | Sets enabled state |
| `widget:isEnabled()` | Returns enabled state |
| `widget:setId(string)` | Sets widget identifier |
| `widget:getId()` | Returns widget identifier |
| `widget:setTooltip(string)` | Sets tooltip text |
| `widget:getTooltip()` | Returns tooltip text |
| `widget:getState()` | Returns widget state string |
| `widget:addChild(child)` | Adds a child widget |
| `widget:removeChild(child)` | Removes a child widget |
| `widget:getChildCount()` | Returns number of children |
| `widget:findById(id)` | Recursively searches for widget by id |
| `widget:containsPoint(x, y)` | Hit test |
| `widget:setPadding(t, r?, b?, l?)` | CSS-like padding |
| `widget:getPadding()` | Returns top, right, bottom, left |
| `widget:setMargin(t, r?, b?, l?)` | CSS-like margin |
| `widget:getMargin()` | Returns top, right, bottom, left |
| `widget:setZOrder(z)` | Sets z-order |
| `widget:getZOrder()` | Returns z-order |
| `widget:setMinSize(w, h)` | Sets minimum size |
| `widget:getMinSize()` | Returns min width, height |
| `widget:setMaxSize(w, h)` | Sets maximum size |
| `widget:getMaxSize()` | Returns max width, height |
| `widget:setAnchor(l?, t?, r?, b?)` | Sets anchor edges |
| `widget:setAnchorCenter(cx?, cy?)` | Sets center anchors |
| `widget:clearAnchor()` | Removes all anchors |
| `widget:setFlexGrow(n)` | Sets flex grow factor |
| `widget:getFlexGrow()` | Returns flex grow factor |
| `widget:setFlexShrink(n)` | Sets flex shrink factor |
| `widget:getFlexShrink()` | Returns flex shrink factor |
| `widget:setOnClick(fn)` | Stores click callback |
| `widget:setOnChange(fn)` | Stores change callback |
| `widget:setOnDraw(fn)` | Stores custom draw callback |

#### Context Functions

| Function | Description |
|----------|-------------|
| `luna.ui.getRoot()` | Returns the root panel widget |
| `luna.ui.setFocus(widget?)` | Sets or clears keyboard focus |
| `luna.ui.getFocus()` | Returns focused widget index or nil |
| `luna.ui.focusNext()` | Moves focus to next focusable widget |
| `luna.ui.focusPrev()` | Moves focus to previous focusable widget |
| `luna.ui.clearFocus()` | Clears keyboard focus |
| `luna.ui.getWidgetCount()` | Returns total widget count |
| `luna.ui.setTheme(theme)` | Sets the active GUI theme |
| `luna.ui.getTheme()` | Returns whether a theme is set |

#### Toast Management

| Function | Description |
|----------|-------------|
| `luna.ui.addToast(tbl)` | Queues a toast `{message=, duration=}` |
| `luna.ui.getToastCount()` | Returns active toast count |

#### Input Forwarding

| Function | Description |
|----------|-------------|
| `luna.ui.mousepressed(x, y, btn?)` | Forwards mouse press, returns consumed |
| `luna.ui.mousereleased(x, y, btn?)` | Forwards mouse release, returns consumed |
| `luna.ui.mousemoved(x, y)` | Forwards mouse move, returns consumed |
| `luna.ui.keypressed(key)` | Forwards key press, returns consumed |
| `luna.ui.textinput(text)` | Forwards text input, returns consumed |
| `luna.ui.wheelmoved(x, y)` | Forwards mouse wheel, returns consumed |
| `luna.ui.update(dt)` | Advances toast timers and cleans expired |

## Lua Examples

```lua
-- Create a simple button
local btn = luna.ui.newButton("Click Me")
btn:setPosition(100, 50)
btn:setSize(120, 40)
btn:setOnClick(function() print("clicked!") end)

-- Add to root panel
local root = luna.ui.getRoot()
root:addChild(btn)

-- Create a vertical layout with controls
local layout = luna.ui.newLayout("vertical")
layout:setPosition(10, 10)
layout:setSpacing(8)

local label = luna.ui.newLabel("Volume:")
local slider = luna.ui.newSlider(0, 100)
slider:setValue(75)

layout:addChild(label)
layout:addChild(slider)
root:addChild(layout)

-- Forward input events
function luna.mousepressed(x, y, btn)
    luna.ui.mousepressed(x, y, btn)
end

function luna.keypressed(key)
    luna.ui.keypressed(key)
end

function luna.process(dt)
    luna.ui.update(dt)
end
```

## Item Summary

| Category | Count |
|----------|-------|
| Structs | 39 |
| Enums | 5 |
| Functions (pub) | ~80 |
| Lua API functions | 33 constructors + 35 base methods + ~100 type-specific methods + 17 context/input functions |
| Rust test functions | 40+ |
| Lua test file | `tests/lua/unit/test_gui.lua` |

## References

- **Lua API binding**: `src/lua_api/gui_api.rs` — registration and per-widget-type method helpers
- **Rust tests**: `tests/rust/unit/gui_tests.rs` — unit tests for widgets, layout, theme, context
- **Lua tests**: `tests/lua/unit/test_gui.lua` — BDD tests for `luna.ui.*` API surface
- **GUI demo**: `demos/devtools_demo/` — developer tools panel demonstrating the GUI system
- **Architecture doc**: `docs/architecture/engine-architecture.md` § Tier 2

## Notes

- **No GPU dependency**: The gui module is pure CPU data. Rendering is delegated to `luna.gfx` calls in `gui_api.rs`.
- **Flat pool indexing**: All widgets are stored in a single `Vec<WidgetKind>` and referenced by `usize` index. Index 0 is always the root panel. This avoids lifetime complexity but means widget indices are invalidated if widgets are removed (currently removal is not supported — widgets are added only).
- **Input forwarding pattern**: Unlike auto-dispatched input, GUI input must be explicitly forwarded from `luna.mousepressed`/`luna.keypressed` callbacks. This lets scripts control which GUI instance receives events — useful for multiple GUI panels, pause menus, etc.
- **1-based Lua indices**: List/combo/tab/tree methods use 1-based indices on the Lua side, converting to 0-based internally.
- **Callbacks are stubs**: `setOnClick`, `setOnChange`, and `setOnDraw` currently accept callbacks but do not invoke them — they are placeholders for future event dispatch.
- **GraphRenderer**: The chart/graph system stores data only. Actual rendering of lines, bars, and axes is done by draw functions in `graphics_api.rs`, not in this module.
