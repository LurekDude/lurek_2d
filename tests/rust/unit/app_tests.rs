//! INTERNAL ONLY: Rust-only tests for app-side helpers that are not exercised through the
//! Lua-facing engine API.
//!
//! Public engine/application behaviour is covered in the Lua-first suite. The
//! remaining Rust coverage here focuses on low-level error-screen formatting
//! and debug-overlay command generation.

use lurek2d::app::error_screen::{wrap_text, format_traceback, ErrorScreen};
use lurek2d::app::debug_overlay::DebugOverlay;
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
