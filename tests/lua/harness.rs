//! Test harness that discovers and runs all Lua integration test scripts.
//!
//! # Running tests in parallel
//! Cargo runs test executables serially, but libtest may run the `#[test]`
//! functions inside this harness in parallel. Each function creates its own
//! independent Lua VM, so those in-process runs stay isolated from each other.
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

use lurek2d::lua_api::{create_lua_vm, SharedState};
use lurek2d::runtime::config::Config;

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

    // Expose a safe read-only file helper for static-analysis tests.
    // The sandbox removes io.open; this restores read-only access to workspace files.
    let read_file_fn = lua
        .create_function(|_, path: String| match std::fs::read_to_string(&path) {
            Ok(s) => Ok(Some(s)),
            Err(_) => Ok(None),
        })
        .expect("Failed to create read_file helper");
    lua.globals()
        .set("read_file", read_file_fn)
        .expect("Failed to register read_file");

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
fn lua_integration_physics_platformer() {
    run_lua_test("integration/test_physics_platformer.lua");
}

#[test]
fn lua_integration_physics_worms() {
    run_lua_test("integration/test_physics_worms.lua");
}

#[test]
fn lua_integration_physics_tanks() {
    run_lua_test("integration/test_physics_tanks.lua");
}

#[test]
fn lua_integration_physics_space() {
    run_lua_test("integration/test_physics_space.lua");
}

#[test]
fn lua_integration_physics_world_sim() {
    run_lua_test("integration/test_physics_world_sim.lua");
}

// === lurek.log tests ===// === lurek.render.newShape / CompoundShape tests ===
// === Stress Tests ===
// === lurek.ui tests ===
// === Validation Tests ===

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
fn lua_integration_ecs_ai() {
    run_lua_test("integration/test_ecs_ai.lua");
}

#[test]
fn lua_integration_compute_dataframe() {
    run_lua_test("integration/test_compute_dataframe.lua");
}

#[test]
fn lua_integration_save_ecs() {
    run_lua_test("integration/test_save_ecs.lua");
}

// === Additional Root Unit Tests ===
// === Additional Stress Tests ===// === Additional Integration Tests ===

// === Library module tests (tests/lua/library/) ===
#[test]
fn lua_integration_data_system() {
    run_lua_test("integration/test_data_app.lua");
}
#[test]
fn lua_integration_math_render() {
    run_lua_test("integration/test_math_render.lua");
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
fn lua_integration_runtime_system() {
    run_lua_test("integration/test_runtime_app.lua");
}

// ─── Phase 2 Integration Tests ───────────────────────────────────────────────

#[test]
fn lua_integration_render_camera() {
    run_lua_test("integration/test_render_camera.lua");
}

#[test]
fn lua_integration_render_animation() {
    run_lua_test("integration/test_render_animation.lua");
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
fn lua_integration_ai_ecs_scene() {
    run_lua_test("integration/test_ai_ecs_scene.lua");
}

#[test]
fn lua_integration_save_ecs_scene() {
    run_lua_test("integration/test_save_ecs_scene.lua");
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
fn lua_integration_pathfind_ecs() {
    run_lua_test("integration/test_pathfind_ecs.lua");
}

#[test]
fn lua_integration_data_compute() {
    run_lua_test("integration/test_data_compute.lua");
}

// ─── Golden ──────────────────────────────────────────────────────────────────
// ─── Security ─────────────────────────────────────────────────────────────────// ─── Stress ───────────────────────────────────────────────────────────────────// ─── Property-Based ──────────────────────────────────────────────────────────
// ─── Unit library tests (battle / crafting / dialog) ─────────────────────────

// ─── Phase 3 Integration Tests ───────────────────────────────────────────────

#[test]
fn lua_integration_ecs_physics() {
    run_lua_test("integration/test_ecs_physics.lua");
}

#[test]
fn lua_integration_ecs_render() {
    run_lua_test("integration/test_ecs_render.lua");
}

#[test]
fn lua_integration_scene_ecs() {
    run_lua_test("integration/test_scene_ecs.lua");
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
fn lua_integration_ai_pathfind() {
    run_lua_test("integration/test_ai_pathfind.lua");
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
    run_lua_test("integration/test_data_fileapp.lua");
}

#[test]
fn lua_integration_save_tilemap() {
    run_lua_test("integration/test_save_tilemap.lua");
}

#[test]
fn lua_integration_event_entity() {
    run_lua_test("integration/test_event_ecs.lua");
}

#[test]
fn lua_integration_tilemap_pathfind() {
    run_lua_test("integration/test_tilemap_pathfind.lua");
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
fn lua_integration_tween_ecs() {
    run_lua_test("integration/test_tween_ecs.lua");
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
fn lua_integration_light_render() {
    run_lua_test("integration/test_light_render.lua");
}

#[test]
fn lua_integration_i18n_ui() {
    run_lua_test("integration/test_i18n_ui.lua");
}

// ─── Phase 3 Golden Tests ────────────────────────────────────────────────────
// ─── Phase 3 Stress Tests ─────────────────────────────────────────────────────
// ─── Evidence Tests ───────────────────────────────────────────────────────────
// Tests in tests/lua/evidence/ verify observable API state and save PNG/JSON
// artefacts to tests/lua/evidence/output/ for human inspection.// ─── Evidence: Math, Noise, Procgen, Effects ──────────────────────────────// ─── Phase 4: Math / Pathfinding / Procgen / Graph expansion ─────────────────

#[test]
fn lua_integration_pathfind_hexmap() {
    run_lua_test("integration/test_pathfind_hexmap.lua");
}

#[test]
fn lua_integration_pathfind_graph() {
    run_lua_test("integration/test_pathfind_graph.lua");
}

#[test]
fn lua_integration_math_pathfind() {
    run_lua_test("integration/test_math_pathfind.lua");
}

#[test]
fn lua_integration_procgen_ai() {
    run_lua_test("integration/test_procgen_ai.lua");
}

#[test]
fn lua_integration_pathfind_ai() {
    run_lua_test("integration/test_pathfind_ai.lua");
}

#[test]
fn lua_integration_graph_pathfind() {
    run_lua_test("integration/test_graph_pathfind.lua");
}

// ── config layer ──

#[test]
fn lua_config_config() {
    run_lua_test("config/test_config.lua");
}

// ── unit layer ──

#[test]
fn lua_unit_ai_unit() {
    run_lua_test("unit/test_ai_unit.lua");
}

#[test]
fn lua_unit_animation_unit() {
    run_lua_test("unit/test_animation_unit.lua");
}

#[test]
fn lua_unit_audio_unit() {
    run_lua_test("unit/test_audio_unit.lua");
}

#[test]
fn lua_unit_automation_unit() {
    run_lua_test("unit/test_automation_unit.lua");
}

#[test]
fn lua_unit_battle_unit() {
    run_lua_test("unit/test_battle_unit.lua");
}

#[test]
fn lua_unit_camera_unit() {
    run_lua_test("unit/test_camera_unit.lua");
}

#[test]
fn lua_unit_compute_unit() {
    run_lua_test("unit/test_compute_unit.lua");
}

#[test]
fn lua_unit_crafting_unit() {
    run_lua_test("unit/test_crafting_unit.lua");
}

#[test]
fn lua_unit_data_unit() {
    run_lua_test("unit/test_data_unit.lua");
}

#[test]
fn lua_unit_dataframe_unit() {
    run_lua_test("unit/test_dataframe_unit.lua");
}

#[test]
fn lua_unit_debugbridge_unit() {
    run_lua_test("unit/test_debugbridge_unit.lua");
}

#[test]
fn lua_unit_devtools_unit() {
    run_lua_test("unit/test_devtools_unit.lua");
}

#[test]
fn lua_unit_dialog_unit() {
    run_lua_test("unit/test_dialog_unit.lua");
}

#[test]
fn lua_unit_docs_unit() {
    run_lua_test("unit/test_docs_unit.lua");
}

#[test]
fn lua_unit_drawlayer_unit() {
    run_lua_test("unit/test_drawlayer_unit.lua");
}

#[test]
fn lua_unit_ecs_unit() {
    run_lua_test("unit/test_ecs_unit.lua");
}

#[test]
fn lua_unit_effect_unit() {
    run_lua_test("unit/test_effect_unit.lua");
}

#[test]
fn lua_unit_event_unit() {
    run_lua_test("unit/test_event_unit.lua");
}

#[test]
fn lua_unit_filesystem_unit() {
    run_lua_test("unit/test_filesystem_unit.lua");
}

#[test]
fn lua_unit_font_unit() {
    run_lua_test("unit/test_font_unit.lua");
}

#[test]
fn lua_unit_globe_unit() {
    run_lua_test("unit/test_globe_unit.lua");
}

#[test]
fn lua_unit_graph_unit() {
    run_lua_test("unit/test_graph_unit.lua");
}

#[test]
fn lua_unit_gui_unit() {
    run_lua_test("unit/test_gui_unit.lua");
}

#[test]
fn lua_unit_i18n_unit() {
    run_lua_test("unit/test_i18n_unit.lua");
}

#[test]
fn lua_unit_image_unit() {
    run_lua_test("unit/test_image_unit.lua");
}

#[test]
fn lua_unit_input_unit() {
    run_lua_test("unit/test_input_unit.lua");
}

#[test]
fn lua_unit_light_unit() {
    run_lua_test("unit/test_light_unit.lua");
}

#[test]
fn lua_unit_log_unit() {
    run_lua_test("unit/test_log_unit.lua");
}

#[test]
fn lua_unit_math_unit() {
    run_lua_test("unit/test_math_unit.lua");
}

#[test]
fn lua_unit_minimap_unit() {
    run_lua_test("unit/test_minimap_unit.lua");
}

#[test]
fn lua_unit_mods_unit() {
    run_lua_test("unit/test_mods_unit.lua");
}

#[test]
fn lua_unit_network_unit() {
    run_lua_test("unit/test_network_unit.lua");
}

#[test]
fn lua_unit_parallax_unit() {
    run_lua_test("unit/test_parallax_unit.lua");
}

#[test]
fn lua_unit_particle_unit() {
    run_lua_test("unit/test_particle_unit.lua");
}

#[test]
fn lua_unit_pathfind_unit() {
    run_lua_test("unit/test_pathfind_unit.lua");
}

#[test]
fn lua_unit_patterns_unit() {
    run_lua_test("unit/test_patterns_unit.lua");
}

#[test]
fn lua_unit_physics_unit() {
    run_lua_test("unit/test_physics_unit.lua");
}

#[test]
fn lua_unit_pipeline_unit() {
    run_lua_test("unit/test_pipeline_unit.lua");
}

#[test]
fn lua_unit_procgen_unit() {
    run_lua_test("unit/test_procgen_unit.lua");
}

#[test]
fn lua_unit_raycaster_unit() {
    run_lua_test("unit/test_raycaster_unit.lua");
}

#[test]
fn lua_unit_render_unit() {
    run_lua_test("unit/test_render_unit.lua");
}

#[test]
fn lua_unit_runtime_unit() {
    run_lua_test("unit/test_runtime_unit.lua");
}

#[test]
fn lua_unit_save_unit() {
    run_lua_test("unit/test_save_unit.lua");
}

#[test]
fn lua_unit_scene_unit() {
    run_lua_test("unit/test_scene_unit.lua");
}

#[test]
fn lua_unit_serial_unit() {
    run_lua_test("unit/test_serial_unit.lua");
}

#[test]
fn lua_unit_shape_unit() {
    run_lua_test("unit/test_shape_unit.lua");
}

#[test]
fn lua_unit_spine_unit() {
    run_lua_test("unit/test_spine_unit.lua");
}

#[test]
fn lua_unit_sprite_unit() {
    run_lua_test("unit/test_sprite_unit.lua");
}

#[test]
fn lua_unit_terminal_unit() {
    run_lua_test("unit/test_terminal_unit.lua");
}

#[test]
fn lua_unit_thread_unit() {
    run_lua_test("unit/test_thread_unit.lua");
}

#[test]
fn lua_unit_tilemap_unit() {
    run_lua_test("unit/test_tilemap_unit.lua");
}

#[test]
fn lua_unit_timer_unit() {
    run_lua_test("unit/test_timer_unit.lua");
}

#[test]
fn lua_unit_tween_unit() {
    run_lua_test("unit/test_tween_unit.lua");
}

#[test]
fn lua_unit_ui_unit() {
    run_lua_test("unit/test_ui_unit.lua");
}

#[test]
fn lua_unit_window_unit() {
    run_lua_test("unit/test_window_unit.lua");
}

// ── evidence layer ──

#[test]
fn lua_evidence_animation_evidence() {
    run_lua_test("evidence/test_animation_evidence.lua");
}

#[test]
fn lua_evidence_audio_evidence() {
    run_lua_test("evidence/test_audio_evidence.lua");
}

#[test]
fn lua_evidence_bezier_evidence() {
    run_lua_test("evidence/test_bezier_evidence.lua");
}

#[test]
fn lua_evidence_camera_evidence() {
    run_lua_test("evidence/test_camera_evidence.lua");
}

#[test]
fn lua_evidence_canvas_evidence() {
    run_lua_test("evidence/test_canvas_evidence.lua");
}

#[test]
fn lua_evidence_cellular_sand_evidence() {
    run_lua_test("evidence/test_cellular_sand_evidence.lua");
}

#[test]
fn lua_evidence_charts_evidence() {
    run_lua_test("evidence/test_charts_evidence.lua");
}

#[test]
fn lua_evidence_easing_evidence() {
    run_lua_test("evidence/test_easing_evidence.lua");
}

#[test]
fn lua_evidence_effect_evidence() {
    run_lua_test("evidence/test_effect_evidence.lua");
}

#[test]
fn lua_evidence_geometry_evidence() {
    run_lua_test("evidence/test_geometry_evidence.lua");
}

#[test]
fn lua_evidence_graph_evidence() {
    run_lua_test("evidence/test_graph_evidence.lua");
}

#[test]
fn lua_evidence_gui_evidence() {
    run_lua_test("evidence/test_gui_evidence.lua");
}

#[test]
fn lua_evidence_image_evidence() {
    run_lua_test("evidence/test_image_evidence.lua");
}

#[test]
fn lua_evidence_imagedata_evidence() {
    run_lua_test("evidence/test_imagedata_evidence.lua");
}

#[test]
fn lua_evidence_layers_evidence() {
    run_lua_test("evidence/test_layers_evidence.lua");
}

#[test]
fn lua_evidence_light_evidence() {
    run_lua_test("evidence/test_light_evidence.lua");
}

#[test]
fn lua_evidence_math_evidence() {
    run_lua_test("evidence/test_math_evidence.lua");
}

#[test]
fn lua_evidence_minimap_evidence() {
    run_lua_test("evidence/test_minimap_evidence.lua");
}

#[test]
fn lua_evidence_noise_evidence() {
    run_lua_test("evidence/test_noise_evidence.lua");
}

#[test]
fn lua_evidence_particle_evidence() {
    run_lua_test("evidence/test_particle_evidence.lua");
}

#[test]
fn lua_evidence_pathfind_evidence() {
    run_lua_test("evidence/test_pathfind_evidence.lua");
}

#[test]
fn lua_evidence_physics_evidence() {
    run_lua_test("evidence/test_physics_evidence.lua");
}

#[test]
fn lua_evidence_procgen_evidence() {
    run_lua_test("evidence/test_procgen_evidence.lua");
}

#[test]
fn lua_evidence_raycaster_evidence() {
    run_lua_test("evidence/test_raycaster_evidence.lua");
}

#[test]
fn lua_evidence_render_evidence() {
    run_lua_test("evidence/test_render_evidence.lua");
}

#[test]
fn lua_evidence_scene_evidence() {
    run_lua_test("evidence/test_scene_evidence.lua");
}

#[test]
fn lua_evidence_shapes_evidence() {
    run_lua_test("evidence/test_shapes_evidence.lua");
}

#[test]
fn lua_evidence_spine_evidence() {
    run_lua_test("evidence/test_spine_evidence.lua");
}

#[test]
fn lua_evidence_tilemap_evidence() {
    run_lua_test("evidence/test_tilemap_evidence.lua");
}

#[test]
fn lua_evidence_ui_evidence() {
    run_lua_test("evidence/test_ui_evidence.lua");
}

// ── golden layer ──

#[test]
fn lua_golden_ai_golden() {
    run_lua_test("golden/test_ai_golden.lua");
}

#[test]
fn lua_golden_animation_golden() {
    run_lua_test("golden/test_animation_golden.lua");
}

#[test]
fn lua_golden_compute_golden() {
    run_lua_test("golden/test_compute_golden.lua");
}

#[test]
fn lua_golden_data_golden() {
    run_lua_test("golden/test_data_golden.lua");
}

#[test]
fn lua_golden_dataframe_golden() {
    run_lua_test("golden/test_dataframe_golden.lua");
}

#[test]
fn lua_golden_ecs_golden() {
    run_lua_test("golden/test_ecs_golden.lua");
}

#[test]
fn lua_golden_graph_golden() {
    run_lua_test("golden/test_graph_golden.lua");
}

#[test]
fn lua_golden_image_golden() {
    run_lua_test("golden/test_image_golden.lua");
}

#[test]
fn lua_golden_math_golden() {
    run_lua_test("golden/test_math_golden.lua");
}

#[test]
fn lua_golden_minimap_golden() {
    run_lua_test("golden/test_minimap_golden.lua");
}

#[test]
fn lua_golden_pathfind_golden() {
    run_lua_test("golden/test_pathfind_golden.lua");
}

#[test]
fn lua_golden_physics_golden() {
    run_lua_test("golden/test_physics_golden.lua");
}

#[test]
fn lua_golden_procgen_golden() {
    run_lua_test("golden/test_procgen_golden.lua");
}

#[test]
fn lua_golden_raycaster_golden() {
    run_lua_test("golden/test_raycaster_golden.lua");
}

#[test]
fn lua_golden_render_golden() {
    run_lua_test("golden/test_render_golden.lua");
}

#[test]
fn lua_golden_serial_golden() {
    run_lua_test("golden/test_serial_golden.lua");
}

#[test]
fn lua_golden_tilemap_golden() {
    run_lua_test("golden/test_tilemap_golden.lua");
}

// ── stress layer ──

#[test]
fn lua_stress_ai_stress() {
    run_lua_test("stress/test_ai_stress.lua");
}

#[test]
fn lua_stress_animation_stress() {
    run_lua_test("stress/test_animation_stress.lua");
}

#[test]
fn lua_stress_camera_stress() {
    run_lua_test("stress/test_camera_stress.lua");
}

#[test]
fn lua_stress_compute_stress() {
    run_lua_test("stress/test_compute_stress.lua");
}

#[test]
fn lua_stress_data_stress() {
    run_lua_test("stress/test_data_stress.lua");
}

#[test]
fn lua_stress_dataframe_stress() {
    run_lua_test("stress/test_dataframe_stress.lua");
}

#[test]
fn lua_stress_ecs_stress() {
    run_lua_test("stress/test_ecs_stress.lua");
}

#[test]
fn lua_stress_event_stress() {
    run_lua_test("stress/test_event_stress.lua");
}

#[test]
fn lua_stress_filesystem_stress() {
    run_lua_test("stress/test_filesystem_stress.lua");
}

#[test]
fn lua_stress_graph_stress() {
    run_lua_test("stress/test_graph_stress.lua");
}

#[test]
fn lua_stress_image_stress() {
    run_lua_test("stress/test_image_stress.lua");
}

#[test]
fn lua_stress_light_stress() {
    run_lua_test("stress/test_light_stress.lua");
}

#[test]
fn lua_stress_math_stress() {
    run_lua_test("stress/test_math_stress.lua");
}

#[test]
fn lua_stress_particle_stress() {
    run_lua_test("stress/test_particle_stress.lua");
}

#[test]
fn lua_stress_pathfind_stress() {
    run_lua_test("stress/test_pathfind_stress.lua");
}

#[test]
fn lua_stress_patterns_stress() {
    run_lua_test("stress/test_patterns_stress.lua");
}

#[test]
fn lua_stress_physics_stress() {
    run_lua_test("stress/test_physics_stress.lua");
}

#[test]
fn lua_stress_procgen_stress() {
    run_lua_test("stress/test_procgen_stress.lua");
}

#[test]
fn lua_stress_render_stress() {
    run_lua_test("stress/test_render_stress.lua");
}

#[test]
fn lua_stress_save_stress() {
    run_lua_test("stress/test_save_stress.lua");
}

#[test]
fn lua_stress_scene_stress() {
    run_lua_test("stress/test_scene_stress.lua");
}

#[test]
fn lua_stress_serial_stress() {
    run_lua_test("stress/test_serial_stress.lua");
}

#[test]
fn lua_stress_thread_stress() {
    run_lua_test("stress/test_thread_stress.lua");
}

#[test]
fn lua_stress_tilemap_stress() {
    run_lua_test("stress/test_tilemap_stress.lua");
}

#[test]
fn lua_stress_timer_stress() {
    run_lua_test("stress/test_timer_stress.lua");
}

#[test]
fn lua_stress_tween_stress() {
    run_lua_test("stress/test_tween_stress.lua");
}

// ── security layer ──

#[test]
fn lua_security_filesystem() {
    run_lua_test("security/test_filesystem.lua");
}

#[test]
fn lua_security_network() {
    run_lua_test("security/test_network.lua");
}

#[test]
fn lua_security_render() {
    run_lua_test("security/test_render.lua");
}

#[test]
fn lua_security_runtime() {
    run_lua_test("security/test_runtime.lua");
}

#[test]
fn lua_security_save() {
    run_lua_test("security/test_save.lua");
}

// ── integration layer ──

#[test]
fn lua_integration_animation_tween() {
    run_lua_test("integration/test_animation_tween.lua");
}

#[test]
fn lua_integration_audio_scene() {
    run_lua_test("integration/test_audio_scene.lua");
}

#[test]
fn lua_integration_automation_event() {
    run_lua_test("integration/test_automation_event.lua");
}

#[test]
fn lua_integration_camera_tilemap_scroll() {
    run_lua_test("integration/test_camera_tilemap_scroll.lua");
}

#[test]
fn lua_integration_cardgame_tween_integration() {
    run_lua_test("integration/test_cardgame_tween_integration.lua");
}

#[test]
fn lua_integration_combat_physics_integration() {
    run_lua_test("integration/test_combat_physics_integration.lua");
}

#[test]
fn lua_integration_dialog_event_integration() {
    run_lua_test("integration/test_dialog_event_integration.lua");
}

#[test]
fn lua_integration_effect_camera() {
    run_lua_test("integration/test_effect_camera.lua");
}

#[test]
fn lua_integration_i18n_dialog() {
    run_lua_test("integration/test_i18n_dialog.lua");
}

#[test]
fn lua_integration_image_dataframe() {
    run_lua_test("integration/test_image_dataframe.lua");
}

#[test]
fn lua_integration_input_ui() {
    run_lua_test("integration/test_input_ui.lua");
}

#[test]
fn lua_integration_inventory_save_integration() {
    run_lua_test("integration/test_inventory_save_integration.lua");
}

#[test]
fn lua_integration_minimap_pathfind() {
    run_lua_test("integration/test_minimap_pathfind.lua");
}

#[test]
fn lua_integration_network_save() {
    run_lua_test("integration/test_network_save.lua");
}

#[test]
fn lua_integration_particle_render() {
    run_lua_test("integration/test_particle_render.lua");
}

#[test]
fn lua_integration_quest_time_integration() {
    run_lua_test("integration/test_quest_time_integration.lua");
}

#[test]
fn lua_integration_serial_filesystem() {
    run_lua_test("integration/test_serial_filesystem.lua");
}

#[test]
fn lua_integration_terminal_input() {
    run_lua_test("integration/test_terminal_input.lua");
}

#[test]
fn lua_integration_timer_event() {
    run_lua_test("integration/test_timer_event.lua");
}

// ── library layer ──

#[test]
fn lua_library_battle() {
    run_lua_test("library/test_library_battle.lua");
}

#[test]
fn lua_library_cardgame() {
    run_lua_test("library/test_library_cardgame.lua");
}

#[test]
fn lua_library_cinematic() {
    run_lua_test("library/test_library_cinematic.lua");
}

#[test]
fn lua_library_combat() {
    run_lua_test("library/test_library_combat.lua");
}

#[test]
fn lua_library_crafting() {
    run_lua_test("library/test_library_crafting.lua");
}

#[test]
fn lua_library_dialog() {
    run_lua_test("library/test_library_dialog.lua");
}

#[test]
fn lua_library_doll() {
    run_lua_test("library/test_library_doll.lua");
}

#[test]
fn lua_library_economy() {
    run_lua_test("library/test_library_economy.lua");
}

#[test]
fn lua_library_inventory() {
    run_lua_test("library/test_library_inventory.lua");
}

#[test]
fn lua_library_item() {
    run_lua_test("library/test_library_item.lua");
}

#[test]
fn lua_library_lobby() {
    run_lua_test("library/test_library_lobby.lua");
}

#[test]
fn lua_library_loot() {
    run_lua_test("library/test_library_loot.lua");
}

#[test]
fn lua_library_narrative() {
    run_lua_test("library/test_library_narrative.lua");
}

#[test]
fn lua_library_netstate() {
    run_lua_test("library/test_library_netstate.lua");
}

#[test]
fn lua_library_patterns() {
    run_lua_test("library/test_library_patterns.lua");
}

#[test]
fn lua_library_province_map() {
    run_lua_test("library/test_library_province_map.lua");
}

#[test]
fn lua_library_quest() {
    run_lua_test("library/test_library_quest.lua");
}

#[test]
fn lua_library_rhythm() {
    run_lua_test("library/test_library_rhythm.lua");
}

#[test]
fn lua_library_roguelike() {
    run_lua_test("library/test_library_roguelike.lua");
}

#[test]
fn lua_library_rpc() {
    run_lua_test("library/test_library_rpc.lua");
}

#[test]
fn lua_library_stats() {
    run_lua_test("library/test_library_stats.lua");
}

#[test]
fn lua_library_scheduler() {
    run_lua_test("library/test_library_scheduler.lua");
}

#[test]
fn lua_unit_engine_unit() {
    run_lua_test("unit/test_engine_unit.lua");
}

#[test]
fn lua_unit_system_unit() {
    run_lua_test("unit/test_system_unit.lua");
}

#[test]
fn lua_unit_collision_unit() {
    run_lua_test("unit/test_collision_unit.lua");
}
