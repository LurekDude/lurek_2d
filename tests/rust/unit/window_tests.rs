//! INTERNAL ONLY: public `lurek.window.*` behavior is covered by the Lua-first suite in
//! `tests/lua/unit/test_window_unit.lua`.
//!
//! This Rust file keeps state-helper coverage that is either more precise at
//! the `WindowState` layer or still internal to the runtime plumbing.

use lurek2d::runtime::{FullscreenType, WindowState};
use lurek2d::window::*;

// ── viewport ──────────────────────────────────────────────────────────────────

mod viewport_tests {
    use super::*;

    fn make_ws() -> WindowState {
        let mut ws = WindowState::default();
        ws.game_width = 800.0;
        ws.game_height = 600.0;
        ws.viewport_scale_x = 2.0;
        ws.viewport_scale_y = 2.0;
        ws.viewport_offset_x = 10.0;
        ws.viewport_offset_y = 20.0;
        ws
    }

    #[test]
    fn from_pixels_zero_scale_returns_zero() {
        let mut ws = make_ws();
        ws.viewport_scale_x = 0.0;
        ws.viewport_scale_y = 0.0;
        let (gx, gy) = from_pixels(&ws, 100.0, 100.0);
        assert_eq!(gx, 0.0);
        assert_eq!(gy, 0.0);
    }

    #[test]
    fn set_scale_mode_validated_accepts_valid() {
        let mut ws = WindowState::default();
        assert!(set_scale_mode_validated(&mut ws, "letterbox"));
        assert_eq!(ws.pending_scale_mode.as_deref(), Some("letterbox"));
    }

    #[test]
    fn set_scale_mode_validated_rejects_invalid() {
        let mut ws = WindowState::default();
        assert!(!set_scale_mode_validated(&mut ws, "invalid"));
        assert!(ws.pending_scale_mode.is_none());
    }

    #[test]
    fn set_scale_mode_stores_pending() {
        let mut ws = WindowState::default();
        set_scale_mode(&mut ws, "stretch");
        assert_eq!(ws.pending_scale_mode.as_deref(), Some("stretch"));
    }

    #[test]
    fn from_pixels_negative_scale_returns_zero() {
        let mut ws = WindowState::default();
        ws.viewport_scale_x = 0.0;
        ws.viewport_scale_y = -0.0; // negative zero
        let (gx, gy) = from_pixels(&ws, 50.0, 50.0);
        assert_eq!(gx, 0.0);
        assert_eq!(gy, 0.0);
    }
}

// ── management ────────────────────────────────────────────────────────────────

mod management_tests {
    use super::*;

    fn make_ws() -> WindowState {
        WindowState::default()
    }

    // --- Title ---

    #[test]
    fn set_title_stores_pending() {
        let mut ws = make_ws();
        set_title(&mut ws, "My Game");
        assert_eq!(ws.pending_title.as_deref(), Some("My Game"));
    }

    #[test]
    fn set_title_overwrites_previous_pending() {
        let mut ws = make_ws();
        set_title(&mut ws, "First");
        set_title(&mut ws, "Second");
        assert_eq!(ws.pending_title.as_deref(), Some("Second"));
    }

    // --- Fullscreen ---

    #[test]
    fn set_fullscreen_desktop_mode() {
        let mut ws = make_ws();
        set_fullscreen(&mut ws, true, "desktop");
        assert_eq!(ws.pending_fullscreen, Some(true));
        assert_eq!(ws.pending_fullscreen_type, FullscreenType::Desktop);
    }

    #[test]
    fn set_fullscreen_exclusive_mode() {
        let mut ws = make_ws();
        set_fullscreen(&mut ws, true, "exclusive");
        assert_eq!(ws.pending_fullscreen, Some(true));
        assert_eq!(ws.pending_fullscreen_type, FullscreenType::Exclusive);
    }

    #[test]
    fn set_fullscreen_exit() {
        let mut ws = make_ws();
        set_fullscreen(&mut ws, false, "desktop");
        assert_eq!(ws.pending_fullscreen, Some(false));
    }

    #[test]
    fn is_fullscreen_reads_state() {
        let mut ws = make_ws();
        assert!(!is_fullscreen(&ws));
        ws.fullscreen = true;
        assert!(is_fullscreen(&ws));
    }

    #[test]
    fn get_fullscreen_type_str_desktop() {
        let ws = make_ws();
        assert_eq!(get_fullscreen_type_str(&ws), "desktop");
    }

    #[test]
    fn get_fullscreen_type_str_exclusive() {
        let mut ws = make_ws();
        ws.fullscreen_type = FullscreenType::Exclusive;
        assert_eq!(get_fullscreen_type_str(&ws), "exclusive");
    }

    #[test]
    fn get_fullscreen_returns_pair() {
        let mut ws = make_ws();
        ws.fullscreen = true;
        ws.fullscreen_type = FullscreenType::Exclusive;
        let (fs, ft) = get_fullscreen(&ws);
        assert!(fs);
        assert_eq!(ft, "exclusive");
    }

    // --- VSync ---

    #[test]
    fn set_vsync_stores_pending() {
        let mut ws = make_ws();
        set_vsync(&mut ws, 0);
        assert_eq!(ws.pending_vsync, Some(0));
    }

    #[test]
    fn get_vsync_reads_current() {
        let mut ws = make_ws();
        ws.vsync_mode = -1;
        assert_eq!(get_vsync(&ws), -1);
    }

    // --- DPI ---

    #[test]
    fn get_dpi_scale_default() {
        let ws = make_ws();
        assert_eq!(get_dpi_scale(&ws), 1.0);
    }

    #[test]
    fn get_dpi_scale_hidpi() {
        let mut ws = make_ws();
        ws.dpi_scale = 2.0;
        assert_eq!(get_dpi_scale(&ws), 2.0);
    }

    #[test]
    fn to_dpi_pixels_scales() {
        let mut ws = make_ws();
        ws.dpi_scale = 2.0;
        assert_eq!(to_dpi_pixels(&ws, 100.0), 200.0);
    }

    #[test]
    fn from_dpi_pixels_unscales() {
        let mut ws = make_ws();
        ws.dpi_scale = 2.0;
        assert_eq!(from_dpi_pixels(&ws, 200.0), 100.0);
    }

    #[test]
    fn from_dpi_pixels_zero_scale_returns_input() {
        let mut ws = make_ws();
        ws.dpi_scale = 0.0;
        assert_eq!(from_dpi_pixels(&ws, 100.0), 100.0);
    }

    // --- Position ---

    #[test]
    fn get_position_default() {
        let ws = make_ws();
        assert_eq!(get_position(&ws), (0, 0));
    }

    #[test]
    fn set_position_stores_pending() {
        let mut ws = make_ws();
        set_position(&mut ws, 200, 100);
        assert_eq!(ws.pending_position, Some((200, 100)));
    }

    #[test]
    fn set_display_stores_pending_index() {
        let mut ws = make_ws();
        assert!(set_display(&mut ws, 2));
        assert_eq!(ws.pending_display_index, Some(2));
    }

    #[test]
    fn set_display_rejects_negative_index() {
        let mut ws = make_ws();
        assert!(!set_display(&mut ws, -1));
        assert_eq!(ws.pending_display_index, None);
    }

    // --- Size ---

    #[test]
    fn set_size_stores_pending() {
        let mut ws = make_ws();
        set_size(&mut ws, 1920, 1080);
        assert_eq!(ws.pending_size, Some((1920, 1080)));
    }

    #[test]
    fn get_pixel_dimensions_applies_dpi() {
        let mut ws = make_ws();
        ws.dpi_scale = 2.0;
        let (pw, ph) = get_pixel_dimensions(&ws, 800, 600);
        assert_eq!(pw, 1600);
        assert_eq!(ph, 1200);
    }

    // --- Minimize / Maximize / Restore ---

    #[test]
    fn minimize_sets_pending() {
        let mut ws = make_ws();
        minimize(&mut ws);
        assert!(ws.pending_minimize);
    }

    #[test]
    fn maximize_sets_pending() {
        let mut ws = make_ws();
        maximize(&mut ws);
        assert!(ws.pending_maximize);
    }

    #[test]
    fn restore_sets_pending() {
        let mut ws = make_ws();
        restore(&mut ws);
        assert!(ws.pending_restore);
    }

    #[test]
    fn is_minimized_reads_state() {
        let mut ws = make_ws();
        assert!(!is_minimized(&ws));
        ws.minimized = true;
        assert!(is_minimized(&ws));
    }

    #[test]
    fn is_maximized_reads_state() {
        let mut ws = make_ws();
        assert!(!is_maximized(&ws));
        ws.maximized = true;
        assert!(is_maximized(&ws));
    }

    // --- Focus / Visibility ---

    #[test]
    fn has_focus_default_true() {
        let ws = make_ws();
        assert!(has_focus(&ws));
    }

    #[test]
    fn has_mouse_focus_default_true() {
        let ws = make_ws();
        assert!(has_mouse_focus(&ws));
    }

    #[test]
    fn is_visible_default_true() {
        let ws = make_ws();
        assert!(is_visible(&ws));
    }

    // --- Attention / Close / Icon ---

    #[test]
    fn request_attention_sets_pending() {
        let mut ws = make_ws();
        request_attention(&mut ws);
        assert!(ws.pending_attention);
    }

    #[test]
    fn flash_sets_pending_attention() {
        let mut ws = make_ws();
        flash(&mut ws);
        assert!(ws.pending_attention);
    }

    #[test]
    fn close_sets_pending() {
        let mut ws = make_ws();
        close(&mut ws);
        assert!(ws.pending_close);
    }

    #[test]
    fn set_icon_stores_path() {
        let mut ws = make_ws();
        set_icon(&mut ws, "icon.png");
        assert_eq!(ws.pending_icon_path.as_deref(), Some("icon.png"));
    }

    // --- Combined mode ---

    #[test]
    fn set_mode_sets_size_only() {
        let mut ws = make_ws();
        set_mode(&mut ws, 1280, 720, None, None, None);
        assert_eq!(ws.pending_size, Some((1280, 720)));
        assert!(ws.pending_fullscreen.is_none());
        assert!(ws.pending_vsync.is_none());
    }

    #[test]
    fn set_mode_sets_all() {
        let mut ws = make_ws();
        set_mode(&mut ws, 1920, 1080, Some(true), Some("exclusive"), Some(0));
        assert_eq!(ws.pending_size, Some((1920, 1080)));
        assert_eq!(ws.pending_fullscreen, Some(true));
        assert_eq!(ws.pending_fullscreen_type, FullscreenType::Exclusive);
        assert_eq!(ws.pending_vsync, Some(0));
    }

    #[test]
    fn get_mode_returns_current() {
        let mut ws = make_ws();
        ws.fullscreen = true;
        ws.fullscreen_type = FullscreenType::Exclusive;
        ws.vsync_mode = -1;
        let mode = get_mode(&ws);
        assert!(mode.fullscreen);
        assert_eq!(mode.fullscreen_type, "exclusive");
        assert_eq!(mode.vsync, -1);
    }
}
