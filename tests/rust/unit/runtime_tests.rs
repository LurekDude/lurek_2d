//! INTERNAL ONLY: public `lurek.runtime.*` behavior is covered by the Lua-first suites in
//! `tests/lua/unit/test_runtime_unit.lua`, `tests/lua/security/test_runtime.lua`,
//! and `tests/lua/integration/test_runtime_system.lua`.
//!
//! The Rust-only coverage that remains here targets internal enums, config
//! defaults, and error/log-message helpers that are not exposed as direct Lua
//! values.

use lurek2d::runtime::config::Config;
use lurek2d::runtime::error::{EngineError, ErrorCategory};
use lurek2d::runtime::log_messages::*;
use lurek2d::runtime::SharedState;
use std::path::PathBuf;

// ── log_messages ─────────────────────────────────────────────────────────────

mod log_messages_tests {
    use super::*;

    #[test]
    fn lifecycle_ids_are_non_empty() {
        assert!(!L001_ENGINE_START.is_empty());
        assert!(!L002_ENGINE_STOP.is_empty());
        assert!(!L003_GAME_LOADED.is_empty());
    }

    #[test]
    fn lifecycle_ids_match_format() {
        for id in &[
            L001_ENGINE_START,
            L002_ENGINE_STOP,
            L003_GAME_LOADED,
            L010_RENDER_ERROR,
            L011_LUA_ERROR,
        ] {
            assert!(
                id.starts_with('L'),
                "lifecycle ID '{}' must start with 'L'",
                id
            );
            assert!(
                id[1..].chars().all(|c| c.is_ascii_digit()),
                "lifecycle ID '{}' suffix must be digits",
                id
            );
        }
    }

    #[test]
    fn subsystem_ids_follow_prefix_convention() {
        assert!(A001_MIDI_READ_FAIL.starts_with('A'));
        assert!(G001_FONT_GLYPH_WARN.starts_with('G'));
        assert!(P001_PULLEY_JOINT_FALLBACK.starts_with('P'));
    }

    #[test]
    fn get_log_level_returns_valid_string() {
        let level = get_log_level();
        assert!(
            ["off", "error", "warn", "info", "debug", "trace"].contains(&level),
            "unexpected log level: {}",
            level
        );
    }
}

// ── error ────────────────────────────────────────────────────────────────────

mod error_tests {
    use super::*;

    // ── ErrorCategory ────────────────────────────────────────────────────

    #[test]
    fn category_as_str_matches() {
        assert_eq!(ErrorCategory::Init.as_str(), "init");
        assert_eq!(ErrorCategory::Runtime.as_str(), "runtime");
        assert_eq!(ErrorCategory::Resource.as_str(), "resource");
        assert_eq!(ErrorCategory::Script.as_str(), "script");
        assert_eq!(ErrorCategory::System.as_str(), "system");
    }

    // ── EngineError codes ────────────────────────────────────────────────

    #[test]
    fn all_variants_have_unique_codes() {
        let errors: Vec<EngineError> = vec![
            EngineError::InitializationError("".into()),
            EngineError::RenderError("".into()),
            EngineError::InputError("".into()),
            EngineError::AudioError("".into()),
            EngineError::PhysicsError("".into()),
            EngineError::FileSystemError("".into()),
            EngineError::LuaError("".into()),
            EngineError::WindowError("".into()),
            EngineError::ConfigError("".into()),
            EngineError::ResourceNotFound("".into()),
            EngineError::ResourceNotLoaded("".into()),
            EngineError::IoError(std::io::Error::new(std::io::ErrorKind::Other, "")),
        ];
        let mut codes: Vec<&str> = errors.iter().map(|e| e.code()).collect();
        let total = codes.len();
        codes.sort();
        codes.dedup();
        assert_eq!(codes.len(), total, "duplicate error codes detected");
    }

    #[test]
    fn error_code_format() {
        let err = EngineError::InitializationError("test".into());
        assert!(err.code().starts_with('E'), "code must start with E");
        assert_eq!(err.code().len(), 5, "code must be 5 chars (Exxxx)");
    }

    // ── Category mapping ─────────────────────────────────────────────────

    #[test]
    fn init_errors_map_to_init_category() {
        assert_eq!(
            EngineError::InitializationError("".into()).category(),
            ErrorCategory::Init
        );
        assert_eq!(
            EngineError::WindowError("".into()).category(),
            ErrorCategory::Init
        );
        assert_eq!(
            EngineError::ConfigError("".into()).category(),
            ErrorCategory::Init
        );
    }

    #[test]
    fn runtime_errors_map_to_runtime_category() {
        assert_eq!(
            EngineError::RenderError("".into()).category(),
            ErrorCategory::Runtime
        );
        assert_eq!(
            EngineError::AudioError("".into()).category(),
            ErrorCategory::Runtime
        );
    }

    #[test]
    fn resource_errors_map_to_resource_category() {
        assert_eq!(
            EngineError::ResourceNotFound("".into()).category(),
            ErrorCategory::Resource
        );
        assert_eq!(
            EngineError::ResourceNotLoaded("".into()).category(),
            ErrorCategory::Resource
        );
    }

    #[test]
    fn lua_error_maps_to_script_category() {
        assert_eq!(
            EngineError::LuaError("".into()).category(),
            ErrorCategory::Script
        );
    }

    #[test]
    fn io_errors_map_to_system_category() {
        assert_eq!(
            EngineError::FileSystemError("".into()).category(),
            ErrorCategory::Filesystem
        );
        let io = EngineError::IoError(std::io::Error::new(std::io::ErrorKind::NotFound, ""));
        assert_eq!(io.category(), ErrorCategory::System);
    }

    // ── Recovery hints ───────────────────────────────────────────────────

    #[test]
    fn every_variant_has_non_empty_hint() {
        let errors: Vec<EngineError> = vec![
            EngineError::InitializationError("".into()),
            EngineError::RenderError("".into()),
            EngineError::InputError("".into()),
            EngineError::AudioError("".into()),
            EngineError::PhysicsError("".into()),
            EngineError::FileSystemError("".into()),
            EngineError::LuaError("".into()),
            EngineError::WindowError("".into()),
            EngineError::ConfigError("".into()),
            EngineError::ResourceNotFound("".into()),
            EngineError::ResourceNotLoaded("".into()),
            EngineError::IoError(std::io::Error::new(std::io::ErrorKind::Other, "")),
        ];
        for err in &errors {
            assert!(!err.recovery_hint().is_empty(), "empty hint for {:?}", err);
        }
    }

    // ── Display / From ───────────────────────────────────────────────────

    #[test]
    fn display_includes_message() {
        let err = EngineError::LuaError("bad variable".into());
        let s = err.to_string();
        assert!(s.contains("bad variable"), "display: {}", s);
    }

    #[test]
    fn io_error_converts_via_from() {
        let io = std::io::Error::new(std::io::ErrorKind::PermissionDenied, "no access");
        let engine: EngineError = io.into();
        assert_eq!(engine.code(), "E1012");
    }
}

// ── config ───────────────────────────────────────────────────────────────────

mod config_tests {
    use super::*;

    // ── Default values ─────────────────────────────────────────────────────────

    #[test]
    fn default_window_width_800() {
        let c = Config::default();
        assert_eq!(c.window.width, 800);
    }

    #[test]
    fn default_window_height_600() {
        let c = Config::default();
        assert_eq!(c.window.height, 600);
    }

    #[test]
    fn default_title_contains_luna2d() {
        let c = Config::default();
        assert!(c.window.title.contains("Lurek2D"));
    }

    #[test]
    fn default_vsync_enabled() {
        let c = Config::default();
        assert!(c.window.vsync);
    }

    #[test]
    fn default_fps_cap_sixty() {
        let c = Config::default();
        assert_eq!(c.performance.target_fps, 60);
    }

    #[test]
    fn default_modules_graphics_enabled() {
        let c = Config::default();
        assert!(c.modules.render);
    }

    #[test]
    fn default_identity_none() {
        let c = Config::default();
        assert!(c.identity.is_none());
    }

    // ── Module validation ─────────────────────────────────────────────────────

    #[test]
    fn validate_disables_minimap_when_no_graphics() {
        let mut c = Config::default();
        c.modules.render = false;
        c.modules.minimap = true;
        c.modules.validate_and_fix();
        assert!(!c.modules.minimap);
    }

    #[test]
    fn validate_disables_particle_when_no_graphics() {
        let mut c = Config::default();
        c.modules.render = false;
        c.modules.particle = true;
        c.modules.validate_and_fix();
        assert!(!c.modules.particle);
    }

    #[test]
    fn validate_disables_animation_when_no_graphics() {
        let mut c = Config::default();
        c.modules.render = false;
        c.modules.animation = true;
        c.modules.validate_and_fix();
        assert!(!c.modules.animation);
    }

    #[test]
    fn validate_disables_tilemap_when_no_graphics() {
        let mut c = Config::default();
        c.modules.render = false;
        c.modules.tilemap = true;
        c.modules.validate_and_fix();
        assert!(!c.modules.tilemap);
    }

    #[test]
    fn validate_disables_raycaster_when_no_graphics() {
        let mut c = Config::default();
        c.modules.render = false;
        c.modules.raycaster = true;
        c.modules.validate_and_fix();
        assert!(!c.modules.raycaster);
    }

    #[test]
    fn validate_disables_camera_when_no_graphics() {
        let mut c = Config::default();
        c.modules.render = false;
        c.modules.camera = true;
        c.modules.validate_and_fix();
        assert!(!c.modules.camera);
    }

    #[test]
    fn validate_disables_globe_when_no_graphics() {
        let mut c = Config::default();
        c.modules.render = false;
        c.modules.globe = true;
        c.modules.validate_and_fix();
        assert!(!c.modules.globe);
    }

    #[test]
    fn validate_disables_spine_when_no_graphics() {
        let mut c = Config::default();
        c.modules.render = false;
        c.modules.animation = true;
        c.modules.spine = true;
        c.modules.validate_and_fix();
        assert!(!c.modules.spine);
    }

    #[test]
    fn validate_disables_spine_when_no_animation() {
        let mut c = Config::default();
        c.modules.render = true;
        c.modules.animation = false;
        c.modules.spine = true;
        c.modules.validate_and_fix();
        assert!(!c.modules.spine);
    }

    #[test]
    fn validate_keeps_spine_when_graphics_and_animation_both_on() {
        let mut c = Config::default();
        c.modules.render = true;
        c.modules.animation = true;
        c.modules.spine = true;
        c.modules.validate_and_fix();
        assert!(c.modules.spine);
    }

    #[test]
    fn load_from_conf_toml_merges_nested_defaults() {
        let tmp = tempfile::tempdir().expect("tempdir");
        let conf = r#"
[window]
title = "Hot Reload Test"

[performance]
target_fps = 144
"#;
        std::fs::write(tmp.path().join("conf.toml"), conf).expect("write conf.toml");

        let (cfg, err) = Config::load_from_conf_toml(tmp.path());
        assert!(err.is_none(), "unexpected parse error: {:?}", err);
        assert_eq!(cfg.window.title, "Hot Reload Test");
        assert_eq!(cfg.performance.target_fps, 144);
        // Omitted nested fields should keep defaults.
        assert_eq!(cfg.window.width, 800);
        assert_eq!(cfg.window.height, 600);
        assert_eq!(cfg.performance.physics_tick_rate, 60);
    }
}

// ── ErrorCategory::Filesystem ────────────────────────────────────────────────

mod error_category_filesystem_tests {
    use super::*;

    #[test]
    fn filesystem_category_as_str() {
        assert_eq!(ErrorCategory::Filesystem.as_str(), "filesystem");
    }

    #[test]
    fn filesystem_error_maps_to_filesystem_category() {
        let e = EngineError::FileSystemError("test".into());
        assert_eq!(e.category(), ErrorCategory::Filesystem);
    }

    #[test]
    fn filesystem_error_code() {
        let e = EngineError::FileSystemError("test".into());
        assert_eq!(e.code(), "E1006");
    }
}

mod resource_memory_stats_tests {
    use super::*;

    #[test]
    fn stats_include_extended_resource_fields() {
        let mut st = SharedState::new(800, 600, "Test", PathBuf::from("."));
        st.resource_budget_bytes = 1024 * 1024;
        st.load_default_fonts();

        st.textures.insert(lurek2d::render::renderer::TextureData {
            pixels: vec![255; 4 * 16 * 16],
            width: 16,
            height: 16,
            color_space: lurek2d::image::TextureColorSpace::Srgb,
        });
        st.canvases.insert(lurek2d::render::Canvas::new(32, 32));

        let stats = st.resource_memory_stats();
        assert_eq!(stats.budget_bytes, 1024 * 1024);
        assert_eq!(stats.texture_count, 1);
        assert!(stats.texture_bytes >= 16 * 16 * 4);
        assert!(stats.font_count >= 1);
        assert!(stats.font_bytes > 0);
        assert_eq!(stats.canvas_count, 1);
        assert_eq!(stats.canvas_bytes, 32 * 32 * 4);
        assert_eq!(
            stats.total_bytes,
            stats.texture_bytes + stats.font_bytes + stats.canvas_bytes + stats.shader_bytes
        );
    }
}

mod error_snapshot_tests {
    use lurek2d::runtime::{EngineError, ErrorSnapshot};

    #[test]
    fn snapshot_has_nonempty_message() {
        let e = EngineError::LuaError("test error".into());
        let s: ErrorSnapshot = e.snapshot();
        assert!(!s.message.is_empty());
        assert!(s.message.contains("test error"), "message={}", s.message);
    }

    #[test]
    fn snapshot_has_code() {
        let e = EngineError::LuaError("x".into());
        let s = e.snapshot();
        assert!(!s.code.is_empty(), "code should not be empty");
    }

    #[test]
    fn snapshot_has_category() {
        let e = EngineError::LuaError("x".into());
        let s = e.snapshot();
        assert!(!s.category.is_empty(), "category should not be empty");
    }

    #[test]
    fn to_json_contains_expected_fields() {
        let e = EngineError::LuaError("hello".into());
        let json = e.snapshot().to_json();
        assert!(json.contains("\"message\""), "json={json}");
        assert!(json.contains("\"code\""), "json={json}");
        assert!(json.contains("\"category\""), "json={json}");
        assert!(json.contains("\"hint\""), "json={json}");
    }

    #[test]
    fn to_json_escapes_double_quotes_in_message() {
        let e = EngineError::LuaError(r#"say "hello""#.into());
        let json = e.snapshot().to_json();
        // The message value should not break the JSON structure
        assert!(json.contains(r#"say \"hello\""#), "json={json}");
    }
}

// ── PhysicsRunConfig ─────────────────────────────────────────────────────────

mod physics_run_config_tests {
    use lurek2d::runtime::shared_state::PhysicsRunConfig;

    #[test]
    fn default_fixed_dt_is_sixty_hz() {
        let cfg = PhysicsRunConfig::default();
        let diff = (cfg.fixed_dt - 1.0 / 60.0).abs();
        assert!(diff < 1e-12, "expected 1/60 s, got {}", cfg.fixed_dt);
    }

    #[test]
    fn default_max_steps_is_eight() {
        assert_eq!(PhysicsRunConfig::default().max_steps, 8);
    }

    #[test]
    fn default_debug_draw_is_false() {
        assert!(!PhysicsRunConfig::default().debug_draw);
    }

    #[test]
    fn default_fixed_update_dt_is_zero() {
        let cfg = PhysicsRunConfig::default();
        assert_eq!(cfg.fixed_update_dt, 0.0);
    }

    #[test]
    fn mutated_cfg_does_not_affect_new_default() {
        let mut cfg = PhysicsRunConfig::default();
        cfg.debug_draw = true;
        cfg.max_steps = 64;
        drop(cfg); // suppress unused-assignment warning
        let fresh = PhysicsRunConfig::default();
        assert!(!fresh.debug_draw);
        assert_eq!(fresh.max_steps, 8);
    }
}

// ── evict_lru_resources (total budget) ───────────────────────────────────────

mod evict_lru_total_budget_tests {
    use super::*;
    use slotmap::Key;

    #[test]
    fn eviction_uses_total_resource_budget_not_just_textures() {
        let mut st = SharedState::new(800, 600, "Test", PathBuf::from("."));
        // Add a canvas (contributes to total_bytes via resource_memory_stats)
        let _canvas_key = st.canvases.insert(lurek2d::render::Canvas::new(64, 64));

        // Add two textures (4 * 32 * 32 = 4096 bytes each)
        let tex_a = st.textures.insert(lurek2d::render::renderer::TextureData {
            pixels: vec![255u8; 4 * 32 * 32],
            width: 32,
            height: 32,
            color_space: lurek2d::image::TextureColorSpace::Srgb,
        });
        let tex_b = st.textures.insert(lurek2d::render::renderer::TextureData {
            pixels: vec![128u8; 4 * 32 * 32],
            width: 32,
            height: 32,
            color_space: lurek2d::image::TextureColorSpace::Srgb,
        });

        // Frame 1: touch tex_b (newer), leave tex_a at frame 0.
        st.frame_counter = 1;
        st.touch_texture(tex_b);

        // Budget: total_bytes is canvas (64*64*4=16384) + 2 textures (8192) + fonts.
        // Set budget to 0 to force eviction of both textures.
        st.resource_budget_bytes = 0;
        st.evict_lru_resources();

        // tex_a (older) must be evicted first; with budget=0 both should be evicted.
        assert!(
            !st.textures.contains_key(tex_a),
            "older texture should be evicted"
        );
        assert!(
            !st.textures.contains_key(tex_b),
            "newer texture should also be evicted when budget=0"
        );
        // Evicted handles must be queued for GPU release.
        assert!(
            st.released_texture_handles.contains(&tex_a.data().as_ffi()),
            "tex_a handle must be released"
        );
    }

    #[test]
    fn no_eviction_when_within_budget() {
        let mut st = SharedState::new(800, 600, "Test", PathBuf::from("."));
        st.textures.insert(lurek2d::render::renderer::TextureData {
            pixels: vec![0u8; 4 * 8 * 8],
            width: 8,
            height: 8,
            color_space: lurek2d::image::TextureColorSpace::Srgb,
        });
        // Very generous budget — no eviction expected.
        st.resource_budget_bytes = 1024 * 1024 * 1024;
        st.evict_lru_resources();
        assert_eq!(st.textures.len(), 1, "no texture should be evicted");
    }
}

// ── touch_canvas ─────────────────────────────────────────────────────────────

mod touch_canvas_tests {
    use super::*;

    #[test]
    fn touch_canvas_records_frame() {
        let mut st = SharedState::new(800, 600, "Test", PathBuf::from("."));
        let key = st.canvases.insert(lurek2d::render::Canvas::new(16, 16));
        st.frame_counter = 42;
        st.touch_canvas(key);
        assert_eq!(
            st.canvas_last_used.get(&key).copied(),
            Some(42),
            "canvas_last_used should be frame 42"
        );
    }

    #[test]
    fn touch_canvas_overwrites_older_frame() {
        let mut st = SharedState::new(800, 600, "Test", PathBuf::from("."));
        let key = st.canvases.insert(lurek2d::render::Canvas::new(16, 16));
        st.frame_counter = 1;
        st.touch_canvas(key);
        st.frame_counter = 99;
        st.touch_canvas(key);
        assert_eq!(st.canvas_last_used.get(&key).copied(), Some(99));
    }
}

// ── pending_config_reload ─────────────────────────────────────────────────────

mod pending_config_reload_tests {
    use super::*;

    #[test]
    fn default_pending_config_reload_is_false() {
        let st = SharedState::new(800, 600, "Test", PathBuf::from("."));
        assert!(!st.pending_config_reload);
    }

    #[test]
    fn pending_config_reload_can_be_set_and_cleared() {
        let mut st = SharedState::new(800, 600, "Test", PathBuf::from("."));
        st.pending_config_reload = true;
        assert!(st.pending_config_reload);
        st.pending_config_reload = false;
        assert!(!st.pending_config_reload);
    }
}
