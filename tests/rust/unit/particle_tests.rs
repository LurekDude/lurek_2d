//! INTERNAL ONLY: Rust-only tests for particle visualization and callback internals
//! that are not directly asserted through `lurek.particle.*`.
//!
//! Public particle system and trail behavior is covered by
//! `tests/lua/unit/test_particle_unit.lua`.

use lurek2d::particle::visualization::draw_to_image;
use lurek2d::particle::{AreaDistribution, ParticleConfig, ParticleSystem};

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

mod distribution_and_fuzz_tests {
    use super::*;
    use lurek2d::particle::emission::emission_offset;
    use lurek2d::particle::presets;

    #[test]
    fn border_rectangle_emission_is_edge_biased() {
        let cfg = ParticleConfig {
            area_distribution: AreaDistribution::BorderRectangle,
            area_width: 100.0,
            area_height: 80.0,
            ..ParticleConfig::default()
        };

        let mut edge_hits = 0;
        let samples = 5000;
        let hw = cfg.area_width * 0.5;
        let hh = cfg.area_height * 0.5;
        for _ in 0..samples {
            let (x, y) = emission_offset(&cfg);
            let on_vertical = (x.abs() - hw).abs() < 1e-3;
            let on_horizontal = (y.abs() - hh).abs() < 1e-3;
            if on_vertical || on_horizontal {
                edge_hits += 1;
            }
        }
        assert!(
            edge_hits > (samples as f32 * 0.98) as usize,
            "expected almost all samples on rectangle border"
        );
    }

    #[test]
    fn presets_build_valid_configs() {
        let all = [
            presets::fire(),
            presets::smoke(),
            presets::rain(),
            presets::snow(),
            presets::sparks(),
        ];
        for cfg in all {
            let ps = ParticleSystem::new(cfg);
            assert!(ps.config.max_particles > 0);
        }
    }

    #[test]
    fn randomized_particle_update_does_not_panic() {
        for i in 0..200 {
            let mut cfg = ParticleConfig {
                max_particles: 16 + (i % 64) as u32,
                emission_rate: (i % 120) as f32,
                lifetime_min: 0.01,
                lifetime_max: 0.5 + (i as f32 * 0.001),
                speed_min: 0.0,
                speed_max: 250.0,
                spread: std::f32::consts::PI,
                drag: (i % 10) as f32 * 0.02,
                turbulence: (i % 8) as f32 * 1.5,
                ..ParticleConfig::default()
            };
            if i % 3 == 0 {
                cfg.area_distribution = AreaDistribution::BorderRectangle;
                cfg.area_width = 20.0 + i as f32;
                cfg.area_height = 15.0 + i as f32 * 0.5;
            }

            let mut ps = ParticleSystem::new(cfg);
            ps.emit(10);
            for _ in 0..8 {
                ps.update(1.0 / 120.0);
            }
        }
    }
}
