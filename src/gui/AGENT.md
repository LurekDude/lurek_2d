# `gui` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 2 — Reusable Engine Extensions |
| **Status** | Implemented — Full |
| **Lua API** | `luna.gui` |
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
| `mod.rs` | Module root — re-exports all public types from submodules |
| `widget.rs` | Shared widget base fields (`WidgetBase`), visual state enum (`WidgetState`), and type tag enum (`WidgetType`) |
| `theme.rs` | Per-widget-type, per-state styling system: `Theme` maps `(WidgetType, WidgetState)` to `WidgetStyle` with fallback chain |
| `containers.rs` | Container and layout widgets: `Panel`, `Layout` (vertical/horizontal/grid with flexbox), `ScrollPanel`, `NinePatch` (nine-slice), `GUIWindow`, `SplitPanel`, `DockPanel` |
| `controls.rs` | Interactive control widgets: `Button`, `Label`, `TextInput` (with cursor), `CheckBox`, `Slider` (range + step snap), `ProgressBar`, `ComboBox`, `ListBox`, `TabBar`, `RadioButton`, `ScrollBar` |
| `extras.rs` | Utility and advanced widgets: `Toast` (timed notifications), `Separator`, `Spacer`, `TreeView`/`TreeNode`, `Toolbar`/`ToolbarButton`, `MenuBar`/`MenuItem`, `Dialog`, `StatusBar`, `Accordion`/`AccordionSection`, `TooltipPanel`, `ColorPicker`, `GUITable`/`TableColumn`, `ImageWidget` |
| `context.rs` | Central coordinator: `GuiContext` (widget pool, child management, focus cycling, toast queue, input routing), `WidgetKind` (type-erased enum wrapping all 32 widget types) |
| `data_graph_renderer.rs` | Data visualization: `GraphRenderer` for line/scatter/bar charts with viewport ↔ world mapping, `GraphSeries` enum |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`specs/gui.md`](../../specs/gui.md)

_Update both this file **and** `specs/gui.md` whenever source files, public types, or Lua bindings change._
