# ui

## General Info

- Module group: `Feature Systems`
- Source path: `src/ui/`
- Lua API path(s): `src/lua_api/ui_api.rs`
- Primary Lua namespace: `lurek.ui`
- Rust test path(s): tests/rust/unit/gui_tests.rs
- Lua test path(s): tests/lua/unit/test_gui.lua, tests/lua/unit/test_ui_layout.lua, tests/lua/integration/test_localization_ui.lua

## Summary

The `ui` module provides Lurek2D's retained-mode widget UI system, enabling game developers to build full user interfaces from a rich library of composed widgets without writing draw calls manually. All rendering is deferred through the `RenderCommand` queue.

`GuiContext` is the root container: it owns the root `Panel`, manages keyboard focus tracking, routes input events to the focused widget, and processes a toast notification queue. All widgets inherit `WidgetBase`, which stores position, size, visibility, enabled state, Z-order, padding, margin, anchor constraints, and flexbox layout properties.

**Containers**: `Panel` (generic layout container), `ScrollPanel` (scrollable content with scrollbar), `DockPanel` (edge-docked child layout), `SplitPanel` (resizable split), `GUIWindow` (moveable, closeable dialog frame). **Controls**: `Button`, `Label`, `TextInput` (with placeholder, cursor, selection), `CheckBox`, `RadioButton`, `Slider`, `ProgressBar`, `ComboBox`, `ListBox`, `TabBar`, `SpinBox`, `Switch`, `ScrollBar`. **Additional widgets**: `Toast` (auto-dismissing notification banner), `TreeView` + `TreeNode` (collapsible hierarchy), `Dialog` (modal dialog with buttons), `MenuBar` + `MenuItem` (top bar dropdowns), `ColorPicker`, `Badge` (count overlay), `Accordion` (collapsible sections), `Toolbar`, `StatusBar`, `Tooltip`, `GUITable` (editable data grid), `ImageWidget`.

`Theme` drives visual appearance: it maps `(WidgetType, WidgetState)` pairs to `WidgetStyle` records (background color, foreground color, font key, font size, border color, corner radius, padding). The `chart` submodule adds `GraphRenderer` for inline data visualizations (line charts, bar charts, pie charts) within the UI tree.

Three new widget types complete the toolkit. The existing `chart.rs` chart renderer has been augmented with `ChartWidget`, a retained-mode widget node that integrates directly into the `GuiContext` tree and responds to layout constraints like other widgets, accessible via `lurek.ui.newChart()`. `rich_text.rs` introduces `RichText`, a text widget supporting inline color, bold, italic, and icon spans via a tag-based markup language, accessible via `lurek.ui.newRichText()`. `tooltip.rs` introduces `Tooltip`, a hover-triggered overlay widget with configurable delay and position anchoring, accessible via `lurek.ui.newTooltip()`. All three integrate with the existing `Theme` system for consistent visual styling.

**Scope boundary**: Feature Systems tier. Depends on `render`, `math`, `runtime`. Lua bridge in `src/lua_api/ui_api.rs`.

## Files

- `chart.rs`: Generates CPU-rendered chart images for line, bar, scatter, pie, and area graphs without requiring the GPU path.
- `containers.rs`: Defines structural widgets such as panels, layouts, split views, scroll panels, windows, dock panels, and nine-patch containers.
- `context.rs`: Implements `GuiContext`, the retained widget pool, focus management, event routing, child relationships, and toast tracking.
- `controls.rs`: Defines common interactive widgets such as buttons, labels, text inputs, sliders, check boxes, combo boxes, list boxes, and progress bars.
- `data_graph_renderer.rs`: Implements data-series rendering helpers for charts and graph-style visualizations.
- `extras.rs`: Defines secondary widgets and utility components such as menus, toolbars, dialogs, tables, tree views, tooltips, accordions, image widgets, and toasts.
- `layout_loader.rs`: Implements pure-Rust layout definition loading (`WidgetDef` / TOML) and a headless software PNG rasteriser for test evidence generation.
- `mod.rs`: Declares the UI submodules and re-exports the widget, context, theme, container, control, and chart-facing types.
- `render.rs`: Walks UI state and theme data to produce render commands or CPU-side image output.
- `theme.rs`: Stores theme style maps, widget visual state, and fallback behavior for widget styling.
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
- `WidgetDef` (`struct`, `layout_loader.rs`): Tree node describing a single widget and its optional children.
- `LayoutDef` (`struct`, `layout_loader.rs`): Top-level TOML layout descriptor.
- `WidgetStyle` (`struct`, `theme.rs`): A concrete set of colors, borders, radius, and font-size values used by theme lookup.
- `Theme` (`struct`, `theme.rs`): Stores widget styles keyed by widget type and state so the same UI tree can be skinned consistently.
- `WidgetState` (`enum`, `widget.rs`): Encodes common UI states such as normal, hovered, pressed, focused, and disabled.
- `WidgetType` (`enum`, `widget.rs`): Identifies the broad widget class for styling and state-dependent behavior.
- `WidgetBase` (`struct`, `widget.rs`): Shared geometry, visibility, spacing, anchoring, and flex-like metadata embedded in every widget.

## Functions

- `LineChart::new` (`chart.rs`): Creates a new line chart with the given configuration.
- `LineChart::add_series` (`chart.rs`): Adds a named data series to the chart.
- `LineChart::draw_to_image` (`chart.rs`): Renders the line chart to an `ImageData`.
- `BarChart::new` (`chart.rs`): Creates a new bar chart with the given configuration.
- `BarChart::add_series` (`chart.rs`): Adds a bar series with a name and colour.
- `BarChart::add_category` (`chart.rs`): Adds a category group with its per-series values.
- `BarChart::draw_to_image` (`chart.rs`): Renders the bar chart to an `ImageData`.
- `ScatterPlot::new` (`chart.rs`): Creates a new scatter plot with the given configuration.
- `ScatterPlot::add_series` (`chart.rs`): Adds a named data series to the scatter plot.
- `ScatterPlot::draw_to_image` (`chart.rs`): Renders the scatter plot to an `ImageData`.
- `PieChart::new` (`chart.rs`): Creates a new pie chart with the given configuration.
- `PieChart::add_segment` (`chart.rs`): Adds a labelled segment to the pie chart.
- `PieChart::draw_to_image` (`chart.rs`): Renders the pie chart to an `ImageData`.
- `AreaChart::new` (`chart.rs`): Creates a new area chart with the given configuration.
- `AreaChart::add_layer` (`chart.rs`): Adds a stacked layer to the area chart.
- `AreaChart::draw_to_image` (`chart.rs`): Renders the stacked area chart to an `ImageData`.
- `Panel::new` (`containers.rs`): Create a new empty panel.
- `LayoutDirection::parse_str` (`containers.rs`): Parse a direction string.
- `LayoutDirection::as_str` (`containers.rs`): Return the lowercase string name.
- `Layout::new` (`containers.rs`): Create a new layout with the given direction, defaulting to zero spacing, no wrapping, `"start"` alignment and justification.
- `Layout::perform_layout` (`containers.rs`): Recalculate child positions based on direction, spacing, alignment, and justification.
- `ScrollPanel::new` (`containers.rs`): Create a new scroll panel with default content size matching widget size.
- `ScrollPanel::max_scroll` (`containers.rs`): Return the maximum scroll offset for each axis, clamped to zero.
- `ScrollPanel::clamp_scroll` (`containers.rs`): Clamp scroll position to valid range.
- `NinePatch::new` (`containers.rs`): Create a new nine-patch with zero insets and zero image dimensions.
- `NinePatch::get_slices` (`containers.rs`): Compute the nine slice rectangles.
- `GUIWindow::new` (`containers.rs`): Create a new GUI window.
- `SplitPanel::new` (`containers.rs`): Create a new split panel.
- `DockPanel::new` (`containers.rs`): Create a new dock panel.
- `WidgetKind::base` (`context.rs`): Return a reference to the shared [`WidgetBase`] inside this variant.
- `WidgetKind::base_mut` (`context.rs`): Return a mutable reference to the shared [`WidgetBase`].
- `WidgetKind::children` (`context.rs`): Return the child indices if this widget is a container type.
- `WidgetKind::children_mut` (`context.rs`): Return mutable child indices if this widget is a container type.
- `GuiContext::new` (`context.rs`): Create a new GUI context with an invisible root panel at index 0.
- `GuiContext::widget_count` (`context.rs`): Return the number of widgets in the pool (including the root).
- `GuiContext::drain_events` (`context.rs`): Drain and return all pending interaction events accumulated since the last call.
- `GuiContext::run_layout_pass` (`context.rs`): Walk the widget tree and write `computed_rect` on each widget.
- `GuiContext::add_button` (`context.rs`): Add a button and return its pool index.
- `GuiContext::add_label` (`context.rs`): Add a label and return its pool index.
- `GuiContext::add_text_input` (`context.rs`): Add a text input and return its pool index.
- `GuiContext::add_checkbox` (`context.rs`): Add a check box and return its pool index.
- `GuiContext::add_slider` (`context.rs`): Add a slider and return its pool index.
- `GuiContext::add_progress_bar` (`context.rs`): Add a progress bar and return its pool index.
- `GuiContext::add_combo_box` (`context.rs`): Add a combo box and return its pool index.
- `GuiContext::add_list_box` (`context.rs`): Add a list box and return its pool index.
- `GuiContext::add_panel` (`context.rs`): Add a panel and return its pool index.
- `GuiContext::add_layout` (`context.rs`): Add a layout and return its pool index.
- `GuiContext::add_scroll_panel` (`context.rs`): Add a scroll panel and return its pool index.
- `GuiContext::add_nine_patch` (`context.rs`): Add a nine-patch and return its pool index.
- `GuiContext::add_tab_bar` (`context.rs`): Add a tab bar and return its pool index.
- `GuiContext::add_separator` (`context.rs`): Add a separator and return its pool index.
- `GuiContext::add_spacer` (`context.rs`): Add a spacer and return its pool index.
- `GuiContext::add_tree_view` (`context.rs`): Add a tree view and return its pool index.
- `GuiContext::add_radio_button` (`context.rs`): Add a radio button and return its pool index.
- `GuiContext::add_scroll_bar` (`context.rs`): Add a scroll bar and return its pool index.
- `GuiContext::add_gui_window` (`context.rs`): Add a GUI window and return its pool index.
- `GuiContext::add_split_panel` (`context.rs`): Add a split panel and return its pool index.
- `GuiContext::add_dock_panel` (`context.rs`): Add a dock panel and return its pool index.
- `GuiContext::add_toolbar` (`context.rs`): Add a toolbar and return its pool index.
- `GuiContext::add_menu_bar` (`context.rs`): Add a menu bar and return its pool index.
- `GuiContext::add_menu_item` (`context.rs`): Add a menu item and return its pool index.
- `GuiContext::add_dialog` (`context.rs`): Add a dialog and return its pool index.
- `GuiContext::add_status_bar` (`context.rs`): Add a status bar and return its pool index.
- `GuiContext::add_accordion` (`context.rs`): Add an accordion and return its pool index.
- `GuiContext::add_tooltip_panel` (`context.rs`): Add a tooltip panel and return its pool index.
- `GuiContext::add_color_picker` (`context.rs`): Add a color picker and return its pool index.
- `GuiContext::add_gui_table` (`context.rs`): Add a GUI table and return its pool index.
- `GuiContext::add_image_widget` (`context.rs`): Add an image widget and return its pool index.
- `GuiContext::add_spin_box` (`context.rs`): Add a spin box and return its pool index.
- `GuiContext::add_switch` (`context.rs`): Add a toggle switch and return its pool index.
- `GuiContext::add_badge` (`context.rs`): Add a badge and return its pool index.
- `GuiContext::set_default_theme` (`context.rs`): Install the built-in dark theme as the active theme.
- `GuiContext::set_viewport` (`context.rs`): Set the logical viewport size (used for anchoring and relative layout).
- `GuiContext::flush_cache` (`context.rs`): Mark the render cache as clean and return `true` if the context was dirty.
- `GuiContext::add_child` (`context.rs`): Add `child_idx` as a child of the container at `parent_idx`.
- `GuiContext::remove_child` (`context.rs`): Remove `child_idx` from the container at `parent_idx`.
- `GuiContext::child_count` (`context.rs`): Count the children of a container widget.
- `GuiContext::set_focus` (`context.rs`): Set keyboard focus to the given widget, clearing focus from the previous widget.
- `GuiContext::focus_next` (`context.rs`): Move focus to the next focusable widget (tab order by pool index).
- `GuiContext::focus_prev` (`context.rs`): Move focus to the previous focusable widget.
- `GuiContext::add_toast` (`context.rs`): Queue a toast notification for display.
- `GuiContext::toast_count` (`context.rs`): Return the number of active (non-expired) toast notifications.
- `GuiContext::update` (`context.rs`): Advance toast timers and remove expired toasts.
- `GuiContext::find_by_id` (`context.rs`): Recursively search for a widget by its `id` string, starting from `start_idx`.
- `GuiContext::mouse_pressed` (`context.rs`): Forward a mouse press event to the widget tree.
- `GuiContext::mouse_released` (`context.rs`): Forward a mouse release event to the widget tree.
- `GuiContext::mouse_moved` (`context.rs`): Forward a mouse move event to update hover states.
- `GuiContext::key_pressed` (`context.rs`): Forward a key press event.
- `GuiContext::text_input` (`context.rs`): Forward a text input event to the focused text input widget.
- `GuiContext::wheel_moved` (`context.rs`): Forward a mouse wheel event.
- `Button::new` (`controls.rs`): Create a new button with the given label text.
- `Label::new` (`controls.rs`): Create a new label with the given text.
- `TextInput::new` (`controls.rs`): Create a new empty text input.
- `TextInput::insert_text` (`controls.rs`): Insert text at the cursor position, respecting `max_length`.
- `TextInput::backspace` (`controls.rs`): Delete the character before the cursor (backspace).
- `CheckBox::new` (`controls.rs`): Create a new unchecked check box with the given label.
- `Slider::new` (`controls.rs`): Create a new slider with the given range.
- `Slider::set_value` (`controls.rs`): Set the current value, clamping to the `[min, max]` range and snapping to `step` if non-zero.
- `ProgressBar::new` (`controls.rs`): Create a new progress bar with the given range.
- `ProgressBar::progress` (`controls.rs`): Return the normalized progress in `[0.0, 1.0]`.
- `ComboBox::new` (`controls.rs`): Create a new empty combo box.
- `ComboBox::add_item` (`controls.rs`): Add an item to the end of the list.
- `ComboBox::remove_item` (`controls.rs`): Remove an item at the given 0-based index.
- `ComboBox::clear` (`controls.rs`): Clear all items and reset selection.
- `ComboBox::selected_item` (`controls.rs`): Get the currently selected item text, if any.
- `ListBox::new` (`controls.rs`): Create a new empty list box.
- `ListBox::add_item` (`controls.rs`): Add an item to the end of the list.
- `ListBox::remove_item` (`controls.rs`): Remove an item at the given 0-based index.
- `ListBox::clear` (`controls.rs`): Clear all items and reset selection.
- `ListBox::selected_item` (`controls.rs`): Get the currently selected item text, if any.
- `TabBar::new` (`controls.rs`): Create a new empty tab bar.
- `TabBar::add_tab` (`controls.rs`): Add a tab with the given label.
- `TabBar::remove_tab` (`controls.rs`): Remove a tab at the given 0-based index.
- `RadioButton::new` (`controls.rs`): Create a new radio button.
- `ScrollBar::new` (`controls.rs`): Create a new scroll bar.
- `SpinBox::new` (`controls.rs`): Create a new spin box with the given range.
- `SpinBox::set_value` (`controls.rs`): Set the value, clamping to `[min, max]` and snapping to `step`.
- `SpinBox::increment` (`controls.rs`): Increment the value by one step (clamped).
- `SpinBox::decrement` (`controls.rs`): Decrement the value by one step (clamped).
- `SpinBox::set_range` (`controls.rs`): Update the range, re-clamping the current value.
- `Switch::new` (`controls.rs`): Create a new switch.
- `Switch::toggle` (`controls.rs`): Toggle the switch state.
- `Switch::set_on` (`controls.rs`): Set the switch state explicitly.
- `GraphSeries::name` (`data_graph_renderer.rs`): Returns the series name regardless of variant.
- `GraphRenderer::new` (`data_graph_renderer.rs`): Creates a new `GraphRenderer` with sensible defaults.
- `GraphRenderer::set_viewport` (`data_graph_renderer.rs`): Sets the screen-pixel viewport for chart rendering.
- `GraphRenderer::get_viewport` (`data_graph_renderer.rs`): Returns the current viewport as `(x, y, w, h)`.
- `GraphRenderer::set_range` (`data_graph_renderer.rs`): Sets the world (data) coordinate range.
- `GraphRenderer::get_range` (`data_graph_renderer.rs`): Returns the current data range as `(x_min, x_max, y_min, y_max)`.
- `GraphRenderer::auto_range` (`data_graph_renderer.rs`): Computes the data range from all series data points with 10 % padding.
- `GraphRenderer::add_line_series` (`data_graph_renderer.rs`): Adds a line series with the given name, data points, and color.
- `GraphRenderer::add_scatter_series` (`data_graph_renderer.rs`): Adds a scatter series.
- `GraphRenderer::add_bar_series` (`data_graph_renderer.rs`): Adds a bar series.
- `GraphRenderer::remove_series` (`data_graph_renderer.rs`): Removes a series by name.
- `GraphRenderer::clear_series` (`data_graph_renderer.rs`): Removes all series.
- `GraphRenderer::get_series_names` (`data_graph_renderer.rs`): Returns the names of all registered series.
- `GraphRenderer::series` (`data_graph_renderer.rs`): Returns a reference to the underlying series map.
- `GraphRenderer::set_show_grid` (`data_graph_renderer.rs`): Enables or disables the background grid.
- `GraphRenderer::set_show_axes` (`data_graph_renderer.rs`): Enables or disables the x/y axes.
- `GraphRenderer::set_show_labels` (`data_graph_renderer.rs`): Enables or disables axis labels and chart title.
- `GraphRenderer::set_grid_color` (`data_graph_renderer.rs`): Sets the grid line color.
- `GraphRenderer::set_axis_color` (`data_graph_renderer.rs`): Sets the axis line color.
- `GraphRenderer::set_bg_color` (`data_graph_renderer.rs`): Sets the chart background color.
- `GraphRenderer::set_title` (`data_graph_renderer.rs`): Sets the chart title.
- `GraphRenderer::set_axis_labels` (`data_graph_renderer.rs`): Sets the x-axis and y-axis labels.
- `GraphRenderer::set_cursor_position` (`data_graph_renderer.rs`): Sets the cursor position in data (world) coordinates.
- `GraphRenderer::get_cursor_value` (`data_graph_renderer.rs`): Returns the current cursor position in data coordinates.
- `GraphRenderer::world_to_screen` (`data_graph_renderer.rs`): Maps world (data) coordinates to viewport screen-pixel coordinates.
- `GraphRenderer::screen_to_world` (`data_graph_renderer.rs`): Maps viewport screen-pixel coordinates back to world (data) coordinates.
- `Toast::new` (`extras.rs`): Create a new toast with the given message and duration.
- `Toast::progress` (`extras.rs`): Return the progress through the toast's lifetime as `[0.0, 1.0]`.
- `Toast::is_expired` (`extras.rs`): Return `true` if the toast has exceeded its display duration.
- `Toast::update` (`extras.rs`): Advance the elapsed timer by `dt` seconds.
- `Separator::new` (`extras.rs`): Create a new separator.
- `Spacer::new` (`extras.rs`): Create a new spacer with the given dimensions.
- `TreeNode::new` (`extras.rs`): Create a new tree node with the given label and optional parent.
- `TreeView::new` (`extras.rs`): Create a new empty tree view.
- `TreeView::add_node` (`extras.rs`): Add a node to the tree.
- `TreeView::toggle_node` (`extras.rs`): Toggle the expanded state of a node.
- `TreeView::node_count` (`extras.rs`): Return the total number of nodes.
- `TreeView::remove_node` (`extras.rs`): Remove the node at `index`, detaching it from its parent and remapping all stored indices that follow.
- `TreeView::clear_nodes` (`extras.rs`): Remove all nodes and reset the tree.
- `TreeView::get_node_text` (`extras.rs`): Return the display text of the node at `index`, or `None` if out of range.
- `TreeView::set_node_text` (`extras.rs`): Set the display text of the node at `index`.
- `TreeView::set_node_icon` (`extras.rs`): Set the icon name for the node at `index`.
- `TreeView::expand_node` (`extras.rs`): Expand the node at `index` (make its children visible).
- `TreeView::collapse_node` (`extras.rs`): Collapse the node at `index` (hide its children).
- `TreeView::is_node_expanded` (`extras.rs`): Return whether the node at `index` is expanded.
- `TreeView::expand_all` (`extras.rs`): Expand all nodes in the tree at once.
- `TreeView::collapse_all` (`extras.rs`): Collapse all nodes in the tree at once.
- `TreeView::set_selected_node` (`extras.rs`): Set the selected node.
- `TreeView::get_selected_node` (`extras.rs`): Return the selected node index, or `None` if nothing is selected.
- `TreeView::get_child_nodes` (`extras.rs`): Return a slice of child indices for the node at `index`.
- `TreeView::get_parent_node` (`extras.rs`): Return the parent index of the node at `index`.
- `TreeView::get_node_depth` (`extras.rs`): Return the depth of the node at `index` (0 for root-level nodes).
- `ToolbarButton::new` (`extras.rs`): Create a new toolbar button.
- `Toolbar::new` (`extras.rs`): Create a new toolbar.
- `Toolbar::add_button` (`extras.rs`): Add a named button to the toolbar.
- `Toolbar::add_separator` (`extras.rs`): Add a visual separator to the toolbar.
- `Toolbar::add_spacer` (`extras.rs`): Add a flexible spacer to the toolbar.
- `Toolbar::get_button_index` (`extras.rs`): Return the 0-based index of the button with the given `id`, or `None`.
- `Toolbar::set_button_enabled` (`extras.rs`): Enable or disable the button identified by `id`.
- `Toolbar::set_button_toggled` (`extras.rs`): Set the toggled (latched pressed) state of the button identified by `id`.
- `Toolbar::is_button_toggled` (`extras.rs`): Return whether the button identified by `id` is in the toggled state.
- `MenuBar::new` (`extras.rs`): Create a new menu bar.
- `MenuItem::new` (`extras.rs`): Create a new menu item.
- `Dialog::new` (`extras.rs`): Create a new dialog.
- `StatusBar::new` (`extras.rs`): Create a new status bar.
- `Accordion::new` (`extras.rs`): Create a new accordion.
- `TooltipPanel::new` (`extras.rs`): Create a new tooltip panel.
- `ColorPicker::new` (`extras.rs`): Create a new color picker.
- `GUITable::new` (`extras.rs`): Create a new data table.
- `ImageWidget::new` (`extras.rs`): Create a new image widget.
- `Badge::new` (`extras.rs`): Create a new badge.
- `Badge::display_text` (`extras.rs`): Return the text that should be rendered inside the badge.
- `Badge::set_count` (`extras.rs`): Set the count.
- `load_layout_def` (`layout_loader.rs`): Recursively build a widget tree from a `WidgetDef` into a `GuiContext`. Returns the pool index of the created root widget.
- `load_layout_toml` (`layout_loader.rs`): Parse a TOML source string into a `LayoutDef` then delegate to `load_layout_def`. Returns the pool index of the created root widget.
- `render_to_image` (`layout_loader.rs`): Run the layout pass, software-rasterise each visible widget rectangle in a representative colour, and save the result as a PNG. Headless-safe.
- `GuiContext::build_render_commands` (`render.rs`): Generate a flat list of [`RenderCommand`]s for the entire widget tree.
- `GuiContext::generate_render_commands` (`render.rs`): Generate render commands using the default font key.
- `GuiContext::draw_to_image` (`render.rs`): Render the widget tree to a CPU image for headless layout testing.
- `Theme::new` (`theme.rs`): Create an empty theme with no style entries.
- `Theme::set_style` (`theme.rs`): Insert or replace a style entry for the given widget type and state.
- `Theme::get_style` (`theme.rs`): Look up the style for a widget type and state.
- `Theme::draw_button_states_to_image` (`theme.rs`): Renders a row of button states (Normal, Hovered, Pressed, Disabled) as styled boxes to an `ImageData` for evidence testing.
- `Theme::default_dark` (`theme.rs`): Create a dark theme pre-loaded with styled entries for all standard widget types.
- `WidgetState::parse_str` (`widget.rs`): Parse a state name string into a [`WidgetState`].
- `WidgetState::as_str` (`widget.rs`): Return the lowercase name of this state.
- `WidgetType::as_str` (`widget.rs`): Return the lowercase Lua-facing name of this widget type.
- `WidgetType::parse_str` (`widget.rs`): Parse a lowercase widget-type name into a [`WidgetType`].
- `WidgetType::default_size` (`widget.rs`): Return the default size `(width, height)` for this widget type on a 16 px grid.
- `WidgetBase::new` (`widget.rs`): Create a new `WidgetBase` with default values for the given widget type.
- `WidgetBase::contains_point` (`widget.rs`): Test whether a point `(px, py)` lies within this widget's bounding rectangle.
- `WidgetBase::clear_anchors` (`widget.rs`): Clear all anchor constraints.

## Lua API Reference

- Binding path(s): `src/lua_api/ui_api.rs`
- Namespace: `lurek.ui`

### Module Functions
- `lurek.ui.setPosition`: Sets the widget position.
- `lurek.ui.getPosition`: Returns the widget position.
- `lurek.ui.setSize`: Sets the width and height of the widget in UI pixels.
- `lurek.ui.getSize`: Returns the current width and height of the widget in UI pixels.
- `lurek.ui.getRect`: Returns the computed screen-space rectangle after layout.
- `lurek.ui.setVisible`: Shows or hides the widget; hidden widgets are not rendered or interactive.
- `lurek.ui.isVisible`: Returns whether the widget is visible.
- `lurek.ui.setEnabled`: Sets whether the widget is enabled.
- `lurek.ui.isEnabled`: Returns whether the widget is enabled.
- `lurek.ui.setId`: Sets the widget string identifier.
- `lurek.ui.getId`: Returns the widget string identifier.
- `lurek.ui.setTooltip`: Sets the widget tooltip text.
- `lurek.ui.getTooltip`: Returns the widget tooltip text.
- `lurek.ui.getState`: Returns the widget interaction state name.
- `lurek.ui.addChild`: Adds a child widget to this container.
- `lurek.ui.removeChild`: Removes a child widget from this container.
- `lurek.ui.getChildCount`: Returns the number of children in this container.
- `lurek.ui.getChildren`: Returns this container's children as widget-handle tables.
- `lurek.ui.findById`: Recursively searches for a widget by id starting from this widget.
- `lurek.ui.setOnClick`: Registers a callback invoked when this widget is clicked.
- `lurek.ui.setOnChange`: Registers a callback invoked when this widget's value changes.
- `lurek.ui.setOnDraw`: Stores a custom draw callback for later invocation.
- `lurek.ui.containsPoint`: Returns whether (x, y) is inside this widget.
- `lurek.ui.setPadding`: Sets widget padding (CSS-like: top, right?, bottom?, left?).
- `lurek.ui.getPadding`: Returns the widget padding (top, right, bottom, left).
- `lurek.ui.setMargin`: Sets widget margin (CSS-like: top, right?, bottom?, left?).
- `lurek.ui.getMargin`: Returns the widget margin (top, right, bottom, left).
- `lurek.ui.setZOrder`: Sets the widget z-order for draw sorting.
- `lurek.ui.getZOrder`: Returns the widget z-order.
- `lurek.ui.setMinSize`: Sets the minimum widget size.
- `lurek.ui.getMinSize`: Returns the minimum widget size.
- `lurek.ui.setMaxSize`: Sets the maximum widget size.
- `lurek.ui.getMaxSize`: Returns the maximum widget size.
- `lurek.ui.setAnchor`: Sets anchor edges (left, top, right, bottom).
- `lurek.ui.setAnchorCenter`: Sets center anchor offsets.
- `lurek.ui.clearAnchor`: Removes all anchor constraints.
- `lurek.ui.setFlexGrow`: Sets the flex-grow factor.
- `lurek.ui.getFlexGrow`: Returns the flex-grow factor.
- `lurek.ui.setFlexShrink`: Sets the flex-shrink factor.
- `lurek.ui.getFlexShrink`: Returns the flex-shrink factor.
- `lurek.ui.bind`: Registers a data-binding key on this widget.
- `lurek.ui.unbind`: Removes the data-binding key from this widget.
- `lurek.ui.setAlpha`: Sets the widget's alpha transparency (`0.0` fully transparent, `1.0` opaque).
- `lurek.ui.getAlpha`: Returns the widget's current alpha transparency.
- `lurek.ui.fadeIn`: Instantly fades the widget in (sets alpha to `1.0`).
- `lurek.ui.fadeOut`: Instantly fades the widget out (sets alpha to `0.0` and hides it).
- `lurek.ui.slideIn`: Instantly moves the widget to `(x, y)` and makes it visible.
- `lurek.ui.slideOut`: Instantly moves the widget to the off-screen position `(x, y)` and hides it.
- `lurek.ui.attachToEntity`: Anchors this widget to a world-space entity by its numeric ID.
- `lurek.ui.detachFromEntity`: Removes the entity anchor from this widget, restoring normal layout positioning.

### `Accordion` Methods
- `Accordion:addSection`: Adds a section entry to this Accordion widget.
- `Accordion:getSectionCount`: Returns the section count of this Accordion widget.
- `Accordion:toggleSection`: Toggles the expanded/collapsed status of an Accordion section.
- `Accordion:isSectionExpanded`: Returns true if section expanded is enabled for this Accordion widget.
- `Accordion:isExclusive`: Returns true if exclusive is enabled for this Accordion widget.
- `Accordion:setExclusive`: Sets the exclusive for this Accordion widget.
- `Accordion:getSectionTitle`: Returns the section title of this Accordion widget.

### `AreaChart` Methods
- `AreaChart:setYMax`: Sets the maximum Y value for axis scaling.
- `AreaChart:drawToImage`: Renders the area chart into an existing ImageData.

### `Badge` Methods
- `Badge:setCount`: Sets the count displayed on this Badge widget.
- `Badge:getCount`: Returns the raw count of this Badge widget.
- `Badge:getDisplayText`: Returns the display text of this Badge widget, e.g. "99+" when over the max.

### `BarChart` Methods
- `BarChart:drawToImage`: Renders the bar chart into an existing ImageData.

### `Button` Methods
- `Button:setText`: Sets the text for this Button widget.
- `Button:getText`: Returns the text of this Button widget.

### `Checkbox` Methods
- `Checkbox:setChecked`: Sets the checked for this Checkbox widget.
- `Checkbox:isChecked`: Returns true if checked is enabled for this Checkbox widget.
- `Checkbox:setText`: Sets the text for this Checkbox widget.
- `Checkbox:getText`: Returns the text of this Checkbox widget.

### `Color_Picker` Methods
- `Color_Picker:getColor`: Returns the color of this Color_Picker widget.
- `Color_Picker:setColor`: Sets the color for this Color_Picker widget.
- `Color_Picker:getShowAlpha`: Returns the show alpha of this Color_Picker widget.
- `Color_Picker:setShowAlpha`: Sets the show alpha for this Color_Picker widget.
- `Color_Picker:getColorMode`: Returns the color mode of this Color_Picker widget.
- `Color_Picker:setColorMode`: Sets the color mode for this Color_Picker widget.
- `Color_Picker:setOnChange`: Registers a callback invoked when this widget's value changes.

### `Combo_Box` Methods
- `Combo_Box:addItem`: Adds a item entry to this Combo_Box widget.
- `Combo_Box:removeItem`: Removes the item from this Combo_Box widget.
- `Combo_Box:clearItems`: Clears all items entries from this Combo_Box widget.
- `Combo_Box:getItemCount`: Returns the item count of this Combo_Box widget.
- `Combo_Box:getItem`: Returns the item of this Combo_Box widget.
- `Combo_Box:setSelectedIndex`: Sets the selected index for this Combo_Box widget.
- `Combo_Box:getSelectedIndex`: Returns the selected index of this Combo_Box widget.
- `Combo_Box:getSelectedItem`: Returns the selected item of this Combo_Box widget.

### `Dialog` Methods
- `Dialog:getTitle`: Returns the title of this Dialog widget.
- `Dialog:setTitle`: Sets the title for this Dialog widget.
- `Dialog:isModal`: Returns true if modal is enabled for this Dialog widget.
- `Dialog:setModal`: Sets the modal for this Dialog widget.
- `Dialog:isOpen`: Returns true if open is enabled for this Dialog widget.
- `Dialog:open`: Performs the open operation on this Dialog widget.
- `Dialog:close`: Closes and removes this dialog from the screen.
- `Dialog:setOnClose`: Registers a callback invoked when this dialog is closed.
- `Dialog:setContent`: Sets the content for this Dialog widget.
- `Dialog:getContent`: Returns the content of this Dialog widget.
- `Dialog:addButton`: Adds a button entry to this Dialog widget.

### `Dock_Panel` Methods
- `Dock_Panel:dock`: Performs the dock operation on this Dock_Panel widget.
- `Dock_Panel:undock`: Performs the undock operation on this Dock_Panel widget.
- `Dock_Panel:getDockedCount`: Returns the docked count of this Dock_Panel widget.
- `Dock_Panel:setSplitSize`: Sets the split size for this Dock_Panel widget.
- `Dock_Panel:getSplitSize`: Returns the split size of this Dock_Panel widget.

### `Gui_Table` Methods
- `Gui_Table:addColumn`: Adds a column entry to this Gui_Table widget.
- `Gui_Table:getColumnCount`: Returns the column count of this Gui_Table widget.
- `Gui_Table:addRow`: Adds a row entry to this Gui_Table widget.
- `Gui_Table:getRowCount`: Returns the row count of this Gui_Table widget.
- `Gui_Table:getCell`: Returns the cell of this Gui_Table widget.
- `Gui_Table:setCell`: Sets the cell for this Gui_Table widget.
- `Gui_Table:getSelectedRow`: Returns the selected row of this Gui_Table widget.
- `Gui_Table:setSelectedRow`: Sets the selected row for this Gui_Table widget.
- `Gui_Table:isSortable`: Returns true if sortable is enabled for this Gui_Table widget.
- `Gui_Table:setSortable`: Sets the sortable for this Gui_Table widget.
- `Gui_Table:setOnSelect`: Registers a callback invoked when a table row is selected.

### `Gui_Window` Methods
- `Gui_Window:getTitle`: Returns the title of this Gui_Window widget.
- `Gui_Window:setTitle`: Sets the title for this Gui_Window widget.
- `Gui_Window:isCloseable`: Returns true if closeable is enabled for this Gui_Window widget.
- `Gui_Window:setCloseable`: Sets the closeable for this Gui_Window widget.
- `Gui_Window:isDraggable`: Returns true if draggable is enabled for this Gui_Window widget.
- `Gui_Window:setDraggable`: Sets the draggable for this Gui_Window widget.
- `Gui_Window:isResizable`: Returns true if resizable is enabled for this Gui_Window widget.
- `Gui_Window:setResizable`: Sets the resizable for this Gui_Window widget.
- `Gui_Window:setOnClose`: Registers a callback invoked when this window is closed.

### `Image_Widget` Methods
- `Image_Widget:getScaleMode`: Returns the scale mode of this Image_Widget widget.
- `Image_Widget:setScaleMode`: Sets the scale mode for this Image_Widget widget.
- `Image_Widget:getTint`: Returns the tint of this Image_Widget widget.
- `Image_Widget:setTint`: Sets the tint for this Image_Widget widget.
- `Image_Widget:newButton`: Creates and returns a new interactive button widget as a child of this widget.
- `Image_Widget:newLabel`: Creates a text label widget.
- `Image_Widget:newTextInput`: Creates a text input widget.
- `Image_Widget:newCheckbox`: Creates a checkbox widget.
- `Image_Widget:newSlider`: Creates a value slider widget.
- `Image_Widget:newProgressBar`: Creates a progress bar widget.
- `Image_Widget:newComboBox`: Creates a dropdown combo box widget.
- `Image_Widget:newList`: Creates a selectable list widget.
- `Image_Widget:newPanel`: Creates a container panel widget.
- `Image_Widget:newLayout`: Creates a flexbox layout container.
- `Image_Widget:newScrollPanel`: Creates a scrollable panel widget.
- `Image_Widget:newNinePatch`: Creates a 9-patch slicer widget.
- `Image_Widget:newTabBar`: Creates a tab bar widget.
- `Image_Widget:newSeparator`: Creates a separator line.
- `Image_Widget:newSpacer`: Creates a spacing filler widget.
- `Image_Widget:newToast`: Creates a toast notification widget.
- `Image_Widget:newTreeView`: Creates a collapsible tree view widget.
- `Image_Widget:newRadioButton`: Creates a grouped radio button widget.
- `Image_Widget:newScrollBar`: Creates a scroll bar widget.
- `Image_Widget:newWindow`: Creates a draggable window widget.
- `Image_Widget:newSplitPanel`: Creates a resizable split panel.
- `Image_Widget:newDockPanel`: Creates and returns a new docking panel that arranges children along its edges.
- `Image_Widget:newToolbar`: Creates a toolbar widget.
- `Image_Widget:newMenuBar`: Creates a menu bar widget.
- `Image_Widget:newMenuItem`: Creates a menu item widget.
- `Image_Widget:newDialog`: Creates a modal dialog widget.
- `Image_Widget:newStatusBar`: Creates a status bar widget.
- `Image_Widget:newAccordion`: Creates a collapsible accordion widget.
- `Image_Widget:newTooltipPanel`: Creates a tooltip panel widget.
- `Image_Widget:newColorPicker`: Creates a color picker widget.
- `Image_Widget:newTable`: Creates a data table widget.
- `Image_Widget:newImageWidget`: Creates an image display widget.
- `Image_Widget:newTheme`: Creates a new theme instance.
- `Image_Widget:setTheme`: Sets the active GUI theme.
- `Image_Widget:getTheme`: Returns whether a theme is set.
- `Image_Widget:getRoot`: Returns the root panel widget table.
- `Image_Widget:setFocus`: Sets keyboard focus to a widget or clears it.
- `Image_Widget:getFocus`: Returns the focused widget index or nil.
- `Image_Widget:focusNext`: Moves focus to the next focusable widget.
- `Image_Widget:focusPrev`: Moves focus to the previous focusable widget.
- `Image_Widget:clearFocus`: Removes keyboard focus from this widget so key events go to the next focusable.
- `Image_Widget:addToast`: Queues a toast notification from a table.
- `Image_Widget:getToastCount`: Returns the number of active toasts.
- `Image_Widget:mousepressed`: Forwards a mouse press event to the GUI.
- `Image_Widget:mousereleased`: Forwards a mouse release event to the GUI.
- `Image_Widget:mousemoved`: Forwards a mouse move event to the GUI.
- `Image_Widget:keypressed`: Forwards a key press event to the GUI.
- `Image_Widget:textinput`: Forwards text input to the focused text input widget.
- `Image_Widget:wheelmoved`: Forwards a mouse wheel event to the GUI.
- `Image_Widget:update`: Advances toast timers, removes expired toasts, and dispatches pending GUI events.
- `Image_Widget:draw`: Headless compatibility stub for GUI draw.
- `Image_Widget:getWidgetCount`: Returns the total widget count in the context.
- `Image_Widget:drawToImage`: Renders the UI widget tree to a CPU ImageData at the given resolution.
- `Image_Widget:newLineChart`: Creates a new line chart.
- `Image_Widget:newBarChart`: Creates and returns a new bar chart widget attached to this image widget.
- `Image_Widget:newScatterPlot`: Creates a new scatter plot.
- `Image_Widget:newPieChart`: Creates and returns a new pie chart widget attached to this image widget.
- `Image_Widget:newAreaChart`: Creates a new stacked-area chart.
- `Image_Widget:newLineChart`: Creates a new line chart.
- `Image_Widget:newBarChart`: Creates and returns a new bar chart widget attached to this image widget.
- `Image_Widget:newScatterPlot`: Creates a new scatter plot.
- `Image_Widget:newPieChart`: Creates and returns a new pie chart widget attached to this image widget.
- `Image_Widget:newAreaChart`: Creates a new stacked-area chart.
- `Image_Widget:parseWidgetState`: Parses a widget state string, returning the canonical form or nil if invalid.
- `Image_Widget:newSpinBox`: Creates a numeric spin box widget with increment and decrement buttons.
- `Image_Widget:newSwitch`: Creates a toggle switch widget.
- `Image_Widget:newBadge`: Creates a badge widget displaying a numeric count.
- `Image_Widget:setDefaultTheme`: Installs the built-in dark theme as the active GUI theme.
- `Image_Widget:setViewport`: Sets the viewport dimensions used for anchor constraints and layout.
- `Image_Widget:flushCache`: Returns true if the widget tree changed since the last call, then resets the flag.
- `Image_Widget:update_bindings`: Updates all widgets that have a data-binding key registered via `:bind(key)`.
- `Image_Widget:loadLayout`: Load a widget tree from a Lua table definition and attach it to the UI
- `Image_Widget:loadLayoutFile`: Load a widget tree from a TOML layout file and attach it to the UI root.
- `Image_Widget:renderToImage`: Render the current UI widget tree to a PNG file for testing purposes.
- `Image_Widget:loadLayout`: Load a widget tree from a Lua table definition and attach it to the UI
- `Image_Widget:loadLayoutFile`: Load a widget tree from a TOML layout file and attach it to the UI root.
- `Image_Widget:renderToImage`: Render the current UI widget tree to a PNG file for testing purposes.

### `Label` Methods
- `Label:setText`: Sets the text for this Label widget.
- `Label:getText`: Returns the text of this Label widget.

### `Layout` Methods
- `Layout:setDirection`: Sets the direction for this Layout widget.
- `Layout:getDirection`: Returns the direction of this Layout widget.
- `Layout:setSpacing`: Sets the spacing for this Layout widget.
- `Layout:getSpacing`: Returns the spacing of this Layout widget.
- `Layout:setColumns`: Sets the columns for this Layout widget.
- `Layout:setWrap`: Sets the wrap for this Layout widget.
- `Layout:getWrap`: Returns the wrap of this Layout widget.
- `Layout:setAlign`: Sets the align for this Layout widget.
- `Layout:getAlign`: Returns the align of this Layout widget.
- `Layout:setJustify`: Sets the justify for this Layout widget.
- `Layout:getJustify`: Returns the justify of this Layout widget.

### `LineChart` Methods
- `LineChart:setYMax`: Sets the maximum Y value for axis scaling.
- `LineChart:setXMax`: Sets the maximum X value for axis scaling.
- `LineChart:drawToImage`: Renders the line chart into an existing ImageData.

### `List_Box` Methods
- `List_Box:addItem`: Adds a item entry to this List_Box widget.
- `List_Box:removeItem`: Removes the item from this List_Box widget.
- `List_Box:clearItems`: Clears all items entries from this List_Box widget.
- `List_Box:getItemCount`: Returns the item count of this List_Box widget.
- `List_Box:getItem`: Returns the item of this List_Box widget.
- `List_Box:setSelectedIndex`: Sets the selected index for this List_Box widget.
- `List_Box:getSelectedIndex`: Returns the selected index of this List_Box widget.
- `List_Box:setItemHeight`: Sets the item height for this List_Box widget.

### `Menu_Bar` Methods
- `Menu_Bar:addMenu`: Adds a menu entry to this Menu_Bar widget.
- `Menu_Bar:removeMenu`: Removes the menu from this Menu_Bar widget.
- `Menu_Bar:getMenus`: Returns the menus of this Menu_Bar widget.
- `Menu_Bar:getMenuCount`: Returns the menu count of this Menu_Bar widget.

### `Menu_Item` Methods
- `Menu_Item:getText`: Returns the text of this Menu_Item widget.
- `Menu_Item:setText`: Sets the text for this Menu_Item widget.
- `Menu_Item:getShortcut`: Returns the shortcut of this Menu_Item widget.
- `Menu_Item:setShortcut`: Sets the shortcut for this Menu_Item widget.
- `Menu_Item:isChecked`: Returns true if checked is enabled for this Menu_Item widget.
- `Menu_Item:setChecked`: Sets the checked for this Menu_Item widget.
- `Menu_Item:addSubItem`: Adds a sub item entry to this Menu_Item widget.
- `Menu_Item:getSubItems`: Returns the sub items of this Menu_Item widget.
- `Menu_Item:setOnClick`: Registers a callback invoked when this menu item is clicked.

### `Nine_Patch` Methods
- `Nine_Patch:setInsets`: Sets the insets for this Nine_Patch widget.
- `Nine_Patch:getInsets`: Returns the insets of this Nine_Patch widget.
- `Nine_Patch:setImageDimensions`: Sets the image dimensions for this Nine_Patch widget.
- `Nine_Patch:getImageDimensions`: Returns the image dimensions of this Nine_Patch widget.
- `Nine_Patch:getSlices`: Returns the slices of this Nine_Patch widget.

### `Panel` Methods
- `Panel:setTitle`: Sets the title for this Panel widget.
- `Panel:getTitle`: Returns the title of this Panel widget.
- `Panel:setScrollable`: Sets the scrollable for this Panel widget.

### `PieChart` Methods
- `PieChart:drawToImage`: Renders the pie chart into an existing ImageData.

### `Progress_Bar` Methods
- `Progress_Bar:setValue`: Sets the value for this Progress_Bar widget.
- `Progress_Bar:getValue`: Returns the value of this Progress_Bar widget.
- `Progress_Bar:getProgress`: Returns the progress of this Progress_Bar widget.
- `Progress_Bar:setRange`: Sets the range for this Progress_Bar widget.
- `Progress_Bar:getMin`: Returns the min of this Progress_Bar widget.
- `Progress_Bar:getMax`: Returns the max of this Progress_Bar widget.

### `Radio_Button` Methods
- `Radio_Button:getText`: Returns the text of this Radio_Button widget.
- `Radio_Button:setText`: Sets the text for this Radio_Button widget.
- `Radio_Button:isSelected`: Returns true if selected is enabled for this Radio_Button widget.
- `Radio_Button:setSelected`: Sets the selected for this Radio_Button widget.
- `Radio_Button:getGroup`: Returns the group of this Radio_Button widget.
- `Radio_Button:setGroup`: Sets the group for this Radio_Button widget.
- `Radio_Button:setOnChange`: Registers a callback invoked when this widget's value changes.

### `ScatterPlot` Methods
- `ScatterPlot:setXRange`: Sets the X-axis data range.
- `ScatterPlot:setYRange`: Sets the Y-axis data range.
- `ScatterPlot:drawToImage`: Renders the scatter plot into an existing ImageData.

### `Scroll_Bar` Methods
- `Scroll_Bar:getScrollPosition`: Returns the scroll position of this Scroll_Bar widget.
- `Scroll_Bar:setScrollPosition`: Sets the scroll position for this Scroll_Bar widget.
- `Scroll_Bar:getContentSize`: Returns the content size of this Scroll_Bar widget.
- `Scroll_Bar:setContentSize`: Sets the content size for this Scroll_Bar widget.
- `Scroll_Bar:getViewSize`: Returns the view size of this Scroll_Bar widget.
- `Scroll_Bar:setViewSize`: Sets the view size for this Scroll_Bar widget.
- `Scroll_Bar:isVertical`: Returns true if vertical is enabled for this Scroll_Bar widget.
- `Scroll_Bar:setOnChange`: Registers a callback invoked when this widget's value changes.

### `Scroll_Panel` Methods
- `Scroll_Panel:setContentSize`: Sets the content size for this Scroll_Panel widget.
- `Scroll_Panel:getContentSize`: Returns the content size of this Scroll_Panel widget.
- `Scroll_Panel:setScrollPosition`: Sets the scroll position for this Scroll_Panel widget.
- `Scroll_Panel:getScrollPosition`: Returns the scroll position of this Scroll_Panel widget.
- `Scroll_Panel:getMaxScroll`: Returns the max scroll of this Scroll_Panel widget.
- `Scroll_Panel:setScrollSpeed`: Sets the scroll speed for this Scroll_Panel widget.
- `Scroll_Panel:getScrollSpeed`: Returns the scroll speed of this Scroll_Panel widget.

### `Separator` Methods
- `Separator:setVertical`: Sets the vertical for this Separator widget.
- `Separator:isVertical`: Returns true if vertical is enabled for this Separator widget.
- `Separator:setThickness`: Sets the thickness for this Separator widget.
- `Separator:getThickness`: Returns the thickness of this Separator widget.

### `Slider` Methods
- `Slider:setValue`: Sets the value for this Slider widget.
- `Slider:getValue`: Returns the value of this Slider widget.
- `Slider:setRange`: Sets the range for this Slider widget.
- `Slider:setStep`: Sets the step for this Slider widget.
- `Slider:getMin`: Returns the min of this Slider widget.
- `Slider:getMax`: Returns the max of this Slider widget.

### `Spin_Box` Methods
- `Spin_Box:setValue`: Sets the value for this SpinBox widget.
- `Spin_Box:getValue`: Returns the current value of this SpinBox widget.
- `Spin_Box:increment`: Increments the value by one step.
- `Spin_Box:decrement`: Decrements the value by one step.
- `Spin_Box:setRange`: Sets the valid range for this SpinBox widget.
- `Spin_Box:setStep`: Sets the increment step for this SpinBox widget.

### `Split_Panel` Methods
- `Split_Panel:getOrientation`: Returns the orientation of this Split_Panel widget.
- `Split_Panel:setOrientation`: Sets the orientation for this Split_Panel widget.
- `Split_Panel:getSplitPosition`: Returns the split position of this Split_Panel widget.
- `Split_Panel:setSplitPosition`: Sets the split position for this Split_Panel widget.
- `Split_Panel:getMinPanelSize`: Returns the min panel size of this Split_Panel widget.
- `Split_Panel:setMinPanelSize`: Sets the min panel size for this Split_Panel widget.
- `Split_Panel:setFirstChild`: Sets the first child for this Split_Panel widget.
- `Split_Panel:setSecondChild`: Sets the second child for this Split_Panel widget.
- `Split_Panel:getFirstChild`: Returns the first child of this Split_Panel widget.
- `Split_Panel:getSecondChild`: Returns the second child of this Split_Panel widget.

### `Status_Bar` Methods
- `Status_Bar:addSection`: Adds a section entry to this Status_Bar widget.
- `Status_Bar:setSectionText`: Sets the section text for this Status_Bar widget.
- `Status_Bar:getSectionText`: Returns the section text of this Status_Bar widget.
- `Status_Bar:getSectionCount`: Returns the section count of this Status_Bar widget.
- `Status_Bar:setSectionCount`: Resizes the section list for this Status_Bar widget.
- `Status_Bar:setSectionWidget`: Compatibility shim for assigning a widget to a section.

### `Switch` Methods
- `Switch:setOn`: Sets the on/off state of this Switch widget.
- `Switch:isOn`: Returns the on/off state of this Switch widget.
- `Switch:toggle`: Toggles the on/off state of this Switch widget.

### `Tab_Bar` Methods
- `Tab_Bar:addTab`: Adds a tab entry to this Tab_Bar widget.
- `Tab_Bar:removeTab`: Removes the tab from this Tab_Bar widget.
- `Tab_Bar:getTab`: Returns the tab of this Tab_Bar widget.
- `Tab_Bar:getTabCount`: Returns the tab count of this Tab_Bar widget.
- `Tab_Bar:setActiveTab`: Sets the active tab for this Tab_Bar widget.
- `Tab_Bar:getActiveTab`: Returns the active tab of this Tab_Bar widget.

### `Text_Input` Methods
- `Text_Input:setText`: Sets the text for this Text_Input widget.
- `Text_Input:getText`: Returns the text of this Text_Input widget.
- `Text_Input:setPlaceholder`: Sets the placeholder for this Text_Input widget.
- `Text_Input:getPlaceholder`: Returns the placeholder of this Text_Input widget.
- `Text_Input:setMaxLength`: Sets the max length for this Text_Input widget.
- `Text_Input:isFocused`: Returns true if focused is enabled for this Text_Input widget.
- `Text_Input:getCursorPosition`: Returns the cursor position of this Text_Input widget.

### `Toast` Methods
- `Toast:setMessage`: Sets the message for this Toast widget.
- `Toast:getMessage`: Returns the message of this Toast widget.
- `Toast:setDuration`: Sets the duration for this Toast widget.
- `Toast:getDuration`: Returns the duration of this Toast widget.
- `Toast:getProgress`: Returns the progress of this Toast widget.
- `Toast:isExpired`: Returns true if expired is enabled for this Toast widget.

### `Toolbar` Methods
- `Toolbar:getOrientation`: Returns the orientation of this Toolbar widget.
- `Toolbar:setOrientation`: Sets the orientation for this Toolbar widget.
- `Toolbar:addButton`: Adds a button entry to this Toolbar widget.
- `Toolbar:addSeparator`: Adds a separator entry to this Toolbar widget.
- `Toolbar:addSpacer`: Adds a spacer entry to this Toolbar widget.
- `Toolbar:getButton`: Returns the button of this Toolbar widget.
- `Toolbar:setButtonEnabled`: Sets the button enabled for this Toolbar widget.
- `Toolbar:setButtonToggled`: Sets the button toggled for this Toolbar widget.
- `Toolbar:isButtonToggled`: Returns true if button toggled is enabled for this Toolbar widget.

### `Tooltip_Panel` Methods
- `Tooltip_Panel:getText`: Returns the text of this Tooltip_Panel widget.
- `Tooltip_Panel:setText`: Sets the text for this Tooltip_Panel widget.
- `Tooltip_Panel:getDelay`: Returns the delay of this Tooltip_Panel widget.
- `Tooltip_Panel:setDelay`: Sets the delay for this Tooltip_Panel widget.
- `Tooltip_Panel:getTarget`: Returns the target of this Tooltip_Panel widget.
- `Tooltip_Panel:setTarget`: Sets the target for this Tooltip_Panel widget.

### `Tree_View` Methods
- `Tree_View:addNode`: Adds a node entry to this Tree_View widget.
- `Tree_View:toggleNode`: Toggles the expanded/collapsed status of a Tree_View node.
- `Tree_View:isExpanded`: Returns true if expanded is enabled for this Tree_View widget.
- `Tree_View:getNodeCount`: Returns the node count of this Tree_View widget.
- `Tree_View:removeNode`: Removes the node from this Tree_View widget.
- `Tree_View:clearNodes`: Clears all nodes entries from this Tree_View widget.
- `Tree_View:getNodeText`: Returns the node text of this Tree_View widget.
- `Tree_View:setNodeText`: Sets the node text for this Tree_View widget.
- `Tree_View:setNodeIcon`: Sets the node icon for this Tree_View widget.
- `Tree_View:expandNode`: Performs the expand node operation on this Tree_View widget.
- `Tree_View:collapseNode`: Performs the collapse node operation on this Tree_View widget.
- `Tree_View:isNodeExpanded`: Returns true if node expanded is enabled for this Tree_View widget.
- `Tree_View:expandAll`: Performs the expand all operation on this Tree_View widget.
- `Tree_View:collapseAll`: Performs the collapse all operation on this Tree_View widget.
- `Tree_View:setSelectedNode`: Sets the selected node for this Tree_View widget.
- `Tree_View:getSelectedNode`: Returns the selected node of this Tree_View widget.
- `Tree_View:getChildNodes`: Returns the child nodes of this Tree_View widget.
- `Tree_View:getParentNode`: Returns the parent node of this Tree_View widget.
- `Tree_View:getNodeDepth`: Returns the node depth of this Tree_View widget.

## References

- `image`: Imports or references `image` from `src/image/`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/ui/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
