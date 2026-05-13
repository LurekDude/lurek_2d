use super::cell::DEFAULT_FG;
use super::terminal_state::{MAX_COLS, MAX_ROWS};
fn text_width(text: &str) -> usize {
    text.chars().count().max(1)
}
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)]
pub enum BorderStyle {
    #[default]
    Single,
    Double,
    Ascii,
}
impl BorderStyle {
    pub fn from_str_name(s: &str) -> Option<Self> {
        match s {
            "single" => Some(Self::Single),
            "double" => Some(Self::Double),
            "ascii" => Some(Self::Ascii),
            _ => None,
        }
    }
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Single => "single",
            Self::Double => "double",
            Self::Ascii => "ascii",
        }
    }
}
#[derive(Debug, Clone)]
pub struct WidgetBase {
    pub x: usize,
    pub y: usize,
    pub width: usize,
    pub height: usize,
    pub visible: bool,
    pub enabled: bool,
    pub tag: String,
}
impl WidgetBase {
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
    pub fn position_1based(&self) -> (usize, usize) {
        (self.x + 1, self.y + 1)
    }
    pub fn set_position_1based(&mut self, col: usize, row: usize) {
        self.x = col.saturating_sub(1);
        self.y = row.saturating_sub(1);
    }
}
#[derive(Debug, Clone)]
pub enum WidgetKind {
    Label {
        text: String,
        color: [f32; 4],
    },
    Button {
        text: String,
    },
    TextBox {
        text: String,
        max_length: usize,
        cursor_pos: usize,
    },
    List {
        items: Vec<String>,
        selected: Option<usize>,
        scroll_offset: usize,
    },
    Border {
        style: BorderStyle,
        title: String,
        color: [f32; 4],
    },
    Panel {
        children: Vec<usize>,
    },
}
#[derive(Debug, Clone)]
pub struct Widget {
    pub base: WidgetBase,
    pub kind: WidgetKind,
}
impl Widget {
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
    pub fn get_text(&self) -> Result<String, &'static str> {
        match &self.kind {
            WidgetKind::Label { text, .. }
            | WidgetKind::Button { text }
            | WidgetKind::TextBox { text, .. } => Ok(text.clone()),
            _ => Err("expected label, button, or text box"),
        }
    }
    pub fn set_color(&mut self, new_color: [f32; 4]) -> Result<(), &'static str> {
        match &mut self.kind {
            WidgetKind::Label { color, .. } | WidgetKind::Border { color, .. } => {
                *color = new_color;
                Ok(())
            }
            _ => Err("expected label or border"),
        }
    }
    pub fn get_color(&self) -> Result<[f32; 4], &'static str> {
        match &self.kind {
            WidgetKind::Label { color, .. } | WidgetKind::Border { color, .. } => Ok(*color),
            _ => Err("expected label or border"),
        }
    }
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
    pub fn get_max_length(&self) -> Result<usize, &'static str> {
        match &self.kind {
            WidgetKind::TextBox { max_length, .. } => Ok(*max_length),
            _ => Err("expected text box"),
        }
    }
    pub fn add_item(&mut self, item: String) -> Result<(), &'static str> {
        match &mut self.kind {
            WidgetKind::List { items, .. } => {
                items.push(item);
                Ok(())
            }
            _ => Err("expected list"),
        }
    }
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
    pub fn get_item_count(&self) -> Result<usize, &'static str> {
        match &self.kind {
            WidgetKind::List { items, .. } => Ok(items.len()),
            _ => Err("expected list"),
        }
    }
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
    pub fn get_selected_1based(&self) -> Result<Option<usize>, &'static str> {
        match &self.kind {
            WidgetKind::List { selected, .. } => Ok(selected.map(|v| v + 1)),
            _ => Err("expected list"),
        }
    }
    pub fn set_border_style(&mut self, new_style: BorderStyle) -> Result<(), &'static str> {
        match &mut self.kind {
            WidgetKind::Border { style, .. } => {
                *style = new_style;
                Ok(())
            }
            _ => Err("expected border"),
        }
    }
    pub fn get_border_style(&self) -> Result<BorderStyle, &'static str> {
        match &self.kind {
            WidgetKind::Border { style, .. } => Ok(*style),
            _ => Err("expected border"),
        }
    }
    pub fn set_title(&mut self, new_title: String) -> Result<(), &'static str> {
        match &mut self.kind {
            WidgetKind::Border { title, .. } => {
                *title = new_title;
                Ok(())
            }
            _ => Err("expected border"),
        }
    }
    pub fn get_title(&self) -> Result<String, &'static str> {
        match &self.kind {
            WidgetKind::Border { title, .. } => Ok(title.clone()),
            _ => Err("expected border"),
        }
    }
    pub fn is_button(&self) -> bool {
        matches!(self.kind, WidgetKind::Button { .. })
    }
    pub fn is_textbox(&self) -> bool {
        matches!(self.kind, WidgetKind::TextBox { .. })
    }
    pub fn is_list(&self) -> bool {
        matches!(self.kind, WidgetKind::List { .. })
    }
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
