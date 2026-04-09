# `gui` � Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 2 � Reusable Engine Extensions |
| **Status** | Implemented � Full |
| **Lua API** | `lurek.ui` |
| **Source** | `src/gui/` |
| **Rust Tests** | `tests/rust/unit/gui_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_gui.lua` |
| **Architecture** | Retained-mode flat widget pool with type-erased `WidgetKind` enum |

## Purpose

The `gui` module provides a retained-mode 2D widget system for building in-game menus, HUDs,
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
| `data_graph_renderer.rs` | Data visualization: `GraphRenderer` for line/scatter/bar charts with viewport - world mapping, `GraphSeries` enum |

## Key Types

| Type | Description |
|------|-------------|
| `Panel` | Principal type for the `gui` module. |
| `LayoutDirection` | Principal type for the `gui` module. |
| `Layout` | Principal type for the `gui` module. |
| `ScrollPanel` | Principal type for the `gui` module. |
| `NinePatch` | Principal type for the `gui` module. |
| `GUIWindow` | Principal type for the `gui` module. |
| `SplitPanel` | Principal type for the `gui` module. |
| `DockPanel` | Principal type for the `gui` module. |
| `GuiEvent` | Principal type for the `gui` module. |
| `WidgetKind` | Principal type for the `gui` module. |
| `GuiContext` | Principal type for the `gui` module. |
| `Button` | Principal type for the `gui` module. |

## Lua API Summary

| Function | Description |
|----------|-------------|
| `lurek.gui.newButton()` | See `docs/specs/gui.md`. |
| `lurek.gui.newLabel()` | See `docs/specs/gui.md`. |
| `lurek.gui.newTextInput()` | See `docs/specs/gui.md`. |
| `lurek.gui.newCheckbox()` | See `docs/specs/gui.md`. |
| `lurek.gui.newSlider()` | See `docs/specs/gui.md`. |
| `lurek.gui.newProgressBar()` | See `docs/specs/gui.md`. |
| `lurek.gui.newComboBox()` | See `docs/specs/gui.md`. |
| `lurek.gui.newList()` | See `docs/specs/gui.md`. |
| `lurek.gui.newPanel()` | See `docs/specs/gui.md`. |
| `lurek.gui.newLayout()` | See `docs/specs/gui.md`. |
| `lurek.gui.newScrollPanel()` | See `docs/specs/gui.md`. |
| `lurek.gui.newNinePatch()` | See `docs/specs/gui.md`. |
| `lurek.gui.newTabBar()` | See `docs/specs/gui.md`. |
| `lurek.gui.newSeparator()` | See `docs/specs/gui.md`. |
| `lurek.gui.newSpacer()` | See `docs/specs/gui.md`. |
| `lurek.gui.newToast()` | See `docs/specs/gui.md`. |
| `lurek.gui.newTreeView()` | See `docs/specs/gui.md`. |
| `lurek.gui.newRadioButton()` | See `docs/specs/gui.md`. |
| `lurek.gui.newScrollBar()` | See `docs/specs/gui.md`. |
| `lurek.gui.newWindow()` | See `docs/specs/gui.md`. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

� [`docs/specs/gui.md`](../../docs/specs/gui.md)

_Update both this file **and** `docs/specs/gui.md` whenever source files, public types, or Lua bindings change._
