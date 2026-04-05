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
}