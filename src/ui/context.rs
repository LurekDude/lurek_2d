//! Runtime UI context for `lurek.ui` — owns the flat widget list, input dispatch, animation ticks,
//! data bindings, drag-and-drop, focus management, and the deferred event queue.
//! `GuiContext` is the single entry point for all widget creation and mutation at runtime.
//! Depends on all widget, control, container, and extra types in the `crate::ui` sub-tree.

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
/// A typed binding value that can be pushed into widgets via `update_bindings`.
#[derive(Debug, Clone, PartialEq)]
pub enum UiBindingValue {
    /// Numeric binding applied to sliders, progress bars, spin boxes, and badges.
    Number(f64),
    /// Text binding applied to labels, buttons, text inputs, and menu items.
    Text(String),
    /// Boolean binding applied to checkboxes, switches, and visibility.
    Bool(bool),
}
/// An event emitted by a widget interaction and drained each frame by the Lua binding.
#[derive(Debug, Clone)]
pub enum GuiEvent {
    /// Primary click or activation of a button, radio button, or menu item at widget `idx`.
    Click(usize),
    /// Value change on a slider, checkbox, switch, or text input at widget `idx`.
    Change(usize),
    /// Window close request for a `GUIWindow` at widget `idx`.
    Close(usize),
    /// Item selection at `(widget_idx, item_idx)` for list boxes or tab bars.
    Select(usize, usize),
}
/// Discriminated union of all concrete widget types stored in the flat `GuiContext::widgets` list.
#[derive(Debug, Clone)]
pub enum WidgetKind {
    /// Push button control.
    Button(Button),
    /// Non-interactive text display.
    Label(Label),
    /// Single-line editable text field.
    TextInput(TextInput),
    /// Toggled checkbox with a label.
    CheckBox(CheckBox),
    /// Draggable value slider.
    Slider(Slider),
    /// Bounded progress indicator.
    ProgressBar(ProgressBar),
    /// Drop-down selection list.
    ComboBox(ComboBox),
    /// Scrollable multi-item selection list.
    ListBox(ListBox),
    /// Box container with optional title.
    Panel(Panel),
    /// Flow/grid layout container.
    Layout(Layout),
    /// Scrollable content panel.
    ScrollPanel(ScrollPanel),
    /// 9-patch scalable border.
    NinePatch(NinePatch),
    /// Horizontal tab navigation bar.
    TabBar(TabBar),
    /// Temporary pop-up message.
    Toast(Toast),
    /// Visual divider line.
    Separator(Separator),
    /// Blank space filler.
    Spacer(Spacer),
    /// Expandable tree of `TreeNode` items.
    TreeView(TreeView),
    /// Mutually exclusive group radio option.
    RadioButton(RadioButton),
    /// Explicit horizontal or vertical scroll bar.
    ScrollBar(ScrollBar),
    /// Floating draggable window.
    GUIWindow(GUIWindow),
    /// Two-pane splitter.
    SplitPanel(SplitPanel),
    /// Multi-region dock container.
    DockPanel(DockPanel),
    /// Icon button strip.
    Toolbar(Toolbar),
    /// Top-level application menu bar.
    MenuBar(MenuBar),
    /// Single entry inside a `MenuBar`.
    MenuItem(MenuItem),
    /// Modal dialog overlay.
    Dialog(Dialog),
    /// Fixed footer status bar.
    StatusBar(StatusBar),
    /// Collapsible section list.
    Accordion(Accordion),
    /// Hover tooltip overlay.
    TooltipPanel(TooltipPanel),
    /// HSVA colour selector.
    ColorPicker(ColorPicker),
    /// Column-row data grid.
    GUITable(GUITable),
    /// Static image display widget.
    ImageWidget(ImageWidget),
    /// Integer or float number field with step buttons.
    SpinBox(SpinBox),
    /// On/off toggle switch.
    Switch(Switch),
    /// Numeric count badge overlay.
    Badge(Badge),
    /// User-defined fully custom widget.
    Custom(CustomWidget),
}
macro_rules! widget_kind_base_match {
    ($value:expr, $map:ident) => {
        match $value {
            WidgetKind::Button(w) => $map!(w),
            WidgetKind::Label(w) => $map!(w),
            WidgetKind::TextInput(w) => $map!(w),
            WidgetKind::CheckBox(w) => $map!(w),
            WidgetKind::Slider(w) => $map!(w),
            WidgetKind::ProgressBar(w) => $map!(w),
            WidgetKind::ComboBox(w) => $map!(w),
            WidgetKind::ListBox(w) => $map!(w),
            WidgetKind::Panel(w) => $map!(w),
            WidgetKind::Layout(w) => $map!(w),
            WidgetKind::ScrollPanel(w) => $map!(w),
            WidgetKind::NinePatch(w) => $map!(w),
            WidgetKind::TabBar(w) => $map!(w),
            WidgetKind::Toast(w) => $map!(w),
            WidgetKind::Separator(w) => $map!(w),
            WidgetKind::Spacer(w) => $map!(w),
            WidgetKind::TreeView(w) => $map!(w),
            WidgetKind::RadioButton(w) => $map!(w),
            WidgetKind::ScrollBar(w) => $map!(w),
            WidgetKind::GUIWindow(w) => $map!(w),
            WidgetKind::SplitPanel(w) => $map!(w),
            WidgetKind::DockPanel(w) => $map!(w),
            WidgetKind::Toolbar(w) => $map!(w),
            WidgetKind::MenuBar(w) => $map!(w),
            WidgetKind::MenuItem(w) => $map!(w),
            WidgetKind::Dialog(w) => $map!(w),
            WidgetKind::StatusBar(w) => $map!(w),
            WidgetKind::Accordion(w) => $map!(w),
            WidgetKind::TooltipPanel(w) => $map!(w),
            WidgetKind::ColorPicker(w) => $map!(w),
            WidgetKind::GUITable(w) => $map!(w),
            WidgetKind::ImageWidget(w) => $map!(w),
            WidgetKind::SpinBox(w) => $map!(w),
            WidgetKind::Switch(w) => $map!(w),
            WidgetKind::Badge(w) => $map!(w),
            WidgetKind::Custom(w) => $map!(w),
        }
    };
}
macro_rules! base_ref {
    ($w:ident) => {
        &$w.base
    };
}
macro_rules! base_mut_ref {
    ($w:ident) => {
        &mut $w.base
    };
}
impl WidgetKind {
    /// Return a shared reference to the common `WidgetBase` of any variant.
    pub fn base(&self) -> &WidgetBase {
        widget_kind_base_match!(self, base_ref)
    }
    /// Return a mutable reference to the common `WidgetBase` of any variant.
    pub fn base_mut(&mut self) -> &mut WidgetBase {
        widget_kind_base_match!(self, base_mut_ref)
    }
    /// Return a shared reference to the child-index list for container variants; `None` for leaf widgets.
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
    /// Return a mutable reference to the child-index list for container variants; `None` for leaf widgets.
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
/// Retained-mode GUI context owning all widgets, focus state, animations, drag state, and event queue.
#[derive(Debug, Clone)]
pub struct GuiContext {
    /// Flat list of all widgets; index 0 is always the invisible root `Panel`.
    pub widgets: Vec<WidgetKind>,
    /// Index of the currently focused widget, if any.
    pub focused_widget: Option<usize>,
    /// Active toast messages rendered as overlays; removed when expired.
    pub toasts: Vec<Toast>,
    /// Current visual theme applied to all widgets during rendering.
    pub theme: Option<Theme>,
    /// Events accumulated this frame, drained by Lua or caller each tick.
    pub pending_events: Vec<GuiEvent>,
    /// Set to `true` whenever any widget state changes; cleared by `flush_cache`.
    pub dirty: bool,
    /// Last-known viewport width used for layout calculations.
    pub viewport_w: f32,
    /// Last-known viewport height used for layout calculations.
    pub viewport_h: f32,
    /// Widget index currently being dragged via the drag-and-drop API, if any.
    pub drag_widget: Option<usize>,
    /// FNV hash of the last rendered widget tree; used to detect changes without full diff.
    pub last_render_signature: u64,
}
impl GuiContext {
    /// Create a new context with a root panel, default dark theme, and dirty=true.
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
    /// Return the total number of widgets including the root panel.
    pub fn widget_count(&self) -> usize {
        self.widgets.len()
    }
    /// Drain and return all pending events accumulated since the last call.
    pub fn drain_events(&mut self) -> Vec<GuiEvent> {
        self.pending_events.drain(..).collect()
    }
    /// Recursively compute and write `computed_rect` and `is_visible` for all widgets from root.
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
    /// Recursively lay out widget `idx` relative to `parent_rect`.
    fn layout_widget(&mut self, idx: usize, parent_rect: &crate::math::Rect) {
        if idx >= self.widgets.len() {
            return;
        }
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
        let child_indices: Vec<usize> = self.widgets[idx].children().cloned().unwrap_or_default();
        for child_idx in child_indices {
            self.layout_widget(child_idx, &computed);
        }
    }
    /// Add a `Button` widget and return its index.
    pub fn add_button(&mut self, text: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Button(Button::new(text)));
        idx
    }
    /// Add a `Label` widget and return its index.
    pub fn add_label(&mut self, text: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Label(Label::new(text)));
        idx
    }
    /// Add a `TextInput` widget and return its index.
    pub fn add_text_input(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::TextInput(TextInput::new()));
        idx
    }
    /// Add a `CheckBox` widget with the given label and return its index.
    pub fn add_checkbox(&mut self, text: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::CheckBox(CheckBox::new(text)));
        idx
    }
    /// Add a `Slider` widget with the given value range and return its index.
    pub fn add_slider(&mut self, min: f64, max: f64) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Slider(Slider::new(min, max)));
        idx
    }
    /// Add a `ProgressBar` widget with the given value range and return its index.
    pub fn add_progress_bar(&mut self, min: f64, max: f64) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::ProgressBar(ProgressBar::new(min, max)));
        idx
    }
    /// Add a `ComboBox` widget and return its index.
    pub fn add_combo_box(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::ComboBox(ComboBox::new()));
        idx
    }
    /// Add a `ListBox` widget and return its index.
    pub fn add_list_box(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::ListBox(ListBox::new()));
        idx
    }
    /// Add a `Panel` container and return its index.
    pub fn add_panel(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Panel(Panel::new()));
        idx
    }
    /// Add a `Layout` container with the given direction and return its index.
    pub fn add_layout(&mut self, direction: super::LayoutDirection) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::Layout(Layout::new(direction)));
        idx
    }
    /// Add a `ScrollPanel` container and return its index.
    pub fn add_scroll_panel(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::ScrollPanel(ScrollPanel::new()));
        idx
    }
    /// Add a `NinePatch` widget and return its index.
    pub fn add_nine_patch(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::NinePatch(NinePatch::new()));
        idx
    }
    /// Add a `TabBar` widget and return its index.
    pub fn add_tab_bar(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::TabBar(TabBar::new()));
        idx
    }
    /// Add a `Separator` widget (horizontal or vertical) and return its index.
    pub fn add_separator(&mut self, vertical: bool) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::Separator(Separator::new(vertical)));
        idx
    }
    /// Add a `Spacer` widget with the given dimensions and return its index.
    pub fn add_spacer(&mut self, width: f32, height: f32) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::Spacer(Spacer::new(width, height)));
        idx
    }
    /// Add a `TreeView` widget and return its index.
    pub fn add_tree_view(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::TreeView(TreeView::new()));
        idx
    }
    /// Add a `RadioButton` with the given label and group name and return its index.
    pub fn add_radio_button(&mut self, text: impl Into<String>, group: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::RadioButton(RadioButton::new(text, group)));
        idx
    }
    /// Add a `ScrollBar` (horizontal or vertical) and return its index.
    pub fn add_scroll_bar(&mut self, vertical: bool) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::ScrollBar(ScrollBar::new(vertical)));
        idx
    }
    /// Add a `GUIWindow` with the given title and return its index.
    pub fn add_gui_window(&mut self, title: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::GUIWindow(GUIWindow::new(title)));
        idx
    }
    /// Add a `SplitPanel` with the given orientation and return its index.
    pub fn add_split_panel(&mut self, orientation: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::SplitPanel(SplitPanel::new(orientation)));
        idx
    }
    /// Add a `DockPanel` container and return its index.
    pub fn add_dock_panel(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::DockPanel(DockPanel::new()));
        idx
    }
    /// Add a `Toolbar` with the given orientation and return its index.
    pub fn add_toolbar(&mut self, orientation: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::Toolbar(Toolbar::new(orientation)));
        idx
    }
    /// Add a `MenuBar` and return its index.
    pub fn add_menu_bar(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::MenuBar(MenuBar::new()));
        idx
    }
    /// Add a `MenuItem` with the given label and return its index.
    pub fn add_menu_item(&mut self, text: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::MenuItem(MenuItem::new(text)));
        idx
    }
    /// Add a `Dialog` with the given title and return its index.
    pub fn add_dialog(&mut self, title: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Dialog(Dialog::new(title)));
        idx
    }
    /// Add a `StatusBar` and return its index.
    pub fn add_status_bar(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::StatusBar(StatusBar::new()));
        idx
    }
    /// Add an `Accordion` container and return its index.
    pub fn add_accordion(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Accordion(Accordion::new()));
        idx
    }
    /// Add a `TooltipPanel` with the given text and return its index.
    pub fn add_tooltip_panel(&mut self, text: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::TooltipPanel(TooltipPanel::new(text)));
        idx
    }
    /// Add a `ColorPicker` widget and return its index.
    pub fn add_color_picker(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::ColorPicker(ColorPicker::new()));
        idx
    }
    /// Add a `GUITable` widget and return its index.
    pub fn add_gui_table(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::GUITable(GUITable::new()));
        idx
    }
    /// Add an `ImageWidget` and return its index; also marks context dirty.
    pub fn add_image_widget(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::ImageWidget(ImageWidget::new()));
        self.dirty = true;
        idx
    }
    /// Add a `SpinBox` with the given value range and return its index; marks dirty.
    pub fn add_spin_box(&mut self, min: f64, max: f64) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::SpinBox(SpinBox::new(min, max)));
        self.dirty = true;
        idx
    }
    /// Add a `Switch` with the given initial on state and return its index; marks dirty.
    pub fn add_switch(&mut self, on: bool) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Switch(Switch::new(on)));
        self.dirty = true;
        idx
    }
    /// Add a `Badge` with the given count and return its index; marks dirty.
    pub fn add_badge(&mut self, count: u32) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Badge(Badge::new(count)));
        self.dirty = true;
        idx
    }
    /// Add a `CustomWidget` and return its index; marks dirty.
    pub fn add_custom_widget(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Custom(CustomWidget::new()));
        self.dirty = true;
        idx
    }
    /// Reset to the built-in dark theme and mark dirty.
    pub fn set_default_theme(&mut self) {
        self.theme = Some(crate::ui::theme::Theme::default_dark());
        self.dirty = true;
    }
    /// Set the viewport size used for root-relative layout; marks dirty.
    pub fn set_viewport(&mut self, width: f32, height: f32) {
        self.viewport_w = width;
        self.viewport_h = height;
        self.dirty = true;
    }
    /// Return `true` if the widget tree has changed since the last call; resets `dirty` and updates the render signature.
    pub fn flush_cache(&mut self) -> bool {
        let signature = self.compute_render_signature();
        let was_dirty = self.dirty || signature != self.last_render_signature;
        self.dirty = false;
        self.last_render_signature = signature;
        was_dirty
    }
    /// Start a drag operation on `widget_idx`; return `false` if the index is invalid or is the root.
    pub fn begin_drag(&mut self, widget_idx: usize) -> bool {
        if widget_idx == 0 || widget_idx >= self.widgets.len() {
            return false;
        }
        self.drag_widget = Some(widget_idx);
        true
    }
    /// Return the widget index currently being dragged, if any.
    pub fn active_drag(&self) -> Option<usize> {
        self.drag_widget
    }
    /// End the current drag operation and return the dragged widget index, if any.
    pub fn end_drag(&mut self) -> Option<usize> {
        self.drag_widget.take()
    }
    /// Drop the active dragged widget onto `target_idx`; returns `false` if target is not a container or would create a cycle.
    pub fn drop_on(&mut self, target_idx: usize) -> bool {
        let Some(drag_idx) = self.drag_widget else {
            return false;
        };
        if target_idx >= self.widgets.len() || drag_idx == target_idx {
            return false;
        }
        if self.widgets[target_idx].children().is_none() {
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
    /// Remove `child_idx` from every container that currently holds it.
    fn detach_from_all_parents(&mut self, child_idx: usize) {
        for idx in 0..self.widgets.len() {
            if let Some(children) = self.widgets[idx].children_mut() {
                children.retain(|c| *c != child_idx);
            }
        }
    }
    /// Return `true` if `needle_idx` is a descendant of `root_idx` in the widget tree.
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
    /// Queue an alpha tween on `widget_idx` from its current alpha to `to_alpha` over `duration` seconds; returns `false` on invalid index.
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
    /// Queue a position tween on `widget_idx` from its current position to `(to_x, to_y)` over `duration` seconds.
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
        base.transitions.push(WidgetTransition::position(
            base.x, base.y, to_x, to_y, duration,
        ));
        self.dirty = true;
        true
    }
    /// Clear all pending transitions on `widget_idx`; returns `false` on invalid index.
    pub fn cancel_animations(&mut self, widget_idx: usize) -> bool {
        if widget_idx >= self.widgets.len() {
            return false;
        }
        self.widgets[widget_idx].base_mut().transitions.clear();
        self.dirty = true;
        true
    }
    /// Return `true` if `widget_idx` has at least one active transition.
    pub fn is_animating(&self, widget_idx: usize) -> bool {
        self.widgets
            .get(widget_idx)
            .is_some_and(|w| !w.base().transitions.is_empty())
    }
    /// Apply `values` to bound widgets; return the number of widgets whose state changed.
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
    /// Compute an FNV-style hash of the visible widget tree for change detection.
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
    /// Append `child_idx` to `parent_idx`'s child list if it is a container; return `false` on invalid indices or non-container.
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
    /// Remove `child_idx` from `parent_idx`'s child list; return `false` if not found.
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
    /// Return the number of direct children of `widget_idx`; 0 for leaf widgets or invalid index.
    pub fn child_count(&self, widget_idx: usize) -> usize {
        self.widgets
            .get(widget_idx)
            .and_then(|w| w.children())
            .map_or(0, |c| c.len())
    }
    /// Move focus to `widget_idx`, updating `WidgetState` for the previous and new focused widgets.
    pub fn set_focus(&mut self, widget_idx: Option<usize>) {
        if let Some(prev) = self.focused_widget {
            if let Some(w) = self.widgets.get_mut(prev) {
                let base = w.base_mut();
                if base.state == WidgetState::Focused {
                    base.state = WidgetState::Normal;
                }
            }
        }
        if let Some(idx) = widget_idx {
            if let Some(w) = self.widgets.get_mut(idx) {
                w.base_mut().state = WidgetState::Focused;
            }
        }
        self.focused_widget = widget_idx;
    }
    /// Advance focus to the next visible enabled widget, wrapping around.
    pub fn focus_next(&mut self) {
        let start = self.focused_widget.map_or(0, |i| i + 1);
        for i in start..self.widgets.len() {
            let base = self.widgets[i].base();
            if base.visible && base.enabled {
                self.set_focus(Some(i));
                return;
            }
        }
        for i in 1..start.min(self.widgets.len()) {
            let base = self.widgets[i].base();
            if base.visible && base.enabled {
                self.set_focus(Some(i));
                return;
            }
        }
    }
    /// Move focus to the previous visible enabled widget, wrapping around.
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
        for i in (1..self.widgets.len()).rev() {
            let base = self.widgets[i].base();
            if base.visible && base.enabled {
                self.set_focus(Some(i));
                return;
            }
        }
    }
    /// Push a toast message into the overlay queue.
    pub fn add_toast(&mut self, toast: Toast) {
        self.toasts.push(toast);
    }
    /// Return the number of active toast messages.
    pub fn toast_count(&self) -> usize {
        self.toasts.len()
    }
    /// Advance toast timers, expire old toasts, and step all active widget transitions by `dt` seconds.
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
    /// Search the subtree rooted at `start_idx` for a widget whose `id` matches; return its index or `None`.
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
    /// Process a mouse button press at `(x, y)`; return `true` if any widget consumed it.
    pub fn mouse_pressed(&mut self, x: f32, y: f32, _button: u32) -> bool {
        let mut hit = None;
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
            if let WidgetKind::CheckBox(cb) = &mut self.widgets[idx] {
                cb.checked = !cb.checked;
                self.pending_events.push(GuiEvent::Change(idx));
            }
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
    /// Process a mouse button release at `(x, y)`; fires `Click` events on clickable widgets.
    pub fn mouse_released(&mut self, x: f32, y: f32, _button: u32) -> bool {
        let mut consumed = false;
        for i in 1..self.widgets.len() {
            let base = self.widgets[i].base();
            if base.state == WidgetState::Pressed {
                let inside = base.contains_point(x, y);
                if inside {
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
    /// Process a mouse move to `(x, y)`; updates `Hovered`/`Normal` states; return `true` on any state change.
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
    /// Process a key press by name; `"tab"` advances focus, `"backspace"` deletes in focused text input.
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
    /// Insert `text` into the focused `TextInput`; return `true` if consumed.
    pub fn text_input(&mut self, text: &str) -> bool {
        if let Some(idx) = self.focused_widget {
            if let WidgetKind::TextInput(ti) = &mut self.widgets[idx] {
                ti.insert_text(text);
                return true;
            }
        }
        false
    }
    /// Scroll the focused `ScrollPanel` by `y` lines; return `true` if consumed.
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
/// Provide a default `GuiContext` via `Self::new()`.
impl Default for GuiContext {
    fn default() -> Self {
        Self::new()
    }
}
