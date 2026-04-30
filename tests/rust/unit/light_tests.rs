//! Tests for the light module.

use lurek2d::light::attenuation::Attenuation;
use lurek2d::light::blend_mode::LightBlendMode;
use lurek2d::light::falloff::FalloffMode;
use lurek2d::light::flicker::FlickerConfig;
use lurek2d::light::light2d::Light2D;
use lurek2d::light::light_type::LightType;
use lurek2d::light::light_world::LightWorld;
use lurek2d::light::occluder::Occluder;
use lurek2d::light::shadow::ShadowFilter;
use lurek2d::light::transition::LightTransition;
use lurek2d::math::Vec2;

// ── attenuation tests ───────────────────────────────────────────────────────

mod attenuation_tests {
    use super::*;

    #[test]
    fn default_has_no_attenuation() {
        let a = Attenuation::default();
        assert!((a.constant - 1.0).abs() < 1e-6);
        assert!((a.linear).abs() < 1e-6);
        assert!((a.quadratic).abs() < 1e-6);
    }

    #[test]
    fn factor_default_is_one_at_any_distance() {
        let a = Attenuation::default();
        assert!((a.factor(0.0) - 1.0).abs() < 1e-6);
        assert!((a.factor(100.0) - 1.0).abs() < 1e-6);
    }

    #[test]
    fn factor_linear_decay() {
        let a = Attenuation::new(1.0, 1.0, 0.0);
        assert!((a.factor(1.0) - 0.5).abs() < 1e-6);
    }

    #[test]
    fn factor_quadratic_decay() {
        let a = Attenuation::new(1.0, 0.0, 1.0);
        assert!((a.factor(2.0) - 0.2).abs() < 1e-6);
    }

    #[test]
    fn factor_clamps_to_one_on_zero_denominator() {
        let a = Attenuation::new(0.0, 0.0, 0.0);
        assert!((a.factor(0.0) - 1.0).abs() < 1e-6);
    }
}

// ── blend_mode tests ────────────────────────────────────────────────────────

mod blend_mode_tests {
    use super::*;

    #[test]
    fn default_is_add() {
        assert_eq!(LightBlendMode::default(), LightBlendMode::Add);
    }

    #[test]
    fn clone_preserves_value() {
        let m = LightBlendMode::Sub;
        assert_eq!(m, m.clone());
    }
}

// ── falloff tests ───────────────────────────────────────────────────────────

mod falloff_tests {
    use super::*;

    #[test]
    fn default_is_linear() {
        assert_eq!(FalloffMode::default(), FalloffMode::Linear);
    }

    #[test]
    fn variants_are_distinct() {
        assert_ne!(FalloffMode::Linear, FalloffMode::Smooth);
        assert_ne!(FalloffMode::Smooth, FalloffMode::Constant);
    }
}

// ── flicker tests ───────────────────────────────────────────────────────────

mod flicker_tests {
    use super::*;

    #[test]
    fn default_is_disabled() {
        let f = FlickerConfig::default();
        assert!(!f.enabled);
        assert!((f.speed - 8.0).abs() < 1e-6);
        assert!((f.strength - 0.15).abs() < 1e-6);
    }

    #[test]
    fn new_is_enabled() {
        let f = FlickerConfig::new(10.0, 0.3);
        assert!(f.enabled);
        assert!((f.speed - 10.0).abs() < 1e-6);
        assert!((f.strength - 0.3).abs() < 1e-6);
    }

    #[test]
    fn multiplier_disabled_is_one() {
        let f = FlickerConfig::default();
        assert!((f.multiplier() - 1.0).abs() < 1e-6);
    }

    #[test]
    fn multiplier_enabled_uses_sine() {
        let mut f = FlickerConfig::new(1.0, 0.5);
        f.phase = std::f32::consts::FRAC_PI_2;
        assert!((f.multiplier() - 1.5).abs() < 1e-4);
    }

    #[test]
    fn advance_does_nothing_when_disabled() {
        let mut f = FlickerConfig::default();
        f.advance(1.0);
        assert!((f.phase).abs() < 1e-6);
    }

    #[test]
    fn advance_increments_phase() {
        let mut f = FlickerConfig::new(2.0, 0.1);
        f.advance(0.5);
        assert!((f.phase - 1.0).abs() < 1e-6);
    }

    #[test]
    fn advance_wraps_phase_at_tau() {
        let mut f = FlickerConfig::new(1.0, 0.1);
        f.phase = std::f32::consts::TAU - 0.1;
        f.advance(1.0);
        assert!(f.phase < std::f32::consts::TAU);
    }
}

// ── light2d tests ───────────────────────────────────────────────────────────

mod light2d_tests {
    use super::*;

    #[test]
    fn new_light_has_expected_defaults() {
        let light = Light2D::new(10.0, 20.0, 100.0);
        assert!((light.x - 10.0).abs() < 1e-5);
        assert!((light.y - 20.0).abs() < 1e-5);
        assert!((light.radius - 100.0).abs() < 1e-5);
        assert!((light.intensity - 1.0).abs() < 1e-5);
        assert!(light.enabled);
    }

    #[test]
    fn set_position_updates_coordinates() {
        let mut light = Light2D::new(0.0, 0.0, 50.0);
        light.set_position(5.5, -3.2);
        let (x, y) = light.get_position();
        assert!((x - 5.5).abs() < 1e-5);
        assert!((y - (-3.2)).abs() < 1e-5);
    }
}

// ── light_type tests ────────────────────────────────────────────────────────

mod light_type_tests {
    use super::*;

    #[test]
    fn default_is_point() {
        assert_eq!(LightType::default(), LightType::Point);
    }

    #[test]
    fn variants_are_distinct() {
        assert_ne!(LightType::Point, LightType::Directional);
        assert_ne!(LightType::Directional, LightType::Spot);
    }
}

// ── light_world tests ───────────────────────────────────────────────────────

mod light_world_tests {
    use super::*;

    #[test]
    fn new_world_is_empty_and_disabled() {
        let w = LightWorld::new();
        assert_eq!(w.light_count(), 0);
        assert_eq!(w.occluder_count(), 0);
        assert!(!w.enabled);
    }

    #[test]
    fn add_light_enables_world() {
        let mut w = LightWorld::new();
        let _k = w.add_light(Light2D::new(0.0, 0.0, 50.0));
        assert!(w.enabled);
        assert_eq!(w.light_count(), 1);
    }

    #[test]
    fn remove_light_returns_it() {
        let mut w = LightWorld::new();
        let k = w.add_light(Light2D::new(1.0, 2.0, 30.0));
        let removed = w.remove_light(k);
        assert!(removed.is_some());
        assert_eq!(w.light_count(), 0);
    }

    #[test]
    fn get_light_mut_modifies_in_place() {
        let mut w = LightWorld::new();
        let k = w.add_light(Light2D::new(0.0, 0.0, 50.0));
        w.get_light_mut(k).unwrap().set_intensity(0.5);
        assert!((w.get_light(k).unwrap().get_intensity() - 0.5).abs() < 1e-6);
    }

    #[test]
    fn add_and_remove_occluder() {
        let mut w = LightWorld::new();
        let verts = vec![
            Vec2::new(0.0, 0.0),
            Vec2::new(10.0, 0.0),
            Vec2::new(5.0, 10.0),
        ];
        let k = w.add_occluder(Occluder::new(verts));
        assert_eq!(w.occluder_count(), 1);
        assert!(w.remove_occluder(k).is_some());
        assert_eq!(w.occluder_count(), 0);
    }

    #[test]
    fn clear_resets_everything() {
        let mut w = LightWorld::new();
        w.add_light(Light2D::new(0.0, 0.0, 50.0));
        w.clear();
        assert_eq!(w.light_count(), 0);
    }

    #[test]
    fn has_active_lights_reflects_enabled_flag() {
        let mut w = LightWorld::new();
        assert!(!w.has_active_lights());
        let k = w.add_light(Light2D::new(0.0, 0.0, 50.0));
        assert!(w.has_active_lights());
        w.get_light_mut(k).unwrap().set_enabled(false);
        assert!(!w.has_active_lights());
    }

    #[test]
    fn advance_flickers_updates_phase() {
        let mut w = LightWorld::new();
        let k = w.add_light(Light2D::new(0.0, 0.0, 50.0));
        w.get_light_mut(k).unwrap().flicker_mut().enabled = true;
        w.get_light_mut(k).unwrap().flicker_mut().speed = 2.0;
        w.advance_flickers(0.5);
        assert!(w.get_light(k).unwrap().flicker().phase > 0.0);
    }

}

// ── occluder tests ──────────────────────────────────────────────────────────

mod occluder_tests {
    use super::*;

    fn tri_verts() -> Vec<Vec2> {
        vec![
            Vec2::new(0.0, 0.0),
            Vec2::new(10.0, 0.0),
            Vec2::new(5.0, 10.0),
        ]
    }

    #[test]
    fn new_with_valid_triangle() {
        let o = Occluder::new(tri_verts());
        assert_eq!(o.get_vertices().len(), 3);
        assert!(o.is_enabled());
        assert!((o.get_opacity() - 1.0).abs() < 1e-6);
    }

    #[test]
    #[should_panic(expected = "3..=512")]
    fn new_rejects_too_few_vertices() {
        Occluder::new(vec![Vec2::ZERO, Vec2::new(1.0, 0.0)]);
    }

    #[test]
    fn from_flat_coords_round_trips() {
        let flat = [0.0, 0.0, 10.0, 0.0, 5.0, 10.0];
        let o = Occluder::from_flat_coords(&flat).unwrap();
        assert_eq!(o.get_vertices().len(), 3);
    }

    #[test]
    fn from_flat_coords_rejects_odd_length() {
        assert!(Occluder::from_flat_coords(&[1.0, 2.0, 3.0]).is_err());
    }

    #[test]
    fn set_position_updates() {
        let mut o = Occluder::new(tri_verts());
        o.set_position(Vec2::new(5.0, 3.0));
        let p = o.get_position();
        assert!((p.x - 5.0).abs() < 1e-6);
        assert!((p.y - 3.0).abs() < 1e-6);
    }

    #[test]
    fn set_opacity_clamp_responsibility_is_on_caller() {
        let mut o = Occluder::new(tri_verts());
        o.set_opacity(0.5);
        assert!((o.get_opacity() - 0.5).abs() < 1e-6);
    }

    #[test]
    fn light_mask_default_is_all_bits() {
        let o = Occluder::new(tri_verts());
        assert_eq!(o.get_light_mask(), 0xFFFF);
    }
}

// ── shadow tests ────────────────────────────────────────────────────────────

mod shadow_tests {
    use super::*;

    #[test]
    fn default_is_none() {
        assert_eq!(ShadowFilter::default(), ShadowFilter::None);
    }

    #[test]
    fn all_variants_copiable() {
        let f = ShadowFilter::Pcf5;
        let f2 = f;
        assert_eq!(f, f2);
    }
}

// ── transition tests ────────────────────────────────────────────────────────

mod transition_tests {
    use super::*;

    #[test]
    fn new_starts_active() {
        let t = LightTransition::new(
            [1.0, 1.0, 1.0, 1.0],
            [0.0, 0.0, 0.0, 1.0],
            1.0,
            0.0,
            100.0,
            50.0,
            2.0,
        );
        assert!(t.active);
        assert!((t.elapsed).abs() < 1e-6);
    }

    #[test]
    fn update_returns_interpolated_values() {
        let mut t = LightTransition::new(
            [1.0, 1.0, 1.0, 1.0],
            [0.0, 0.0, 0.0, 1.0],
            1.0,
            0.0,
            100.0,
            50.0,
            2.0,
        );
        let result = t.update(1.0);
        assert!(result.is_some());
        let (color, intensity, radius) = result.unwrap();
        assert!((color[0] - 0.5).abs() < 1e-4);
        assert!((intensity - 0.5).abs() < 1e-4);
        assert!((radius - 75.0).abs() < 1e-3);
    }

    #[test]
    fn update_deactivates_after_duration() {
        let mut t = LightTransition::new(
            [1.0, 0.0, 0.0, 1.0],
            [0.0, 1.0, 0.0, 1.0],
            1.0,
            0.5,
            50.0,
            100.0,
            1.0,
        );
        let r1 = t.update(1.5);
        assert!(r1.is_some());
        assert!(!t.active);
        let r2 = t.update(0.1);
        assert!(r2.is_none());
    }

    #[test]
    fn progress_starts_at_zero() {
        let t = LightTransition::new([0.0; 4], [1.0; 4], 1.0, 1.0, 10.0, 20.0, 5.0);
        assert!((t.progress()).abs() < 1e-6);
    }

    #[test]
    fn progress_clamps_to_one() {
        let mut t = LightTransition::new([0.0; 4], [1.0; 4], 1.0, 1.0, 10.0, 20.0, 1.0);
        t.elapsed = 5.0;
        assert!((t.progress() - 1.0).abs() < 1e-6);
    }
}
