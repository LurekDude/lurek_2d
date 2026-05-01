//! INTERNAL ONLY: Rust-only tests for particle visualization and callback internals
//! that are not directly asserted through `lurek.particle.*`.
//!
//! Public particle system and trail behavior is covered by
//! `tests/lua/unit/test_particle_unit.lua`.

use lurek2d::particle::visualization::draw_to_image;
use lurek2d::particle::{ParticleConfig, ParticleSystem};

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
