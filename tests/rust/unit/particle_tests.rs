//! Integration tests for the `luna.particles.*` Lua API and particle system.

use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

use lurek2d::engine::config::Config;
use lurek2d::graphics::renderer::{DrawCommand, ParticleRenderShape};
use lurek2d::lua_api::{create_lua_vm, SharedState};
use lurek2d::particle::{
    interpolate_colors, interpolate_sizes, AreaDistribution, EmissionShape, InsertMode,
    ParticleConfig, ParticleShape, ParticleSystem, RelativeMode,
};

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

fn assert_lua_error_contains(result: mlua::Result<()>, expected: &str) {
    let err = result.expect_err("expected Lua script to fail");
    let message = err.to_string();
    assert!(
        message.contains(expected),
        "expected Lua error to contain '{expected}', got '{message}'"
    );
}

// ── Existing tests (updated for new API) ────────────────────────────────

#[test]
fn test_phase01_released_particle_handle_reuse_reports_invalid_system() {
    let (_state, lua) = make_vm();
    let result = lua
        .load(
            r#"
            local released = luna.particles.newSystem({ emissionRate = 10 })
            assert(type(released) == "userdata")
            assert(luna.particles.release(released) == true)

            local replacement = luna.particles.newSystem({ emissionRate = 20 })
            assert(type(replacement) == "userdata")

            luna.particles.getCount(released)
            "#,
        )
        .exec();

    assert_lua_error_contains(result, "invalid or already-released particle system handle");
}

#[test]
fn test_phase01_released_particle_long_tail_accessors_report_invalid_system() {
    let cases = [
        (
            "lurek.particles.getEmitterLifetime(released)",
            "lurek.particles.getEmitterLifetime: invalid or already-released particle system handle",
        ),
        (
            "lurek.particles.getDirection(released)",
            "lurek.particles.getDirection: invalid or already-released particle system handle",
        ),
        (
            "lurek.particles.getSpread(released)",
            "lurek.particles.getSpread: invalid or already-released particle system handle",
        ),
        (
            "lurek.particles.getLinearAcceleration(released)",
            "lurek.particles.getLinearAcceleration: invalid or already-released particle system handle",
        ),
        (
            "lurek.particles.getRadialAcceleration(released)",
            "lurek.particles.getRadialAcceleration: invalid or already-released particle system handle",
        ),
        (
            "lurek.particles.getTangentialAcceleration(released)",
            "lurek.particles.getTangentialAcceleration: invalid or already-released particle system handle",
        ),
        (
            "lurek.particles.getSizes(released)",
            "lurek.particles.getSizes: invalid or already-released particle system handle",
        ),
        (
            "lurek.particles.getColors(released)",
            "lurek.particles.getColors: invalid or already-released particle system handle",
        ),
        (
            "lurek.particles.getInsertMode(released)",
            "lurek.particles.getInsertMode: invalid or already-released particle system handle",
        ),
        (
            "lurek.particles.getBufferSize(released)",
            "lurek.particles.getBufferSize: invalid or already-released particle system handle",
        ),
    ];

    for (expression, expected_error) in cases {
        let (_state, lua) = make_vm();
        let script = format!(
            r#"
            local released = luna.particles.newSystem({{ emissionRate = 10 }})
            assert(type(released) == "userdata")
            assert(luna.particles.release(released) == true)

            {expression}
            "#,
        );
        let result = lua.load(&script).exec();
        assert_lua_error_contains(result, expected_error);
    }
}

#[test]
fn test_phase01_released_particle_long_tail_mutators_report_invalid_system() {
    let cases = [
        (
            "lurek.particles.setEmitterLifetime(released, 5.0)",
            "lurek.particles.setEmitterLifetime: invalid or already-released particle system handle",
        ),
        (
            "lurek.particles.setDirection(released, 1.25)",
            "lurek.particles.setDirection: invalid or already-released particle system handle",
        ),
        (
            "lurek.particles.setSizes(released, 1, 2)",
            "lurek.particles.setSizes: invalid or already-released particle system handle",
        ),
    ];

    for (expression, expected_error) in cases {
        let (_state, lua) = make_vm();
        let script = format!(
            r#"
            local released = luna.particles.newSystem({{ emissionRate = 10 }})
            assert(type(released) == "userdata")
            assert(luna.particles.release(released) == true)

            {expression}
            "#,
        );
        let result = lua.load(&script).exec();
        assert_lua_error_contains(result, expected_error);
    }
}

#[test]
fn test_particle_new_system_default() {
    let (state, lua) = make_vm();
    lua.load("local id = luna.particles.newSystem(); assert(type(id) == 'userdata')")
        .exec()
        .unwrap();
    let st = state.borrow();
    assert_eq!(st.particle_systems.len(), 1);
    assert!(st.particle_systems.values().next().unwrap().is_active());
}

#[test]
fn test_particle_new_system_with_config() {
    let (state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem({
            maxParticles = 100,
            emissionRate = 50,
            lifetimeMin = 0.5,
            lifetimeMax = 1.5,
            speedMin = 10,
            speedMax = 200,
            gravityY = 100,
            sizeStart = 8,
            sizeEnd = 2,
        })
        assert(type(id) == 'userdata')
        "#,
    )
    .exec()
    .unwrap();
    let st = state.borrow();
    let ps = st.particle_systems.values().next().unwrap();
    assert_eq!(ps.config.max_particles, 100);
    assert!((ps.config.emission_rate - 50.0).abs() < 1e-5);
    assert!((ps.config.gravity_y - 100.0).abs() < 1e-5);
    // sizeStart/sizeEnd backward compat -> sizes vec
    assert_eq!(ps.config.sizes.len(), 2);
    assert!((ps.config.sizes[0] - 8.0).abs() < 1e-5);
    assert!((ps.config.sizes[1] - 2.0).abs() < 1e-5);
}

#[test]
fn test_particle_update_and_count() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem({ emissionRate = 100 })
        luna.particles.update(id, 1.0)
        local count = luna.particles.getCount(id)
        assert(count > 0, "Expected particles after update, got " .. tostring(count))
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_particle_stop_and_start() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem({ emissionRate = 1000, lifetimeMin = 10, lifetimeMax = 10 })
        luna.particles.update(id, 0.1)
        local c1 = luna.particles.getCount(id)
        assert(c1 > 0)
        luna.particles.stop(id)
        local frozen = luna.particles.getCount(id)
        luna.particles.update(id, 0.1)
        local c2 = luna.particles.getCount(id)
        assert(c2 <= frozen, "Expected no new particles after stop")
        luna.particles.start(id)
        luna.particles.update(id, 0.1)
        local c3 = luna.particles.getCount(id)
        assert(c3 >= c2, "Expected new particles after start")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_particle_reset() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem({ emissionRate = 100 })
        luna.particles.update(id, 1.0)
        assert(luna.particles.getCount(id) > 0)
        luna.particles.reset(id)
        assert(luna.particles.getCount(id) == 0)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_particle_set_position() {
    let (state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem()
        luna.particles.setPosition(id, 100, 200)
        "#,
    )
    .exec()
    .unwrap();
    let st = state.borrow();
    let ps = st.particle_systems.values().next().unwrap();
    assert!((ps.emitter_x - 100.0).abs() < 1e-5);
    assert!((ps.emitter_y - 200.0).abs() < 1e-5);
}

#[test]
fn test_particle_set_emission_rate() {
    let (state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem({ emissionRate = 10 })
        luna.particles.setEmissionRate(id, 500)
        "#,
    )
    .exec()
    .unwrap();
    let st = state.borrow();
    assert!(
        (st.particle_systems
            .values()
            .next()
            .unwrap()
            .config
            .emission_rate
            - 500.0)
            .abs()
            < 1e-5
    );
}

#[test]
fn test_particle_draw_generates_commands() {
    let (state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem({ emissionRate = 100 })
        luna.particles.update(id, 1.0)
        luna.particles.draw(id)
        "#,
    )
    .exec()
    .unwrap();
    let st = state.borrow();
    // draw_commands batches all particles into a single DrawParticleSystem command
    assert_eq!(
        st.draw_commands.len(),
        1,
        "expected one DrawParticleSystem command"
    );
    match &st.draw_commands[0] {
        DrawCommand::DrawParticleSystem { particles } => {
            assert!(!particles.is_empty(), "particles list should be non-empty");
        }
        other => panic!("expected DrawParticleSystem, got {:?}", other),
    }
}

#[test]
fn test_particle_multiple_systems() {
    let (state, lua) = make_vm();
    lua.load(
        r#"
        local id0 = luna.particles.newSystem({ emissionRate = 10 })
        local id1 = luna.particles.newSystem({ emissionRate = 20 })
        assert(type(id0) == "userdata", "first system should return userdata")
        assert(type(id1) == "userdata", "second system should return userdata")
        assert(id0 ~= id1, "different systems should have different ids")
        "#,
    )
    .exec()
    .unwrap();
    assert_eq!(state.borrow().particle_systems.len(), 2);
}

// ── Phase 12: New Rust-level tests ──────────────────────────────────────

#[test]
fn test_multi_stop_size_interpolation() {
    // 3-stop: [10, 20, 5]
    let sizes = [10.0, 20.0, 5.0];
    assert!((interpolate_sizes(&sizes, 0.0, 0.0) - 10.0).abs() < 1e-5);
    assert!((interpolate_sizes(&sizes, 0.5, 0.0) - 20.0).abs() < 1e-5);
    assert!((interpolate_sizes(&sizes, 1.0, 0.0) - 5.0).abs() < 1e-5);
    // Midpoints
    assert!((interpolate_sizes(&sizes, 0.25, 0.0) - 15.0).abs() < 1e-5);
    assert!((interpolate_sizes(&sizes, 0.75, 0.0) - 12.5).abs() < 1e-5);
}

#[test]
fn test_multi_stop_color_interpolation() {
    let colors = [
        [1.0, 0.0, 0.0, 1.0], // red
        [0.0, 1.0, 0.0, 1.0], // green
        [0.0, 0.0, 1.0, 1.0], // blue
    ];
    let c0 = interpolate_colors(&colors, 0.0);
    assert!((c0[0] - 1.0).abs() < 1e-5); // red
    let c_mid = interpolate_colors(&colors, 0.5);
    assert!((c_mid[1] - 1.0).abs() < 1e-5); // green
    let c1 = interpolate_colors(&colors, 1.0);
    assert!((c1[2] - 1.0).abs() < 1e-5); // blue
                                         // Quarter: between red and green
    let c_q = interpolate_colors(&colors, 0.25);
    assert!((c_q[0] - 0.5).abs() < 1e-5);
    assert!((c_q[1] - 0.5).abs() < 1e-5);
}

#[test]
fn test_burst_emit() {
    let mut cfg = ParticleConfig::default();
    cfg.max_particles = 1000;
    cfg.lifetime_min = 10.0;
    cfg.lifetime_max = 10.0;
    let mut sys = ParticleSystem::new(cfg);
    sys.emit(50);
    assert_eq!(sys.count(), 50);
}

#[test]
fn test_burst_emit_respects_max() {
    let mut cfg = ParticleConfig::default();
    cfg.max_particles = 10;
    cfg.lifetime_min = 10.0;
    cfg.lifetime_max = 10.0;
    let mut sys = ParticleSystem::new(cfg);
    sys.emit(100);
    assert_eq!(sys.count(), 10);
}

#[test]
fn test_emitter_lifetime_auto_stop() {
    let mut cfg = ParticleConfig::default();
    cfg.emitter_lifetime = 0.5;
    cfg.emission_rate = 100.0;
    cfg.lifetime_min = 10.0;
    cfg.lifetime_max = 10.0;
    let mut sys = ParticleSystem::new(cfg);
    assert!(sys.is_active());
    // Update past the emitter lifetime
    sys.update(0.6);
    assert!(sys.is_stopped());
    // Should not emit more after stopping
    let count_after_stop = sys.count();
    sys.update(1.0);
    assert!(sys.count() <= count_after_stop);
}

#[test]
fn test_pause_freezes_particles() {
    let mut cfg = ParticleConfig::default();
    cfg.emission_rate = 100.0;
    cfg.lifetime_min = 10.0;
    cfg.lifetime_max = 10.0;
    cfg.speed_min = 100.0;
    cfg.speed_max = 100.0;
    let mut sys = ParticleSystem::new(cfg);
    sys.update(0.1); // emit some
    let count_before = sys.count();
    let positions: Vec<(f32, f32)> = sys.particles.iter().map(|p| (p.x, p.y)).collect();

    sys.pause();
    sys.update(1.0); // should do nothing

    assert_eq!(sys.count(), count_before); // same count
    for (i, p) in sys.particles.iter().enumerate() {
        assert!((p.x - positions[i].0).abs() < 1e-5, "expected frozen x");
        assert!((p.y - positions[i].1).abs() < 1e-5, "expected frozen y");
    }
}

#[test]
fn test_clone_copies_config_not_particles() {
    let mut cfg = ParticleConfig::default();
    cfg.emission_rate = 100.0;
    cfg.lifetime_min = 10.0;
    cfg.lifetime_max = 10.0;
    let mut sys = ParticleSystem::new(cfg);
    sys.update(1.0);
    assert!(sys.count() > 0);

    let cloned = sys.clone_config();
    assert_eq!(cloned.count(), 0);
    assert!((cloned.config.emission_rate - 100.0).abs() < 1e-5);
}

#[test]
fn test_area_emission_ellipse() {
    let mut cfg = ParticleConfig::default();
    cfg.area_distribution = AreaDistribution::Ellipse;
    cfg.area_width = 100.0;
    cfg.area_height = 50.0;
    cfg.emission_rate = 1000.0;
    cfg.speed_min = 0.0;
    cfg.speed_max = 0.0;
    cfg.lifetime_min = 100.0;
    cfg.lifetime_max = 100.0;
    let mut sys = ParticleSystem::new(cfg);
    sys.emit(200);

    for p in &sys.particles {
        let nx = p.x / 50.0; // half-width
        let ny = p.y / 25.0; // half-height
        let d = nx * nx + ny * ny;
        assert!(
            d <= 1.0 + 1e-3,
            "particle ({}, {}) outside ellipse: d={}",
            p.x,
            p.y,
            d
        );
    }
}

#[test]
fn test_radial_acceleration() {
    let mut cfg = ParticleConfig::default();
    cfg.radial_accel_min = 100.0;
    cfg.radial_accel_max = 100.0;
    cfg.emission_rate = 0.0; // manual emit only
    cfg.speed_min = 50.0;
    cfg.speed_max = 50.0;
    cfg.direction = 0.0; // rightward
    cfg.spread = 0.0;
    cfg.gravity_x = 0.0;
    cfg.gravity_y = 0.0;
    cfg.lifetime_min = 10.0;
    cfg.lifetime_max = 10.0;
    let mut sys = ParticleSystem::new(cfg);
    sys.emit(1);

    // First small step to move particle away from the origin (dist must be > 0
    // for radial/tangential accel to apply).
    sys.update(0.1);
    let speed_after_move = (sys.particles[0].vx.powi(2) + sys.particles[0].vy.powi(2)).sqrt();

    // Now a larger step where radial accel can act
    sys.update(1.0);
    let final_speed = (sys.particles[0].vx.powi(2) + sys.particles[0].vy.powi(2)).sqrt();

    // Radial accel should increase speed away from origin
    assert!(
        final_speed > speed_after_move,
        "expected speed increase from radial accel: {} > {}",
        final_speed,
        speed_after_move
    );
}

#[test]
fn test_tangential_acceleration() {
    let mut cfg = ParticleConfig::default();
    cfg.tangential_accel_min = 200.0;
    cfg.tangential_accel_max = 200.0;
    cfg.emission_rate = 0.0;
    cfg.speed_min = 50.0;
    cfg.speed_max = 50.0;
    cfg.direction = 0.0; // rightward
    cfg.spread = 0.0;
    cfg.gravity_x = 0.0;
    cfg.gravity_y = 0.0;
    cfg.lifetime_min = 10.0;
    cfg.lifetime_max = 10.0;
    let mut sys = ParticleSystem::new(cfg);
    sys.emit(1);

    // First small step to move particle away from origin
    sys.update(0.1);
    let vy_after_move = sys.particles[0].vy;

    // Now tangential accel can act (perpendicular to radial direction)
    sys.update(0.5);
    let final_vy = sys.particles[0].vy;

    assert!(
        (final_vy - vy_after_move).abs() > 1.0,
        "expected vy change from tangential accel: {} -> {}",
        vy_after_move,
        final_vy
    );
}

#[test]
fn test_linear_damping() {
    let mut cfg = ParticleConfig::default();
    cfg.linear_damping_min = 5.0;
    cfg.linear_damping_max = 5.0;
    cfg.emission_rate = 0.0;
    cfg.speed_min = 100.0;
    cfg.speed_max = 100.0;
    cfg.direction = 0.0;
    cfg.spread = 0.0;
    cfg.gravity_x = 0.0;
    cfg.gravity_y = 0.0;
    cfg.lifetime_min = 10.0;
    cfg.lifetime_max = 10.0;
    let mut sys = ParticleSystem::new(cfg);
    sys.emit(1);

    let initial_speed = (sys.particles[0].vx.powi(2) + sys.particles[0].vy.powi(2)).sqrt();
    sys.update(1.0);
    let final_speed = (sys.particles[0].vx.powi(2) + sys.particles[0].vy.powi(2)).sqrt();

    assert!(
        final_speed < initial_speed,
        "expected velocity decrease from damping: {} < {}",
        final_speed,
        initial_speed
    );
}

#[test]
fn test_relative_rotation() {
    let mut cfg = ParticleConfig::default();
    cfg.relative_rotation = true;
    cfg.emission_rate = 0.0;
    cfg.speed_min = 100.0;
    cfg.speed_max = 100.0;
    cfg.direction = std::f32::consts::FRAC_PI_4; // 45 degrees
    cfg.spread = 0.0;
    cfg.gravity_x = 0.0;
    cfg.gravity_y = 0.0;
    cfg.lifetime_min = 10.0;
    cfg.lifetime_max = 10.0;
    let mut sys = ParticleSystem::new(cfg);
    sys.emit(1);
    sys.update(0.1);

    let expected_angle = sys.particles[0].vy.atan2(sys.particles[0].vx);
    assert!(
        (sys.particles[0].rotation - expected_angle).abs() < 1e-5,
        "rotation {} should match velocity direction {}",
        sys.particles[0].rotation,
        expected_angle
    );
}

#[test]
fn test_insert_mode_top() {
    let mut cfg = ParticleConfig::default();
    cfg.insert_mode = InsertMode::Top;
    cfg.emission_rate = 0.0;
    cfg.lifetime_min = 10.0;
    cfg.lifetime_max = 10.0;
    let mut sys = ParticleSystem::new(cfg);
    sys.emit(3);
    assert_eq!(sys.count(), 3);
    // Top insert: last emitted should be at the end
    // Verify they're all present
    assert!(!sys.is_empty());
}

#[test]
fn test_emitter_state_transitions() {
    let mut sys = ParticleSystem::new(ParticleConfig::default());
    assert!(sys.is_active());
    assert!(!sys.is_paused());
    assert!(!sys.is_stopped());

    sys.pause();
    assert!(sys.is_paused());
    assert!(!sys.is_active());

    sys.resume();
    assert!(sys.is_active());

    sys.stop();
    assert!(sys.is_stopped());

    sys.start();
    assert!(sys.is_active());
}

#[test]
fn test_move_to_updates_position() {
    let mut sys = ParticleSystem::new(ParticleConfig::default());
    assert!((sys.emitter_x - 0.0).abs() < 1e-5);
    assert!((sys.emitter_y - 0.0).abs() < 1e-5);
    sys.move_to(100.0, 200.0);
    assert!((sys.emitter_x - 100.0).abs() < 1e-5);
    assert!((sys.emitter_y - 200.0).abs() < 1e-5);
    assert!((sys.prev_emitter_x - 0.0).abs() < 1e-5);
    assert!((sys.prev_emitter_y - 0.0).abs() < 1e-5);
}

#[test]
fn test_backward_compat_size_start_end() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem({
            sizeStart = 10,
            sizeEnd = 2,
        })
        -- Sizes should be populated from sizeStart/sizeEnd
        local sizes = luna.particles.getSizes(id)
        assert(sizes ~= nil, "sizes should not be nil")
        assert(math.abs(sizes[1] - 10) < 0.001, "first size should be 10, got " .. tostring(sizes[1]))
        assert(math.abs(sizes[2] - 2) < 0.001, "second size should be 2, got " .. tostring(sizes[2]))
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_backward_compat_color_start_end() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem({
            colorStart = {1, 0, 0, 1},
            colorEnd = {0, 0, 1, 0.5},
        })
        local colors = luna.particles.getColors(id)
        assert(colors ~= nil)
        assert(math.abs(colors[1][1] - 1) < 0.001, "start red should be 1")
        assert(math.abs(colors[1][2] - 0) < 0.001, "start green should be 0")
        assert(math.abs(colors[2][3] - 1) < 0.001, "end blue should be 1")
        assert(math.abs(colors[2][4] - 0.5) < 0.001, "end alpha should be 0.5")
        "#,
    )
    .exec()
    .unwrap();
}

// ── Phase 12: Lua API tests for new functions ───────────────────────────

#[test]
fn test_lua_pause_resume() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem({ emissionRate = 100 })
        assert(luna.particles.isActive(id))
        luna.particles.pause(id)
        assert(luna.particles.isPaused(id))
        assert(not luna.particles.isActive(id))
        luna.particles.start(id)
        assert(luna.particles.isActive(id))
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_emit_burst() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem({
            maxParticles = 1000,
            emissionRate = 0,
            lifetimeMin = 10,
            lifetimeMax = 10,
        })
        luna.particles.emit(id, 50)
        assert(luna.particles.getCount(id) == 50, "Expected 50 particles, got " .. luna.particles.getCount(id))
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_clone_system() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem({
            emissionRate = 100,
            lifetimeMin = 10,
            lifetimeMax = 10,
        })
        luna.particles.update(id, 0.5)
        assert(luna.particles.getCount(id) > 0)
        local cloned = luna.particles.clone(id)
        assert(cloned ~= id)
        assert(luna.particles.getCount(cloned) == 0, "Cloned system should have 0 particles")
        assert(luna.particles.getEmissionRate(cloned) == 100, "Cloned should have same emission rate")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_get_set_position() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem()
        luna.particles.setPosition(id, 42, 84)
        local x, y = luna.particles.getPosition(id)
        assert(math.abs(x - 42) < 0.001)
        assert(math.abs(y - 84) < 0.001)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_move_to() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem()
        luna.particles.moveTo(id, 50, 75)
        local x, y = luna.particles.getPosition(id)
        assert(math.abs(x - 50) < 0.001)
        assert(math.abs(y - 75) < 0.001)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_is_empty_is_full() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem({
            maxParticles = 5,
            emissionRate = 0,
            lifetimeMin = 10,
            lifetimeMax = 10,
        })
        assert(luna.particles.isEmpty(id), "should start empty")
        assert(not luna.particles.isFull(id))
        luna.particles.emit(id, 5)
        assert(not luna.particles.isEmpty(id))
        assert(luna.particles.isFull(id), "should be full at max")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_lifetime_getters_setters() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem()
        luna.particles.setParticleLifetime(id, 0.5, 3.0)
        local min, max = luna.particles.getParticleLifetime(id)
        assert(math.abs(min - 0.5) < 0.001)
        assert(math.abs(max - 3.0) < 0.001)
        luna.particles.setEmitterLifetime(id, 5.0)
        assert(math.abs(luna.particles.getEmitterLifetime(id) - 5.0) < 0.001)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_speed_direction_spread() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem()
        luna.particles.setSpeed(id, 10, 200)
        local smin, smax = luna.particles.getSpeed(id)
        assert(math.abs(smin - 10) < 0.001)
        assert(math.abs(smax - 200) < 0.001)
        luna.particles.setDirection(id, 1.5)
        assert(math.abs(luna.particles.getDirection(id) - 1.5) < 0.001)
        luna.particles.setSpread(id, 0.5)
        assert(math.abs(luna.particles.getSpread(id) - 0.5) < 0.001)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_acceleration_setters() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem()
        luna.particles.setLinearAcceleration(id, -10, -20, 10, 20)
        local xmin, ymin, xmax, ymax = luna.particles.getLinearAcceleration(id)
        assert(math.abs(xmin - (-10)) < 0.001)
        assert(math.abs(ymax - 20) < 0.001)
        luna.particles.setRadialAcceleration(id, 5, 50)
        local rmin, rmax = luna.particles.getRadialAcceleration(id)
        assert(math.abs(rmin - 5) < 0.001)
        assert(math.abs(rmax - 50) < 0.001)
        luna.particles.setTangentialAcceleration(id, -30, 30)
        local tmin, tmax = luna.particles.getTangentialAcceleration(id)
        assert(math.abs(tmin - (-30)) < 0.001)
        assert(math.abs(tmax - 30) < 0.001)
        luna.particles.setLinearDamping(id, 1, 3)
        local dmin, dmax = luna.particles.getLinearDamping(id)
        assert(math.abs(dmin - 1) < 0.001)
        assert(math.abs(dmax - 3) < 0.001)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_sizes_api() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem()
        luna.particles.setSizes(id, 1, 5, 10, 2)
        local sizes = luna.particles.getSizes(id)
        assert(#sizes == 4)
        assert(math.abs(sizes[1] - 1) < 0.001)
        assert(math.abs(sizes[4] - 2) < 0.001)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_colors_api() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem()
        luna.particles.setColors(id, {1, 0, 0, 1}, {0, 1, 0, 0.5}, {0, 0, 1, 0})
        local colors = luna.particles.getColors(id)
        assert(#colors == 3)
        assert(math.abs(colors[1][1] - 1) < 0.001, "first color red")
        assert(math.abs(colors[2][2] - 1) < 0.001, "second color green")
        assert(math.abs(colors[3][3] - 1) < 0.001, "third color blue")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_rotation_spin_variation() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem()
        luna.particles.setRotation(id, 0, 6.28)
        local rmin, rmax = luna.particles.getRotation(id)
        assert(math.abs(rmin - 0) < 0.001)
        assert(math.abs(rmax - 6.28) < 0.001)
        luna.particles.setSpin(id, -5, 5)
        local smin, smax = luna.particles.getSpin(id)
        assert(math.abs(smin - (-5)) < 0.001)
        assert(math.abs(smax - 5) < 0.001)
        luna.particles.setSpinVariation(id, 0.5)
        assert(math.abs(luna.particles.getSpinVariation(id) - 0.5) < 0.001)
        luna.particles.setSizeVariation(id, 0.8)
        assert(math.abs(luna.particles.getSizeVariation(id) - 0.8) < 0.001)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_relative_rotation_api() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem()
        assert(not luna.particles.hasRelativeRotation(id))
        luna.particles.setRelativeRotation(id, true)
        assert(luna.particles.hasRelativeRotation(id))
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_emission_area() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem()
        luna.particles.setEmissionArea(id, "ellipse", 100, 50, 0.5, true)
        local dist, w, h, angle, rel = luna.particles.getEmissionArea(id)
        assert(dist == "ellipse")
        assert(math.abs(w - 100) < 0.001)
        assert(math.abs(h - 50) < 0.001)
        assert(math.abs(angle - 0.5) < 0.001)
        assert(rel == true)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_insert_mode() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem()
        assert(luna.particles.getInsertMode(id) == "top")
        luna.particles.setInsertMode(id, "bottom")
        assert(luna.particles.getInsertMode(id) == "bottom")
        luna.particles.setInsertMode(id, "random")
        assert(luna.particles.getInsertMode(id) == "random")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_buffer_size() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem({ maxParticles = 100 })
        assert(luna.particles.getBufferSize(id) == 100)
        luna.particles.setBufferSize(id, 50)
        assert(luna.particles.getBufferSize(id) == 50)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_offset() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem()
        luna.particles.setOffset(id, 16, 16)
        local ox, oy = luna.particles.getOffset(id)
        assert(math.abs(ox - 16) < 0.001)
        assert(math.abs(oy - 16) < 0.001)
        "#,
    )
    .exec()
    .unwrap();
}

// ── Phase 30 — Particle System Extended ────────────────────────────────

#[test]
fn test_lua_gravity_api() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem({ gravityX = 10, gravityY = 20 })
        local gx, gy = luna.particles.getGravity(id)
        assert(math.abs(gx - 10) < 0.001)
        assert(math.abs(gy - 20) < 0.001)
        luna.particles.setGravity(id, -5, 100)
        gx, gy = luna.particles.getGravity(id)
        assert(math.abs(gx - (-5)) < 0.001)
        assert(math.abs(gy - 100) < 0.001)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_alphas_api() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem()
        luna.particles.setAlphas(id, 1.0, 0.5, 0.0)
        local alphas = luna.particles.getAlphas(id)
        assert(#alphas == 3)
        assert(math.abs(alphas[1] - 1.0) < 0.001)
        assert(math.abs(alphas[2] - 0.5) < 0.001)
        assert(math.abs(alphas[3] - 0.0) < 0.001)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_alphas_config() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem({
            alphaKeyframes = {1.0, 0.8, 0.3, 0.0}
        })
        local alphas = luna.particles.getAlphas(id)
        assert(#alphas == 4)
        assert(math.abs(alphas[1] - 1.0) < 0.001)
        assert(math.abs(alphas[4] - 0.0) < 0.001)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_emission_shape_api() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem()
        -- Default is point
        local shape = luna.particles.getEmissionShape(id)
        assert(shape.type == "point")

        -- Set to circle
        luna.particles.setEmissionShape(id, "circle", { radius = 25.0, fill = false })
        shape = luna.particles.getEmissionShape(id)
        assert(shape.type == "circle")
        assert(math.abs(shape.radius - 25.0) < 0.001)
        assert(shape.fill == false)

        -- Set to rectangle
        luna.particles.setEmissionShape(id, "rectangle", { width = 100, height = 50 })
        shape = luna.particles.getEmissionShape(id)
        assert(shape.type == "rectangle")
        assert(math.abs(shape.width - 100) < 0.001)
        assert(math.abs(shape.height - 50) < 0.001)

        -- Set to ring
        luna.particles.setEmissionShape(id, "ring", { innerRadius = 5, outerRadius = 15 })
        shape = luna.particles.getEmissionShape(id)
        assert(shape.type == "ring")
        assert(math.abs(shape.innerRadius - 5) < 0.001)
        assert(math.abs(shape.outerRadius - 15) < 0.001)

        -- Set back to point
        luna.particles.setEmissionShape(id, "point")
        shape = luna.particles.getEmissionShape(id)
        assert(shape.type == "point")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_emission_shape_config() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem({
            emissionShape = "circle",
            emissionShapeRadius = 30.0,
            emissionShapeFill = true
        })
        local shape = luna.particles.getEmissionShape(id)
        assert(shape.type == "circle")
        assert(math.abs(shape.radius - 30.0) < 0.001)
        assert(shape.fill == true)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_relative_mode_api() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem()
        -- Default is detached
        assert(luna.particles.getRelativeMode(id) == "detached")

        luna.particles.setRelativeMode(id, "attached")
        assert(luna.particles.getRelativeMode(id) == "attached")

        luna.particles.setRelativeMode(id, "detached")
        assert(luna.particles.getRelativeMode(id) == "detached")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_relative_mode_config() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local id = luna.particles.newSystem({
            relativeMode = "attached"
        })
        assert(luna.particles.getRelativeMode(id) == "attached")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_oo_gravity_api() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local ps = luna.particles.newSystem()
        ps:setGravity(0, 9.8)
        local gx, gy = ps:getGravity()
        assert(math.abs(gx) < 0.001)
        assert(math.abs(gy - 9.8) < 0.001)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_oo_alphas_api() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local ps = luna.particles.newSystem()
        ps:setAlphas(1.0, 0.0)
        local alphas = ps:getAlphas()
        assert(#alphas == 2)
        assert(math.abs(alphas[1] - 1.0) < 0.001)
        assert(math.abs(alphas[2]) < 0.001)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_oo_emission_shape_api() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local ps = luna.particles.newSystem()
        ps:setEmissionShape("line", { length = 40, angle = 1.57 })
        local shape = ps:getEmissionShape()
        assert(shape.type == "line")
        assert(math.abs(shape.length - 40) < 0.001)
        assert(math.abs(shape.angle - 1.57) < 0.001)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_oo_relative_mode_api() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local ps = luna.particles.newSystem()
        ps:setRelativeMode("attached")
        assert(ps:getRelativeMode() == "attached")
        ps:setRelativeMode("detached")
        assert(ps:getRelativeMode() == "detached")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_oo_clone_method() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local ps = luna.particles.newSystem({
            emissionRate = 42,
            gravityX = 5,
            gravityY = 10
        })
        ps:setAlphas(1.0, 0.5, 0.0)
        ps:setEmissionShape("circle", { radius = 20 })
        ps:setRelativeMode("attached")

        local cloned = ps:clone()
        -- Clone is a separate system
        assert(cloned ~= ps)

        -- Check copied properties
        local gx, gy = cloned:getGravity()
        assert(math.abs(gx - 5) < 0.001)
        assert(math.abs(gy - 10) < 0.001)

        local alphas = cloned:getAlphas()
        assert(#alphas == 3)

        local shape = cloned:getEmissionShape()
        assert(shape.type == "circle")
        assert(math.abs(shape.radius - 20) < 0.001)

        assert(cloned:getRelativeMode() == "attached")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_emission_shape_enum_derive() {
    // Verify PartialEq works for EmissionShape
    assert_eq!(EmissionShape::Point, EmissionShape::Point);
    assert_ne!(
        EmissionShape::Point,
        EmissionShape::Circle {
            radius: 10.0,
            fill: true
        }
    );
    assert_eq!(
        EmissionShape::Circle {
            radius: 5.0,
            fill: false
        },
        EmissionShape::Circle {
            radius: 5.0,
            fill: false
        }
    );
}

#[test]
fn test_relative_mode_enum_derive() {
    assert_eq!(RelativeMode::Detached, RelativeMode::Detached);
    assert_eq!(RelativeMode::Attached, RelativeMode::Attached);
    assert_ne!(RelativeMode::Detached, RelativeMode::Attached);
}

// ── Phase 7: Shape, batching, and math helpers ───────────────────────────

#[test]
fn particle_shape_default_is_square() {
    let cfg = ParticleConfig::default();
    assert_eq!(cfg.shape, ParticleShape::Square);
}

#[test]
fn particle_config_all_shapes_set() {
    let mut cfg = ParticleConfig::default();
    cfg.shape = ParticleShape::Circle;
    assert_eq!(cfg.shape, ParticleShape::Circle);
    cfg.shape = ParticleShape::Triangle;
    assert_eq!(cfg.shape, ParticleShape::Triangle);
    cfg.shape = ParticleShape::Spark;
    assert_eq!(cfg.shape, ParticleShape::Spark);
    cfg.shape = ParticleShape::Diamond;
    assert_eq!(cfg.shape, ParticleShape::Diamond);
    cfg.shape = ParticleShape::Square;
    assert_eq!(cfg.shape, ParticleShape::Square);
}

#[test]
fn particle_system_draw_commands_returns_one_entry() {
    let mut cfg = ParticleConfig::default();
    cfg.max_particles = 10;
    cfg.lifetime_min = 10.0;
    cfg.lifetime_max = 10.0;
    let mut sys = ParticleSystem::new(cfg);
    sys.stop();
    sys.emit(10);
    assert_eq!(sys.count(), 10);

    let cmds = sys.draw_commands(0.0, 0.0);
    assert_eq!(
        cmds.len(),
        1,
        "draw_commands should return exactly one DrawParticleSystem"
    );
    match &cmds[0] {
        DrawCommand::DrawParticleSystem { particles } => {
            assert_eq!(particles.len(), 10, "should have 10 particle instances");
        }
        other => panic!("expected DrawParticleSystem, got {:?}", other),
    }
}

#[test]
fn particle_system_draw_commands_empty_when_no_particles() {
    let sys = ParticleSystem::new(ParticleConfig::default());
    assert_eq!(sys.count(), 0);
    let cmds = sys.draw_commands(0.0, 0.0);
    assert!(
        cmds.is_empty(),
        "fresh system with no particles should return empty draw list"
    );
}

#[test]
fn particle_instance_color_matches_config() {
    let mut cfg = ParticleConfig::default();
    cfg.max_particles = 1;
    cfg.lifetime_min = 10.0;
    cfg.lifetime_max = 10.0;
    cfg.colors = vec![[1.0, 0.0, 0.0, 1.0]];
    let mut sys = ParticleSystem::new(cfg);
    sys.stop();
    sys.emit(1);

    let cmds = sys.draw_commands(0.0, 0.0);
    let particles = match &cmds[0] {
        DrawCommand::DrawParticleSystem { particles } => particles,
        other => panic!("expected DrawParticleSystem, got {:?}", other),
    };
    let inst = &particles[0];
    assert!(
        (inst.r - 1.0).abs() < 1e-4,
        "r should be 1.0, got {}",
        inst.r
    );
    assert!(
        (inst.g - 0.0).abs() < 1e-4,
        "g should be 0.0, got {}",
        inst.g
    );
    assert!(
        (inst.b - 0.0).abs() < 1e-4,
        "b should be 0.0, got {}",
        inst.b
    );
}

#[test]
fn particle_instance_shape_reflects_config() {
    let mut cfg = ParticleConfig::default();
    cfg.max_particles = 1;
    cfg.lifetime_min = 10.0;
    cfg.lifetime_max = 10.0;
    cfg.shape = ParticleShape::Circle;
    let mut sys = ParticleSystem::new(cfg);
    sys.stop();
    sys.emit(1);

    let cmds = sys.draw_commands(0.0, 0.0);
    let particles = match &cmds[0] {
        DrawCommand::DrawParticleSystem { particles } => particles,
        other => panic!("expected DrawParticleSystem, got {:?}", other),
    };
    assert!(
        matches!(particles[0].shape, ParticleRenderShape::Circle),
        "expected Circle shape in instance"
    );
}

#[test]
fn particle_spark_shape_draw_commands() {
    let mut cfg = ParticleConfig::default();
    cfg.max_particles = 1;
    cfg.lifetime_min = 10.0;
    cfg.lifetime_max = 10.0;
    cfg.shape = ParticleShape::Spark;
    let mut sys = ParticleSystem::new(cfg);
    sys.stop();
    sys.emit(1);

    let cmds = sys.draw_commands(0.0, 0.0);
    let particles = match &cmds[0] {
        DrawCommand::DrawParticleSystem { particles } => particles,
        other => panic!("expected DrawParticleSystem, got {:?}", other),
    };
    assert!(
        matches!(particles[0].shape, ParticleRenderShape::Spark),
        "expected Spark shape in instance"
    );
}

#[test]
fn particle_gravity_affects_velocity() {
    let mut cfg = ParticleConfig::default();
    cfg.max_particles = 1;
    cfg.lifetime_min = 10.0;
    cfg.lifetime_max = 10.0;
    cfg.gravity_y = 200.0;
    cfg.speed_min = 0.0;
    cfg.speed_max = 0.0;
    cfg.spread = 0.0;
    let mut sys = ParticleSystem::new(cfg);
    sys.stop();
    sys.emit(1);

    let vy_before = sys.particles[0].vy;
    sys.update(0.1);
    let vy_after = sys.particles[0].vy;

    assert!(
        vy_after > vy_before,
        "gravity_y=200 should increase vy over dt=0.1; before={}, after={}",
        vy_before,
        vy_after
    );
}

#[test]
fn particle_system_emit_respects_max() {
    let mut cfg = ParticleConfig::default();
    cfg.max_particles = 5;
    cfg.lifetime_min = 10.0;
    cfg.lifetime_max = 10.0;
    let mut sys = ParticleSystem::new(cfg);
    sys.stop();
    sys.emit(100);
    assert_eq!(
        sys.count(),
        5,
        "emit(100) should be capped at max_particles=5"
    );
}

#[test]
fn interpolate_sizes_empty_returns_one() {
    let result = interpolate_sizes(&[], 0.5, 0.0);
    assert!(
        (result - 1.0).abs() < 1e-4,
        "empty sizes should return 1.0, got {}",
        result
    );
}

#[test]
fn interpolate_colors_empty_returns_white() {
    let result = interpolate_colors(&[], 0.5);
    assert!((result[0] - 1.0).abs() < 1e-4, "r should be 1.0");
    assert!((result[1] - 1.0).abs() < 1e-4, "g should be 1.0");
    assert!((result[2] - 1.0).abs() < 1e-4, "b should be 1.0");
    assert!((result[3] - 1.0).abs() < 1e-4, "a should be 1.0");
}

#[test]
fn particle_files_are_split() {
    // Verify each sub-module is publicly reachable from the crate.
    use lurek2d::particle::config::ParticleConfig as _Cfg;
    use lurek2d::particle::emitter::ParticleSystem as _Sys;
    use lurek2d::particle::math::interpolate_sizes as _IS;
    use lurek2d::particle::shapes::ParticleShape as _Shape;
    let _ = _IS(&[], 0.0, 0.0);
    let _ = _Cfg::default();
    let _ = _Sys::new(_Cfg::default());
    let _ = _Shape::Circle;
}

#[test]
fn particle_lua_setshape_getshape_round_trip() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local ps = luna.particles.newSystem({ maxParticles = 10 })
        local shapes = {"square", "circle", "triangle", "spark", "diamond"}
        for _, s in ipairs(shapes) do
            ps:setShape(s)
            assert(ps:getShape() == s, "round-trip failed for shape: " .. s)
        end
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn particle_lua_setshape_invalid_raises_error() {
    let (_state, lua) = make_vm();
    let result = lua
        .load(
            r#"
        local ps = luna.particles.newSystem({ maxParticles = 10 })
        ps:setShape("hexagon")
        "#,
        )
        .exec();
    assert!(
        result.is_err(),
        "invalid shape name should raise a Lua error"
    );
    let err = result.unwrap_err().to_string();
    assert!(
        err.contains("hexagon"),
        "error message should mention the bad shape name, got: {}",
        err
    );
}

#[test]
fn particle_lua_default_shape_is_square() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local ps = luna.particles.newSystem({ maxParticles = 10 })
        assert(ps:getShape() == "square", "default shape should be square, got " .. ps:getShape())
        "#,
    )
    .exec()
    .unwrap();
}

// ── Trail ──────────────────────────────────────────────────────────────────

use lurek2d::math::Color;
use lurek2d::particle::Trail;

#[test]
fn trail_new_starts_empty() {
    let trail = Trail::new(2.0, 8.0);
    assert_eq!(trail.get_point_count(), 0);
    assert!((trail.get_lifetime() - 2.0).abs() < 1e-5);
    let (sw, _ew) = trail.get_width();
    assert!((sw - 8.0).abs() < 1e-5);
}

#[test]
fn trail_push_point_adds_entry() {
    let mut trail = Trail::new(5.0, 4.0);
    trail.push_point(10.0, 20.0);
    assert_eq!(trail.get_point_count(), 1);
}

#[test]
fn trail_push_point_respects_min_distance() {
    let mut trail = Trail::new(5.0, 4.0);
    trail.set_min_distance(10.0);
    trail.push_point(0.0, 0.0);
    // Second point is only 1 unit away — below min_distance → rejected
    trail.push_point(1.0, 0.0);
    assert_eq!(trail.get_point_count(), 1);
    // Third point is 15 units away — accepted
    trail.push_point(15.0, 0.0);
    assert_eq!(trail.get_point_count(), 2);
}

#[test]
fn trail_update_removes_expired_points() {
    let mut trail = Trail::new(0.5, 4.0);
    trail.push_point(0.0, 0.0);
    trail.push_point(100.0, 0.0); // force distance > min_distance
    assert_eq!(trail.get_point_count(), 2);
    // Advance past lifetime — both points should expire
    trail.update(1.0);
    assert_eq!(trail.get_point_count(), 0);
}

#[test]
fn trail_set_width_updates_both_ends() {
    let mut trail = Trail::new(2.0, 6.0);
    trail.set_width(12.0, Some(3.0));
    let (sw, ew) = trail.get_width();
    assert!((sw - 12.0).abs() < 1e-5);
    assert!((ew - 3.0).abs() < 1e-5);
}

#[test]
fn trail_set_width_none_preserves_end_width() {
    let mut trail = Trail::new(2.0, 6.0);
    trail.set_width(6.0, Some(2.0)); // set end_width to 2.0
    trail.set_width(10.0, None); // None should leave end_width at 2.0
    let (sw, ew) = trail.get_width();
    assert!((sw - 10.0).abs() < 1e-5);
    assert!((ew - 2.0).abs() < 1e-5);
}

#[test]
fn trail_clear_removes_all_points() {
    let mut trail = Trail::new(5.0, 4.0);
    trail.push_point(0.0, 0.0);
    trail.push_point(100.0, 0.0);
    trail.push_point(200.0, 0.0);
    assert_eq!(trail.get_point_count(), 3);
    trail.clear();
    assert_eq!(trail.get_point_count(), 0);
}

#[test]
fn trail_set_and_get_lifetime() {
    let mut trail = Trail::new(1.0, 4.0);
    trail.set_lifetime(3.5);
    assert!((trail.get_lifetime() - 3.5).abs() < 1e-5);
}

#[test]
fn trail_set_colors_updates_head_and_tail() {
    let mut trail = Trail::new(1.0, 4.0);
    trail.set_head_color(Color::new(1.0, 0.0, 0.0, 1.0));
    trail.set_tail_color(Color::new(0.0, 0.0, 1.0, 0.5));
    assert!((trail.head_color.r - 1.0).abs() < 1e-5);
    assert!((trail.tail_color.b - 1.0).abs() < 1e-5);
    assert!((trail.tail_color.a - 0.5).abs() < 1e-5);
}
