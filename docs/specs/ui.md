# `ui` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | `lurek.ui` |
| **Source** | `src/ui/` |
| **Rust Tests** | `tests/rust/unit/gui_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_gui.lua`, `tests/lua/integration/test_localization_ui.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The `ui` module provides Lurek2D's retained-mode widget system for in-game menus, HUD panels, tool windows, dialogs, forms, data displays, and other 2D interface work. It stores widgets as CPU-side data, applies theme styling, manages focus and widget relationships, and produces render commands for the actual draw layer.

It exists so interface logic, widget composition, and layout behavior stay decoupled from game scripts and from the renderer. Scripts can assemble and drive UI state through the Lua bridge, while the Rust module owns the widget model, type-erased context, theme lookup, and shared behavior.

It intentionally does not own native OS widgets, window management, or raw input capture from the platform layer. It also does not rasterize fonts itself beyond delegating draw output; input events are routed into it by higher layers.

**Scope boundary**: This module currently depends on `image`, `math`, `render`, `runtime`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.ui.* (Lua API — src/lua_api/ui_api.rs)
    |
    v
src/ui/mod.rs
    |- chart.rs - chart
    |- containers.rs - containers
    |- context.rs - context
    |- controls.rs - controls
    |- data_graph_renderer.rs - data_graph_renderer
    |- extras.rs - extras
    |- render.rs - render
    |- theme.rs - theme
    |- ...
```

---

## Source Files

| File | Purpose |
|------|---------|
| `chart.rs` | Generates CPU-rendered chart images for line, bar, scatter, pie, and area graphs without requiring the GPU path. |
| `containers.rs` | Defines structural widgets such as panels, layouts, split views, scroll panels, windows, dock panels, and nine-patch containers. |
| `context.rs` | Implements `GuiContext`, the retained widget pool, focus management, event routing, child relationships, and toast tracking. |
| `controls.rs` | Defines common interactive widgets such as buttons, labels, text inputs, sliders, check boxes, combo boxes, list boxes, and progress bars. |
| `data_graph_renderer.rs` | Implements data-series rendering helpers for charts and graph-style visualizations. |
| `extras.rs` | Defines secondary widgets and utility components such as menus, toolbars, dialogs, tables, tree views, tooltips, accordions, image widgets, and toasts. |
| `mod.rs` | Declares the UI submodules and re-exports the widget, context, theme, container, control, and chart-facing types. |
| `render.rs` | Walks UI state and theme data to produce render commands or CPU-side image output. |
| `theme.rs` | Stores theme style maps, widget visual state, and fallback behavior for widget styling. |
| `widget.rs` | Defines shared widget metadata and the broad widget-type and widget-state enums used across the module. |

---

## Submodules

### `ui::chart`

Generates CPU-rendered chart images for line, bar, scatter, pie, and area graphs without requiring the GPU path.

- **`ChartConfig`** (struct): Common configuration shared by all chart types.
- **`ChartMargin`** (struct): Pixel margins around the chart plot area.
- **`ChartSeries`** (struct): A named data series with colour.
- **`LineChart`** (struct): A configurable line chart renderer.
- **`BarCategory`** (struct): A single category group in a bar chart.
- **`BarChart`** (struct): A configurable grouped bar chart renderer.
- **`ScatterPlot`** (struct): A configurable scatter plot renderer.
- **`PieSegment`** (struct): A segment in a pie chart.
- **`PieChart`** (struct): A configurable pie chart renderer.
- **`AreaChart`** (struct): A configurable stacked area chart renderer.

### `ui::containers`

Defines structural widgets such as panels, layouts, split views, scroll panels, windows, dock panels, and nine-patch containers.

- **`Panel`** (struct): Generic container widget that holds an ordered list of children.
- **`LayoutDirection`** (enum): Direction in which a [`Layout`] positions its children.
- **`Layout`** (struct): Flexbox-inspired layout container.
- **`ScrollPanel`** (struct): Scrollable viewport container.
- **`NineSlice`** (type): A nine-slice rectangle: `(sx, sy, sw, sh, dx, dy, dw, dh)`.
- **`NinePatch`** (struct): Nine-slice data for scalable panel border rendering.
- **`GUIWindow`** (struct): A draggable, closeable window container.
- **`SplitPanel`** (struct): A resizable split panel with two child regions.
- **`DockPanel`** (struct): A dock-based layout container with left/right/top/bottom/center regions.

### `ui::context`

Implements `GuiContext`, the retained widget pool, focus management, event routing, child relationships, and toast tracking.

- **`GuiEvent`** (enum): A single interaction event emitted by the GUI widget tree.
- **`WidgetKind`** (enum): Type-erased widget storage.
- **`GuiContext`** (struct): Central GUI coordinator: widget pool, focus, toasts, and theme.

### `ui::controls`

Defines common interactive widgets such as buttons, labels, text inputs, sliders, check boxes, combo boxes, list boxes, and progress bars.

- **`Button`** (struct): Clickable button widget.
- **`Label`** (struct): Static text label widget.
- **`TextInput`** (struct): Editable single-line text input field.
- **`CheckBox`** (struct): Toggle check-box widget with an associated label.
- **`Slider`** (struct): Numeric value slider widget.
- **`ProgressBar`** (struct): Read-only progress indicator widget.
- **`ComboBox`** (struct): Drop-down selection widget.
- **`ListBox`** (struct): Scrollable list of selectable items.
- **`TabBar`** (struct): Tabbed page selector widget.
- **`RadioButton`** (struct): A grouped radio button with mutually exclusive selection.

### `ui::data_graph_renderer`

Implements data-series rendering helpers for charts and graph-style visualizations.

- **`GraphSeries`** (enum): A data series that can be added to a [`GraphRenderer`].
- **`GraphRenderer`** (struct): Mathematical function graph / chart renderer.

### `ui::extras`

Defines secondary widgets and utility components such as menus, toolbars, dialogs, tables, tree views, tooltips, accordions, image widgets, and toasts.

- **`Toast`** (struct): Auto-expiring notification overlay.
- **`Separator`** (struct): Visual divider line widget.
- **`Spacer`** (struct): Empty layout filler widget.
- **`TreeNode`** (struct): A single node in a [`TreeView`] hierarchy.
- **`TreeView`** (struct): Collapsible hierarchical tree widget.
- **`ToolbarButton`** (struct): A named action button entry in a [`Toolbar`].
- **`Toolbar`** (struct): A toolbar container for buttons and separators.
- **`MenuBar`** (struct): A horizontal menu bar.
- **`MenuItem`** (struct): A menu item usable in menus and context menus.
- **`Dialog`** (struct): A modal dialog window.

### `ui::render`

Walks UI state and theme data to produce render commands or CPU-side image output.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `ui::theme`

Stores theme style maps, widget visual state, and fallback behavior for widget styling.

- **`WidgetStyle`** (struct): Visual style record applied to a specific widget type in a specific state.
- **`Theme`** (struct): Theme registry that maps `(WidgetType, WidgetState)` pairs to [`WidgetStyle`].

### `ui::widget`

Defines shared widget metadata and the broad widget-type and widget-state enums used across the module.

- **`WidgetState`** (enum): Visual interaction state of a widget.
- **`WidgetType`** (enum): Type tag identifying a concrete widget kind.
- **`WidgetBase`** (struct): Shared base properties embedded by every concrete widget.

---

## Key Types

### Public Types

#### `GuiContext`

The central retained-mode UI state container.

#### `WidgetKind`

A type-erased enum over all concrete widget variants stored in the `GuiContext` pool.

#### `WidgetBase`

Shared geometry, visibility, spacing, anchoring, and flex-like metadata embedded in every widget.

#### `WidgetType`

Identifies the broad widget class for styling and state-dependent behavior.

#### `WidgetState`

Encodes common UI states such as normal, hovered, pressed, focused, and disabled.

#### `Theme`

Stores widget styles keyed by widget type and state so the same UI tree can be skinned consistently.

#### `WidgetStyle`

A concrete set of colors, borders, radius, and font-size values used by theme lookup.

#### `Layout`

Flexible container widget for vertical, horizontal, and grid-style composition.

#### `Panel`

Basic visual container for grouping child widgets.

#### `ScrollPanel`

Container with scrolling behavior for content larger than its visible region.

#### `GUIWindow`

Higher-level window container for movable or framed interface sections.

#### `Button`

Clickable action widget.

#### `Label`

Static text widget.

#### `TextInput`

Editable single-line text field with cursor state.

#### `Slider`

Numeric drag control.

#### `ComboBox`

Drop-down selection control.

#### `ListBox`

Multi-item selection list.

#### `Toast`

Timed transient notification.

#### `GraphRenderer`

Data visualization helper for graph and series rendering.

#### `ChartConfig`

Configuration for chart image generation.

#### `LayoutDirection`

Principal type for the `ui` module.

#### `NinePatch`

Principal type for the `ui` module.

#### `SplitPanel`

Principal type for the `ui` module.

#### `DockPanel`

Principal type for the `ui` module.

#### `GuiEvent`

Principal type for the `ui` module.

---

## Lua API

Exposed under `lurek.ui.*` by `src/lua_api/ui_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.ui.setPosition` | Sets the widget position. |
| `lurek.ui.getPosition` | Returns the widget position. |
| `lurek.ui.setSize` | Sets the widget size. |
| `lurek.ui.getSize` | Returns the widget size. |
| `lurek.ui.getRect` | Returns the computed screen-space rectangle after layout. |
| `lurek.ui.setVisible` | Sets widget visibility. |
| `lurek.ui.isVisible` | Returns whether the widget is visible. |
| `lurek.ui.setEnabled` | Sets whether the widget is enabled. |
| `lurek.ui.isEnabled` | Returns whether the widget is enabled. |
| `lurek.ui.setId` | Sets the widget string identifier. |
| `lurek.ui.getId` | Returns the widget string identifier. |
| `lurek.ui.setTooltip` | Sets the widget tooltip text. |
| `lurek.ui.getTooltip` | Returns the widget tooltip text. |
| `lurek.ui.getState` | Returns the widget interaction state name. |
| `lurek.ui.addChild` | Adds a child widget to this container. |
| `lurek.ui.removeChild` | Removes a child widget from this container. |
| `lurek.ui.getChildCount` | Returns the number of children in this container. |
| `lurek.ui.findById` | Recursively searches for a widget by id starting from this widget. |
| `lurek.ui.setOnClick` | Registers a callback invoked when this widget is clicked. |
| `lurek.ui.setOnChange` | Registers a callback invoked when this widget's value changes. |
| `lurek.ui.setOnDraw` | Stores a custom draw callback for later invocation. |
| `lurek.ui.containsPoint` | Returns whether (x, y) is inside this widget. |
| `lurek.ui.setPadding` | Sets widget padding (CSS-like: top, right?, bottom?, left?). |
| `lurek.ui.getPadding` | Returns the widget padding (top, right, bottom, left). |
| `lurek.ui.setMargin` | Sets widget margin (CSS-like: top, right?, bottom?, left?). |
| `lurek.ui.getMargin` | Returns the widget margin (top, right, bottom, left). |
| `lurek.ui.setZOrder` | Sets the widget z-order for draw sorting. |
| `lurek.ui.getZOrder` | Returns the widget z-order. |
| `lurek.ui.setMinSize` | Sets the minimum widget size. |
| `lurek.ui.getMinSize` | Returns the minimum widget size. |
| `lurek.ui.setMaxSize` | Sets the maximum widget size. |
| `lurek.ui.getMaxSize` | Returns the maximum widget size. |
| `lurek.ui.setAnchor` | Sets anchor edges (left, top, right, bottom). |
| `lurek.ui.setAnchorCenter` | Sets center anchor offsets. |
| `lurek.ui.clearAnchor` | Removes all anchor constraints. |
| `lurek.ui.setFlexGrow` | Sets the flex-grow factor. |
| `lurek.ui.getFlexGrow` | Returns the flex-grow factor. |
| `lurek.ui.setFlexShrink` | Sets the flex-shrink factor. |
| `lurek.ui.getFlexShrink` | Returns the flex-shrink factor. |

### `Accordion` Methods

| Method | Description |
|--------|-------------|
| `accordion:addSection(...)` | Adds a section entry to this Accordion widget. |
| `accordion:getSectionCount(...)` | Returns the section count of this Accordion widget. |
| `accordion:toggleSection(...)` | Toggles the expanded/collapsed status of an Accordion section. |
| `accordion:isSectionExpanded(...)` | Returns true if section expanded is enabled for this Accordion widget. |
| `accordion:isExclusive(...)` | Returns true if exclusive is enabled for this Accordion widget. |
| `accordion:setExclusive(...)` | Sets the exclusive for this Accordion widget. |
| `accordion:getSectionTitle(...)` | Returns the section title of this Accordion widget. |

### `Button` Methods

| Method | Description |
|--------|-------------|
| `button:setText(...)` | Sets the text for this Button widget. |
| `button:getText(...)` | Returns the text of this Button widget. |

### `Checkbox` Methods

| Method | Description |
|--------|-------------|
| `checkbox:setChecked(...)` | Sets the checked for this Checkbox widget. |
| `checkbox:isChecked(...)` | Returns true if checked is enabled for this Checkbox widget. |
| `checkbox:setText(...)` | Sets the text for this Checkbox widget. |
| `checkbox:getText(...)` | Returns the text of this Checkbox widget. |

### `Color_Picker` Methods

| Method | Description |
|--------|-------------|
| `color_picker:getColor(...)` | Returns the color of this Color_Picker widget. |
| `color_picker:setColor(...)` | Sets the color for this Color_Picker widget. |
| `color_picker:getShowAlpha(...)` | Returns the show alpha of this Color_Picker widget. |
| `color_picker:setShowAlpha(...)` | Sets the show alpha for this Color_Picker widget. |
| `color_picker:getColorMode(...)` | Returns the color mode of this Color_Picker widget. |
| `color_picker:setColorMode(...)` | Sets the color mode for this Color_Picker widget. |
| `color_picker:setOnChange(...)` | Registers a callback invoked when this widget's value changes. |

### `Combo_Box` Methods

| Method | Description |
|--------|-------------|
| `combo_box:addItem(...)` | Adds a item entry to this Combo_Box widget. |
| `combo_box:removeItem(...)` | Removes the item from this Combo_Box widget. |
| `combo_box:clearItems(...)` | Clears all items entries from this Combo_Box widget. |
| `combo_box:getItemCount(...)` | Returns the item count of this Combo_Box widget. |
| `combo_box:getItem(...)` | Returns the item of this Combo_Box widget. |
| `combo_box:setSelectedIndex(...)` | Sets the selected index for this Combo_Box widget. |
| `combo_box:getSelectedIndex(...)` | Returns the selected index of this Combo_Box widget. |
| `combo_box:getSelectedItem(...)` | Returns the selected item of this Combo_Box widget. |

### `Dialog` Methods

| Method | Description |
|--------|-------------|
| `dialog:getTitle(...)` | Returns the title of this Dialog widget. |
| `dialog:setTitle(...)` | Sets the title for this Dialog widget. |
| `dialog:isModal(...)` | Returns true if modal is enabled for this Dialog widget. |
| `dialog:setModal(...)` | Sets the modal for this Dialog widget. |
| `dialog:isOpen(...)` | Returns true if open is enabled for this Dialog widget. |
| `dialog:open(...)` | Performs the open operation on this Dialog widget. |
| `dialog:close(...)` | Closes and removes this dialog from the screen. |
| `dialog:setOnClose(...)` | Registers a callback invoked when this dialog is closed. |
| `dialog:setContent(...)` | Sets the content for this Dialog widget. |
| `dialog:getContent(...)` | Returns the content of this Dialog widget. |
| `dialog:addButton(...)` | Adds a button entry to this Dialog widget. |

### `Dock_Panel` Methods

| Method | Description |
|--------|-------------|
| `dock_panel:dock(...)` | Performs the dock operation on this Dock_Panel widget. |
| `dock_panel:undock(...)` | Performs the undock operation on this Dock_Panel widget. |
| `dock_panel:getDockedCount(...)` | Returns the docked count of this Dock_Panel widget. |
| `dock_panel:setSplitSize(...)` | Sets the split size for this Dock_Panel widget. |
| `dock_panel:getSplitSize(...)` | Returns the split size of this Dock_Panel widget. |

### `Gui_Table` Methods

| Method | Description |
|--------|-------------|
| `gui_table:addColumn(...)` | Adds a column entry to this Gui_Table widget. |
| `gui_table:getColumnCount(...)` | Returns the column count of this Gui_Table widget. |
| `gui_table:addRow(...)` | Adds a row entry to this Gui_Table widget. |
| `gui_table:getRowCount(...)` | Returns the row count of this Gui_Table widget. |
| `gui_table:getCell(...)` | Returns the cell of this Gui_Table widget. |
| `gui_table:setCell(...)` | Sets the cell for this Gui_Table widget. |
| `gui_table:getSelectedRow(...)` | Returns the selected row of this Gui_Table widget. |
| `gui_table:setSelectedRow(...)` | Sets the selected row for this Gui_Table widget. |
| `gui_table:isSortable(...)` | Returns true if sortable is enabled for this Gui_Table widget. |
| `gui_table:setSortable(...)` | Sets the sortable for this Gui_Table widget. |
| `gui_table:setOnSelect(...)` | Registers a callback invoked when a table row is selected. |

### `Gui_Window` Methods

| Method | Description |
|--------|-------------|
| `gui_window:getTitle(...)` | Returns the title of this Gui_Window widget. |
| `gui_window:setTitle(...)` | Sets the title for this Gui_Window widget. |
| `gui_window:isCloseable(...)` | Returns true if closeable is enabled for this Gui_Window widget. |
| `gui_window:setCloseable(...)` | Sets the closeable for this Gui_Window widget. |
| `gui_window:isDraggable(...)` | Returns true if draggable is enabled for this Gui_Window widget. |
| `gui_window:setDraggable(...)` | Sets the draggable for this Gui_Window widget. |
| `gui_window:isResizable(...)` | Returns true if resizable is enabled for this Gui_Window widget. |
| `gui_window:setResizable(...)` | Sets the resizable for this Gui_Window widget. |
| `gui_window:setOnClose(...)` | Registers a callback invoked when this window is closed. |

### `Image_Widget` Methods

| Method | Description |
|--------|-------------|
| `image_widget:getScaleMode(...)` | Returns the scale mode of this Image_Widget widget. |
| `image_widget:setScaleMode(...)` | Sets the scale mode for this Image_Widget widget. |
| `image_widget:getTint(...)` | Returns the tint of this Image_Widget widget. |
| `image_widget:setTint(...)` | Sets the tint for this Image_Widget widget. |
| `image_widget:newButton(...)` | Creates a button widget. |
| `image_widget:newLabel(...)` | Creates a text label widget. |
| `image_widget:newTextInput(...)` | Creates a text input widget. |
| `image_widget:newCheckbox(...)` | Creates a checkbox widget. |
| `image_widget:newSlider(...)` | Creates a value slider widget. |
| `image_widget:newProgressBar(...)` | Creates a progress bar widget. |
| `image_widget:newComboBox(...)` | Creates a dropdown combo box widget. |
| `image_widget:newList(...)` | Creates a selectable list widget. |
| `image_widget:newPanel(...)` | Creates a container panel widget. |
| `image_widget:newLayout(...)` | Creates a flexbox layout container. |
| `image_widget:newScrollPanel(...)` | Creates a scrollable panel widget. |
| `image_widget:newNinePatch(...)` | Creates a 9-patch slicer widget. |
| `image_widget:newTabBar(...)` | Creates a tab bar widget. |
| `image_widget:newSeparator(...)` | Creates a separator line. |
| `image_widget:newSpacer(...)` | Creates a spacing filler widget. |
| `image_widget:newToast(...)` | Creates a toast notification widget. |
| `image_widget:newTreeView(...)` | Creates a collapsible tree view widget. |
| `image_widget:newRadioButton(...)` | Creates a grouped radio button widget. |
| `image_widget:newScrollBar(...)` | Creates a scroll bar widget. |
| `image_widget:newWindow(...)` | Creates a draggable window widget. |
| `image_widget:newSplitPanel(...)` | Creates a resizable split panel. |
| `image_widget:newDockPanel(...)` | Creates a dock panel. |
| `image_widget:newToolbar(...)` | Creates a toolbar widget. |
| `image_widget:newMenuBar(...)` | Creates a menu bar widget. |
| `image_widget:newMenuItem(...)` | Creates a menu item widget. |
| `image_widget:newDialog(...)` | Creates a modal dialog widget. |
| `image_widget:newStatusBar(...)` | Creates a status bar widget. |
| `image_widget:newAccordion(...)` | Creates a collapsible accordion widget. |
| `image_widget:newTooltipPanel(...)` | Creates a tooltip panel widget. |
| `image_widget:newColorPicker(...)` | Creates a color picker widget. |
| `image_widget:newTable(...)` | Creates a data table widget. |
| `image_widget:newImageWidget(...)` | Creates an image display widget. |
| `image_widget:newTheme(...)` | Creates a new theme instance. |
| `image_widget:setTheme(...)` | Sets the active GUI theme. |
| `image_widget:getTheme(...)` | Returns whether a theme is set. |
| `image_widget:getRoot(...)` | Returns the root panel widget table. |
| `image_widget:setFocus(...)` | Sets keyboard focus to a widget or clears it. |
| `image_widget:getFocus(...)` | Returns the focused widget index or nil. |
| `image_widget:focusNext(...)` | Moves focus to the next focusable widget. |
| `image_widget:focusPrev(...)` | Moves focus to the previous focusable widget. |
| `image_widget:clearFocus(...)` | Clears keyboard focus. |
| `image_widget:addToast(...)` | Queues a toast notification from a table. |
| `image_widget:getToastCount(...)` | Returns the number of active toasts. |
| `image_widget:mousepressed(...)` | Forwards a mouse press event to the GUI. |
| `image_widget:mousereleased(...)` | Forwards a mouse release event to the GUI. |
| `image_widget:mousemoved(...)` | Forwards a mouse move event to the GUI. |
| `image_widget:keypressed(...)` | Forwards a key press event to the GUI. |
| `image_widget:textinput(...)` | Forwards text input to the focused text input widget. |
| `image_widget:wheelmoved(...)` | Forwards a mouse wheel event to the GUI. |
| `image_widget:update(...)` | Advances toast timers, removes expired toasts, and dispatches pending GUI events. |
| `image_widget:draw(...)` | Headless compatibility stub for GUI draw. |
| `image_widget:getWidgetCount(...)` | Returns the total widget count in the context. |
| `image_widget:drawToImage(...)` | Renders the UI widget tree to a CPU ImageData at the given resolution. |

### `Label` Methods

| Method | Description |
|--------|-------------|
| `label:setText(...)` | Sets the text for this Label widget. |
| `label:getText(...)` | Returns the text of this Label widget. |

### `Layout` Methods

| Method | Description |
|--------|-------------|
| `layout:setDirection(...)` | Sets the direction for this Layout widget. |
| `layout:getDirection(...)` | Returns the direction of this Layout widget. |
| `layout:setSpacing(...)` | Sets the spacing for this Layout widget. |
| `layout:getSpacing(...)` | Returns the spacing of this Layout widget. |
| `layout:setColumns(...)` | Sets the columns for this Layout widget. |
| `layout:setWrap(...)` | Sets the wrap for this Layout widget. |
| `layout:getWrap(...)` | Returns the wrap of this Layout widget. |
| `layout:setAlign(...)` | Sets the align for this Layout widget. |
| `layout:getAlign(...)` | Returns the align of this Layout widget. |
| `layout:setJustify(...)` | Sets the justify for this Layout widget. |
| `layout:getJustify(...)` | Returns the justify of this Layout widget. |

### `List_Box` Methods

| Method | Description |
|--------|-------------|
| `list_box:addItem(...)` | Adds a item entry to this List_Box widget. |
| `list_box:removeItem(...)` | Removes the item from this List_Box widget. |
| `list_box:clearItems(...)` | Clears all items entries from this List_Box widget. |
| `list_box:getItemCount(...)` | Returns the item count of this List_Box widget. |
| `list_box:getItem(...)` | Returns the item of this List_Box widget. |
| `list_box:setSelectedIndex(...)` | Sets the selected index for this List_Box widget. |
| `list_box:getSelectedIndex(...)` | Returns the selected index of this List_Box widget. |
| `list_box:setItemHeight(...)` | Sets the item height for this List_Box widget. |

### `Menu_Bar` Methods

| Method | Description |
|--------|-------------|
| `menu_bar:addMenu(...)` | Adds a menu entry to this Menu_Bar widget. |
| `menu_bar:removeMenu(...)` | Removes the menu from this Menu_Bar widget. |
| `menu_bar:getMenus(...)` | Returns the menus of this Menu_Bar widget. |
| `menu_bar:getMenuCount(...)` | Returns the menu count of this Menu_Bar widget. |

### `Menu_Item` Methods

| Method | Description |
|--------|-------------|
| `menu_item:getText(...)` | Returns the text of this Menu_Item widget. |
| `menu_item:setText(...)` | Sets the text for this Menu_Item widget. |
| `menu_item:getShortcut(...)` | Returns the shortcut of this Menu_Item widget. |
| `menu_item:setShortcut(...)` | Sets the shortcut for this Menu_Item widget. |
| `menu_item:isChecked(...)` | Returns true if checked is enabled for this Menu_Item widget. |
| `menu_item:setChecked(...)` | Sets the checked for this Menu_Item widget. |
| `menu_item:addSubItem(...)` | Adds a sub item entry to this Menu_Item widget. |
| `menu_item:getSubItems(...)` | Returns the sub items of this Menu_Item widget. |
| `menu_item:setOnClick(...)` | Registers a callback invoked when this menu item is clicked. |

### `Nine_Patch` Methods

| Method | Description |
|--------|-------------|
| `nine_patch:setInsets(...)` | Sets the insets for this Nine_Patch widget. |
| `nine_patch:getInsets(...)` | Returns the insets of this Nine_Patch widget. |
| `nine_patch:setImageDimensions(...)` | Sets the image dimensions for this Nine_Patch widget. |
| `nine_patch:getImageDimensions(...)` | Returns the image dimensions of this Nine_Patch widget. |
| `nine_patch:getSlices(...)` | Returns the slices of this Nine_Patch widget. |

### `Panel` Methods

| Method | Description |
|--------|-------------|
| `panel:setTitle(...)` | Sets the title for this Panel widget. |
| `panel:getTitle(...)` | Returns the title of this Panel widget. |
| `panel:setScrollable(...)` | Sets the scrollable for this Panel widget. |

### `Progress_Bar` Methods

| Method | Description |
|--------|-------------|
| `progress_bar:setValue(...)` | Sets the value for this Progress_Bar widget. |
| `progress_bar:getValue(...)` | Returns the value of this Progress_Bar widget. |
| `progress_bar:getProgress(...)` | Returns the progress of this Progress_Bar widget. |
| `progress_bar:setRange(...)` | Sets the range for this Progress_Bar widget. |
| `progress_bar:getMin(...)` | Returns the min of this Progress_Bar widget. |
| `progress_bar:getMax(...)` | Returns the max of this Progress_Bar widget. |

### `Radio_Button` Methods

| Method | Description |
|--------|-------------|
| `radio_button:getText(...)` | Returns the text of this Radio_Button widget. |
| `radio_button:setText(...)` | Sets the text for this Radio_Button widget. |
| `radio_button:isSelected(...)` | Returns true if selected is enabled for this Radio_Button widget. |
| `radio_button:setSelected(...)` | Sets the selected for this Radio_Button widget. |
| `radio_button:getGroup(...)` | Returns the group of this Radio_Button widget. |
| `radio_button:setGroup(...)` | Sets the group for this Radio_Button widget. |
| `radio_button:setOnChange(...)` | Registers a callback invoked when this widget's value changes. |

### `Scroll_Bar` Methods

| Method | Description |
|--------|-------------|
| `scroll_bar:getScrollPosition(...)` | Returns the scroll position of this Scroll_Bar widget. |
| `scroll_bar:setScrollPosition(...)` | Sets the scroll position for this Scroll_Bar widget. |
| `scroll_bar:getContentSize(...)` | Returns the content size of this Scroll_Bar widget. |
| `scroll_bar:setContentSize(...)` | Sets the content size for this Scroll_Bar widget. |
| `scroll_bar:getViewSize(...)` | Returns the view size of this Scroll_Bar widget. |
| `scroll_bar:setViewSize(...)` | Sets the view size for this Scroll_Bar widget. |
| `scroll_bar:isVertical(...)` | Returns true if vertical is enabled for this Scroll_Bar widget. |
| `scroll_bar:setOnChange(...)` | Registers a callback invoked when this widget's value changes. |

### `Scroll_Panel` Methods

| Method | Description |
|--------|-------------|
| `scroll_panel:setContentSize(...)` | Sets the content size for this Scroll_Panel widget. |
| `scroll_panel:getContentSize(...)` | Returns the content size of this Scroll_Panel widget. |
| `scroll_panel:setScrollPosition(...)` | Sets the scroll position for this Scroll_Panel widget. |
| `scroll_panel:getScrollPosition(...)` | Returns the scroll position of this Scroll_Panel widget. |
| `scroll_panel:getMaxScroll(...)` | Returns the max scroll of this Scroll_Panel widget. |
| `scroll_panel:setScrollSpeed(...)` | Sets the scroll speed for this Scroll_Panel widget. |
| `scroll_panel:getScrollSpeed(...)` | Returns the scroll speed of this Scroll_Panel widget. |

### `Separator` Methods

| Method | Description |
|--------|-------------|
| `separator:setVertical(...)` | Sets the vertical for this Separator widget. |
| `separator:isVertical(...)` | Returns true if vertical is enabled for this Separator widget. |
| `separator:setThickness(...)` | Sets the thickness for this Separator widget. |
| `separator:getThickness(...)` | Returns the thickness of this Separator widget. |

### `Slider` Methods

| Method | Description |
|--------|-------------|
| `slider:setValue(...)` | Sets the value for this Slider widget. |
| `slider:getValue(...)` | Returns the value of this Slider widget. |
| `slider:setRange(...)` | Sets the range for this Slider widget. |
| `slider:setStep(...)` | Sets the step for this Slider widget. |
| `slider:getMin(...)` | Returns the min of this Slider widget. |
| `slider:getMax(...)` | Returns the max of this Slider widget. |

### `Split_Panel` Methods

| Method | Description |
|--------|-------------|
| `split_panel:getOrientation(...)` | Returns the orientation of this Split_Panel widget. |
| `split_panel:setOrientation(...)` | Sets the orientation for this Split_Panel widget. |
| `split_panel:getSplitPosition(...)` | Returns the split position of this Split_Panel widget. |
| `split_panel:setSplitPosition(...)` | Sets the split position for this Split_Panel widget. |
| `split_panel:getMinPanelSize(...)` | Returns the min panel size of this Split_Panel widget. |
| `split_panel:setMinPanelSize(...)` | Sets the min panel size for this Split_Panel widget. |
| `split_panel:setFirstChild(...)` | Sets the first child for this Split_Panel widget. |
| `split_panel:setSecondChild(...)` | Sets the second child for this Split_Panel widget. |
| `split_panel:getFirstChild(...)` | Returns the first child of this Split_Panel widget. |
| `split_panel:getSecondChild(...)` | Returns the second child of this Split_Panel widget. |

### `Status_Bar` Methods

| Method | Description |
|--------|-------------|
| `status_bar:addSection(...)` | Adds a section entry to this Status_Bar widget. |
| `status_bar:setSectionText(...)` | Sets the section text for this Status_Bar widget. |
| `status_bar:getSectionText(...)` | Returns the section text of this Status_Bar widget. |
| `status_bar:getSectionCount(...)` | Returns the section count of this Status_Bar widget. |
| `status_bar:setSectionCount(...)` | Resizes the section list for this Status_Bar widget. |
| `status_bar:setSectionWidget(...)` | Compatibility shim for assigning a widget to a section. |

### `Tab_Bar` Methods

| Method | Description |
|--------|-------------|
| `tab_bar:addTab(...)` | Adds a tab entry to this Tab_Bar widget. |
| `tab_bar:removeTab(...)` | Removes the tab from this Tab_Bar widget. |
| `tab_bar:getTab(...)` | Returns the tab of this Tab_Bar widget. |
| `tab_bar:getTabCount(...)` | Returns the tab count of this Tab_Bar widget. |
| `tab_bar:setActiveTab(...)` | Sets the active tab for this Tab_Bar widget. |
| `tab_bar:getActiveTab(...)` | Returns the active tab of this Tab_Bar widget. |

### `Text_Input` Methods

| Method | Description |
|--------|-------------|
| `text_input:setText(...)` | Sets the text for this Text_Input widget. |
| `text_input:getText(...)` | Returns the text of this Text_Input widget. |
| `text_input:setPlaceholder(...)` | Sets the placeholder for this Text_Input widget. |
| `text_input:getPlaceholder(...)` | Returns the placeholder of this Text_Input widget. |
| `text_input:setMaxLength(...)` | Sets the max length for this Text_Input widget. |
| `text_input:isFocused(...)` | Returns true if focused is enabled for this Text_Input widget. |
| `text_input:getCursorPosition(...)` | Returns the cursor position of this Text_Input widget. |

### `Toast` Methods

| Method | Description |
|--------|-------------|
| `toast:setMessage(...)` | Sets the message for this Toast widget. |
| `toast:getMessage(...)` | Returns the message of this Toast widget. |
| `toast:setDuration(...)` | Sets the duration for this Toast widget. |
| `toast:getDuration(...)` | Returns the duration of this Toast widget. |
| `toast:getProgress(...)` | Returns the progress of this Toast widget. |
| `toast:isExpired(...)` | Returns true if expired is enabled for this Toast widget. |

### `Toolbar` Methods

| Method | Description |
|--------|-------------|
| `toolbar:getOrientation(...)` | Returns the orientation of this Toolbar widget. |
| `toolbar:setOrientation(...)` | Sets the orientation for this Toolbar widget. |
| `toolbar:addButton(...)` | Adds a button entry to this Toolbar widget. |
| `toolbar:addSeparator(...)` | Adds a separator entry to this Toolbar widget. |
| `toolbar:addSpacer(...)` | Adds a spacer entry to this Toolbar widget. |
| `toolbar:getButton(...)` | Returns the button of this Toolbar widget. |
| `toolbar:setButtonEnabled(...)` | Sets the button enabled for this Toolbar widget. |
| `toolbar:setButtonToggled(...)` | Sets the button toggled for this Toolbar widget. |
| `toolbar:isButtonToggled(...)` | Returns true if button toggled is enabled for this Toolbar widget. |

### `Tooltip_Panel` Methods

| Method | Description |
|--------|-------------|
| `tooltip_panel:getText(...)` | Returns the text of this Tooltip_Panel widget. |
| `tooltip_panel:setText(...)` | Sets the text for this Tooltip_Panel widget. |
| `tooltip_panel:getDelay(...)` | Returns the delay of this Tooltip_Panel widget. |
| `tooltip_panel:setDelay(...)` | Sets the delay for this Tooltip_Panel widget. |
| `tooltip_panel:getTarget(...)` | Returns the target of this Tooltip_Panel widget. |
| `tooltip_panel:setTarget(...)` | Sets the target for this Tooltip_Panel widget. |

### `Tree_View` Methods

| Method | Description |
|--------|-------------|
| `tree_view:addNode(...)` | Adds a node entry to this Tree_View widget. |
| `tree_view:toggleNode(...)` | Toggles the expanded/collapsed status of a Tree_View node. |
| `tree_view:isExpanded(...)` | Returns true if expanded is enabled for this Tree_View widget. |
| `tree_view:getNodeCount(...)` | Returns the node count of this Tree_View widget. |
| `tree_view:removeNode(...)` | Removes the node from this Tree_View widget. |
| `tree_view:clearNodes(...)` | Clears all nodes entries from this Tree_View widget. |
| `tree_view:getNodeText(...)` | Returns the node text of this Tree_View widget. |
| `tree_view:setNodeText(...)` | Sets the node text for this Tree_View widget. |
| `tree_view:setNodeIcon(...)` | Sets the node icon for this Tree_View widget. |
| `tree_view:expandNode(...)` | Performs the expand node operation on this Tree_View widget. |
| `tree_view:collapseNode(...)` | Performs the collapse node operation on this Tree_View widget. |
| `tree_view:isNodeExpanded(...)` | Returns true if node expanded is enabled for this Tree_View widget. |
| `tree_view:expandAll(...)` | Performs the expand all operation on this Tree_View widget. |
| `tree_view:collapseAll(...)` | Performs the collapse all operation on this Tree_View widget. |
| `tree_view:setSelectedNode(...)` | Sets the selected node for this Tree_View widget. |
| `tree_view:getSelectedNode(...)` | Returns the selected node of this Tree_View widget. |
| `tree_view:getChildNodes(...)` | Returns the child nodes of this Tree_View widget. |
| `tree_view:getParentNode(...)` | Returns the parent node of this Tree_View widget. |
| `tree_view:getNodeDepth(...)` | Returns the node depth of this Tree_View widget. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.ui.
if lurek.ui then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 52 |
| `enum` | 6 |
| `fn` (Lua API) | 309 |
| **Total** | **367** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `image` | Imports or references `image` from `src/image/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `math` | Imports or references `math` from `src/math/`. | Cross-group dependency from Feature Systems to Foundations. |
| `render` | Imports or references `render` from `src/render/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Feature Systems to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/ui/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
