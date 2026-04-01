use std::fs;

use luna2d::engine::Config;
use tempfile::TempDir;

fn write_conf(temp_dir: &TempDir, contents: &str) {
    fs::write(temp_dir.path().join("conf.lua"), contents).expect("Failed to write conf.lua");
}

#[test]
fn config_load_from_conf_lua_parses_phase01_fields() {
    let temp_dir = TempDir::new().expect("Failed to create temp dir");
    write_conf(
        &temp_dir,
        r#"
        function luna.conf(t)
            t.window.title = "Phase 01"
            t.window.width = 1280
            t.window.height = 720
            t.window.resizable = true
            t.window.minwidth = 400
            t.window.minheight = 300
            t.window.borderless = true
            t.window.icon = "assets/icon.png"
            t.window.displayindex = 2

            t.modules.audio = false
            t.modules.physics = false
            t.modules.graphics = true
            t.modules.input = false
            t.modules.timer = true
            t.modules.filesystem = false

            t.performance.target_fps = 144
            t.identity = "phase01-save"
            t.version = "0.5.0"
        end
        "#,
    );

    let (config, error) = Config::load_from_conf_lua(temp_dir.path());

    assert!(error.is_none(), "unexpected conf.lua error: {error:?}");
    assert_eq!(config.window.title, "Phase 01");
    assert_eq!(config.window.width, 1280);
    assert_eq!(config.window.height, 720);
    assert!(config.window.resizable);
    assert_eq!(config.window.min_width, Some(400));
    assert_eq!(config.window.min_height, Some(300));
    assert!(config.window.borderless);
    assert_eq!(config.window.icon.as_deref(), Some("assets/icon.png"));
    assert_eq!(config.window.display_index, 2);
    assert!(!config.modules.audio);
    assert!(!config.modules.physics);
    assert!(config.modules.graphics);
    assert!(!config.modules.input);
    assert!(config.modules.timer);
    assert!(!config.modules.filesystem);
    assert_eq!(config.performance.target_fps, 144);
    assert_eq!(config.identity.as_deref(), Some("phase01-save"));
    assert_eq!(config.version.as_deref(), Some("0.5.0"));
}

#[test]
fn config_load_from_conf_lua_maps_empty_phase01_optionals_to_none() {
    let temp_dir = TempDir::new().expect("Failed to create temp dir");
    write_conf(
        &temp_dir,
        r#"
        function luna.conf(t)
            t.window.minwidth = 0
            t.window.minheight = 0
            t.window.icon = ""
            t.identity = ""
            t.version = ""
        end
        "#,
    );

    let (config, error) = Config::load_from_conf_lua(temp_dir.path());

    assert!(error.is_none(), "unexpected conf.lua error: {error:?}");
    assert_eq!(config.window.min_width, None);
    assert_eq!(config.window.min_height, None);
    assert_eq!(config.window.icon, None);
    assert_eq!(config.identity, None);
    assert_eq!(config.version, None);
}

// ── Default config (no conf.lua present) ────────────────────────────────────

#[test]
fn config_defaults_when_no_conf_lua() {
    let temp_dir = TempDir::new().expect("Failed to create temp dir");
    // Do NOT write conf.lua — directory is empty

    let (config, error) = Config::load_from_conf_lua(temp_dir.path());

    assert!(error.is_none(), "no error expected when conf.lua is absent");
    // Default window
    assert_eq!(config.window.width, 800);
    assert_eq!(config.window.height, 600);
    assert!(config.window.vsync);
    assert!(!config.window.fullscreen);
    assert!(!config.window.resizable);
    assert!(!config.window.borderless);
    assert_eq!(config.window.min_width, None);
    assert_eq!(config.window.min_height, None);
    assert_eq!(config.window.icon, None);
    assert_eq!(config.window.display_index, 0);
    // Default modules — all enabled
    assert!(config.modules.audio);
    assert!(config.modules.physics);
    assert!(config.modules.graphics);
    assert!(config.modules.input);
    assert!(config.modules.timer);
    assert!(config.modules.filesystem);
    // Default performance
    assert_eq!(config.performance.target_fps, 60);
    // Default optional strings
    assert!(config.identity.is_none());
    assert!(config.version.is_none());
    assert!(config.log_file.is_none());
    assert!(!config.log_append);
}

// ── Vsync and fullscreen ────────────────────────────────────────────────────

#[test]
fn config_vsync_false_fullscreen_true() {
    let temp_dir = TempDir::new().expect("Failed to create temp dir");
    write_conf(
        &temp_dir,
        r#"
        function luna.conf(t)
            t.window.vsync = false
            t.window.fullscreen = true
        end
        "#,
    );

    let (config, error) = Config::load_from_conf_lua(temp_dir.path());

    assert!(error.is_none());
    assert!(!config.window.vsync);
    assert!(config.window.fullscreen);
}

// ── Log settings ────────────────────────────────────────────────────────────

#[test]
fn config_log_file_and_append() {
    let temp_dir = TempDir::new().expect("Failed to create temp dir");
    write_conf(
        &temp_dir,
        r#"
        function luna.conf(t)
            t.log.file = "game.log"
            t.log.append = true
        end
        "#,
    );

    let (config, error) = Config::load_from_conf_lua(temp_dir.path());

    assert!(error.is_none());
    assert_eq!(config.log_file.as_deref(), Some("game.log"));
    assert!(config.log_append);
}

#[test]
fn config_log_file_empty_maps_to_none() {
    let temp_dir = TempDir::new().expect("Failed to create temp dir");
    write_conf(
        &temp_dir,
        r#"
        function luna.conf(t)
            t.log.file = ""
            t.log.append = false
        end
        "#,
    );

    let (config, error) = Config::load_from_conf_lua(temp_dir.path());

    assert!(error.is_none());
    assert!(config.log_file.is_none());
    assert!(!config.log_append);
}

// ── Performance settings ─────────────────────────────────────────────────────

#[test]
fn config_target_fps_30() {
    let temp_dir = TempDir::new().expect("Failed to create temp dir");
    write_conf(
        &temp_dir,
        r#"
        function luna.conf(t)
            t.performance.target_fps = 30
        end
        "#,
    );

    let (config, error) = Config::load_from_conf_lua(temp_dir.path());

    assert!(error.is_none());
    assert_eq!(config.performance.target_fps, 30);
}

// ── Malformed conf.lua ───────────────────────────────────────────────────────

#[test]
fn config_syntax_error_in_conf_lua_returns_error_and_defaults() {
    let temp_dir = TempDir::new().expect("Failed to create temp dir");
    write_conf(
        &temp_dir,
        r#"
        this is not valid lua!!!
        "#,
    );

    let (config, error) = Config::load_from_conf_lua(temp_dir.path());

    // Should report a parse/exec error
    assert!(error.is_some(), "expected error for invalid Lua syntax");
    // Should still return usable defaults
    assert_eq!(config.window.width, 800);
    assert_eq!(config.window.height, 600);
}

#[test]
fn config_runtime_error_in_luna_conf_returns_error_and_defaults() {
    let temp_dir = TempDir::new().expect("Failed to create temp dir");
    write_conf(
        &temp_dir,
        r#"
        function luna.conf(t)
            error("intentional runtime error")
        end
        "#,
    );

    let (config, error) = Config::load_from_conf_lua(temp_dir.path());

    assert!(
        error.is_some(),
        "expected error when luna.conf() throws at runtime"
    );
    // Defaults should still be returned
    assert_eq!(config.window.width, 800);
}

// ── conf.lua that defines luna.conf but changes nothing ──────────────────────

#[test]
fn config_noop_conf_lua_returns_defaults() {
    let temp_dir = TempDir::new().expect("Failed to create temp dir");
    write_conf(
        &temp_dir,
        r#"
        function luna.conf(t)
            -- intentionally empty
        end
        "#,
    );

    let (config, error) = Config::load_from_conf_lua(temp_dir.path());

    assert!(error.is_none());
    assert_eq!(config.window.width, 800);
    assert_eq!(config.window.height, 600);
    assert_eq!(config.performance.target_fps, 60);
}

// ── conf.lua with no luna.conf function defined (just code, no function) ─────

#[test]
fn config_no_luna_conf_function_uses_defaults() {
    let temp_dir = TempDir::new().expect("Failed to create temp dir");
    write_conf(
        &temp_dir,
        r#"
        -- This file exists but does not define luna.conf
        local x = 1 + 1
        "#,
    );

    let (config, error) = Config::load_from_conf_lua(temp_dir.path());

    assert!(error.is_none(), "no error expected: {error:?}");
    assert_eq!(config.window.width, 800);
}

// ── All modules disabled ──────────────────────────────────────────────────────

#[test]
fn config_all_modules_disabled() {
    let temp_dir = TempDir::new().expect("Failed to create temp dir");
    write_conf(
        &temp_dir,
        r#"
        function luna.conf(t)
            t.modules.audio    = false
            t.modules.physics  = false
            t.modules.graphics = false
            t.modules.input    = false
            t.modules.timer    = false
            t.modules.filesystem = false
        end
        "#,
    );

    let (config, error) = Config::load_from_conf_lua(temp_dir.path());

    assert!(error.is_none());
    assert!(!config.modules.audio);
    assert!(!config.modules.physics);
    assert!(!config.modules.graphics);
    assert!(!config.modules.input);
    assert!(!config.modules.timer);
    assert!(!config.modules.filesystem);
}

// ── Large display index ───────────────────────────────────────────────────────

#[test]
fn config_large_display_index() {
    let temp_dir = TempDir::new().expect("Failed to create temp dir");
    write_conf(
        &temp_dir,
        r#"
        function luna.conf(t)
            t.window.displayindex = 3
        end
        "#,
    );

    let (config, error) = Config::load_from_conf_lua(temp_dir.path());

    assert!(error.is_none());
    assert_eq!(config.window.display_index, 3);
}

// ── min_width / min_height set to exactly 1 (boundary: not zero) ─────────────

#[test]
fn config_min_dimensions_boundary_value_one() {
    let temp_dir = TempDir::new().expect("Failed to create temp dir");
    write_conf(
        &temp_dir,
        r#"
        function luna.conf(t)
            t.window.minwidth  = 1
            t.window.minheight = 1
        end
        "#,
    );

    let (config, error) = Config::load_from_conf_lua(temp_dir.path());

    assert!(error.is_none());
    assert_eq!(config.window.min_width, Some(1));
    assert_eq!(config.window.min_height, Some(1));
}
