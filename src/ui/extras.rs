use crate::ui::widget::{WidgetBase, WidgetType};
#[derive(Debug, Clone)]
pub struct Toast {
    pub base: WidgetBase,
    pub message: String,
    pub duration: f32,
    pub elapsed: f32,
}
impl Toast {
    pub fn new(message: impl Into<String>, duration: f32) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Toast),
            message: message.into(),
            duration,
            elapsed: 0.0,
        }
    }
    pub fn progress(&self) -> f32 {
        if self.duration <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration).clamp(0.0, 1.0)
        }
    }
    pub fn is_expired(&self) -> bool {
        self.elapsed >= self.duration
    }
    pub fn update(&mut self, dt: f32) {
        self.elapsed += dt;
    }
}
#[derive(Debug, Clone)]
pub struct Separator {
    pub base: WidgetBase,
    pub vertical: bool,
    pub thickness: f32,
}
impl Separator {
    pub fn new(vertical: bool) -> Self {
        let mut base = WidgetBase::new(WidgetType::Separator);
        if vertical {
            base.width = 2.0;
            base.height = 30.0;
        } else {
            base.width = 100.0;
            base.height = 2.0;
        }
        Self {
            base,
            vertical,
            thickness: 1.0,
        }
    }
}
#[derive(Debug, Clone)]
pub struct Spacer {
    pub base: WidgetBase,
}
impl Spacer {
    pub fn new(width: f32, height: f32) -> Self {
        let mut base = WidgetBase::new(WidgetType::Spacer);
        base.width = width;
        base.height = height;
        Self { base }
    }
}
impl Default for Spacer {
    fn default() -> Self {
        Self::new(0.0, 0.0)
    }
}
#[derive(Debug, Clone)]
pub struct TreeNode {
    pub text: String,
    pub icon: Option<String>,
    pub children: Vec<usize>,
    pub expanded: bool,
    pub parent: Option<usize>,
}
impl TreeNode {
    pub fn new(text: impl Into<String>, parent: Option<usize>) -> Self {
        Self {
            text: text.into(),
            icon: None,
            children: Vec::new(),
            expanded: false,
            parent,
        }
    }
}
#[derive(Debug, Clone)]
pub struct TreeView {
    pub base: WidgetBase,
    pub nodes: Vec<TreeNode>,
    pub root_nodes: Vec<usize>,
    pub selected_node: Option<usize>,
}
impl TreeView {
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::TreeView),
            nodes: Vec::new(),
            root_nodes: Vec::new(),
            selected_node: None,
        }
    }
    pub fn add_node(&mut self, text: impl Into<String>, parent_index: Option<usize>) -> usize {
        let idx = self.nodes.len();
        let node = TreeNode::new(text, parent_index);
        self.nodes.push(node);
        if let Some(pi) = parent_index {
            if pi < self.nodes.len() - 1 {
                self.nodes[pi].children.push(idx);
            }
        } else {
            self.root_nodes.push(idx);
        }
        idx
    }
    pub fn toggle_node(&mut self, index: usize) -> bool {
        if let Some(node) = self.nodes.get_mut(index) {
            node.expanded = !node.expanded;
            true
        } else {
            false
        }
    }
    pub fn node_count(&self) -> usize {
        self.nodes.len()
    }
    pub fn remove_node(&mut self, index: usize) -> bool {
        if index >= self.nodes.len() {
            return false;
        }
        let parent = self.nodes[index].parent;
        if let Some(pi) = parent {
            if pi < self.nodes.len() {
                self.nodes[pi].children.retain(|&c| c != index);
            }
        } else {
            self.root_nodes.retain(|&r| r != index);
        }
        self.nodes.remove(index);
        let remap = |i: usize| -> usize {
            if i > index {
                i - 1
            } else {
                i
            }
        };
        for node in &mut self.nodes {
            node.children.retain(|&c| c != index);
            node.children.iter_mut().for_each(|c| *c = remap(*c));
            node.parent = node
                .parent
                .and_then(|p| if p == index { None } else { Some(remap(p)) });
        }
        self.root_nodes.retain(|&r| r != index);
        self.root_nodes.iter_mut().for_each(|r| *r = remap(*r));
        self.selected_node =
            self.selected_node
                .and_then(|s| if s == index { None } else { Some(remap(s)) });
        true
    }
    pub fn clear_nodes(&mut self) {
        self.nodes.clear();
        self.root_nodes.clear();
        self.selected_node = None;
    }
    pub fn get_node_text(&self, index: usize) -> Option<&str> {
        self.nodes.get(index).map(|n| n.text.as_str())
    }
    pub fn set_node_text(&mut self, index: usize, text: impl Into<String>) -> bool {
        if let Some(node) = self.nodes.get_mut(index) {
            node.text = text.into();
            true
        } else {
            false
        }
    }
    pub fn set_node_icon(&mut self, index: usize, icon: impl Into<String>) -> bool {
        if let Some(node) = self.nodes.get_mut(index) {
            let s = icon.into();
            node.icon = if s.is_empty() { None } else { Some(s) };
            true
        } else {
            false
        }
    }
    pub fn expand_node(&mut self, index: usize) -> bool {
        if let Some(node) = self.nodes.get_mut(index) {
            node.expanded = true;
            true
        } else {
            false
        }
    }
    pub fn collapse_node(&mut self, index: usize) -> bool {
        if let Some(node) = self.nodes.get_mut(index) {
            node.expanded = false;
            true
        } else {
            false
        }
    }
    pub fn is_node_expanded(&self, index: usize) -> Option<bool> {
        self.nodes.get(index).map(|n| n.expanded)
    }
    pub fn expand_all(&mut self) {
        for node in &mut self.nodes {
            node.expanded = true;
        }
    }
    pub fn collapse_all(&mut self) {
        for node in &mut self.nodes {
            node.expanded = false;
        }
    }
    pub fn set_selected_node(&mut self, index: usize) -> bool {
        if index < self.nodes.len() {
            self.selected_node = Some(index);
            true
        } else {
            self.selected_node = None;
            false
        }
    }
    pub fn get_selected_node(&self) -> Option<usize> {
        self.selected_node
    }
    pub fn get_child_nodes(&self, index: usize) -> Option<&[usize]> {
        self.nodes.get(index).map(|n| n.children.as_slice())
    }
    pub fn get_parent_node(&self, index: usize) -> Option<Option<usize>> {
        self.nodes.get(index).map(|n| n.parent)
    }
    pub fn get_node_depth(&self, index: usize) -> Option<usize> {
        let mut depth = 0usize;
        let mut current = index;
        loop {
            let node = self.nodes.get(current)?;
            match node.parent {
                None => return Some(depth),
                Some(p) => {
                    depth += 1;
                    current = p;
                }
            }
        }
    }
}
impl Default for TreeView {
    fn default() -> Self {
        Self::new()
    }
}
#[derive(Debug, Clone)]
pub struct ToolbarButton {
    pub id: String,
    pub tooltip: String,
    pub enabled: bool,
    pub toggled: bool,
}
impl ToolbarButton {
    pub fn new(id: impl Into<String>, tooltip: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            tooltip: tooltip.into(),
            enabled: true,
            toggled: false,
        }
    }
}
#[derive(Debug, Clone)]
pub struct Toolbar {
    pub base: WidgetBase,
    pub orientation: String,
    pub children: Vec<usize>,
    pub buttons: Vec<ToolbarButton>,
}
impl Toolbar {
    pub fn new(orientation: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Toolbar),
            orientation: orientation.into(),
            children: Vec::new(),
            buttons: Vec::new(),
        }
    }
    pub fn add_button(&mut self, id: impl Into<String>, tooltip: impl Into<String>) -> usize {
        let id = id.into();
        if let Some(pos) = self.buttons.iter().position(|b| b.id == id) {
            return pos;
        }
        self.buttons.push(ToolbarButton::new(id, tooltip));
        self.buttons.len() - 1
    }
    pub fn add_separator(&mut self) {}
    pub fn add_spacer(&mut self, _width: f32) {}
    pub fn get_button_index(&self, id: &str) -> Option<usize> {
        self.buttons.iter().position(|b| b.id == id)
    }
    pub fn set_button_enabled(&mut self, id: &str, enabled: bool) -> bool {
        if let Some(b) = self.buttons.iter_mut().find(|b| b.id == id) {
            b.enabled = enabled;
            true
        } else {
            false
        }
    }
    pub fn set_button_toggled(&mut self, id: &str, toggled: bool) -> bool {
        if let Some(b) = self.buttons.iter_mut().find(|b| b.id == id) {
            b.toggled = toggled;
            true
        } else {
            false
        }
    }
    pub fn is_button_toggled(&self, id: &str) -> Option<bool> {
        self.buttons.iter().find(|b| b.id == id).map(|b| b.toggled)
    }
}
#[derive(Debug, Clone)]
pub struct MenuBar {
    pub base: WidgetBase,
    pub menus: Vec<usize>,
}
impl MenuBar {
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::MenuBar),
            menus: Vec::new(),
        }
    }
}
impl Default for MenuBar {
    fn default() -> Self {
        Self::new()
    }
}
#[derive(Debug, Clone)]
pub struct MenuItem {
    pub base: WidgetBase,
    pub text: String,
    pub shortcut: String,
    pub checked: bool,
    pub items: Vec<usize>,
}
impl MenuItem {
    pub fn new(text: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::MenuItem),
            text: text.into(),
            shortcut: String::new(),
            checked: false,
            items: Vec::new(),
        }
    }
}
#[derive(Debug, Clone)]
pub struct Dialog {
    pub base: WidgetBase,
    pub title: String,
    pub modal: bool,
    pub open: bool,
    pub content_idx: Option<usize>,
    pub footer_buttons: Vec<String>,
}
impl Dialog {
    pub fn new(title: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Dialog),
            title: title.into(),
            modal: true,
            open: false,
            content_idx: None,
            footer_buttons: Vec::new(),
        }
    }
}
#[derive(Debug, Clone)]
pub struct StatusBar {
    pub base: WidgetBase,
    pub sections: Vec<(String, f32)>,
}
impl StatusBar {
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::StatusBar),
            sections: Vec::new(),
        }
    }
}
impl Default for StatusBar {
    fn default() -> Self {
        Self::new()
    }
}
#[derive(Debug, Clone)]
pub struct AccordionSection {
    pub title: String,
    pub content_idx: Option<usize>,
    pub expanded: bool,
}
#[derive(Debug, Clone)]
pub struct Accordion {
    pub base: WidgetBase,
    pub sections: Vec<AccordionSection>,
    pub exclusive: bool,
}
impl Accordion {
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Accordion),
            sections: Vec::new(),
            exclusive: false,
        }
    }
}
impl Default for Accordion {
    fn default() -> Self {
        Self::new()
    }
}
#[derive(Debug, Clone)]
pub struct TooltipPanel {
    pub base: WidgetBase,
    pub text: String,
    pub delay: f32,
    pub target_idx: Option<usize>,
}
impl TooltipPanel {
    pub fn new(text: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::TooltipPanel),
            text: text.into(),
            delay: 0.5,
            target_idx: None,
        }
    }
}
#[derive(Debug, Clone)]
pub struct ColorPicker {
    pub base: WidgetBase,
    pub r: f32,
    pub g: f32,
    pub b: f32,
    pub a: f32,
    pub show_alpha: bool,
    pub color_mode: String,
}
impl ColorPicker {
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::ColorPicker),
            r: 1.0,
            g: 1.0,
            b: 1.0,
            a: 1.0,
            show_alpha: true,
            color_mode: "rgb".to_string(),
        }
    }
}
impl Default for ColorPicker {
    fn default() -> Self {
        Self::new()
    }
}
#[derive(Debug, Clone)]
pub struct TableColumn {
    pub header: String,
    pub width: f32,
}
#[derive(Debug, Clone)]
pub struct GUITable {
    pub base: WidgetBase,
    pub columns: Vec<TableColumn>,
    pub rows: Vec<Vec<String>>,
    pub selected_row: Option<usize>,
    pub sortable: bool,
}
impl GUITable {
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::GUITable),
            columns: Vec::new(),
            rows: Vec::new(),
            selected_row: None,
            sortable: false,
        }
    }
}
impl Default for GUITable {
    fn default() -> Self {
        Self::new()
    }
}
#[derive(Debug, Clone)]
pub struct ImageWidget {
    pub base: WidgetBase,
    pub scale_mode: String,
    pub tint: (f32, f32, f32, f32),
}
impl ImageWidget {
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::ImageWidget),
            scale_mode: "fit".to_string(),
            tint: (1.0, 1.0, 1.0, 1.0),
        }
    }
}
impl Default for ImageWidget {
    fn default() -> Self {
        Self::new()
    }
}
#[derive(Debug, Clone)]
pub struct Badge {
    pub base: WidgetBase,
    pub count: u32,
    pub max_display: u32,
}
impl Badge {
    pub fn new(count: u32) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Badge),
            count,
            max_display: 99,
        }
    }
    pub fn display_text(&self) -> String {
        if self.count > self.max_display {
            format!("{}+", self.max_display)
        } else {
            self.count.to_string()
        }
    }
    pub fn set_count(&mut self, count: u32) {
        self.count = count;
    }
}
#[derive(Debug, Clone)]
pub struct CustomWidget {
    pub base: WidgetBase,
}
impl CustomWidget {
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Custom),
        }
    }
}
impl Default for CustomWidget {
    fn default() -> Self {
        Self::new()
    }
}
