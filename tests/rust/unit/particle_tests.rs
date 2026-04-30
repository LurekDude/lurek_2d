//! Smoke tests for the particle module against the current public API.

use lurek2d::particle::visualization::draw_to_image;
use lurek2d::particle::{ParticleConfig, ParticleSystem, Trail};

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

mod extensibility_tests {
    use lurek2d::particle::{EmissionShape, ParticleConfig, ParticleSystem};

    #[test]
    fn custom_emission_shape_variant_exists() {
        let shape = EmissionShape::Custom { callback_id: 99 };
        match shape {
            EmissionShape::Custom { callback_id } => assert_eq!(callback_id, 99),
            _ => panic!("unexpected variant"),
        }
    }

    #[test]
    fn pending_deaths_drained_after_update() {
        let mut config = ParticleConfig::default();
        config.lifetime_min = 0.001;
        config.lifetime_max = 0.001;
        config.emission_rate = 0.0;
        let mut ps = ParticleSystem::new(config);
        ps.emit(3);
        ps.update(1.0); // enough time to kill all 3
        let deaths = ps.drain_pending_deaths();
        assert!(
            !deaths.is_empty(),
            "should have deaths recorded after all particles expire"
        );
    }

    #[test]
    fn drain_custom_offsets_clears_vec() {
        let mut config = ParticleConfig::default();
        config.emission_shape = EmissionShape::Custom { callback_id: 1 };
        config.emission_rate = 0.0;
        let mut ps = ParticleSystem::new(config);
        ps.emit(2);
        let offsets = ps.drain_custom_offsets();
        assert_eq!(offsets.len(), 2);
        assert!(
            ps.drain_custom_offsets().is_empty(),
            "second drain should be empty"
        );
    }
}
