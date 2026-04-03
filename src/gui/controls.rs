//! Interactive and display control widgets.
//!
//! This sub-module provides the leaf-level widgets that users interact with
//! or read information from: [`Button`], [`Label`], [`TextInput`],
//! [`CheckBox`], [`Slider`], [`ProgressBar`], [`ComboBox`], [`ListBox`], and
//! [`TabBar`].  Each widget embeds a [`WidgetBase`](super::WidgetBase) for
//! shared properties and adds type-specific data fields.

use crate::gui::widget::{WidgetBase, WidgetType};

// ── Button ────────────────────────────────────────────────────────────────

/// Clickable button widget.
///
/// Displays a text label and triggers an `onClick` callback (registered via
/// Lua) when the mouse is pressed and released within its bounds.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `text` — `String`. Button label text.
#[derive(Debug, Clone)]
pub struct Button {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Button label text.
    pub text: String,
}

impl Button {
    /// Create a new button with the given label text.
    ///
    /// # Parameters
    /// - `text` — `impl Into<String>`. Button label.
    ///
    /// # Returns
    /// `Button`.
    pub fn new(text: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Button),
            text: text.into(),
        }
    }
}

// ── Label ─────────────────────────────────────────────────────────────────

/// Static text label widget.
///
/// Displays read-only text.  Does not receive focus or respond to input
/// events.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `text` — `String`. Display text.
#[derive(Debug, Clone)]
pub struct Label {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Display text.
    pub text: String,
}

impl Label {
    /// Create a new label with the given text.
    ///
    /// # Parameters
    /// - `text` — `impl Into<String>`. Label text.
    ///
    /// # Returns
    /// `Label`.
    pub fn new(text: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Label),
            text: text.into(),
        }
    }
}

// ── TextInput ─────────────────────────────────────────────────────────────

/// Editable single-line text input field.
///
/// Supports placeholder text, maximum character length, cursor position
/// tracking, and an `onChange` callback triggered when the text mutates.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `text` — `String`. Current input value.
/// - `placeholder` — `String`. Greyed-out hint when empty.
/// - `max_length` — `usize`. Maximum character count (0 = unlimited).
/// - `cursor_pos` — `usize`. Byte offset of the editing cursor.
/// - `focused` — `bool`. Whether this input has keyboard focus.
#[derive(Debug, Clone)]
pub struct TextInput {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Current input value.
    pub text: String,
    /// Greyed-out hint when empty.
    pub placeholder: String,
    /// Maximum character count (0 = unlimited).
    pub max_length: usize,
    /// Byte offset of the editing cursor.
    pub cursor_pos: usize,
    /// Whether this input has keyboard focus.
    pub focused: bool,
}

impl TextInput {
    /// Create a new empty text input.
    ///
    /// # Returns
    /// `TextInput`.
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

    /// Insert text at the cursor position, respecting `max_length`.
    ///
    /// # Parameters
    /// - `input` — `&str`. Text to insert.
    ///
    /// # Returns
    /// `bool` — `true` if any characters were inserted.
    pub fn insert_text(&mut self, input: &str) -> bool {
        if self.max_length > 0 && self.text.len() + input.len() > self.max_length {
            return false;
        }
        self.text.insert_str(self.cursor_pos, input);
        self.cursor_pos += input.len();
        true
    }

    /// Delete the character before the cursor (backspace).
    ///
    /// # Returns
    /// `bool` — `true` if a character was deleted.
    pub fn backspace(&mut self) -> bool {
        if self.cursor_pos > 0 {
            // Find the char boundary before cursor_pos
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

// ── CheckBox ──────────────────────────────────────────────────────────────

/// Toggle check-box widget with an associated label.
///
/// Fires an `onChange` callback (via Lua) when toggled.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `text` — `String`. Label text shown beside the check box.
/// - `checked` — `bool`. Current toggle state.
#[derive(Debug, Clone)]
pub struct CheckBox {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Label text shown beside the check box.
    pub text: String,
    /// Current toggle state.
    pub checked: bool,
}

impl CheckBox {
    /// Create a new unchecked check box with the given label.
    ///
    /// # Parameters
    /// - `text` — `impl Into<String>`. Label text.
    ///
    /// # Returns
    /// `CheckBox`.
    pub fn new(text: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::CheckBox),
            text: text.into(),
            checked: false,
        }
    }
}

// ── Slider ────────────────────────────────────────────────────────────────

/// Numeric value slider widget.
///
/// Allows the user to drag a thumb along a track to select a value between
/// `min` and `max`, snapped to `step` increments.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `value` — `f64`. Current value.
/// - `min` — `f64`. Minimum allowed value.
/// - `max` — `f64`. Maximum allowed value.
/// - `step` — `f64`. Snap increment (0 = continuous).
#[derive(Debug, Clone)]
pub struct Slider {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Current value.
    pub value: f64,
    /// Minimum allowed value.
    pub min: f64,
    /// Maximum allowed value.
    pub max: f64,
    /// Snap increment (0 = continuous).
    pub step: f64,
}

impl Slider {
    /// Create a new slider with the given range.
    ///
    /// The initial value is clamped to `min`.
    ///
    /// # Parameters
    /// - `min` — `f64`. Minimum value.
    /// - `max` — `f64`. Maximum value.
    ///
    /// # Returns
    /// `Slider`.
    pub fn new(min: f64, max: f64) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Slider),
            value: min,
            min,
            max,
            step: 0.0,
        }
    }

    /// Set the current value, clamping to the `[min, max]` range and
    /// snapping to `step` if non-zero.
    ///
    /// # Parameters
    /// - `v` — `f64`. New value.
    pub fn set_value(&mut self, v: f64) {
        let mut v = v.clamp(self.min, self.max);
        if self.step > 0.0 {
            v = ((v - self.min) / self.step).round() * self.step + self.min;
            v = v.clamp(self.min, self.max);
        }
        self.value = v;
    }
}

// ── ProgressBar ───────────────────────────────────────────────────────────

/// Read-only progress indicator widget.
///
/// Displays a filled bar proportional to `value` within `[min, max]`.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `value` — `f64`. Current value.
/// - `min` — `f64`. Minimum value.
/// - `max` — `f64`. Maximum value.
#[derive(Debug, Clone)]
pub struct ProgressBar {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Current value.
    pub value: f64,
    /// Minimum value.
    pub min: f64,
    /// Maximum value.
    pub max: f64,
}

impl ProgressBar {
    /// Create a new progress bar with the given range.
    ///
    /// # Parameters
    /// - `min` — `f64`. Minimum value.
    /// - `max` — `f64`. Maximum value.
    ///
    /// # Returns
    /// `ProgressBar`.
    pub fn new(min: f64, max: f64) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::ProgressBar),
            value: min,
            min,
            max,
        }
    }

    /// Return the normalized progress in `[0.0, 1.0]`.
    ///
    /// # Returns
    /// `f64`.
    pub fn progress(&self) -> f64 {
        let range = self.max - self.min;
        if range <= 0.0 {
            0.0
        } else {
            ((self.value - self.min) / range).clamp(0.0, 1.0)
        }
    }
}

// ── ComboBox ──────────────────────────────────────────────────────────────

/// Drop-down selection widget.
///
/// Maintains a list of string items and a 0-based selected index.  The Lua
/// API exposes 1-based indices for Lua convention.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `items` — `Vec<String>`. Item list.
/// - `selected_index` — `Option<usize>`. 0-based selected index.
/// - `open` — `bool`. Whether the dropdown is expanded.
#[derive(Debug, Clone)]
pub struct ComboBox {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Item list.
    pub items: Vec<String>,
    /// 0-based selected index.
    pub selected_index: Option<usize>,
    /// Whether the dropdown is expanded.
    pub open: bool,
}

impl ComboBox {
    /// Create a new empty combo box.
    ///
    /// # Returns
    /// `ComboBox`.
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::ComboBox),
            items: Vec::new(),
            selected_index: None,
            open: false,
        }
    }

    /// Add an item to the end of the list.
    ///
    /// # Parameters
    /// - `text` — `impl Into<String>`.
    pub fn add_item(&mut self, text: impl Into<String>) {
        self.items.push(text.into());
    }

    /// Remove an item at the given 0-based index.
    ///
    /// Returns `false` if the index is out of bounds.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_item(&mut self, index: usize) -> bool {
        if index < self.items.len() {
            self.items.remove(index);
            // Adjust selection
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

    /// Clear all items and reset selection.
    pub fn clear(&mut self) {
        self.items.clear();
        self.selected_index = None;
    }

    /// Get the currently selected item text, if any.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn selected_item(&self) -> Option<&str> {
        self.selected_index.and_then(|i| self.items.get(i).map(|s| s.as_str()))
    }
}

impl Default for ComboBox {
    fn default() -> Self {
        Self::new()
    }
}

// ── ListBox ───────────────────────────────────────────────────────────────

/// Scrollable list of selectable items.
///
/// Maintains a list of string items, a 0-based selected index, and a
/// configurable per-item height.  The Lua API exposes 1-based indices.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `items` — `Vec<String>`. Item list.
/// - `selected_index` — `Option<usize>`. 0-based selected index.
/// - `item_height` — `f32`. Height of each item row in pixels.
#[derive(Debug, Clone)]
pub struct ListBox {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Item list.
    pub items: Vec<String>,
    /// 0-based selected index.
    pub selected_index: Option<usize>,
    /// Height of each item row in pixels.
    pub item_height: f32,
}

impl ListBox {
    /// Create a new empty list box.
    ///
    /// # Returns
    /// `ListBox`.
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::ListBox),
            items: Vec::new(),
            selected_index: None,
            item_height: 24.0,
        }
    }

    /// Add an item to the end of the list.
    ///
    /// # Parameters
    /// - `text` — `impl Into<String>`.
    pub fn add_item(&mut self, text: impl Into<String>) {
        self.items.push(text.into());
    }

    /// Remove an item at the given 0-based index.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `bool`.
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

    /// Clear all items and reset selection.
    pub fn clear(&mut self) {
        self.items.clear();
        self.selected_index = None;
    }

    /// Get the currently selected item text, if any.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn selected_item(&self) -> Option<&str> {
        self.selected_index.and_then(|i| self.items.get(i).map(|s| s.as_str()))
    }
}

impl Default for ListBox {
    fn default() -> Self {
        Self::new()
    }
}

// ── TabBar ────────────────────────────────────────────────────────────────

/// Tabbed page selector widget.
///
/// Manages a list of tab labels and tracks the currently active tab (0-based
/// internally, 1-based in Lua).
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `tabs` — `Vec<String>`. Tab label list.
/// - `active_tab` — `usize`. 0-based index of the active tab.
#[derive(Debug, Clone)]
pub struct TabBar {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Tab label list.
    pub tabs: Vec<String>,
    /// 0-based index of the active tab.
    pub active_tab: usize,
}

impl TabBar {
    /// Create a new empty tab bar.
    ///
    /// # Returns
    /// `TabBar`.
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::TabBar),
            tabs: Vec::new(),
            active_tab: 0,
        }
    }

    /// Add a tab with the given label.
    ///
    /// # Parameters
    /// - `label` — `impl Into<String>`.
    pub fn add_tab(&mut self, label: impl Into<String>) {
        self.tabs.push(label.into());
    }

    /// Remove a tab at the given 0-based index.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `bool`.
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


// ── RadioButton ───────────────────────────────────────────────────────

/// A grouped radio button with mutually exclusive selection.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `text` — `String`. Display label next to the radio circle.
/// - `selected` — `bool`. Whether this radio button is currently selected.
/// - `group` — `String`. Group name — only one radio in a group can be selected.
#[derive(Debug, Clone)]
pub struct RadioButton {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Display label next to the radio circle.
    pub text: String,
    /// Whether this radio button is currently selected.
    pub selected: bool,
    /// Group name — only one radio in a group can be selected.
    pub group: String,
}

impl RadioButton {
    /// Create a new radio button.
    ///
    /// # Parameters
    /// - `text` — `impl Into<String>`. Label text.
    /// - `group` — `impl Into<String>`. Group name.
    ///
    /// # Returns
    /// `RadioButton`.
    pub fn new(text: impl Into<String>, group: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::RadioButton),
            text: text.into(),
            selected: false,
            group: group.into(),
        }
    }
}

// ── ScrollBar ─────────────────────────────────────────────────────────

/// A scroll bar for scrollable content areas.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `position` — `f32`. Current scroll position.
/// - `content_size` — `f32`. Total content size.
/// - `view_size` — `f32`. Visible viewport size.
/// - `vertical` — `bool`. Orientation.
#[derive(Debug, Clone)]
pub struct ScrollBar {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Current scroll position.
    pub position: f32,
    /// Total content size.
    pub content_size: f32,
    /// Visible viewport size.
    pub view_size: f32,
    /// Orientation.
    pub vertical: bool,
}

impl ScrollBar {
    /// Create a new scroll bar.
    ///
    /// # Parameters
    /// - `vertical` — `bool`. Orientation.
    ///
    /// # Returns
    /// `ScrollBar`.
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
