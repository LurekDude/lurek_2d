//! Widget primitives for the terminal UI layer. Owns `Widget`, `WidgetBase`,
//! `WidgetKind`, and `BorderStyle`. Does not own input dispatch or rendering;
//! those are handled by `terminal_state` and `render`. Depends on `cell` constants
//! and the `MAX_COLS`/`MAX_ROWS` grid caps.

use super::cell::DEFAULT_FG;
use super::terminal_state::{MAX_COLS, MAX_ROWS};

/// Return the display width in characters for `text`, always at least 1.
fn text_width(text: &str) -> usize {
    text.chars().count().max(1)
}

/// Border drawing style used by `WidgetKind::Border`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)]
pub enum BorderStyle {
    /// Box-drawing single lines: ┌─┐│└┘.
    #[default]
    Single,
    /// Box-drawing double lines: ╔═╗║╚╝.
    Double,
    /// ASCII fallback: +-|.
    Ascii,
}
impl BorderStyle {
    /// Parse a lowercase style name and return the matching variant, or `None` for unknown names.
    pub fn from_str_name(s: &str) -> Option<Self> {
        match s {
            "single" => Some(Self::Single),
            "double" => Some(Self::Double),
            "ascii" => Some(Self::Ascii),
            _ => None,
        }
    }
    /// Return the canonical lowercase string name for this style.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Single => "single",
            Self::Double => "double",
            Self::Ascii => "ascii",
        }
    }
}
/// Layout and shared state common to all widget kinds.
#[derive(Debug, Clone)]
pub struct WidgetBase {
    /// Zero-based column of the widget's top-left corner.
    pub x: usize,
    /// Zero-based row of the widget's top-left corner.
    pub y: usize,
    /// Width of the widget in character cells.
    pub width: usize,
    /// Height of the widget in character cells.
    pub height: usize,
    /// When `false` the widget is not rendered.
    pub visible: bool,
    /// When `false` the widget ignores input events.
    pub enabled: bool,
    /// Caller-supplied tag string for `find_by_tag` lookup.
    pub tag: String,
}
impl WidgetBase {
    /// Create a new `WidgetBase` at zero-based position derived from 1-based `(col, row)` with given pixel-grid size.
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
    /// Return the widget position as 1-based `(col, row)`.
    pub fn position_1based(&self) -> (usize, usize) {
        (self.x + 1, self.y + 1)
    }

    /// Move the widget to 1-based `(col, row)`.
    pub fn set_position_1based(&mut self, col: usize, row: usize) {
        self.x = col.saturating_sub(1);
        self.y = row.saturating_sub(1);
    }
}
/// The type-specific data for a `Widget`.
#[derive(Debug, Clone)]
pub enum WidgetKind {
    /// Static text rendered with a given color.
    Label {
        /// Display string.
        text: String,
        /// RGBA foreground color.
        color: [f32; 4],
    },
    /// Clickable button with centered label text.
    Button {
        /// Label shown inside the button bounds.
        text: String,
    },
    /// Single-line text input with optional length cap and cursor.
    TextBox {
        /// Current text content.
        text: String,
        /// Maximum character count; 0 means unlimited.
        max_length: usize,
        /// Char-index cursor position within `text`.
        cursor_pos: usize,
    },
    /// Scrollable item list with optional selection.
    List {
        /// All list items in display order.
        items: Vec<String>,
        /// Zero-based selected item index, or `None` when nothing is selected.
        selected: Option<usize>,
        /// Zero-based index of the first visible item.
        scroll_offset: usize,
    },
    /// Decorative border frame with optional title.
    Border {
        /// Line-drawing style.
        style: BorderStyle,
        /// Title string written in the top border row; empty means no title.
        title: String,
        /// RGBA color for the border and title characters.
        color: [f32; 4],
    },
    /// Invisible grouping widget that holds child widget indices.
    Panel {
        /// Indices of child widgets owned by this panel.
        children: Vec<usize>,
    },
}
/// A positioned, typed UI widget rendered over the `Terminal` cell grid.
#[derive(Debug, Clone)]
pub struct Widget {
    /// Shared layout and visibility state.
    pub base: WidgetBase,
    /// Type-specific widget data.
    pub kind: WidgetKind,
}
impl Widget {
    /// Create a `Label` widget at 1-based `(col, row)` with auto-sized width.
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
    /// Create a `Button` widget at 1-based `(col, row)` with explicit `width`/`height`.
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
    /// Create a single-row `TextBox` widget at 1-based `(col, row)` with given `width`.
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
    /// Create a `List` widget at 1-based `(col, row)` with explicit `width`/`height`.
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
    /// Create a `Border` widget at 1-based `(col, row)` with explicit `width`/`height`.
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
    /// Create a `Panel` grouping widget at 1-based `(col, row)` with explicit `width`/`height`.
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
    /// Set the display text for `Label`, `Button`, or `TextBox`; returns `Ok(true)` when the `TextBox` content changed.
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
    /// Return the display text for `Label`, `Button`, or `TextBox`; errors on other kinds.
    pub fn get_text(&self) -> Result<String, &'static str> {
        match &self.kind {
            WidgetKind::Label { text, .. }
            | WidgetKind::Button { text }
            | WidgetKind::TextBox { text, .. } => Ok(text.clone()),
            _ => Err("expected label, button, or text box"),
        }
    }
    /// Set the foreground color on `Label` or `Border`; errors on other kinds.
    pub fn set_color(&mut self, new_color: [f32; 4]) -> Result<(), &'static str> {
        match &mut self.kind {
            WidgetKind::Label { color, .. } | WidgetKind::Border { color, .. } => {
                *color = new_color;
                Ok(())
            }
            _ => Err("expected label or border"),
        }
    }
    /// Return the foreground color of `Label` or `Border`; errors on other kinds.
    pub fn get_color(&self) -> Result<[f32; 4], &'static str> {
        match &self.kind {
            WidgetKind::Label { color, .. } | WidgetKind::Border { color, .. } => Ok(*color),
            _ => Err("expected label or border"),
        }
    }
    /// Set the character cap on a `TextBox` and truncate current text and cursor if needed; errors on other kinds.
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
    /// Return the character cap for a `TextBox`; errors on other kinds.
    pub fn get_max_length(&self) -> Result<usize, &'static str> {
        match &self.kind {
            WidgetKind::TextBox { max_length, .. } => Ok(*max_length),
            _ => Err("expected text box"),
        }
    }
    /// Append `item` to the `List`; errors on other kinds.
    pub fn add_item(&mut self, item: String) -> Result<(), &'static str> {
        match &mut self.kind {
            WidgetKind::List { items, .. } => {
                items.push(item);
                Ok(())
            }
            _ => Err("expected list"),
        }
    }
    /// Remove the item at 1-based `index` from a `List`, adjusting selection and scroll; errors on other kinds.
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
    /// Remove all items from a `List` and reset selection and scroll; errors on other kinds.
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
    /// Return the item count for a `List`; errors on other kinds.
    pub fn get_item_count(&self) -> Result<usize, &'static str> {
        match &self.kind {
            WidgetKind::List { items, .. } => Ok(items.len()),
            _ => Err("expected list"),
        }
    }
    /// Return the item text at 1-based `index` from a `List`; returns empty string when index is out of range; errors on other kinds.
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
    /// Set the 1-based selected index on a `List`, clamping scroll to keep it visible; returns `Ok(true)` when selection changed; errors on other kinds.
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
    /// Return the 1-based selected index for a `List`, or `None`; errors on other kinds.
    pub fn get_selected_1based(&self) -> Result<Option<usize>, &'static str> {
        match &self.kind {
            WidgetKind::List { selected, .. } => Ok(selected.map(|v| v + 1)),
            _ => Err("expected list"),
        }
    }
    /// Set the border line style on a `Border` widget; errors on other kinds.
    pub fn set_border_style(&mut self, new_style: BorderStyle) -> Result<(), &'static str> {
        match &mut self.kind {
            WidgetKind::Border { style, .. } => {
                *style = new_style;
                Ok(())
            }
            _ => Err("expected border"),
        }
    }
    /// Return the border line style of a `Border` widget; errors on other kinds.
    pub fn get_border_style(&self) -> Result<BorderStyle, &'static str> {
        match &self.kind {
            WidgetKind::Border { style, .. } => Ok(*style),
            _ => Err("expected border"),
        }
    }
    /// Set the title string on a `Border` widget; errors on other kinds.
    pub fn set_title(&mut self, new_title: String) -> Result<(), &'static str> {
        match &mut self.kind {
            WidgetKind::Border { title, .. } => {
                *title = new_title;
                Ok(())
            }
            _ => Err("expected border"),
        }
    }
    /// Return the title string of a `Border` widget; errors on other kinds.
    pub fn get_title(&self) -> Result<String, &'static str> {
        match &self.kind {
            WidgetKind::Border { title, .. } => Ok(title.clone()),
            _ => Err("expected border"),
        }
    }
    /// Return `true` when this widget is a `Button`.
    pub fn is_button(&self) -> bool {
        matches!(self.kind, WidgetKind::Button { .. })
    }

    /// Return `true` when this widget is a `TextBox`.
    pub fn is_textbox(&self) -> bool {
        matches!(self.kind, WidgetKind::TextBox { .. })
    }

    /// Return `true` when this widget is a `List`.
    pub fn is_list(&self) -> bool {
        matches!(self.kind, WidgetKind::List { .. })
    }

    /// Return `true` when this widget is a `Panel`.
    pub fn is_panel(&self) -> bool {
        matches!(self.kind, WidgetKind::Panel { .. })
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn border_style_roundtrip() {
        for name in &["single", "double", "ascii"] {
            let bs = BorderStyle::from_str_name(name).unwrap();
            assert_eq!(bs.as_str(), *name);
        }
    }
    #[test]
    fn border_style_unknown_returns_none() {
        assert!(BorderStyle::from_str_name("dashed").is_none());
    }
    #[test]
    fn widget_base_position_1based_roundtrip() {
        let mut base = WidgetBase::new(4, 9, 20, 15);
        assert_eq!(base.position_1based(), (5, 10));
        base.set_position_1based(3, 7);
        assert_eq!(base.x, 2);
        assert_eq!(base.y, 6);
    }
    #[test]
    fn widget_new_label() {
        let w = Widget::new_label(1, 1, "Hello");
        assert!(matches!(w.kind, WidgetKind::Label { .. }));
        assert_eq!(w.get_text().unwrap(), "Hello".to_string());
    }
    #[test]
    fn widget_new_button() {
        let w = Widget::new_button(1, 1, 5, 1, "OK");
        assert!(w.is_button());
    }
    #[test]
    fn widget_set_text() {
        let mut w = Widget::new_label(1, 1, "A");
        w.set_text("B".to_string()).unwrap();
        assert_eq!(w.get_text().unwrap(), "B".to_string());
    }
    #[test]
    fn widget_list_add_and_count() {
        let mut w = Widget::new_list(1, 1, 10, 5);
        w.add_item("alpha".to_string()).unwrap();
        w.add_item("beta".to_string()).unwrap();
        assert_eq!(w.get_item_count().unwrap(), 2);
        assert_eq!(w.get_item_1based(1).unwrap(), "alpha".to_string());
    }
    #[test]
    fn widget_is_type_checks() {
        let btn = Widget::new_button(1, 1, 5, 1, "X");
        assert!(btn.is_button());
        assert!(!btn.is_textbox());
        assert!(!btn.is_list());
        assert!(!btn.is_panel());
    }
}
