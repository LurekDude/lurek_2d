//! INTERNAL ONLY: public `lurek.ui.*` behavior is covered primarily by
//! `tests/lua/unit/test_ui_unit.lua` and related GUI/UI evidence suites.
//!
//! This Rust file keeps internal widget/theme/render helpers where Lua coverage
//! is still partial or placeholder-only, so the stronger assertions remain at
//! the Rust layer for now.

// ── widget ────────────────────────────────────────────────────────────────────

mod widget_tests {
    use lurek2d::ui::widget::{WidgetBase, WidgetState, WidgetType};

    #[test]
    fn widget_state_roundtrip() {
        for name in &["normal", "hovered", "pressed", "focused", "disabled"] {
            let state = WidgetState::parse_str(name).unwrap();
            assert_eq!(state.as_str(), *name);
        }
    }

    #[test]
    fn widget_state_parse_unknown_returns_none() {
        assert!(WidgetState::parse_str("unknown").is_none());
    }

    #[test]
    fn widget_base_contains_point() {
        let mut base = WidgetBase::new(WidgetType::Button);
        base.x = 10.0;
        base.y = 20.0;
        base.width = 100.0;
        base.height = 50.0;
        assert!(base.contains_point(50.0, 40.0));
        assert!(!base.contains_point(5.0, 40.0));
    }

    #[test]
    fn widget_base_default_is_panel() {
        let base = WidgetBase::default();
        assert!(base.visible);
        assert!(base.enabled);
    }

    #[test]
    fn widget_type_as_str_button() {
        assert_eq!(WidgetType::Button.as_str(), "button");
    }
}

// ── theme ─────────────────────────────────────────────────────────────────────

mod theme_tests {
    use lurek2d::ui::theme::{Theme, WidgetStyle};
    use lurek2d::ui::widget::{WidgetState, WidgetType};

    #[test]
    fn theme_set_and_get_style() {
        let mut t = Theme::new();
        let style = WidgetStyle::default();
        t.set_style(WidgetType::Button, WidgetState::Normal, style.clone());
        assert!(t
            .get_style(WidgetType::Button, WidgetState::Normal)
            .is_some());
    }

    #[test]
    fn theme_fallback_to_normal_state() {
        let mut t = Theme::new();
        t.set_style(
            WidgetType::Button,
            WidgetState::Normal,
            WidgetStyle::default(),
        );
        // Requesting Hovered should fall back to Normal.
        assert!(t
            .get_style(WidgetType::Button, WidgetState::Hovered)
            .is_some());
    }

    #[test]
    fn theme_missing_type_returns_none() {
        let t = Theme::new();
        assert!(t
            .get_style(WidgetType::Label, WidgetState::Normal)
            .is_none());
    }

    #[test]
    fn widget_style_default_values() {
        let s = WidgetStyle::default();
        assert_eq!(s.font_size, 14.0);
        assert_eq!(s.border_width, 1.0);
        assert_eq!(s.corner_radius, 0.0);
    }
}

// ── render ────────────────────────────────────────────────────────────────────

mod render_tests {
    use lurek2d::render::RenderCommand;
    use lurek2d::runtime::resource_keys::FontKey;
    use lurek2d::ui::context::GuiContext;

    #[test]
    fn empty_context_no_commands() {
        let mut ctx = GuiContext::new();
        let cmds = ctx.build_render_commands(FontKey::default());
        assert!(cmds.is_empty());
    }

    #[test]
    fn button_emits_box_and_text() {
        let mut ctx = GuiContext::new();
        let idx = ctx.add_button("Click");
        ctx.add_child(0, idx);
        let cmds = ctx.build_render_commands(FontKey::default());
        // At minimum: SetColor + Rectangle (bg) + SetColor + SetLineWidth + Rectangle (border) + SetColor + Print (text)
        assert!(
            cmds.len() >= 5,
            "expected at least 5 commands, got {}",
            cmds.len()
        );
        let has_print = cmds
            .iter()
            .any(|c| matches!(c, RenderCommand::Print { text, .. } if text == "Click"));
        assert!(has_print, "expected a Print command with 'Click'");
    }

    #[test]
    fn invisible_widget_no_commands() {
        let mut ctx = GuiContext::new();
        let idx = ctx.add_label("Hidden");
        ctx.add_child(0, idx);
        // Make the label invisible
        ctx.widgets[idx].base_mut().visible = false;
        let cmds = ctx.build_render_commands(FontKey::default());
        assert!(cmds.is_empty());
    }

    #[test]
    fn label_emits_text() {
        let mut ctx = GuiContext::new();
        let idx = ctx.add_label("Hello");
        ctx.add_child(0, idx);
        let cmds = ctx.build_render_commands(FontKey::default());
        let has_print = cmds
            .iter()
            .any(|c| matches!(c, RenderCommand::Print { text, .. } if text == "Hello"));
        assert!(has_print, "expected a Print command with 'Hello'");
    }

    #[test]
    fn generate_render_commands_matches_build() {
        let mut ctx = GuiContext::new();
        let idx = ctx.add_button("Ok");
        ctx.add_child(0, idx);
        let a = ctx.generate_render_commands();
        let b = ctx.build_render_commands(FontKey::default());
        assert_eq!(
            a.len(),
            b.len(),
            "generate_render_commands must produce same count as build_render_commands"
        );
    }

    #[test]
    fn draw_to_image_returns_correct_size() {
        let ctx = GuiContext::new();
        let img = ctx.draw_to_image(64, 48);
        assert_eq!(img.width(), 64);
        assert_eq!(img.height(), 48);
    }
}

// ── layout_loader ─────────────────────────────────────────────────────────────

mod layout_loader_tests {
    use std::fs;
    use lurek2d::ui::context::GuiContext;
    use lurek2d::ui::layout_loader::{load_layout_def, load_layout_toml, LayoutDef, WidgetDef};

    #[test]
    fn widget_def_default_has_empty_type() {
        let def = WidgetDef::default();
        assert!(def.widget_type.is_empty());
        assert!(def.children.is_none());
    }

    #[test]
    fn load_layout_toml_parses_simple_panel() {
        let toml_src = r#"
[root]
widget_type = "panel"
w = 200.0
h = 100.0
"#;
        let mut ctx = GuiContext::new();
        let result = load_layout_toml(&mut ctx, toml_src);
        assert!(result.is_ok());
    }

    #[test]
    fn load_layout_def_rejects_unknown_type() {
        let def = WidgetDef {
            widget_type: "unknown_widget".to_string(),
            ..Default::default()
        };
        let mut ctx = GuiContext::new();
        assert!(load_layout_def(&mut ctx, &def).is_err());
    }

    #[test]
    fn layout_def_with_resolution() {
        let toml_src = r#"
resolution = [800, 600]

[root]
widget_type = "panel"
w = 800.0
h = 600.0
"#;
        let def: LayoutDef = toml::from_str(toml_src).unwrap();
        assert_eq!(def.resolution, Some([800, 600]));
    }

    #[test]
    fn load_layout_def_handles_nested_tree_ids() {
        let def = WidgetDef {
            widget_type: "panel".to_string(),
            id: Some("root".to_string()),
            children: Some(vec![WidgetDef {
                widget_type: "panel".to_string(),
                id: Some("left".to_string()),
                children: Some(vec![WidgetDef {
                    widget_type: "label".to_string(),
                    id: Some("score".to_string()),
                    text: Some("Score".to_string()),
                    ..Default::default()
                }]),
                ..Default::default()
            }]),
            ..Default::default()
        };
        let mut ctx = GuiContext::new();
        let root_idx = load_layout_def(&mut ctx, &def).expect("layout should load");
        ctx.add_child(0, root_idx);

        let found = ctx.find_by_id(root_idx, "score");
        assert!(found.is_some(), "nested id should resolve");
    }

    #[test]
    fn render_to_image_writes_png_file() {
        let mut ctx = GuiContext::new();
        let panel = ctx.add_panel();
        ctx.add_child(0, panel);

        let out = std::env::temp_dir().join("lurek_ui_layout_loader_test.png");
        let _ = fs::remove_file(&out);
        let out_s = out.to_string_lossy().to_string();

        lurek2d::ui::render_to_image(&mut ctx, 96, 64, &out_s).expect("render_to_image should succeed");

        let meta = fs::metadata(&out).expect("png should exist");
        assert!(meta.len() > 0, "png should not be empty");
        let _ = fs::remove_file(out);
    }
}

// ── extras ────────────────────────────────────────────────────────────────────

mod extras_tests {
    use lurek2d::ui::extras::*;

    #[test]
    fn toast_progress_starts_at_zero() {
        let t = Toast::new("Hello", 5.0);
        assert_eq!(t.progress(), 0.0);
        assert!(!t.is_expired());
    }

    #[test]
    fn toast_expires_after_duration() {
        let mut t = Toast::new("Bye", 1.0);
        t.update(1.5);
        assert!(t.is_expired());
        assert!((t.progress() - 1.0).abs() < f32::EPSILON);
    }

    #[test]
    fn toast_zero_duration_is_immediately_done() {
        let t = Toast::new("Instant", 0.0);
        assert_eq!(t.progress(), 1.0);
    }

    #[test]
    fn separator_horizontal_dimensions() {
        let sep = Separator::new(false);
        assert!(!sep.vertical);
        assert_eq!(sep.base.width, 100.0);
    }

    #[test]
    fn separator_vertical_dimensions() {
        let sep = Separator::new(true);
        assert!(sep.vertical);
        assert_eq!(sep.base.height, 30.0);
    }

    #[test]
    fn spacer_default_zero_size() {
        let sp = Spacer::default();
        assert_eq!(sp.base.width, 0.0);
        assert_eq!(sp.base.height, 0.0);
    }

    #[test]
    fn badge_display_text_normal() {
        let b = Badge::new(42);
        assert_eq!(b.display_text(), "42");
    }

    #[test]
    fn badge_display_text_overflow() {
        let b = Badge::new(150);
        assert_eq!(b.display_text(), "99+");
    }

    #[test]
    fn badge_set_count() {
        let mut b = Badge::new(0);
        b.set_count(5);
        assert_eq!(b.count, 5);
    }

    #[test]
    fn tree_node_new_has_no_children() {
        let node = TreeNode::new("root", None);
        assert!(node.children.is_empty());
        assert!(!node.expanded);
    }
}

// ── context ───────────────────────────────────────────────────────────────────

mod context_tests {
    use std::collections::HashMap;
    use lurek2d::ui::context::GuiContext;
    use lurek2d::ui::UiBindingValue;

    #[test]
    fn new_context_has_root_panel() {
        let ctx = GuiContext::new();
        assert_eq!(ctx.widget_count(), 1, "root panel at index 0");
    }

    #[test]
    fn add_button_increases_widget_count() {
        let mut ctx = GuiContext::new();
        let idx = ctx.add_button("Test");
        assert!(idx > 0);
        assert_eq!(ctx.widget_count(), 2);
    }

    #[test]
    fn add_label_and_retrieve_base() {
        let mut ctx = GuiContext::new();
        let idx = ctx.add_label("Hello");
        let base = ctx.widgets[idx].base();
        assert!(base.visible);
    }

    #[test]
    fn add_child_and_child_count() {
        let mut ctx = GuiContext::new();
        let panel = ctx.add_panel();
        let btn = ctx.add_button("OK");
        ctx.add_child(panel, btn);
        assert_eq!(ctx.child_count(panel), 1);
    }

    #[test]
    fn remove_child() {
        let mut ctx = GuiContext::new();
        let panel = ctx.add_panel();
        let btn = ctx.add_button("OK");
        ctx.add_child(panel, btn);
        ctx.remove_child(panel, btn);
        assert_eq!(ctx.child_count(panel), 0);
    }

    #[test]
    fn set_focus_and_focus_next() {
        let mut ctx = GuiContext::new();
        let b1 = ctx.add_button("A");
        let b2 = ctx.add_button("B");
        ctx.set_focus(Some(b1));
        ctx.focus_next();
        assert_eq!(ctx.focused_widget, Some(b2));
    }

    #[test]
    fn toast_lifecycle() {
        let mut ctx = GuiContext::new();
        ctx.add_toast(lurek2d::ui::Toast::new("Hello", 1.0));
        assert_eq!(ctx.toast_count(), 1);
        ctx.update(2.0);
        assert_eq!(ctx.toast_count(), 0, "toast should expire");
    }

    #[test]
    fn drain_events_returns_empty_initially() {
        let mut ctx = GuiContext::new();
        let events = ctx.drain_events();
        assert!(events.is_empty());
    }

    #[test]
    fn find_by_id_returns_none_for_missing() {
        let ctx = GuiContext::new();
        assert!(ctx.find_by_id(0, "nonexistent").is_none());
    }

    #[test]
    fn default_context_equals_new() {
        let ctx = GuiContext::default();
        assert_eq!(ctx.widget_count(), 1);
    }

    #[test]
    fn drag_drop_moves_widget_between_containers() {
        let mut ctx = GuiContext::new();
        let left = ctx.add_panel();
        let right = ctx.add_panel();
        let item = ctx.add_button("Item");

        ctx.add_child(0, left);
        ctx.add_child(0, right);
        ctx.add_child(left, item);
        assert_eq!(ctx.child_count(left), 1);
        assert_eq!(ctx.child_count(right), 0);

        assert!(ctx.begin_drag(item));
        assert_eq!(ctx.active_drag(), Some(item));
        assert!(ctx.drop_on(right));

        assert_eq!(ctx.child_count(left), 0);
        assert_eq!(ctx.child_count(right), 1);
        assert_eq!(ctx.active_drag(), None);
    }

    #[test]
    fn alpha_animation_progresses_during_update() {
        let mut ctx = GuiContext::new();
        let idx = ctx.add_button("Anim");
        ctx.widgets[idx].base_mut().alpha = 0.0;

        assert!(ctx.animate_alpha(idx, 1.0, 1.0, false));
        assert!(ctx.is_animating(idx));

        ctx.update(0.5);
        let mid = ctx.widgets[idx].base().alpha;
        assert!(mid > 0.0 && mid < 1.0, "expected interpolated alpha, got {mid}");

        ctx.update(0.6);
        let end = ctx.widgets[idx].base().alpha;
        assert!((end - 1.0).abs() < 1e-5, "alpha should finish at 1.0, got {end}");
        assert!(!ctx.is_animating(idx));
    }

    #[test]
    fn update_bindings_updates_multiple_widget_types() {
        let mut ctx = GuiContext::new();
        let label = ctx.add_label("old");
        let switch = ctx.add_switch(false);
        let slider = ctx.add_slider(0.0, 100.0);

        ctx.widgets[label].base_mut().bind_key = Some("hp_text".to_string());
        ctx.widgets[switch].base_mut().bind_key = Some("enabled".to_string());
        ctx.widgets[slider].base_mut().bind_key = Some("value".to_string());

        let mut values = HashMap::new();
        values.insert("hp_text".to_string(), UiBindingValue::Text("HP: 80".to_string()));
        values.insert("enabled".to_string(), UiBindingValue::Bool(true));
        values.insert("value".to_string(), UiBindingValue::Number(42.0));

        let changed = ctx.update_bindings(&values);
        assert!(changed >= 3);

        match &ctx.widgets[label] {
            lurek2d::ui::context::WidgetKind::Label(lbl) => assert_eq!(lbl.text, "HP: 80"),
            _ => panic!("expected label"),
        }
        match &ctx.widgets[switch] {
            lurek2d::ui::context::WidgetKind::Switch(sw) => assert!(sw.on),
            _ => panic!("expected switch"),
        }
        match &ctx.widgets[slider] {
            lurek2d::ui::context::WidgetKind::Slider(sl) => assert!((sl.value - 42.0).abs() < f64::EPSILON),
            _ => panic!("expected slider"),
        }
    }
}

// ── data_graph_renderer ───────────────────────────────────────────────────────

mod data_graph_renderer_tests {
    use lurek2d::math::Color;
    use lurek2d::ui::data_graph_renderer::GraphRenderer;

    #[test]
    fn default_renderer_has_sensible_defaults() {
        let gr = GraphRenderer::new();
        assert!(gr.show_grid);
        assert!(gr.show_axes);
        assert_eq!(gr.series().len(), 0);
    }

    #[test]
    fn add_and_remove_series() {
        let mut gr = GraphRenderer::new();
        gr.add_line_series("sin", vec![(0.0, 0.0), (1.0, 1.0)], Color::RED);
        gr.add_scatter_series("pts", vec![(2.0, 3.0)], Color::WHITE, 4.0);
        assert_eq!(gr.get_series_names().len(), 2);
        assert!(gr.remove_series("sin"));
        assert!(!gr.remove_series("sin"));
        assert_eq!(gr.get_series_names().len(), 1);
    }

    #[test]
    fn world_to_screen_and_back() {
        let mut gr = GraphRenderer::new();
        gr.set_viewport(0.0, 0.0, 400.0, 300.0);
        gr.set_range(0.0, 10.0, 0.0, 10.0);

        let (sx, sy) = gr.world_to_screen(5.0, 5.0);
        assert!((sx - 200.0).abs() < 1e-3);
        assert!((sy - 150.0).abs() < 1e-3);

        let (wx, wy) = gr.screen_to_world(sx, sy);
        assert!((wx - 5.0).abs() < 1e-3);
        assert!((wy - 5.0).abs() < 1e-3);
    }

    #[test]
    fn auto_range_with_padding() {
        let mut gr = GraphRenderer::new();
        gr.add_line_series("f", vec![(0.0, 0.0), (10.0, 10.0)], Color::WHITE);
        gr.auto_range();
        let (x_min, x_max, y_min, y_max) = gr.get_range();
        assert!(x_min < 0.0);
        assert!(x_max > 10.0);
        assert!(y_min < 0.0);
        assert!(y_max > 10.0);
    }

    #[test]
    fn bar_series_auto_range_includes_zero() {
        let mut gr = GraphRenderer::new();
        gr.add_bar_series("bars", vec![5.0, 10.0, 3.0], Color::RED);
        gr.auto_range();
        let (_, _, y_min, _) = gr.get_range();
        assert!(y_min <= 0.0);
    }

    #[test]
    fn clear_series_empties_all() {
        let mut gr = GraphRenderer::new();
        gr.add_line_series("a", vec![], Color::WHITE);
        gr.add_line_series("b", vec![], Color::RED);
        gr.clear_series();
        assert_eq!(gr.get_series_names().len(), 0);
    }

    #[test]
    fn cursor_round_trip() {
        let mut gr = GraphRenderer::new();
        assert!(gr.get_cursor_value().is_none());
        gr.set_cursor_position(3.14, 2.71);
        let (cx, cy) = gr.get_cursor_value().unwrap();
        assert!((cx - 3.14).abs() < 1e-10);
        assert!((cy - 2.71).abs() < 1e-10);
    }
}

// ── controls ──────────────────────────────────────────────────────────────────

mod controls_tests {
    use lurek2d::ui::controls::*;

    #[test]
    fn button_new_stores_text() {
        let b = Button::new("Click me");
        assert_eq!(b.text, "Click me");
    }

    #[test]
    fn text_input_insert_and_backspace() {
        let mut ti = TextInput::new();
        assert!(ti.insert_text("abc"));
        assert_eq!(ti.text, "abc");
        assert_eq!(ti.cursor_pos, 3);
        assert!(ti.backspace());
        assert_eq!(ti.text, "ab");
    }

    #[test]
    fn text_input_max_length_enforced() {
        let mut ti = TextInput::new();
        ti.max_length = 3;
        assert!(ti.insert_text("ab"));
        assert!(!ti.insert_text("cd"));
        assert_eq!(ti.text, "ab");
    }

    #[test]
    fn checkbox_default_unchecked() {
        let cb = CheckBox::new("opt");
        assert!(!cb.checked);
    }

    #[test]
    fn switch_toggle() {
        let mut sw = Switch::new(false);
        assert!(!sw.on);
        sw.toggle();
        assert!(sw.on);
        sw.toggle();
        assert!(!sw.on);
    }
}

// ── containers ────────────────────────────────────────────────────────────────

mod containers_tests {
    use lurek2d::ui::containers::*;

    #[test]
    fn panel_new_has_no_children() {
        let p = Panel::new();
        assert!(p.children.is_empty());
        assert!(!p.scrollable);
    }

    #[test]
    fn layout_direction_roundtrip() {
        for name in &["vertical", "horizontal", "grid"] {
            let dir = LayoutDirection::parse_str(name).unwrap();
            assert_eq!(dir.as_str(), *name);
        }
    }

    #[test]
    fn layout_direction_parse_unknown_returns_none() {
        assert!(LayoutDirection::parse_str("diagonal").is_none());
    }

    #[test]
    fn layout_new_defaults() {
        let l = Layout::new(LayoutDirection::Vertical);
        assert_eq!(l.spacing, 0.0);
        assert!(!l.wrap);
        assert_eq!(l.align, "start");
        assert_eq!(l.justify, "start");
    }

    #[test]
    fn dock_panel_default() {
        let dp = DockPanel::new();
        assert!(dp.docked.is_empty());
    }
}

// ── chart ─────────────────────────────────────────────────────────────────────

mod chart_tests {
    use lurek2d::image::ImageData;
    use lurek2d::math::Color;
    use lurek2d::ui::chart::*;

    #[test]
    fn chart_config_default_has_sane_dimensions() {
        let cfg = ChartConfig::default();
        assert_eq!(cfg.width, 400);
        assert_eq!(cfg.height, 300);
        assert!(cfg.show_grid);
    }

    #[test]
    fn chart_margin_default_values() {
        let m = ChartMargin::default();
        assert_eq!(m.left, 40);
        assert_eq!(m.right, 20);
        assert_eq!(m.top, 30);
        assert_eq!(m.bottom, 40);
    }

    #[test]
    fn line_chart_add_series_and_draw() {
        let mut lc = LineChart::new(ChartConfig::default());
        lc.series.push(ChartSeries {
            name: "test".to_string(),
            color: Color::new(1.0, 0.0, 0.0, 1.0),
            values: vec![(0.0, 0.0), (1.0, 50.0), (2.0, 100.0)],
        });
        let mut img = ImageData::new(400, 300);
        lc.draw_to_image(&mut img);
        assert_eq!(img.width(), 400);
        assert_eq!(img.height(), 300);
    }

    #[test]
    fn pie_chart_draw_produces_correct_size() {
        let mut pc = PieChart::new(ChartConfig::default());
        pc.add_segment("A", 50.0, Color::new(1.0, 0.0, 0.0, 1.0));
        pc.add_segment("B", 50.0, Color::new(0.0, 1.0, 0.0, 1.0));
        let mut img = ImageData::new(400, 300);
        pc.draw_to_image(&mut img);
        assert_eq!(img.width(), 400);
    }

    #[test]
    fn bar_chart_empty_draw_does_not_panic() {
        let bc = BarChart::new(ChartConfig::default());
        let mut img = ImageData::new(400, 300);
        bc.draw_to_image(&mut img);
        assert_eq!(img.width(), 400);
    }

    #[test]
    fn scatter_plot_zero_range_draw_does_not_panic() {
        let mut scatter = ScatterPlot::new(ChartConfig::default());
        scatter.x_range = (1.0, 1.0);
        scatter.y_range = (5.0, 5.0);
        scatter.add_series("cluster", &[(1.0, 5.0), (1.0, 5.0)], Color::new(0.2, 0.7, 0.9, 1.0));

        let mut img = ImageData::new(320, 240);
        scatter.draw_to_image(&mut img);
        assert_eq!(img.height(), 240);
    }

    #[test]
    fn area_chart_sparse_layers_draw_does_not_panic() {
        let mut area = AreaChart::new(ChartConfig::default());
        area.y_max = 20.0;
        area.add_layer("a", &[1.0, 2.0, 3.0], Color::new(0.2, 0.4, 0.8, 1.0));
        area.add_layer("b", &[0.0], Color::new(0.8, 0.4, 0.2, 1.0));

        let mut img = ImageData::new(320, 200);
        area.draw_to_image(&mut img);
        assert_eq!(img.width(), 320);
    }
}
