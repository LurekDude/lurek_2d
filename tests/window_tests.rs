//! Integration tests for luna2d engine window configuration and state.

use luna2d::engine::{Config, WindowState};

// ── WindowConfig defaults ─────────────────────────────────────────────────────

#[test]
fn window_config_scale_mode_defaults_to_none() {
    let config = Config::default();
    assert_eq!(config.window.scale_mode, "none");
}

#[test]
fn window_config_game_dimensions_default_none() {
    let config = Config::default();
    assert!(config.window.game_width.is_none());
    assert!(config.window.game_height.is_none());
}

#[test]
fn window_config_maximized_defaults_false() {
    let config = Config::default();
    assert!(!config.window.maximized);
}

// ── WindowState viewport defaults ─────────────────────────────────────────────

#[test]
fn window_state_viewport_scale_defaults_are_one() {
    let ws = WindowState::default();
    assert!(
        (ws.viewport_scale_x - 1.0).abs() < 1e-5,
        "viewport_scale_x should default to 1.0, got {}",
        ws.viewport_scale_x
    );
    assert!(
        (ws.viewport_scale_y - 1.0).abs() < 1e-5,
        "viewport_scale_y should default to 1.0, got {}",
        ws.viewport_scale_y
    );
}

#[test]
fn window_state_viewport_offsets_default_to_zero() {
    let ws = WindowState::default();
    assert!(
        ws.viewport_offset_x.abs() < 1e-5,
        "viewport_offset_x should default to 0.0, got {}",
        ws.viewport_offset_x
    );
    assert!(
        ws.viewport_offset_y.abs() < 1e-5,
        "viewport_offset_y should default to 0.0, got {}",
        ws.viewport_offset_y
    );
}

#[test]
fn window_state_scale_mode_str_defaults_to_none() {
    let ws = WindowState::default();
    assert_eq!(ws.scale_mode_str, "none");
}

#[test]
fn window_state_game_dimensions_default_to_800x600() {
    let ws = WindowState::default();
    assert!(
        (ws.game_width - 800.0).abs() < 1e-5,
        "default game_width should be 800.0"
    );
    assert!(
        (ws.game_height - 600.0).abs() < 1e-5,
        "default game_height should be 600.0"
    );
}

#[test]
fn window_state_pending_scale_mode_defaults_none() {
    let ws = WindowState::default();
    assert!(ws.pending_scale_mode.is_none());
}
