//! Integration tests for lurek2d::light.

use lurek2d::light::*;
use lurek2d::math::{Color, Vec2};

// ── Enum Defaults ─────────────────────────────────────────────────────────────

#[test]
fn light_blend_mode_default_is_add() {
    assert_eq!(LightBlendMode::default(), LightBlendMode::Add);
}

#[test]
fn falloff_mode_default_is_linear() {
    assert_eq!(FalloffMode::default(), FalloffMode::Linear);
}

#[test]
fn shadow_filter_default_is_none() {
    assert_eq!(ShadowFilter::default(), ShadowFilter::None);
}

// ── Light2D Construction ──────────────────────────────────────────────────────

#[test]
fn light2d_new_creates_default_values() {
    let l = Light2D::new(10.0, 20.0, 100.0);
    assert!((l.x - 10.0).abs() < 1e-5);
    assert!((l.y - 20.0).abs() < 1e-5);
    assert!((l.radius - 100.0).abs() < 1e-5);
    assert_eq!(l.color, Color::WHITE);
    assert!((l.intensity - 1.0).abs() < 1e-5);
    assert!(l.enabled);
    assert!((l.energy - 1.0).abs() < 1e-5);
    assert_eq!(l.blend_mode, LightBlendMode::Add);
    assert_eq!(l.falloff, FalloffMode::Linear);
    assert!(!l.shadow_enabled);
    assert_eq!(l.shadow_color, Color::BLACK);
    assert_eq!(l.shadow_filter, ShadowFilter::None);
    assert!((l.shadow_smooth - 1.0).abs() < 1e-5);
    assert_eq!(l.light_mask, 0xFFFF);
    assert_eq!(l.shadow_mask, 0xFFFF);
}

// ── Light2D Getters/Setters ───────────────────────────────────────────────────

#[test]
fn light2d_set_get_position() {
    let mut l = Light2D::new(0.0, 0.0, 50.0);
    l.set_position(123.5, -456.0);
    let (x, y) = l.get_position();
    assert!((x - 123.5).abs() < 1e-5);
    assert!((y - (-456.0)).abs() < 1e-5);
}

#[test]
fn light2d_set_get_radius() {
    let mut l = Light2D::new(0.0, 0.0, 50.0);
    l.set_radius(200.0);
    assert!((l.get_radius() - 200.0).abs() < 1e-5);
}

#[test]
fn light2d_set_get_color() {
    let mut l = Light2D::new(0.0, 0.0, 50.0);
    let red = Color::new(1.0, 0.0, 0.0, 1.0);
    l.set_color(red);
    assert_eq!(l.get_color(), red);
}

#[test]
fn light2d_set_get_intensity() {
    let mut l = Light2D::new(0.0, 0.0, 50.0);
    l.set_intensity(0.5);
    assert!((l.get_intensity() - 0.5).abs() < 1e-5);
}

#[test]
fn light2d_set_get_enabled() {
    let mut l = Light2D::new(0.0, 0.0, 50.0);
    assert!(l.is_enabled());
    l.set_enabled(false);
    assert!(!l.is_enabled());
    l.set_enabled(true);
    assert!(l.is_enabled());
}

#[test]
fn light2d_set_get_energy() {
    let mut l = Light2D::new(0.0, 0.0, 50.0);
    l.set_energy(2.5);
    assert!((l.get_energy() - 2.5).abs() < 1e-5);
}

#[test]
fn light2d_set_get_blend_mode() {
    let mut l = Light2D::new(0.0, 0.0, 50.0);
    l.set_blend_mode(LightBlendMode::Sub);
    assert_eq!(l.get_blend_mode(), LightBlendMode::Sub);
    l.set_blend_mode(LightBlendMode::Mix);
    assert_eq!(l.get_blend_mode(), LightBlendMode::Mix);
    l.set_blend_mode(LightBlendMode::Add);
    assert_eq!(l.get_blend_mode(), LightBlendMode::Add);
}

#[test]
fn light2d_set_get_falloff() {
    let mut l = Light2D::new(0.0, 0.0, 50.0);
    l.set_falloff(FalloffMode::Smooth);
    assert_eq!(l.get_falloff(), FalloffMode::Smooth);
    l.set_falloff(FalloffMode::Constant);
    assert_eq!(l.get_falloff(), FalloffMode::Constant);
    l.set_falloff(FalloffMode::Linear);
    assert_eq!(l.get_falloff(), FalloffMode::Linear);
}

// ── Light2D Shadow Fields ─────────────────────────────────────────────────────

#[test]
fn light2d_shadow_defaults() {
    let l = Light2D::new(0.0, 0.0, 50.0);
    assert!(!l.is_shadow_enabled());
    assert_eq!(l.get_shadow_color(), Color::BLACK);
    assert_eq!(l.get_shadow_filter(), ShadowFilter::None);
    assert!((l.get_shadow_smooth() - 1.0).abs() < 1e-5);
}

#[test]
fn light2d_set_get_shadow_fields() {
    let mut l = Light2D::new(0.0, 0.0, 50.0);
    l.set_shadow_enabled(true);
    assert!(l.is_shadow_enabled());

    let gray = Color::new(0.5, 0.5, 0.5, 1.0);
    l.set_shadow_color(gray);
    assert_eq!(l.get_shadow_color(), gray);

    l.set_shadow_filter(ShadowFilter::Pcf5);
    assert_eq!(l.get_shadow_filter(), ShadowFilter::Pcf5);
    l.set_shadow_filter(ShadowFilter::Pcf13);
    assert_eq!(l.get_shadow_filter(), ShadowFilter::Pcf13);

    l.set_shadow_smooth(2.0);
    assert!((l.get_shadow_smooth() - 2.0).abs() < 1e-5);
}

// ── Light2D Masks ─────────────────────────────────────────────────────────────

#[test]
fn light2d_set_get_masks() {
    let mut l = Light2D::new(0.0, 0.0, 50.0);
    assert_eq!(l.get_light_mask(), 0xFFFF);
    assert_eq!(l.get_shadow_mask(), 0xFFFF);

    l.set_light_mask(0x00FF);
    assert_eq!(l.get_light_mask(), 0x00FF);

    l.set_shadow_mask(0x0001);
    assert_eq!(l.get_shadow_mask(), 0x0001);
}

// ── Occluder Construction ─────────────────────────────────────────────────────

#[test]
fn occluder_new_triangle() {
    let verts = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(10.0, 0.0),
        Vec2::new(5.0, 10.0),
    ];
    let o = Occluder::new(verts.clone());
    assert_eq!(o.get_vertices().len(), 3);
    assert_eq!(o.get_position(), Vec2::ZERO);
    assert!((o.get_opacity() - 1.0).abs() < 1e-5);
    assert_eq!(o.get_light_mask(), 0xFFFF);
    assert!(o.is_enabled());
}

#[test]
fn occluder_new_max_vertices() {
    let verts: Vec<Vec2> = (0..256)
        .map(|i| Vec2::new(i as f32, (i * 2) as f32))
        .collect();
    let o = Occluder::new(verts);
    assert_eq!(o.get_vertices().len(), 256);
}

#[test]
#[should_panic(expected = "Occluder vertex count must be 3..=256")]
fn occluder_new_too_few_panics() {
    let verts = vec![Vec2::new(0.0, 0.0), Vec2::new(1.0, 0.0)];
    let _ = Occluder::new(verts);
}

#[test]
#[should_panic(expected = "Occluder vertex count must be 3..=256")]
fn occluder_new_too_many_panics() {
    let verts: Vec<Vec2> = (0..257).map(|i| Vec2::new(i as f32, 0.0)).collect();
    let _ = Occluder::new(verts);
}

// ── Occluder Getters/Setters ──────────────────────────────────────────────────

#[test]
fn occluder_set_get_vertices() {
    let initial = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(1.0, 0.0),
        Vec2::new(0.5, 1.0),
    ];
    let mut o = Occluder::new(initial);
    let replacement = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(5.0, 0.0),
        Vec2::new(5.0, 5.0),
        Vec2::new(0.0, 5.0),
    ];
    o.set_vertices(replacement.clone());
    assert_eq!(o.get_vertices().len(), 4);
}

#[test]
#[should_panic(expected = "Occluder vertex count must be 3..=256")]
fn occluder_set_vertices_invalid_panics() {
    let initial = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(1.0, 0.0),
        Vec2::new(0.5, 1.0),
    ];
    let mut o = Occluder::new(initial);
    o.set_vertices(vec![Vec2::new(0.0, 0.0)]);
}

#[test]
fn occluder_set_get_position() {
    let verts = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(1.0, 0.0),
        Vec2::new(0.5, 1.0),
    ];
    let mut o = Occluder::new(verts);
    o.set_position(Vec2::new(100.0, -50.0));
    let pos = o.get_position();
    assert!((pos.x - 100.0).abs() < 1e-5);
    assert!((pos.y - (-50.0)).abs() < 1e-5);
}

#[test]
fn occluder_set_get_opacity() {
    let verts = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(1.0, 0.0),
        Vec2::new(0.5, 1.0),
    ];
    let mut o = Occluder::new(verts);
    o.set_opacity(0.5);
    assert!((o.get_opacity() - 0.5).abs() < 1e-5);
}

#[test]
fn occluder_set_get_light_mask() {
    let verts = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(1.0, 0.0),
        Vec2::new(0.5, 1.0),
    ];
    let mut o = Occluder::new(verts);
    o.set_light_mask(0x000F);
    assert_eq!(o.get_light_mask(), 0x000F);
}

#[test]
fn occluder_set_get_enabled() {
    let verts = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(1.0, 0.0),
        Vec2::new(0.5, 1.0),
    ];
    let mut o = Occluder::new(verts);
    assert!(o.is_enabled());
    o.set_enabled(false);
    assert!(!o.is_enabled());
}

// ── LightWorld Construction ───────────────────────────────────────────────────

#[test]
fn light_world_new_defaults() {
    let w = LightWorld::new();
    let a = w.ambient;
    assert!((a.r - 0.1).abs() < 1e-5);
    assert!((a.g - 0.1).abs() < 1e-5);
    assert!((a.b - 0.1).abs() < 1e-5);
    assert!((a.a - 1.0).abs() < 1e-5);
    assert!(!w.enabled);
    assert_eq!(w.light_count(), 0);
    assert_eq!(w.occluder_count(), 0);
    assert_eq!(w.max_lights, 64);
}

// ── LightWorld Add/Remove ─────────────────────────────────────────────────────

#[test]
fn light_world_add_light_returns_key() {
    let mut w = LightWorld::new();
    let key = w.add_light(Light2D::new(0.0, 0.0, 50.0));
    assert!(w.get_light(key).is_some());
    assert_eq!(w.light_count(), 1);
}

#[test]
fn light_world_auto_enables_on_first_light() {
    let mut w = LightWorld::new();
    assert!(!w.enabled);
    w.add_light(Light2D::new(0.0, 0.0, 50.0));
    assert!(w.enabled);
}

#[test]
fn light_world_add_occluder() {
    let mut w = LightWorld::new();
    let verts = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(1.0, 0.0),
        Vec2::new(0.5, 1.0),
    ];
    let key = w.add_occluder(Occluder::new(verts));
    assert!(w.get_occluder(key).is_some());
    assert_eq!(w.occluder_count(), 1);
}

#[test]
fn light_world_remove_light() {
    let mut w = LightWorld::new();
    let key = w.add_light(Light2D::new(0.0, 0.0, 50.0));
    assert_eq!(w.light_count(), 1);
    let removed = w.remove_light(key);
    assert!(removed.is_some());
    assert_eq!(w.light_count(), 0);
}

#[test]
fn light_world_remove_nonexistent_returns_none() {
    let mut w = LightWorld::new();
    let key = w.add_light(Light2D::new(0.0, 0.0, 50.0));
    w.remove_light(key);
    // Removing the same key again should return None.
    assert!(w.remove_light(key).is_none());
}

#[test]
fn light_world_get_light_mut() {
    let mut w = LightWorld::new();
    let key = w.add_light(Light2D::new(0.0, 0.0, 50.0));
    if let Some(l) = w.get_light_mut(key) {
        l.set_radius(999.0);
    }
    let l = w.get_light(key).unwrap();
    assert!((l.get_radius() - 999.0).abs() < 1e-5);
}

#[test]
fn light_world_light_count_occluder_count() {
    let mut w = LightWorld::new();
    w.add_light(Light2D::new(0.0, 0.0, 50.0));
    w.add_light(Light2D::new(1.0, 1.0, 30.0));
    assert_eq!(w.light_count(), 2);

    let tri = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(1.0, 0.0),
        Vec2::new(0.5, 1.0),
    ];
    w.add_occluder(Occluder::new(tri.clone()));
    w.add_occluder(Occluder::new(tri));
    assert_eq!(w.occluder_count(), 2);
}

#[test]
fn light_world_clear_resets_all() {
    let mut w = LightWorld::new();
    w.add_light(Light2D::new(0.0, 0.0, 50.0));
    let tri = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(1.0, 0.0),
        Vec2::new(0.5, 1.0),
    ];
    w.add_occluder(Occluder::new(tri));
    w.ambient = Color::new(1.0, 1.0, 1.0, 1.0);

    w.clear();

    assert_eq!(w.light_count(), 0);
    assert_eq!(w.occluder_count(), 0);
    assert!((w.ambient.r - 0.1).abs() < 1e-5);
    assert!((w.ambient.g - 0.1).abs() < 1e-5);
    assert!((w.ambient.b - 0.1).abs() < 1e-5);
    assert!((w.ambient.a - 1.0).abs() < 1e-5);
}

// ── LightWorld Active Lights ──────────────────────────────────────────────────

#[test]
fn light_world_has_active_lights_true() {
    let mut w = LightWorld::new();
    w.add_light(Light2D::new(0.0, 0.0, 50.0));
    assert!(w.has_active_lights());
}

#[test]
fn light_world_has_active_lights_false_all_disabled() {
    let mut w = LightWorld::new();
    let key = w.add_light(Light2D::new(0.0, 0.0, 50.0));
    w.get_light_mut(key).unwrap().set_enabled(false);
    assert!(!w.has_active_lights());
}

#[test]
fn light_world_has_active_lights_false_empty() {
    let w = LightWorld::new();
    assert!(!w.has_active_lights());
}

// ── LightType Enum ────────────────────────────────────────────────────────────

#[test]
fn light_type_default_is_point() {
    assert_eq!(LightType::default(), LightType::Point);
}

#[test]
fn light_type_variants_distinct() {
    assert_ne!(LightType::Point, LightType::Directional);
    assert_ne!(LightType::Directional, LightType::Spot);
    assert_ne!(LightType::Point, LightType::Spot);
}

// ── Attenuation ───────────────────────────────────────────────────────────────

#[test]
fn attenuation_default_no_decay() {
    let a = Attenuation::default();
    assert!((a.constant - 1.0).abs() < 1e-5);
    assert!((a.linear - 0.0).abs() < 1e-5);
    assert!((a.quadratic - 0.0).abs() < 1e-5);
}

#[test]
fn attenuation_new_stores_values() {
    let a = Attenuation::new(1.0, 0.09, 0.032);
    assert!((a.constant - 1.0).abs() < 1e-5);
    assert!((a.linear - 0.09).abs() < 1e-5);
    assert!((a.quadratic - 0.032).abs() < 1e-5);
}

#[test]
fn attenuation_factor_at_zero() {
    let a = Attenuation::new(1.0, 0.1, 0.01);
    assert!((a.factor(0.0) - 1.0).abs() < 1e-5);
}

#[test]
fn attenuation_factor_at_distance() {
    let a = Attenuation::new(1.0, 0.0, 0.01);
    // at d=10: 1/(1 + 0 + 0.01*100) = 1/2 = 0.5
    assert!((a.factor(10.0) - 0.5).abs() < 1e-5);
}

#[test]
fn attenuation_factor_zero_denom_returns_one() {
    let a = Attenuation::new(0.0, 0.0, 0.0);
    assert!((a.factor(5.0) - 1.0).abs() < 1e-5);
}

// ── FlickerConfig ─────────────────────────────────────────────────────────────

#[test]
fn flicker_default_disabled() {
    let f = FlickerConfig::default();
    assert!(!f.enabled);
    assert!((f.speed - 8.0).abs() < 1e-5);
    assert!((f.strength - 0.15).abs() < 1e-5);
    assert!((f.phase - 0.0).abs() < 1e-5);
}

#[test]
fn flicker_new_enabled() {
    let f = FlickerConfig::new(10.0, 0.2);
    assert!(f.enabled);
    assert!((f.speed - 10.0).abs() < 1e-5);
    assert!((f.strength - 0.2).abs() < 1e-5);
}

#[test]
fn flicker_multiplier_disabled_is_one() {
    let f = FlickerConfig::default();
    assert!((f.multiplier() - 1.0).abs() < 1e-5);
}

#[test]
fn flicker_multiplier_enabled_at_zero_phase() {
    let f = FlickerConfig::new(8.0, 0.15);
    // sin(0) = 0, so multiplier = 1.0
    assert!((f.multiplier() - 1.0).abs() < 1e-5);
}

#[test]
fn flicker_advance_adds_phase() {
    let mut f = FlickerConfig::new(10.0, 0.15);
    f.advance(0.1);
    // phase = 10.0 * 0.1 = 1.0
    assert!((f.phase - 1.0).abs() < 1e-5);
}

#[test]
fn flicker_advance_wraps_phase() {
    let mut f = FlickerConfig::new(100.0, 0.15);
    f.advance(1.0);
    // phase = 100.0, should wrap below TAU (6.28...)
    assert!(f.phase < std::f32::consts::TAU);
}

#[test]
fn flicker_advance_no_op_when_disabled() {
    let mut f = FlickerConfig::default();
    f.advance(1.0);
    assert!((f.phase - 0.0).abs() < 1e-5);
}

// ── Light2D New Fields ────────────────────────────────────────────────────────

#[test]
fn light2d_new_has_default_new_fields() {
    let l = Light2D::new(0.0, 0.0, 50.0);
    assert_eq!(l.get_light_type(), LightType::Point);
    assert!((l.get_direction() - 0.0).abs() < 1e-5);
    assert!((l.get_inner_angle() - std::f32::consts::FRAC_PI_6).abs() < 1e-5);
    assert!((l.get_outer_angle() - std::f32::consts::FRAC_PI_4).abs() < 1e-5);
    assert!((l.get_attenuation().constant - 1.0).abs() < 1e-5);
    assert!(!l.flicker().enabled);
    assert_eq!(l.get_group_id(), 0);
    assert!(!l.is_volumetric());
}

#[test]
fn light2d_set_get_light_type() {
    let mut l = Light2D::new(0.0, 0.0, 50.0);
    l.set_light_type(LightType::Spot);
    assert_eq!(l.get_light_type(), LightType::Spot);
    l.set_light_type(LightType::Directional);
    assert_eq!(l.get_light_type(), LightType::Directional);
}

#[test]
fn light2d_set_get_direction() {
    let mut l = Light2D::new(0.0, 0.0, 50.0);
    l.set_direction(1.57);
    assert!((l.get_direction() - 1.57).abs() < 1e-5);
}

#[test]
fn light2d_set_get_inner_outer_angle() {
    let mut l = Light2D::new(0.0, 0.0, 50.0);
    l.set_inner_angle(0.3);
    l.set_outer_angle(0.6);
    assert!((l.get_inner_angle() - 0.3).abs() < 1e-5);
    assert!((l.get_outer_angle() - 0.6).abs() < 1e-5);
}

#[test]
fn light2d_set_get_attenuation() {
    let mut l = Light2D::new(0.0, 0.0, 50.0);
    l.set_attenuation(Attenuation::new(1.0, 0.09, 0.032));
    let a = l.get_attenuation();
    assert!((a.constant - 1.0).abs() < 1e-5);
    assert!((a.linear - 0.09).abs() < 1e-5);
    assert!((a.quadratic - 0.032).abs() < 1e-5);
}

#[test]
fn light2d_flicker_mut_sets_values() {
    let mut l = Light2D::new(0.0, 0.0, 50.0);
    let f = l.flicker_mut();
    f.enabled = true;
    f.speed = 12.0;
    f.strength = 0.25;
    assert!(l.flicker().enabled);
    assert!((l.flicker().speed - 12.0).abs() < 1e-5);
    assert!((l.flicker().strength - 0.25).abs() < 1e-5);
}

#[test]
fn light2d_set_get_group_id() {
    let mut l = Light2D::new(0.0, 0.0, 50.0);
    l.set_group_id(42);
    assert_eq!(l.get_group_id(), 42);
}

#[test]
fn light2d_set_get_volumetric() {
    let mut l = Light2D::new(0.0, 0.0, 50.0);
    l.set_volumetric(true);
    assert!(l.is_volumetric());
    l.set_volumetric(false);
    assert!(!l.is_volumetric());
}

// ── LightWorld Group Operations ───────────────────────────────────────────────

#[test]
fn light_world_group_count() {
    let mut w = LightWorld::new();
    let k1 = w.add_light(Light2D::new(0.0, 0.0, 50.0));
    let k2 = w.add_light(Light2D::new(1.0, 1.0, 50.0));
    w.get_light_mut(k1).unwrap().set_group_id(1);
    w.get_light_mut(k2).unwrap().set_group_id(1);
    w.add_light(Light2D::new(2.0, 2.0, 50.0)); // group 0

    assert_eq!(w.group_count(1), 2);
    assert_eq!(w.group_count(0), 1);
    assert_eq!(w.group_count(99), 0);
}

#[test]
fn light_world_set_group_enabled() {
    let mut w = LightWorld::new();
    let k1 = w.add_light(Light2D::new(0.0, 0.0, 50.0));
    let k2 = w.add_light(Light2D::new(1.0, 1.0, 50.0));
    w.get_light_mut(k1).unwrap().set_group_id(1);
    w.get_light_mut(k2).unwrap().set_group_id(1);
    let k3 = w.add_light(Light2D::new(2.0, 2.0, 50.0)); // group 0

    w.set_group_enabled(1, false);
    assert!(!w.get_light(k1).unwrap().is_enabled());
    assert!(!w.get_light(k2).unwrap().is_enabled());
    assert!(w.get_light(k3).unwrap().is_enabled()); // unaffected
}

#[test]
fn light_world_set_group_intensity() {
    let mut w = LightWorld::new();
    let k1 = w.add_light(Light2D::new(0.0, 0.0, 50.0));
    w.get_light_mut(k1).unwrap().set_group_id(5);

    w.set_group_intensity(5, 0.5);
    assert!((w.get_light(k1).unwrap().get_intensity() - 0.5).abs() < 1e-5);
}

#[test]
fn light_world_set_group_color() {
    let mut w = LightWorld::new();
    let k1 = w.add_light(Light2D::new(0.0, 0.0, 50.0));
    w.get_light_mut(k1).unwrap().set_group_id(3);

    let red = Color::new(1.0, 0.0, 0.0, 1.0);
    w.set_group_color(3, red);
    assert_eq!(w.get_light(k1).unwrap().get_color(), red);
}

#[test]
fn light_world_advance_flickers() {
    let mut w = LightWorld::new();
    let k1 = w.add_light(Light2D::new(0.0, 0.0, 50.0));
    w.get_light_mut(k1).unwrap().flicker_mut().enabled = true;
    w.get_light_mut(k1).unwrap().flicker_mut().speed = 10.0;

    w.advance_flickers(0.1);
    assert!((w.get_light(k1).unwrap().flicker().phase - 1.0).abs() < 1e-5);
}
