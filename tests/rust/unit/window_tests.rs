//! Integration tests for the Lurek2D window state and missing surface API.

use lurek2d::engine::config::Config;
use lurek2d::lua_api::{create_lua_vm, SharedState};
use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

fn make_vm() -> (Rc<RefCell<SharedState>>, mlua::Lua) {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "test",
        PathBuf::from("."),
    )));
    let lua = create_lua_vm(state.clone(), &Config::default().modules).unwrap();
    (state, lua)
}

// ── Phase 17 — Window: Missing Surface ───────────────────────────

#[test]
fn window_native_dpi_scale_positive() {
    let (state, lua) = make_vm();
    // Default dpi_scale is 1.0
    state.borrow_mut().window_state.dpi_scale = 2.0;
    lua.load(
        r#"
        local s = luna.window.getNativeDPIScale()
        assert(type(s) == "number")
        assert(s > 0)
        assert(math.abs(s - 2.0) < 0.01)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn window_native_dpi_scale_default_is_one() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local s = luna.window.getNativeDPIScale()
        assert(math.abs(s - 1.0) < 0.01)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn window_display_orientation_is_landscape_for_wide_window() {
    let (_state, lua) = make_vm();
    // 800×600 window is landscape
    lua.load(
        r#"
        local o = luna.window.getDisplayOrientation()
        assert(type(o) == "string")
        assert(o == "landscape")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn window_display_orientation_is_portrait_for_tall_window() {
    let (state, lua) = make_vm();
    state.borrow_mut().window_width = 400;
    state.borrow_mut().window_height = 700;
    lua.load(
        r#"
        local o = luna.window.getDisplayOrientation()
        assert(o == "portrait")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn window_system_theme_returns_string() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local t = luna.window.getSystemTheme()
        assert(type(t) == "string")
        assert(t == "unknown" or t == "light" or t == "dark")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn window_safe_area_full_on_desktop() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local x, y, w, h = luna.window.getSafeArea()
        assert(math.abs(x) < 0.01)
        assert(math.abs(y) < 0.01)
        assert(w > 0)
        assert(h > 0)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn window_safe_area_matches_window_dimensions() {
    let (state, lua) = make_vm();
    state.borrow_mut().window_width = 1920;
    state.borrow_mut().window_height = 1080;
    lua.load(
        r#"
        local x, y, w, h = luna.window.getSafeArea()
        assert(math.abs(w - 1920) < 0.01)
        assert(math.abs(h - 1080) < 0.01)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn window_is_high_dpi_allowed_returns_bool() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local ok = luna.window.isHighDPIAllowed()
        assert(type(ok) == "boolean")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn window_focus_can_be_called_without_error() {
    let (_state, lua) = make_vm();
    lua.load("lurek.window.focus()").exec().unwrap();
}

// ── Window Scaling — Config defaults ─────────────────────────────────────────

#[test]
fn window_config_scale_mode_defaults_to_none() {
    let config = lurek2d::engine::Config::default();
    assert_eq!(config.window.scale_mode, "none");
}

#[test]
fn window_config_game_dimensions_default_none() {
    let config = lurek2d::engine::Config::default();
    assert!(config.window.game_width.is_none());
    assert!(config.window.game_height.is_none());
}

#[test]
fn window_config_maximized_defaults_false() {
    let config = lurek2d::engine::Config::default();
    assert!(!config.window.maximized);
}

// ── Window Scaling — WindowState defaults ─────────────────────────────────────

#[test]
fn window_state_viewport_scale_defaults_are_one() {
    let ws = lurek2d::engine::WindowState::default();
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
    let ws = lurek2d::engine::WindowState::default();
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
    let ws = lurek2d::engine::WindowState::default();
    assert_eq!(ws.scale_mode_str, "none");
}

#[test]
fn window_state_game_dimensions_default_to_800x600() {
    let ws = lurek2d::engine::WindowState::default();
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
    let ws = lurek2d::engine::WindowState::default();
    assert!(ws.pending_scale_mode.is_none());
}
