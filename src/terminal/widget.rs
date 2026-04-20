//! Widget types for the terminal UI system.

use super::cell::DEFAULT_FG;
use super::terminal_state::{MAX_COLS, MAX_ROWS};

fn text_width(text: &str) -> usize {
    text.chars().count().max(1)
}

/// Line-drawing style for [`WidgetKind::Border`] widgets.
///
/// # Variants
/// - `Single` — Single-line box-drawing characters (default).
/// - `Double` — Double-line box-drawing characters.
/// - `Ascii` — Plain ASCII characters (`+`, `-`, `|`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)]
pub enum BorderStyle {
    /// Single-line box-drawing characters.
    #[default]
    Single,
    /// Double-line box-drawing characters.
    Double,
    /// Plain ASCII characters (`+`, `-`, `|`).
    Ascii,
}

impl BorderStyle {
    /// Parse a style name string.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Option<BorderStyle>`.
    pub fn from_str_name(s: &str) -> Option<Self> {
        match s {
            "single" => Some(Self::Single),
            "double" => Some(Self::Double),
            "ascii" => Some(Self::Ascii),
            _ => None,
        }
    }

    /// Return the lowercase style name.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Single => "single",
            Self::Double => "double",
            Self::Ascii => "ascii",
        }
    }
}

/// Shared base fields for all terminal widgets.
///
/// # Fields
/// - `x` — `usize`. Column position (0-based internal).
/// - `y` — `usize`. Row position (0-based internal).
/// - `width` — `usize`. Width in cells.
/// - `height` — `usize`. Height in cells.
/// - `visible` — `bool`. Whether the widget is drawn.
/// - `enabled` — `bool`. Whether the widget accepts input.
/// - `tag` — `String`. Free-form identification tag.
#[derive(Debug, Clone)]
pub struct WidgetBase {
    /// Column position (0-based internal storage).
    pub x: usize,
    /// Row position (0-based internal storage).
    pub y: usize,
    /// Width in cells.
    pub width: usize,
    /// Height in cells.
    pub height: usize,
    /// Whether the widget is drawn.
    pub visible: bool,
    /// Whether the widget accepts input.
    pub enabled: bool,
    /// Free-form identification tag.
    pub tag: String,
}

impl WidgetBase {
    /// Create a new widget base with the given position and size.
    ///
    /// # Parameters
    /// - `x` — `usize`. Column (0-based).
    /// - `y` — `usize`. Row (0-based).
    /// - `width` — `usize`. Width in cells.
    /// - `height` — `usize`. Height in cells.
    ///
    /// # Returns
    /// `WidgetBase`.
    pub fn new(x: usize, y: usize, width: usize, height: usize) -> Self {
        Self {
            x,
            y,
            width,
            height,
            visible: true,
            enabled: true,
            tag: String::new(),
        }
    }

    /// Get the widget position as 1-based coordinates.
    ///
    /// # Returns
    /// `(usize, usize)`.
    pub fn position_1based(&self) -> (usize, usize) {
        (self.x + 1, self.y + 1)
    }

    /// Set the widget position from 1-based coordinates.
    ///
    /// # Parameters
    /// - `col` — `usize`. 1-based column.
    /// - `row` — `usize`. 1-based row.
    pub fn set_position_1based(&mut self, col: usize, row: usize) {
        self.x = col.saturating_sub(1);
        self.y = row.saturating_sub(1);
    }
}

/// Concrete widget type discriminant.
///
/// # Variants
/// - `Label` — Static or dynamic text label.
/// - `Button` — Clickable button.
/// - `TextBox` — Editable single-line text input.
/// - `List` — Scrollable list of selectable items.
/// - `Border` — Decorative border frame with optional title.
/// - `Panel` — Container that groups child widgets.
#[derive(Debug, Clone)]
pub enum WidgetKind {
    /// Static or dynamic text label.
    Label {
        /// Display text.
        text: String,
        /// Text colour (RGBA).
        color: [f32; 4],
    },
    /// Clickable button.
    Button {
        /// Button label text.
        text: String,
    },
    /// Editable single-line text input.
    TextBox {
        /// Current text content.
        text: String,
        /// Maximum character count (0 = unlimited).
        max_length: usize,
        /// Cursor position within the text, measured in characters.
        cursor_pos: usize,
    },
    /// Scrollable list of selectable items.
    List {
        /// Item strings.
        items: Vec<String>,
        /// Currently selected item index (0-based), if any.
        selected: Option<usize>,
        /// Scroll offset for the visible window.
        scroll_offset: usize,
    },
    /// Decorative border frame with optional title.
    Border {
        /// Line-drawing style.
        style: BorderStyle,
        /// Title text displayed in the top border.
        title: String,
        /// Border colour (RGBA).
        color: [f32; 4],
    },
    /// Container that groups child widgets by terminal index.
    Panel {
        /// Indices into the parent terminal's widget list.
        children: Vec<usize>,
    },
}

/// A terminal widget combining shared [`WidgetBase`] fields with a concrete
/// [`WidgetKind`] variant.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared position, size, visibility, and tag.
/// - `kind` — `WidgetKind`. Type-specific data.
#[derive(Debug, Clone)]
pub struct Widget {
    /// Shared position, size, visibility, and tag.
    pub base: WidgetBase,
    /// Type-specific data.
    pub kind: WidgetKind,
}

impl Widget {
    /// Create a new label widget.
    ///
    /// # Parameters
    /// - `col` — `usize`. 1-based column.
    /// - `row` — `usize`. 1-based row.
    /// - `text` — `impl Into<String>`.
    ///
    /// # Returns
    /// `Widget`.
    pub fn new_label(col: usize, row: usize, text: impl Into<String>) -> Self {
        let text = text.into();
        Self {
            base: WidgetBase::new(
                col.saturating_sub(1),
                row.saturating_sub(1),
                text_width(&text),
                1,
            ),
            kind: WidgetKind::Label {
                text,
                color: DEFAULT_FG,
            },
        }
    }

    /// Create a new button widget.
    ///
    /// # Parameters
    /// - `col` — `usize`. 1-based column.
    /// - `row` — `usize`. 1-based row.
    /// - `width` — `usize`. Width in cells.
    /// - `height` — `usize`. Height in cells.
    /// - `text` — `impl Into<String>`.
    ///
    /// # Returns
    /// `Widget`.
    pub fn new_button(
        col: usize,
        row: usize,
        width: usize,
        height: usize,
        text: impl Into<String>,
    ) -> Self {
        Self {
            base: WidgetBase::new(
                col.saturating_sub(1),
                row.saturating_sub(1),
                width.clamp(1, MAX_COLS),
                height.clamp(1, MAX_ROWS),
            ),
            kind: WidgetKind::Button { text: text.into() },
        }
    }

    /// Create a new text box widget.
    ///
    /// # Parameters
    /// - `col` — `usize`. 1-based column.
    /// - `row` — `usize`. 1-based row.
    /// - `width` — `usize`. Width in cells.
    ///
    /// # Returns
    /// `Widget`.
    pub fn new_text_box(col: usize, row: usize, width: usize) -> Self {
        Self {
            base: WidgetBase::new(
                col.saturating_sub(1),
                row.saturating_sub(1),
                width.clamp(1, MAX_COLS),
                1,
            ),
            kind: WidgetKind::TextBox {
                text: String::new(),
                max_length: 0,
                cursor_pos: 0,
            },
        }
    }

    /// Create a new list widget.
    ///
    /// # Parameters
    /// - `col` — `usize`. 1-based column.
    /// - `row` — `usize`. 1-based row.
    /// - `width` — `usize`. Width in cells.
    /// - `height` — `usize`. Height in cells.
    ///
    /// # Returns
    /// `Widget`.
    pub fn new_list(col: usize, row: usize, width: usize, height: usize) -> Self {
        Self {
            base: WidgetBase::new(
                col.saturating_sub(1),
                row.saturating_sub(1),
                width.clamp(1, MAX_COLS),
                height.clamp(1, MAX_ROWS),
            ),
            kind: WidgetKind::List {
                items: Vec::new(),
                selected: None,
                scroll_offset: 0,
            },
        }
    }

    /// Create a new border widget.
    ///
    /// # Parameters
    /// - `col` — `usize`. 1-based column.
    /// - `row` — `usize`. 1-based row.
    /// - `width` — `usize`. Width in cells.
    /// - `height` — `usize`. Height in cells.
    ///
    /// # Returns
    /// `Widget`.
    pub fn new_border(col: usize, row: usize, width: usize, height: usize) -> Self {
        Self {
            base: WidgetBase::new(
                col.saturating_sub(1),
                row.saturating_sub(1),
                width.clamp(1, MAX_COLS),
                height.clamp(1, MAX_ROWS),
            ),
            kind: WidgetKind::Border {
                style: BorderStyle::default(),
                title: String::new(),
                color: DEFAULT_FG,
            },
        }
    }

    /// Create a new panel widget.
    ///
    /// # Parameters
    /// - `col` — `usize`. 1-based column.
    /// - `row` — `usize`. 1-based row.
    /// - `width` — `usize`. Width in cells.
    /// - `height` — `usize`. Height in cells.
    ///
    /// # Returns
    /// `Widget`.
    pub fn new_panel(col: usize, row: usize, width: usize, height: usize) -> Self {
        Self {
            base: WidgetBase::new(
                col.saturating_sub(1),
                row.saturating_sub(1),
                width.clamp(1, MAX_COLS),
                height.clamp(1, MAX_ROWS),
            ),
            kind: WidgetKind::Panel {
                children: Vec::new(),
            },
        }
    }

    // ── Kind-specific mutation methods ──────────────────────────────────────

    /// Set the text content of a label, button, or text box widget.
    ///
    /// For text boxes, the text is truncated to `max_length` if set.
    /// Returns `true` if the text actually changed (useful for triggering
    /// change callbacks on text boxes).
    ///
    /// # Parameters
    /// - `new_text` — `String`.
    ///
    /// # Returns
    /// `Result<bool, &'static str>`.
    pub fn set_text(&mut self, new_text: String) -> Result<bool, &'static str> {
        match &mut self.kind {
            WidgetKind::Label { text, .. } => {
                *text = new_text;
                self.base.width = text_width(text);
                Ok(false)
            }
            WidgetKind::Button { text } => {
                *text = new_text;
                Ok(false)
            }
            WidgetKind::TextBox {
                text,
                max_length,
                cursor_pos,
            } => {
                let final_text = if *max_length > 0 {
                    new_text.chars().take(*max_length).collect()
                } else {
                    new_text
                };
                let changed = *text != final_text;
                *text = final_text;
                *cursor_pos = text.chars().count();
                Ok(changed)
            }
            _ => Err("expected label, button, or text box"),
        }
    }

    /// Get the text content of a label, button, or text box widget.
    ///
    /// # Returns
    /// `Result<String, &'static str>`.
    pub fn get_text(&self) -> Result<String, &'static str> {
        match &self.kind {
            WidgetKind::Label { text, .. }
            | WidgetKind::Button { text }
            | WidgetKind::TextBox { text, .. } => Ok(text.clone()),
            _ => Err("expected label, button, or text box"),
        }
    }

    /// Set the colour of a label or border widget.
    ///
    /// # Parameters
    /// - `new_color` — `[f32; 4]`.
    ///
    /// # Returns
    /// `Result<(), &'static str>`.
    pub fn set_color(&mut self, new_color: [f32; 4]) -> Result<(), &'static str> {
        match &mut self.kind {
            WidgetKind::Label { color, .. } | WidgetKind::Border { color, .. } => {
                *color = new_color;
                Ok(())
            }
            _ => Err("expected label or border"),
        }
    }

    /// Get the colour of a label or border widget.
    ///
    /// # Returns
    /// `Result<[f32; 4], &'static str>`.
    pub fn get_color(&self) -> Result<[f32; 4], &'static str> {
        match &self.kind {
            WidgetKind::Label { color, .. } | WidgetKind::Border { color, .. } => Ok(*color),
            _ => Err("expected label or border"),
        }
    }

    /// Set the maximum character length of a text box widget.
    ///
    /// If the current text exceeds the new limit it is truncated.
    ///
    /// # Parameters
    /// - `max` — `usize`.
    ///
    /// # Returns
    /// `Result<(), &'static str>`.
    pub fn set_max_length(&mut self, max: usize) -> Result<(), &'static str> {
        match &mut self.kind {
            WidgetKind::TextBox {
                text,
                max_length,
                cursor_pos,
            } => {
                *max_length = max;
                if *max_length > 0 && text.chars().count() > *max_length {
                    *text = text.chars().take(*max_length).collect();
                }
                *cursor_pos = (*cursor_pos).min(text.chars().count());
                Ok(())
            }
            _ => Err("expected text box"),
        }
    }

    /// Get the maximum character length of a text box widget.
    ///
    /// # Returns
    /// `Result<usize, &'static str>`.
    pub fn get_max_length(&self) -> Result<usize, &'static str> {
        match &self.kind {
            WidgetKind::TextBox { max_length, .. } => Ok(*max_length),
            _ => Err("expected text box"),
        }
    }

    /// Add an item to a list widget.
    ///
    /// # Parameters
    /// - `item` — `String`.
    ///
    /// # Returns
    /// `Result<(), &'static str>`.
    pub fn add_item(&mut self, item: String) -> Result<(), &'static str> {
        match &mut self.kind {
            WidgetKind::List { items, .. } => {
                items.push(item);
                Ok(())
            }
            _ => Err("expected list"),
        }
    }

    /// Remove an item from a list widget by 1-based index.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Result<(), &'static str>`.
    pub fn remove_item_1based(&mut self, index: usize) -> Result<(), &'static str> {
        match &mut self.kind {
            WidgetKind::List {
                items,
                selected,
                scroll_offset,
            } => {
                if index >= 1 && index <= items.len() {
                    items.remove(index - 1);
                    if let Some(current) = *selected {
                        if current == index - 1 {
                            *selected = None;
                        } else if current > index - 1 {
                            *selected = Some(current - 1);
                        }
                    }
                    if *scroll_offset > items.len().saturating_sub(1) {
                        *scroll_offset = items.len().saturating_sub(1);
                    }
                }
                Ok(())
            }
            _ => Err("expected list"),
        }
    }

    /// Remove all items from a list widget.
    ///
    /// # Returns
    /// `Result<(), &'static str>`.
    pub fn clear_items(&mut self) -> Result<(), &'static str> {
        match &mut self.kind {
            WidgetKind::List {
                items,
                selected,
                scroll_offset,
            } => {
                items.clear();
                *selected = None;
                *scroll_offset = 0;
                Ok(())
            }
            _ => Err("expected list"),
        }
    }

    /// Get the number of items in a list widget.
    ///
    /// # Returns
    /// `Result<usize, &'static str>`.
    pub fn get_item_count(&self) -> Result<usize, &'static str> {
        match &self.kind {
            WidgetKind::List { items, .. } => Ok(items.len()),
            _ => Err("expected list"),
        }
    }

    /// Get an item from a list widget by 1-based index.
    ///
    /// Returns an empty string if the index is out of range.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Result<String, &'static str>`.
    pub fn get_item_1based(&self, index: usize) -> Result<String, &'static str> {
        match &self.kind {
            WidgetKind::List { items, .. } => {
                if index >= 1 && index <= items.len() {
                    Ok(items[index - 1].clone())
                } else {
                    Ok(String::new())
                }
            }
            _ => Err("expected list"),
        }
    }

    /// Set the selected item in a list widget by 1-based index.
    ///
    /// Returns `true` if the selection actually changed.
    ///
    /// # Parameters
    /// - `index` — `Option<usize>`.
    ///
    /// # Returns
    /// `Result<bool, &'static str>`.
    pub fn set_selected_1based(&mut self, index: Option<usize>) -> Result<bool, &'static str> {
        match &mut self.kind {
            WidgetKind::List {
                items,
                selected,
                scroll_offset,
            } => {
                let new_selected = index.and_then(|v| {
                    if v >= 1 && v <= items.len() {
                        Some(v - 1)
                    } else {
                        None
                    }
                });
                let changed = *selected != new_selected;
                *selected = new_selected;
                if let Some(current) = *selected {
                    if current < *scroll_offset {
                        *scroll_offset = current;
                    }
                }
                Ok(changed)
            }
            _ => Err("expected list"),
        }
    }

    /// Get the selected item index (1-based) in a list widget.
    ///
    /// # Returns
    /// `Result<Option<usize>, &'static str>`.
    pub fn get_selected_1based(&self) -> Result<Option<usize>, &'static str> {
        match &self.kind {
            WidgetKind::List { selected, .. } => Ok(selected.map(|v| v + 1)),
            _ => Err("expected list"),
        }
    }

    /// Set the border style of a border widget.
    ///
    /// # Parameters
    /// - `new_style` — `BorderStyle`.
    ///
    /// # Returns
    /// `Result<(), &'static str>`.
    pub fn set_border_style(&mut self, new_style: BorderStyle) -> Result<(), &'static str> {
        match &mut self.kind {
            WidgetKind::Border { style, .. } => {
                *style = new_style;
                Ok(())
            }
            _ => Err("expected border"),
        }
    }

    /// Get the border style of a border widget.
    ///
    /// # Returns
    /// `Result<BorderStyle, &'static str>`.
    pub fn get_border_style(&self) -> Result<BorderStyle, &'static str> {
        match &self.kind {
            WidgetKind::Border { style, .. } => Ok(*style),
            _ => Err("expected border"),
        }
    }

    /// Set the title of a border widget.
    ///
    /// # Parameters
    /// - `new_title` — `String`.
    ///
    /// # Returns
    /// `Result<(), &'static str>`.
    pub fn set_title(&mut self, new_title: String) -> Result<(), &'static str> {
        match &mut self.kind {
            WidgetKind::Border { title, .. } => {
                *title = new_title;
                Ok(())
            }
            _ => Err("expected border"),
        }
    }

    /// Get the title of a border widget.
    ///
    /// # Returns
    /// `Result<String, &'static str>`.
    pub fn get_title(&self) -> Result<String, &'static str> {
        match &self.kind {
            WidgetKind::Border { title, .. } => Ok(title.clone()),
            _ => Err("expected border"),
        }
    }

    /// Check if this widget is a button.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_button(&self) -> bool {
        matches!(self.kind, WidgetKind::Button { .. })
    }

    /// Check if this widget is a text box.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_textbox(&self) -> bool {
        matches!(self.kind, WidgetKind::TextBox { .. })
    }

    /// Check if this widget is a list.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_list(&self) -> bool {
        matches!(self.kind, WidgetKind::List { .. })
    }

    /// Check if this widget is a panel.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_panel(&self) -> bool {
        matches!(self.kind, WidgetKind::Panel { .. })
    }
}
