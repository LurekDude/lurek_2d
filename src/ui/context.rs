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
#[derive(Debug, Clone, PartialEq)]
pub enum UiBindingValue {
    Number(f64),
    Text(String),
    Bool(bool),
}
#[derive(Debug, Clone)]
pub enum GuiEvent {
    Click(usize),
    Change(usize),
    Close(usize),
    Select(usize, usize),
}
#[derive(Debug, Clone)]
pub enum WidgetKind {
    Button(Button),
    Label(Label),
    TextInput(TextInput),
    CheckBox(CheckBox),
    Slider(Slider),
    ProgressBar(ProgressBar),
    ComboBox(ComboBox),
    ListBox(ListBox),
    Panel(Panel),
    Layout(Layout),
    ScrollPanel(ScrollPanel),
    NinePatch(NinePatch),
    TabBar(TabBar),
    Toast(Toast),
    Separator(Separator),
    Spacer(Spacer),
    TreeView(TreeView),
    RadioButton(RadioButton),
    ScrollBar(ScrollBar),
    GUIWindow(GUIWindow),
    SplitPanel(SplitPanel),
    DockPanel(DockPanel),
    Toolbar(Toolbar),
    MenuBar(MenuBar),
    MenuItem(MenuItem),
    Dialog(Dialog),
    StatusBar(StatusBar),
    Accordion(Accordion),
    TooltipPanel(TooltipPanel),
    ColorPicker(ColorPicker),
    GUITable(GUITable),
    ImageWidget(ImageWidget),
    SpinBox(SpinBox),
    Switch(Switch),
    Badge(Badge),
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
    pub fn base(&self) -> &WidgetBase {
        widget_kind_base_match!(self, base_ref)
    }
    pub fn base_mut(&mut self) -> &mut WidgetBase {
        widget_kind_base_match!(self, base_mut_ref)
    }
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
#[derive(Debug, Clone)]
pub struct GuiContext {
    pub widgets: Vec<WidgetKind>,
    pub focused_widget: Option<usize>,
    pub toasts: Vec<Toast>,
    pub theme: Option<Theme>,
    pub pending_events: Vec<GuiEvent>,
    pub dirty: bool,
    pub viewport_w: f32,
    pub viewport_h: f32,
    pub drag_widget: Option<usize>,
    pub last_render_signature: u64,
}
impl GuiContext {
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
    pub fn widget_count(&self) -> usize {
        self.widgets.len()
    }
    pub fn drain_events(&mut self) -> Vec<GuiEvent> {
        self.pending_events.drain(..).collect()
    }
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
    pub fn add_button(&mut self, text: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Button(Button::new(text)));
        idx
    }
    pub fn add_label(&mut self, text: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Label(Label::new(text)));
        idx
    }
    pub fn add_text_input(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::TextInput(TextInput::new()));
        idx
    }
    pub fn add_checkbox(&mut self, text: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::CheckBox(CheckBox::new(text)));
        idx
    }
    pub fn add_slider(&mut self, min: f64, max: f64) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Slider(Slider::new(min, max)));
        idx
    }
    pub fn add_progress_bar(&mut self, min: f64, max: f64) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::ProgressBar(ProgressBar::new(min, max)));
        idx
    }
    pub fn add_combo_box(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::ComboBox(ComboBox::new()));
        idx
    }
    pub fn add_list_box(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::ListBox(ListBox::new()));
        idx
    }
    pub fn add_panel(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Panel(Panel::new()));
        idx
    }
    pub fn add_layout(&mut self, direction: super::LayoutDirection) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::Layout(Layout::new(direction)));
        idx
    }
    pub fn add_scroll_panel(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::ScrollPanel(ScrollPanel::new()));
        idx
    }
    pub fn add_nine_patch(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::NinePatch(NinePatch::new()));
        idx
    }
    pub fn add_tab_bar(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::TabBar(TabBar::new()));
        idx
    }
    pub fn add_separator(&mut self, vertical: bool) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::Separator(Separator::new(vertical)));
        idx
    }
    pub fn add_spacer(&mut self, width: f32, height: f32) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::Spacer(Spacer::new(width, height)));
        idx
    }
    pub fn add_tree_view(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::TreeView(TreeView::new()));
        idx
    }
    pub fn add_radio_button(&mut self, text: impl Into<String>, group: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::RadioButton(RadioButton::new(text, group)));
        idx
    }
    pub fn add_scroll_bar(&mut self, vertical: bool) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::ScrollBar(ScrollBar::new(vertical)));
        idx
    }
    pub fn add_gui_window(&mut self, title: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::GUIWindow(GUIWindow::new(title)));
        idx
    }
    pub fn add_split_panel(&mut self, orientation: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::SplitPanel(SplitPanel::new(orientation)));
        idx
    }
    pub fn add_dock_panel(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::DockPanel(DockPanel::new()));
        idx
    }
    pub fn add_toolbar(&mut self, orientation: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::Toolbar(Toolbar::new(orientation)));
        idx
    }
    pub fn add_menu_bar(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::MenuBar(MenuBar::new()));
        idx
    }
    pub fn add_menu_item(&mut self, text: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::MenuItem(MenuItem::new(text)));
        idx
    }
    pub fn add_dialog(&mut self, title: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Dialog(Dialog::new(title)));
        idx
    }
    pub fn add_status_bar(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::StatusBar(StatusBar::new()));
        idx
    }
    pub fn add_accordion(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Accordion(Accordion::new()));
        idx
    }
    pub fn add_tooltip_panel(&mut self, text: impl Into<String>) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::TooltipPanel(TooltipPanel::new(text)));
        idx
    }
    pub fn add_color_picker(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::ColorPicker(ColorPicker::new()));
        idx
    }
    pub fn add_gui_table(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::GUITable(GUITable::new()));
        idx
    }
    pub fn add_image_widget(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::ImageWidget(ImageWidget::new()));
        self.dirty = true;
        idx
    }
    pub fn add_spin_box(&mut self, min: f64, max: f64) -> usize {
        let idx = self.widgets.len();
        self.widgets
            .push(WidgetKind::SpinBox(SpinBox::new(min, max)));
        self.dirty = true;
        idx
    }
    pub fn add_switch(&mut self, on: bool) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Switch(Switch::new(on)));
        self.dirty = true;
        idx
    }
    pub fn add_badge(&mut self, count: u32) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Badge(Badge::new(count)));
        self.dirty = true;
        idx
    }
    pub fn add_custom_widget(&mut self) -> usize {
        let idx = self.widgets.len();
        self.widgets.push(WidgetKind::Custom(CustomWidget::new()));
        self.dirty = true;
        idx
    }
    pub fn set_default_theme(&mut self) {
        self.theme = Some(crate::ui::theme::Theme::default_dark());
        self.dirty = true;
    }
    pub fn set_viewport(&mut self, width: f32, height: f32) {
        self.viewport_w = width;
        self.viewport_h = height;
        self.dirty = true;
    }
    pub fn flush_cache(&mut self) -> bool {
        let signature = self.compute_render_signature();
        let was_dirty = self.dirty || signature != self.last_render_signature;
        self.dirty = false;
        self.last_render_signature = signature;
        was_dirty
    }
    pub fn begin_drag(&mut self, widget_idx: usize) -> bool {
        if widget_idx == 0 || widget_idx >= self.widgets.len() {
            return false;
        }
        self.drag_widget = Some(widget_idx);
        true
    }
    pub fn active_drag(&self) -> Option<usize> {
        self.drag_widget
    }
    pub fn end_drag(&mut self) -> Option<usize> {
        self.drag_widget.take()
    }
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
    pub fn cancel_animations(&mut self, widget_idx: usize) -> bool {
        if widget_idx >= self.widgets.len() {
            return false;
        }
        self.widgets[widget_idx].base_mut().transitions.clear();
        self.dirty = true;
        true
    }
    pub fn is_animating(&self, widget_idx: usize) -> bool {
        self.widgets
            .get(widget_idx)
            .is_some_and(|w| !w.base().transitions.is_empty())
    }
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
    pub fn child_count(&self, widget_idx: usize) -> usize {
        self.widgets
            .get(widget_idx)
            .and_then(|w| w.children())
            .map_or(0, |c| c.len())
    }
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
    pub fn add_toast(&mut self, toast: Toast) {
        self.toasts.push(toast);
    }
    pub fn toast_count(&self) -> usize {
        self.toasts.len()
    }
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
    pub fn text_input(&mut self, text: &str) -> bool {
        if let Some(idx) = self.focused_widget {
            if let WidgetKind::TextInput(ti) = &mut self.widgets[idx] {
                ti.insert_text(text);
                return true;
            }
        }
        false
    }
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
