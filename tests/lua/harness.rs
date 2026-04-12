//! Test harness that discovers and runs all Lua integration test scripts.
//!
//! # Running tests in parallel
//! All `#[test]` functions create their own independent Lua VM, so they run fully
//! in parallel with `cargo test`. Each VM is isolated — no shared state between tests.
//!
//! # Filtering
//! Use a substring to filter: `cargo test lua_test_math` — runs only math tests.
//! Use category prefix: `cargo test lua_unit` / `cargo test lua_integration` / `cargo test lua_stress`.
//!
//! # Parsing results
//! Run `python tools/parse_test_log.py` on captured output to get a structured report.
//! The SUMMARY line format is: `SUMMARY: total=N passed=N failed=N skipped=N`

use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;
use std::time::Instant;

use lurek2d::runtime::config::Config;
use lurek2d::lua_api::{create_lua_vm, SharedState};

fn create_test_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "Test",
        PathBuf::from("."),
    )));
    state.borrow_mut().load_default_fonts();
    let lua = create_lua_vm(state, &Config::default().modules).expect("Failed to create Lua VM");

    // Load test framework
    let framework = include_str!("init.lua");
    lua.load(framework)
        .set_name("test_framework")
        .exec()
        .expect("Failed to load test framework");

    lua
}

fn run_lua_test(filename: &str) {
    let start = Instant::now();
    let lua = create_test_vm();

    let code = std::fs::read_to_string(format!("tests/lua/{}", filename))
        .unwrap_or_else(|e| panic!("Failed to read {}: {}", filename, e));

    lua.load(&code)
        .set_name(filename)
        .exec()
        .unwrap_or_else(|e| panic!("Lua error in {}: {}", filename, e));

    // Collect results from _test_results global
    let results: mlua::Table = lua
        .globals()
        .get("_test_results")
        .expect("Missing _test_results global");

    let total: i64 = results.get("total").unwrap_or(0);
    let passed: i64 = results.get("passed").unwrap_or(0);
    let failed: i64 = results.get("failed").unwrap_or(0);
    let skipped: i64 = results.get("skipped").unwrap_or(0);

    let elapsed = start.elapsed();

    // Print structured result line (parseable by parse_test_log.py)
    println!(
        "{}: {}/{} passed, {} failed, {} skipped [{:.2}s]",
        filename,
        passed,
        total,
        failed,
        skipped,
        elapsed.as_secs_f64()
    );

    // Print all failures with FAIL: prefix (parseable by parse_test_log.py)
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
    assert!(
        total > 0 || skipped > 0,
        "No tests were run in {}",
        filename
    );
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
fn lua_test_event() {
    run_lua_test("unit/test_event.lua");
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
fn lua_test_automation() {
    run_lua_test("unit/test_automation.lua");
}

#[test]
fn lua_test_audio_bus() {
    run_lua_test("unit/test_audio_bus.lua");
}

#[test]
fn lua_test_audio_dsp() {
    run_lua_test("unit/test_audio_dsp.lua");
}

#[test]
fn lua_test_compute() {
    run_lua_test("unit/test_compute.lua");
}

#[test]
fn lua_test_data() {
    run_lua_test("unit/test_data.lua");
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
fn lua_test_pipeline() {
    run_lua_test("unit/test_pipeline.lua");
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
fn lua_test_light() {
    run_lua_test("unit/test_light.lua");
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
#[ignore = "docs quality tests fail on incomplete coverage baseline — requires docs pipeline pass"]
fn lua_test_docs() {
    run_lua_test("unit/test_docs.lua");
}

// === lurek.log tests ===

#[test]
fn lua_test_log() {
    run_lua_test("unit/test_log.lua");
}

// === lurek.gfx.newShape / CompoundShape tests ===

#[test]
fn lua_test_shape() {
    run_lua_test("unit/test_shape.lua");
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

// === lurek.ui tests ===

#[test]
fn lua_test_gui() {
    run_lua_test("unit/test_gui.lua");
}

#[test]
fn lua_test_serial() {
    run_lua_test("unit/test_serial.lua");
}

#[test]
fn lua_test_thread() {
    run_lua_test("unit/test_thread.lua");
}

#[test]
fn lua_test_savegame() {
    run_lua_test("unit/test_savegame.lua");
}

#[test]
fn lua_test_modding() {
    run_lua_test("unit/test_modding.lua");
}

// === Validation Tests ===

#[test]
fn lua_validation_toml() {
    run_lua_test("security/test_toml_validation.lua");
}

#[test]
fn lua_validation_invalid_args() {
    run_lua_test("security/test_invalid_args.lua");
}

#[test]
fn lua_validation_savegame() {
    run_lua_test("security/test_savegame_validation.lua");
}

#[test]
fn lua_validation_filesystem_security() {
    run_lua_test("security/test_mount_traversal.lua");
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
#[ignore = "lurek.sprite.newDrawLayer not yet registered (sprite module pending)"]
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
fn lua_test_parallax() {
    run_lua_test("unit/test_parallax.lua");
}

#[test]
fn lua_test_postfx() {
    run_lua_test("unit/test_postfx.lua");
}

#[test]
fn lua_test_image_effect() {
    run_lua_test("unit/test_image_effect.lua");
}

#[test]
fn lua_test_overlay() {
    run_lua_test("unit/test_overlay.lua");
}

#[test]
fn lua_test_scene() {
    run_lua_test("unit/test_scene.lua");
}

#[test]
fn lua_test_tween() {
    run_lua_test("unit/test_tween.lua");
}

#[test]
fn lua_test_image() {
    run_lua_test("unit/test_image.lua");
}

#[test]
fn lua_test_font() {
    run_lua_test("unit/test_font.lua");
}

#[test]
fn lua_test_window_scaling() {
    run_lua_test("unit/test_window_scaling.lua");
}

#[test]
fn lua_test_tilemap() {
    run_lua_test("unit/test_tilemap.lua");
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

// === Library module tests (tests/lua/library/) ===

#[test]
fn lua_test_library_dialog() {
    run_lua_test("library/test_library_dialog.lua");
}

#[test]
fn lua_test_library_quest() {
    run_lua_test("library/test_library_quest.lua");
}

#[test]
fn lua_test_library_economy() {
    run_lua_test("library/test_library_economy.lua");
}

#[test]
fn lua_test_library_battle() {
    run_lua_test("library/test_library_battle.lua");
}

#[test]
fn lua_test_library_stats() {
    run_lua_test("library/test_library_stats.lua");
}

#[test]
fn lua_test_library_crafting() {
    run_lua_test("library/test_library_crafting.lua");
}

#[test]
fn lua_test_library_cardgame() {
    run_lua_test("library/test_library_cardgame.lua");
}

#[test]
fn lua_test_library_combat() {
    run_lua_test("library/test_library_combat.lua");
}

#[test]
fn lua_test_library_province_map() {
    run_lua_test("library/test_library_province_map.lua");
}

#[test]
fn lua_test_library_inventory() {
    run_lua_test("library/test_library_inventory.lua");
}

#[test]
fn lua_test_library_item() {
    run_lua_test("library/test_library_item.lua");
}

#[test]
fn lua_test_library_doll() {
    run_lua_test("library/test_library_doll.lua");
}
#[test]
fn lua_test_animation() {
    run_lua_test("unit/test_animation.lua");
}
#[test]
fn lua_test_camera() {
    run_lua_test("unit/test_camera.lua");
}
#[test]
#[ignore = "lurek.net raw ENet API is not yet registered in the Lua VM"]
fn lua_test_network_host() {
    run_lua_test("unit/test_network.lua");
}
#[test]
fn lua_test_procgen() {
    run_lua_test("unit/test_procgen.lua");
}
#[test]
fn lua_test_raycaster() {
    run_lua_test("unit/test_raycaster.lua");
}
#[test]
fn lua_test_spine() {
    run_lua_test("unit/test_spine.lua");
}

#[test]
fn lua_test_rendering_drawing_contract() {
    run_lua_test("unit/test_rendering_drawing_contract.lua");
}

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

#[test]
fn lua_integration_debugbridge() {
    run_lua_test("integration/test_debugbridge.lua");
}

#[test]
fn lua_integration_devtools() {
    run_lua_test("integration/test_devtools.lua");
}

#[test]
fn lua_integration_docs() {
    run_lua_test("integration/test_docs.lua");
}

#[test]
fn lua_integration_drawlayer() {
    run_lua_test("integration/test_drawlayer.lua");
}

#[test]
fn lua_integration_system() {
    run_lua_test("integration/test_system.lua");
}

// ─── New: unit, config, examples ─────────────────────────────────────────

#[test]
fn lua_test_terminal() {
    run_lua_test("unit/test_terminal.lua");
}

#[test]
fn lua_test_fx() {
    run_lua_test("unit/test_fx.lua");
}

#[test]
fn lua_test_config() {
    run_lua_test("config/test_config.lua");
}

#[test]
fn lua_test_examples() {
    run_lua_test("examples/test_examples.lua");
}

// ─── Phase 2 Integration Tests ───────────────────────────────────────────────

#[test]
fn lua_integration_graphics_camera() {
    run_lua_test("integration/test_graphics_camera.lua");
}

#[test]
fn lua_integration_graphics_animation() {
    run_lua_test("integration/test_graphics_animation.lua");
}

#[test]
fn lua_integration_audio_timer() {
    run_lua_test("integration/test_audio_timer.lua");
}

#[test]
fn lua_integration_audio_event() {
    run_lua_test("integration/test_audio_event.lua");
}

#[test]
fn lua_integration_ai_entity_scene() {
    run_lua_test("integration/test_ai_entity_scene.lua");
}

#[test]
fn lua_integration_savegame_entity_scene() {
    run_lua_test("integration/test_savegame_entity_scene.lua");
}

#[test]
fn lua_integration_tween_animation() {
    run_lua_test("integration/test_tween_animation.lua");
}

#[test]
fn lua_integration_procgen_tilemap() {
    run_lua_test("integration/test_procgen_tilemap.lua");
}

#[test]
fn lua_integration_pathfinding_entity() {
    run_lua_test("integration/test_pathfinding_entity.lua");
}

#[test]
fn lua_integration_data_compute() {
    run_lua_test("integration/test_data_compute.lua");
}

// ─── Golden ──────────────────────────────────────────────────────────────────

#[test]
fn lua_golden_math() {
    run_lua_test("golden/test_math_golden.lua");
}

#[test]
fn lua_golden_data() {
    run_lua_test("golden/test_data_golden.lua");
}

#[test]
fn lua_golden_serial() {
    run_lua_test("golden/test_serial_golden.lua");
}

#[test]
fn lua_golden_physics() {
    run_lua_test("golden/test_physics_golden.lua");
}

#[test]
fn lua_golden_animation() {
    run_lua_test("golden/test_animation_golden.lua");
}

#[test]
fn lua_golden_procgen() {
    run_lua_test("golden/test_procgen_golden.lua");
}

// ─── Security ─────────────────────────────────────────────────────────────────

#[test]
fn lua_security_api_fuzz() {
    run_lua_test("security/test_api_fuzz.lua");
}

// ─── Stress ───────────────────────────────────────────────────────────────────

#[test]
fn lua_stress_graphics() {
    run_lua_test("stress/test_graphics_stress.lua");
}

#[test]
fn lua_stress_animation() {
    run_lua_test("stress/test_animation_stress.lua");
}

#[test]
fn lua_stress_serial() {
    run_lua_test("stress/test_serial_stress.lua");
}

#[test]
fn lua_stress_thread() {
    run_lua_test("stress/test_thread_stress.lua");
}

// ─── Property-Based ──────────────────────────────────────────────────────────

#[test]
fn lua_unit_math_property() {
    run_lua_test("unit/test_math_property.lua");
}

// ─── Unit library tests (battle / crafting / dialog) ─────────────────────────

#[test]
#[ignore = "lurek.turnbattle moved to library/battle; use lua_test_library_battle"]
fn lua_unit_battle() {
    run_lua_test("unit/test_battle.lua");
}

#[test]
#[ignore = "lurek.crafting moved to library/crafting; use lua_test_library_crafting"]
fn lua_unit_crafting() {
    run_lua_test("unit/test_crafting.lua");
}

#[test]
#[ignore = "lurek.dialog moved to library/dialog; use lua_test_library_dialog"]
fn lua_unit_dialog() {
    run_lua_test("unit/test_dialog.lua");
}

// ─── Phase 3 Integration Tests ───────────────────────────────────────────────

#[test]
fn lua_integration_entity_physics() {
    run_lua_test("integration/test_entity_physics.lua");
}

#[test]
fn lua_integration_entity_graphics() {
    run_lua_test("integration/test_entity_graphics.lua");
}

#[test]
fn lua_integration_scene_entity() {
    run_lua_test("integration/test_scene_entity.lua");
}

#[test]
fn lua_integration_scene_camera() {
    run_lua_test("integration/test_scene_camera.lua");
}

#[test]
fn lua_integration_tilemap_camera() {
    run_lua_test("integration/test_tilemap_camera.lua");
}

#[test]
fn lua_integration_ai_pathfinding() {
    run_lua_test("integration/test_ai_pathfinding.lua");
}

#[test]
fn lua_integration_input_camera() {
    run_lua_test("integration/test_input_camera.lua");
}

#[test]
fn lua_integration_animation_timer() {
    run_lua_test("integration/test_animation_timer.lua");
}

#[test]
fn lua_integration_data_filesystem() {
    run_lua_test("integration/test_data_filesystem.lua");
}

#[test]
fn lua_integration_savegame_tilemap() {
    run_lua_test("integration/test_savegame_tilemap.lua");
}

#[test]
fn lua_integration_signal_entity() {
    run_lua_test("integration/test_signal_entity.lua");
}

#[test]
fn lua_integration_tilemap_pathfinding() {
    run_lua_test("integration/test_tilemap_pathfinding.lua");
}

#[test]
fn lua_integration_thread_data() {
    run_lua_test("integration/test_thread_data.lua");
}

#[test]
fn lua_integration_tween_camera() {
    run_lua_test("integration/test_tween_camera.lua");
}

#[test]
fn lua_integration_tween_entity() {
    run_lua_test("integration/test_tween_entity.lua");
}

#[test]
fn lua_integration_particle_timer() {
    run_lua_test("integration/test_particle_timer.lua");
}

#[test]
fn lua_integration_parallax_camera() {
    run_lua_test("integration/test_parallax_camera.lua");
}

#[test]
fn lua_integration_light_graphics() {
    run_lua_test("integration/test_light_graphics.lua");
}

#[test]
fn lua_integration_localization_ui() {
    run_lua_test("integration/test_localization_ui.lua");
}

// ─── Phase 3 Golden Tests ────────────────────────────────────────────────────

#[test]
fn lua_golden_dataframe() {
    run_lua_test("golden/test_dataframe_golden.lua");
}

#[test]
fn lua_golden_pathfinding() {
    run_lua_test("golden/test_pathfinding_golden.lua");
}

#[test]
fn lua_golden_graph() {
    run_lua_test("golden/test_graph_golden.lua");
}

#[test]
fn lua_golden_ai() {
    run_lua_test("golden/test_ai_golden.lua");
}

#[test]
fn lua_golden_compute() {
    run_lua_test("golden/test_compute_golden.lua");
}

#[test]
fn lua_golden_tilemap() {
    run_lua_test("golden/test_tilemap_golden.lua");
}

#[test]
fn lua_golden_entity() {
    run_lua_test("golden/test_entity_golden.lua");
}

// ─── Phase 3 Stress Tests ─────────────────────────────────────────────────────

#[test]
fn lua_stress_ai() {
    run_lua_test("stress/test_ai_stress.lua");
}

#[test]
fn lua_stress_scene() {
    run_lua_test("stress/test_scene_stress.lua");
}

#[test]
fn lua_stress_camera() {
    run_lua_test("stress/test_camera_stress.lua");
}

#[test]
fn lua_stress_savegame() {
    run_lua_test("stress/test_savegame_stress.lua");
}

#[test]
fn lua_stress_timer() {
    run_lua_test("stress/test_timer_stress.lua");
}

#[test]
fn lua_stress_signal() {
    run_lua_test("stress/test_signal_stress.lua");
}

#[test]
fn lua_stress_tween() {
    run_lua_test("stress/test_tween_stress.lua");
}

#[test]
fn lua_stress_image() {
    run_lua_test("stress/test_image_stress.lua");
}

#[test]
fn lua_stress_patterns() {
    run_lua_test("stress/test_patterns_stress.lua");
}

#[test]
fn lua_stress_filesystem() {
    run_lua_test("stress/test_filesystem_stress.lua");
}

#[test]
fn lua_stress_light() {
    run_lua_test("stress/test_light_stress.lua");
}

// ─── Evidence Tests ───────────────────────────────────────────────────────────
// Tests in tests/lua/evidence/ verify observable API state and save PNG/JSON
// artefacts to tests/lua/evidence/output/ for human inspection.

#[test]
fn lua_evidence_imagedata() {
    run_lua_test("evidence/test_evidence_imagedata.lua");
}

#[test]
fn lua_evidence_imagedata_effects() {
    run_lua_test("evidence/test_evidence_imagedata_effects.lua");
}

#[test]
fn lua_evidence_canvas() {
    run_lua_test("evidence/test_evidence_canvas.lua");
}

#[test]
fn lua_evidence_graphic_drawing() {
    run_lua_test("evidence/test_evidence_graphic_drawing.lua");
}

#[test]
fn lua_evidence_audio() {
    run_lua_test("evidence/test_evidence_audio.lua");
}

#[test]
fn lua_evidence_audio_bus() {
    run_lua_test("evidence/test_evidence_audio_bus.lua");
}

#[test]
fn lua_evidence_light() {
    run_lua_test("evidence/test_evidence_light.lua");
}

#[test]
fn lua_evidence_particle() {
    run_lua_test("evidence/test_evidence_particle.lua");
}

#[test]
fn lua_evidence_postfx() {
    run_lua_test("evidence/test_evidence_postfx.lua");
}

#[test]
fn lua_evidence_minimap() {
    run_lua_test("evidence/test_evidence_minimap.lua");
}

#[test]
fn lua_evidence_tilemap() {
    run_lua_test("evidence/test_evidence_tilemap.lua");
}

#[test]
fn lua_evidence_raycaster() {
    run_lua_test("evidence/test_evidence_raycaster.lua");
}

#[test]
fn lua_evidence_overlay() {
    run_lua_test("evidence/test_evidence_overlay.lua");
}

// ─── Evidence: Math, Noise, Procgen, Effects ──────────────────────────────

#[test]
fn lua_evidence_noise() {
    run_lua_test("evidence/test_evidence_noise.lua");
}

#[test]
fn lua_evidence_easing() {
    run_lua_test("evidence/test_evidence_easing.lua");
}

#[test]
fn lua_evidence_procgen() {
    run_lua_test("evidence/test_evidence_procgen.lua");
}

#[test]
fn lua_evidence_image_effects() {
    run_lua_test("evidence/test_evidence_image_effects.lua");
}

#[test]
fn lua_evidence_image_drawing() {
    run_lua_test("evidence/test_evidence_image_drawing.lua");
}

#[test]
fn lua_evidence_physics() {
    run_lua_test("evidence/test_evidence_physics.lua");
}

#[test]
fn lua_evidence_bezier() {
    run_lua_test("evidence/test_evidence_bezier.lua");
}

#[test]
fn lua_evidence_pathfinding() {
    run_lua_test("evidence/test_evidence_pathfinding.lua");
}

#[test]
fn lua_evidence_animation() {
    run_lua_test("evidence/test_evidence_animation.lua");
}

#[test]
fn lua_evidence_camera() {
    run_lua_test("evidence/test_evidence_camera.lua");
}

#[test]
fn lua_evidence_graph() {
    run_lua_test("evidence/test_evidence_graph.lua");
}

#[test]
fn lua_evidence_audio_dsp() {
    run_lua_test("evidence/test_evidence_audio_dsp.lua");
}

#[test]
fn lua_evidence_audio_waves() {
    run_lua_test("evidence/test_evidence_audio_waves.lua");
}

#[test]
fn lua_evidence_charts() {
    run_lua_test("evidence/test_evidence_charts.lua");
}

#[test]
fn lua_evidence_spine() {
    run_lua_test("evidence/test_evidence_spine.lua");
}

#[test]
fn lua_evidence_layers() {
    run_lua_test("evidence/test_evidence_layers.lua");
}

#[test]
fn lua_evidence_shapes() {
    run_lua_test("evidence/test_evidence_shapes.lua");
}

#[test]
fn lua_evidence_combined() {
    run_lua_test("evidence/test_evidence_combined.lua");
}
