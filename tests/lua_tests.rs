use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

use luna2d::lua_api::{create_lua_vm, SharedState};

fn create_test_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "Test",
        PathBuf::from("."),
    )));
    let lua = create_lua_vm(state).expect("Failed to create Lua VM");

    // Load test framework
    let framework = include_str!("lua/init.lua");
    lua.load(framework)
        .set_name("test_framework")
        .exec()
        .expect("Failed to load test framework");

    lua
}

fn run_lua_test(filename: &str) {
    let lua = create_test_vm();

    let code = std::fs::read_to_string(format!("tests/lua/{}", filename))
        .unwrap_or_else(|e| panic!("Failed to read {}: {}", filename, e));

    lua.load(&code)
        .set_name(filename)
        .exec()
        .unwrap_or_else(|e| panic!("Lua error in {}: {}", filename, e));

    // Check test results
    let results: mlua::Table = lua
        .globals()
        .get("_test_results")
        .expect("Missing _test_results global");

    let total: i64 = results.get("total").unwrap_or(0);
    let passed: i64 = results.get("passed").unwrap_or(0);
    let failed: i64 = results.get("failed").unwrap_or(0);

    println!(
        "{}: {}/{} passed, {} failed",
        filename, passed, total, failed
    );

    if failed > 0 {
        if let Ok(errors) = results.get::<_, mlua::Table>("errors") {
            for pair in errors.pairs::<i64, mlua::Table>() {
                if let Ok((_, err_tbl)) = pair {
                    let suite: String = err_tbl.get("suite").unwrap_or_default();
                    let test: String = err_tbl.get("test").unwrap_or_default();
                    let error: String = err_tbl.get("error").unwrap_or_default();
                    eprintln!("  FAIL: [{}] {} - {}", suite, test, error);
                }
            }
        }
    }

    assert_eq!(failed, 0, "{} Lua tests failed in {}", failed, filename);
    assert!(total > 0, "No tests were run in {}", filename);
}

#[test]
fn lua_test_math() {
    run_lua_test("test_math.lua");
}

#[test]
fn lua_test_timer() {
    run_lua_test("test_timer.lua");
}

#[test]
fn lua_test_input() {
    run_lua_test("test_input.lua");
}

#[test]
fn lua_test_window() {
    run_lua_test("test_window.lua");
}

#[test]
fn lua_test_system() {
    run_lua_test("test_system.lua");
}

#[test]
fn lua_test_graphics() {
    run_lua_test("test_graphics.lua");
}

#[test]
fn lua_test_physics() {
    run_lua_test("test_physics.lua");
}

#[test]
fn lua_test_ai() {
    run_lua_test("test_ai.lua");
}

#[test]
fn lua_test_audio_bus() {
    run_lua_test("test_audio_bus.lua");
}

#[test]
fn lua_test_compute() {
    run_lua_test("test_compute.lua");
}

#[test]
fn lua_test_dataframe() {
    run_lua_test("test_dataframe.lua");
}

#[test]
fn lua_test_graph() {
    run_lua_test("test_graph.lua");
}

#[test]
fn lua_test_pathfinding() {
    run_lua_test("test_pathfinding.lua");
}

#[test]
fn lua_test_signal() {
    run_lua_test("test_signal.lua");
}

#[test]
fn lua_test_patterns() {
    run_lua_test("test_patterns.lua");
}

#[test]
fn lua_test_localization() {
    run_lua_test("test_localization.lua");
}

#[test]
fn lua_test_joystick_ext() {
    run_lua_test("test_joystick_ext.lua");
}

#[test]
fn lua_test_devtools() {
    run_lua_test("test_devtools.lua");
}

#[test]
fn lua_test_debugbridge() {
    run_lua_test("test_debugbridge.lua");
}

#[test]
fn lua_test_docs() {
    run_lua_test("test_docs.lua");
}

// === luna.log tests ===

#[test]
fn test_log_api_namespace_exists() {
    let lua = create_test_vm();
    lua.load(
        r#"
        assert(type(luna.log) == "table", "luna.log should be a table")
        assert(type(luna.log.info) == "function", "luna.log.info should be a function")
        "#,
    )
    .exec()
    .expect("luna.log namespace check failed");
}

#[test]
fn test_log_info_does_not_error() {
    let lua = create_test_vm();
    lua.load(r#"luna.log.info("test message")"#)
        .exec()
        .expect("luna.log.info should not return a Lua error");
}

#[test]
fn test_log_warn_does_not_error() {
    let lua = create_test_vm();
    lua.load(r#"luna.log.warn("test warning")"#)
        .exec()
        .expect("luna.log.warn should not return a Lua error");
}

#[test]
fn test_log_error_does_not_error() {
    let lua = create_test_vm();
    lua.load(r#"luna.log.error("test error")"#)
        .exec()
        .expect("luna.log.error should not return a Lua error");
}

#[test]
fn test_log_debug_does_not_error() {
    let lua = create_test_vm();
    lua.load(r#"luna.log.debug("test debug")"#)
        .exec()
        .expect("luna.log.debug should not return a Lua error");
}

#[test]
fn test_log_print_dispatches() {
    let lua = create_test_vm();
    lua.load(r#"luna.log.print("info", "printed msg")"#)
        .exec()
        .expect("luna.log.print should not return a Lua error");
}

#[test]
fn test_log_set_and_get_level() {
    let lua = create_test_vm();
    lua.load(
        r#"
        luna.log.setLevel("warn")
        local level = luna.log.getLevel()
        assert(level == "warn", "expected 'warn', got: " .. tostring(level))
        luna.log.setLevel("debug")
        "#,
    )
    .exec()
    .expect("luna.log.setLevel / getLevel round-trip failed");
}

#[test]
fn test_log_getlevel_returns_string() {
    let lua = create_test_vm();
    lua.load(
        r#"
        local level = luna.log.getLevel()
        assert(type(level) == "string", "getLevel should return a string")
        assert(#level > 0, "getLevel should return a non-empty string")
        "#,
    )
    .exec()
    .expect("luna.log.getLevel should return a non-empty string");
}

#[test]
fn test_log_print_unknown_level_does_not_crash() {
    let lua = create_test_vm();
    lua.load(r#"luna.log.print("unknown_level", "msg")"#)
        .exec()
        .expect("luna.log.print with unknown level should not crash");
}

// === Stress Tests ===

#[test]
fn lua_stress_tilemap() {
    run_lua_test("stress/test_tilemap_stress.lua");
}

#[test]
fn lua_stress_compute() {
    run_lua_test("stress/test_compute_stress.lua");
}

#[test]
fn lua_stress_dataframe() {
    run_lua_test("stress/test_dataframe_stress.lua");
}

#[test]
fn lua_stress_pathfinding() {
    run_lua_test("stress/test_pathfinding_stress.lua");
}

#[test]
fn lua_stress_physics_collision() {
    run_lua_test("stress/test_physics_collision_stress.lua");
}

#[test]
fn lua_stress_graph() {
    run_lua_test("stress/test_graph_stress.lua");
}

#[test]
fn lua_stress_entity() {
    run_lua_test("stress/test_entity_stress.lua");
}

#[test]
fn lua_stress_particle() {
    run_lua_test("stress/test_particle_stress.lua");
}

#[test]
fn lua_stress_data_compression() {
    run_lua_test("stress/test_data_compression_stress.lua");
}

// === Validation Tests ===

#[test]
fn lua_validation_toml() {
    run_lua_test("validation/test_toml_validation.lua");
}

#[test]
fn lua_validation_invalid_args() {
    run_lua_test("validation/test_invalid_args.lua");
}

#[test]
fn lua_validation_savegame() {
    run_lua_test("validation/test_savegame_validation.lua");
}

// === Cross-Module Integration Tests ===

#[test]
fn lua_integration_ai_physics() {
    run_lua_test("integration/test_ai_physics.lua");
}

#[test]
fn lua_integration_tilemap_physics() {
    run_lua_test("integration/test_tilemap_physics.lua");
}

#[test]
fn lua_integration_entity_ai() {
    run_lua_test("integration/test_entity_ai.lua");
}

#[test]
fn lua_integration_compute_dataframe() {
    run_lua_test("integration/test_compute_dataframe.lua");
}

#[test]
fn lua_integration_save_entity() {
    run_lua_test("integration/test_save_entity.lua");
}
