//! TOML-driven retained-mode UI subsystem for `lurek.ui`. Owns widgets,
//! containers, controls, theming, layout loading, chart rendering, and a
//! data-graph renderer. Does not own rendering draw calls directly — those
//! live in `render.rs`. Key dependencies: `fontdue`, `crate::render`.

pub mod containers;
pub mod context;
pub mod controls;
pub mod extras;
pub mod render;
pub mod theme;
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
#[cfg(feature = "ui-layout-loader")]
pub mod layout_loader;
#[cfg(feature = "ui-layout-loader")]
pub use layout_loader::{load_layout_def, load_layout_toml, render_to_image, LayoutDef, WidgetDef};
pub mod data_graph_renderer;
pub use data_graph_renderer::{GraphRenderer, GraphSeries};
#[cfg(feature = "ui-charts")]
pub mod chart;
#[cfg(feature = "ui-charts")]
pub use chart::{
    AreaChart, AreaLayer, BarCategory, BarChart, ChartConfig, ChartMargin, ChartSeries, LineChart,
    PieChart, PieSegment, ScatterPlot,
};
