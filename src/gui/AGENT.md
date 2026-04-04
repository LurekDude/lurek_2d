# `gui` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 2 — Reusable Engine Extensions |
| **Lua API** | `luna.gui` |
| **Source** | `src/gui/` |
| **Tests** | `tests/unit/gui_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_gui.lua` |

## Summary

Retained-mode 2D widget system for building in-game menus, HUDs, dialog
boxes, and inventory screens. The widget tree is rooted at an invisible
`Panel` returned by `getRoot()`; all concrete types share a `Widget` base
with position, size, visibility, zIndex, anchor constraints, and flexbox
layout properties. Built-in widget types cover the full UI spectrum: `Button`
(click with onClickRef), `Label` (text with font/alignment), `TextInput`
(editable single-line field), `CheckBox`, `Slider`, `ProgressBar`
(value-bound controls), `List`, `ComboBox` (1-based indexed selection),
`ScrollPanel` (overflow scrolling), `NinePatch` (scalable border panels),
and `Panel` (arbitrary child container). A theme system maps per-widget-type
per-state style records — normal, hover, pressed, focused, disabled — to
colours, fonts, and textures. Input events must be forwarded manually from
`luna.mousepressed`, `luna.keypressed`, etc., giving scripts full control
over which GUI instance is active. Toast notifications auto-expire after a
configurable duration.

## Architecture

```
Widget tree (retained, lazy-rendered)
  ├── root: Panel     ← invisible root, returned by getRoot()
  │
  ├── Widget (abstract base)
  │     ├── x, y, width, height, visible, enabled, zIndex
  │     ├── Anchor constraints (NaN = not anchored)
  │     └── Flexbox: direction, wrap, align, justify, flexGrow, flexShrink
  │
  ├── Concrete widget types
  │     ├── Button  { onClickRef }
  │     ├── Label   { text, font, align }
  │     ├── TextInput { value, placeholder, onChangeRef }
  │     ├── CheckBox / Slider / ProgressBar { value, onChangeRef }
  │     ├── List / ComboBox { items, selectedIndex (1-based), onSelectRef }
  │     ├── ScrollPanel { content, scrollX, scrollY }
  │     ├── NinePatch panel border rendering
  │     └── Panel   (container) { children: Vec<Widget>, layout }
  │
  ├── Theme system
  │     └── styles: HashMap<(WidgetType, StateName), WidgetStyle>
  │           (StateName: "normal"|"hover"|"pressed"|"focused"|"disabled")
  │
  ├── Input routing (manual forward)
  │     mousepressed / mousereleased / mousemoved / keypressed / textinput / wheelmoved
  │
  ├── Toast notifications (auto-expire overlays)
  └── update(dt) / draw()
```

## Source Files

| File | Purpose |
|------|---------|
| `widget.rs` | Widget base type: shared fields, anchor constraints, flexbox layout |
| `controls.rs` | Input controls: Button, Label, TextInput, Checkbox, RadioButton, Slider, ScrollBar, ComboBox, List, TabBar, ProgressBar |
| `containers.rs` | Container/layout types: Panel, GUIWindow, ScrollPanel, Layout, Spacer, Separator, NinePatch, SplitPanel, DockPanel, Accordion |
| `extras.rs` | Extended widget types: TreeView, Toolbar, MenuBar, MenuItem, Dialog, StatusBar, TooltipPanel, ColorPicker, GUITable, ImageWidget, Toast |
| `context.rs` | GuiContext: the widget pool (`Vec<WidgetKind>`), input dispatch, draw queue |
| `theme.rs` | Theme and WidgetStyle: per-type per-state style records |
| `mod.rs` | Module root: re-exports all public types |

## Lua API

Exposed under `luna.gui.*` by `src/lua_api/gui_api.rs`.

All Lua indices are **1-based**. Bindings use `index.checked_sub(1)` to convert
to 0-based Rust and `i + 1` when returning indices to Lua. Widget references
are Lua tables with methods injected at construction time; they are not
userdata values.

---

## Module Functions

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `newButton` | `text?: string=""` | `Button` | Create a button widget |
| `newLabel` | `text?: string=""` | `Label` | Create a text label |
| `newTextInput` | — | `TextInput` | Create a text input field |
| `newCheckbox` | `text?: string=""` | `Checkbox` | Create a checkbox with label |
| `newRadioButton` | `text?: string="", group?: string="default"` | `RadioButton` | Create grouped radio button |
| `newSlider` | `min?: number=0, max?: number=100` | `Slider` | Create a value slider |
| `newScrollBar` | `vertical?: boolean=true` | `ScrollBar` | Create a scroll bar |
| `newComboBox` | — | `ComboBox` | Create a dropdown combo box |
| `newPanel` | — | `Panel` | Create a container panel |
| `newWindow` | `title?: string=""` | `GUIWindow` | Create a draggable/closeable window |
| `newProgressBar` | `min?: number=0, max?: number=100` | `ProgressBar` | Create a progress bar |
| `newList` | — | `List` | Create a selectable list |
| `newTabBar` | — | `TabBar` | Create a tab bar |
| `newLayout` | `direction?: string="vertical"` | `Layout` | Create a flexbox layout container |
| `newTheme` | — | `Theme` | Create a theme instance |
| `newSeparator` | `vertical?: boolean=false` | `Separator` | Create a visual separator line |
| `newSpacer` | `width?: number=0, height?: number=0` | `Spacer` | Create an empty spacing widget |
| `newNinePatch` | — | `NinePatch` | Create a 9-patch slice calculator |
| `newScrollPanel` | — | `ScrollPanel` | Create a scrollable panel |
| `newToast` | `message?: string="", duration?: number=3.0` | `Toast` | Create a toast notification |
| `newTreeView` | — | `TreeView` | Create a collapsible tree widget |
| `newToolbar` | `orientation?: string="horizontal"` | `Toolbar` | Create a toolbar container |
| `newMenuBar` | — | `MenuBar` | Create a horizontal menu bar |
| `newMenuItem` | `text: string` | `MenuItem` | Create a menu item |
| `newDialog` | `title?: string=""` | `Dialog` | Create a modal dialog |
| `newStatusBar` | — | `StatusBar` | Create a status bar |
| `newSplitPanel` | `orientation?: string="horizontal"` | `SplitPanel` | Create a resizable split panel |
| `newDockPanel` | — | `DockPanel` | Create a dock-based layout container |
| `newAccordion` | — | `Accordion` | Create a collapsible section container |
| `newTooltipPanel` | `text?: string=""` | `TooltipPanel` | Create a rich tooltip panel |
| `newColorPicker` | — | `ColorPicker` | Create a color picker widget |
| `newTable` | — | `GUITable` | Create a data table widget |
| `newImageWidget` | `image?: Texture` | `ImageWidget` | Create an image display widget |
| `setTheme` | `theme: Theme` | — | Set the active theme |
| `getTheme` | — | `Theme \| nil` | Get the active theme |
| `getRoot` | — | `Widget` | Get the root panel of the widget tree |
| `setFocus` | `widget: Widget \| nil` | — | Set keyboard focus (nil to clear) |
| `getFocus` | — | `Widget \| nil` | Get the currently focused widget |
| `focusNext` | — | — | Move focus to next widget in tab order |
| `focusPrev` | — | — | Move focus to previous widget in tab order |
| `clearFocus` | — | — | Remove keyboard focus from all widgets |
| `addToast` | `toast: Toast` | — | Queue a toast for display |
| `getToastCount` | — | `number` | Number of active toast notifications |
| `mousepressed` | `x: number, y: number, button?: int=1` | `boolean` | Forward mouse press; returns true if consumed |
| `mousereleased` | `x: number, y: number, button?: int=1` | `boolean` | Forward mouse release; returns true if consumed |
| `mousemoved` | `x: number, y: number, dx?: number=0, dy?: number=0` | `boolean` | Forward mouse move; returns true if consumed |
| `keypressed` | `key: string` | `boolean` | Forward key press; returns true if consumed |
| `textinput` | `text: string` | `boolean` | Forward text input; returns true if consumed |
| `wheelmoved` | `x: number, y: number` | `boolean` | Forward wheel move; returns true if consumed |
| `update` | `dt: number` | — | Update all widgets (animations, toasts) |
| `draw` | — | — | Draw the entire widget tree |

---

## Widget (base type)

All widget types inherit these methods.

### WidgetState values

`"normal"` `"hovered"` `"pressed"` `"focused"` `"disabled"`

### Methods

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setPosition` | `x: number, y: number` | — | Set position relative to parent |
| `getPosition` | — | `x: number, y: number` | Get position relative to parent |
| `setSize` | `w: number, h: number` | — | Set width and height |
| `getSize` | — | `w: number, h: number` | Get width and height |
| `setVisible` | `visible: boolean` | — | Show/hide widget |
| `isVisible` | — | `boolean` | Check visibility |
| `setEnabled` | `enabled: boolean` | — | Enable/disable input |
| `isEnabled` | — | `boolean` | Check if enabled |
| `setId` | `id: string` | — | Set identifier for `findById` |
| `getId` | — | `string` | Get identifier |
| `setTooltip` | `text: string` | — | Set tooltip text |
| `getTooltip` | — | `string` | Get tooltip text |
| `addChild` | `child: Widget` | — | Add a child to this widget |
| `removeChild` | `child: Widget` | — | Remove a child widget |
| `getChildCount` | — | `number` | Number of children |
| `findById` | `id: string` | `Widget \| nil` | Recursive search by ID |
| `containsPoint` | `x: number, y: number` | `boolean` | Hit test |
| `setPadding` | `top: number, right?: number, bottom?: number, left?: number` | — | Set inner padding (CSS shorthand) |
| `getPadding` | — | `top, right, bottom, left` | Get padding (4 values) |
| `getState` | — | `string` | Current state name |
| `setOnClick` | `callback: function` | — | Set click handler |
| `setOnChange` | `callback: function` | — | Set change handler |
| `setOnDraw` | `callback: function` | — | Set custom draw handler |
| `setMargin` | `top: number, right?: number, bottom?: number, left?: number` | — | Set outer margin (CSS shorthand) |
| `getMargin` | — | `top, right, bottom, left` | Get margin (4 values) |
| `setZOrder` | `z: number` | — | Set draw layer (higher = on top) |
| `getZOrder` | — | `number` | Get draw layer |
| `setMinSize` | `w: number, h: number` | — | Set minimum size constraints |
| `getMinSize` | — | `w: number, h: number` | Get minimum size constraints |
| `setMaxSize` | `w: number, h: number` | — | Set maximum size constraints |
| `getMaxSize` | — | `w: number, h: number` | Get maximum size constraints |
| `setAnchor` | `left: number\|nil, top: number\|nil, right: number\|nil, bottom: number\|nil` | — | Set constraint edges (nil = unanchored) |
| `setAnchorCenter` | `cx: number\|nil, cy: number\|nil` | — | Set center anchor (nil = unanchored) |
| `clearAnchor` | — | — | Remove all anchor constraints |
| `setFlexGrow` | `grow: number` | — | Set flex grow factor |
| `getFlexGrow` | — | `number` | Get flex grow factor |
| `setFlexShrink` | `shrink: number` | — | Set flex shrink factor |
| `getFlexShrink` | — | `number` | Get flex shrink factor |

---

## Button

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setText` | `text: string` | — | Set button label text |
| `getText` | — | `string` | Get button label text |

## Label

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setText` | `text: string` | — | Set label text |
| `getText` | — | `string` | Get label text |

## TextInput

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setText` | `text: string` | — | Set input text |
| `getText` | — | `string` | Get input text |
| `setPlaceholder` | `text: string` | — | Set placeholder text |
| `getPlaceholder` | — | `string` | Get placeholder text |
| `setMaxLength` | `n: number` | — | Set maximum character count |
| `isFocused` | — | `boolean` | Check if input has keyboard focus |
| `getCursorPosition` | — | `number` | Get cursor index |

## Checkbox

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setChecked` | `checked: boolean` | — | Set checked state |
| `isChecked` | — | `boolean` | Get checked state |
| `setText` | `text: string` | — | Set label text |
| `getText` | — | `string` | Get label text |

## RadioButton

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setSelected` | `selected: boolean` | — | Set selection state |
| `isSelected` | — | `boolean` | Get selection state |
| `setGroup` | `group: string` | — | Set radio group name |
| `setText` | `text: string` | — | Set label text |
| `getText` | — | `string` | Get label text |

## Slider

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setValue` | `value: number` | — | Set current value |
| `getValue` | — | `number` | Get current value |
| `setRange` | `min: number, max: number` | — | Set value range |
| `setStep` | `step: number` | — | Set step increment |

## ScrollBar

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setScrollPosition` | `pos: number` | — | Set scroll position |
| `getScrollPosition` | — | `number` | Get scroll position |
| `setContentSize` | `size: number` | — | Set total content size |
| `setViewSize` | `size: number` | — | Set visible view size |

## ComboBox

Inherits all Widget methods plus (1-based indices):

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addItem` | `text: string` | — | Append an item |
| `removeItem` | `index: number` | — | Remove item at index (1-based) |
| `clearItems` | — | — | Remove all items |
| `getItemCount` | — | `number` | Number of items |
| `getItem` | `index: number` | `string` | Get item text (1-based) |
| `setSelectedIndex` | `index: number` | — | Set selection (1-based) |
| `getSelectedIndex` | — | `number` | Get selection (1-based) |
| `getSelectedItem` | — | `string \| nil` | Get selected item text |

## Panel

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setTitle` | `title: string` | — | Set panel title |
| `getTitle` | — | `string` | Get panel title |
| `setScrollable` | `scrollable: boolean` | — | Enable/disable scrolling |

## GUIWindow

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setTitle` | `title: string` | — | Set window title |
| `getTitle` | — | `string` | Get window title |
| `setCloseable` | `closeable: boolean` | — | Enable close button |
| `setDraggable` | `draggable: boolean` | — | Enable drag behaviour |
| `setResizable` | `resizable: boolean` | — | Enable resize handles |

## ProgressBar

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setValue` | `value: number` | — | Set current value |
| `getValue` | — | `number` | Get current value |
| `getProgress` | — | `number` | Get normalized progress (0..1) |
| `setRange` | `min: number, max: number` | — | Set value range |

## List

Inherits all Widget methods plus (1-based indices):

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addItem` | `text: string` | — | Append an item |
| `removeItem` | `index: number` | — | Remove item (1-based) |
| `clearItems` | — | — | Remove all items |
| `getItemCount` | — | `number` | Number of items |
| `getItem` | `index: number` | `string` | Get item text (1-based) |
| `setSelectedIndex` | `index: number` | — | Set selection (1-based) |
| `getSelectedIndex` | — | `number` | Get selection (1-based) |
| `setItemHeight` | `height: number` | — | Set per-item height |

## TabBar

Inherits all Widget methods plus (1-based indices):

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addTab` | `label: string` | — | Append a tab |
| `removeTab` | `index: number` | — | Remove tab (1-based) |
| `getTabCount` | — | `number` | Number of tabs |
| `setActiveTab` | `index: number` | — | Set active tab (1-based) |
| `getActiveTab` | — | `number` | Get active tab (1-based) |

## Layout

Inherits all Widget methods plus:

### LayoutDirection values
`"vertical"`, `"horizontal"`, `"grid"`

### FlexAlign values
`"start"`, `"center"`, `"end"`, `"stretch"`

### FlexJustify values
`"start"`, `"center"`, `"end"`, `"space-between"`, `"space-around"`, `"space-evenly"`

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setDirection` | `dir: string` | — | Set layout direction |
| `setSpacing` | `spacing: number` | — | Set inter-child spacing |
| `setColumns` | `n: number` | — | Set column count (grid mode) |
| `performLayout` | — | — | Recalculate child positions |
| `setWrap` | `wrap: boolean` | — | Enable line wrapping |
| `getWrap` | — | `boolean` | Get wrap state |
| `setAlign` | `align: string` | — | Set cross-axis alignment |
| `getAlign` | — | `string` | Get cross-axis alignment |
| `setJustify` | `justify: string` | — | Set main-axis justification |
| `getJustify` | — | `string` | Get main-axis justification |

## Separator

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setVertical` | `vertical: boolean` | — | Set orientation |
| `isVertical` | — | `boolean` | Get orientation |
| `setThickness` | `thickness: number` | — | Set line thickness |
| `getThickness` | — | `number` | Get line thickness |

## Spacer

Inherits all Widget methods. No additional methods (pure layout filler).

## NinePatch

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setInsets` | `left: int, top: int, right: int, bottom: int` | — | Set 9-patch slice insets |
| `getInsets` | — | `left, top, right, bottom` | Get slice insets (4 values) |
| `setImageDimensions` | `w: number, h: number` | — | Set source image size |
| `getImageDimensions` | — | `w: number, h: number` | Get source image size |
| `getSlices` | — | `table` | Get 9 slice rects: `{sx,sy,sw,sh,dx,dy,dw,dh}` per entry |

## ScrollPanel

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setContentSize` | `w: number, h: number` | — | Set scrollable content dimensions |
| `getContentSize` | — | `w: number, h: number` | Get content dimensions |
| `setScrollPosition` | `x: number, y: number` | — | Set scroll offset |
| `getScrollPosition` | — | `x: number, y: number` | Get scroll offset |
| `getMaxScroll` | — | `x: number, y: number` | Get maximum scroll limits |
| `setScrollSpeed` | `speed: number` | — | Set scroll speed multiplier |
| `getScrollSpeed` | — | `number` | Get scroll speed multiplier |

## Toast

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setMessage` | `msg: string` | — | Set notification message |
| `getMessage` | — | `string` | Get message text |
| `setDuration` | `seconds: number` | — | Set display duration |
| `getDuration` | — | `number` | Get display duration |
| `getProgress` | — | `number` | Get 0..1 progress through lifetime |
| `isExpired` | — | `boolean` | Check if duration has elapsed |

## TreeView

Inherits all Widget methods plus (1-based indices):

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addNode` | `text: string, parentIndex?: number` | `number` | Add a node; optional parent index. Returns 1-based index |
| `removeNode` | `index: number` | `boolean` | Remove node and its children (1-based); returns true on success |
| `clearNodes` | — | — | Remove all nodes |
| `getNodeCount` | — | `number` | Total node count |
| `getNodeText` | `index: number` | `string \| nil` | Get node text (1-based) |
| `setNodeText` | `index: number, text: string` | `boolean` | Set node text (1-based); returns true on success |
| `setNodeIcon` | `index: number, icon: string \| nil` | `boolean` | Set node icon path (1-based); returns true on success |
| `expandNode` | `index: number` | `boolean` | Expand a node to show children; returns true on success |
| `collapseNode` | `index: number` | `boolean` | Collapse a node; returns true on success |
| `isNodeExpanded` | `index: number` | `boolean \| nil` | Get expanded state (1-based); nil if out of range |
| `expandAll` | — | — | Expand all nodes |
| `collapseAll` | — | — | Collapse all nodes |
| `setSelectedNode` | `index: number` | `boolean` | Set selected node (1-based); returns true on success |
| `getSelectedNode` | — | `number \| nil` | Get selected node index (1-based), or nil if none |
| `getChildNodes` | `index: number` | `{number,...}` | Get child node indices as 1-based array |
| `getParentNode` | `index: number` | `number \| nil` | Get parent index (1-based), or nil if root |
| `getNodeDepth` | `index: number` | `number` | Get nesting depth (0 = root level) |

## Toolbar

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addButton` | `id: string, tooltip?: string` | `number` | Add toolbar button; returns 1-based index |
| `addSeparator` | — | — | Add a visual separator |
| `addSpacer` | `width?: number` | — | Add flexible space |
| `getButton` | `id: string` | `table \| nil` | Get button info table `{id, tooltip, enabled, toggled}` by id |
| `setButtonEnabled` | `id: string, enabled: boolean` | `boolean` | Enable/disable a button; returns true on success |
| `setButtonToggled` | `id: string, toggled: boolean` | `boolean` | Set toggle state; returns true on success |
| `isButtonToggled` | `id: string` | `boolean \| nil` | Get toggle state; nil if id not found |

## MenuBar

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addMenu` | `menu_idx: number` | — | Register a top-level MenuItem widget by its context index |
| `getMenuCount` | — | `number` | Number of top-level menus |
| `getMenu` | `index: number` | `MenuItem` | Get top-level menu (1-based) |
| `closeAll` | — | — | Close all open menus |

## MenuItem

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setText` | `text: string` | — | Set item text |
| `getText` | — | `string` | Get item text |
| `setShortcut` | `shortcut: string` | — | Set display shortcut text (e.g. `"Ctrl+S"`) |
| `getShortcut` | — | `string` | Get shortcut text |
| `addSubItem` | `child_idx: number` | — | Register a child MenuItem by its context index |
| `getSubItems` | — | `{number,...}` | Get child MenuItem context indices |
| `addSeparator` | — | — | Add a separator line |
| `getItemCount` | — | `number` | Number of sub-items |
| `getItem` | `index: number` | `MenuItem` | Get sub-item (1-based) |
| `setChecked` | `checked: boolean` | — | Set check mark state |
| `isChecked` | — | `boolean` | Get check mark state |
| `setIcon` | `icon: Texture \| nil` | — | Set item icon |

## Dialog

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setTitle` | `title: string` | — | Set dialog title |
| `getTitle` | — | `string` | Get dialog title |
| `setModal` | `modal: boolean` | — | Set modal (blocks background input; default true) |
| `isModal` | — | `boolean` | Check modal state |
| `setContent` | `content_idx: number \| nil` | — | Set content widget by context index (nil clears) |
| `getContent` | — | `number \| nil` | Get content widget context index, or nil if none |
| `addButton` | `text: string, callback?: function` | `number` | Add a footer button; returns footer button count |
| `show` | — | — | Show the dialog |
| `close` | — | — | Close the dialog |
| `isOpen` | — | `boolean` | Check if dialog is displayed |
| `setOnClose` | `callback: function` | — | Set handler for dialog close |

## StatusBar

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addSection` | `text: string, width?: number` | — | Append a section with text and optional fixed width |
| `setSectionText` | `index: number, text: string` | — | Set section text (1-based) |
| `getSectionText` | `index: number` | `string \| nil` | Get section text (1-based); nil if out of range |
| `getSectionCount` | — | `number` | Get number of sections |
| `setSectionCount` | `count: number` | — | Resize sections array (shrinks or grows) |
| `setSectionWidget` | `index: number, widget: number` | — | Set a custom widget (by context index) in a section |

## SplitPanel

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setFirstPanel` | `widget: Widget` | — | Set the first (left/top) panel content |
| `setSecondPanel` | `widget: Widget` | — | Set the second (right/bottom) panel content |
| `getFirstPanel` | — | `Widget \| nil` | Get first panel |
| `getSecondPanel` | — | `Widget \| nil` | Get second panel |
| `setSplitPosition` | `ratio: number` | — | Set split ratio (0.0–1.0, default 0.5) |
| `getSplitPosition` | — | `number` | Get split ratio |
| `setMinPanelSize` | `minSize: number` | — | Set minimum panel size in pixels |
| `setOrientation` | `orientation: string` | — | `"horizontal"` or `"vertical"` |
| `getOrientation` | — | `string` | Get orientation |

## DockPanel

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `dock` | `widget: Widget, side: string` | — | Dock a widget to a side (`"left"`, `"right"`, `"top"`, `"bottom"`, `"center"`) |
| `undock` | `widget: Widget` | — | Remove a docked widget |
| `getSide` | `widget: Widget` | `string \| nil` | Get which side a widget is docked to |
| `getDocked` | `side: string` | `Widget \| nil` | Get the widget docked to a specific side |
| `setSplitSize` | `side: string, size: number` | — | Set the size (width or height) of a docked panel |

## Accordion

Inherits all Widget methods plus (1-based indices):

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addSection` | `title: string, content_idx?: number` | — | Add a collapsible section with optional content widget index |
| `removeSection` | `index: number` | — | Remove section (1-based) |
| `getSectionCount` | — | `number` | Number of sections |
| `setSectionTitle` | `index: number, title: string` | — | Set section title (1-based) |
| `getSectionTitle` | `index: number` | `string` | Get section title (1-based) |
| `expandSection` | `index: number` | — | Expand a section |
| `collapseSection` | `index: number` | — | Collapse a section |
| `isSectionExpanded` | `index: number` | `boolean` | Check if section is expanded |
| `setExclusive` | `exclusive: boolean` | — | If true, only one section can be expanded at a time |
| `isExclusive` | — | `boolean` | Check exclusive mode |

## TooltipPanel

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setText` | `text: string` | — | Set tooltip text |
| `getText` | — | `string` | Get tooltip text |
| `setDelay` | `seconds: number` | — | Set hover delay before showing |
| `getDelay` | — | `number` | Get hover delay |
| `setTarget` | `widget: Widget` | — | Attach to a target widget (shows on target hover) |
| `getTarget` | — | `Widget \| nil` | Get target widget |

## ColorPicker

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setColor` | `r: number, g: number, b: number, a?: number` | — | Set selected color |
| `getColor` | — | `r, g, b, a` | Get selected color |
| `setShowAlpha` | `show: boolean` | — | Show/hide alpha slider |
| `isShowAlpha` | — | `boolean` | Check alpha slider visibility |
| `setShowHex` | `show: boolean` | — | Show/hide hex input field |
| `setColorMode` | `mode: string` | — | `"rgb"`, `"hsv"`, or `"hsl"` |
| `getColorMode` | — | `string` | Get color mode |

## GUITable

Inherits all Widget methods plus (1-based indices):

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `addColumn` | `header: string, width?: number` | — | Add a column |
| `removeColumn` | `index: number` | — | Remove column (1-based) |
| `getColumnCount` | — | `number` | Number of columns |
| `setColumnHeader` | `index: number, header: string` | — | Set column header text (1-based) |
| `setColumnWidth` | `index: number, width: number` | — | Set column width (1-based) |
| `addRow` | `values: {string,...}` | `number` | Add a row; returns row index (1-based) |
| `removeRow` | `index: number` | — | Remove row (1-based) |
| `clearRows` | — | — | Remove all rows |
| `getRowCount` | — | `number` | Number of rows |
| `setCell` | `row: number, col: number, value: string` | — | Set cell value (1-based) |
| `getCell` | `row: number, col: number` | `string` | Get cell value (1-based) |
| `setSelectedRow` | `index: number` | — | Set selected row (1-based) |
| `getSelectedRow` | — | `number` | Get selected row (1-based) |
| `setSortable` | `sortable: boolean` | — | Enable/disable column sort on header click |
| `sortByColumn` | `index: number, ascending?: boolean` | — | Sort rows by column (1-based) |

## ImageWidget

Inherits all Widget methods plus:

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setImage` | `image: Texture \| nil` | — | Set displayed image |
| `getImage` | — | `Texture \| nil` | Get displayed image |
| `setScaleMode` | `mode: string` | — | `"fit"`, `"fill"`, `"stretch"`, or `"none"` |
| `getScaleMode` | — | `string` | Get scale mode |
| `setTint` | `r: number, g: number, b: number, a?: number` | — | Set color tint |
| `getTint` | — | `r, g, b, a` | Get color tint |

---

## Theme

Does NOT inherit Widget. Standalone type.

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setStyle` | `widgetType: string, state: string, style: table` | — | Set style for a widget type + state |
| `getStyle` | `widgetType: string, state: string` | `table` | Get style table |
| `setName` | `name: string` | — | Set theme name |
| `getName` | — | `string` | Get theme name |

### WidgetStyle table format (for `setStyle`/`getStyle`):

```lua
{
    backgroundColor = {r, g, b, a},  -- default {0.2, 0.2, 0.2, 1.0}
    textColor       = {r, g, b, a},  -- default {1.0, 1.0, 1.0, 1.0}
    borderColor     = {r, g, b, a},  -- default {0.4, 0.4, 0.4, 1.0}
    borderWidth     = number,         -- pixels
    cornerRadius    = number,         -- pixels
    fontSize        = number          -- points
}
```

---

## Type Summary

| Type | Factory | Inherits Widget | Additional Methods |
|---|---|---|---|
| `Widget` | (base — no factory) | — | 38 shared methods |
| `Accordion` | `newAccordion` | ✅ | 10 methods |
| `Button` | `newButton` | ✅ | `setText`, `getText` |
| `Checkbox` | `newCheckbox` | ✅ | 4 methods |
| `ColorPicker` | `newColorPicker` | ✅ | 7 methods |
| `ComboBox` | `newComboBox` | ✅ | 8 methods |
| `Dialog` | `newDialog` | ✅ | 11 methods |
| `DockPanel` | `newDockPanel` | ✅ | 5 methods |
| `GUITable` | `newTable` | ✅ | 15 methods |
| `GUIWindow` | `newWindow` | ✅ | 5 methods |
| `ImageWidget` | `newImageWidget` | ✅ | 6 methods |
| `Label` | `newLabel` | ✅ | `setText`, `getText` |
| `Layout` | `newLayout` | ✅ | 10 methods |
| `List` | `newList` | ✅ | 8 methods |
| `MenuBar` | `newMenuBar` | ✅ | 4 methods |
| `MenuItem` | `newMenuItem` | ✅ | 12 methods |
| `NinePatch` | `newNinePatch` | ✅ | 5 methods |
| `Panel` | `newPanel` | ✅ | 3 methods |
| `ProgressBar` | `newProgressBar` | ✅ | 4 methods |
| `RadioButton` | `newRadioButton` | ✅ | 5 methods |
| `ScrollBar` | `newScrollBar` | ✅ | 4 methods |
| `ScrollPanel` | `newScrollPanel` | ✅ | 7 methods |
| `Separator` | `newSeparator` | ✅ | 4 methods |
| `Slider` | `newSlider` | ✅ | 4 methods |
| `Spacer` | `newSpacer` | ✅ | (none) |
| `SplitPanel` | `newSplitPanel` | ✅ | 9 methods |
| `StatusBar` | `newStatusBar` | ✅ | 6 methods |
| `TabBar` | `newTabBar` | ✅ | 5 methods |
| `TextInput` | `newTextInput` | ✅ | 7 methods |
| `Toast` | `newToast` | ✅ | 6 methods |
| `Toolbar` | `newToolbar` | ✅ | 7 methods |
| `TooltipPanel` | `newTooltipPanel` | ✅ | 6 methods |
| `TreeView` | `newTreeView` | ✅ | 17 methods |
| `Theme` | `newTheme` | ❌ | 4 methods |

---

## Module Boundaries

**vs luna.graphics** — Graphics provides immediate-mode draw primitives (images, rectangles, text). GUI is a retained-mode widget tree that internally calls Graphics for rendering. Never mix raw `luna.graphics.draw` inside a widget region.

**vs luna.scene** — Scene manages screen transitions. GUI widgets live *inside* a scene; push a GUI-heavy scene for menus, overlay widgets on gameplay scenes.

**vs luna.inventory** — Inventory manages item *data* (stacks, containers, equipment). GUI renders the *view* (grid of InventorySlot widgets). Connect them by reading Inventory state in GUI callbacks.

**vs luna.event** — Event delivers raw input (key presses, mouse clicks). GUI translates those into widget-level callbacks (`onClick`, `onFocus`, `onChange`). Widgets consume input events; raw handlers should not duplicate widget logic.

**vs luna.dialog** — Dialog manages narrative text flow (typewriter, choices, branching). GUI provides the visual container (a Panel with Labels). Dialog feeds content; GUI renders it.

## Game Design Role

- **Menus**: Title screens, pause menus, settings panels — all composed from Widget trees.
- **HUD**: Health bars, score counters, minimaps laid out with anchor constraints.
- **Dialogs**: Modal confirmation boxes, popup alerts, and toast notifications.
- **Forms**: Text inputs, sliders, checkboxes for user settings or in-game editors.
- **Focus navigation**: Keyboard / gamepad tab-order for accessibility.
- **Notifications**: Toast messages that auto-dismiss after a timeout.
