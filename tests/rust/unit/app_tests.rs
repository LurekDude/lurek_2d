//! Tests for the app module.

use lurek2d::app::debug_overlay::DebugOverlay;
use lurek2d::app::error_screen::{format_traceback, wrap_text, ErrorScreen};
use lurek2d::runtime::error::EngineError;
use lurek2d::runtime::resource_keys::FontKey;
use slotmap::SlotMap;

// ── error_screen ─────────────────────────────────────────────────────────────

mod error_screen_tests {
    use super::*;

    #[test]
    fn test_wrap_text_short_string() {
        let result = wrap_text("hello world", 80);
        assert_eq!(result, vec!["hello world"]);
    }

    #[test]
    fn test_wrap_text_long_string() {
        let input = "the quick brown fox jumps over the lazy dog and keeps running";
        let result = wrap_text(input, 30);
        for line in &result {
            assert!(line.len() <= 30, "line too long: {}", line);
        }
        let joined = result.join(" ");
        assert_eq!(joined, input);
    }

    #[test]
    fn test_wrap_text_empty() {
        let result = wrap_text("", 80);
        assert!(result.is_empty());
    }

    #[test]
    fn test_format_traceback_cleans_string_markers() {
        let input = r#"stack traceback:
	[string "main.lua"]:10: in function 'update'
	[string "main.lua"]:5: in main chunk"#;
        let result = format_traceback(input);
        assert_eq!(result.len(), 2);
        assert!(result[0].contains("main.lua:10"));
        assert!(!result[0].contains("[string"));
    }

    #[test]
    fn test_format_traceback_strips_header() {
        let input = "stack traceback:\n\t[string \"test\"]:1: in main chunk";
        let result = format_traceback(input);
        for line in &result {
            assert!(!line.contains("stack traceback:"));
        }
    }

    #[test]
    fn test_error_screen_from_simple_message() {
        let screen = ErrorScreen::from_error("Something went wrong");
        let text = screen.as_text();
        assert!(text.contains("Something went wrong"));
        let cmds = screen.build_render_commands(800, 600, None, None);
        assert!(!cmds.is_empty());
    }

    #[test]
    fn test_error_screen_from_multiline_message() {
        let screen = ErrorScreen::from_error("Error in update\ndetail line 1\ndetail line 2");
        let text = screen.as_text();
        assert!(text.contains("Error in update"));
    }

    #[test]
    fn test_error_screen_from_engine_error() {
        let err = EngineError::LuaError("test error".to_string());
        let screen = ErrorScreen::from_engine_error(&err);
        assert!(screen.as_text().contains("Lua error"));
    }
}

// ── debug_overlay ────────────────────────────────────────────────────────────

mod debug_overlay_tests {
    use super::*;

    #[test]
    fn test_disabled_returns_empty() {
        let overlay = DebugOverlay::new();
        assert!(!overlay.enabled);
        let mut fonts: SlotMap<FontKey, ()> = SlotMap::with_key();
        let fk = fonts.insert(());
        let cmds = overlay.build_render_commands(800, 60.0, 10, Some(fk));
        assert!(cmds.is_empty());
    }

    #[test]
    fn test_enabled_returns_commands() {
        let mut overlay = DebugOverlay::new();
        overlay.enabled = true;
        let mut fonts: SlotMap<FontKey, ()> = SlotMap::with_key();
        let fk = fonts.insert(());
        let cmds = overlay.build_render_commands(800, 60.0, 10, Some(fk));
        assert!(!cmds.is_empty());
    }

    #[test]
    fn test_enabled_no_font_returns_empty() {
        let mut overlay = DebugOverlay::new();
        overlay.enabled = true;
        let cmds = overlay.build_render_commands(800, 60.0, 10, None);
        assert!(cmds.is_empty());
    }
}

// ── app ─────────────────────────────────────────────────────────────

mod app_tests {
    use lurek2d::app::app::*;

    use tempfile::TempDir;

    #[test]
    fn test_init_lua_applies_identity_to_filesystem_state_and_api() {
        let temp_dir = TempDir::new().expect("Failed to create temp dir");
        let mut config = Config::default();
        config.identity = Some("phase01-save".to_string());

        let mut app = LunaApp::new(config, temp_dir.path().to_path_buf(), None, false, None, 1);
        app.init_lua();

        let lua = app.lua.as_ref().expect("Lua VM should be initialized");
        let reported_identity: String = lua
            .load("return lurek.filesystem.getIdentity()")
            .eval()
            .expect("filesystem identity should be readable from Lua");
        assert_eq!(reported_identity, "phase01-save");

        let state = app
            .state
            .as_ref()
            .expect("shared state should be initialized");
        assert_eq!(state.borrow().filesystem_identity, "phase01-save");
        assert!(matches!(app.run_state, RunState::Running));
    }

    // ── recompute_viewport ────────────────────────────────────────────────────

    /// Build a WindowState with the given mode and game size for viewport tests.
    fn make_ws(mode: &str, game_w: f32, game_h: f32) -> WindowState {
        let mut ws = WindowState::default();
        ws.scale_mode_str = mode.to_string();
        ws.game_width = game_w;
        ws.game_height = game_h;
        ws
    }

    #[test]
    fn recompute_viewport_letterbox_wide_window_uses_height_limited_scale() {
        // 800×600 game, 1600×600 window → scale limited by height (600/600 = 1.0)
        let mut ws = make_ws("letterbox", 800.0, 600.0);
        recompute_viewport(&mut ws, 1600, 600);
        assert!(
            (ws.viewport_scale_x - 1.0).abs() < 1e-4,
            "scale_x should be 1.0, got {}",
            ws.viewport_scale_x
        );
        assert!(
            (ws.viewport_scale_y - 1.0).abs() < 1e-4,
            "scale_y should be 1.0, got {}",
            ws.viewport_scale_y
        );
        // offset_x = (1600 - 800*1) * 0.5 = 400
        assert!(
            (ws.viewport_offset_x - 400.0).abs() < 1e-4,
            "offset_x should be 400.0, got {}",
            ws.viewport_offset_x
        );
        assert!(
            ws.viewport_offset_y.abs() < 1e-4,
            "offset_y should be 0.0, got {}",
            ws.viewport_offset_y
        );
    }

    #[test]
    fn recompute_viewport_letterbox_tall_window_adds_top_bottom_bars() {
        // 800×600 game, 800×900 window → scale = min(1.0, 1.5) = 1.0
        let mut ws = make_ws("letterbox", 800.0, 600.0);
        recompute_viewport(&mut ws, 800, 900);
        assert!(
            (ws.viewport_scale_x - 1.0).abs() < 1e-4,
            "scale_x should be 1.0, got {}",
            ws.viewport_scale_x
        );
        assert!(
            (ws.viewport_scale_y - 1.0).abs() < 1e-4,
            "scale_y should be 1.0, got {}",
            ws.viewport_scale_y
        );
        assert!(
            ws.viewport_offset_x.abs() < 1e-4,
            "offset_x should be 0.0, got {}",
            ws.viewport_offset_x
        );
        // offset_y = (900 - 600*1) * 0.5 = 150
        assert!(
            (ws.viewport_offset_y - 150.0).abs() < 1e-4,
            "offset_y should be 150.0, got {}",
            ws.viewport_offset_y
        );
    }

    #[test]
    fn recompute_viewport_letterbox_doubled_window_gives_scale_two() {
        // 800×600 game, 1600×1200 window → scale = min(2.0, 2.0) = 2.0, no offset
        let mut ws = make_ws("letterbox", 800.0, 600.0);
        recompute_viewport(&mut ws, 1600, 1200);
        assert!(
            (ws.viewport_scale_x - 2.0).abs() < 1e-4,
            "scale_x should be 2.0, got {}",
            ws.viewport_scale_x
        );
        assert!(
            (ws.viewport_scale_y - 2.0).abs() < 1e-4,
            "scale_y should be 2.0, got {}",
            ws.viewport_scale_y
        );
        assert!(ws.viewport_offset_x.abs() < 1e-4, "offset_x should be 0.0");
        assert!(ws.viewport_offset_y.abs() < 1e-4, "offset_y should be 0.0");
    }

    #[test]
    fn recompute_viewport_stretch_produces_nonuniform_scale() {
        // 800×600 game, 1600×1200 window → scale_x = 2.0, scale_y = 2.0, no offset
        let mut ws = make_ws("stretch", 800.0, 600.0);
        recompute_viewport(&mut ws, 1600, 1200);
        assert!(
            (ws.viewport_scale_x - 2.0).abs() < 1e-4,
            "scale_x should be 2.0, got {}",
            ws.viewport_scale_x
        );
        assert!(
            (ws.viewport_scale_y - 2.0).abs() < 1e-4,
            "scale_y should be 2.0, got {}",
            ws.viewport_scale_y
        );
        assert!(ws.viewport_offset_x.abs() < 1e-4);
        assert!(ws.viewport_offset_y.abs() < 1e-4);
    }

    #[test]
    fn recompute_viewport_stretch_nonuniform_window() {
        // 800×600 game, 1600×900 window → scale_x = 2.0, scale_y = 1.5 (non-uniform)
        let mut ws = make_ws("stretch", 800.0, 600.0);
        recompute_viewport(&mut ws, 1600, 900);
        assert!(
            (ws.viewport_scale_x - 2.0).abs() < 1e-4,
            "scale_x should be 2.0, got {}",
            ws.viewport_scale_x
        );
        assert!(
            (ws.viewport_scale_y - 1.5).abs() < 1e-4,
            "scale_y should be 1.5, got {}",
            ws.viewport_scale_y
        );
        assert!(ws.viewport_offset_x.abs() < 1e-4);
        assert!(ws.viewport_offset_y.abs() < 1e-4);
    }

    #[test]
    fn recompute_viewport_pixel_uses_integer_scale() {
        // 320×240 game, 1000×800 window → raw scale = min(3.125, 3.333) = 3.125 → floor = 3
        let mut ws = make_ws("pixel", 320.0, 240.0);
        recompute_viewport(&mut ws, 1000, 800);
        assert!(
            (ws.viewport_scale_x - 3.0).abs() < 1e-4,
            "scale_x should be 3.0, got {}",
            ws.viewport_scale_x
        );
        assert!(
            (ws.viewport_scale_y - 3.0).abs() < 1e-4,
            "scale_y should be 3.0, got {}",
            ws.viewport_scale_y
        );
        // offset_x = (1000 - 320*3) * 0.5 = (1000 - 960) * 0.5 = 20
        assert!(
            (ws.viewport_offset_x - 20.0).abs() < 1e-4,
            "offset_x should be 20.0, got {}",
            ws.viewport_offset_x
        );
        // offset_y = (800 - 240*3) * 0.5 = (800 - 720) * 0.5 = 40
        assert!(
            (ws.viewport_offset_y - 40.0).abs() < 1e-4,
            "offset_y should be 40.0, got {}",
            ws.viewport_offset_y
        );
    }

    #[test]
    fn recompute_viewport_pixel_window_barely_larger_than_game_gives_scale_one() {
        // 320×240 game, 321×241 window → raw = min(1.003, 1.004) = 1.003 → floor = 1
        let mut ws = make_ws("pixel", 320.0, 240.0);
        recompute_viewport(&mut ws, 321, 241);
        assert!(
            (ws.viewport_scale_x - 1.0).abs() < 1e-4,
            "scale should floor to 1.0, got {}",
            ws.viewport_scale_x
        );
        assert!(
            (ws.viewport_scale_y - 1.0).abs() < 1e-4,
            "scale should floor to 1.0, got {}",
            ws.viewport_scale_y
        );
    }

    #[test]
    fn recompute_viewport_pixel_window_smaller_than_game_clamps_to_one() {
        // 320×240 game, 100×100 window → raw = ~0.31 → floor = 0 → max(1) = 1
        let mut ws = make_ws("pixel", 320.0, 240.0);
        recompute_viewport(&mut ws, 100, 100);
        assert!(
            (ws.viewport_scale_x - 1.0).abs() < 1e-4,
            "scale should clamp to 1.0 minimum, got {}",
            ws.viewport_scale_x
        );
    }

    #[test]
    fn recompute_viewport_none_mode_passthrough() {
        let mut ws = make_ws("none", 800.0, 600.0);
        recompute_viewport(&mut ws, 1920, 1080);
        assert!(
            (ws.viewport_scale_x - 1.0).abs() < 1e-4,
            "none mode: scale_x should be 1.0"
        );
        assert!(
            (ws.viewport_scale_y - 1.0).abs() < 1e-4,
            "none mode: scale_y should be 1.0"
        );
        assert!(
            ws.viewport_offset_x.abs() < 1e-4,
            "none mode: offset_x should be 0"
        );
        assert!(
            ws.viewport_offset_y.abs() < 1e-4,
            "none mode: offset_y should be 0"
        );
    }

    #[test]
    fn recompute_viewport_unknown_mode_acts_as_none() {
        let mut ws = make_ws("bogus", 800.0, 600.0);
        recompute_viewport(&mut ws, 1600, 900);
        assert!((ws.viewport_scale_x - 1.0).abs() < 1e-4);
        assert!((ws.viewport_scale_y - 1.0).abs() < 1e-4);
        assert!(ws.viewport_offset_x.abs() < 1e-4);
        assert!(ws.viewport_offset_y.abs() < 1e-4);
    }

    // ── fit_contain_size ──────────────────────────────────────────────────────

    #[test]
    fn fit_contain_preserves_aspect_ratio() {
        let (w, h) = fit_contain_size(200, 100, 400.0, 400.0);
        // 200×100 → 2:1 ratio → should fit at 400×200
        assert!((w - 400.0).abs() < 1e-2);
        assert!((h - 200.0).abs() < 1e-2);
    }

    #[test]
    fn fit_contain_tall_image_in_wide_box() {
        let (w, h) = fit_contain_size(100, 400, 200.0, 200.0);
        // 100×400 → 1:4 ratio → height-limited at 200 → width = 50
        assert!((h - 200.0).abs() < 1e-2);
        assert!((w - 50.0).abs() < 1e-2);
    }

    #[test]
    fn fit_contain_zero_source_clamps() {
        let (w, h) = fit_contain_size(0, 0, 100.0, 100.0);
        // src clamped to 1×1, scale = 100 → 100×100
        assert!((w - 100.0).abs() < 1e-2);
        assert!((h - 100.0).abs() < 1e-2);
    }

    // ── splash_window_title ───────────────────────────────────────────────────

    #[test]
    fn splash_title_includes_version() {
        let title = splash_window_title("Lurek2D");
        assert!(title.contains("Lurek2D"));
        assert!(title.contains(env!("CARGO_PKG_VERSION")));
    }

    // ── resolve_present_mode ──────────────────────────────────────────────────

    #[test]
    fn resolve_present_mode_fifo_when_vsync_requested() {
        let modes = vec![wgpu::PresentMode::Fifo, wgpu::PresentMode::Immediate];
        let (mode, vsync) = LunaApp::resolve_present_mode(&modes, 1);
        assert_eq!(mode, wgpu::PresentMode::Fifo);
        assert_eq!(vsync, 1);
    }

    #[test]
    fn resolve_present_mode_immediate_when_no_vsync() {
        let modes = vec![wgpu::PresentMode::Fifo, wgpu::PresentMode::Immediate];
        let (mode, vsync) = LunaApp::resolve_present_mode(&modes, 0);
        assert_eq!(mode, wgpu::PresentMode::Immediate);
        assert_eq!(vsync, 0);
    }

    #[test]
    fn resolve_present_mode_mailbox_when_requested() {
        let modes = vec![
            wgpu::PresentMode::Fifo,
            wgpu::PresentMode::Immediate,
            wgpu::PresentMode::Mailbox,
        ];
        let (mode, vsync) = LunaApp::resolve_present_mode(&modes, -1);
        assert_eq!(mode, wgpu::PresentMode::Mailbox);
        assert_eq!(vsync, -1);
    }

    #[test]
    fn resolve_present_mode_fallback_when_empty() {
        let modes = vec![];
        let (_mode, vsync) = LunaApp::resolve_present_mode(&modes, 1);
        // Should fallback to AutoVsync or AutoNoVsync; vsync should be valid.
        assert!(vsync == 0 || vsync == 1);
    }
}
