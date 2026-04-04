//! Integration tests for the gui module: WidgetState, WidgetType, WidgetBase,
//! controls, containers, extras, theme, and context.

use luna2d::gui::{
    Accordion, AccordionSection, Button, CheckBox, ColorPicker, ComboBox, DockPanel, Dialog,
    GUITable, GUIWindow, GuiContext, ImageWidget, Label, Layout, LayoutDirection, ListBox,
    MenuBar, MenuItem, NinePatch, Panel, ProgressBar, RadioButton, ScrollBar, ScrollPanel,
    Separator, Slider, Spacer, SplitPanel, StatusBar, TabBar, TableColumn, TextInput, Theme,
    Toast, Toolbar, ToolbarButton, TooltipPanel, TreeView, WidgetBase, WidgetState,
    WidgetStyle, WidgetType,
};

// ============================================================
// WidgetState
// ============================================================

#[test]
fn widget_state_parse_str_valid() {
    assert_eq!(WidgetState::parse_str("normal"), Some(WidgetState::Normal));
    assert_eq!(
        WidgetState::parse_str("hovered"),
        Some(WidgetState::Hovered)
    );
    assert_eq!(
        WidgetState::parse_str("pressed"),
        Some(WidgetState::Pressed)
    );
    assert_eq!(
        WidgetState::parse_str("focused"),
        Some(WidgetState::Focused)
    );
    assert_eq!(
        WidgetState::parse_str("disabled"),
        Some(WidgetState::Disabled)
    );
}

#[test]
fn widget_state_parse_str_invalid() {
    assert_eq!(WidgetState::parse_str("NORMAL"), None);
    assert_eq!(WidgetState::parse_str(""), None);
    assert_eq!(WidgetState::parse_str("active"), None);
}

#[test]
fn widget_state_as_str_roundtrip() {
    let states = [
        WidgetState::Normal,
        WidgetState::Hovered,
        WidgetState::Pressed,
        WidgetState::Focused,
        WidgetState::Disabled,
    ];
    for s in &states {
        assert_eq!(WidgetState::parse_str(s.as_str()), Some(*s));
    }
}

// ============================================================
// WidgetBase
// ============================================================

#[test]
fn widget_base_defaults() {
    let b = WidgetBase::new(WidgetType::Button);
    assert_eq!(b.widget_type, WidgetType::Button);
    assert!(b.visible);
    assert!(b.enabled);
    assert_eq!(b.state, WidgetState::Normal);
    assert!((b.x - 0.0).abs() < 1e-5);
    assert!((b.y - 0.0).abs() < 1e-5);
    assert!((b.width - 100.0).abs() < 1e-5);
    assert!((b.height - 30.0).abs() < 1e-5);
}

#[test]
fn widget_base_contains_point() {
    let mut b = WidgetBase::new(WidgetType::Label);
    b.x = 10.0;
    b.y = 20.0;
    b.width = 100.0;
    b.height = 50.0;
    assert!(b.contains_point(10.0, 20.0));
    assert!(b.contains_point(109.0, 69.0));
    assert!(!b.contains_point(9.0, 20.0));
    assert!(!b.contains_point(111.0, 20.0));
    assert!(!b.contains_point(50.0, 71.0));
}

#[test]
fn widget_base_clear_anchors() {
    let mut b = WidgetBase::new(WidgetType::Panel);
    b.anchor_left = Some(5.0);
    b.anchor_top = Some(10.0);
    b.anchor_right = Some(15.0);
    b.anchor_bottom = Some(20.0);
    b.clear_anchors();
    assert!(b.anchor_left.is_none());
    assert!(b.anchor_top.is_none());
    assert!(b.anchor_right.is_none());
    assert!(b.anchor_bottom.is_none());
}

#[test]
fn widget_base_padding_and_margin() {
    let mut b = WidgetBase::new(WidgetType::Button);
    b.padding = [4.0, 8.0, 4.0, 8.0];
    b.margin = [2.0, 2.0, 2.0, 2.0];
    assert!((b.padding[0] - 4.0).abs() < 1e-5);
    assert!((b.padding[1] - 8.0).abs() < 1e-5);
    assert!((b.margin[0] - 2.0).abs() < 1e-5);
}

// ============================================================
// Button
// ============================================================

#[test]
fn button_text() {
    let btn = Button::new("Click Me");
    assert_eq!(btn.text, "Click Me");
    assert_eq!(btn.base.widget_type, WidgetType::Button);
}

// ============================================================
// Label
// ============================================================

#[test]
fn label_text() {
    let lbl = Label::new("Hello");
    assert_eq!(lbl.text, "Hello");
    assert_eq!(lbl.base.widget_type, WidgetType::Label);
}

// ============================================================
// TextInput
// ============================================================

#[test]
fn text_input_insert_and_backspace() {
    let mut ti = TextInput::new();
    ti.insert_text("abc");
    assert_eq!(ti.text, "abc");
    assert_eq!(ti.cursor_pos, 3);
    ti.backspace();
    assert_eq!(ti.text, "ab");
    assert_eq!(ti.cursor_pos, 2);
}

#[test]
fn text_input_max_length() {
    let mut ti = TextInput::new();
    ti.max_length = 5;
    // Inserting beyond max_length is rejected entirely
    assert!(!ti.insert_text("abcdefgh"));
    assert_eq!(ti.text, "");
    // Inserting within limit succeeds
    assert!(ti.insert_text("abc"));
    assert_eq!(ti.text, "abc");
    // Now 3 + 3 > 5, so this is rejected
    assert!(!ti.insert_text("xyz"));
    assert_eq!(ti.text, "abc");
    // But 3 + 2 <= 5, so this succeeds
    assert!(ti.insert_text("de"));
    assert_eq!(ti.text, "abcde");
}

#[test]
fn text_input_backspace_empty() {
    let mut ti = TextInput::new();
    ti.backspace(); // should not panic
    assert_eq!(ti.text, "");
    assert_eq!(ti.cursor_pos, 0);
}

// ============================================================
// CheckBox
// ============================================================

#[test]
fn checkbox_default_unchecked() {
    let cb = CheckBox::new("Option");
    assert!(!cb.checked);
    assert_eq!(cb.text, "Option");
}

// ============================================================
// Slider
// ============================================================

#[test]
fn slider_clamp_to_range() {
    let mut sl = Slider::new(0.0, 100.0);
    sl.set_value(150.0);
    assert!((sl.value - 100.0).abs() < 1e-5);
    sl.set_value(-10.0);
    assert!((sl.value - 0.0).abs() < 1e-5);
}

#[test]
fn slider_step_snapping() {
    let mut sl = Slider::new(0.0, 100.0);
    sl.step = 10.0;
    sl.set_value(23.0);
    assert!((sl.value - 20.0).abs() < 1e-5);
    sl.set_value(27.0);
    assert!((sl.value - 30.0).abs() < 1e-5);
}

// ============================================================
// ProgressBar
// ============================================================

#[test]
fn progress_bar_percentage() {
    let mut pb = ProgressBar::new(0.0, 100.0);
    pb.value = 50.0;
    assert!((pb.progress() - 0.5).abs() < 1e-5);
}

#[test]
fn progress_bar_zero_range() {
    let mut pb = ProgressBar::new(10.0, 10.0);
    pb.value = 10.0;
    assert!((pb.progress() - 0.0).abs() < 1e-5);
}

// ============================================================
// ComboBox
// ============================================================

#[test]
fn combo_box_add_remove_clear() {
    let mut cb = ComboBox::new();
    cb.add_item("A");
    cb.add_item("B");
    cb.add_item("C");
    assert_eq!(cb.items.len(), 3);
    assert!(cb.remove_item(1)); // remove "B"
    assert_eq!(cb.items.len(), 2);
    assert_eq!(cb.items[1], "C");
    cb.clear();
    assert_eq!(cb.items.len(), 0);
    assert!(cb.selected_index.is_none());
}

#[test]
fn combo_box_selected_item() {
    let mut cb = ComboBox::new();
    cb.add_item("X");
    cb.add_item("Y");
    cb.selected_index = Some(1);
    assert_eq!(cb.selected_item(), Some("Y"));
}

#[test]
fn combo_box_selected_item_none() {
    let cb = ComboBox::new();
    assert_eq!(cb.selected_item(), None);
}

// ============================================================
// ListBox
// ============================================================

#[test]
fn list_box_add_remove() {
    let mut lb = ListBox::new();
    lb.add_item("A");
    lb.add_item("B");
    assert_eq!(lb.items.len(), 2);
    lb.remove_item(0);
    assert_eq!(lb.items[0], "B");
}

// ============================================================
// TabBar
// ============================================================

#[test]
fn tab_bar_add_remove() {
    let mut tb = TabBar::new();
    tb.add_tab("Tab1");
    tb.add_tab("Tab2");
    tb.add_tab("Tab3");
    assert_eq!(tb.tabs.len(), 3);
    assert_eq!(tb.active_tab, 0);
    assert!(tb.remove_tab(0));
    assert_eq!(tb.tabs.len(), 2);
    assert_eq!(tb.tabs[0], "Tab2");
    assert_eq!(tb.active_tab, 0); // clamped
}

#[test]
fn tab_bar_remove_out_of_bounds() {
    let mut tb = TabBar::new();
    tb.add_tab("Only");
    assert!(!tb.remove_tab(5));
    assert_eq!(tb.tabs.len(), 1);
}

// ============================================================
// Panel
// ============================================================

#[test]
fn panel_defaults() {
    let p = Panel::new();
    assert_eq!(p.children.len(), 0);
    assert_eq!(p.title, "");
    assert!(!p.scrollable);
}

// ============================================================
// Layout + LayoutDirection
// ============================================================

#[test]
fn layout_direction_parse_str() {
    assert_eq!(
        LayoutDirection::parse_str("vertical"),
        Some(LayoutDirection::Vertical)
    );
    assert_eq!(
        LayoutDirection::parse_str("horizontal"),
        Some(LayoutDirection::Horizontal)
    );
    assert_eq!(
        LayoutDirection::parse_str("grid"),
        Some(LayoutDirection::Grid)
    );
    assert_eq!(LayoutDirection::parse_str("VERTICAL"), None);
}

#[test]
fn layout_direction_as_str_roundtrip() {
    let dirs = [
        LayoutDirection::Vertical,
        LayoutDirection::Horizontal,
        LayoutDirection::Grid,
    ];
    for d in &dirs {
        assert_eq!(LayoutDirection::parse_str(d.as_str()), Some(*d));
    }
}

#[test]
fn layout_perform_vertical() {
    let mut ly = Layout::new(LayoutDirection::Vertical);
    ly.base.x = 10.0;
    ly.base.y = 20.0;
    ly.spacing = 5.0;
    ly.children.push(0);
    ly.children.push(1);
    let mut bases = vec![
        { let mut b = WidgetBase::new(WidgetType::Button); b.width = 100.0; b.height = 30.0; b },
        { let mut b = WidgetBase::new(WidgetType::Button); b.width = 100.0; b.height = 40.0; b },
    ];
    ly.perform_layout(&mut bases);
    assert!((bases[0].x - 10.0).abs() < 1e-5);
    assert!((bases[0].y - 20.0).abs() < 1e-5);
    assert!((bases[1].x - 10.0).abs() < 1e-5);
    assert!((bases[1].y - 55.0).abs() < 1e-5); // 20 + 30 + 5
}

#[test]
fn layout_perform_horizontal() {
    let mut ly = Layout::new(LayoutDirection::Horizontal);
    ly.base.x = 0.0;
    ly.base.y = 0.0;
    ly.spacing = 10.0;
    ly.children.push(0);
    ly.children.push(1);
    let mut bases = vec![
        { let mut b = WidgetBase::new(WidgetType::Button); b.width = 50.0; b.height = 30.0; b },
        { let mut b = WidgetBase::new(WidgetType::Button); b.width = 60.0; b.height = 30.0; b },
    ];
    ly.perform_layout(&mut bases);
    assert!((bases[0].x - 0.0).abs() < 1e-5);
    assert!((bases[1].x - 60.0).abs() < 1e-5); // 0 + 50 + 10
}

// ============================================================
// ScrollPanel
// ============================================================

#[test]
fn scroll_panel_clamp() {
    let mut sp = ScrollPanel::new();
    sp.content_width = 500.0;
    sp.content_height = 800.0;
    sp.base.width = 200.0;
    sp.base.height = 300.0;
    sp.scroll_x = -50.0;
    sp.scroll_y = 900.0;
    sp.clamp_scroll();
    assert!((sp.scroll_x - 0.0).abs() < 1e-5);
    assert!((sp.scroll_y - sp.max_scroll().1).abs() < 1e-5);
}

#[test]
fn scroll_panel_max_scroll() {
    let mut sp = ScrollPanel::new();
    sp.content_width = 400.0;
    sp.content_height = 600.0;
    sp.base.width = 200.0;
    sp.base.height = 300.0;
    let (mx, my) = sp.max_scroll();
    assert!((mx - 200.0).abs() < 1e-5);
    assert!((my - 300.0).abs() < 1e-5);
}

// ============================================================
// NinePatch
// ============================================================

#[test]
fn nine_patch_slices_count() {
    let mut np = NinePatch::new();
    np.image_width = 64;
    np.image_height = 64;
    np.inset_left = 8;
    np.inset_top = 8;
    np.inset_right = 8;
    np.inset_bottom = 8;
    np.base.width = 128.0;
    np.base.height = 128.0;
    let slices = np.get_slices();
    assert_eq!(slices.len(), 9);
}

// ============================================================
// Toast
// ============================================================

#[test]
fn toast_lifecycle() {
    let mut t = Toast::new("Hello", 2.0);
    assert!(!t.is_expired());
    assert!((t.progress() - 0.0).abs() < 1e-5);
    t.update(1.0);
    assert!((t.progress() - 0.5).abs() < 1e-5);
    assert!(!t.is_expired());
    t.update(1.5);
    assert!(t.is_expired());
}

// ============================================================
// Separator
// ============================================================

#[test]
fn separator_defaults() {
    let sep = Separator::new(false);
    assert!(!sep.vertical);
    assert!((sep.thickness - 1.0).abs() < 1e-5);
}

#[test]
fn separator_vertical() {
    let sep = Separator::new(true);
    assert!(sep.vertical);
}

// ============================================================
// Spacer
// ============================================================

#[test]
fn spacer_custom_size() {
    let sp = Spacer::new(50.0, 25.0);
    assert!((sp.base.width - 50.0).abs() < 1e-5);
    assert!((sp.base.height - 25.0).abs() < 1e-5);
}

// ============================================================
// TreeView
// ============================================================

#[test]
fn tree_view_add_and_toggle() {
    let mut tv = TreeView::new();
    let root = tv.add_node("Root", None);
    let child = tv.add_node("Child", Some(root));
    assert_eq!(tv.node_count(), 2);
    assert_eq!(tv.nodes[root].children.len(), 1);
    assert_eq!(tv.nodes[child].parent, Some(root));
    // Root starts collapsed by default
    assert!(!tv.nodes[root].expanded);
    tv.toggle_node(root);
    assert!(tv.nodes[root].expanded);
    tv.toggle_node(root);
    assert!(!tv.nodes[root].expanded);
}

#[test]
fn tree_view_clear_nodes() {
    let mut tv = TreeView::new();
    tv.add_node("A", None);
    tv.add_node("B", None);
    tv.clear_nodes();
    assert_eq!(tv.node_count(), 0);
    assert!(tv.root_nodes.is_empty());
    assert!(tv.selected_node.is_none());
}

#[test]
fn tree_view_node_text_ops() {
    let mut tv = TreeView::new();
    let i = tv.add_node("Hello", None);
    assert_eq!(tv.get_node_text(i), Some("Hello"));
    assert!(tv.set_node_text(i, "World"));
    assert_eq!(tv.get_node_text(i), Some("World"));
    assert!(!tv.set_node_text(99, "Nope"));
    assert!(tv.get_node_text(99).is_none());
}

#[test]
fn tree_view_node_icon() {
    let mut tv = TreeView::new();
    let i = tv.add_node("File", None);
    assert!(tv.nodes[i].icon.is_none());
    assert!(tv.set_node_icon(i, "file-icon"));
    assert_eq!(tv.nodes[i].icon.as_deref(), Some("file-icon"));
    // Empty string clears the icon
    tv.set_node_icon(i, "");
    assert!(tv.nodes[i].icon.is_none());
}

#[test]
fn tree_view_expand_collapse_node() {
    let mut tv = TreeView::new();
    let i = tv.add_node("X", None);
    assert!(!tv.nodes[i].expanded);
    assert!(tv.expand_node(i));
    assert!(tv.nodes[i].expanded);
    assert_eq!(tv.is_node_expanded(i), Some(true));
    assert!(tv.collapse_node(i));
    assert_eq!(tv.is_node_expanded(i), Some(false));
    assert!(!tv.expand_node(999));
    assert!(tv.is_node_expanded(999).is_none());
}

#[test]
fn tree_view_expand_collapse_all() {
    let mut tv = TreeView::new();
    tv.add_node("A", None);
    tv.add_node("B", None);
    tv.expand_all();
    assert!(tv.nodes.iter().all(|n| n.expanded));
    tv.collapse_all();
    assert!(tv.nodes.iter().all(|n| !n.expanded));
}

#[test]
fn tree_view_selected_node() {
    let mut tv = TreeView::new();
    let a = tv.add_node("A", None);
    let b = tv.add_node("B", None);
    assert!(tv.get_selected_node().is_none());
    assert!(tv.set_selected_node(a));
    assert_eq!(tv.get_selected_node(), Some(a));
    assert!(tv.set_selected_node(b));
    assert_eq!(tv.get_selected_node(), Some(b));
    // Out of range clears selection
    assert!(!tv.set_selected_node(999));
    assert!(tv.get_selected_node().is_none());
}

#[test]
fn tree_view_remove_node_basic() {
    let mut tv = TreeView::new();
    let root = tv.add_node("Root", None);
    let child = tv.add_node("Child", Some(root));
    assert_eq!(tv.node_count(), 2);
    // Remove child
    assert!(tv.remove_node(child));
    assert_eq!(tv.node_count(), 1);
    assert!(tv.nodes[root].children.is_empty());
    // Index out of range returns false
    assert!(!tv.remove_node(99));
}

#[test]
fn tree_view_remove_root_node() {
    let mut tv = TreeView::new();
    tv.add_node("A", None);
    tv.add_node("B", None);
    assert_eq!(tv.root_nodes.len(), 2);
    tv.remove_node(0);
    assert_eq!(tv.node_count(), 1);
    // B was re-indexed to 0
    assert_eq!(tv.root_nodes, vec![0]);
}

#[test]
fn tree_view_remove_remaps_selection() {
    let mut tv = TreeView::new();
    tv.add_node("A", None);
    let b = tv.add_node("B", None);
    tv.set_selected_node(b);
    // Remove A (index 0); B becomes index 0
    tv.remove_node(0);
    assert_eq!(tv.get_selected_node(), Some(0));
}

#[test]
fn tree_view_child_and_parent_nodes() {
    let mut tv = TreeView::new();
    let root = tv.add_node("Root", None);
    let child = tv.add_node("Child", Some(root));
    assert_eq!(tv.get_child_nodes(root), Some([child].as_slice()));
    assert_eq!(tv.get_parent_node(child), Some(Some(root)));
    assert_eq!(tv.get_parent_node(root), Some(None));
    assert!(tv.get_child_nodes(99).is_none());
    assert!(tv.get_parent_node(99).is_none());
}

#[test]
fn tree_view_node_depth() {
    let mut tv = TreeView::new();
    let root = tv.add_node("Root", None);
    let lvl1 = tv.add_node("Level1", Some(root));
    let lvl2 = tv.add_node("Level2", Some(lvl1));
    assert_eq!(tv.get_node_depth(root), Some(0));
    assert_eq!(tv.get_node_depth(lvl1), Some(1));
    assert_eq!(tv.get_node_depth(lvl2), Some(2));
    assert!(tv.get_node_depth(99).is_none());
}

// ============================================================
// Theme + WidgetStyle
// ============================================================

#[test]
fn theme_set_get_style() {
    let mut theme = Theme::new();
    let style = WidgetStyle {
        bg_color: [1.0, 0.0, 0.0, 1.0],
        fg_color: [1.0, 1.0, 1.0, 1.0],
        border_color: [0.0, 0.0, 0.0, 1.0],
        border_width: 2.0,
        corner_radius: 4.0,
        font_size: 16.0,
    };
    theme.set_style(WidgetType::Button, WidgetState::Normal, style.clone());
    let retrieved = theme.get_style(WidgetType::Button, WidgetState::Normal).unwrap();
    assert!((retrieved.bg_color[0] - 1.0).abs() < 1e-5);
    assert!((retrieved.border_width - 2.0).abs() < 1e-5);
}

#[test]
fn theme_fallback_to_normal() {
    let mut theme = Theme::new();
    let style = WidgetStyle {
        bg_color: [0.5, 0.5, 0.5, 1.0],
        fg_color: [1.0, 1.0, 1.0, 1.0],
        border_color: [0.0, 0.0, 0.0, 1.0],
        border_width: 1.0,
        corner_radius: 0.0,
        font_size: 14.0,
    };
    theme.set_style(WidgetType::Label, WidgetState::Normal, style);
    // Querying Hovered should fall back to Normal
    let retrieved = theme.get_style(WidgetType::Label, WidgetState::Hovered).unwrap();
    assert!((retrieved.bg_color[0] - 0.5).abs() < 1e-5);
}

// ============================================================
// GuiContext
// ============================================================

#[test]
fn gui_context_add_widgets_and_count() {
    let mut ctx = GuiContext::new();
    ctx.add_button("A");
    ctx.add_label("B");
    ctx.add_text_input();
    assert_eq!(ctx.widgets.len(), 4); // root panel + 3 added
}

#[test]
fn gui_context_add_child_remove_child() {
    let mut ctx = GuiContext::new();
    let panel = ctx.add_panel();
    let btn = ctx.add_button("Child");
    ctx.add_child(panel, btn);
    assert_eq!(ctx.widgets[panel].children().unwrap().len(), 1);
    ctx.remove_child(panel, btn);
    assert_eq!(ctx.widgets[panel].children().unwrap().len(), 0);
}

#[test]
fn gui_context_focus_cycle() {
    let mut ctx = GuiContext::new();
    // Root panel is at index 0; buttons at 1, 2, 3
    let a = ctx.add_button("A"); // index 1
    let b = ctx.add_button("B"); // index 2
    let c = ctx.add_button("C"); // index 3
    ctx.set_focus(Some(a));
    assert_eq!(ctx.focused_widget, Some(a));
    ctx.focus_next();
    assert_eq!(ctx.focused_widget, Some(b));
    ctx.focus_next();
    assert_eq!(ctx.focused_widget, Some(c));
    ctx.focus_next();
    assert_eq!(ctx.focused_widget, Some(a)); // wraps around (skips root panel)
    ctx.focus_prev();
    assert_eq!(ctx.focused_widget, Some(c));
}

#[test]
fn gui_context_toast_update() {
    let mut ctx = GuiContext::new();
    ctx.add_toast(Toast::new("Hello", 1.0));
    assert_eq!(ctx.toasts.len(), 1);
    ctx.update(0.5);
    assert_eq!(ctx.toasts.len(), 1); // not yet expired
    ctx.update(1.0);
    assert_eq!(ctx.toasts.len(), 0); // expired and removed
}

#[test]
fn gui_context_find_by_id() {
    let mut ctx = GuiContext::new();
    let idx = ctx.add_button("Test");
    ctx.widgets[idx].base_mut().id = "my_button".to_string();
    // Add button as child of root so tree search finds it
    ctx.add_child(0, idx);
    let found = ctx.find_by_id(0, "my_button");
    assert_eq!(found, Some(idx));
    let not_found = ctx.find_by_id(0, "nonexistent");
    assert_eq!(not_found, None);
}

#[test]
fn gui_context_all_widget_constructors() {
    let mut ctx = GuiContext::new();
    ctx.add_button("B");
    ctx.add_label("L");
    ctx.add_text_input();
    ctx.add_checkbox("C");
    ctx.add_slider(0.0, 1.0);
    ctx.add_progress_bar(0.0, 100.0);
    ctx.add_combo_box();
    ctx.add_list_box();
    ctx.add_panel();
    ctx.add_layout(LayoutDirection::Vertical);
    ctx.add_scroll_panel();
    ctx.add_nine_patch();
    ctx.add_tab_bar();
    ctx.add_separator(false);
    ctx.add_spacer(10.0, 10.0);
    ctx.add_tree_view();
    assert_eq!(ctx.widgets.len(), 17); // root panel + 16 added
}


// ============================================================
// RadioButton
// ============================================================

#[test]
fn radio_button_new_defaults() {
    let rb = RadioButton::new("Option A", "grp1");
    assert_eq!(rb.text, "Option A");
    assert_eq!(rb.group, "grp1");
    assert!(!rb.selected);
}

#[test]
fn radio_button_select_toggle() {
    let mut rb = RadioButton::new("X", "g");
    rb.selected = true;
    assert!(rb.selected);
    rb.selected = false;
    assert!(!rb.selected);
}

#[test]
fn gui_context_add_radio_button() {
    let mut ctx = GuiContext::new();
    let idx = ctx.add_radio_button("Opt".to_string(), "g1".to_string());
    assert!(idx > 0);
    assert_eq!(ctx.widgets[idx].base().widget_type.as_str(), "radiobutton");
}

// ============================================================
// ScrollBar
// ============================================================

#[test]
fn scroll_bar_new_defaults() {
    let sb = ScrollBar::new(true);
    assert!(sb.vertical);
    assert!((sb.position - 0.0).abs() < 1e-5);
    assert!((sb.content_size - 100.0).abs() < 1e-5);
    assert!((sb.view_size - 50.0).abs() < 1e-5);
}

#[test]
fn scroll_bar_horizontal() {
    let sb = ScrollBar::new(false);
    assert!(!sb.vertical);
}

#[test]
fn gui_context_add_scroll_bar() {
    let mut ctx = GuiContext::new();
    let idx = ctx.add_scroll_bar(false);
    assert!(idx > 0);
    assert_eq!(ctx.widgets[idx].base().widget_type.as_str(), "scrollbar");
}

// ============================================================
// GUIWindow
// ============================================================

#[test]
fn gui_window_new_defaults() {
    let w = GUIWindow::new("My Window");
    assert_eq!(w.title, "My Window");
    assert!(w.closeable);
    assert!(w.draggable);
    assert!(!w.resizable);
    assert!(w.children.is_empty());
}

#[test]
fn gui_context_add_gui_window() {
    let mut ctx = GuiContext::new();
    let idx = ctx.add_gui_window("Test".to_string());
    assert!(idx > 0);
    assert_eq!(ctx.widgets[idx].base().widget_type.as_str(), "guiwindow");
}

#[test]
fn gui_window_has_children() {
    let mut ctx = GuiContext::new();
    let win = ctx.add_gui_window("Win".to_string());
    let btn = ctx.add_button("Click");
    ctx.add_child(win, btn);
    assert_eq!(ctx.widgets[win].children().unwrap().len(), 1);
}

// ============================================================
// SplitPanel
// ============================================================

#[test]
fn split_panel_new_defaults() {
    let sp = SplitPanel::new("horizontal");
    assert_eq!(sp.orientation, "horizontal");
    assert!((sp.split_position - 0.5).abs() < 1e-5);
    assert!((sp.min_panel_size - 50.0).abs() < 1e-5);
    assert!(sp.first_child.is_none());
    assert!(sp.second_child.is_none());
}

#[test]
fn gui_context_add_split_panel() {
    let mut ctx = GuiContext::new();
    let idx = ctx.add_split_panel("vertical".to_string());
    assert!(idx > 0);
    assert_eq!(ctx.widgets[idx].base().widget_type.as_str(), "splitpanel");
}

// ============================================================
// DockPanel
// ============================================================

#[test]
fn dock_panel_default() {
    let dp = DockPanel::default();
    assert!(dp.docked.is_empty());
    assert!(dp.split_sizes.is_empty());
}

#[test]
fn gui_context_add_dock_panel() {
    let mut ctx = GuiContext::new();
    let idx = ctx.add_dock_panel();
    assert!(idx > 0);
    assert_eq!(ctx.widgets[idx].base().widget_type.as_str(), "dockpanel");
}

// ============================================================
// Toolbar
// ============================================================

#[test]
fn toolbar_new_defaults() {
    let tb = Toolbar::new("horizontal");
    assert_eq!(tb.orientation, "horizontal");
    assert!(tb.children.is_empty());
    assert!(tb.buttons.is_empty());
}

#[test]
fn toolbar_button_struct() {
    let btn = ToolbarButton::new("open", "Open file");
    assert_eq!(btn.id, "open");
    assert_eq!(btn.tooltip, "Open file");
    assert!(btn.enabled);
    assert!(!btn.toggled);
}

#[test]
fn toolbar_add_button() {
    let mut tb = Toolbar::new("horizontal");
    let idx = tb.add_button("save", "Save");
    assert_eq!(idx, 0);
    assert_eq!(tb.buttons.len(), 1);
    assert_eq!(tb.buttons[0].id, "save");
}

#[test]
fn toolbar_add_button_no_duplicate() {
    let mut tb = Toolbar::new("horizontal");
    tb.add_button("cut", "Cut");
    let idx2 = tb.add_button("cut", "Cut again");
    // Same id returns existing index, no duplicate
    assert_eq!(idx2, 0);
    assert_eq!(tb.buttons.len(), 1);
}

#[test]
fn toolbar_get_button_index() {
    let mut tb = Toolbar::new("horizontal");
    tb.add_button("copy", "Copy");
    assert_eq!(tb.get_button_index("copy"), Some(0));
    assert!(tb.get_button_index("missing").is_none());
}

#[test]
fn toolbar_set_button_enabled() {
    let mut tb = Toolbar::new("horizontal");
    tb.add_button("paste", "Paste");
    assert!(tb.buttons[0].enabled);
    assert!(tb.set_button_enabled("paste", false));
    assert!(!tb.buttons[0].enabled);
    assert!(!tb.set_button_enabled("missing", false));
}

#[test]
fn toolbar_button_toggled() {
    let mut tb = Toolbar::new("horizontal");
    tb.add_button("bold", "Bold");
    assert_eq!(tb.is_button_toggled("bold"), Some(false));
    assert!(tb.set_button_toggled("bold", true));
    assert_eq!(tb.is_button_toggled("bold"), Some(true));
    assert!(tb.is_button_toggled("missing").is_none());
}

#[test]
fn gui_context_add_toolbar() {
    let mut ctx = GuiContext::new();
    let idx = ctx.add_toolbar("vertical".to_string());
    assert!(idx > 0);
    assert_eq!(ctx.widgets[idx].base().widget_type.as_str(), "toolbar");
}

#[test]
fn toolbar_has_children() {
    let mut ctx = GuiContext::new();
    let tb = ctx.add_toolbar("horizontal".to_string());
    let btn = ctx.add_button("B1");
    ctx.add_child(tb, btn);
    assert_eq!(ctx.widgets[tb].children().unwrap().len(), 1);
}

// ============================================================
// MenuBar
// ============================================================

#[test]
fn menu_bar_default() {
    let mb = MenuBar::default();
    assert!(mb.menus.is_empty());
}

#[test]
fn gui_context_add_menu_bar() {
    let mut ctx = GuiContext::new();
    let idx = ctx.add_menu_bar();
    assert!(idx > 0);
    assert_eq!(ctx.widgets[idx].base().widget_type.as_str(), "menubar");
}

// ============================================================
// MenuItem
// ============================================================

#[test]
fn menu_item_new_defaults() {
    let mi = MenuItem::new("File");
    assert_eq!(mi.text, "File");
    assert!(mi.shortcut.is_empty());
    assert!(!mi.checked);
    assert!(mi.items.is_empty());
}

#[test]
fn gui_context_add_menu_item() {
    let mut ctx = GuiContext::new();
    let idx = ctx.add_menu_item("Edit".to_string());
    assert!(idx > 0);
    assert_eq!(ctx.widgets[idx].base().widget_type.as_str(), "menuitem");
}

// ============================================================
// Dialog
// ============================================================

#[test]
fn dialog_new_defaults() {
    let d = Dialog::new("Confirm");
    assert_eq!(d.title, "Confirm");
    assert!(d.modal);
    assert!(!d.open);
    assert!(d.content_idx.is_none());
    assert!(d.footer_buttons.is_empty());
}

#[test]
fn dialog_content_and_footer() {
    let mut d = Dialog::new("Save");
    d.content_idx = Some(3);
    d.footer_buttons.push("OK".to_string());
    d.footer_buttons.push("Cancel".to_string());
    assert_eq!(d.content_idx, Some(3));
    assert_eq!(d.footer_buttons.len(), 2);
    assert_eq!(d.footer_buttons[0], "OK");
}

#[test]
fn gui_context_add_dialog() {
    let mut ctx = GuiContext::new();
    let idx = ctx.add_dialog("Save?".to_string());
    assert!(idx > 0);
    assert_eq!(ctx.widgets[idx].base().widget_type.as_str(), "dialog");
}

// ============================================================
// StatusBar
// ============================================================

#[test]
fn status_bar_default() {
    let sb = StatusBar::default();
    assert!(sb.sections.is_empty());
}

#[test]
fn gui_context_add_status_bar() {
    let mut ctx = GuiContext::new();
    let idx = ctx.add_status_bar();
    assert!(idx > 0);
    assert_eq!(ctx.widgets[idx].base().widget_type.as_str(), "statusbar");
}

// ============================================================
// Accordion
// ============================================================

#[test]
fn accordion_default() {
    let acc = Accordion::default();
    assert!(acc.sections.is_empty());
    assert!(!acc.exclusive);
}

#[test]
fn accordion_section_new() {
    let sec = AccordionSection {
        title: "Section A".to_string(),
        content_idx: Some(5),
        expanded: false,
    };
    assert_eq!(sec.title, "Section A");
    assert_eq!(sec.content_idx, Some(5));
}

#[test]
fn gui_context_add_accordion() {
    let mut ctx = GuiContext::new();
    let idx = ctx.add_accordion();
    assert!(idx > 0);
    assert_eq!(ctx.widgets[idx].base().widget_type.as_str(), "accordion");
}

// ============================================================
// TooltipPanel
// ============================================================

#[test]
fn tooltip_panel_new_defaults() {
    let tp = TooltipPanel::new("Hover me");
    assert_eq!(tp.text, "Hover me");
    assert!((tp.delay - 0.5).abs() < 1e-5);
    assert!(tp.target_idx.is_none());
}

#[test]
fn gui_context_add_tooltip_panel() {
    let mut ctx = GuiContext::new();
    let idx = ctx.add_tooltip_panel("tip".to_string());
    assert!(idx > 0);
    assert_eq!(ctx.widgets[idx].base().widget_type.as_str(), "tooltippanel");
}

// ============================================================
// ColorPicker
// ============================================================

#[test]
fn color_picker_default() {
    let cp = ColorPicker::default();
    assert!((cp.r - 1.0).abs() < 1e-5);
    assert!((cp.g - 1.0).abs() < 1e-5);
    assert!((cp.b - 1.0).abs() < 1e-5);
    assert!((cp.a - 1.0).abs() < 1e-5);
    assert!(cp.show_alpha);
    assert_eq!(cp.color_mode, "rgb");
}

#[test]
fn gui_context_add_color_picker() {
    let mut ctx = GuiContext::new();
    let idx = ctx.add_color_picker();
    assert!(idx > 0);
    assert_eq!(ctx.widgets[idx].base().widget_type.as_str(), "colorpicker");
}

// ============================================================
// GUITable
// ============================================================

#[test]
fn gui_table_default() {
    let tbl = GUITable::default();
    assert!(tbl.columns.is_empty());
    assert!(tbl.rows.is_empty());
    assert!(tbl.selected_row.is_none());
    assert!(!tbl.sortable);
}

#[test]
fn table_column_new() {
    let col = TableColumn {
        header: "Name".to_string(),
        width: 120.0,
    };
    assert_eq!(col.header, "Name");
    assert!((col.width - 120.0).abs() < 1e-5);
}

#[test]
fn gui_context_add_gui_table() {
    let mut ctx = GuiContext::new();
    let idx = ctx.add_gui_table();
    assert!(idx > 0);
    assert_eq!(ctx.widgets[idx].base().widget_type.as_str(), "guitable");
}

// ============================================================
// ImageWidget
// ============================================================

#[test]
fn image_widget_default() {
    let iw = ImageWidget::default();
    assert_eq!(iw.scale_mode, "fit");
    assert!((iw.tint.0 - 1.0).abs() < 1e-5);
    assert!((iw.tint.1 - 1.0).abs() < 1e-5);
    assert!((iw.tint.2 - 1.0).abs() < 1e-5);
    assert!((iw.tint.3 - 1.0).abs() < 1e-5);
}

#[test]
fn gui_context_add_image_widget() {
    let mut ctx = GuiContext::new();
    let idx = ctx.add_image_widget();
    assert!(idx > 0);
    assert_eq!(ctx.widgets[idx].base().widget_type.as_str(), "imagewidget");
}

// ============================================================
// WidgetType as_str for new types
// ============================================================

#[test]
fn widget_type_as_str_new_types() {
    assert_eq!(WidgetType::RadioButton.as_str(), "radiobutton");
    assert_eq!(WidgetType::ScrollBar.as_str(), "scrollbar");
    assert_eq!(WidgetType::GUIWindow.as_str(), "guiwindow");
    assert_eq!(WidgetType::SplitPanel.as_str(), "splitpanel");
    assert_eq!(WidgetType::DockPanel.as_str(), "dockpanel");
    assert_eq!(WidgetType::Toolbar.as_str(), "toolbar");
    assert_eq!(WidgetType::MenuBar.as_str(), "menubar");
    assert_eq!(WidgetType::MenuItem.as_str(), "menuitem");
    assert_eq!(WidgetType::Dialog.as_str(), "dialog");
    assert_eq!(WidgetType::StatusBar.as_str(), "statusbar");
    assert_eq!(WidgetType::Accordion.as_str(), "accordion");
    assert_eq!(WidgetType::TooltipPanel.as_str(), "tooltippanel");
    assert_eq!(WidgetType::ColorPicker.as_str(), "colorpicker");
    assert_eq!(WidgetType::GUITable.as_str(), "guitable");
    assert_eq!(WidgetType::ImageWidget.as_str(), "imagewidget");
}
