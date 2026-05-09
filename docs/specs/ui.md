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
- `GuiContext::add_custom_widget` (`context.rs`): Add a custom Lua-driven widget and return its pool index.
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
- `CustomWidget::new` (`extras.rs`): Create a new custom widget.
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
- `lurek.ui.newButton`: Creates and returns a new interactive button widget as a child of this widget.
- `lurek.ui.newLabel`: Creates a text label widget.
- `lurek.ui.newTextInput`: Creates a text input widget.
- `lurek.ui.newCheckbox`: Creates a checkbox widget.
- `lurek.ui.newSlider`: Creates a value slider widget.
- `lurek.ui.newProgressBar`: Creates a progress bar widget.
- `lurek.ui.newComboBox`: Creates a dropdown combo box widget.
- `lurek.ui.newList`: Creates a selectable list widget.
- `lurek.ui.newPanel`: Creates a container panel widget.
- `lurek.ui.newLayout`: Creates a flexbox layout container.
- `lurek.ui.newScrollPanel`: Creates a scrollable panel widget.
- `lurek.ui.newNinePatch`: Creates a 9-patch slicer widget.
- `lurek.ui.newTabBar`: Creates a tab bar widget.
- `lurek.ui.newSeparator`: Creates a separator line.
- `lurek.ui.newSpacer`: Creates a spacing filler widget.
- `lurek.ui.newToast`: Creates a toast notification widget.
- `lurek.ui.newTreeView`: Creates a collapsible tree view widget.
- `lurek.ui.newRadioButton`: Creates a grouped radio button widget.
- `lurek.ui.newScrollBar`: Creates a scroll bar widget.
- `lurek.ui.newWindow`: Creates a draggable window widget.
- `lurek.ui.newSplitPanel`: Creates a resizable split panel.
- `lurek.ui.newDockPanel`: Creates and returns a new docking panel that arranges children along its edges.
- `lurek.ui.newToolbar`: Creates a toolbar widget.
- `lurek.ui.newMenuBar`: Creates a menu bar widget.
- `lurek.ui.newMenuItem`: Creates a menu item widget.
- `lurek.ui.newDialog`: Creates a modal dialog widget.
- `lurek.ui.newStatusBar`: Creates a status bar widget.
- `lurek.ui.newAccordion`: Creates a collapsible accordion widget.
- `lurek.ui.newTooltipPanel`: Creates a tooltip panel widget.
- `lurek.ui.newColorPicker`: Creates a color picker widget.
- `lurek.ui.newTable`: Creates a data table widget.
- `lurek.ui.newImageWidget`: Creates an image display widget.
- `lurek.ui.newTheme`: Creates a new theme instance.
- `lurek.ui.setTheme`: Sets the active GUI theme.
- `lurek.ui.getTheme`: Returns whether a theme is set.
- `lurek.ui.getRoot`: Returns the root panel widget table.
- `lurek.ui.setFocus`: Sets keyboard focus to a widget or clears it.
- `lurek.ui.getFocus`: Returns the focused widget index or nil.
- `lurek.ui.focusNext`: Moves focus to the next focusable widget.
- `lurek.ui.focusPrev`: Moves focus to the previous focusable widget.
- `lurek.ui.clearFocus`: Removes keyboard focus from this widget so key events go to the next focusable.
- `lurek.ui.addToast`: Queues a toast notification from a table.
- `lurek.ui.getToastCount`: Returns the number of active toasts.
- `lurek.ui.mousepressed`: Forwards a mouse press event to the GUI.
- `lurek.ui.mousereleased`: Forwards a mouse release event to the GUI.
- `lurek.ui.mousemoved`: Forwards a mouse move event to the GUI.
- `lurek.ui.keypressed`: Forwards a key press event to the GUI.
- `lurek.ui.textinput`: Forwards text input to the focused text input widget.
- `lurek.ui.wheelmoved`: Forwards a mouse wheel event to the GUI.
- `lurek.ui.update`: Advances toast timers, removes expired toasts, and dispatches pending GUI events.
- `lurek.ui.draw`: Invokes all registered `on_draw` callbacks with a screen-space rect table.
- `lurek.ui.newCustomWidget`: Creates a new widget with custom Lua-driven rendering.
- `lurek.ui.getWidgetCount`: Returns the total widget count in the context.
- `lurek.ui.drawToImage`: Renders the UI widget tree to a CPU ImageData at the given resolution.
- `lurek.ui.newLineChart`: Creates a new line chart.
- `lurek.ui.newBarChart`: Creates and returns a new bar chart widget attached to this image widget.
- `lurek.ui.newScatterPlot`: Creates a new scatter plot.
- `lurek.ui.newPieChart`: Creates and returns a new pie chart widget attached to this image widget.
- `lurek.ui.newAreaChart`: Creates a new stacked-area chart.
- `lurek.ui.parseWidgetState`: Parses a widget state string and returns its canonical form.
- `lurek.ui.newSpinBox`: Creates a numeric spin box widget with increment and decrement buttons.
- `lurek.ui.newSwitch`: Creates a toggle switch widget.
- `lurek.ui.newBadge`: Creates a badge widget displaying a numeric count.
- `lurek.ui.setDefaultTheme`: Installs the built-in dark theme as the active GUI theme.
- `lurek.ui.setViewport`: Sets the viewport dimensions used for anchor constraints and layout.
- `lurek.ui.flushCache`: Returns true if the widget tree changed since the last call, then resets the flag.
- `lurek.ui.update_bindings`: Updates widgets whose bound keys match values in the provided data table.
- `lurek.ui.loadLayout`: Loads a widget tree from a Lua definition table and attaches it to the UI root.
- `lurek.ui.loadLayoutFile`: Loads a widget tree from a TOML layout file and attaches it to the UI root.
- `lurek.ui.renderToImage`: Renders the current UI widget tree to a PNG file for testing.

### `LAccordion` Methods
- `LAccordion:addSection`: Adds a section entry to this Accordion widget.
- `LAccordion:getSectionCount`: Returns the section count of this Accordion widget.
- `LAccordion:toggleSection`: Toggles the expanded/collapsed status of an Accordion section.
- `LAccordion:isSectionExpanded`: Returns true if section expanded is enabled for this Accordion widget.
- `LAccordion:isExclusive`: Returns true if exclusive is enabled for this Accordion widget.
- `LAccordion:setExclusive`: Sets the exclusive for this Accordion widget.
- `LAccordion:getSectionTitle`: Returns the section title of this Accordion widget.

### `LAreaChart` Methods
- `LAreaChart:addLayer`: Adds a stacked layer with values and colour.
- `LAreaChart:setYMax`: Sets the maximum Y value for axis scaling.
- `LAreaChart:drawToImage`: Renders the area chart into an existing ImageData.
- `LAreaChart:type`: Returns the type name of this object.
- `LAreaChart:typeOf`: Returns true if this object is of the given type.

### `LBadge` Methods
- `LBadge:setCount`: Sets the count displayed on this Badge widget.
- `LBadge:getCount`: Returns the raw count of this Badge widget.
- `LBadge:getDisplayText`: Returns the display text of this Badge widget, e.g. "99+" when over the max.

### `LBarChart` Methods
- `LBarChart:addSeries`: Adds a bar series with a name and colour.
- `LBarChart:addCategory`: Adds a category group with per-series values.
- `LBarChart:drawToImage`: Renders the bar chart into an existing ImageData.
- `LBarChart:type`: Returns the type name of this object.
- `LBarChart:typeOf`: Returns true if this object is of the given type.

### `LButton` Methods
- `LButton:setText`: Sets the text for this Button widget.
- `LButton:getText`: Returns the text of this Button widget.

### `LCheckbox` Methods
- `LCheckbox:setChecked`: Sets the checked for this Checkbox widget.
- `LCheckbox:isChecked`: Returns true if checked is enabled for this Checkbox widget.
- `LCheckbox:setText`: Sets the text for this Checkbox widget.
- `LCheckbox:getText`: Returns the text of this Checkbox widget.

### `LColorPicker` Methods
- `LColorPicker:getColor`: Returns the color of this Color_Picker widget.
- `LColorPicker:setColor`: Sets the color for this Color_Picker widget.
- `LColorPicker:getShowAlpha`: Returns the show alpha of this Color_Picker widget.
- `LColorPicker:setShowAlpha`: Sets the show alpha for this Color_Picker widget.
- `LColorPicker:getColorMode`: Returns the color mode of this Color_Picker widget.
- `LColorPicker:setColorMode`: Sets the color mode for this Color_Picker widget.
- `LColorPicker:setOnChange`: Registers a callback invoked when this widget's value changes.

### `LComboBox` Methods
- `LComboBox:addItem`: Adds a item entry to this Combo_Box widget.
- `LComboBox:removeItem`: Removes the item from this Combo_Box widget.
- `LComboBox:clearItems`: Clears all items entries from this Combo_Box widget.
- `LComboBox:getItemCount`: Returns the item count of this Combo_Box widget.
- `LComboBox:getItem`: Returns the item of this Combo_Box widget.
- `LComboBox:setSelectedIndex`: Sets the selected index for this Combo_Box widget.
- `LComboBox:getSelectedIndex`: Returns the selected index of this Combo_Box widget.
- `LComboBox:getSelectedItem`: Returns the selected item of this Combo_Box widget.

### `LDialog` Methods
- `LDialog:getTitle`: Returns the title of this Dialog widget.
- `LDialog:setTitle`: Sets the title for this Dialog widget.
- `LDialog:isModal`: Returns true if modal is enabled for this Dialog widget.
- `LDialog:setModal`: Sets the modal for this Dialog widget.
- `LDialog:isOpen`: Returns true if open is enabled for this Dialog widget.
- `LDialog:open`: Performs the open operation on this Dialog widget.
- `LDialog:close`: Closes and removes this dialog from the screen.
- `LDialog:setOnClose`: Registers a callback invoked when this dialog is closed.
- `LDialog:setContent`: Sets the content for this Dialog widget.
- `LDialog:getContent`: Returns the content of this Dialog widget.
- `LDialog:addButton`: Adds a button entry to this Dialog widget.

### `LDockPanel` Methods
- `LDockPanel:dock`: Performs the dock operation on this Dock_Panel widget.
- `LDockPanel:undock`: Performs the undock operation on this Dock_Panel widget.
- `LDockPanel:getDockedCount`: Returns the docked count of this Dock_Panel widget.
- `LDockPanel:setSplitSize`: Sets the split size for this Dock_Panel widget.
- `LDockPanel:getSplitSize`: Returns the split size of this Dock_Panel widget.

### `LGuiTable` Methods
- `LGuiTable:addColumn`: Adds a column entry to this Gui_Table widget.
- `LGuiTable:getColumnCount`: Returns the column count of this Gui_Table widget.
- `LGuiTable:addRow`: Adds a row entry to this Gui_Table widget.
- `LGuiTable:getRowCount`: Returns the row count of this Gui_Table widget.
- `LGuiTable:getCell`: Returns the cell of this Gui_Table widget.
- `LGuiTable:setCell`: Sets the cell for this Gui_Table widget.
- `LGuiTable:getSelectedRow`: Returns the selected row of this Gui_Table widget.
- `LGuiTable:setSelectedRow`: Sets the selected row for this Gui_Table widget.
- `LGuiTable:isSortable`: Returns true if sortable is enabled for this Gui_Table widget.
- `LGuiTable:setSortable`: Sets the sortable for this Gui_Table widget.
- `LGuiTable:setOnSelect`: Registers a callback invoked when a table row is selected.

### `LGuiWindow` Methods
- `LGuiWindow:getTitle`: Returns the title of this Gui_Window widget.
- `LGuiWindow:setTitle`: Sets the title for this Gui_Window widget.
- `LGuiWindow:isCloseable`: Returns true if closeable is enabled for this Gui_Window widget.
- `LGuiWindow:setCloseable`: Sets the closeable for this Gui_Window widget.
- `LGuiWindow:isDraggable`: Returns true if draggable is enabled for this Gui_Window widget.
- `LGuiWindow:setDraggable`: Sets the draggable for this Gui_Window widget.
- `LGuiWindow:isResizable`: Returns true if resizable is enabled for this Gui_Window widget.
- `LGuiWindow:setResizable`: Sets the resizable for this Gui_Window widget.
- `LGuiWindow:setOnClose`: Registers a callback invoked when this window is closed.

### `LImageWidget` Methods
- `LImageWidget:getScaleMode`: Returns the scale mode of this Image_Widget widget.
- `LImageWidget:setScaleMode`: Sets the scale mode for this Image_Widget widget.
- `LImageWidget:getTint`: Returns the tint of this Image_Widget widget.
- `LImageWidget:setTint`: Sets the tint for this Image_Widget widget.

### `LLabel` Methods
- `LLabel:setText`: Sets the text for this Label widget.
- `LLabel:getText`: Returns the text of this Label widget.

### `LLayout` Methods
- `LLayout:setDirection`: Sets the direction for this Layout widget.
- `LLayout:getDirection`: Returns the direction of this Layout widget.
- `LLayout:setSpacing`: Sets the spacing for this Layout widget.
- `LLayout:getSpacing`: Returns the spacing of this Layout widget.
- `LLayout:setColumns`: Sets the columns for this Layout widget.
- `LLayout:setWrap`: Sets the wrap for this Layout widget.
- `LLayout:getWrap`: Returns the wrap of this Layout widget.
- `LLayout:setAlign`: Sets the align for this Layout widget.
- `LLayout:getAlign`: Returns the align of this Layout widget.
- `LLayout:setJustify`: Sets the justify for this Layout widget.
- `LLayout:getJustify`: Returns the justify of this Layout widget.

### `LLineChart` Methods
- `LLineChart:addSeries`: Adds a named data series to the chart.
- `LLineChart:setYMax`: Sets the maximum Y value for axis scaling.
- `LLineChart:setXMax`: Sets the maximum X value for axis scaling.
- `LLineChart:drawToImage`: Renders the line chart into an existing ImageData.
- `LLineChart:type`: Returns the type name of this object.
- `LLineChart:typeOf`: Returns true if this object is of the given type.

### `LListBox` Methods
- `LListBox:addItem`: Adds a item entry to this List_Box widget.
- `LListBox:removeItem`: Removes the item from this List_Box widget.
- `LListBox:clearItems`: Clears all items entries from this List_Box widget.
- `LListBox:getItemCount`: Returns the item count of this List_Box widget.
- `LListBox:getItem`: Returns the item of this List_Box widget.
- `LListBox:setSelectedIndex`: Sets the selected index for this List_Box widget.
- `LListBox:getSelectedIndex`: Returns the selected index of this List_Box widget.
- `LListBox:setItemHeight`: Sets the item height for this List_Box widget.

### `LMenuBar` Methods
- `LMenuBar:addMenu`: Adds a menu entry to this Menu_Bar widget.
- `LMenuBar:removeMenu`: Removes the menu from this Menu_Bar widget.
- `LMenuBar:getMenus`: Returns the menus of this Menu_Bar widget.
- `LMenuBar:getMenuCount`: Returns the menu count of this Menu_Bar widget.

### `LMenuItem` Methods
- `LMenuItem:getText`: Returns the text of this Menu_Item widget.
- `LMenuItem:setText`: Sets the text for this Menu_Item widget.
- `LMenuItem:getShortcut`: Returns the shortcut of this Menu_Item widget.
- `LMenuItem:setShortcut`: Sets the shortcut for this Menu_Item widget.
- `LMenuItem:isChecked`: Returns true if checked is enabled for this Menu_Item widget.
- `LMenuItem:setChecked`: Sets the checked for this Menu_Item widget.
- `LMenuItem:addSubItem`: Adds a sub item entry to this Menu_Item widget.
- `LMenuItem:getSubItems`: Returns the sub items of this Menu_Item widget.
- `LMenuItem:setOnClick`: Registers a callback invoked when this menu item is clicked.

### `LNinePatch` Methods
- `LNinePatch:setInsets`: Sets the insets for this Nine_Patch widget.
- `LNinePatch:getInsets`: Returns the insets of this Nine_Patch widget.
- `LNinePatch:setImageDimensions`: Sets the image dimensions for this Nine_Patch widget.
- `LNinePatch:getImageDimensions`: Returns the image dimensions of this Nine_Patch widget.
- `LNinePatch:getSlices`: Returns the slices of this Nine_Patch widget.

### `LPanel` Methods
- `LPanel:setTitle`: Sets the title for this Panel widget.
- `LPanel:getTitle`: Returns the title of this Panel widget.
- `LPanel:setScrollable`: Sets the scrollable for this Panel widget.

### `LPieChart` Methods
- `LPieChart:addSegment`: Adds a labelled pie segment.
- `LPieChart:drawToImage`: Renders the pie chart into an existing ImageData.
- `LPieChart:type`: Returns the type name of this object.
- `LPieChart:typeOf`: Returns true if this object is of the given type.

### `LProgressBar` Methods
- `LProgressBar:setValue`: Sets the value for this Progress_Bar widget.
- `LProgressBar:getValue`: Returns the value of this Progress_Bar widget.
- `LProgressBar:getProgress`: Returns the progress of this Progress_Bar widget.
- `LProgressBar:setRange`: Sets the range for this Progress_Bar widget.
- `LProgressBar:getMin`: Returns the min of this Progress_Bar widget.
- `LProgressBar:getMax`: Returns the max of this Progress_Bar widget.

### `LRadioButton` Methods
- `LRadioButton:getText`: Returns the text of this Radio_Button widget.
- `LRadioButton:setText`: Sets the text for this Radio_Button widget.
- `LRadioButton:isSelected`: Returns true if selected is enabled for this Radio_Button widget.
- `LRadioButton:setSelected`: Sets the selected for this Radio_Button widget.
- `LRadioButton:getGroup`: Returns the group of this Radio_Button widget.
- `LRadioButton:setGroup`: Sets the group for this Radio_Button widget.
- `LRadioButton:setOnChange`: Registers a callback invoked when this widget's value changes.

### `LScatterPlot` Methods
- `LScatterPlot:addSeries`: Adds a named data series.
- `LScatterPlot:setXRange`: Sets the X-axis data range.
- `LScatterPlot:setYRange`: Sets the Y-axis data range.
- `LScatterPlot:drawToImage`: Renders the scatter plot into an existing ImageData.
- `LScatterPlot:type`: Returns the type name of this object.
- `LScatterPlot:typeOf`: Returns true if this object is of the given type.

### `LScrollBar` Methods
- `LScrollBar:getScrollPosition`: Returns the scroll position of this Scroll_Bar widget.
- `LScrollBar:setScrollPosition`: Sets the scroll position for this Scroll_Bar widget.
- `LScrollBar:getContentSize`: Returns the content size of this Scroll_Bar widget.
- `LScrollBar:setContentSize`: Sets the content size for this Scroll_Bar widget.
- `LScrollBar:getViewSize`: Returns the view size of this Scroll_Bar widget.
- `LScrollBar:setViewSize`: Sets the view size for this Scroll_Bar widget.
- `LScrollBar:isVertical`: Returns true if vertical is enabled for this Scroll_Bar widget.
- `LScrollBar:setOnChange`: Registers a callback invoked when this widget's value changes.

### `LScrollPanel` Methods
- `LScrollPanel:setContentSize`: Sets the content size for this Scroll_Panel widget.
- `LScrollPanel:getContentSize`: Returns the content size of this Scroll_Panel widget.
- `LScrollPanel:setScrollPosition`: Sets the scroll position for this Scroll_Panel widget.
- `LScrollPanel:getScrollPosition`: Returns the scroll position of this Scroll_Panel widget.
- `LScrollPanel:getMaxScroll`: Returns the max scroll of this Scroll_Panel widget.
- `LScrollPanel:setScrollSpeed`: Sets the scroll speed for this Scroll_Panel widget.
- `LScrollPanel:getScrollSpeed`: Returns the scroll speed of this Scroll_Panel widget.

### `LSeparator` Methods
- `LSeparator:setVertical`: Sets the vertical for this Separator widget.
- `LSeparator:isVertical`: Returns true if vertical is enabled for this Separator widget.
- `LSeparator:setThickness`: Sets the thickness for this Separator widget.
- `LSeparator:getThickness`: Returns the thickness of this Separator widget.

### `LSlider` Methods
- `LSlider:setValue`: Sets the value for this Slider widget.
- `LSlider:getValue`: Returns the value of this Slider widget.
- `LSlider:setRange`: Sets the range for this Slider widget.
- `LSlider:setStep`: Sets the step for this Slider widget.
- `LSlider:getMin`: Returns the min of this Slider widget.
- `LSlider:getMax`: Returns the max of this Slider widget.

### `LSpinBox` Methods
- `LSpinBox:setValue`: Sets the value for this SpinBox widget.
- `LSpinBox:getValue`: Returns the current value of this SpinBox widget.
- `LSpinBox:increment`: Increments the value by one step.
- `LSpinBox:decrement`: Decrements the value by one step.
- `LSpinBox:setRange`: Sets the valid range for this SpinBox widget.
- `LSpinBox:setStep`: Sets the increment step for this SpinBox widget.

### `LSplitPanel` Methods
- `LSplitPanel:getOrientation`: Returns the orientation of this Split_Panel widget.
- `LSplitPanel:setOrientation`: Sets the orientation for this Split_Panel widget.
- `LSplitPanel:getSplitPosition`: Returns the split position of this Split_Panel widget.
- `LSplitPanel:setSplitPosition`: Sets the split position for this Split_Panel widget.
- `LSplitPanel:getMinPanelSize`: Returns the min panel size of this Split_Panel widget.
- `LSplitPanel:setMinPanelSize`: Sets the min panel size for this Split_Panel widget.
- `LSplitPanel:setFirstChild`: Sets the first child for this Split_Panel widget.
- `LSplitPanel:setSecondChild`: Sets the second child for this Split_Panel widget.
- `LSplitPanel:getFirstChild`: Returns the first child of this Split_Panel widget.
- `LSplitPanel:getSecondChild`: Returns the second child of this Split_Panel widget.

### `LStatusBar` Methods
- `LStatusBar:addSection`: Adds a section entry to this Status_Bar widget.
- `LStatusBar:setSectionText`: Sets the section text for this Status_Bar widget.
- `LStatusBar:getSectionText`: Returns the section text of this Status_Bar widget.
- `LStatusBar:getSectionCount`: Returns the section count of this Status_Bar widget.
- `LStatusBar:setSectionCount`: Resizes the section list for this Status_Bar widget.
- `LStatusBar:setSectionWidget`: Compatibility shim for assigning a widget to a section.

### `LSwitch` Methods
- `LSwitch:setOn`: Sets the on/off state of this Switch widget.
- `LSwitch:isOn`: Returns the on/off state of this Switch widget.
- `LSwitch:toggle`: Toggles the on/off state of this Switch widget.

### `LTabBar` Methods
- `LTabBar:addTab`: Adds a tab entry to this Tab_Bar widget.
- `LTabBar:removeTab`: Removes the tab from this Tab_Bar widget.
- `LTabBar:getTab`: Returns the tab of this Tab_Bar widget.
- `LTabBar:getTabCount`: Returns the tab count of this Tab_Bar widget.
- `LTabBar:setActiveTab`: Sets the active tab for this Tab_Bar widget.
- `LTabBar:getActiveTab`: Returns the active tab of this Tab_Bar widget.

### `LTextInput` Methods
- `LTextInput:setText`: Sets the text for this Text_Input widget.
- `LTextInput:getText`: Returns the text of this Text_Input widget.
- `LTextInput:setPlaceholder`: Sets the placeholder for this Text_Input widget.
- `LTextInput:getPlaceholder`: Returns the placeholder of this Text_Input widget.
- `LTextInput:setMaxLength`: Sets the max length for this Text_Input widget.
- `LTextInput:isFocused`: Returns true if focused is enabled for this Text_Input widget.
- `LTextInput:getCursorPosition`: Returns the cursor position of this Text_Input widget.

### `LTheme` Methods
- `LTheme:setStyle`: Sets a style for a (widget_type, state) pair.
- `LTheme:type`: Returns the type name of this object.
- `LTheme:typeOf`: Returns true if this object is of the given type.

### `LToast` Methods
- `LToast:setMessage`: Sets the message for this Toast widget.
- `LToast:getMessage`: Returns the message of this Toast widget.
- `LToast:setDuration`: Sets the duration for this Toast widget.
- `LToast:getDuration`: Returns the duration of this Toast widget.
- `LToast:getProgress`: Returns the progress of this Toast widget.
- `LToast:isExpired`: Returns true if expired is enabled for this Toast widget.

### `LToolbar` Methods
- `LToolbar:getOrientation`: Returns the orientation of this Toolbar widget.
- `LToolbar:setOrientation`: Sets the orientation for this Toolbar widget.
- `LToolbar:addButton`: Adds a button entry to this Toolbar widget.
- `LToolbar:addSeparator`: Adds a separator entry to this Toolbar widget.
- `LToolbar:addSpacer`: Adds a spacer entry to this Toolbar widget.
- `LToolbar:getButton`: Returns the button of this Toolbar widget.
- `LToolbar:setButtonEnabled`: Sets the button enabled for this Toolbar widget.
- `LToolbar:setButtonToggled`: Sets the button toggled for this Toolbar widget.
- `LToolbar:isButtonToggled`: Returns true if button toggled is enabled for this Toolbar widget.

### `LTooltipPanel` Methods
- `LTooltipPanel:getText`: Returns the text of this Tooltip_Panel widget.
- `LTooltipPanel:setText`: Sets the text for this Tooltip_Panel widget.
- `LTooltipPanel:getDelay`: Returns the delay of this Tooltip_Panel widget.
- `LTooltipPanel:setDelay`: Sets the delay for this Tooltip_Panel widget.
- `LTooltipPanel:getTarget`: Returns the target of this Tooltip_Panel widget.
- `LTooltipPanel:setTarget`: Sets the target for this Tooltip_Panel widget.

### `LTreeView` Methods
- `LTreeView:addNode`: Adds a node entry to this Tree_View widget.
- `LTreeView:toggleNode`: Toggles the expanded/collapsed status of a Tree_View node.
- `LTreeView:isExpanded`: Returns true if expanded is enabled for this Tree_View widget.
- `LTreeView:getNodeCount`: Returns the node count of this Tree_View widget.
- `LTreeView:removeNode`: Removes the node from this Tree_View widget.
- `LTreeView:clearNodes`: Clears all nodes entries from this Tree_View widget.
- `LTreeView:getNodeText`: Returns the node text of this Tree_View widget.
- `LTreeView:setNodeText`: Sets the node text for this Tree_View widget.
- `LTreeView:setNodeIcon`: Sets the node icon for this Tree_View widget.
- `LTreeView:expandNode`: Performs the expand node operation on this Tree_View widget.
- `LTreeView:collapseNode`: Performs the collapse node operation on this Tree_View widget.
- `LTreeView:isNodeExpanded`: Returns true if node expanded is enabled for this Tree_View widget.
- `LTreeView:expandAll`: Performs the expand all operation on this Tree_View widget.
- `LTreeView:collapseAll`: Performs the collapse all operation on this Tree_View widget.
- `LTreeView:setSelectedNode`: Sets the selected node for this Tree_View widget.
- `LTreeView:getSelectedNode`: Returns the selected node of this Tree_View widget.
- `LTreeView:getChildNodes`: Returns the child nodes of this Tree_View widget.
- `LTreeView:getParentNode`: Returns the parent node of this Tree_View widget.
- `LTreeView:getNodeDepth`: Returns the node depth of this Tree_View widget.

### `LUiWidget` Methods
- `LUiWidget:type`: Returns the Lua type name of this widget (e.g. "LButton").
- `LUiWidget:typeOf`: Returns true if this widget is of the given type, "LWidget", or "Object".
- `LUiWidget:setPosition`: Sets the widget position.
- `LUiWidget:getPosition`: Returns the widget position.
- `LUiWidget:setSize`: Sets the width and height of the widget in UI pixels.
- `LUiWidget:getSize`: Returns the current width and height of the widget in UI pixels.
- `LUiWidget:getRect`: Returns the computed screen-space rectangle after layout.
- `LUiWidget:setVisible`: Shows or hides the widget; hidden widgets are not rendered or interactive.
- `LUiWidget:isVisible`: Returns whether the widget is visible.
- `LUiWidget:setEnabled`: Sets whether the widget is enabled.
- `LUiWidget:isEnabled`: Returns whether the widget is enabled.
- `LUiWidget:setId`: Sets the widget string identifier.
- `LUiWidget:getId`: Returns the widget string identifier.
- `LUiWidget:setTooltip`: Sets the widget tooltip text.
- `LUiWidget:getTooltip`: Returns the widget tooltip text.
- `LUiWidget:getState`: Returns the widget interaction state name.
- `LUiWidget:addChild`: Adds a child widget to this container.
- `LUiWidget:removeChild`: Removes a child widget from this container.
- `LUiWidget:getChildCount`: Returns the number of children in this container.
- `LUiWidget:getChildren`: Returns this container's children as widget-handle tables.
- `LUiWidget:findById`: Recursively searches for a widget by id starting from this widget.
- `LUiWidget:setOnClick`: Registers a callback invoked when this widget is clicked.
- `LUiWidget:setOnChange`: Registers a callback invoked when this widget's value changes.
- `LUiWidget:setOnDraw`: Stores a custom draw callback for later invocation.
- `LUiWidget:containsPoint`: Returns whether (x, y) is inside this widget.
- `LUiWidget:setPadding`: Sets widget padding (CSS-like: top, right?, bottom?, left?).
- `LUiWidget:getPadding`: Returns the widget padding (top, right, bottom, left).
- `LUiWidget:setMargin`: Sets widget margin (CSS-like: top, right?, bottom?, left?).
- `LUiWidget:getMargin`: Returns the widget margin (top, right, bottom, left).
- `LUiWidget:setZOrder`: Sets the widget z-order for draw sorting.
- `LUiWidget:getZOrder`: Returns the widget z-order.
- `LUiWidget:setMinSize`: Sets the minimum widget size.
- `LUiWidget:getMinSize`: Returns the minimum widget size.
- `LUiWidget:setMaxSize`: Sets the maximum widget size.
- `LUiWidget:getMaxSize`: Returns the maximum widget size.
- `LUiWidget:setAnchor`: Sets anchor edges (left, top, right, bottom).
- `LUiWidget:setAnchorCenter`: Sets center anchor offsets.
- `LUiWidget:clearAnchor`: Removes all anchor constraints.
- `LUiWidget:setFlexGrow`: Sets the flex-grow factor.
- `LUiWidget:getFlexGrow`: Returns the flex-grow factor.
- `LUiWidget:setFlexShrink`: Sets the flex-shrink factor.
- `LUiWidget:getFlexShrink`: Returns the flex-shrink factor.
- `LUiWidget:bind`: Registers a data-binding key on this widget.
- `LUiWidget:unbind`: Removes the data-binding key from this widget.
- `LUiWidget:setAlpha`: Sets the widget's alpha transparency (`0.0` fully transparent, `1.0` opaque).
- `LUiWidget:getAlpha`: Returns the widget's current alpha transparency.
- `LUiWidget:fadeIn`: Instantly fades the widget in (sets alpha to `1.0`).
- `LUiWidget:fadeOut`: Instantly fades the widget out (sets alpha to `0.0` and hides it).
- `LUiWidget:slideIn`: Instantly moves the widget to `(x, y)` and makes it visible.
- `LUiWidget:slideOut`: Instantly moves the widget to the off-screen position `(x, y)` and hides it.
- `LUiWidget:attachToEntity`: Anchors this widget to a world-space entity by its numeric ID.
- `LUiWidget:detachFromEntity`: Removes the entity anchor from this widget, restoring normal layout positioning.

## References

- `image`: Imports or references `image` from `src/image/`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/ui/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
