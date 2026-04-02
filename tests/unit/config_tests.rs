//! Integration tests for the Luna2D configuration loading.

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
