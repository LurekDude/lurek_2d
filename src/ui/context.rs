//! Root widget tree, focus tracking, toast queue, and input routing.
//!
//! [`GuiContext`] is the central coordinator for the GUI system.  It owns a
//! flat pool of type-erased widgets (stored as [`WidgetKind`] enum variants),
//! tracks which widget has keyboard focus, manages a queue of active
//! [`Toast`](super::Toast) notifications, and optionally holds a [`Theme`]
//! for styled rendering.
//!
//! Widgets are identified by a `usize` index into the internal `widgets`
//! vector.  The root panel is always at index `0`.  Container widgets
//! (`Panel`, `Layout`, `ScrollPanel`) store their children's indices.
//!
//! Input events are forwarded from Lua callbacks and dispatched to the widget
//! tree by hit-testing against widget bounds.

use crate::log_msg;
use crate::runtime::log_messages::{GU01_CTX_INIT, GU02_WIDGET_ADD};
use crate::ui::containers::{
    DockPanel, GUIWindow, Layout, NinePatch, Panel, ScrollPanel, SplitPanel,
};
use crate::ui::controls::{
    Button, CheckBox, ComboBox, Label, ListBox, ProgressBar, RadioButton, ScrollBar, Slider,
    SpinBox, Switch, TabBar, TextInput,
};
use crate::ui::extras::{
    Accordion, Badge, ColorPicker, CustomWidget, Dialog, GUITable, ImageWidget, MenuBar, MenuItem,
    Separator, Spacer, StatusBar, Toast, Toolbar, TooltipPanel, TreeView,
};
use crate::ui::theme::Theme;
use crate::ui::widget::{WidgetBase, WidgetState, WidgetTransition};
use std::collections::HashMap;

/// Value variant used by UI model-to-widget binding sync.
#[derive(Debug, Clone, PartialEq)]
pub enum UiBindingValue {
    /// Numeric binding value.
    Number(f64),
    /// Text binding value.
    Text(String),
    /// Boolean binding value.
    Bool(bool),
}

/// A single interaction event emitted by the GUI widget tree.
///
/// Accumulated by [`GuiContext`] in `pending_events` and drained by the Lua
/// bridge each frame to dispatch registered Lua callbacks.
///
/// # Variants
/// - `Click(usize)` — A button-family widget at the given index was activated.
/// - `Change(usize)` — A value-bearing widget changed its value.
/// - `Close(usize)` — A dismissible widget was closed.
/// - `Select(usize, usize)` — An item in a list/tab widget was selected; (widget_idx, item_idx).
#[derive(Debug, Clone)]
pub enum GuiEvent {
    /// A button or clickable widget at the given index was activated.
    Click(usize),
    /// A value-bearing widget at the given index changed its value.
    Change(usize),
    /// A dismissible widget at the given index was closed.
    Close(usize),
    /// An item in a list/tab widget was selected; (widget_idx, item_idx).
    Select(usize, usize),
}

/// Type-erased widget storage.
///
/// Each variant wraps a concrete widget type so that the [`GuiContext`] can
/// store all widgets in a single `Vec<WidgetKind>`.
///
/// # Variants
/// - `Button` — Wraps a [`Button`].
/// - `Label` — Wraps a [`Label`].
/// - `TextInput` — Wraps a [`TextInput`].
/// - `CheckBox` — Wraps a [`CheckBox`].
/// - `Slider` — Wraps a [`Slider`].
/// - `ProgressBar` — Wraps a [`ProgressBar`].
/// - `ComboBox` — Wraps a [`ComboBox`].
/// - `ListBox` — Wraps a [`ListBox`].
/// - `Panel` — Wraps a [`Panel`].
/// - `Layout` — Wraps a [`Layout`].
/// - `ScrollPanel` — Wraps a [`ScrollPanel`].
/// - `NinePatch` — Wraps a [`NinePatch`].
/// - `TabBar` — Wraps a [`TabBar`].
/// - `Toast` — Wraps a [`Toast`].
/// - `Separator` — Wraps a [`Separator`].
/// - `Spacer` — Wraps a [`Spacer`].
/// - `TreeView` — Wraps a [`TreeView`].
/// - `RadioButton` — Wraps a [`RadioButton`].
/// - `ScrollBar` — Wraps a [`ScrollBar`].
/// - `GUIWindow` — Wraps a [`GUIWindow`].
/// - `SplitPanel` — Wraps a [`SplitPanel`].
/// - `DockPanel` — Wraps a [`DockPanel`].
/// - `Toolbar` — Wraps a [`Toolbar`].
/// - `MenuBar` — Wraps a [`MenuBar`].
/// - `MenuItem` — Wraps a [`MenuItem`].
/// - `Dialog` — Wraps a [`Dialog`].
/// - `StatusBar` — Wraps a [`StatusBar`].
/// # Variants
/// - `Accordion` — Wraps a [`Accordion`].
/// - `TooltipPanel` — Wraps a [`TooltipPanel`].
/// - `ColorPicker` — Wraps a [`ColorPicker`].
/// - `GUITable` — Wraps a [`GUITable`].
/// - `ImageWidget` — Wraps an [`ImageWidget`].
/// - `SpinBox` — Wraps a [`SpinBox`].
/// - `Switch` — Wraps a [`Switch`].
/// - `Badge` — Wraps a [`Badge`].
#[derive(Debug, Clone)]
pub enum WidgetKind {
    /// Wraps a [`Button`].
    Button(Button),
    /// Wraps a [`Label`].
    Label(Label),
    /// Wraps a [`TextInput`].
    TextInput(TextInput),
    /// Wraps a [`CheckBox`].
    CheckBox(CheckBox),
    /// Wraps a [`Slider`].
    Slider(Slider),
    /// Wraps a [`ProgressBar`].
    ProgressBar(ProgressBar),
    /// Wraps a [`ComboBox`].
    ComboBox(ComboBox),
    /// Wraps a [`ListBox`].
    ListBox(ListBox),
    /// Wraps a [`Panel`].
    Panel(Panel),
    /// Wraps a [`Layout`].
    Layout(Layout),
    /// Wraps a [`ScrollPanel`].
    ScrollPanel(ScrollPanel),
    /// Wraps a [`NinePatch`].
    NinePatch(NinePatch),
    /// Wraps a [`TabBar`].
    TabBar(TabBar),
    /// Wraps a [`Toast`].
    Toast(Toast),
    /// Wraps a [`Separator`].
    Separator(Separator),
    /// Wraps a [`Spacer`].
    Spacer(Spacer),
    /// Wraps a [`TreeView`].
    TreeView(TreeView),
    /// Wraps a [`RadioButton`].
    RadioButton(RadioButton),
    /// Wraps a [`ScrollBar`].
    ScrollBar(ScrollBar),
    /// Wraps a [`GUIWindow`].
    GUIWindow(GUIWindow),
    /// Wraps a [`SplitPanel`].
    SplitPanel(SplitPanel),
    /// Wraps a [`DockPanel`].
    DockPanel(DockPanel),
    /// Wraps a [`Toolbar`].
    Toolbar(Toolbar),
    /// Wraps a [`MenuBar`].
    MenuBar(MenuBar),
    /// Wraps a [`MenuItem`].
    MenuItem(MenuItem),
    /// Wraps a [`Dialog`].
    Dialog(Dialog),
    /// Wraps a [`StatusBar`].
    StatusBar(StatusBar),
    /// Wraps a [`Accordion`].
    Accordion(Accordion),
    /// Wraps a [`TooltipPanel`].
    TooltipPanel(TooltipPanel),
    /// Wraps a [`ColorPicker`].
    ColorPicker(ColorPicker),
    /// Wraps a [`GUITable`].
    GUITable(GUITable),
    /// Wraps an [`ImageWidget`].
    ImageWidget(ImageWidget),
    /// Wraps a [`SpinBox`].
    SpinBox(SpinBox),
    /// Wraps a [`Switch`].
    Switch(Switch),
    /// Wraps a [`Badge`].
    Badge(Badge),
    /// Wraps a [`CustomWidget`].
    Custom(CustomWidget),
}

impl WidgetKind {
    /// Return a reference to the shared [`WidgetBase`] inside this variant.
    ///
    /// # Returns
    /// `&WidgetBase`.
    pub fn base(&self) -> &WidgetBase {
        match self {
            Self::Button(w) => &w.base,
            Self::Label(w) => &w.base,
            Self::TextInput(w) => &w.base,
            Self::CheckBox(w) => &w.base,
            Self::Slider(w) => &w.base,
            Self::ProgressBar(w) => &w.base,
            Self::ComboBox(w) => &w.base,
            Self::ListBox(w) => &w.base,
            Self::Panel(w) => &w.base,
            Self::Layout(w) => &w.base,
            Self::ScrollPanel(w) => &w.base,
            Self::NinePatch(w) => &w.base,
            Self::TabBar(w) => &w.base,
            Self::Toast(w) => &w.base,
            Self::Separator(w) => &w.base,
            Self::Spacer(w) => &w.base,
            Self::TreeView(w) => &w.base,
            Self::RadioButton(w) => &w.base,
            Self::ScrollBar(w) => &w.base,
            Self::GUIWindow(w) => &w.base,
            Self::SplitPanel(w) => &w.base,
            Self::DockPanel(w) => &w.base,
            Self::Toolbar(w) => &w.base,
            Self::MenuBar(w) => &w.base,
            Self::MenuItem(w) => &w.base,
            Self::Dialog(w) => &w.base,
            Self::StatusBar(w) => &w.base,
            Self::Accordion(w) => &w.base,
            Self::TooltipPanel(w) => &w.base,
            Self::ColorPicker(w) => &w.base,
            Self::GUITable(w) => &w.base,
            Self::ImageWidget(w) => &w.base,
            Self::SpinBox(w) => &w.base,
            Self::Switch(w) => &w.base,
            Self::Badge(w) => &w.base,
            Self::Custom(w) => &w.base,
        }
    }

    /// Return a mutable reference to the shared [`WidgetBase`].
    ///
    /// # Returns
    /// `&mut WidgetBase`.
    pub fn base_mut(&mut self) -> &mut WidgetBase {
        match self {
            Self::Button(w) => &mut w.base,
            Self::Label(w) => &mut w.base,
            Self::TextInput(w) => &mut w.base,
            Self::CheckBox(w) => &mut w.base,
            Self::Slider(w) => &mut w.base,
            Self::ProgressBar(w) => &mut w.base,
            Self::ComboBox(w) => &mut w.base,
            Self::ListBox(w) => &mut w.base,
            Self::Panel(w) => &mut w.base,
            Self::Layout(w) => &mut w.base,
            Self::ScrollPanel(w) => &mut w.base,
            Self::NinePatch(w) => &mut w.base,
            Self::TabBar(w) => &mut w.base,
            Self::Toast(w) => &mut w.base,
            Self::Separator(w) => &mut w.base,
            Self::Spacer(w) => &mut w.base,
            Self::TreeView(w) => &mut w.base,
            Self::RadioButton(w) => &mut w.base,
            Self::ScrollBar(w) => &mut w.base,
            Self::GUIWindow(w) => &mut w.base,
            Self::SplitPanel(w) => &mut w.base,
            Self::DockPanel(w) => &mut w.base,
            Self::Toolbar(w) => &mut w.base,
            Self::MenuBar(w) => &mut w.base,
            Self::MenuItem(w) => &mut w.base,
            Self::Dialog(w) => &mut w.base,
            Self::StatusBar(w) => &mut w.base,
            Self::Accordion(w) => &mut w.base,
            Self::TooltipPanel(w) => &mut w.base,
            Self::ColorPicker(w) => &mut w.base,
            Self::GUITable(w) => &mut w.base,
            Self::ImageWidget(w) => &mut w.base,
            Self::SpinBox(w) => &mut w.base,
            Self::Switch(w) => &mut w.base,
            Self::Badge(w) => &mut w.base,
            Self::Custom(w) => &mut w.base,
        }
    }

    /// Return the child indices if this widget is a container type.
    ///
    /// # Returns
    /// `Option<&Vec<usize>>`.
    pub fn children(&self) -> Option<&Vec<usize>> {
        match self {
            Self::Panel(p) => Some(&p.children),
            Self::Layout(l) => Some(&l.children),
            Self::ScrollPanel(s) => Some(&s.children),
            Self::GUIWindow(w) => Some(&w.children),
            Self::Toolbar(w) => Some(&w.children),
            _ => None,
        }
    }

    /// Return mutable child indices if this widget is a container type.
    ///
    /// # Returns
    /// `Option<&mut Vec<usize>>`.
    pub fn children_mut(&mut self) -> Option<&mut Vec<usize>> {
        match self {
            Self::Panel(p) => Some(&mut p.children),
            Self::Layout(l) => Some(&mut l.children),
            Self::ScrollPanel(s) => Some(&mut s.children),
            Self::GUIWindow(w) => Some(&mut w.children),
            Self::Toolbar(w) => Some(&mut w.children),
            _ => None,
        }
    }
}

/// Central GUI coordinator: widget pool, focus, toasts, and theme.
///
/// The context owns a flat `Vec<WidgetKind>` indexed by widget ID.  Index `0`
/// is always the invisible root `Panel`.  New widgets are appended with
/// `add_*` methods that return the widget's index.
///
/// Focus is tracked by `focused_widget: Option<usize>`.  The toast queue is
/// a separate `Vec<Toast>` that is updated and drained by `update(dt)`.
///
/// # Fields
/// - `widgets` — `Vec<WidgetKind>`. Flat pool of all widgets.
/// - `focused_widget` — `Option<usize>`. Index of the focused widget.
/// - `toasts` — `Vec<Toast>`. Active toast notifications.
/// - `theme` — `Option<Theme>`. Active theme.
/// - `pending_events` — `Vec<GuiEvent>`. Interaction events queued since the last drain.
/// - `dirty` — `bool`. Set to `true` on any structural change; cleared by `flush_cache()`.
/// - `viewport_w` — `f32`. Viewport width (set via `set_viewport`).
/// - `viewport_h` — `f32`. Viewport height (set via `set_viewport`).
#[derive(Debug, Clone)]
pub struct GuiContext {
    /// Flat pool of all widgets.
    pub widgets: Vec<WidgetKind>,
    /// Index of the focused widget.
    pub focused_widget: Option<usize>,
    /// Active toast notifications.
    pub toasts: Vec<Toast>,
    /// Active theme.
    pub theme: Option<Theme>,
    /// Interaction events queued since the last drain.
    pub pending_events: Vec<GuiEvent>,
    /// Set to `true` on any structural change; cleared by `flush_cache()`.
    pub dirty: bool,
    /// Viewport width in pixels.
    pub viewport_w: f32,
    /// Viewport height in pixels.
    pub viewport_h: f32,
    /// Widget currently being dragged between containers.
    pub drag_widget: Option<usize>,
    /// Last render signature used for lightweight diff invalidation.
    pub last_render_signature: u64,
}

impl GuiContext {
    /// Create a new GUI context with an invisible root panel at index 0.
    ///
    /// # Returns
    /// `GuiContext`.
    pub fn new() -> Self {
        log_msg!(debug, GU01_CTX_INIT);
        let root = Panel::new();
        Self {
            widgets: vec![WidgetKind::Panel(root)],
            focused_widget: None,
            toasts: Vec::new(),
            theme: Some(crate::ui::theme::Theme::default_dark()),
            pending_events: Vec::new(),
            dirty: true,
            viewport_w: 0.0,
            viewport_h: 0.0,
            drag_widget: None,
            last_render_signature: 0,
        }
    }

    /// Return the number of widgets in the pool (including the root).
    ///
    /// # Returns
    /// `usize`.
    pub fn widget_count(&self) -> usize {
        self.widgets.len()
    }

    /// Drain and return all pending interaction events accumulated since the last call.
    ///
    /// Called by the Lua bridge each frame to dispatch registered callbacks.
    ///
    /// # Returns
    /// `Vec<GuiEvent>`.
    pub fn drain_events(&mut self) -> Vec<GuiEvent> {
        self.pending_events.drain(..).collect()
    }

    // ── Layout ────────────────────────────────────────────────────────

    /// Walk the widget tree and write `computed_rect` on each widget.
    ///
    /// Top-level widgets use their declared `(x, y, width, height)`.
    /// Children are offset by their parent's `computed_rect` origin.
    /// A zero width or height inherits the parent dimension (auto-sizing).
    pub fn run_layout_pass(&mut self) {
        let root_rect = crate::math::Rect::new(0.0, 0.0, 0.0, 0.0);
        let root_children: Vec<usize> = self
            .widgets
            .first()
            .and_then(|w| w.children())
            .cloned()
            .unwrap_or_default();
        for &child_idx in &root_children {
            self.layout_widget(child_idx, &root_rect);
        }
    }

    /// Recursively compute layout for a single widget and its children.
    fn layout_widget(&mut self, idx: usize, parent_rect: &crate::math::Rect) {
        if idx >= self.widgets.len() {
            return;
        }

        // Compute this widget's screen-space rect
        let (x, y, mut w, mut h) = {
            let base = self.widgets[idx].base();
            (base.x, base.y, base.width, base.height)
        };
        if w == 0.0 && parent_rect.width > 0.0 {
            w = parent_rect.width;
        }
        if h == 0.0 && parent_rect.height > 0.0 {
            h = parent_rect.height;
        }
        let computed = crate::math::Rect::new(parent_rect.x + x, parent_rect.y + y, w, h);
        {
            let base = self.widgets[idx].base_mut();
            base.computed_rect = computed;
            base.is_visible = true;
        }

        // Recurse into children
        let child_indices: Vec<usize> = self.widgets[idx].children().cloned().unwrap_or_default();
        for child_idx in child_indices {
            self.layout_widget(child_idx, &computed);
        }
    }

    // ── Widget constructors ───────────────────────────────────────────

    /// Add a button and return its pool index.
    ///
    /// # Parameters
    /// - `text` — `impl Into<String>`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_button(&mut self, text: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Button(Button::new(text)));
        idx
    }

    /// Add a label and return its pool index.
    ///
    /// # Parameters
    /// - `text` — `impl Into<String>`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_label(&mut self, text: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Label(Label::new(text)));
        idx
    }

    /// Add a text input and return its pool index.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_text_input(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::TextInput(TextInput::new()));
        idx
    }

    /// Add a check box and return its pool index.
    ///
    /// # Parameters
    /// - `text` — `impl Into<String>`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_checkbox(&mut self, text: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::CheckBox(CheckBox::new(text)));
        idx
    }

    /// Add a slider and return its pool index.
    ///
    /// # Parameters
    /// - `min` — `f64`.
    /// - `max` — `f64`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_slider(&mut self, min: f64, max: f64) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Slider(Slider::new(min, max)));
        idx
    }

    /// Add a progress bar and return its pool index.
    ///
    /// # Parameters
    /// - `min` — `f64`.
    /// - `max` — `f64`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_progress_bar(&mut self, min: f64, max: f64) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::ProgressBar(ProgressBar::new(min, max)));
        idx
    }

    /// Add a combo box and return its pool index.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_combo_box(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::ComboBox(ComboBox::new()));
        idx
    }

    /// Add a list box and return its pool index.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_list_box(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::ListBox(ListBox::new()));
        idx
    }

    /// Add a panel and return its pool index.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_panel(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Panel(Panel::new()));
        idx
    }

    /// Add a layout and return its pool index.
    ///
    /// # Parameters
    /// - `direction` — `LayoutDirection`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_layout(&mut self, direction: super::LayoutDirection) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::Layout(Layout::new(direction)));
        idx
    }

    /// Add a scroll panel and return its pool index.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_scroll_panel(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::ScrollPanel(ScrollPanel::new()));
        idx
    }

    /// Add a nine-patch and return its pool index.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_nine_patch(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::NinePatch(NinePatch::new()));
        idx
    }

    /// Add a tab bar and return its pool index.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_tab_bar(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::TabBar(TabBar::new()));
        idx
    }

    /// Add a separator and return its pool index.
    ///
    /// # Parameters
    /// - `vertical` — `bool`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_separator(&mut self, vertical: bool) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::Separator(Separator::new(vertical)));
        idx
    }

    /// Add a spacer and return its pool index.
    ///
    /// # Parameters
    /// - `width` — `f32`.
    /// - `height` — `f32`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_spacer(&mut self, width: f32, height: f32) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::Spacer(Spacer::new(width, height)));
        idx
    }

    /// Add a tree view and return its pool index.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_tree_view(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::TreeView(TreeView::new()));
        idx
    }

    /// Add a radio button and return its pool index.
    ///
    /// # Parameters
    /// - `text` — `impl Into<String>`.
    /// - `group` — `impl Into<String>`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_radio_button(&mut self, text: impl Into<String>, group: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::RadioButton(RadioButton::new(text, group)));
        idx
    }

    /// Add a scroll bar and return its pool index.
    ///
    /// # Parameters
    /// - `vertical` — `bool`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_scroll_bar(&mut self, vertical: bool) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::ScrollBar(ScrollBar::new(vertical)));
        idx
    }

    /// Add a GUI window and return its pool index.
    ///
    /// # Parameters
    /// - `title` — `impl Into<String>`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_gui_window(&mut self, title: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::GUIWindow(GUIWindow::new(title)));
        idx
    }

    /// Add a split panel and return its pool index.
    ///
    /// # Parameters
    /// - `orientation` — `impl Into<String>`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_split_panel(&mut self, orientation: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::SplitPanel(SplitPanel::new(orientation)));
        idx
    }

    /// Add a dock panel and return its pool index.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_dock_panel(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::DockPanel(DockPanel::new()));
        idx
    }

    /// Add a toolbar and return its pool index.
    ///
    /// # Parameters
    /// - `orientation` — `impl Into<String>`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_toolbar(&mut self, orientation: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::Toolbar(Toolbar::new(orientation)));
        idx
    }

    /// Add a menu bar and return its pool index.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_menu_bar(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::MenuBar(MenuBar::new()));
        idx
    }

    /// Add a menu item and return its pool index.
    ///
    /// # Parameters
    /// - `text` — `impl Into<String>`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_menu_item(&mut self, text: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::MenuItem(MenuItem::new(text)));
        idx
    }

    /// Add a dialog and return its pool index.
    ///
    /// # Parameters
    /// - `title` — `impl Into<String>`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_dialog(&mut self, title: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Dialog(Dialog::new(title)));
        idx
    }

    /// Add a status bar and return its pool index.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_status_bar(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::StatusBar(StatusBar::new()));
        idx
    }

    /// Add an accordion and return its pool index.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_accordion(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Accordion(Accordion::new()));
        idx
    }

    /// Add a tooltip panel and return its pool index.
    ///
    /// # Parameters
    /// - `text` — `impl Into<String>`.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_tooltip_panel(&mut self, text: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::TooltipPanel(TooltipPanel::new(text)));
        idx
    }

    /// Add a color picker and return its pool index.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_color_picker(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::ColorPicker(ColorPicker::new()));
        idx
    }

    /// Add a GUI table and return its pool index.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_gui_table(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::GUITable(GUITable::new()));
        idx
    }

    /// Add an image widget and return its pool index.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_image_widget(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::ImageWidget(ImageWidget::new()));
        self.dirty = true;
        idx
    }

    /// Add a spin box and return its pool index.
    ///
    /// # Parameters
    /// - `min` — `f64`. Minimum value.
    /// - `max` — `f64`. Maximum value.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_spin_box(&mut self, min: f64, max: f64) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::SpinBox(SpinBox::new(min, max)));
        self.dirty = true;
        idx
    }

    /// Add a toggle switch and return its pool index.
    ///
    /// # Parameters
    /// - `on` — `bool`. Initial state.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_switch(&mut self, on: bool) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Switch(Switch::new(on)));
        self.dirty = true;
        idx
    }

    /// Add a badge and return its pool index.
    ///
    /// # Parameters
    /// - `count` — `u32`. Initial badge count.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_badge(&mut self, count: u32) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Badge(Badge::new(count)));
        self.dirty = true;
        idx
    }

    /// Add a custom Lua-driven widget and return its pool index.
    ///
    /// # Returns
    /// `usize`.
    pub fn add_custom_widget(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Custom(CustomWidget::new()));
        self.dirty = true;
        idx
    }

    /// Install the built-in dark theme as the active theme.
    pub fn set_default_theme(&mut self) {
        self.theme = Some(crate::ui::theme::Theme::default_dark());
        self.dirty = true;
    }

    /// Set the logical viewport size (used for anchoring and relative layout).
    ///
    /// # Parameters
    /// - `width` — `f32`. Viewport width in pixels.
    /// - `height` — `f32`. Viewport height in pixels.
    pub fn set_viewport(&mut self, width: f32, height: f32) {
        self.viewport_w = width;
        self.viewport_h = height;
        self.dirty = true;
    }

    /// Mark the render cache as clean and return `true` if the context was dirty.
    ///
    /// Call this after rebuilding the GPU command list so that the renderer
    /// can skip an expensive rebuild on frames where nothing changed.
    ///
    /// # Returns
    /// `bool` — `true` if the cache was dirty before this call.
    pub fn flush_cache(&mut self) -> bool {
        let signature = self.compute_render_signature();
        let was_dirty = self.dirty || signature != self.last_render_signature;
        self.dirty = false;
        self.last_render_signature = signature;
        was_dirty
    }

    /// Start dragging a widget to be dropped into another container.
    pub fn begin_drag(&mut self, widget_idx: usize) -> bool {
        if widget_idx == 0 || widget_idx >= self.widgets.len() {
            return false;
        }
        self.drag_widget = Some(widget_idx);
        true
    }

    /// Return the widget currently tracked as active drag payload.
    pub fn active_drag(&self) -> Option<usize> {
        self.drag_widget
    }

    /// Cancel active drag and return the previously dragged widget index.
    pub fn end_drag(&mut self) -> Option<usize> {
        self.drag_widget.take()
    }

    /// Drop the currently dragged widget onto a container target.
    pub fn drop_on(&mut self, target_idx: usize) -> bool {
        let Some(drag_idx) = self.drag_widget else {
            return false;
        };
        if target_idx >= self.widgets.len() || drag_idx == target_idx {
            return false;
        }
        if !self.widgets[target_idx].children().is_some() {
            return false;
        }
        if self.contains_descendant(drag_idx, target_idx) {
            return false;
        }

        self.detach_from_all_parents(drag_idx);
        if !self.add_child(target_idx, drag_idx) {
            return false;
        }
        self.drag_widget = None;
        self.dirty = true;
        true
    }

    fn detach_from_all_parents(&mut self, child_idx: usize) {
        for idx in 0..self.widgets.len() {
            if let Some(children) = self.widgets[idx].children_mut() {
                children.retain(|c| *c != child_idx);
            }
        }
    }

    fn contains_descendant(&self, root_idx: usize, needle_idx: usize) -> bool {
        if root_idx >= self.widgets.len() {
            return false;
        }
        if let Some(children) = self.widgets[root_idx].children() {
            for child in children {
                if *child == needle_idx || self.contains_descendant(*child, needle_idx) {
                    return true;
                }
            }
        }
        false
    }

    /// Add an alpha transition to a widget.
    pub fn animate_alpha(
        &mut self,
        widget_idx: usize,
        to_alpha: f32,
        duration: f32,
        hide_on_complete: bool,
    ) -> bool {
        if widget_idx >= self.widgets.len() {
            return false;
        }
        let base = self.widgets[widget_idx].base_mut();
        base.visible = true;
        base.transitions.push(WidgetTransition::alpha(
            base.alpha,
            to_alpha.clamp(0.0, 1.0),
            duration,
            hide_on_complete,
        ));
        self.dirty = true;
        true
    }

    /// Add a position transition to a widget.
    pub fn animate_position(
        &mut self,
        widget_idx: usize,
        to_x: f32,
        to_y: f32,
        duration: f32,
    ) -> bool {
        if widget_idx >= self.widgets.len() {
            return false;
        }
        let base = self.widgets[widget_idx].base_mut();
        base.transitions
            .push(WidgetTransition::position(base.x, base.y, to_x, to_y, duration));
        self.dirty = true;
        true
    }

    /// Cancel all active transitions for a widget.
    pub fn cancel_animations(&mut self, widget_idx: usize) -> bool {
        if widget_idx >= self.widgets.len() {
            return false;
        }
        self.widgets[widget_idx].base_mut().transitions.clear();
        self.dirty = true;
        true
    }

    /// Return whether a widget currently has active transitions.
    pub fn is_animating(&self, widget_idx: usize) -> bool {
        self.widgets
            .get(widget_idx)
            .is_some_and(|w| !w.base().transitions.is_empty())
    }

    /// Apply model values to bound widgets.
    pub fn update_bindings(&mut self, values: &HashMap<String, UiBindingValue>) -> usize {
        let mut changed = 0usize;
        for w in &mut self.widgets {
            let Some(key) = w.base().bind_key.clone() else {
                continue;
            };
            let Some(value) = values.get(&key) else {
                continue;
            };
            match value {
                UiBindingValue::Number(n) => match w {
                    WidgetKind::Slider(sl) => {
                        if (sl.value - *n).abs() > f64::EPSILON {
                            sl.value = *n;
                            changed += 1;
                        }
                    }
                    WidgetKind::ProgressBar(pb) => {
                        if (pb.value - *n).abs() > f64::EPSILON {
                            pb.value = *n;
                            changed += 1;
                        }
                    }
                    WidgetKind::SpinBox(sb) => {
                        if (sb.value - *n).abs() > f64::EPSILON {
                            sb.value = *n;
                            changed += 1;
                        }
                    }
                    WidgetKind::Badge(b) => {
                        let next = if *n < 0.0 { 0 } else { *n as u32 };
                        if b.count != next {
                            b.count = next;
                            changed += 1;
                        }
                    }
                    _ => {}
                },
                UiBindingValue::Text(t) => match w {
                    WidgetKind::Label(lbl) => {
                        if lbl.text != *t {
                            lbl.text = t.clone();
                            changed += 1;
                        }
                    }
                    WidgetKind::Button(btn) => {
                        if btn.text != *t {
                            btn.text = t.clone();
                            changed += 1;
                        }
                    }
                    WidgetKind::TextInput(input) => {
                        if input.text != *t {
                            input.text = t.clone();
                            input.cursor_pos = input.text.len();
                            changed += 1;
                        }
                    }
                    WidgetKind::MenuItem(item) => {
                        if item.text != *t {
                            item.text = t.clone();
                            changed += 1;
                        }
                    }
                    _ => {}
                },
                UiBindingValue::Bool(v) => match w {
                    WidgetKind::CheckBox(cb) => {
                        if cb.checked != *v {
                            cb.checked = *v;
                            changed += 1;
                        }
                    }
                    WidgetKind::Switch(sw) => {
                        if sw.on != *v {
                            sw.on = *v;
                            changed += 1;
                        }
                    }
                    _ => {
                        if w.base().visible != *v {
                            w.base_mut().visible = *v;
                            changed += 1;
                        }
                    }
                },
            }
        }
        if changed > 0 {
            self.dirty = true;
        }
        changed
    }

    fn compute_render_signature(&self) -> u64 {
        let mut hash = 1469598103934665603u64;
        for (idx, w) in self.widgets.iter().enumerate() {
            let b = w.base();
            hash ^= idx as u64;
            hash = hash.wrapping_mul(1099511628211);
            hash ^= (b.x.to_bits() as u64) ^ ((b.y.to_bits() as u64) << 1);
            hash = hash.wrapping_mul(1099511628211);
            hash ^= (b.width.to_bits() as u64)
                ^ ((b.height.to_bits() as u64) << 1)
                ^ ((b.alpha.to_bits() as u64) << 2);
            hash = hash.wrapping_mul(1099511628211);
            hash ^= (b.visible as u64) | ((b.enabled as u64) << 1) | ((b.state as u64) << 2);
            hash = hash.wrapping_mul(1099511628211);
            hash ^= b.id.len() as u64;
            hash = hash.wrapping_mul(1099511628211);
            if let Some(children) = w.children() {
                hash ^= children.len() as u64;
                hash = hash.wrapping_mul(1099511628211);
                for child in children {
                    hash ^= *child as u64;
                    hash = hash.wrapping_mul(1099511628211);
                }
            }
        }
        hash
    }

    // ── Child management ──────────────────────────────────────────────

    /// Add `child_idx` as a child of the container at `parent_idx`.
    ///
    /// Returns `false` if the parent is not a container or indices are invalid.
    ///
    /// # Parameters
    /// - `parent_idx` — `usize`.
    /// - `child_idx` — `usize`.
    ///
    /// # Returns
    /// `bool`.
    pub fn add_child(&mut self, parent_idx: usize, child_idx: usize) -> bool {
        log_msg!(debug, GU02_WIDGET_ADD);
        if parent_idx >= self.widgets.len() || child_idx >= self.widgets.len() {
            return false;
        }
        if let Some(children) = self.widgets[parent_idx].children_mut() {
            if !children.contains(&child_idx) {
                children.push(child_idx);
            }
            self.dirty = true;
            true
        } else {
            false
        }
    }

    /// Remove `child_idx` from the container at `parent_idx`.
    ///
    /// # Parameters
    /// - `parent_idx` — `usize`.
    /// - `child_idx` — `usize`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_child(&mut self, parent_idx: usize, child_idx: usize) -> bool {
        if parent_idx >= self.widgets.len() {
            return false;
        }
        if let Some(children) = self.widgets[parent_idx].children_mut() {
            if let Some(pos) = children.iter().position(|&c| c == child_idx) {
                children.remove(pos);
                self.dirty = true;
                return true;
            }
        }
        false
    }

    /// Count the children of a container widget.
    ///
    /// # Parameters
    /// - `widget_idx` — `usize`.
    ///
    /// # Returns
    /// `usize`.
    pub fn child_count(&self, widget_idx: usize) -> usize {
        self.widgets
            .get(widget_idx)
            .and_then(|w| w.children())
            .map_or(0, |c| c.len())
    }

    // ── Focus ─────────────────────────────────────────────────────────

    /// Set keyboard focus to the given widget, clearing focus from the
    /// previous widget.
    ///
    /// # Parameters
    /// - `widget_idx` — `Option<usize>`. `None` to clear focus.
    pub fn set_focus(&mut self, widget_idx: Option<usize>) {
        // Clear previous
        if let Some(prev) = self.focused_widget {
            if let Some(w) = self.widgets.get_mut(prev) {
                let base = w.base_mut();
                if base.state == WidgetState::Focused {
                    base.state = WidgetState::Normal;
                }
            }
        }
        // Set new
        if let Some(idx) = widget_idx {
            if let Some(w) = self.widgets.get_mut(idx) {
                w.base_mut().state = WidgetState::Focused;
            }
        }
        self.focused_widget = widget_idx;
    }

    /// Move focus to the next focusable widget (tab order by pool index).
    pub fn focus_next(&mut self) {
        let start = self.focused_widget.map_or(0, |i| i + 1);
        for i in start..self.widgets.len() {
            let base = self.widgets[i].base();
            if base.visible && base.enabled {
                self.set_focus(Some(i));
                return;
            }
        }
        // Wrap around
        for i in 1..start.min(self.widgets.len()) {
            let base = self.widgets[i].base();
            if base.visible && base.enabled {
                self.set_focus(Some(i));
                return;
            }
        }
    }

    /// Move focus to the previous focusable widget.
    pub fn focus_prev(&mut self) {
        let start = self.focused_widget.unwrap_or(self.widgets.len());
        if start > 1 {
            for i in (1..start).rev() {
                let base = self.widgets[i].base();
                if base.visible && base.enabled {
                    self.set_focus(Some(i));
                    return;
                }
            }
        }
        // Wrap around
        for i in (1..self.widgets.len()).rev() {
            let base = self.widgets[i].base();
            if base.visible && base.enabled {
                self.set_focus(Some(i));
                return;
            }
        }
    }

    // ── Toasts ────────────────────────────────────────────────────────

    /// Queue a toast notification for display.
    ///
    /// # Parameters
    /// - `toast` — `Toast`.
    pub fn add_toast(&mut self, toast: Toast) {
        self.toasts.push(toast);
    }

    /// Return the number of active (non-expired) toast notifications.
    ///
    /// # Returns
    /// `usize`.
    pub fn toast_count(&self) -> usize {
        self.toasts.len()
    }

    // ── Update ────────────────────────────────────────────────────────

    /// Advance toast timers and remove expired toasts.
    ///
    /// # Parameters
    /// - `dt` — `f32`. Delta time in seconds.
    pub fn update(&mut self, dt: f32) {
        for toast in &mut self.toasts {
            toast.update(dt);
        }
        self.toasts.retain(|t| !t.is_expired());

        let mut any_changed = false;
        for widget in &mut self.widgets {
            let base = widget.base_mut();
            if base.transitions.is_empty() {
                continue;
            }

            let mut kept = Vec::with_capacity(base.transitions.len());
            for mut transition in base.transitions.drain(..) {
                transition.elapsed = (transition.elapsed + dt).max(0.0);
                let t = if transition.duration <= 0.0 {
                    1.0
                } else {
                    (transition.elapsed / transition.duration).clamp(0.0, 1.0)
                };
                match transition.kind {
                    crate::ui::widget::WidgetTransitionKind::Alpha { from, to } => {
                        base.alpha = (from + (to - from) * t).clamp(0.0, 1.0);
                        base.visible = true;
                        if t >= 1.0 && transition.hide_on_complete && to <= 0.0 {
                            base.visible = false;
                        }
                    }
                    crate::ui::widget::WidgetTransitionKind::Position {
                        from_x,
                        from_y,
                        to_x,
                        to_y,
                    } => {
                        base.x = from_x + (to_x - from_x) * t;
                        base.y = from_y + (to_y - from_y) * t;
                    }
                }
                any_changed = true;
                if t < 1.0 {
                    kept.push(transition);
                }
            }
            base.transitions = kept;
        }
        if any_changed {
            self.dirty = true;
        }
    }

    // ── Lookup ────────────────────────────────────────────────────────

    /// Recursively search for a widget by its `id` string, starting from
    /// `start_idx`.
    ///
    /// # Parameters
    /// - `start_idx` — `usize`. Widget to start searching from.
    /// - `id` — `&str`. Target `id`.
    ///
    /// # Returns
    /// `Option<usize>` — widget pool index.
    pub fn find_by_id(&self, start_idx: usize, id: &str) -> Option<usize> {
        if start_idx >= self.widgets.len() {
            return None;
        }
        if self.widgets[start_idx].base().id == id {
            return Some(start_idx);
        }
        if let Some(children) = self.widgets[start_idx].children() {
            for &child_idx in children {
                if let Some(found) = self.find_by_id(child_idx, id) {
                    return Some(found);
                }
            }
        }
        None
    }

    // ── Input routing ─────────────────────────────────────────────────

    /// Forward a mouse press event to the widget tree.
    ///
    /// Hit-tests all visible, enabled widgets and sets focus + state
    /// accordingly.
    ///
    /// # Parameters
    /// - `x` — `f32`. Mouse X.
    /// - `y` — `f32`. Mouse Y.
    /// - `_button` — `u32`. Mouse button (1=left, 2=right, 3=middle).
    ///
    /// # Returns
    /// `bool` — `true` if any widget consumed the event.
    pub fn mouse_pressed(&mut self, x: f32, y: f32, _button: u32) -> bool {
        let mut hit = None;
        // Iterate in reverse z-order (last drawn = on top)
        for i in (1..self.widgets.len()).rev() {
            let base = self.widgets[i].base();
            if base.visible && base.enabled && base.contains_point(x, y) {
                hit = Some(i);
                break;
            }
        }
        if let Some(idx) = hit {
            self.set_focus(Some(idx));
            self.widgets[idx].base_mut().state = WidgetState::Pressed;

            // Toggle checkbox and emit Change event
            if let WidgetKind::CheckBox(cb) = &mut self.widgets[idx] {
                cb.checked = !cb.checked;
                self.pending_events.push(GuiEvent::Change(idx));
            }

            // Toggle switch and emit Change event
            if let WidgetKind::Switch(sw) = &mut self.widgets[idx] {
                sw.toggle();
                self.pending_events.push(GuiEvent::Change(idx));
                self.dirty = true;
            }

            true
        } else {
            self.set_focus(None);
            false
        }
    }

    /// Forward a mouse release event to the widget tree.
    ///
    /// # Parameters
    /// - `x` — `f32`. Mouse X.
    /// - `y` — `f32`. Mouse Y.
    /// - `_button` — `u32`. Mouse button.
    ///
    /// # Returns
    /// `bool` — `true` if any widget consumed the event.
    pub fn mouse_released(&mut self, x: f32, y: f32, _button: u32) -> bool {
        let mut consumed = false;
        for i in 1..self.widgets.len() {
            let base = self.widgets[i].base();
            if base.state == WidgetState::Pressed {
                let inside = base.contains_point(x, y);
                if inside {
                    // Emit Click for activatable widget types
                    let is_clickable = matches!(
                        self.widgets[i],
                        WidgetKind::Button(_)
                            | WidgetKind::RadioButton(_)
                            | WidgetKind::MenuItem(_)
                    );
                    if is_clickable {
                        self.pending_events.push(GuiEvent::Click(i));
                    }
                }
                let new_state = if inside {
                    WidgetState::Hovered
                } else {
                    WidgetState::Normal
                };
                self.widgets[i].base_mut().state = new_state;
                consumed = true;
            }
        }
        consumed
    }

    /// Forward a mouse move event to update hover states.
    ///
    /// # Parameters
    /// - `x` — `f32`. Mouse X.
    /// - `y` — `f32`. Mouse Y.
    ///
    /// # Returns
    /// `bool` — `true` if any widget's state changed.
    pub fn mouse_moved(&mut self, x: f32, y: f32) -> bool {
        let mut changed = false;
        for i in 1..self.widgets.len() {
            let base = self.widgets[i].base();
            if !base.visible || !base.enabled {
                continue;
            }
            let inside = base.contains_point(x, y);
            let current = base.state;
            if current == WidgetState::Pressed || current == WidgetState::Disabled {
                continue;
            }
            let new_state = if inside {
                if self.focused_widget == Some(i) {
                    WidgetState::Focused
                } else {
                    WidgetState::Hovered
                }
            } else if self.focused_widget == Some(i) {
                WidgetState::Focused
            } else {
                WidgetState::Normal
            };
            if current != new_state {
                self.widgets[i].base_mut().state = new_state;
                changed = true;
            }
        }
        changed
    }

    /// Forward a key press event.  Handles tab focus navigation and
    /// delegates to focused text inputs.
    ///
    /// # Parameters
    /// - `key` — `&str`. Key name.
    ///
    /// # Returns
    /// `bool` — `true` if consumed.
    pub fn key_pressed(&mut self, key: &str) -> bool {
        match key {
            "tab" => {
                self.focus_next();
                true
            }
            "backspace" => {
                if let Some(idx) = self.focused_widget {
                    if let WidgetKind::TextInput(ti) = &mut self.widgets[idx] {
                        ti.backspace();
                        return true;
                    }
                }
                false
            }
            _ => false,
        }
    }

    /// Forward a text input event to the focused text input widget.
    ///
    /// # Parameters
    /// - `text` — `&str`. Input text.
    ///
    /// # Returns
    /// `bool` — `true` if consumed.
    pub fn text_input(&mut self, text: &str) -> bool {
        if let Some(idx) = self.focused_widget {
            if let WidgetKind::TextInput(ti) = &mut self.widgets[idx] {
                ti.insert_text(text);
                return true;
            }
        }
        false
    }

    /// Forward a mouse wheel event.
    ///
    /// # Parameters
    /// - `_x` — `f32`. Horizontal scroll.
    /// - `y` — `f32`. Vertical scroll.
    ///
    /// # Returns
    /// `bool` — `true` if consumed.
    pub fn wheel_moved(&mut self, _x: f32, y: f32) -> bool {
        if let Some(idx) = self.focused_widget {
            if let WidgetKind::ScrollPanel(sp) = &mut self.widgets[idx] {
                sp.scroll_y -= y * sp.scroll_speed;
                sp.clamp_scroll();
                return true;
            }
        }
        false
    }
}

impl Default for GuiContext {
    fn default() -> Self {
        Self::new()
    }
}
