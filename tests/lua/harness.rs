//! Test harness that discovers and runs all Lua integration test scripts.

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
    let framework = include_str!("init.lua");
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
    run_lua_test("unit/test_math.lua");
}

#[test]
fn lua_test_timer() {
    run_lua_test("unit/test_timer.lua");
}

#[test]
fn lua_test_input() {
    run_lua_test("unit/test_input.lua");
}

#[test]
fn lua_test_window() {
    run_lua_test("unit/test_window.lua");
}

#[test]
fn lua_test_system() {
    run_lua_test("unit/test_system.lua");
}

#[test]
fn lua_test_graphics() {
    run_lua_test("unit/test_graphics.lua");
}

#[test]
fn lua_test_physics() {
    run_lua_test("unit/test_physics.lua");
}

#[test]
fn lua_test_ai() {
    run_lua_test("unit/test_ai.lua");
}

#[test]
fn lua_test_audio_bus() {
    run_lua_test("unit/test_audio_bus.lua");
}

#[test]
fn lua_test_compute() {
    run_lua_test("unit/test_compute.lua");
}

#[test]
fn lua_test_dataframe() {
    run_lua_test("unit/test_dataframe.lua");
}

#[test]
fn lua_test_graph() {
    run_lua_test("unit/test_graph.lua");
}

#[test]
fn lua_test_pathfinding() {
    run_lua_test("unit/test_pathfinding.lua");
}

#[test]
fn lua_test_signal() {
    run_lua_test("unit/test_signal.lua");
}

#[test]
fn lua_test_patterns() {
    run_lua_test("unit/test_patterns.lua");
}

#[test]
fn lua_test_localization() {
    run_lua_test("unit/test_localization.lua");
}

#[test]
fn lua_test_joystick_ext() {
    run_lua_test("unit/test_joystick_ext.lua");
}

#[test]
fn lua_test_devtools() {
    run_lua_test("unit/test_devtools.lua");
}

#[test]
fn lua_test_debugbridge() {
    run_lua_test("unit/test_debugbridge.lua");
}

#[test]
fn lua_test_docs() {
    run_lua_test("unit/test_docs.lua");
}

#[test]
fn lua_test_battle() {
    run_lua_test("unit/test_battle.lua");
}

// === luna.crafting tests ===

#[test]
fn lua_test_crafting() {
    run_lua_test("unit/test_crafting.lua");
}

// === luna.log tests ===

#[test]
fn lua_test_log() {
    run_lua_test("unit/test_log.lua");
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

// === Additional Root Unit Tests ===

#[test]
fn lua_test_audio() {
    run_lua_test("unit/test_audio.lua");
}

#[test]
fn lua_test_dialog() {
    run_lua_test("unit/test_dialog.lua");
}

#[test]
fn lua_test_drawlayer() {
    run_lua_test("unit/test_drawlayer.lua");
}

#[test]
fn lua_test_entity() {
    run_lua_test("unit/test_entity.lua");
}

#[test]
fn lua_test_filesystem() {
    run_lua_test("unit/test_filesystem.lua");
}

#[test]
fn lua_test_minimap() {
    run_lua_test("unit/test_minimap.lua");
}

#[test]
fn lua_test_particle() {
    run_lua_test("unit/test_particle.lua");
}

#[test]
fn lua_test_postfx() {
    run_lua_test("unit/test_postfx.lua");
}

#[test]
fn lua_test_scene() {
    run_lua_test("unit/test_scene.lua");
}

#[test]
fn lua_test_tween() {
    run_lua_test("unit/test_tween.lua");
}

// === Additional Stress Tests ===

#[test]
fn lua_stress_data() {
    run_lua_test("stress/test_data_stress.lua");
}

#[test]
fn lua_stress_math() {
    run_lua_test("stress/test_math_stress.lua");
}

#[test]
fn lua_stress_physics() {
    run_lua_test("stress/test_physics_stress.lua");
}

// === Additional Integration Tests ===

#[test]
fn lua_integration_data_system() {
    run_lua_test("integration/test_data_system.lua");
}
#[test]
fn lua_integration_math_graphics() {
    run_lua_test("integration/test_math_graphics.lua");
}
#[test]
fn lua_integration_math_physics() {
    run_lua_test("integration/test_math_physics.lua");
}
#[test]
fn lua_integration_physics_timer() {
    run_lua_test("integration/test_physics_timer.lua");
}
#[test]
fn lua_integration_timer_math() {
    run_lua_test("integration/test_timer_math.lua");
}
