//! Integration tests for luna2d::particle.

use luna2d::graphics::renderer::{DrawCommand, ParticleRenderShape};
use luna2d::particle::{
    interpolate_colors, interpolate_sizes, ParticleConfig, ParticleShape, ParticleSystem,
};

// ── Shape defaults and assignment ────────────────────────────────────────────

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

// ── draw_commands batching ────────────────────────────────────────────────────

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
    assert_eq!(cmds.len(), 1, "draw_commands should return exactly one DrawParticleSystem");

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
    assert!(cmds.is_empty(), "fresh system with no particles should return empty draw list");
}

// ── Per-instance color and shape ─────────────────────────────────────────────

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
    assert_eq!(sys.count(), 1);

    let cmds = sys.draw_commands(0.0, 0.0);
    let particles = match &cmds[0] {
        DrawCommand::DrawParticleSystem { particles } => particles,
        other => panic!("expected DrawParticleSystem, got {:?}", other),
    };
    let inst = &particles[0];
    assert!((inst.r - 1.0).abs() < 1e-4, "r should be 1.0, got {}", inst.r);
    assert!((inst.g - 0.0).abs() < 1e-4, "g should be 0.0, got {}", inst.g);
    assert!((inst.b - 0.0).abs() < 1e-4, "b should be 0.0, got {}", inst.b);
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

// ── Physics ──────────────────────────────────────────────────────────────────

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
        vy_before, vy_after
    );
}

// ── Max particle cap ─────────────────────────────────────────────────────────

#[test]
fn particle_system_emit_respects_max() {
    let mut cfg = ParticleConfig::default();
    cfg.max_particles = 5;
    cfg.lifetime_min = 10.0;
    cfg.lifetime_max = 10.0;
    let mut sys = ParticleSystem::new(cfg);
    sys.stop();
    sys.emit(100);
    assert_eq!(sys.count(), 5, "emit(100) should be capped at max_particles=5");
}

// ── Math helpers ─────────────────────────────────────────────────────────────

#[test]
fn interpolate_sizes_empty_returns_one() {
    let result = interpolate_sizes(&[], 0.5, 0.0);
    assert!((result - 1.0).abs() < 1e-4, "empty sizes should return 1.0, got {}", result);
}

#[test]
fn interpolate_colors_empty_returns_white() {
    let result = interpolate_colors(&[], 0.5);
    assert!((result[0] - 1.0).abs() < 1e-4, "r should be 1.0");
    assert!((result[1] - 1.0).abs() < 1e-4, "g should be 1.0");
    assert!((result[2] - 1.0).abs() < 1e-4, "b should be 1.0");
    assert!((result[3] - 1.0).abs() < 1e-4, "a should be 1.0");
}

// ── Sub-module imports compile ────────────────────────────────────────────────

#[test]
fn particle_files_are_split() {
    // These imports verify each sub-module is publicly reachable from the crate.
    use luna2d::particle::config::ParticleConfig as _Cfg;
    use luna2d::particle::emitter::ParticleSystem as _Sys;
    use luna2d::particle::shapes::ParticleShape as _Shape;
    use luna2d::particle::math::interpolate_sizes as _IS;
    use luna2d::particle::particle::Particle as _P;
    // If this compiles, the sub-modules are correctly split and exported.
    let _ = _IS(&[], 0.0, 0.0);
    let _ = _Cfg::default();
    let _ = _Sys::new(_Cfg::default());
    let _ = _Shape::Circle;
    drop(_P {
        x: 0.0, y: 0.0, vx: 0.0, vy: 0.0,
        life: 1.0, max_life: 1.0,
        rotation: 0.0, spin: 0.0,
        radial_accel: 0.0, tangential_accel: 0.0,
        linear_damping: 0.0, size_variation: 0.0,
        origin_x: 0.0, origin_y: 0.0,
    });
}
