# IDEA.md — `ui` module

| Field      | Value           |
| ---------- | --------------- |
| **Module** | `ui`            |
| **Path**   | `src/ui/`       |
| **Date**   | 2026-04-18      |
| **Tier**   | Feature Systems |

---

## Mission

Provide a retained-mode 2D widget system for in-game menus, HUDs, dialogs, inventories, and data visualisation. Widgets are styled via a `Theme` and rendered through the `RenderCommand` queue without direct GPU access.

## Strengths

- Comprehensive widget catalogue: 30+ widget types covering buttons, sliders, trees, tables, color pickers, accordions, dialogs, and charts.
- Clean separation: layout logic in pure Rust, Lua bridge thin, CPU-rendered chart system with no GPU dependency.
- Theme system with per-type per-state style lookup and dark-theme default.
- TOML layout loader enables declarative UI authoring and headless PNG evidence generation.

## Gaps

- No drag-and-drop between containers (inventory/card game pattern).
- No data-binding system (e.g. `widget:bind("score", playerData)`) — all widget state updates are manual.
- No world-space UI anchoring — all widgets are screen-space only.

## Features — Competitor Reference

| Feature                          | Status    | Competitor                                                         |
| -------------------------------- | --------- | ------------------------------------------------------------------ |
| Drag-and-drop between containers | ❌ Missing | LÖVE — Slab library, Godot — Control.drag_and_drop                 |
| Data binding for widget values   | ❌ Missing | Dear ImGui — automatic model reflection, Godot — property bindings |
| Widget animation/transitions     | ❌ Missing | Flutter — AnimatedWidget, Solar2D — transition.to on UI            |

## Performance / Quality

- Widget tree re-rendered every frame even when unchanged; retained dirty-flag diff would reduce CPU time.
- `perform_layout` in `Layout` iterates children linearly — adequate for typical game UIs.
- Chart renderer allocates per-draw — acceptable since charts are drawn infrequently.

## Test Gaps

- `context.rs` — newly added sibling `context_tests.rs` (10 tests); still needs input-routing and layout-pass coverage.
- `extras.rs` — newly added sibling `extras_tests.rs` (10 tests); TreeView multi-level operations untested.
- `chart.rs` — newly added inline tests; scatter and area chart draw paths not exercised.
- `layout_loader.rs` — newly added inline tests; nested children and render_to_image untested.

## TODO(dedup)

- `WidgetKind::base()` / `base_mut()` — 30+ match arms per method; macro or trait-based dispatch would reduce boilerplate.
- Chart types share identical grid/axis drawing; extract shared `draw_grid_and_axes` already exists but legend code is duplicated per chart type.

## TODO(helper)

- `emit_box` / `emit_text` / `emit_shadow` / `emit_highlight` in `render.rs` could be grouped into a `WidgetRenderer` struct for cleaner state.
- `safe_circle` helper in `chart.rs` duplicates bounds-checked pixel logic available in `ImageData`.

## TODO(plugin)

- `ui` is a plugin candidate under proposed constraint A-05 (see `docs/architecture/plugins.md`).
- Chart subsystem (`chart.rs`, `data_graph_renderer.rs`) could be split into a separate `ui-charts` feature flag.
- Layout loader (`layout_loader.rs`) has a `serde` + `toml` + `image` dependency set that could be gated.

## References

- `docs/specs/ui.md`
- `src/lua_api/ui_api.rs`
- `tests/rust/unit/gui_tests.rs`
- `tests/lua/unit/test_gui.lua`
