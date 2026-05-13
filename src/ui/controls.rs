use crate::ui::widget::{WidgetBase, WidgetType};
#[derive(Debug, Clone)]
pub struct Button {
    pub base: WidgetBase,
    pub text: String,
}
impl Button {
    pub fn new(text: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Button),
            text: text.into(),
        }
    }
}
#[derive(Debug, Clone)]
pub struct Label {
    pub base: WidgetBase,
    pub text: String,
}
impl Label {
    pub fn new(text: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Label),
            text: text.into(),
        }
    }
}
#[derive(Debug, Clone)]
pub struct TextInput {
    pub base: WidgetBase,
    pub text: String,
    pub placeholder: String,
    pub max_length: usize,
    pub cursor_pos: usize,
    pub focused: bool,
}
impl TextInput {
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::TextInput),
            text: String::new(),
            placeholder: String::new(),
            max_length: 0,
            cursor_pos: 0,
            focused: false,
        }
    }
    pub fn insert_text(&mut self, input: &str) -> bool {
        if self.max_length > 0 && self.text.len() + input.len() > self.max_length {
            return false;
        }
        self.text.insert_str(self.cursor_pos, input);
        self.cursor_pos += input.len();
        true
    }
    pub fn backspace(&mut self) -> bool {
        if self.cursor_pos > 0 {
            let prev = self.text[..self.cursor_pos]
                .char_indices()
                .next_back()
                .map(|(i, _)| i)
                .unwrap_or(0);
            self.text.drain(prev..self.cursor_pos);
            self.cursor_pos = prev;
            true
        } else {
            false
        }
    }
}
impl Default for TextInput {
    fn default() -> Self {
        Self::new()
    }
}
#[derive(Debug, Clone)]
pub struct CheckBox {
    pub base: WidgetBase,
    pub text: String,
    pub checked: bool,
}
impl CheckBox {
    pub fn new(text: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::CheckBox),
            text: text.into(),
            checked: false,
        }
    }
}
#[derive(Debug, Clone)]
pub struct Slider {
    pub base: WidgetBase,
    pub value: f64,
    pub min: f64,
    pub max: f64,
    pub step: f64,
}
impl Slider {
    pub fn new(min: f64, max: f64) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Slider),
            value: min,
            min,
            max,
            step: 0.0,
        }
    }
    pub fn set_value(&mut self, v: f64) {
        let mut v = v.clamp(self.min, self.max);
        if self.step > 0.0 {
            v = ((v - self.min) / self.step).round() * self.step + self.min;
            v = v.clamp(self.min, self.max);
        }
        self.value = v;
    }
}
#[derive(Debug, Clone)]
pub struct ProgressBar {
    pub base: WidgetBase,
    pub value: f64,
    pub min: f64,
    pub max: f64,
}
impl ProgressBar {
    pub fn new(min: f64, max: f64) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::ProgressBar),
            value: min,
            min,
            max,
        }
    }
    pub fn progress(&self) -> f64 {
        let range = self.max - self.min;
        if range <= 0.0 {
            0.0
        } else {
            ((self.value - self.min) / range).clamp(0.0, 1.0)
        }
    }
}
#[derive(Debug, Clone)]
pub struct ComboBox {
    pub base: WidgetBase,
    pub items: Vec<String>,
    pub selected_index: Option<usize>,
    pub open: bool,
}
impl ComboBox {
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::ComboBox),
            items: Vec::new(),
            selected_index: None,
            open: false,
        }
    }
    pub fn add_item(&mut self, text: impl Into<String>) {
        self.items.push(text.into());
    }
    pub fn remove_item(&mut self, index: usize) -> bool {
        if index < self.items.len() {
            self.items.remove(index);
            if let Some(sel) = self.selected_index {
                if sel >= self.items.len() {
                    self.selected_index = if self.items.is_empty() {
                        None
                    } else {
                        Some(self.items.len() - 1)
                    };
                }
            }
            true
        } else {
            false
        }
    }
    pub fn clear(&mut self) {
        self.items.clear();
        self.selected_index = None;
    }
    pub fn selected_item(&self) -> Option<&str> {
        self.selected_index
            .and_then(|i| self.items.get(i).map(|s| s.as_str()))
    }
}
impl Default for ComboBox {
    fn default() -> Self {
        Self::new()
    }
}
#[derive(Debug, Clone)]
pub struct ListBox {
    pub base: WidgetBase,
    pub items: Vec<String>,
    pub selected_index: Option<usize>,
    pub item_height: f32,
}
impl ListBox {
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::ListBox),
            items: Vec::new(),
            selected_index: None,
            item_height: 24.0,
        }
    }
    pub fn add_item(&mut self, text: impl Into<String>) {
        self.items.push(text.into());
    }
    pub fn remove_item(&mut self, index: usize) -> bool {
        if index < self.items.len() {
            self.items.remove(index);
            if let Some(sel) = self.selected_index {
                if sel >= self.items.len() {
                    self.selected_index = if self.items.is_empty() {
                        None
                    } else {
                        Some(self.items.len() - 1)
                    };
                }
            }
            true
        } else {
            false
        }
    }
    pub fn clear(&mut self) {
        self.items.clear();
        self.selected_index = None;
    }
    pub fn selected_item(&self) -> Option<&str> {
        self.selected_index
            .and_then(|i| self.items.get(i).map(|s| s.as_str()))
    }
}
impl Default for ListBox {
    fn default() -> Self {
        Self::new()
    }
}
#[derive(Debug, Clone)]
pub struct TabBar {
    pub base: WidgetBase,
    pub tabs: Vec<String>,
    pub active_tab: usize,
}
impl TabBar {
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::TabBar),
            tabs: Vec::new(),
            active_tab: 0,
        }
    }
    pub fn add_tab(&mut self, label: impl Into<String>) {
        self.tabs.push(label.into());
    }
    pub fn remove_tab(&mut self, index: usize) -> bool {
        if index < self.tabs.len() {
            self.tabs.remove(index);
            if self.active_tab >= self.tabs.len() && !self.tabs.is_empty() {
                self.active_tab = self.tabs.len() - 1;
            }
            true
        } else {
            false
        }
    }
}
impl Default for TabBar {
    fn default() -> Self {
        Self::new()
    }
}
#[derive(Debug, Clone)]
pub struct RadioButton {
    pub base: WidgetBase,
    pub text: String,
    pub selected: bool,
    pub group: String,
}
impl RadioButton {
    pub fn new(text: impl Into<String>, group: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::RadioButton),
            text: text.into(),
            selected: false,
            group: group.into(),
        }
    }
}
#[derive(Debug, Clone)]
pub struct ScrollBar {
    pub base: WidgetBase,
    pub position: f32,
    pub content_size: f32,
    pub view_size: f32,
    pub vertical: bool,
}
impl ScrollBar {
    pub fn new(vertical: bool) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::ScrollBar),
            position: 0.0,
            content_size: 100.0,
            view_size: 50.0,
            vertical,
        }
    }
}
#[derive(Debug, Clone)]
pub struct SpinBox {
    pub base: WidgetBase,
    pub value: f64,
    pub min: f64,
    pub max: f64,
    pub step: f64,
}
impl SpinBox {
    pub fn new(min: f64, max: f64) -> Self {
        let clamped_min = min.min(max);
        Self {
            base: WidgetBase::new(WidgetType::SpinBox),
            value: clamped_min,
            min: clamped_min,
            max: min.max(max),
            step: 1.0,
        }
    }
    pub fn set_value(&mut self, v: f64) {
        let snapped = if self.step > 0.0 {
            (v / self.step).round() * self.step
        } else {
            v
        };
        self.value = snapped.clamp(self.min, self.max);
    }
    pub fn increment(&mut self) {
        self.set_value(self.value + self.step);
    }
    pub fn decrement(&mut self) {
        self.set_value(self.value - self.step);
    }
    pub fn set_range(&mut self, min: f64, max: f64) {
        self.min = min.min(max);
        self.max = min.max(max);
        self.value = self.value.clamp(self.min, self.max);
    }
}
#[derive(Debug, Clone)]
pub struct Switch {
    pub base: WidgetBase,
    pub on: bool,
    pub thumb_t: f32,
}
impl Switch {
    pub fn new(on: bool) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Switch),
            on,
            thumb_t: if on { 1.0 } else { 0.0 },
        }
    }
    pub fn toggle(&mut self) {
        self.on = !self.on;
        self.thumb_t = if self.on { 1.0 } else { 0.0 };
    }
    pub fn set_on(&mut self, on: bool) {
        self.on = on;
        self.thumb_t = if on { 1.0 } else { 0.0 };
    }
}
