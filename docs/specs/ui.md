# ui

## General Info

- Module group: `Feature Systems`
- Source path: `src/ui/`
- Lua API path(s): `src/lua_api/ui_api.rs`
- Primary Lua namespace: `lurek.ui`
- Rust test path(s): tests/rust/unit/gui_tests.rs
- Lua test path(s): tests/lua/unit/test_gui.lua, tests/lua/unit/test_ui_layout.lua, tests/lua/integration/test_i18n_ui.lua

## Summary

The `ui` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `image`, `math`, `render`, `runtime`. Its responsibility should stay inside the Feature Systems group rather than absorb behavior owned by those neighbors.

### 2026-05 UI Runtime Additions

- Added first-class widget transitions in core UI runtime:
	- timed alpha transitions and timed position transitions,
	- runtime helpers for start/cancel/query animation state.
- Added drag-and-drop reparenting between containers:
	- explicit drag lifecycle (`beginDrag`, `dropOn`, `endDrag`),
	- cycle-safe reparenting and parent detachment.
- Extended model binding sync:
	- number/text/bool binding values,
	- binding updates for slider/progress/spinbox/badge, label/button/text input/menu item, checkbox/switch, plus generic visibility.
- Improved render-cache invalidation:
	- `flushCache` now uses a lightweight widget-tree signature (position/size/state/topology) in addition to the dirty flag.

### 2026-05 UI Refactor Closure (IDEA.md)

- Reduced `WidgetKind::base` / `WidgetKind::base_mut` dispatch boilerplate in `src/ui/context.rs` via shared macro mapping.
- Introduced `WidgetRenderer` orchestration in `src/ui/render.rs` to keep root traversal/render pipeline setup separate from per-widget emission logic.
- Unified repeated chart legend/title fragments in `src/ui/chart.rs` through shared helper functions used by line/bar/scatter/pie/area renderers.
- No Lua API surface change in this pass; behavior is preserved while reducing maintenance duplication.

## Files

- `chart.rs`: Generates CPU-rendered chart images for line, bar, scatter, pie, and area graphs without requiring the GPU path.
- `containers.rs`: Defines structural widgets such as panels, layouts, split views, scroll panels, windows, dock panels, and nine-patch containers.
- `context.rs`: Implements `GuiContext`, the retained widget pool, focus management, event routing, child relationships, and toast tracking.
- `controls.rs`: Defines common interactive widgets such as buttons, labels, text inputs, sliders, check boxes, combo boxes, list boxes, and progress bars.
- `data_graph_renderer.rs`: Implements data-series rendering helpers for charts and graph-style visualizations.
- `extras.rs`: Defines secondary widgets and utility components such as menus, toolbars, dialogs, tables, tree views, tooltips, accordions, image widgets, and toasts.
- `layout_loader.rs`: Implements pure-Rust layout definition loading (`WidgetDef` / TOML) and a headless software PNG rasteriser for test evidence generation.
- `mod.rs`: Declares the UI submodules and re-exports the widget, context, theme, container, control, and chart-facing types.
- `render.rs`: Walks UI state and theme data to produce runtime render commands for every built-in widget and a CPU-side `drawToImage()` helper used by evidence tests.
- `theme.rs`: Stores theme style maps, widget visual state, and the built-in `Theme::default_dark()` skin that covers every built-in widget type.
- `widget.rs`: Defines shared widget metadata and the broad widget-type and widget-state enums used across the module.

## Types

- `ChartConfig` (`struct`, `chart.rs`): Configuration for chart image generation.
- `ChartMargin` (`struct`, `chart.rs`): Pixel margins around the chart plot area.
- `ChartSeries` (`struct`, `chart.rs`): A named data series with colour.
- `LineChart` (`struct`, `chart.rs`): A configurable line chart renderer.
- `BarCategory` (`struct`, `chart.rs`): A single category group in a bar chart.
- `BarChart` (`struct`, `chart.rs`): A configurable grouped bar chart renderer.
- `ScatterPlot` (`struct`, `chart.rs`): A configurable scatter plot renderer.
- `PieSegment` (`struct`, `chart.rs`): A segment in a pie chart.
- `PieChart` (`struct`, `chart.rs`): A configurable pie chart renderer.
- `AreaChart` (`struct`, `chart.rs`): A configurable stacked area chart renderer.
- `AreaLayer` (`struct`, `chart.rs`): A single layer in an area chart.
- `Panel` (`struct`, `containers.rs`): Basic visual container for grouping child widgets.
- `LayoutDirection` (`enum`, `containers.rs`): Direction in which a [`Layout`] positions its children.
- `Layout` (`struct`, `containers.rs`): Flexible container widget for vertical, horizontal, and grid-style composition.
- `ScrollPanel` (`struct`, `containers.rs`): Container with scrolling behavior for content larger than its visible region.
- `NineSlice` (`type`, `containers.rs`): A nine-slice rectangle: `(sx, sy, sw, sh, dx, dy, dw, dh)`.
- `NinePatch` (`struct`, `containers.rs`): Nine-slice data for scalable panel border rendering.
- `GUIWindow` (`struct`, `containers.rs`): Higher-level window container for movable or framed interface sections.
- `SplitPanel` (`struct`, `containers.rs`): A resizable split panel with two child regions.
- `DockPanel` (`struct`, `containers.rs`): A dock-based layout container with left/right/top/bottom/center regions.
- `UiBindingValue` (`enum`, `context.rs`): A typed binding value that can be pushed into widgets via `update_bindings`.
- `GuiEvent` (`enum`, `context.rs`): A single interaction event emitted by the GUI widget tree.
- `WidgetKind` (`enum`, `context.rs`): A type-erased enum over all concrete widget variants stored in the `GuiContext` pool.
- `GuiContext` (`struct`, `context.rs`): The central retained-mode UI state container. It owns the widget pool, tree structure, focus bookkeeping, and event dispatch context.
- `Button` (`struct`, `controls.rs`): Clickable action widget.
- `Label` (`struct`, `controls.rs`): Static text widget.
- `TextInput` (`struct`, `controls.rs`): Editable single-line text field with cursor state.
- `CheckBox` (`struct`, `controls.rs`): Toggle check-box widget with an associated label.
- `Slider` (`struct`, `controls.rs`): Numeric drag control.
- `ProgressBar` (`struct`, `controls.rs`): Read-only progress indicator widget.
- `ComboBox` (`struct`, `controls.rs`): Drop-down selection control.
- `ListBox` (`struct`, `controls.rs`): Multi-item selection list.
- `TabBar` (`struct`, `controls.rs`): Tabbed page selector widget.
- `RadioButton` (`struct`, `controls.rs`): A grouped radio button with mutually exclusive selection.
- `ScrollBar` (`struct`, `controls.rs`): A scroll bar for scrollable content areas.
- `SpinBox` (`struct`, `controls.rs`): A numeric spin box: a text field with increment and decrement buttons.
- `Switch` (`struct`, `controls.rs`): A binary toggle switch rendered as a pill with a sliding thumb.
- `GraphSeries` (`enum`, `data_graph_renderer.rs`): A data series that can be added to a [`GraphRenderer`].
- `GraphRenderer` (`struct`, `data_graph_renderer.rs`): Data visualization helper for graph and series rendering.
- `Toast` (`struct`, `extras.rs`): Timed transient notification.
- `Separator` (`struct`, `extras.rs`): Visual divider line widget.
- `Spacer` (`struct`, `extras.rs`): Empty layout filler widget.
- `TreeNode` (`struct`, `extras.rs`): A single node in a [`TreeView`] hierarchy.
- `TreeView` (`struct`, `extras.rs`): Collapsible hierarchical tree widget.
- `ToolbarButton` (`struct`, `extras.rs`): A named action button entry in a [`Toolbar`].
- `Toolbar` (`struct`, `extras.rs`): A toolbar container for buttons and separators.
- `MenuBar` (`struct`, `extras.rs`): A horizontal menu bar.
- `MenuItem` (`struct`, `extras.rs`): A menu item usable in menus and context menus.
- `Dialog` (`struct`, `extras.rs`): A modal dialog window.
- `StatusBar` (`struct`, `extras.rs`): A status bar with named sections.
- `AccordionSection` (`struct`, `extras.rs`): A single section in an [`Accordion`].
- `Accordion` (`struct`, `extras.rs`): A collapsible accordion container with named sections.
- `TooltipPanel` (`struct`, `extras.rs`): A rich tooltip panel attached to a target widget.
- `ColorPicker` (`struct`, `extras.rs`): A color picker widget with RGB/HSV/HSL modes.
- `TableColumn` (`struct`, `extras.rs`): A single column in a [`GUITable`].
- `GUITable` (`struct`, `extras.rs`): A data table widget with sortable columns and selectable rows.
- `ImageWidget` (`struct`, `extras.rs`): An image display widget.
- `Badge` (`struct`, `extras.rs`): A notification badge displaying a numeric count or short label.
- `CustomWidget` (`struct`, `extras.rs`): A fully Lua-driven widget with custom rendering.
- `WidgetDef` (`struct`, `layout_loader.rs`): Tree node describing a single widget and its optional children.
- `LayoutDef` (`struct`, `layout_loader.rs`): Top-level TOML layout descriptor.
- `WidgetStyle` (`struct`, `theme.rs`): A concrete set of colors, borders, radius, and font-size values used by theme lookup.
- `Theme` (`struct`, `theme.rs`): Stores widget styles keyed by widget type and state so the same UI tree can be skinned consistently.
- `WidgetState` (`enum`, `widget.rs`): Encodes common UI states such as normal, hovered, pressed, focused, and disabled.
- `WidgetType` (`enum`, `widget.rs`): Identifies the broad widget class for styling and state-dependent behavior.
- `WidgetTransitionKind` (`enum`, `widget.rs`): Which property a `WidgetTransition` animates.
- `WidgetTransition` (`struct`, `widget.rs`): Active animation on a `WidgetBase`; evaluated each frame by `GuiContext::update`.
- `WidgetBase` (`struct`, `widget.rs`): Shared geometry, visibility, spacing, anchoring, and flex-like metadata embedded in every widget.

## Functions

- `LineChart::new` (`chart.rs`): Create a new line chart with the given config and default Y/X range of 100.0/6.0.
- `LineChart::add_series` (`chart.rs`): Append a named data series of `(x, y)` points with the given colour.
- `LineChart::draw_to_image` (`chart.rs`): Rasterise the line chart into `img`, overwriting its contents.
- `BarChart::new` (`chart.rs`): Create an empty bar chart with the given config and default Y max of 100.0.
- `BarChart::add_series` (`chart.rs`): Register a named series with the given colour; call before `add_category`.
- `BarChart::add_category` (`chart.rs`): Add a labelled category group with one value per series.
- `BarChart::draw_to_image` (`chart.rs`): Rasterise the bar chart into `img`, overwriting its contents.
- `ScatterPlot::new` (`chart.rs`): Create an empty scatter plot with the given config and default axis ranges of (0.0, 1.0).
- `ScatterPlot::add_series` (`chart.rs`): Append a named series of `(x, y)` scatter points with the given colour.
- `ScatterPlot::draw_to_image` (`chart.rs`): Rasterise the scatter plot into `img`, overwriting its contents.
- `PieChart::new` (`chart.rs`): Create an empty pie chart with the given config.
- `PieChart::add_segment` (`chart.rs`): Append a labelled segment with the given value and fill colour.
- `PieChart::draw_to_image` (`chart.rs`): Rasterise the pie chart into `img`, overwriting its contents; no-ops when total value <= 0.
- `AreaChart::new` (`chart.rs`): Create an empty area chart with the given config and Y max of 100.0.
- `AreaChart::add_layer` (`chart.rs`): Append a named area layer; `values` are sampled at uniform X intervals across the chart width.
- `AreaChart::draw_to_image` (`chart.rs`): Rasterise the stacked area chart into `img`, overwriting its contents.
- `Panel::new` (`containers.rs`): Create an empty panel with no title and scrolling disabled.
- `LayoutDirection::parse_str` (`containers.rs`): Parse a lowercase string to a variant; return `None` for unrecognised values.
- `LayoutDirection::as_str` (`containers.rs`): Return the canonical lowercase string representation of this variant.
- `Layout::new` (`containers.rs`): Create a layout with the given direction; sets spacing=0, columns=1, wrap=false.
- `Layout::perform_layout` (`containers.rs`): Apply this layout's direction and spacing to position the given widget bases in-place.
- `ScrollPanel::new` (`containers.rs`): Create a scroll panel with default content size 100×100 and scroll_speed 20.
- `ScrollPanel::max_scroll` (`containers.rs`): Return `(max_scroll_x, max_scroll_y)` derived from content and widget dimensions.
- `ScrollPanel::clamp_scroll` (`containers.rs`): Clamp `scroll_x` and `scroll_y` to the valid `[0, max_scroll]` range.
- `NinePatch::new` (`containers.rs`): Create a nine-patch widget with zero insets and zero source image size.
- `NinePatch::get_slices` (`containers.rs`): Return the 9 `NineSlice` tuples describing source and destination rects for each patch region.
- `GUIWindow::new` (`containers.rs`): Create a window with the given title; closeable and draggable by default, not resizable.
- `SplitPanel::new` (`containers.rs`): Create a split panel with the given orientation; split_position defaults to 0.5.
- `DockPanel::new` (`containers.rs`): Create an empty dock panel with no docked children.
- `WidgetKind::base` (`context.rs`): Return a shared reference to the common `WidgetBase` of any variant.
- `WidgetKind::base_mut` (`context.rs`): Return a mutable reference to the common `WidgetBase` of any variant.
- `WidgetKind::children` (`context.rs`): Return a shared reference to the child-index list for container variants; `None` for leaf widgets.
- `WidgetKind::children_mut` (`context.rs`): Return a mutable reference to the child-index list for container variants; `None` for leaf widgets.
- `GuiContext::new` (`context.rs`): Create a new context with a root panel, default dark theme, and dirty=true.
- `GuiContext::widget_count` (`context.rs`): Return the total number of widgets including the root panel.
- `GuiContext::drain_events` (`context.rs`): Drain and return all pending events accumulated since the last call.
- `GuiContext::run_layout_pass` (`context.rs`): Recursively compute and write `computed_rect` and `is_visible` for all widgets from root.
- `GuiContext::add_button` (`context.rs`): Add a `Button` widget and return its index.
- `GuiContext::add_label` (`context.rs`): Add a `Label` widget and return its index.
- `GuiContext::add_text_input` (`context.rs`): Add a `TextInput` widget and return its index.
- `GuiContext::add_checkbox` (`context.rs`): Add a `CheckBox` widget with the given label and return its index.
- `GuiContext::add_slider` (`context.rs`): Add a `Slider` widget with the given value range and return its index.
- `GuiContext::add_progress_bar` (`context.rs`): Add a `ProgressBar` widget with the given value range and return its index.
- `GuiContext::add_combo_box` (`context.rs`): Add a `ComboBox` widget and return its index.
- `GuiContext::add_list_box` (`context.rs`): Add a `ListBox` widget and return its index.
- `GuiContext::add_panel` (`context.rs`): Add a `Panel` container and return its index.
- `GuiContext::add_layout` (`context.rs`): Add a `Layout` container with the given direction and return its index.
- `GuiContext::add_scroll_panel` (`context.rs`): Add a `ScrollPanel` container and return its index.
- `GuiContext::add_nine_patch` (`context.rs`): Add a `NinePatch` widget and return its index.
- `GuiContext::add_tab_bar` (`context.rs`): Add a `TabBar` widget and return its index.
- `GuiContext::add_separator` (`context.rs`): Add a `Separator` widget (horizontal or vertical) and return its index.
- `GuiContext::add_spacer` (`context.rs`): Add a `Spacer` widget with the given dimensions and return its index.
- `GuiContext::add_tree_view` (`context.rs`): Add a `TreeView` widget and return its index.
- `GuiContext::add_radio_button` (`context.rs`): Add a `RadioButton` with the given label and group name and return its index.
- `GuiContext::add_scroll_bar` (`context.rs`): Add a `ScrollBar` (horizontal or vertical) and return its index.
- `GuiContext::add_gui_window` (`context.rs`): Add a `GUIWindow` with the given title and return its index.
- `GuiContext::add_split_panel` (`context.rs`): Add a `SplitPanel` with the given orientation and return its index.
- `GuiContext::add_dock_panel` (`context.rs`): Add a `DockPanel` container and return its index.
- `GuiContext::add_toolbar` (`context.rs`): Add a `Toolbar` with the given orientation and return its index.
- `GuiContext::add_menu_bar` (`context.rs`): Add a `MenuBar` and return its index.
- `GuiContext::add_menu_item` (`context.rs`): Add a `MenuItem` with the given label and return its index.
- `GuiContext::add_dialog` (`context.rs`): Add a `Dialog` with the given title and return its index.
- `GuiContext::add_status_bar` (`context.rs`): Add a `StatusBar` and return its index.
- `GuiContext::add_accordion` (`context.rs`): Add an `Accordion` container and return its index.
- `GuiContext::add_tooltip_panel` (`context.rs`): Add a `TooltipPanel` with the given text and return its index.
- `GuiContext::add_color_picker` (`context.rs`): Add a `ColorPicker` widget and return its index.
- `GuiContext::add_gui_table` (`context.rs`): Add a `GUITable` widget and return its index.
- `GuiContext::add_image_widget` (`context.rs`): Add an `ImageWidget` and return its index; also marks context dirty.
- `GuiContext::add_spin_box` (`context.rs`): Add a `SpinBox` with the given value range and return its index; marks dirty.
- `GuiContext::add_switch` (`context.rs`): Add a `Switch` with the given initial on state and return its index; marks dirty.
- `GuiContext::add_badge` (`context.rs`): Add a `Badge` with the given count and return its index; marks dirty.
- `GuiContext::add_custom_widget` (`context.rs`): Add a `CustomWidget` and return its index; marks dirty.
- `GuiContext::set_default_theme` (`context.rs`): Reset to the built-in dark theme and mark dirty.
- `GuiContext::set_viewport` (`context.rs`): Set the viewport size used for root-relative layout; marks dirty.
- `GuiContext::flush_cache` (`context.rs`): Return `true` if the widget tree has changed since the last call; resets `dirty` and updates the render signature.
- `GuiContext::begin_drag` (`context.rs`): Start a drag operation on `widget_idx`; return `false` if the index is invalid or is the root.
- `GuiContext::active_drag` (`context.rs`): Return the widget index currently being dragged, if any.
- `GuiContext::end_drag` (`context.rs`): End the current drag operation and return the dragged widget index, if any.
- `GuiContext::drop_on` (`context.rs`): Drop the active dragged widget onto `target_idx`; returns `false` if target is not a container or would create a cycle.
- `GuiContext::animate_alpha` (`context.rs`): Queue an alpha tween on `widget_idx` from its current alpha to `to_alpha` over `duration` seconds; returns `false` on invalid index.
- `GuiContext::animate_position` (`context.rs`): Queue a position tween on `widget_idx` from its current position to `(to_x, to_y)` over `duration` seconds.
- `GuiContext::cancel_animations` (`context.rs`): Clear all pending transitions on `widget_idx`; returns `false` on invalid index.
- `GuiContext::is_animating` (`context.rs`): Return `true` if `widget_idx` has at least one active transition.
- `GuiContext::update_bindings` (`context.rs`): Apply `values` to bound widgets; return the number of widgets whose state changed.
- `GuiContext::add_child` (`context.rs`): Append `child_idx` to `parent_idx`'s child list if it is a container; return `false` on invalid indices or non-container.
- `GuiContext::remove_child` (`context.rs`): Remove `child_idx` from `parent_idx`'s child list; return `false` if not found.
- `GuiContext::child_count` (`context.rs`): Return the number of direct children of `widget_idx`; 0 for leaf widgets or invalid index.
- `GuiContext::set_focus` (`context.rs`): Move focus to `widget_idx`, updating `WidgetState` for the previous and new focused widgets.
- `GuiContext::focus_next` (`context.rs`): Advance focus to the next visible enabled widget, wrapping around.
- `GuiContext::focus_prev` (`context.rs`): Move focus to the previous visible enabled widget, wrapping around.
- `GuiContext::add_toast` (`context.rs`): Push a toast message into the overlay queue.
- `GuiContext::toast_count` (`context.rs`): Return the number of active toast messages.
- `GuiContext::update` (`context.rs`): Advance toast timers, expire old toasts, and step all active widget transitions by `dt` seconds.
- `GuiContext::find_by_id` (`context.rs`): Search the subtree rooted at `start_idx` for a widget whose `id` matches; return its index or `None`.
- `GuiContext::mouse_pressed` (`context.rs`): Process a mouse button press at `(x, y)`; return `true` if any widget consumed it.
- `GuiContext::mouse_released` (`context.rs`): Process a mouse button release at `(x, y)`; fires `Click` events on clickable widgets.
- `GuiContext::mouse_moved` (`context.rs`): Process a mouse move to `(x, y)`; updates `Hovered`/`Normal` states; return `true` on any state change.
- `GuiContext::key_pressed` (`context.rs`): Process a key press by name; `"tab"` advances focus, `"backspace"` deletes in focused text input.
- `GuiContext::text_input` (`context.rs`): Insert `text` into the focused `TextInput`; return `true` if consumed.
- `GuiContext::wheel_moved` (`context.rs`): Scroll the focused `ScrollPanel` by `y` lines; return `true` if consumed.
- `Button::new` (`controls.rs`): Create a button with the given text.
- `Label::new` (`controls.rs`): Create a label with the given text.
- `TextInput::new` (`controls.rs`): Create an empty text input with no placeholder and unlimited length.
- `TextInput::insert_text` (`controls.rs`): Insert `input` at the cursor position; return `false` if it would exceed `max_length`.
- `TextInput::backspace` (`controls.rs`): Delete the character before the cursor; return `false` if already at position 0.
- `CheckBox::new` (`controls.rs`): Create an unchecked checkbox with the given label.
- `Slider::new` (`controls.rs`): Create a slider with the given range; initial value is `min`, step defaults to 0 (continuous).
- `Slider::set_value` (`controls.rs`): Clamp `v` to `[min, max]` and snap to the nearest step if step > 0.
- `ProgressBar::new` (`controls.rs`): Create a progress bar with the given range; initial value is `min`.
- `ProgressBar::progress` (`controls.rs`): Return the normalised fill fraction in `[0.0, 1.0]`; returns 0.0 when `max == min`.
- `ComboBox::new` (`controls.rs`): Create an empty combo box with no selection.
- `ComboBox::add_item` (`controls.rs`): Append a new item to the drop-down list.
- `ComboBox::remove_item` (`controls.rs`): Remove the item at `index` from ComboBox; adjusts `selected_index`; return `false` when out of range.
- `ComboBox::clear` (`controls.rs`): Remove all items and reset selection for ComboBox.
- `ComboBox::selected_item` (`controls.rs`): Return the text of the selected ComboBox item, or `None`.
- `ListBox::new` (`controls.rs`): Create an empty list box with item_height=24.
- `ListBox::add_item` (`controls.rs`): Append a new item to the ListBox.
- `ListBox::remove_item` (`controls.rs`): Remove the item at `index` from the ListBox; adjusts `selected_index`; return `false` when out of range.
- `ListBox::clear` (`controls.rs`): Remove all items and reset selection for ListBox.
- `ListBox::selected_item` (`controls.rs`): Return the text of the selected ListBox item, or `None`.
- `TabBar::new` (`controls.rs`): Create an empty tab bar with active_tab=0.
- `TabBar::add_tab` (`controls.rs`): Append a tab with the given label.
- `TabBar::remove_tab` (`controls.rs`): Remove the tab at `index`; clamps `active_tab` to the new length; return `false` when out of range.
- `RadioButton::new` (`controls.rs`): Create an unselected radio button with the given label and group.
- `ScrollBar::new` (`controls.rs`): Create a scroll bar with content_size=100 and view_size=50.
- `SpinBox::new` (`controls.rs`): Create a spin box clamped to `[min, max]` with step=1.0; initial value is `min`.
- `SpinBox::set_value` (`controls.rs`): Snap `v` to the nearest step and clamp to `[min, max]`.
- `SpinBox::increment` (`controls.rs`): Increase value by one step.
- `SpinBox::decrement` (`controls.rs`): Decrease value by one step.
- `SpinBox::set_range` (`controls.rs`): Update the allowed range and re-clamp the current value.
- `Switch::new` (`controls.rs`): Create a switch with the given initial state; sets `thumb_t` accordingly.
- `Switch::toggle` (`controls.rs`): Flip the on/off state and snap `thumb_t` to the new position.
- `Switch::set_on` (`controls.rs`): Set `on` to the given value and snap `thumb_t`.
- `GraphSeries::name` (`data_graph_renderer.rs`): Return the series name shared across all variants.
- `GraphRenderer::new` (`data_graph_renderer.rs`): Create a renderer with a 400×300 viewport, range (-10, 10, -10, 10), and dark colour defaults.
- `GraphRenderer::set_viewport` (`data_graph_renderer.rs`): Set the screen-space viewport rect `(x, y, w, h)` for this renderer.
- `GraphRenderer::get_viewport` (`data_graph_renderer.rs`): Return the current viewport as `(x, y, w, h)`.
- `GraphRenderer::set_range` (`data_graph_renderer.rs`): Override the axis range with explicit `(x_min, x_max, y_min, y_max)` values.
- `GraphRenderer::get_range` (`data_graph_renderer.rs`): Return the current axis range as `(x_min, x_max, y_min, y_max)`.
- `GraphRenderer::auto_range` (`data_graph_renderer.rs`): Compute and apply a tight range from all loaded series, padded by 10%; no-ops when series are empty.
- `GraphRenderer::add_line_series` (`data_graph_renderer.rs`): Insert or replace a line series with the given name, points, and colour.
- `GraphRenderer::add_scatter_series` (`data_graph_renderer.rs`): Insert or replace a scatter series with the given name, points, colour, and dot size.
- `GraphRenderer::add_bar_series` (`data_graph_renderer.rs`): Insert or replace a bar series with the given name, bar heights, and colour.
- `GraphRenderer::remove_series` (`data_graph_renderer.rs`): Remove the series with the given name; return `false` if not found.
- `GraphRenderer::clear_series` (`data_graph_renderer.rs`): Remove all series.
- `GraphRenderer::get_series_names` (`data_graph_renderer.rs`): Return all current series names in arbitrary order.
- `GraphRenderer::series` (`data_graph_renderer.rs`): Return a shared reference to the internal series map.
- `GraphRenderer::set_show_grid` (`data_graph_renderer.rs`): Set whether grid lines are drawn.
- `GraphRenderer::set_show_axes` (`data_graph_renderer.rs`): Set whether axis lines are drawn.
- `GraphRenderer::set_show_labels` (`data_graph_renderer.rs`): Set whether numeric axis tick labels are drawn.
- `GraphRenderer::set_grid_color` (`data_graph_renderer.rs`): Set the grid line colour.
- `GraphRenderer::set_axis_color` (`data_graph_renderer.rs`): Set the axis line colour.
- `GraphRenderer::set_bg_color` (`data_graph_renderer.rs`): Set the background fill colour.
- `GraphRenderer::set_title` (`data_graph_renderer.rs`): Set the chart title text.
- `GraphRenderer::set_axis_labels` (`data_graph_renderer.rs`): Set the X and Y axis annotation labels.
- `GraphRenderer::set_cursor_position` (`data_graph_renderer.rs`): Set the hover cursor world-space position shown as a crosshair overlay.
- `GraphRenderer::get_cursor_value` (`data_graph_renderer.rs`): Return the current cursor world-space position, or `None` if unset.
- `GraphRenderer::world_to_screen` (`data_graph_renderer.rs`): Map world-space `(wx, wy)` to screen-space pixel coordinates within the viewport.
- `GraphRenderer::screen_to_world` (`data_graph_renderer.rs`): Map screen-space pixel coordinates back to world-space `(wx, wy)`.
- `Toast::new` (`extras.rs`): Create a toast with the given message and display duration in seconds.
- `Toast::progress` (`extras.rs`): Return the normalised progress in `[0.0, 1.0]`; returns 1.0 when `duration <= 0`.
- `Toast::is_expired` (`extras.rs`): Return `true` if `elapsed >= duration`.
- `Toast::update` (`extras.rs`): Advance elapsed time by `dt` seconds.
- `Separator::new` (`extras.rs`): Create a separator with the given orientation; defaults to 1px thickness.
- `Spacer::new` (`extras.rs`): Create a spacer with the given pixel dimensions.
- `TreeNode::new` (`extras.rs`): Create a leaf node with the given text and optional parent index; initially collapsed.
- `TreeView::new` (`extras.rs`): Create an empty tree view with no nodes.
- `TreeView::add_node` (`extras.rs`): Add a node under `parent_index` (or as root if `None`); return the new node index.
- `TreeView::toggle_node` (`extras.rs`): Toggle expanded state of node `index`; return `false` if index is out of range.
- `TreeView::node_count` (`extras.rs`): Return the total node count.
- `TreeView::remove_node` (`extras.rs`): Remove node at `index`, re-linking parent/children and remapping indices; return `false` when out of range.
- `TreeView::clear_nodes` (`extras.rs`): Remove all nodes and reset selection.
- `TreeView::get_node_text` (`extras.rs`): Return the text of node `index`, or `None` if out of range.
- `TreeView::set_node_text` (`extras.rs`): Set the text of node `index`; return `false` if out of range.
- `TreeView::set_node_icon` (`extras.rs`): Set the icon path of node `index`; empty string clears the icon; return `false` if out of range.
- `TreeView::expand_node` (`extras.rs`): Force expand node `index`; return `false` if out of range.
- `TreeView::collapse_node` (`extras.rs`): Force collapse node `index`; return `false` if out of range.
- `TreeView::is_node_expanded` (`extras.rs`): Return the expanded state of node `index`, or `None` if out of range.
- `TreeView::expand_all` (`extras.rs`): Set all nodes expanded.
- `TreeView::collapse_all` (`extras.rs`): Set all nodes collapsed.
- `TreeView::set_selected_node` (`extras.rs`): Select node `index`; return `false` and clear selection if out of range.
- `TreeView::get_selected_node` (`extras.rs`): Return the selected node index, or `None` when nothing is selected.
- `TreeView::get_child_nodes` (`extras.rs`): Return the slice of child indices for node `index`, or `None` if out of range.
- `TreeView::get_parent_node` (`extras.rs`): Return the parent index (wrapped in `Some`) for node `index`, or `None` if out of range.
- `TreeView::get_node_depth` (`extras.rs`): Return the depth of node `index` in the tree (root = 0), or `None` if out of range or cycle detected.
- `ToolbarButton::new` (`extras.rs`): Create an enabled, non-toggled button with the given id and tooltip.
- `Toolbar::new` (`extras.rs`): Create an empty toolbar with the given orientation.
- `Toolbar::add_button` (`extras.rs`): Add a button with `id` and `tooltip` if not already present; return its index.
- `Toolbar::add_separator` (`extras.rs`): Add a visual separator between button groups (no-op at runtime; layout hint only).
- `Toolbar::add_spacer` (`extras.rs`): Add a flexible spacer of `_width` pixels between button groups (no-op at runtime; layout hint only).
- `Toolbar::get_button_index` (`extras.rs`): Return the index of the button with the given `id`, or `None` if not found.
- `Toolbar::set_button_enabled` (`extras.rs`): Set the enabled state of the button with `id`; return `false` if not found.
- `Toolbar::set_button_toggled` (`extras.rs`): Set the toggled state of the button with `id`; return `false` if not found.
- `Toolbar::is_button_toggled` (`extras.rs`): Return the toggled state of the button with `id`, or `None` if not found.
- `MenuBar::new` (`extras.rs`): Create an empty menu bar.
- `MenuItem::new` (`extras.rs`): Create a menu item with the given text; no shortcut, unchecked, no sub-items.
- `Dialog::new` (`extras.rs`): Create a closed modal dialog with the given title and no content or buttons.
- `StatusBar::new` (`extras.rs`): Create an empty status bar.
- `Accordion::new` (`extras.rs`): Create an empty non-exclusive accordion.
- `TooltipPanel::new` (`extras.rs`): Create a tooltip with the given text and a default delay of 0.5 seconds.
- `ColorPicker::new` (`extras.rs`): Create a colour picker defaulting to opaque white in RGB mode with alpha shown.
- `GUITable::new` (`extras.rs`): Create an empty, non-sortable table with no columns or rows.
- `ImageWidget::new` (`extras.rs`): Create an image widget with `"fit"` scale mode and opaque white tint.
- `Badge::new` (`extras.rs`): Create a badge with the given count and default max_display of 99.
- `Badge::display_text` (`extras.rs`): Return the display string: `count.to_string()` or `"{max_display}+"` when count exceeds max.
- `Badge::set_count` (`extras.rs`): Update the count value.
- `CustomWidget::new` (`extras.rs`): Create a custom widget with default base state.
- `load_layout_def` (`layout_loader.rs`): Recursively build a widget tree from a `WidgetDef` into a `GuiContext`. Returns the pool index of the created root widget.
- `load_layout_toml` (`layout_loader.rs`): Parse a TOML source string into a `LayoutDef` then delegate to `load_layout_def`. Returns the pool index of the created root widget.
- `render_to_image` (`layout_loader.rs`): Run the layout pass, software-rasterise each visible widget rectangle in a representative colour, and save the result as a PNG. Headless-safe.
- `GuiContext::build_render_commands` (`render.rs`): Run a layout pass then emit all render commands using `font_key`; return the command list.
- `GuiContext::generate_render_commands` (`render.rs`): Run a layout pass and emit render commands using the default font key.
- `GuiContext::draw_to_image` (`render.rs`): Rasterise all visible widgets into a new `ImageData` of `width × height` pixels.
- `Theme::new` (`theme.rs`): Create a theme with no style overrides.
- `Theme::set_style` (`theme.rs`): Register `style` for `(widget_type, state)`, replacing any previous entry.
- `Theme::get_style` (`theme.rs`): Return the style for `(widget_type, state)`, falling back to `WidgetState::Normal` if the exact state is absent.
- `Theme::draw_button_states_to_image` (`theme.rs`): Render all four `Button` states as labelled tiles into a new `ImageData` of `width × height` pixels.
- `Theme::default_dark` (`theme.rs`): Create the built-in dark theme preset with styles for all standard widget types and states.
- `WidgetState::parse_str` (`widget.rs`): Parse a lowercase state name to a variant, or return `None` if unrecognised.
- `WidgetState::as_str` (`widget.rs`): Return the canonical lowercase name string for this state.
- `WidgetType::as_str` (`widget.rs`): Return the canonical lowercase name string for this type.
- `WidgetType::parse_str` (`widget.rs`): Public function or method declared in `widget.rs`.
- `WidgetType::default_size` (`widget.rs`): Return the default `(width, height)` size in pixels for this widget type.
- `WidgetTransition::alpha` (`widget.rs`): Create an alpha fade from `from` to `to` over `duration` seconds; optionally hide when done.
- `WidgetTransition::position` (`widget.rs`): Create a position slide from `(from_x, from_y)` to `(to_x, to_y)` over `duration` seconds.
- `WidgetBase::new` (`widget.rs`): Create a `WidgetBase` with `widget_type` defaults from `WidgetType::default_size`, visible, enabled, alpha 1.
- `WidgetBase::contains_point` (`widget.rs`): Return `true` if `(px, py)` lies within the widget's `x/y/width/height` rectangle.
- `WidgetBase::clear_anchors` (`widget.rs`): Clear all six anchor fields (`anchor_left`, `anchor_top`, `anchor_right`, `anchor_bottom`, `anchor_center_x`, `anchor_center_y`).

## Lua API Reference

- Binding path(s): `src/lua_api/ui_api.rs`
- Namespace: `lurek.ui`

### Module Functions
- `lurek.ui.newButton`: Creates a new button widget.
- `lurek.ui.newLabel`: Creates a new label widget.
- `lurek.ui.newTextInput`: Creates a new text input widget.
- `lurek.ui.newCheckbox`: Creates a new checkbox widget.
- `lurek.ui.newSlider`: Creates a new slider widget.
- `lurek.ui.newProgressBar`: Creates a new progress bar widget.
- `lurek.ui.newComboBox`: Creates a new combo box (drop-down) widget.
- `lurek.ui.newList`: Creates a new list box widget.
- `lurek.ui.newPanel`: Creates a new panel widget (container).
- `lurek.ui.newLayout`: Creates a new layout container widget.
- `lurek.ui.newScrollPanel`: Creates a new scrollable panel widget.
- `lurek.ui.newNinePatch`: Creates a new nine-patch widget for scalable bordered images.
- `lurek.ui.newTabBar`: Creates a new tab bar widget.
- `lurek.ui.newSeparator`: Creates a new separator widget.
- `lurek.ui.newSpacer`: Creates a new spacer widget for spacing between other widgets.
- `lurek.ui.newToast`: Creates a new toast notification widget.
- `lurek.ui.newTreeView`: Creates a new tree view widget.
- `lurek.ui.newRadioButton`: Creates a new radio button widget.
- `lurek.ui.newScrollBar`: Creates a new scroll bar widget.
- `lurek.ui.newWindow`: Creates a new GUI window widget.
- `lurek.ui.newSplitPanel`: Creates a new split panel widget with two resizable sub-panels.
- `lurek.ui.newDockPanel`: Creates a new dock panel widget for docking child widgets to sides.
- `lurek.ui.newToolbar`: Creates a new toolbar widget.
- `lurek.ui.newMenuBar`: Creates a new menu bar widget.
- `lurek.ui.newMenuItem`: Creates a new menu item widget.
- `lurek.ui.newDialog`: Creates a new dialog widget.
- `lurek.ui.newStatusBar`: Creates a new status bar widget.
- `lurek.ui.newAccordion`: Creates a new accordion widget.
- `lurek.ui.newTooltipPanel`: Creates a new tooltip panel widget.
- `lurek.ui.newColorPicker`: Creates a new color picker widget.
- `lurek.ui.newTable`: Creates a new table widget for tabular data display.
- `lurek.ui.newImageWidget`: Creates a new image display widget.
- `lurek.ui.setTheme`: Applies a theme to the UI context.
- `lurek.ui.getTheme`: Returns whether a theme is currently set.
- `lurek.ui.getRoot`: Returns the root panel widget.
- `lurek.ui.setFocus`: Sets keyboard focus to a widget, or clears focus if nil.
- `lurek.ui.getFocus`: Returns the index of the currently focused widget, or nil.
- `lurek.ui.focusNext`: Moves keyboard focus to the next focusable widget.
- `lurek.ui.focusPrev`: Moves keyboard focus to the previous focusable widget.
- `lurek.ui.clearFocus`: Clears keyboard focus from all widgets.
- `lurek.ui.addToast`: Adds a toast notification to the queue.
- `lurek.ui.getToastCount`: Returns the number of active toast notifications.
- `lurek.ui.mousepressed`: Delivers a mouse press event to the UI.
- `lurek.ui.mousereleased`: Delivers a mouse release event to the UI.
- `lurek.ui.mousemoved`: Delivers a mouse move event to the UI.
- `lurek.ui.keypressed`: Delivers a key press event to the UI.
- `lurek.ui.textinput`: Delivers a text input event to the UI.
- `lurek.ui.wheelmoved`: Delivers a mouse wheel event to the UI.
- `lurek.ui.update`: Updates the UI context and dispatches pending events to callbacks.
- `lurek.ui.draw`: Invokes custom draw callbacks for all widgets that have one registered.
- `lurek.ui.newCustomWidget`: Creates a new custom widget with optional initial configuration.
- `lurek.ui.getWidgetCount`: Returns the total number of widgets in the UI context.
- `lurek.ui.drawToImage`: Renders the entire UI to an image buffer.
- `lurek.ui.parseWidgetState`: Validates and normalizes a widget state string.
- `lurek.ui.newSpinBox`: Creates a new spin box (numeric stepper) widget.
- `lurek.ui.newSwitch`: Creates a new toggle switch widget.
- `lurek.ui.newBadge`: Creates a new badge widget for displaying counts.
- `lurek.ui.setDefaultTheme`: Applies the built-in default theme to the UI context.
- `lurek.ui.setViewport`: Sets the viewport size for the UI context.
- `lurek.ui.flushCache`: Flushes internal UI caches.
- `lurek.ui.beginDrag`: Begins a drag operation on a widget.
- `lurek.ui.getActiveDrag`: Returns the widget index currently being dragged, or nil.
- `lurek.ui.dropOn`: Drops the currently dragged widget onto a target widget.
- `lurek.ui.endDrag`: Ends the current drag operation without dropping.
- `lurek.ui.update_bindings`: Updates data bindings for widgets that reference binding keys.
- `lurek.ui.loadLayout`: Loads a UI layout from a Lua table definition.
- `lurek.ui.loadLayoutFile`: Loads a UI layout from a TOML file.
- `lurek.ui.renderToImage`: Renders the UI to a PNG file.

### `LAccordion` Methods
- `LAccordion:addSection`: Adds a collapsible section to this accordion.
- `LAccordion:getSectionCount`: Returns the number of sections in this accordion.
- `LAccordion:toggleSection`: Toggles the expanded state of an accordion section by its 1-based index.
- `LAccordion:isSectionExpanded`: Returns whether an accordion section is expanded.
- `LAccordion:isExclusive`: Returns whether this accordion is in exclusive mode (only one section open at a time).
- `LAccordion:setExclusive`: Sets exclusive mode. When true, expanding one section collapses all others.
- `LAccordion:getSectionTitle`: Returns the title of an accordion section by its 1-based index.

### `LAreaChart` Methods
- `LAreaChart:addLayer`: Adds a data layer to this area chart.
- `LAreaChart:setYMax`: Sets the maximum Y-axis value for this area chart.
- `LAreaChart:drawToImage`: Renders this area chart to an image buffer.
- `LAreaChart:type`: Returns the type name of this object.
- `LAreaChart:typeOf`: Checks whether this object matches the given type name.

### `LBadge` Methods
- `LBadge:setCount`: Sets the notification count displayed by this badge.
- `LBadge:getCount`: Returns the current notification count of this badge.
- `LBadge:getDisplayText`: Returns the formatted display text of this badge (e.g. "99+" when count exceeds the maximum).

### `LBarChart` Methods
- `LBarChart:addSeries`: Adds a named series to this bar chart.
- `LBarChart:addCategory`: Adds a category with values for each series.
- `LBarChart:drawToImage`: Renders this bar chart to an image buffer.
- `LBarChart:type`: Returns the type name of this object.
- `LBarChart:typeOf`: Checks whether this object matches the given type name.

### `LButton` Methods
- `LButton:setText`: Sets the display text on this button.
- `LButton:getText`: Returns the current display text of this button.

### `LCheckbox` Methods
- `LCheckbox:setChecked`: Sets the checked state of this checkbox.
- `LCheckbox:isChecked`: Returns whether this checkbox is currently checked.
- `LCheckbox:setText`: Sets the label text displayed next to this checkbox.
- `LCheckbox:getText`: Returns the label text of this checkbox.

### `LColorPicker` Methods
- `LColorPicker:getColor`: Returns the current color as RGBA components (0.0 to 1.0).
- `LColorPicker:setColor`: Sets the current color as RGBA components.
- `LColorPicker:getShowAlpha`: Returns whether the alpha channel slider is visible.
- `LColorPicker:setShowAlpha`: Sets whether the alpha channel slider is visible.
- `LColorPicker:getColorMode`: Returns the color mode of this picker (e.g. "rgb", "hsv").
- `LColorPicker:setColorMode`: Sets the color mode of this picker (e.g. "rgb", "hsv").
- `LColorPicker:setOnChange`: Registers a callback invoked when this color picker's value changes.

### `LComboBox` Methods
- `LComboBox:addItem`: Appends a new text item to this combo box's dropdown list.
- `LComboBox:removeItem`: Removes the item at the given 1-based index from this combo box.
- `LComboBox:clearItems`: Removes all items from this combo box.
- `LComboBox:getItemCount`: Returns the number of items in this combo box.
- `LComboBox:getItem`: Returns the text of the item at the given 1-based index.
- `LComboBox:setSelectedIndex`: Sets the selected item by 1-based index.
- `LComboBox:getSelectedIndex`: Returns the 1-based index of the currently selected item, or 0 if none is selected.
- `LComboBox:getSelectedItem`: Returns the text of the currently selected item, or nil if none is selected.

### `LDialog` Methods
- `LDialog:getTitle`: Returns the title text of this dialog.
- `LDialog:setTitle`: Sets the title text of this dialog.
- `LDialog:isModal`: Returns whether this dialog is modal (blocks interaction with other widgets).
- `LDialog:setModal`: Sets whether this dialog is modal.
- `LDialog:isOpen`: Returns whether this dialog is currently open and visible.
- `LDialog:open`: Opens this dialog, making it visible.
- `LDialog:close`: Closes this dialog and fires the onClose callback if it was open.
- `LDialog:setOnClose`: Registers a callback invoked when this dialog is closed.
- `LDialog:setContent`: Sets the content widget for this dialog.
- `LDialog:getContent`: Returns the widget index of this dialog's content, or nil if not set.
- `LDialog:addButton`: Adds a footer button to this dialog and returns its 1-based index.

### `LDockPanel` Methods
- `LDockPanel:dock`: Docks a child widget to the specified side of this dock panel.
- `LDockPanel:undock`: Removes a child widget from this dock panel.
- `LDockPanel:getDockedCount`: Returns the number of widgets docked in this dock panel.
- `LDockPanel:setSplitSize`: Sets the size of a dock panel side region.
- `LDockPanel:getSplitSize`: Returns the size configured for a dock panel side region.

### `LGuiTable` Methods
- `LGuiTable:getColumnCount`: Returns the number of columns in this table widget.
- `LGuiTable:addRow`: Adds a row to this table widget.
- `LGuiTable:getRowCount`: Returns the number of rows in this table widget.
- `LGuiTable:getCell`: Returns the text of a cell at the given 1-based row and column.
- `LGuiTable:setCell`: Sets the text of a cell at the given 1-based row and column.
- `LGuiTable:getSelectedRow`: Returns the 1-based index of the currently selected row, or nil.
- `LGuiTable:setSelectedRow`: Sets the selected row by its 1-based index, or nil to deselect.
- `LGuiTable:isSortable`: Returns whether columns in this table can be sorted by clicking headers.
- `LGuiTable:setSortable`: Sets whether columns in this table can be sorted by clicking headers.
- `LGuiTable:setOnSelect`: Registers a callback invoked when a table row is selected.

### `LGuiWindow` Methods
- `LGuiWindow:getTitle`: Returns the title bar text of this GUI window.
- `LGuiWindow:setTitle`: Sets the title bar text of this GUI window.
- `LGuiWindow:isCloseable`: Returns whether this window shows a close button.
- `LGuiWindow:setCloseable`: Sets whether this window shows a close button.
- `LGuiWindow:isDraggable`: Returns whether this window can be dragged by its title bar.
- `LGuiWindow:setDraggable`: Sets whether this window can be dragged by its title bar.
- `LGuiWindow:isResizable`: Returns whether this window can be resized by dragging its edges.
- `LGuiWindow:setResizable`: Sets whether this window can be resized.
- `LGuiWindow:setOnClose`: Registers a callback invoked when this window is closed.

### `LImageWidget` Methods
- `LImageWidget:getScaleMode`: Returns the image scaling mode (e.g. "fit", "fill", "stretch").
- `LImageWidget:setScaleMode`: Sets the image scaling mode (e.g. "fit", "fill", "stretch").
- `LImageWidget:getTint`: Returns the tint color of this image widget as RGBA components.
- `LImageWidget:setTint`: Sets the tint color of this image widget as RGBA components.

### `LLabel` Methods
- `LLabel:setText`: Sets the display text on this label.
- `LLabel:getText`: Returns the current display text of this label.

### `LLayout` Methods
- `LLayout:setDirection`: Sets the layout direction for child arrangement ("horizontal", "vertical", or "grid").
- `LLayout:getDirection`: Returns the current layout direction.
- `LLayout:setSpacing`: Sets the spacing in pixels between child widgets in this layout.
- `LLayout:getSpacing`: Returns the current spacing between children.
- `LLayout:setColumns`: Sets the number of columns for grid layout mode (minimum 1).
- `LLayout:setWrap`: Enables or disables wrapping of children to the next row/column when they overflow.
- `LLayout:getWrap`: Returns whether wrapping is enabled for this layout.
- `LLayout:setAlign`: Sets the cross-axis alignment for children (e.g. "start", "center", "end", "stretch").
- `LLayout:getAlign`: Returns the current cross-axis alignment mode.
- `LLayout:setJustify`: Sets the main-axis justification for children (e.g. "start", "center", "end", "space-between").
- `LLayout:getJustify`: Returns the current main-axis justification mode.

### `LLineChart` Methods
- `LLineChart:addSeries`: Adds a named series of points to this line chart.
- `LLineChart:setYMax`: Sets the maximum Y-axis value for this line chart.
- `LLineChart:setXMax`: Sets the maximum X-axis value for this line chart.
- `LLineChart:drawToImage`: Renders this line chart to an image buffer.
- `LLineChart:type`: Returns the type name of this object.
- `LLineChart:typeOf`: Checks whether this object matches the given type name.

### `LListBox` Methods
- `LListBox:addItem`: Appends a new text item to this list box.
- `LListBox:removeItem`: Removes the item at the given 1-based index from this list box.
- `LListBox:clearItems`: Removes all items from this list box.
- `LListBox:getItemCount`: Returns the number of items in this list box.
- `LListBox:getItem`: Returns the text of the item at the given 1-based index.
- `LListBox:setSelectedIndex`: Sets the selected item by 1-based index.
- `LListBox:getSelectedIndex`: Returns the 1-based index of the currently selected item, or 0 if none.
- `LListBox:setItemHeight`: Sets the pixel height of each item row in this list box.

### `LMenuBar` Methods
- `LMenuBar:addMenu`: Adds a menu (by its widget index) to this menu bar.
- `LMenuBar:removeMenu`: Removes a menu from this menu bar by its widget index.
- `LMenuBar:getMenus`: Returns a table of widget indices for all menus in this menu bar.
- `LMenuBar:getMenuCount`: Returns the number of menus in this menu bar.

### `LMenuItem` Methods
- `LMenuItem:getText`: Returns the display text of this menu item.
- `LMenuItem:setText`: Sets the display text of this menu item.
- `LMenuItem:getShortcut`: Returns the keyboard shortcut string associated with this menu item.
- `LMenuItem:setShortcut`: Sets the keyboard shortcut text displayed next to this menu item.
- `LMenuItem:isChecked`: Returns whether this menu item is checked (for checkable menu items).
- `LMenuItem:setChecked`: Sets the checked state of this menu item.
- `LMenuItem:addSubItem`: Adds a sub-item to this menu item for building nested menus.
- `LMenuItem:getSubItems`: Returns a table of widget indices for all sub-items of this menu item.
- `LMenuItem:setOnClick`: Registers a callback invoked when this menu item is clicked.

### `LNinePatch` Methods
- `LNinePatch:setInsets`: Sets the border insets defining the stretchable center region of the nine-patch image.
- `LNinePatch:getInsets`: Returns the border insets of this nine-patch.
- `LNinePatch:setImageDimensions`: Sets the original image dimensions used for nine-patch slice calculations.
- `LNinePatch:getImageDimensions`: Returns the original image dimensions of this nine-patch.
- `LNinePatch:getSlices`: Returns the computed nine-patch slices as a table of source/dest rectangles for rendering.

### `LPanel` Methods
- `LPanel:setTitle`: Sets the title text displayed on this panel's header.
- `LPanel:getTitle`: Returns the title text of this panel.
- `LPanel:setScrollable`: Enables or disables scrolling within this panel.

### `LPieChart` Methods
- `LPieChart:addSegment`: Adds a segment to this pie chart.
- `LPieChart:drawToImage`: Renders this pie chart to an image buffer.
- `LPieChart:type`: Returns the type name of this object.
- `LPieChart:typeOf`: Checks whether this object matches the given type name.

### `LProgressBar` Methods
- `LProgressBar:setValue`: Sets the current fill value of this progress bar, clamped to its range.
- `LProgressBar:getValue`: Returns the current value of this progress bar.
- `LProgressBar:getProgress`: Returns the normalized progress as a fraction (0.0 to 1.0) of the current range.
- `LProgressBar:setRange`: Sets the minimum and maximum bounds for this progress bar.
- `LProgressBar:getMin`: Returns the minimum value of this progress bar's range.
- `LProgressBar:getMax`: Returns the maximum value of this progress bar's range.

### `LRadioButton` Methods
- `LRadioButton:getText`: Returns the label text of this radio button.
- `LRadioButton:setText`: Sets the label text of this radio button.
- `LRadioButton:isSelected`: Returns whether this radio button is currently selected.
- `LRadioButton:getGroup`: Returns the radio button group name. Buttons in the same group are mutually exclusive.
- `LRadioButton:setGroup`: Sets the radio button group name. Buttons in the same group are mutually exclusive.
- `LRadioButton:setOnChange`: Registers a callback invoked when this radio button's selection changes.

### `LScatterPlot` Methods
- `LScatterPlot:addSeries`: Adds a data series to this scatter plot.
- `LScatterPlot:setXRange`: Sets the X-axis range for this scatter plot.
- `LScatterPlot:setYRange`: Sets the Y-axis range for this scatter plot.
- `LScatterPlot:drawToImage`: Renders this scatter plot to an image buffer.
- `LScatterPlot:type`: Returns the type name of this object.
- `LScatterPlot:typeOf`: Checks whether this object matches the given type name.

### `LScrollBar` Methods
- `LScrollBar:setScrollPosition`: Sets the scroll position of this scroll bar, clamped to the valid range.
- `LScrollBar:getContentSize`: Returns the total content size tracked by this scroll bar.
- `LScrollBar:setContentSize`: Sets the total content size that this scroll bar represents.
- `LScrollBar:getViewSize`: Returns the visible viewport size tracked by this scroll bar.
- `LScrollBar:isVertical`: Returns whether this scroll bar is oriented vertically.
- `LScrollBar:setOnChange`: Registers a callback invoked when this scroll bar's position changes.

### `LScrollPanel` Methods
- `LScrollPanel:setContentSize`: Sets the virtual content dimensions of this scroll panel.
- `LScrollPanel:setScrollPosition`: Sets the scroll offset position of this scroll panel.
- `LScrollPanel:getScrollPosition`: Returns the current scroll offset of this scroll panel.
- `LScrollPanel:getMaxScroll`: Returns the maximum scroll offset allowed in each axis.
- `LScrollPanel:setScrollSpeed`: Sets the scroll speed multiplier for mouse wheel scrolling.
- `LScrollPanel:getScrollSpeed`: Returns the current scroll speed multiplier.

### `LSeparator` Methods
- `LSeparator:setVertical`: Sets whether this separator draws vertically or horizontally.
- `LSeparator:isVertical`: Returns whether this separator is oriented vertically.
- `LSeparator:setThickness`: Sets the line thickness of this separator in pixels.
- `LSeparator:getThickness`: Returns the line thickness of this separator.

### `LSlider` Methods
- `LSlider:setValue`: Sets the current value of this slider, clamped to its range.
- `LSlider:getValue`: Returns the current value of this slider.
- `LSlider:setRange`: Sets the minimum and maximum bounds for this slider.
- `LSlider:setStep`: Sets the step increment for this slider's value snapping.
- `LSlider:getMin`: Returns the minimum value of this slider's range.
- `LSlider:getMax`: Returns the maximum value of this slider's range.

### `LSpinBox` Methods
- `LSpinBox:setValue`: Sets the numeric value of this spin box, clamped to its range.
- `LSpinBox:getValue`: Returns the current numeric value of this spin box.
- `LSpinBox:increment`: Increases this spin box's value by one step.
- `LSpinBox:setRange`: Sets the minimum and maximum bounds for this spin box.
- `LSpinBox:setStep`: Sets the step increment for this spin box.

### `LSplitPanel` Methods
- `LSplitPanel:getOrientation`: Returns the orientation of this split panel ("horizontal" or "vertical").
- `LSplitPanel:setOrientation`: Sets the orientation of this split panel ("horizontal" or "vertical").
- `LSplitPanel:getSplitPosition`: Returns the split position as a fraction (0.0 to 1.0) of the panel's total size.
- `LSplitPanel:setSplitPosition`: Sets the split position as a fraction (0.0 to 1.0).
- `LSplitPanel:getMinPanelSize`: Returns the minimum pixel size of each split sub-panel.
- `LSplitPanel:setMinPanelSize`: Sets the minimum pixel size of each split sub-panel.
- `LSplitPanel:setFirstChild`: Sets the widget index for the first (left/top) panel.
- `LSplitPanel:setSecondChild`: Sets the widget index for the second (right/bottom) panel.
- `LSplitPanel:getFirstChild`: Returns the widget index of the first (left/top) child panel.
- `LSplitPanel:getSecondChild`: Returns the widget index of the second (right/bottom) child panel.

### `LStatusBar` Methods
- `LStatusBar:addSection`: Adds a section to this status bar.
- `LStatusBar:setSectionText`: Sets the text of a status bar section by its 1-based index.
- `LStatusBar:getSectionCount`: Returns the number of sections in this status bar.
- `LStatusBar:setSectionCount`: Sets the number of sections, truncating or adding empty sections as needed.
- `LStatusBar:setSectionWidget`: Associates a widget with a status bar section (reserved for future use).

### `LSwitch` Methods
- `LSwitch:setOn`: Sets the on/off state of this toggle switch.
- `LSwitch:isOn`: Returns whether this switch is currently in the on state.
- `LSwitch:toggle`: Toggles this switch between on and off states.

### `LTabBar` Methods
- `LTabBar:addTab`: Adds a new tab with the given label to this tab bar.
- `LTabBar:removeTab`: Removes the tab at the given 1-based index.
- `LTabBar:getTab`: Returns the label of the tab at the given 1-based index.
- `LTabBar:getTabCount`: Returns the total number of tabs.
- `LTabBar:setActiveTab`: Sets the active (selected) tab by 1-based index.
- `LTabBar:getActiveTab`: Returns the 1-based index of the currently active tab.

### `LTextInput` Methods
- `LTextInput:setText`: Sets the text content of this text input field and moves the cursor to the end.
- `LTextInput:getText`: Returns the current text content of this text input field.
- `LTextInput:setMaxLength`: Sets the maximum number of characters allowed in this text input.
- `LTextInput:isFocused`: Returns whether this text input currently has keyboard focus.
- `LTextInput:getCursorPosition`: Returns the current cursor position (character index) within the text input.

### `LTheme` Methods
- `LTheme:setStyle`: Sets a style entry for the given widget type and state.
- `LTheme:type`: Returns the type name of this object.
- `LTheme:typeOf`: Checks whether this object matches the given type name.

### `LToast` Methods
- `LToast:setMessage`: Sets the message text displayed by this toast notification.
- `LToast:getMessage`: Returns the message text of this toast.
- `LToast:getDuration`: Returns the display duration of this toast in seconds.
- `LToast:getProgress`: Returns the elapsed fraction (0.0 to 1.0) of this toast's lifetime.
- `LToast:isExpired`: Returns whether this toast has exceeded its display duration.

### `LToolbar` Methods
- `LToolbar:getOrientation`: Returns the toolbar orientation ("horizontal" or "vertical").
- `LToolbar:setOrientation`: Sets the toolbar orientation ("horizontal" or "vertical").
- `LToolbar:addButton`: Adds a new button to this toolbar and returns its 1-based index.
- `LToolbar:addSeparator`: Adds a visual separator to this toolbar.
- `LToolbar:addSpacer`: Adds a flexible spacer to this toolbar.
- `LToolbar:getButton`: Returns a table describing the toolbar button with the given ID.
- `LToolbar:setButtonEnabled`: Enables or disables a toolbar button by its ID.
- `LToolbar:setButtonToggled`: Sets the toggle state of a toolbar button by its ID.
- `LToolbar:isButtonToggled`: Returns whether a toolbar button is toggled on.

### `LTooltipPanel` Methods
- `LTooltipPanel:getText`: Returns the tooltip display text.
- `LTooltipPanel:setText`: Sets the tooltip display text.
- `LTooltipPanel:getDelay`: Returns the delay in seconds before this tooltip appears.
- `LTooltipPanel:setDelay`: Sets the delay in seconds before this tooltip appears.
- `LTooltipPanel:getTarget`: Returns the widget index that this tooltip is attached to.
- `LTooltipPanel:setTarget`: Sets the widget index that this tooltip is attached to.

### `LTreeView` Methods
- `LTreeView:addNode`: /// Returns a value for addNode (auto-generated).
- `LTreeView:toggleNode`: /// Returns a value for toggleNode (auto-generated).
- `LTreeView:isExpanded`: /// Returns a value for isExpanded (auto-generated).
- `LTreeView:getNodeCount`: /// Returns a value for getNodeCount (auto-generated).
- `LTreeView:removeNode`: /// Returns a value for removeNode (auto-generated).
- `LTreeView:clearNodes`: /// Returns a value for clearNodes (auto-generated).
- `LTreeView:getNodeText`: /// Returns a value for getNodeText (auto-generated).
- `LTreeView:setNodeText`: /// Returns a value for setNodeText (auto-generated).
- `LTreeView:setNodeIcon`: /// Returns a value for setNodeIcon (auto-generated).
- `LTreeView:expandNode`: /// Returns a value for expandNode (auto-generated).
- `LTreeView:collapseNode`: Collapses the node at the given 1-based index to hide its children.
- `LTreeView:isNodeExpanded`: Returns whether the node at the given 1-based index is expanded. Returns nil if the index is invalid.
- `LTreeView:expandAll`: Expands all nodes in this tree view.
- `LTreeView:collapseAll`: Collapses all nodes in this tree view.
- `LTreeView:setSelectedNode`: Sets the selected node by 1-based index.
- `LTreeView:getSelectedNode`: Returns the 1-based index of the currently selected node.
- `LTreeView:getChildNodes`: Returns a table of 1-based child node indices for the node at the given index.
- `LTreeView:getParentNode`: Returns the 1-based index of the parent of the node at the given index.
- `LTreeView:getNodeDepth`: Returns the nesting depth of the node at the given index (0 for root nodes).

### `LUiWidget` Methods
- `LUiWidget:type`: Returns the type name string of this widget (e.g. "LButton", "LSlider").
- `LUiWidget:typeOf`: Checks whether this widget matches the given type name, including base types "LWidget" and "Object".
- `LUiWidget:setPosition`: Sets the local position of this widget relative to its parent.
- `LUiWidget:getPosition`: Returns the local position of this widget relative to its parent.
- `LUiWidget:setSize`: Sets the width and height of this widget in pixels.
- `LUiWidget:getSize`: Returns the width and height of this widget.
- `LUiWidget:getRect`: Returns the computed bounding rectangle of this widget in screen coordinates after layout.
- `LUiWidget:setVisible`: Shows or hides this widget. Hidden widgets are not drawn and do not receive input.
- `LUiWidget:isVisible`: Returns whether this widget is currently visible.
- `LUiWidget:setEnabled`: Enables or disables this widget. Disabled widgets appear grayed out and ignore input.
- `LUiWidget:isEnabled`: Returns whether this widget is currently enabled and can receive input.
- `LUiWidget:setId`: Assigns a string identifier to this widget for lookup with findById.
- `LUiWidget:getId`: Returns the string identifier assigned to this widget.
- `LUiWidget:setTooltip`: Sets the tooltip text shown when the user hovers over this widget.
- `LUiWidget:getTooltip`: Returns the tooltip text of this widget.
- `LUiWidget:getState`: Returns the current interaction state of this widget (e.g. "normal", "hovered", "pressed", "disabled").
- `LUiWidget:addChild`: Adds a child widget to this widget's hierarchy.
- `LUiWidget:removeChild`: Removes a child widget from this widget's hierarchy.
- `LUiWidget:getChildCount`: Returns the number of direct child widgets attached to this widget.
- `LUiWidget:getChildren`: Returns a table of lightweight child widget references, each containing an _idx field.
- `LUiWidget:findById`: Searches this widget's subtree for a child with the given ID.
- `LUiWidget:setOnClick`: Registers a callback function invoked when this widget is clicked.
- `LUiWidget:setOnChange`: Registers a callback function invoked when this widget's value changes.
- `LUiWidget:setOnDraw`: Registers a custom draw callback for this widget, invoked each frame during the draw pass.
- `LUiWidget:containsPoint`: Tests whether the given screen-space point is inside this widget's bounds.
- `LUiWidget:setPadding`: Sets the inner padding of this widget. Accepts 1 to 4 values (top, right?, bottom?, left?) following CSS shorthand rules.
- `LUiWidget:getPadding`: Returns the inner padding of this widget.
- `LUiWidget:setMargin`: Sets the outer margin of this widget. Accepts 1 to 4 values (top, right?, bottom?, left?) following CSS shorthand rules.
- `LUiWidget:getMargin`: Returns the outer margin of this widget.
- `LUiWidget:setZOrder`: Sets the z-order (draw priority) of this widget. Higher values draw on top.
- `LUiWidget:getZOrder`: Returns the z-order (draw priority) of this widget.
- `LUiWidget:setMinSize`: Sets the minimum allowed width and height for this widget during layout.
- `LUiWidget:getMinSize`: Returns the minimum width and height of this widget.
- `LUiWidget:setMaxSize`: Sets the maximum allowed width and height for this widget during layout.
- `LUiWidget:getMaxSize`: Returns the maximum width and height of this widget.
- `LUiWidget:setAnchor`: Anchors this widget to its parent's edges. Pass nil for any side to leave it unanchored.
- `LUiWidget:setAnchorCenter`: Centers this widget within its parent using proportional anchor offsets (0.0 to 1.0).
- `LUiWidget:clearAnchor`: Removes all anchor constraints from this widget.
- `LUiWidget:setFlexGrow`: Sets the flex-grow factor controlling how much extra space this widget receives in a layout.
- `LUiWidget:getFlexGrow`: Returns the flex-grow factor of this widget.
- `LUiWidget:setFlexShrink`: Sets the flex-shrink factor controlling how much this widget shrinks when layout space is insufficient.
- `LUiWidget:getFlexShrink`: Returns the flex-shrink factor of this widget.
- `LUiWidget:bind`: Binds this widget to a data key for use with update_bindings.
- `LUiWidget:unbind`: Removes the data binding from this widget.
- `LUiWidget:setAlpha`: Sets the opacity of this widget, clamped to 0.0 (fully transparent) through 1.0 (fully opaque).
- `LUiWidget:getAlpha`: Returns the current opacity of this widget.
- `LUiWidget:fadeIn`: Instantly makes this widget fully opaque and visible.
- `LUiWidget:fadeOut`: Instantly makes this widget fully transparent and hidden.
- `LUiWidget:slideIn`: Moves this widget to the given position and makes it visible.
- `LUiWidget:slideOut`: Moves this widget to the given position and hides it.
- `LUiWidget:animateAlpha`: Smoothly animates this widget's opacity toward a target value over the given duration.
- `LUiWidget:animatePosition`: Smoothly animates this widget's position toward the target coordinates.
- `LUiWidget:isAnimating`: Returns whether this widget currently has an active animation.
- `LUiWidget:cancelAnimations`: Cancels all active animations on this widget, leaving it at its current state.
- `LUiWidget:attachToEntity`: Attaches this widget to a game entity so it follows the entity's position on screen.
- `LUiWidget:detachFromEntity`: Detaches this widget from any previously attached entity.

## References

- `image`: Imports or references `image` from `src/image/`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/ui/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
