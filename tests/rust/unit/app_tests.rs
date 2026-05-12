//! INTERNAL ONLY: Rust-only tests for app-side helpers that are not exercised through the
//! Lua-facing engine API.
//!
//! Public engine/application behaviour is covered in the Lua-first suite. The
//! remaining Rust coverage here focuses on low-level error-screen formatting
//! and debug-overlay command generation.

use lurek2d::app::debug_overlay::DebugOverlay;
use lurek2d::app::app::{fit_contain_size, recompute_viewport, LurekApp};
use lurek2d::app::error_screen::{format_traceback, wrap_text, ErrorScreen};
use lurek2d::runtime::shared_state::WindowState;
use lurek2d::runtime::error::EngineError;
use lurek2d::runtime::resource_keys::FontKey;
use lurek2d::render::renderer::RenderCommand;
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

    #[test]
    fn test_error_screen_formats_lua_traceback() {
        let err = mlua::Error::RuntimeError(
            "main.lua:12: bad argument\nstack traceback:\n\t[string \"main.lua\"]:12: in function 'update'".to_string(),
        );
        let screen = ErrorScreen::from_lua_error(&err);
        let text = screen.as_text();
        assert!(text.contains("Lua Error"));
        assert!(text.contains("main.lua:12"));
        assert!(!text.contains("[string"));
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

        assert!(matches!(cmds[0], RenderCommand::SetColor(_, _, _, _)));
        assert!(matches!(cmds[1], RenderCommand::Rectangle { .. }));
        assert!(matches!(cmds[2], RenderCommand::SetColor(_, _, _, _)));
        assert!(matches!(cmds[3], RenderCommand::Print { .. }));
        assert!(matches!(cmds[4], RenderCommand::Print { .. }));
    }

    #[test]
    fn test_enabled_no_font_returns_empty() {
        let mut overlay = DebugOverlay::new();
        overlay.enabled = true;
        let cmds = overlay.build_render_commands(800, 60.0, 10, None);
        assert!(cmds.is_empty());
    }
}

mod viewport_tests {
    use super::*;

    fn make_window_state(scale_mode: &str, game_w: f32, game_h: f32) -> WindowState {
        let mut ws = WindowState::default();
        ws.scale_mode_str = scale_mode.to_string();
        ws.game_width = game_w;
        ws.game_height = game_h;
        ws
    }

    #[test]
    fn test_recompute_viewport_letterbox() {
        let mut ws = make_window_state("letterbox", 800.0, 600.0);
        recompute_viewport(&mut ws, 1920, 1080);
        assert!((ws.viewport_scale_x - 1.8).abs() < 0.0001);
        assert!((ws.viewport_scale_y - 1.8).abs() < 0.0001);
        assert!((ws.viewport_offset_x - 240.0).abs() < 0.001);
        assert!((ws.viewport_offset_y - 0.0).abs() < 0.001);
    }

    #[test]
    fn test_recompute_viewport_stretch() {
        let mut ws = make_window_state("stretch", 800.0, 600.0);
        recompute_viewport(&mut ws, 1600, 900);
        assert!((ws.viewport_scale_x - 2.0).abs() < 0.0001);
        assert!((ws.viewport_scale_y - 1.5).abs() < 0.0001);
        assert_eq!(ws.viewport_offset_x, 0.0);
        assert_eq!(ws.viewport_offset_y, 0.0);
    }

    #[test]
    fn test_recompute_viewport_pixel_integer_scale() {
        let mut ws = make_window_state("pixel", 320.0, 240.0);
        recompute_viewport(&mut ws, 1000, 740);
        assert_eq!(ws.viewport_scale_x, 3.0);
        assert_eq!(ws.viewport_scale_y, 3.0);
        assert!((ws.viewport_offset_x - 20.0).abs() < 0.001);
        assert!((ws.viewport_offset_y - 10.0).abs() < 0.001);
    }

    #[test]
    fn test_recompute_viewport_none_and_zero_game_size() {
        let mut ws = make_window_state("none", 0.0, 0.0);
        recompute_viewport(&mut ws, 640, 360);
        assert_eq!(ws.viewport_scale_x, 1.0);
        assert_eq!(ws.viewport_scale_y, 1.0);
        assert_eq!(ws.viewport_offset_x, 0.0);
        assert_eq!(ws.viewport_offset_y, 0.0);
    }

    #[test]
    fn test_fit_contain_size_edge_cases() {
        let (w, h) = fit_contain_size(1920, 1080, 800.0, 600.0);
        assert!((w - 800.0).abs() < 0.001);
        assert!((h - 450.0).abs() < 0.001);

        let (w, h) = fit_contain_size(0, 0, 0.0, 0.0);
        assert_eq!(w, 1.0);
        assert_eq!(h, 1.0);
    }
}

mod present_mode_tests {
    use super::*;

    #[test]
    fn test_resolve_present_mode_requested_immediate_when_available() {
        let available = vec![wgpu::PresentMode::Fifo, wgpu::PresentMode::Immediate];
        let (mode, vsync) = LurekApp::resolve_present_mode(&available, 0);
        assert_eq!(mode, wgpu::PresentMode::Immediate);
        assert_eq!(vsync, 0);
    }

    #[test]
    fn test_resolve_present_mode_requested_mailbox_when_available() {
        let available = vec![wgpu::PresentMode::Fifo, wgpu::PresentMode::Mailbox];
        let (mode, vsync) = LurekApp::resolve_present_mode(&available, -1);
        assert_eq!(mode, wgpu::PresentMode::Mailbox);
        assert_eq!(vsync, -1);
    }

    #[test]
    fn test_resolve_present_mode_fallback_to_fifo() {
        let available = vec![wgpu::PresentMode::Fifo];
        let (mode, vsync) = LurekApp::resolve_present_mode(&available, 0);
        assert_eq!(mode, wgpu::PresentMode::Fifo);
        assert_eq!(vsync, 1);
    }

    #[test]
    fn test_resolve_present_mode_fallback_auto_no_vsync_when_empty() {
        let available = vec![];
        let (mode, vsync) = LurekApp::resolve_present_mode(&available, 0);
        assert_eq!(mode, wgpu::PresentMode::AutoNoVsync);
        assert_eq!(vsync, 0);
    }
}
