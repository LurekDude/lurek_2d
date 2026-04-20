//! Smoke tests for the particle module against the current public API.

use lurek2d::math::Color;
use lurek2d::particle::config::{Attractor, BounceBounds};
use lurek2d::particle::emission::{emission_offset, emission_shape_offset};
use lurek2d::particle::trail::TrailPoint;
use lurek2d::particle::visualization::draw_to_image;
use lurek2d::particle::{
    AreaDistribution, EmissionShape, InsertMode, Particle, ParticleConfig, ParticleShape,
    ParticleSystem, RelativeMode, Trail,
};
use lurek2d::render::renderer::{DrawMode, RenderCommand};

mod emitter_tests {
    use super::*;

    #[test]
    fn emit_increases_count() {
        let mut ps = ParticleSystem::new(ParticleConfig::default());
        assert!(ps.is_empty());
        ps.emit(5);
        assert!(ps.count() > 0);
    }

    #[test]
    fn state_transitions_toggle_flags() {
        let mut ps = ParticleSystem::new(ParticleConfig::default());
        assert!(ps.is_active());
        ps.start();
        assert!(ps.is_active());
        ps.pause();
        assert!(ps.is_paused());
        ps.resume();
        assert!(ps.is_active());
        ps.stop();
        assert!(ps.is_stopped());
    }

    #[test]
    fn attractor_management() {
        let mut ps = ParticleSystem::new(ParticleConfig::default());
        ps.add_attractor(0.0, 0.0, 10.0, 32.0);
        assert_eq!(ps.attractor_count(), 1);
        ps.clear_attractors();
        assert_eq!(ps.attractor_count(), 0);
    }
}

mod trail_tests {
    use super::*;

    #[test]
    fn push_point_and_clear() {
        let mut trail = Trail::new(1.0, 4.0);
        trail.push_point(0.0, 0.0);
        trail.push_point(5.0, 5.0);
        assert_eq!(trail.get_point_count(), 2);
        trail.clear();
        assert_eq!(trail.get_point_count(), 0);
    }

    #[test]
    fn width_and_lifetime_roundtrip() {
        let mut trail = Trail::new(1.0, 4.0);
        trail.set_width(4.0, Some(1.0));
        trail.set_lifetime(2.5);
        assert_eq!(trail.get_width(), (4.0, 1.0));
        assert!((trail.get_lifetime() - 2.5).abs() < f32::EPSILON);
    }

    #[test]
    fn draw_to_image_correct_dimensions() {
        let trail = Trail::new(1.0, 4.0);
        let img = trail.draw_to_image(64, 32);
        assert_eq!(img.width(), 64);
        assert_eq!(img.height(), 32);
    }
}

mod visualization_tests {
    use super::*;

    #[test]
    fn draw_to_image_correct_dimensions() {
        let ps = ParticleSystem::new(ParticleConfig::default());
        let img = draw_to_image(&ps, 80, 40);
        assert_eq!(img.width(), 80);
        assert_eq!(img.height(), 40);
    }
}

mod config_tests {
    use super::*;

    #[test]
    fn default_config_pool_and_rate() {
        let cfg = ParticleConfig::default();
        assert_eq!(cfg.max_particles, 256);
        assert!((cfg.emission_rate - 10.0).abs() < f32::EPSILON);
    }

    #[test]
    fn default_config_lifetime_range() {
        let cfg = ParticleConfig::default();
        assert!(cfg.lifetime_min <= cfg.lifetime_max);
        assert!((cfg.lifetime_min - 1.0).abs() < f32::EPSILON);
        assert!((cfg.lifetime_max - 2.0).abs() < f32::EPSILON);
    }

    #[test]
    fn default_config_speed_range() {
        let cfg = ParticleConfig::default();
        assert!(cfg.speed_min <= cfg.speed_max);
    }

    #[test]
    fn default_config_sizes_and_colors() {
        let cfg = ParticleConfig::default();
        assert_eq!(cfg.sizes.len(), 2);
        assert_eq!(cfg.colors.len(), 2);
    }

    #[test]
    fn default_config_shape_is_square() {
        let cfg = ParticleConfig::default();
        assert_eq!(cfg.shape, ParticleShape::default());
    }

    #[test]
    fn area_distribution_default_is_none() {
        assert_eq!(AreaDistribution::default(), AreaDistribution::None);
    }

    #[test]
    fn insert_mode_default_is_top() {
        assert_eq!(InsertMode::default(), InsertMode::Top);
    }

    #[test]
    fn emission_shape_default_is_point() {
        assert_eq!(EmissionShape::default(), EmissionShape::Point);
    }

    #[test]
    fn relative_mode_default_is_detached() {
        assert_eq!(RelativeMode::default(), RelativeMode::Detached);
    }

    #[test]
    fn attractor_clone_preserves_fields() {
        let a = Attractor { x: 1.0, y: 2.0, strength: 50.0, radius: 100.0 };
        let b = a.clone();
        assert!((b.strength - 50.0).abs() < f32::EPSILON);
        assert!((b.radius - 100.0).abs() < f32::EPSILON);
    }

    #[test]
    fn bounce_bounds_clone_preserves_restitution() {
        let bb = BounceBounds {
            x_min: 0.0,
            x_max: 800.0,
            y_min: 0.0,
            y_max: 600.0,
            restitution: 0.7,
        };
        let c = bb.clone();
        assert!((c.restitution - 0.7).abs() < f32::EPSILON);
    }

    #[test]
    fn default_config_no_death_emitter() {
        let cfg = ParticleConfig::default();
        assert!(cfg.death_emitter.is_none());
        assert_eq!(cfg.death_burst_count, 0);
    }

    #[test]
    fn default_config_shape_helper_fields() {
        let cfg = ParticleConfig::default();
        assert_eq!(cfg.shrapnel_edges, 6);
        assert!((cfg.ray_aspect - 4.0).abs() < f32::EPSILON);
        assert!((cfg.ring_thickness - 0.2).abs() < f32::EPSILON);
    }
}

mod emission_tests {
    use super::*;

    #[test]
    fn emission_offset_none_is_zero() {
        let cfg = ParticleConfig {
            area_distribution: AreaDistribution::None,
            ..ParticleConfig::default()
        };
        let (dx, dy) = emission_offset(&cfg);
        assert!(dx.abs() < f32::EPSILON);
        assert!(dy.abs() < f32::EPSILON);
    }

    #[test]
    fn emission_offset_uniform_within_bounds() {
        let mut cfg = ParticleConfig::default();
        cfg.area_distribution = AreaDistribution::Uniform;
        cfg.area_width = 100.0;
        cfg.area_height = 50.0;
        for _ in 0..100 {
            let (dx, dy) = emission_offset(&cfg);
            assert!(dx.abs() <= 50.0 + 1e-3);
            assert!(dy.abs() <= 25.0 + 1e-3);
        }
    }

    #[test]
    fn emission_offset_ellipse_within_radius() {
        let mut cfg = ParticleConfig::default();
        cfg.area_distribution = AreaDistribution::Ellipse;
        cfg.area_width = 20.0;
        cfg.area_height = 20.0;
        for _ in 0..100 {
            let (dx, dy) = emission_offset(&cfg);
            let dist = (dx * dx + dy * dy).sqrt();
            assert!(dist <= 10.0 + 1e-3);
        }
    }

    #[test]
    fn emission_offset_area_angle_rotates() {
        let mut cfg = ParticleConfig::default();
        cfg.area_distribution = AreaDistribution::Uniform;
        cfg.area_width = 100.0;
        cfg.area_height = 0.0;
        cfg.area_angle = std::f32::consts::FRAC_PI_2;
        let (dx, dy) = emission_offset(&cfg);
        assert!(dx.abs() < 1e-3 || dy.abs() > 0.0);
    }

    #[test]
    fn emission_shape_point_is_zero() {
        let (x, y) = emission_shape_offset(&EmissionShape::Point);
        assert!(x.abs() < f32::EPSILON);
        assert!(y.abs() < f32::EPSILON);
    }

    #[test]
    fn emission_shape_circle_edge_only() {
        let shape = EmissionShape::Circle { radius: 10.0, fill: false };
        for _ in 0..50 {
            let (x, y) = emission_shape_offset(&shape);
            let dist = (x * x + y * y).sqrt();
            assert!((dist - 10.0).abs() < 1e-3, "edge-only circle should be at radius");
        }
    }

    #[test]
    fn emission_shape_star_stays_bounded() {
        let shape = EmissionShape::Star { points: 5, outer_radius: 20.0, inner_radius: 10.0 };
        for _ in 0..100 {
            let (x, y) = emission_shape_offset(&shape);
            let dist = (x * x + y * y).sqrt();
            assert!(dist <= 20.0 + 1e-3);
        }
    }

    #[test]
    fn emission_shape_spiral_stays_bounded() {
        let shape = EmissionShape::Spiral { revolutions: 3.0, radius: 50.0 };
        for _ in 0..100 {
            let (x, y) = emission_shape_offset(&shape);
            let dist = (x * x + y * y).sqrt();
            assert!(dist <= 50.0 + 1e-3);
        }
    }

    #[test]
    fn border_rectangle_zero_perimeter_returns_zero() {
        let mut cfg = ParticleConfig::default();
        cfg.area_distribution = AreaDistribution::BorderRectangle;
        cfg.area_width = 0.0;
        cfg.area_height = 0.0;
        let (dx, dy) = emission_offset(&cfg);
        assert!(dx.abs() < f32::EPSILON);
        assert!(dy.abs() < f32::EPSILON);
    }
}

mod particle_struct_tests {
    use super::*;

    fn default_particle() -> Particle {
        Particle {
            x: 10.0,
            y: 20.0,
            vx: 1.0,
            vy: -2.0,
            life: 1.5,
            max_life: 3.0,
            rotation: 0.0,
            spin: 0.5,
            radial_accel: 0.0,
            tangential_accel: 0.0,
            linear_damping: 0.0,
            size_variation: 0.0,
            origin_x: 0.0,
            origin_y: 0.0,
            shape_seed: 42,
        }
    }

    #[test]
    fn particle_clone_preserves_fields() {
        let p = default_particle();
        let c = p.clone();
        assert!((c.x - 10.0).abs() < f32::EPSILON);
        assert!((c.vy - (-2.0)).abs() < f32::EPSILON);
        assert_eq!(c.shape_seed, 42);
    }

    #[test]
    fn particle_debug_format_contains_fields() {
        let p = default_particle();
        let dbg = format!("{:?}", p);
        assert!(dbg.contains("Particle"));
        assert!(dbg.contains("shape_seed"));
    }

    #[test]
    fn particle_life_ratio() {
        let p = default_particle();
        let ratio = 1.0 - (p.life / p.max_life);
        assert!((ratio - 0.5).abs() < f32::EPSILON);
    }
}

mod render_tests {
    use super::*;

    #[test]
    fn empty_system_gives_empty_commands() {
        let sys = ParticleSystem::new(ParticleConfig::default());
        let cmds = sys.generate_render_commands();
        assert!(cmds.is_empty());
    }

    #[test]
    fn generate_render_commands_matches_build() {
        let sys = ParticleSystem::new(ParticleConfig::default());
        let a = sys.generate_render_commands();
        let b = sys.build_render_commands(0.0, 0.0);
        assert_eq!(a.len(), b.len());
    }

    #[test]
    fn empty_trail_gives_empty_commands() {
        let trail = Trail::new(2.0, 4.0);
        let cmds: Vec<RenderCommand> = trail.generate_render_commands();
        assert!(cmds.is_empty());
    }
}

mod shapes_tests {
    use super::*;

    #[test]
    fn default_shape_is_square() {
        assert_eq!(ParticleShape::default(), ParticleShape::Square);
    }

    #[test]
    fn shrapnel_edges_cloned() {
        let s = ParticleShape::Shrapnel { edges: 8 };
        let c = s.clone();
        assert_eq!(c, ParticleShape::Shrapnel { edges: 8 });
    }

    #[test]
    fn ray_aspect_preserved() {
        let s = ParticleShape::Ray { aspect: 6.0 };
        if let ParticleShape::Ray { aspect } = s {
            assert!((aspect - 6.0).abs() < f32::EPSILON);
        } else {
            panic!("expected Ray variant");
        }
    }

    #[test]
    fn ring_thickness_preserved() {
        let s = ParticleShape::Ring { thickness: 0.3 };
        if let ParticleShape::Ring { thickness } = s {
            assert!((thickness - 0.3).abs() < f32::EPSILON);
        } else {
            panic!("expected Ring variant");
        }
    }

    #[test]
    fn all_variants_are_debug_printable() {
        let variants: Vec<ParticleShape> = vec![
            ParticleShape::Square,
            ParticleShape::Circle,
            ParticleShape::Triangle,
            ParticleShape::Spark,
            ParticleShape::Diamond,
            ParticleShape::Shrapnel { edges: 5 },
            ParticleShape::Ray { aspect: 4.0 },
            ParticleShape::Puff,
            ParticleShape::Ring { thickness: 0.2 },
            ParticleShape::Capsule,
        ];
        for v in &variants {
            let _ = format!("{:?}", v);
        }
        assert_eq!(variants.len(), 10);
    }
}

mod trail_render_tests {
    use super::*;

    #[test]
    fn empty_trail_no_commands() {
        let trail = Trail::new(1.0, 4.0);
        let cmds = trail.build_render_commands();
        assert!(cmds.is_empty());
    }

    #[test]
    fn single_point_no_commands() {
        let mut trail = Trail::new(1.0, 4.0);
        trail.min_distance = 0.0;
        trail.points.push(TrailPoint { x: 0.0, y: 0.0, age: 0.0 });
        let cmds = trail.build_render_commands();
        assert!(cmds.is_empty());
    }

    #[test]
    fn two_points_produce_three_commands() {
        let mut trail = Trail::new(1.0, 4.0);
        trail.min_distance = 0.0;
        trail.points.push(TrailPoint { x: 0.0, y: 0.0, age: 0.0 });
        trail.points.push(TrailPoint { x: 10.0, y: 0.0, age: 0.5 });
        let cmds = trail.build_render_commands();
        assert_eq!(cmds.len(), 3);
        assert!(matches!(cmds[0], RenderCommand::SetColor(..)));
        assert!(matches!(cmds[1], RenderCommand::Triangle { mode: DrawMode::Fill, .. }));
        assert!(matches!(cmds[2], RenderCommand::Triangle { mode: DrawMode::Fill, .. }));
    }

    #[test]
    fn color_interpolation_midpoint() {
        let mut trail = Trail::new(2.0, 4.0);
        trail.head_color = Color::new(1.0, 0.0, 0.0, 1.0);
        trail.tail_color = Color::new(0.0, 1.0, 0.0, 1.0);
        trail.min_distance = 0.0;
        trail.points.push(TrailPoint { x: 0.0, y: 0.0, age: 0.0 });
        trail.points.push(TrailPoint { x: 10.0, y: 0.0, age: 2.0 });
        let cmds = trail.build_render_commands();
        match &cmds[0] {
            RenderCommand::SetColor(r, g, _b, _a) => {
                assert!((r - 0.5).abs() < 1e-5);
                assert!((g - 0.5).abs() < 1e-5);
            }
            other => panic!("Expected SetColor, got {:?}", other),
        }
    }

    #[test]
    fn width_tapering_at_tail() {
        let mut trail = Trail::new(1.0, 10.0);
        trail.end_width = 2.0;
        trail.min_distance = 0.0;
        trail.points.push(TrailPoint { x: 0.0, y: 0.0, age: 0.0 });
        trail.points.push(TrailPoint { x: 20.0, y: 0.0, age: 1.0 });
        let cmds = trail.build_render_commands();
        match &cmds[1] {
            RenderCommand::Triangle { y1, y2, .. } => {
                assert!((y1.abs() - 5.0).abs() < 1e-5);
                assert!((y2.abs() - 5.0).abs() < 1e-5);
            }
            other => panic!("Expected Triangle, got {:?}", other),
        }
    }
}
