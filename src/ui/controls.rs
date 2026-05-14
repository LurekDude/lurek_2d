//! Leaf control widgets for `lurek.ui` — interactive elements including `Button`, `Label`, `TextInput`,
//! `CheckBox`, `Slider`, `ProgressBar`, `ComboBox`, `ListBox`, `TabBar`, `RadioButton`, `ScrollBar`,
//! `SpinBox`, and `Switch`. Each widget owns a `WidgetBase` and its control-specific state.
//! Depends on `crate::ui::widget`.

use crate::ui::widget::{WidgetBase, WidgetType};
/// Clickable push button with a text label.
#[derive(Debug, Clone)]
pub struct Button {
    /// Shared layout, style, and state fields.
    pub base: WidgetBase,
    /// Label text rendered inside the button.
    pub text: String,
}
impl Button {
    /// Create a button with the given text.
    pub fn new(text: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Button),
            text: text.into(),
        }
    }
}
/// Non-interactive single-line text display.
#[derive(Debug, Clone)]
pub struct Label {
    /// Shared layout, style, and state fields.
    pub base: WidgetBase,
    /// Text string to render.
    pub text: String,
}
impl Label {
    /// Create a label with the given text.
    pub fn new(text: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Label),
            text: text.into(),
        }
    }
}
/// Single-line editable text field with cursor tracking and optional max length.
#[derive(Debug, Clone)]
pub struct TextInput {
    /// Shared layout, style, and state fields.
    pub base: WidgetBase,
    /// Current text content.
    pub text: String,
    /// Placeholder text shown when `text` is empty.
    pub placeholder: String,
    /// Maximum character count; 0 = unlimited.
    pub max_length: usize,
    /// Byte offset of the insertion cursor within `text`.
    pub cursor_pos: usize,
    /// Whether this widget currently holds keyboard focus.
    pub focused: bool,
}
impl TextInput {
    /// Create an empty text input with no placeholder and unlimited length.
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
    /// Insert `input` at the cursor position; return `false` if it would exceed `max_length`.
    pub fn insert_text(&mut self, input: &str) -> bool {
        if self.max_length > 0 && self.text.len() + input.len() > self.max_length {
            return false;
        }
        self.text.insert_str(self.cursor_pos, input);
        self.cursor_pos += input.len();
        true
    }
    /// Delete the character before the cursor; return `false` if already at position 0.
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
/// Provide a default `TextInput` via `Self::new()`.
impl Default for TextInput {
    fn default() -> Self {
        Self::new()
    }
}
/// Boolean toggle control with a visible label.
#[derive(Debug, Clone)]
pub struct CheckBox {
    /// Shared layout, style, and state fields.
    pub base: WidgetBase,
    /// Label displayed next to the checkbox.
    pub text: String,
    /// Whether the checkbox is currently checked.
    pub checked: bool,
}
impl CheckBox {
    /// Create an unchecked checkbox with the given label.
    pub fn new(text: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::CheckBox),
            text: text.into(),
            checked: false,
        }
    }
}
/// Continuous or stepped numeric value slider.
#[derive(Debug, Clone)]
pub struct Slider {
    /// Shared layout, style, and state fields.
    pub base: WidgetBase,
    /// Current clamped value in `[min, max]`.
    pub value: f64,
    /// Minimum allowed value.
    pub min: f64,
    /// Maximum allowed value.
    pub max: f64,
    /// Snap step size; 0.0 = continuous.
    pub step: f64,
}
impl Slider {
    /// Create a slider with the given range; initial value is `min`, step defaults to 0 (continuous).
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
/// Read-only bounded progress indicator.
#[derive(Debug, Clone)]
pub struct ProgressBar {
    /// Shared layout, style, and state fields.
    pub base: WidgetBase,
    /// Current value; should lie in `[min, max]`.
    pub value: f64,
    /// Minimum bound for the progress range.
    pub min: f64,
    /// Maximum bound for the progress range.
    pub max: f64,
}
impl ProgressBar {
    /// Create a progress bar with the given range; initial value is `min`.
    pub fn new(min: f64, max: f64) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::ProgressBar),
            value: min,
            min,
            max,
        }
    }
    /// Return the normalised fill fraction in `[0.0, 1.0]`; returns 0.0 when `max == min`.
    pub fn progress(&self) -> f64 {
        let range = self.max - self.min;
        if range <= 0.0 {
            0.0
        } else {
            ((self.value - self.min) / range).clamp(0.0, 1.0)
        }
    }
}
/// Drop-down single-selection list with an open/closed toggle.
#[derive(Debug, Clone)]
pub struct ComboBox {
    /// Shared layout, style, and state fields.
    pub base: WidgetBase,
    /// Ordered item strings shown in the drop-down.
    pub items: Vec<String>,
    /// Index of the currently selected item, or `None` when nothing is selected.
    pub selected_index: Option<usize>,
    /// Whether the drop-down list is currently visible.
    pub open: bool,
}
impl ComboBox {
    /// Create an empty combo box with no selection.
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
    /// Remove the item at `index` from ComboBox; adjusts `selected_index`; return `false` when out of range.
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
    /// Remove all items and reset selection for ComboBox.
    pub fn clear(&mut self) {
        self.items.clear();
        self.selected_index = None;
    }
    /// Return the text of the selected ComboBox item, or `None`.
    pub fn selected_item(&self) -> Option<&str> {
        self.selected_index
            .and_then(|i| self.items.get(i).map(|s| s.as_str()))
    }
}
/// Provide a default `ComboBox` via `Self::new()`.
impl Default for ComboBox {
    fn default() -> Self {
        Self::new()
    }
}
/// Scrollable multi-item list with keyboard-navigable single selection.
#[derive(Debug, Clone)]
pub struct ListBox {
    /// Shared layout, style, and state fields.
    pub base: WidgetBase,
    /// Ordered list items.
    pub items: Vec<String>,
    /// Index of the currently selected item, or `None`.
    pub selected_index: Option<usize>,
    /// Pixel height allocated for each row.
    pub item_height: f32,
}
impl ListBox {
    /// Create an empty list box with item_height=24.
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::ListBox),
            items: Vec::new(),
            selected_index: None,
            item_height: 24.0,
        }
    }
    /// Append a new item to the ListBox.
    pub fn add_item(&mut self, text: impl Into<String>) {
        self.items.push(text.into());
    }
    /// Remove the item at `index` from the ListBox; adjusts `selected_index`; return `false` when out of range.
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
    /// Remove all items and reset selection for ListBox.
    pub fn clear(&mut self) {
        self.items.clear();
        self.selected_index = None;
    }
    /// Return the text of the selected ListBox item, or `None`.
    pub fn selected_item(&self) -> Option<&str> {
        self.selected_index
            .and_then(|i| self.items.get(i).map(|s| s.as_str()))
    }
}
/// Provide a default `ListBox` via `Self::new()`.
impl Default for ListBox {
    fn default() -> Self {
        Self::new()
    }
}
/// Horizontal navigation bar with labelled tab buttons.
#[derive(Debug, Clone)]
pub struct TabBar {
    /// Shared layout, style, and state fields.
    pub base: WidgetBase,
    /// Ordered tab label strings.
    pub tabs: Vec<String>,
    /// Index of the currently active tab.
    pub active_tab: usize,
}
impl TabBar {
    /// Create an empty tab bar with active_tab=0.
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::TabBar),
            tabs: Vec::new(),
            active_tab: 0,
        }
    }
    /// Append a tab with the given label.
    pub fn add_tab(&mut self, label: impl Into<String>) {
        self.tabs.push(label.into());
    }
    /// Remove the tab at `index`; clamps `active_tab` to the new length; return `false` when out of range.
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
/// Provide a default `TabBar` via `Self::new()`.
impl Default for TabBar {
    fn default() -> Self {
        Self::new()
    }
}
/// Mutually exclusive selection option belonging to a named group.
#[derive(Debug, Clone)]
pub struct RadioButton {
    /// Shared layout, style, and state fields.
    pub base: WidgetBase,
    /// Label rendered next to the radio circle.
    pub text: String,
    /// Whether this button is the selected option in its group.
    pub selected: bool,
    /// Group name used to coordinate mutual exclusion.
    pub group: String,
}
impl RadioButton {
    /// Create an unselected radio button with the given label and group.
    pub fn new(text: impl Into<String>, group: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::RadioButton),
            text: text.into(),
            selected: false,
            group: group.into(),
        }
    }
}
/// Explicit horizontal or vertical scroll bar for a `ScrollPanel`.
#[derive(Debug, Clone)]
pub struct ScrollBar {
    /// Shared layout, style, and state fields.
    pub base: WidgetBase,
    /// Current scroll position in content pixels.
    pub position: f32,
    /// Total scrollable content size in pixels.
    pub content_size: f32,
    /// Visible viewport size in pixels; thumb length is `view_size / content_size`.
    pub view_size: f32,
    /// `true` for a vertical orientation, `false` for horizontal.
    pub vertical: bool,
}
impl ScrollBar {
    /// Create a scroll bar with content_size=100 and view_size=50.
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
/// Number field with increment/decrement step buttons.
#[derive(Debug, Clone)]
pub struct SpinBox {
    /// Shared layout, style, and state fields.
    pub base: WidgetBase,
    /// Current clamped value.
    pub value: f64,
    /// Minimum allowed value.
    pub min: f64,
    /// Maximum allowed value.
    pub max: f64,
    /// Amount added or subtracted per button click.
    pub step: f64,
}
impl SpinBox {
    /// Create a spin box clamped to `[min, max]` with step=1.0; initial value is `min`.
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
    /// Increase value by one step.
    pub fn increment(&mut self) {
        self.set_value(self.value + self.step);
    }
    /// Decrease value by one step.
    pub fn decrement(&mut self) {
        self.set_value(self.value - self.step);
    }
    /// Update the allowed range and re-clamp the current value.
    pub fn set_range(&mut self, min: f64, max: f64) {
        self.min = min.min(max);
        self.max = min.max(max);
        self.value = self.value.clamp(self.min, self.max);
    }
}
/// Animated on/off toggle switch.
#[derive(Debug, Clone)]
pub struct Switch {
    /// Shared layout, style, and state fields.
    pub base: WidgetBase,
    /// Current logical state: `true` = on.
    pub on: bool,
    /// Thumb animation position in `[0.0, 1.0]`; 0.0 = off end, 1.0 = on end.
    pub thumb_t: f32,
}
impl Switch {
    /// Create a switch with the given initial state; sets `thumb_t` accordingly.
    pub fn new(on: bool) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Switch),
            on,
            thumb_t: if on { 1.0 } else { 0.0 },
        }
    }
    /// Flip the on/off state and snap `thumb_t` to the new position.
    pub fn toggle(&mut self) {
        self.on = !self.on;
        self.thumb_t = if self.on { 1.0 } else { 0.0 };
    }
    /// Set `on` to the given value and snap `thumb_t`.
    pub fn set_on(&mut self, on: bool) {
        self.on = on;
        self.thumb_t = if on { 1.0 } else { 0.0 };
    }
}
