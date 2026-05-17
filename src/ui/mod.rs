//! - Immediate-mode GUI toolkit: containers, controls, extras, and theming.
//! - Provides layout panels, interactive widgets, and data-bound context.
//! - Optional chart and TOML layout-loader features behind feature flags.

/// Container widgets: panels, docks, scroll areas, split views.
pub mod containers;
/// GUI context, event dispatch, and data-binding values.
pub mod context;
/// Interactive control widgets: buttons, sliders, inputs, combo boxes.
pub mod controls;
/// Extended widgets: dialogs, menus, trees, tables, toasts, toolbars.
pub mod extras;
/// UI render helpers and draw-command generation.
pub mod render;
/// Theming and per-widget style configuration.
pub mod theme;
/// Base widget trait, state, transitions, and type registry.
pub mod widget;
pub use containers::{DockPanel, GUIWindow, Layout, LayoutDirection, NinePatch, NineSlice, Panel, ScrollPanel, SplitPanel};
pub use context::{GuiContext, GuiEvent, UiBindingValue};
pub use controls::{Button, CheckBox, ComboBox, Label, ListBox, ProgressBar, RadioButton, ScrollBar, Slider, SpinBox, Switch, TabBar, TextInput};
pub use extras::{Accordion, AccordionSection, Badge, ColorPicker, CustomWidget, Dialog, GUITable, ImageWidget, MenuBar, MenuItem, Separator, Spacer, StatusBar, TableColumn, Toast, Toolbar, ToolbarButton, TooltipPanel, TreeNode, TreeView};
pub use theme::{Theme, WidgetStyle};
pub use widget::{WidgetBase, WidgetState, WidgetTransition, WidgetTransitionKind, WidgetType};
/// TOML-based declarative layout loader and image renderer.
#[cfg(feature = "ui-layout-loader")]
pub mod layout_loader;
#[cfg(feature = "ui-layout-loader")]
pub use layout_loader::{load_layout_def, load_layout_toml, render_to_image, LayoutDef, WidgetDef};
/// Graph and chart data renderer for line/bar/area series.
pub mod data_graph_renderer;
pub use data_graph_renderer::{GraphRenderer, GraphSeries};
/// Rich chart widgets: line, bar, area, pie, and scatter plots.
#[cfg(feature = "ui-charts")]
pub mod chart;
#[cfg(feature = "ui-charts")]
pub use chart::{AreaChart, AreaLayer, BarCategory, BarChart, ChartConfig, ChartMargin, ChartSeries, LineChart, PieChart, PieSegment, ScatterPlot};
