# ui

## Module Info
- Module name: `ui`
- Module group: `Feature Systems`
- Spec path: `docs/specs/ui.md`
- Lua API path(s): `src/lua_api/ui_api.rs`
- Rust test path(s): `tests/rust/unit/gui_tests.rs`
- Lua test path(s): `tests/lua/unit/test_gui.lua`, `tests/lua/integration/test_localization_ui.lua`

## Module Purpose
The `ui` module provides Lurek2D's retained-mode widget system for in-game menus, HUD panels, tool windows, dialogs, forms, data displays, and other 2D interface work. It stores widgets as CPU-side data, applies theme styling, manages focus and widget relationships, and produces render commands for the actual draw layer.

It exists so interface logic, widget composition, and layout behavior stay decoupled from game scripts and from the renderer. Scripts can assemble and drive UI state through the Lua bridge, while the Rust module owns the widget model, type-erased context, theme lookup, and shared behavior.

It intentionally does not own native OS widgets, window management, or raw input capture from the platform layer. It also does not rasterize fonts itself beyond delegating draw output; input events are routed into it by higher layers.

## Files
- `mod.rs` - Declares the UI submodules and re-exports the widget, context, theme, container, control, and chart-facing types.
- `chart.rs` - Generates CPU-rendered chart images for line, bar, scatter, pie, and area graphs without requiring the GPU path.
- `containers.rs` - Defines structural widgets such as panels, layouts, split views, scroll panels, windows, dock panels, and nine-patch containers.
- `context.rs` - Implements `GuiContext`, the retained widget pool, focus management, event routing, child relationships, and toast tracking.
- `controls.rs` - Defines common interactive widgets such as buttons, labels, text inputs, sliders, check boxes, combo boxes, list boxes, and progress bars.
- `data_graph_renderer.rs` - Implements data-series rendering helpers for charts and graph-style visualizations.
- `extras.rs` - Defines secondary widgets and utility components such as menus, toolbars, dialogs, tables, tree views, tooltips, accordions, image widgets, and toasts.
- `render.rs` - Walks UI state and theme data to produce render commands or CPU-side image output.
- `theme.rs` - Stores theme style maps, widget visual state, and fallback behavior for widget styling.
- `widget.rs` - Defines shared widget metadata and the broad widget-type and widget-state enums used across the module.

## Key Types
- `GuiContext` - The central retained-mode UI state container. It owns the widget pool, tree structure, focus bookkeeping, and event dispatch context.
- `WidgetKind` - A type-erased enum over all concrete widget variants stored in the `GuiContext` pool.
- `WidgetBase` - Shared geometry, visibility, spacing, anchoring, and flex-like metadata embedded in every widget.
- `WidgetType` - Identifies the broad widget class for styling and state-dependent behavior.
- `WidgetState` - Encodes common UI states such as normal, hovered, pressed, focused, and disabled.
- `Theme` - Stores widget styles keyed by widget type and state so the same UI tree can be skinned consistently.
- `WidgetStyle` - A concrete set of colors, borders, radius, and font-size values used by theme lookup.
- `Layout` - Flexible container widget for vertical, horizontal, and grid-style composition.
- `Panel` - Basic visual container for grouping child widgets.
- `ScrollPanel` - Container with scrolling behavior for content larger than its visible region.
- `GUIWindow` - Higher-level window container for movable or framed interface sections.
- `Button` - Clickable action widget.
- `Label` - Static text widget.
- `TextInput` - Editable single-line text field with cursor state.
- `Slider` - Numeric drag control.
- `ComboBox` - Drop-down selection control.
- `ListBox` - Multi-item selection list.
- `Toast` - Timed transient notification.
- `GraphRenderer` - Data visualization helper for graph and series rendering.
- `ChartConfig` - Configuration for chart image generation.
