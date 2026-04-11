# `ui` � Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 2 � Reusable Engine Extensions |
| **Status** | Implemented � Full |
| **Lua API** | `lurek.ui` |
| **Source** | `src/ui/` |
| **Rust Tests** | `tests/rust/unit/gui_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_gui.lua` |
| **Architecture** | Retained-mode flat widget pool with type-erased `WidgetKind` enum |

## Purpose

The `ui` module provides a retained-mode 2D widget system for building in-game menus, HUDs,
dialog boxes, inventory screens, and developer tool panels. It is a Tier 2 Engine Extension
that depends only on `math` and `engine` (Baseline).

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | Module root � re-exports all public types from submodules |
| `widget.rs` | Shared widget base fields (`WidgetBase`), visual state enum (`WidgetState`), and type tag enum (`WidgetType`) |
| `theme.rs` | Per-widget-type, per-state styling system: `Theme` maps `(WidgetType, WidgetState)` to `WidgetStyle` with fallback chain |
| `containers.rs` | Container and layout widgets: `Panel`, `Layout` (vertical/horizontal/grid with flexbox), `ScrollPanel`, `NinePatch` (nine-slice), `GUIWindow`, `SplitPanel`, `DockPanel` |
| `controls.rs` | Interactive control widgets: `Button`, `Label`, `TextInput` (with cursor), `CheckBox`, `Slider` (range + step snap), `ProgressBar`, `ComboBox`, `ListBox`, `TabBar`, `RadioButton`, `ScrollBar` |
| `extras.rs` | Utility and advanced widgets: `Toast` (timed notifications), `Separator`, `Spacer`, `TreeView`/`TreeNode`, `Toolbar`/`ToolbarButton`, `MenuBar`/`MenuItem`, `Dialog`, `StatusBar`, `Accordion`/`AccordionSection`, `TooltipPanel`, `ColorPicker`, `GUITable`/`TableColumn`, `ImageWidget` |
| `context.rs` | Central coordinator: `GuiContext` (widget pool, child management, focus cycling, toast queue, input routing), `WidgetKind` (type-erased enum wrapping all 32 widget types) |
| `data_graph_renderer.rs` | Data visualization: `GraphRenderer` for line/scatter/bar charts with viewport↔world mapping, `GraphSeries` enum |
| `chart.rs`           | Configurable chart rendering to `ImageData`: line, bar, scatter, pie, and area charts with shared `ChartConfig`; no GPU dependency |
| `render.rs`          | Render command generation for the widget tree. `GuiContext::build_render_commands(font_key)` walks the tree depth-first emitting styled rectangles and text. `generate_render_commands()` is the zero-arg alias (uses `FontKey::default()`). `draw_to_image(w, h)` rasterises widget bounds CPU-side. |

## Key Types

| Type | Description |
|------|-------------|
| `Panel` | Principal type for the `ui` module. |
| `LayoutDirection` | Principal type for the `ui` module. |
| `Layout` | Principal type for the `ui` module. |
| `ScrollPanel` | Principal type for the `ui` module. |
| `NinePatch` | Principal type for the `ui` module. |
| `GUIWindow` | Principal type for the `ui` module. |
| `SplitPanel` | Principal type for the `ui` module. |
| `DockPanel` | Principal type for the `ui` module. |
| `GuiEvent` | Principal type for the `ui` module. |
| `WidgetKind` | Principal type for the `ui` module. |
| `GuiContext` | Principal type for the `ui` module. |
| `Button` | Principal type for the `ui` module. |

## Lua API Summary

| Function | Description |
|----------|-------------|
| `lurek.gui.newButton()` | See `docs/specs/ui.md`. |
| `lurek.gui.newLabel()` | See `docs/specs/ui.md`. |
| `lurek.gui.newTextInput()` | See `docs/specs/ui.md`. |
| `lurek.gui.newCheckbox()` | See `docs/specs/ui.md`. |
| `lurek.gui.newSlider()` | See `docs/specs/ui.md`. |
| `lurek.gui.newProgressBar()` | See `docs/specs/ui.md`. |
| `lurek.gui.newComboBox()` | See `docs/specs/ui.md`. |
| `lurek.gui.newList()` | See `docs/specs/ui.md`. |
| `lurek.gui.newPanel()` | See `docs/specs/ui.md`. |
| `lurek.gui.newLayout()` | See `docs/specs/ui.md`. |
| `lurek.gui.newScrollPanel()` | See `docs/specs/ui.md`. |
| `lurek.gui.newNinePatch()` | See `docs/specs/ui.md`. |
| `lurek.gui.newTabBar()` | See `docs/specs/ui.md`. |
| `lurek.gui.newSeparator()` | See `docs/specs/ui.md`. |
| `lurek.gui.newSpacer()` | See `docs/specs/ui.md`. |
| `lurek.gui.newToast()` | See `docs/specs/ui.md`. |
| `lurek.gui.newTreeView()` | See `docs/specs/ui.md`. |
| `lurek.gui.newRadioButton()` | See `docs/specs/ui.md`. |
| `lurek.gui.newScrollBar()` | See `docs/specs/ui.md`. |
| `lurek.gui.newWindow()` | See `docs/specs/ui.md`. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

� [`docs/specs/ui.md`](../../docs/specs/ui.md)

_Update both this file **and** `docs/specs/ui.md` whenever source files, public types, or Lua bindings change._
