//! INTERNAL ONLY: Rust-only tests for lighting helpers that are not directly asserted through
//! `lurek.light.*`.
//!
//! Public light/world behaviour is covered by `tests/lua/unit/test_light_unit.lua`.
//! The remaining Rust tests keep attenuation/flicker math and light-world
//! helper invariants.

use lurek2d::light::attenuation::Attenuation;
use lurek2d::light::flicker::FlickerConfig;
use lurek2d::light::light2d::Light2D;
use lurek2d::light::light_world::LightWorld;

mod attenuation_tests {
    use super::*;

    #[test]
    fn factor_default_is_one_at_any_distance() {
        let attenuation = Attenuation::default();
        assert!((attenuation.factor(0.0) - 1.0).abs() < 1e-6);
        assert!((attenuation.factor(100.0) - 1.0).abs() < 1e-6);
    }

    #[test]
    fn factor_linear_decay() {
        let attenuation = Attenuation::new(1.0, 1.0, 0.0);
        assert!((attenuation.factor(1.0) - 0.5).abs() < 1e-6);
    }

    #[test]
    fn factor_quadratic_decay() {
        let attenuation = Attenuation::new(1.0, 0.0, 1.0);
        assert!((attenuation.factor(2.0) - 0.2).abs() < 1e-6);
    }

    #[test]
    fn factor_clamps_to_one_on_zero_denominator() {
        let attenuation = Attenuation::new(0.0, 0.0, 0.0);
        assert!((attenuation.factor(0.0) - 1.0).abs() < 1e-6);
    }
}

mod flicker_tests {
    use super::*;

    #[test]
    fn multiplier_disabled_is_one() {
        let flicker = FlickerConfig::default();
        assert!((flicker.multiplier() - 1.0).abs() < 1e-6);
    }

    #[test]
    fn multiplier_enabled_uses_sine() {
        let mut flicker = FlickerConfig::new(1.0, 0.5);
        flicker.phase = std::f32::consts::FRAC_PI_2;
        assert!((flicker.multiplier() - 1.5).abs() < 1e-4);
    }

    #[test]
    fn advance_does_nothing_when_disabled() {
        let mut flicker = FlickerConfig::default();
        flicker.advance(1.0);
        assert!((flicker.phase).abs() < 1e-6);
    }

    #[test]
    fn advance_increments_phase() {
        let mut flicker = FlickerConfig::new(2.0, 0.1);
        flicker.advance(0.5);
        assert!((flicker.phase - 1.0).abs() < 1e-6);
    }

    #[test]
    fn advance_wraps_phase_at_tau() {
        let mut flicker = FlickerConfig::new(1.0, 0.1);
        flicker.phase = std::f32::consts::TAU - 0.1;
        flicker.advance(1.0);
        assert!(flicker.phase < std::f32::consts::TAU);
    }
}

mod light_world_tests {
    use super::*;

    #[test]
    fn has_active_lights_reflects_enabled_flag() {
        let mut world = LightWorld::new();
        assert!(!world.has_active_lights());

        let key = world.add_light(Light2D::new(0.0, 0.0, 50.0));
        assert!(world.has_active_lights());

        world.get_light_mut(key).unwrap().set_enabled(false);
        assert!(!world.has_active_lights());
    }

    #[test]
    fn advance_flickers_updates_phase() {
        let mut world = LightWorld::new();
        let key = world.add_light(Light2D::new(0.0, 0.0, 50.0));
        world.get_light_mut(key).unwrap().flicker_mut().enabled = true;
        world.get_light_mut(key).unwrap().flicker_mut().speed = 2.0;

        world.advance_flickers(0.5);

        assert!(world.get_light(key).unwrap().flicker().phase > 0.0);
    }
}
