//! Integration tests for the `terminal` module (grid-based terminal emulator).
//!
//! Covers: `TCell`, `Terminal`, `WidgetBase`, `WidgetKind`, `Widget`,
//! and `BorderStyle`. All tests are purely in-memory — no GPU, no window.

use lurek2d::terminal::{BorderStyle, TCell, Terminal, Widget, WidgetBase, WidgetKind};

fn assert_color_near(actual: [f32; 4], expected: [f32; 4]) {
    for (index, (actual, expected)) in actual.iter().zip(expected.iter()).enumerate() {
        assert!(
            (*actual - *expected).abs() < 1e-5,
            "component {index} expected {expected}, got {actual}"
        );
    }
}

// TCell defaults

#[test]
fn terminal_default_cell_values() {
    let cell = TCell::default();
    assert_eq!(cell.ch, b' ' as u32, "default char should be space");
    assert!((cell.fg[0] - 1.0).abs() < 1e-5, "fg.r should be 1.0");
    assert!((cell.fg[1] - 1.0).abs() < 1e-5, "fg.g should be 1.0");
    assert!((cell.fg[2] - 1.0).abs() < 1e-5, "fg.b should be 1.0");
    assert!((cell.fg[3] - 1.0).abs() < 1e-5, "fg.a should be 1.0");
    assert!((cell.bg[0] - 0.0).abs() < 1e-5, "bg.r should be 0.0");
    assert!((cell.bg[1] - 0.0).abs() < 1e-5, "bg.g should be 0.0");
    assert!((cell.bg[2] - 0.0).abs() < 1e-5, "bg.b should be 0.0");
    assert!((cell.bg[3] - 0.0).abs() < 1e-5, "bg.a should be 0.0");
}

// Terminal construction

#[test]
fn terminal_new_default_dimensions() {
    let t = Terminal::new(80, 25);
    let (cols, rows) = t.get_dimensions();
    assert_eq!(cols, 80);
    assert_eq!(rows, 25);
}

#[test]
fn terminal_new_clamped_dimensions() {
    let t = Terminal::new(1000, 500);
    let (cols, rows) = t.get_dimensions();
    assert!(cols <= 512, "cols should be clamped to 512, got {cols}");
    assert!(rows <= 256, "rows should be clamped to 256, got {rows}");

    let t = Terminal::new(0, 0);
    let (cols, rows) = t.get_dimensions();
    assert!(cols >= 1, "cols should be at least 1, got {cols}");
    assert!(rows >= 1, "rows should be at least 1, got {rows}");
}

#[test]
fn terminal_default_is_80x40() {
    let t = Terminal::default();
    assert_eq!(t.get_dimensions(), (80, 40));
}

// Terminal cell operations

#[test]
fn terminal_set_get_cell() {
    let mut t = Terminal::new(10, 10);
    let fg = [1.0, 0.0, 0.0, 1.0];
    let bg = [0.0, 0.0, 1.0, 0.5];
    t.set(1, 1, b'@' as u32, fg, bg);

    let cell = t.get(1, 1);
    assert_eq!(cell.ch, b'@' as u32);
    assert!((cell.fg[0] - 1.0).abs() < 1e-5);
    assert!((cell.fg[1] - 0.0).abs() < 1e-5);
    assert!((cell.bg[2] - 1.0).abs() < 1e-5);
    assert!((cell.bg[3] - 0.5).abs() < 1e-5);
}

#[test]
fn terminal_set_out_of_bounds_ignored() {
    let mut t = Terminal::new(5, 5);
    let fg = [1.0; 4];
    let bg = [0.0; 4];
    t.set(0, 0, b'X' as u32, fg, bg);
    t.set(100, 100, b'Y' as u32, fg, bg);
    let cell_00 = t.get(0, 0);
    assert_eq!(cell_00, TCell::default());
    let cell_oob = t.get(100, 100);
    assert_eq!(cell_oob, TCell::default());
}

#[test]
fn terminal_clear_resets_cells() {
    let mut t = Terminal::new(5, 5);
    let fg = [1.0, 0.0, 0.0, 1.0];
    let bg = [0.0, 1.0, 0.0, 1.0];
    t.set(1, 1, b'A' as u32, fg, bg);
    t.set(3, 3, b'B' as u32, fg, bg);
    t.clear();
    for row in 1..=5 {
        for col in 1..=5 {
            assert_eq!(t.get(col, row), TCell::default());
        }
    }
}

#[test]
fn terminal_try_get_respects_bounds() {
    let t = Terminal::new(3, 2);

    assert_eq!(t.try_get(1, 1), Some(TCell::default()));
    assert_eq!(t.try_get(3, 2), Some(TCell::default()));
    assert_eq!(t.try_get(0, 1), None);
    assert_eq!(t.try_get(1, 0), None);
    assert_eq!(t.try_get(4, 2), None);
    assert_eq!(t.try_get(3, 3), None);
}

#[test]
fn terminal_set_char_preserves_existing_colors() {
    let mut t = Terminal::new(2, 2);
    let fg = [0.2, 0.3, 0.4, 1.0];
    let bg = [0.5, 0.6, 0.7, 0.8];

    t.set(1, 1, b'A' as u32, fg, bg);
    t.set_char(1, 1, b'Z' as u32);

    let cell = t.get(1, 1);
    assert_eq!(cell.ch, b'Z' as u32);
    assert_color_near(cell.fg, fg);
    assert_color_near(cell.bg, bg);
}

#[test]
fn terminal_set_fg_preserves_character_and_background() {
    let mut t = Terminal::new(2, 2);
    let initial_fg = [0.2, 0.3, 0.4, 1.0];
    let bg = [0.5, 0.6, 0.7, 0.8];
    let updated_fg = [0.9, 0.1, 0.2, 0.7];

    t.set(1, 1, b'Q' as u32, initial_fg, bg);
    t.set_fg(1, 1, updated_fg);

    let cell = t.get(1, 1);
    assert_eq!(cell.ch, b'Q' as u32);
    assert_color_near(cell.fg, updated_fg);
    assert_color_near(cell.bg, bg);
}

#[test]
fn terminal_set_bg_preserves_character_and_foreground() {
    let mut t = Terminal::new(2, 2);
    let fg = [0.2, 0.3, 0.4, 1.0];
    let initial_bg = [0.5, 0.6, 0.7, 0.8];
    let updated_bg = [0.1, 0.2, 0.3, 0.9];

    t.set(1, 1, b'Q' as u32, fg, initial_bg);
    t.set_bg(1, 1, updated_bg);

    let cell = t.get(1, 1);
    assert_eq!(cell.ch, b'Q' as u32);
    assert_color_near(cell.fg, fg);
    assert_color_near(cell.bg, updated_bg);
}

#[test]
fn terminal_print_writes_utf8_chars_and_clips_at_right_edge() {
    let mut t = Terminal::new(5, 2);

    t.print(4, 1, "é界X");

    assert_eq!(t.get(4, 1).ch, 'é' as u32);
    assert_eq!(t.get(5, 1).ch, '界' as u32);
    assert_eq!(t.get(3, 1), TCell::default());
    assert_eq!(t.get(1, 2), TCell::default(), "print should not wrap");
}

// Terminal cursor

#[test]
fn terminal_cursor_default_and_set() {
    let mut t = Terminal::new(10, 10);
    assert_eq!(t.get_cursor(), (1, 1));
    t.set_cursor(5, 3);
    assert_eq!(t.get_cursor(), (5, 3));
    t.set_cursor(100, 100);
    assert_eq!(t.get_cursor(), (10, 10));
}

#[test]
fn terminal_resize_preserves_overlap_and_defaults_new_cells() {
    let mut t = Terminal::new(3, 2);
    let fg = [0.3, 0.4, 0.5, 1.0];
    let bg = [0.1, 0.2, 0.3, 0.4];

    t.set(1, 1, b'A' as u32, fg, bg);
    t.set(3, 2, b'B' as u32, fg, bg);
    t.resize(5, 4);

    assert_eq!(t.get_dimensions(), (5, 4));
    assert_eq!(t.get(1, 1).ch, b'A' as u32);
    assert_eq!(t.get(3, 2).ch, b'B' as u32);
    assert_eq!(t.get(5, 4), TCell::default());
    assert_eq!(t.try_get(5, 4), Some(TCell::default()));
}

#[test]
fn terminal_resize_shrink_clamps_cursor_and_discards_outside_cells() {
    let mut t = Terminal::new(5, 4);
    let fg = [0.9, 0.8, 0.7, 1.0];
    let bg = [0.1, 0.2, 0.3, 0.4];

    t.set(3, 2, b'K' as u32, fg, bg);
    t.set(5, 4, b'Z' as u32, fg, bg);
    t.set_cursor(5, 4);
    t.resize(3, 2);

    assert_eq!(t.get_dimensions(), (3, 2));
    assert_eq!(t.get_cursor(), (3, 2));
    assert_eq!(t.get(3, 2).ch, b'K' as u32);
    assert_eq!(t.try_get(5, 4), None);
}

// BorderStyle

#[test]
fn widget_border_styles() {
    for (name, style) in [
        ("single", BorderStyle::Single),
        ("double", BorderStyle::Double),
        ("ascii", BorderStyle::Ascii),
    ] {
        assert_eq!(BorderStyle::from_str_name(name), Some(style));
        assert_eq!(style.as_str(), name);
    }
    assert_eq!(BorderStyle::from_str_name("invalid"), None);
    assert_eq!(BorderStyle::from_str_name("SINGLE"), None);
    assert_eq!(BorderStyle::from_str_name(""), None);
    assert_eq!(BorderStyle::default(), BorderStyle::Single);
}

// WidgetBase

#[test]
fn widget_base_position_1based() {
    let base = WidgetBase::new(0, 0, 10, 5);
    assert_eq!(base.position_1based(), (1, 1));
    let base = WidgetBase::new(4, 2, 10, 5);
    assert_eq!(base.position_1based(), (5, 3));
}

#[test]
fn widget_base_set_position_1based() {
    let mut base = WidgetBase::new(0, 0, 10, 5);
    base.set_position_1based(5, 3);
    assert_eq!(base.x, 4);
    assert_eq!(base.y, 2);
    assert_eq!(base.position_1based(), (5, 3));
}

#[test]
fn widget_base_visibility_enabled() {
    let mut base = WidgetBase::new(0, 0, 10, 5);
    assert!(base.visible);
    assert!(base.enabled);
    base.visible = false;
    assert!(!base.visible);
    base.visible = true;
    assert!(base.visible);
    base.enabled = false;
    assert!(!base.enabled);
    base.enabled = true;
    assert!(base.enabled);
}

// Widget constructors

#[test]
fn widget_label_creation() {
    let w = Widget::new_label(3, 2, "Hello");
    assert_eq!(w.base.position_1based(), (3, 2));
    if let WidgetKind::Label {
        ref text,
        ref color,
    } = w.kind
    {
        assert_eq!(text, "Hello");
        assert!((color[0] - 1.0).abs() < 1e-5);
    } else {
        panic!("Expected Label widget kind");
    }
}

#[test]
fn widget_button_creation() {
    let w = Widget::new_button(1, 1, 10, 2, "Click Me");
    assert_eq!(w.base.width, 10);
    assert_eq!(w.base.height, 2);
    if let WidgetKind::Button { ref text } = w.kind {
        assert_eq!(text, "Click Me");
    } else {
        panic!("Expected Button widget kind");
    }
}

#[test]
fn widget_textbox_creation() {
    let w = Widget::new_text_box(5, 3, 20);
    assert_eq!(w.base.position_1based(), (5, 3));
    assert_eq!(w.base.width, 20);
    assert_eq!(w.base.height, 1);
    if let WidgetKind::TextBox {
        ref text,
        max_length,
        cursor_pos,
    } = w.kind
    {
        assert_eq!(text, "");
        assert_eq!(max_length, 0);
        assert_eq!(cursor_pos, 0);
    } else {
        panic!("Expected TextBox widget kind");
    }
}

#[test]
fn widget_list_operations() {
    let mut w = Widget::new_list(1, 1, 20, 10);
    if let WidgetKind::List {
        ref mut items,
        ref mut selected,
        ..
    } = w.kind
    {
        assert_eq!(items.len(), 0);
        assert_eq!(*selected, None);
        items.push("Apple".into());
        items.push("Banana".into());
        items.push("Cherry".into());
        assert_eq!(items.len(), 3);
        *selected = Some(1);
        assert_eq!(*selected, Some(1));
        items.remove(1);
        assert_eq!(items.len(), 2);
        assert_eq!(items[0], "Apple");
        assert_eq!(items[1], "Cherry");
    } else {
        panic!("Expected List widget kind");
    }
}

#[test]
fn widget_label_width_matches_text() {
    let w = Widget::new_label(1, 1, "test");
    assert_eq!(w.base.width, 4);
}

#[test]
fn widget_constructors_convert_1based_to_0based() {
    let label = Widget::new_label(3, 5, "test");
    assert_eq!(label.base.x, 2);
    assert_eq!(label.base.y, 4);
    let btn = Widget::new_button(1, 1, 10, 2, "Go");
    assert_eq!(btn.base.x, 0);
    assert_eq!(btn.base.y, 0);
}

// Terminal widget management

#[test]
fn terminal_add_remove_widgets() {
    let mut t = Terminal::new(40, 20);
    assert_eq!(t.get_widget_count(), 0);
    let idx0 = t.add_widget(Widget::new_label(1, 1, "Hello"));
    assert_eq!(idx0, 0);
    assert_eq!(t.get_widget_count(), 1);
    let idx1 = t.add_widget(Widget::new_button(1, 2, 10, 1, "OK"));
    assert_eq!(idx1, 1);
    assert_eq!(t.get_widget_count(), 2);
    assert!(t.remove_widget(0));
    assert_eq!(t.get_widget_count(), 1);
    assert!(!t.remove_widget(99));
    t.add_widget(Widget::new_label(1, 1, "B"));
    t.clear_widgets();
    assert_eq!(t.get_widget_count(), 0);
}

#[test]
fn terminal_get_widget_by_index() {
    let mut t = Terminal::new(40, 20);
    t.add_widget(Widget::new_label(1, 1, "Test"));
    let w = t.get_widget(0);
    assert!(w.is_some());
    if let WidgetKind::Label { ref text, .. } = w.unwrap().kind {
        assert_eq!(text, "Test");
    }
    assert!(t.get_widget(99).is_none());
}

#[test]
fn terminal_widget_count_alias_matches_get_widget_count() {
    let mut t = Terminal::new(40, 20);

    assert_eq!(t.widget_count(), t.get_widget_count());
    t.add_widget(Widget::new_label(1, 1, "A"));
    assert_eq!(t.widget_count(), t.get_widget_count());
    t.add_widget(Widget::new_button(1, 2, 8, 1, "Go"));
    assert_eq!(t.widget_count(), t.get_widget_count());
    t.remove_widget(0);
    assert_eq!(t.widget_count(), t.get_widget_count());
}

#[test]
fn terminal_find_by_tag_returns_match_and_none_when_missing() {
    let mut t = Terminal::new(40, 20);
    let label_index = t.add_widget(Widget::new_label(1, 1, "Status"));
    let button_index = t.add_widget(Widget::new_button(1, 2, 8, 1, "Go"));

    t.get_widget_mut(label_index).unwrap().base.tag = "status".into();
    t.get_widget_mut(button_index).unwrap().base.tag = "primary".into();

    let widget = t.find_by_tag("primary");
    assert!(widget.is_some());
    match &widget.unwrap().kind {
        WidgetKind::Button { text } => assert_eq!(text, "Go"),
        _ => panic!("expected tagged widget to be a button"),
    }

    assert!(t.find_by_tag("missing").is_none());
}

// Terminal focus management

#[test]
fn terminal_focus_management() {
    let mut t = Terminal::new(40, 20);
    t.add_widget(Widget::new_text_box(1, 1, 10));
    t.add_widget(Widget::new_text_box(1, 2, 10));
    assert_eq!(t.get_focused(), None);
    t.set_focus(Some(0));
    assert_eq!(t.get_focused(), Some(0));
    t.set_focus(Some(1));
    assert_eq!(t.get_focused(), Some(1));
    t.set_focus(Some(99));
    assert_eq!(t.get_focused(), None);
    t.set_focus(Some(0));
    t.set_focus(None);
    assert_eq!(t.get_focused(), None);
}

#[test]
fn terminal_remove_widget_adjusts_focus() {
    let mut t = Terminal::new(40, 20);
    t.add_widget(Widget::new_label(1, 1, "A"));
    t.add_widget(Widget::new_label(1, 2, "B"));
    t.add_widget(Widget::new_label(1, 3, "C"));
    t.set_focus(Some(2));
    t.remove_widget(0);
    assert_eq!(t.get_focused(), Some(1));
    t.remove_widget(1);
    assert_eq!(t.get_focused(), None);
}

// Terminal text input routing

#[test]
fn terminal_textbox_textinput() {
    let mut t = Terminal::new(40, 20);
    t.add_widget(Widget::new_text_box(1, 1, 15));
    t.set_focus(Some(0));
    assert!(t.textinput("Hello"));
    let w = t.get_widget(0).unwrap();
    if let WidgetKind::TextBox {
        ref text,
        cursor_pos,
        ..
    } = w.kind
    {
        assert_eq!(text, "Hello");
        assert_eq!(cursor_pos, 5);
    } else {
        panic!("Expected TextBox");
    }
}

#[test]
fn terminal_keypressed_backspace() {
    let mut t = Terminal::new(40, 20);
    t.add_widget(Widget::new_text_box(1, 1, 15));
    t.set_focus(Some(0));
    t.textinput("abc");
    assert!(t.keypressed("backspace"));
    let w = t.get_widget(0).unwrap();
    if let WidgetKind::TextBox {
        ref text,
        cursor_pos,
        ..
    } = w.kind
    {
        assert_eq!(text, "ab");
        assert_eq!(cursor_pos, 2);
    } else {
        panic!("Expected TextBox");
    }
}

#[test]
fn widget_textbox_max_length() {
    let mut t = Terminal::new(40, 20);
    let mut tb = Widget::new_text_box(1, 1, 15);
    if let WidgetKind::TextBox {
        ref mut max_length, ..
    } = tb.kind
    {
        *max_length = 5;
    }
    t.add_widget(tb);
    t.set_focus(Some(0));
    assert!(t.textinput("Hello"));
    assert!(!t.textinput("X"));
    let w = t.get_widget(0).unwrap();
    if let WidgetKind::TextBox { ref text, .. } = w.kind {
        assert_eq!(text, "Hello");
    }
}

#[test]
fn terminal_textbox_cursor_navigation() {
    let mut t = Terminal::new(40, 20);
    t.add_widget(Widget::new_text_box(1, 1, 15));
    t.set_focus(Some(0));
    t.textinput("abcde");
    assert!(t.keypressed("left"));
    if let WidgetKind::TextBox { cursor_pos, .. } = t.get_widget(0).unwrap().kind {
        assert_eq!(cursor_pos, 4);
    }
    assert!(t.keypressed("home"));
    if let WidgetKind::TextBox { cursor_pos, .. } = t.get_widget(0).unwrap().kind {
        assert_eq!(cursor_pos, 0);
    }
    assert!(t.keypressed("end"));
    if let WidgetKind::TextBox { cursor_pos, .. } = t.get_widget(0).unwrap().kind {
        assert_eq!(cursor_pos, 5);
    }
}

// Terminal list key navigation

#[test]
fn terminal_list_keypressed_navigation() {
    let mut t = Terminal::new(40, 20);
    let mut list = Widget::new_list(1, 1, 10, 3);
    if let WidgetKind::List { ref mut items, .. } = list.kind {
        items.push("Apple".into());
        items.push("Banana".into());
        items.push("Cherry".into());
    }
    t.add_widget(list);
    t.set_focus(Some(0));
    assert!(t.keypressed("down"));
    if let WidgetKind::List { selected, .. } = &t.get_widget(0).unwrap().kind {
        assert_eq!(*selected, Some(0));
    }
    assert!(t.keypressed("down"));
    if let WidgetKind::List { selected, .. } = &t.get_widget(0).unwrap().kind {
        assert_eq!(*selected, Some(1));
    }
    assert!(t.keypressed("up"));
    if let WidgetKind::List { selected, .. } = &t.get_widget(0).unwrap().kind {
        assert_eq!(*selected, Some(0));
    }
    assert!(t.keypressed("up"));
    if let WidgetKind::List { selected, .. } = &t.get_widget(0).unwrap().kind {
        assert_eq!(*selected, Some(0));
    }
}

#[test]
fn terminal_button_key_activation_returns_consumed() {
    let mut t = Terminal::new(20, 10);
    t.add_widget(Widget::new_button(1, 1, 8, 1, "OK"));
    t.set_focus(Some(0));

    assert!(t.keypressed("space"));
    assert!(t.keypressed("return"));
    assert!(!t.keypressed("escape"));
}

// Widget panel children

#[test]
fn widget_panel_children() {
    let mut panel = Widget::new_panel(1, 1, 20, 10);
    if let WidgetKind::Panel { ref mut children } = panel.kind {
        assert_eq!(children.len(), 0);
        children.push(0);
        children.push(1);
        children.push(2);
        assert_eq!(children.len(), 3);
        assert_eq!(children[0], 0);
        assert_eq!(children[1], 1);
        children.clear();
        assert_eq!(children.len(), 0);
    } else {
        panic!("Expected Panel widget kind");
    }
}

// Terminal input without focus

#[test]
fn terminal_no_input_without_focus() {
    let mut t = Terminal::new(10, 5);
    t.add_widget(Widget::new_text_box(1, 1, 10));
    assert!(!t.keypressed("a"));
    assert!(!t.textinput("hello"));
}

#[test]
fn terminal_disabled_widget_ignores_input() {
    let mut t = Terminal::new(10, 5);
    let mut tb = Widget::new_text_box(1, 1, 10);
    tb.base.enabled = false;
    t.add_widget(tb);
    t.set_focus(Some(0));
    assert!(!t.textinput("hello"));
    assert!(!t.keypressed("backspace"));
}

// Terminal mouse press

#[test]
fn terminal_mousepressed_focuses_widget() {
    let mut t = Terminal::new(20, 10);
    t.add_widget(Widget::new_button(3, 3, 5, 1, "OK"));
    assert!(t.mousepressed(4, 3, 1));
    assert_eq!(t.get_focused(), Some(0));
    assert!(!t.mousepressed(1, 1, 1));
    assert_eq!(t.get_focused(), None);
}

#[test]
fn terminal_mousepressed_miss_clears_focus() {
    let mut t = Terminal::new(20, 10);
    t.add_widget(Widget::new_button(3, 3, 5, 1, "OK"));
    t.set_focus(Some(0));

    assert_eq!(t.get_focused(), Some(0));
    assert!(!t.mousepressed(1, 1, 1));
    assert_eq!(t.get_focused(), None);
}

#[test]
fn terminal_mousepressed_ignores_hidden_and_disabled_widgets() {
    let mut t = Terminal::new(20, 10);
    let mut hidden = Widget::new_button(2, 2, 4, 1, "Hide");
    let mut disabled = Widget::new_button(8, 2, 4, 1, "Stop");
    hidden.base.visible = false;
    disabled.base.enabled = false;

    t.add_widget(hidden);
    t.add_widget(disabled);
    t.set_focus(Some(1));

    assert!(!t.mousepressed(2, 2, 1));
    assert_eq!(t.get_focused(), None);

    t.set_focus(Some(1));
    assert!(!t.mousepressed(8, 2, 1));
    assert_eq!(t.get_focused(), None);
}

// Border widget creation

#[test]
fn widget_border_creation() {
    let w = Widget::new_border(2, 3, 30, 10);
    assert_eq!(w.base.position_1based(), (2, 3));
    assert_eq!(w.base.width, 30);
    assert_eq!(w.base.height, 10);
    if let WidgetKind::Border {
        style, ref title, ..
    } = w.kind
    {
        assert_eq!(style, BorderStyle::Single);
        assert_eq!(title, "");
    } else {
        panic!("Expected Border widget kind");
    }
}
