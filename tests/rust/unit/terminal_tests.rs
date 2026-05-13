//! INTERNAL ONLY: public `lurek.terminal.*` behavior is covered by the Lua-first suite in
//! `tests/lua/unit/test_terminal_unit.lua` plus targeted integration tests.
//!
//! The Rust coverage that remains here focuses on lower-level ANSI helpers,
//! render-command generation, and widget internals that are more direct to
//! assert outside the Lua binding layer.

// ── cell ──────────────────────────────────────────────────────────────────────

mod cell_tests {
    use lurek2d::terminal::TCell;

    #[test]
    fn default_cell_is_space() {
        let cell = TCell::default();
        assert_eq!(cell.ch, b' ' as u32);
    }

    #[test]
    fn cell_clone_eq() {
        let a = TCell::default();
        let b = a;
        assert_eq!(a, b);
    }
}

// ── ansi ──────────────────────────────────────────────────────────────────────

mod ansi_tests {
    use lurek2d::terminal::ansi::{parse_ansi_spans, strip_ansi_codes};

    #[test]
    fn strip_removes_color_codes() {
        let s = "\x1b[31mHello\x1b[0m world";
        assert_eq!(strip_ansi_codes(s), "Hello world");
    }

    #[test]
    fn strip_empty_sequence() {
        let s = "\x1b[mText";
        assert_eq!(strip_ansi_codes(s), "Text");
    }

    #[test]
    fn parse_spans_plain_text_becomes_single_span() {
        let spans = parse_ansi_spans("hello");
        assert_eq!(spans.len(), 1);
        assert_eq!(spans[0].text, "hello");
        assert!(spans[0].fg.is_none());
    }

    #[test]
    fn parse_spans_red_text_has_correct_color() {
        let spans = parse_ansi_spans("\x1b[31mred\x1b[0m");
        assert!(!spans.is_empty());
        let red_span = spans.iter().find(|s| s.text == "red").unwrap();
        assert!(red_span.fg.is_some());
        assert_eq!(red_span.fg.as_ref().unwrap().r, 170);
    }

    #[test]
    fn parse_spans_bold_flag() {
        let spans = parse_ansi_spans("\x1b[1mBold\x1b[0m");
        let bold_span = spans.iter().find(|s| s.text == "Bold").unwrap();
        assert!(bold_span.bold);
    }

    #[test]
    fn parse_spans_reset_clears_color() {
        let spans = parse_ansi_spans("\x1b[31mred\x1b[0mnormal");
        let normal_span = spans.iter().find(|s| s.text == "normal").unwrap();
        assert!(normal_span.fg.is_none());
    }

    #[test]
    fn parse_spans_supports_256_fg_color() {
        let spans = parse_ansi_spans("\x1b[38;5;196mhot\x1b[0m");
        let hot = spans.iter().find(|s| s.text == "hot").unwrap();
        let fg = hot.fg.as_ref().unwrap();
        assert_eq!((fg.r, fg.g, fg.b), (255, 0, 0));
    }

    #[test]
    fn parse_spans_supports_truecolor_bg() {
        let spans = parse_ansi_spans("\x1b[48;2;10;20;30mcell\x1b[0m");
        let cell = spans.iter().find(|s| s.text == "cell").unwrap();
        let bg = cell.bg.as_ref().unwrap();
        assert_eq!((bg.r, bg.g, bg.b), (10, 20, 30));
    }
}

// ── widget ────────────────────────────────────────────────────────────────────

mod widget_tests {
    use lurek2d::terminal::{BorderStyle, WidgetBase};

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
        let mut base = WidgetBase::new(5, 10, 20, 15);
        assert_eq!(base.position_1based(), (6, 11));
        base.set_position_1based(3, 7);
        assert_eq!(base.x, 2);
        assert_eq!(base.y, 6);
    }
}

// ── terminal_state ────────────────────────────────────────────────────────────

mod terminal_state_tests {}

// ── render ────────────────────────────────────────────────────────────────────

mod render_tests {
    use lurek2d::render::RenderCommand;
    use lurek2d::runtime::resource_keys::FontKey;
    use lurek2d::terminal::Terminal;
    use slotmap::KeyData;

    fn dummy_font() -> FontKey {
        FontKey::from(KeyData::from_ffi(1))
    }

    #[test]
    fn generate_render_commands_empty_terminal_returns_empty() {
        let t = Terminal::new(4, 2);
        let cmds = t.generate_render_commands(dummy_font(), 8.0, 16.0, 1.0);
        assert!(cmds.is_empty(), "blank terminal should emit no commands");
    }

    #[test]
    fn generate_render_commands_single_char_emits_color_and_print() {
        let mut t = Terminal::new(4, 2);
        t.set(
            1,
            1,
            b'A' as u32,
            [1.0, 1.0, 1.0, 1.0],
            [0.0, 0.0, 0.0, 0.0],
        );
        let cmds = t.generate_render_commands(dummy_font(), 8.0, 16.0, 1.0);
        assert_eq!(cmds.len(), 2, "SetColor + Print for one non-space cell");
        assert!(matches!(cmds[0], RenderCommand::SetColor(_, _, _, _)));
        assert!(matches!(cmds[1], RenderCommand::Print { .. }));
    }

    #[test]
    fn draw_to_image_correct_dimensions() {
        let t = Terminal::new(8, 4);
        let img = t.draw_to_image(160, 80);
        assert_eq!(img.width(), 160);
        assert_eq!(img.height(), 80);
    }

    #[test]
    fn draw_to_image_non_space_cell_writes_pixels() {
        let mut t = Terminal::new(2, 2);
        t.set(
            1,
            1,
            b'X' as u32,
            [1.0, 0.0, 0.0, 1.0],
            [0.0, 0.0, 0.0, 0.0],
        );
        let img = t.draw_to_image(64, 32);
        if let Some((r, g, b, _)) = img.get_pixel(0, 0) {
            assert!(r > 100 && g < 50 && b < 50, "expected red cell pixel");
        }
    }
}

// ── completion ────────────────────────────────────────────────────────────────

mod completion_tests {
    use lurek2d::terminal::completion::CompletionEngine;

    #[test]
    fn empty_engine_returns_no_completions() {
        let e = CompletionEngine::new();
        assert!(e.completions_for("he").is_empty());
    }

    #[test]
    fn single_match_returned() {
        let mut e = CompletionEngine::new();
        e.add_candidate("help");
        assert_eq!(e.completions_for("hel"), vec!["help"]);
    }

    #[test]
    fn multiple_matches_sorted() {
        let mut e = CompletionEngine::new();
        e.add_candidate("hello");
        e.add_candidate("help");
        let got = e.completions_for("hel");
        assert_eq!(got, vec!["hello", "help"]);
    }

    #[test]
    fn next_completion_cycles_on_repeated_calls() {
        let mut e = CompletionEngine::new();
        e.add_candidate("hello");
        e.add_candidate("help");
        let first = e.next_completion("hel").unwrap();
        let second = e.next_completion("hel").unwrap();
        assert_ne!(first, second);
    }

    #[test]
    fn next_completion_resets_on_prefix_change() {
        let mut e = CompletionEngine::new();
        e.add_candidate("hello");
        e.add_candidate("world");
        let _ = e.next_completion("hel");
        let w = e.next_completion("wor").unwrap();
        assert_eq!(w, "world");
    }

    #[test]
    fn remove_candidate_removes_it() {
        let mut e = CompletionEngine::new();
        e.add_candidate("help");
        e.remove_candidate("help");
        assert!(e.completions_for("hel").is_empty());
    }
}
