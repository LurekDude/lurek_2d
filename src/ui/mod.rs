//! Retained-mode 2D widget system for building in-game menus, HUDs, dialog
//! boxes, and inventory screens.
//!
//! The `ui` module provides a tree of widgets rooted at an invisible `Panel`
//! returned by `getRoot()`.  Concrete widget types — `Button`, `Label`,
//! `TextInput`, `CheckBox`, `Slider`, `ProgressBar`, `ListBox`, `ComboBox`,
//! `ScrollPanel`, `NinePatch`, `Panel`, `Toast`, and many more — inherit
//! shared base properties (position, size, visibility, padding, margin,
//! z-order, anchor constraints, and flexbox layout settings) from `WidgetBase`.
//!
//! A `Theme` maps `(WidgetType, WidgetState)` pairs to `WidgetStyle` records
//! containing colours, font size, border width, and corner radius.  Input
//! events are forwarded manually from `lurek.mousepressed` / `lurek.keypressed`
//! etc., giving scripts full control over which GUI instance is active.
//!
//! ## Sub-modules
//!
//! | Sub-module | Exported types | Purpose |
//! |---|---|---|
//! | `widget` | [`WidgetBase`], [`WidgetState`], [`WidgetType`] | Shared base fields, state enum, type tag |
//! | `theme` | [`Theme`], [`WidgetStyle`] | Per-widget-type per-state styling |
//! | `containers` | [`Panel`], [`Layout`], [`ScrollPanel`], [`NinePatch`] | Layout containers and nine-patch slicer |
//! | `controls` | [`Button`], [`Label`], [`TextInput`], [`CheckBox`], [`Slider`], [`ProgressBar`], [`ComboBox`], [`ListBox`], [`TabBar`], [`SpinBox`], [`Switch`] | Interactive and display controls |
//! | `extras` | [`Toast`], [`Separator`], [`Spacer`], [`TreeNode`], [`TreeView`], [`Badge`] | Utility widgets: notifications, separators, tree views, badges |
//! | `context` | [`GuiContext`] | Root widget tree, focus tracking, toast queue, input routing |
//!
//! ## Tier
//!
//! `ui` is a **Tier 2 — Engine Extension** module.  It may import `math`,
//! `engine`, and all Tier 1 modules.  It must not import other Tier 2 modules.

/// Layout primitives: panels, dock, scroll, window, nine-slice, split, and grid containers.
pub mod containers;
/// Root widget tree, focus management, input routing, and toast queue.
pub mod context;
/// Interactive leaf widgets: buttons, checkboxes, sliders, combo-boxes, text inputs, and more.
pub mod controls;
/// Extended widgets: accordion, color picker, dialog, menu bar, status bar, tree view, and table.
pub mod extras;
/// Render command generation for the widget tree.
pub mod render;
/// Visual theme tokens (colors, fonts, spacing) used across all widgets.
pub mod theme;
/// Core widget trait and shared widget-state types.
pub mod widget;

pub use containers::{
    DockPanel, GUIWindow, Layout, LayoutDirection, NinePatch, NineSlice, Panel, ScrollPanel,
    SplitPanel,
};
pub use context::{GuiContext, GuiEvent, UiBindingValue};
pub use controls::{
    Button, CheckBox, ComboBox, Label, ListBox, ProgressBar, RadioButton, ScrollBar, Slider,
    SpinBox, Switch, TabBar, TextInput,
};
pub use extras::{
    Accordion, AccordionSection, Badge, ColorPicker, CustomWidget, Dialog, GUITable, ImageWidget,
    MenuBar, MenuItem, Separator, Spacer, StatusBar, TableColumn, Toast, Toolbar, ToolbarButton,
    TooltipPanel, TreeNode, TreeView,
};
pub use theme::{Theme, WidgetStyle};
pub use widget::{WidgetBase, WidgetState, WidgetTransition, WidgetTransitionKind, WidgetType};

/// Layout definition loader and headless PNG rasteriser for UI testing.
#[cfg(feature = "ui-layout-loader")]
pub mod layout_loader;
#[cfg(feature = "ui-layout-loader")]
pub use layout_loader::{load_layout_def, load_layout_toml, render_to_image, LayoutDef, WidgetDef};

/// Mathematical function graph and chart renderer (data series, viewport mapping).
pub mod data_graph_renderer;
pub use data_graph_renderer::{GraphRenderer, GraphSeries};

/// Configurable chart rendering to `ImageData` (line, bar, scatter, pie, area).
#[cfg(feature = "ui-charts")]
pub mod chart;
#[cfg(feature = "ui-charts")]
pub use chart::{
    AreaChart, AreaLayer, BarCategory, BarChart, ChartConfig, ChartMargin, ChartSeries, LineChart,
    PieChart, PieSegment, ScatterPlot,
};
