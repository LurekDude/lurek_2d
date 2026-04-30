//! Tests for the effect module.

use lurek2d::effect::ambient::AmbientState;
use lurek2d::effect::atmosphere::{
    CloudState, FilmGrainState, FogState, HeatHazeState, LightningState, VignetteState,
};
use lurek2d::effect::effect::PostFxEffect;
use lurek2d::effect::effect_type::PostFxEffectType;
use lurek2d::effect::overlay::Overlay;
use lurek2d::effect::presets::{build_preset, preset_names};
use lurek2d::effect::screen_effects::{FadeState, FlashState, ShakeState};
use lurek2d::effect::stack::PostFxStack;
use lurek2d::effect::transition::{ScreenTransition, TransitionKind};
use lurek2d::effect::water_overlay::WaterOverlayState;
use lurek2d::effect::weather::{WeatherParticle, WeatherState, WeatherType};
use lurek2d::render::renderer::RenderCommand;

// ── ambient tests ───────────────────────────────────────────────────────────

mod ambient_tests {
    use super::*;

    #[test]
    fn default_is_disabled_white_noon() {
        let a = AmbientState::default();
        assert!(!a.enabled);
        assert!((a.time_of_day - 12.0).abs() < 1e-6);
        assert!((a.color[0] - 1.0).abs() < 1e-6);
    }

    #[test]
    fn night_is_dark_blue() {
        let mut a = AmbientState::default();
        a.time_of_day = 2.0;
        let c = a.compute_color_from_time();
        assert!(c[0] < 0.2, "red should be low at night");
        assert!(c[2] > c[0], "blue should dominate at night");
    }

    #[test]
    fn midday_is_bright() {
        let mut a = AmbientState::default();
        a.time_of_day = 12.0;
        let c = a.compute_color_from_time();
        assert!(c[0] > 0.8, "red should be high during day");
    }

    #[test]
    fn wraps_past_24() {
        let mut a = AmbientState::default();
        a.time_of_day = 26.0;
        let c = a.compute_color_from_time();
        assert!(c[0] < 0.2);
    }
}

// ── atmosphere tests ────────────────────────────────────────────────────────

mod atmosphere_tests {
    use super::*;

    #[test]
    fn cloud_default_is_disabled() {
        let c = CloudState::default();
        assert!(!c.enabled);
        assert_eq!(c.count, 5);
    }

    #[test]
    fn fog_default_is_disabled() {
        let f = FogState::default();
        assert!(!f.enabled);
        assert!((f.density - 0.3).abs() < 1e-6);
    }

    #[test]
    fn heat_haze_default_is_disabled() {
        let h = HeatHazeState::default();
        assert!(!h.enabled);
        assert!((h.intensity - 0.5).abs() < 1e-6);
    }

    #[test]
    fn vignette_default_is_disabled() {
        let v = VignetteState::default();
        assert!(!v.enabled);
        assert!((v.strength - 0.5).abs() < 1e-6);
    }

    #[test]
    fn film_grain_default_is_disabled() {
        let f = FilmGrainState::default();
        assert!(!f.enabled);
        assert!((f.intensity - 0.3).abs() < 1e-6);
    }

    #[test]
    fn lightning_default_is_inactive() {
        let l = LightningState::default();
        assert!(!l.active);
        assert!((l.duration - 0.15).abs() < 1e-6);
    }
}

// ── draw tests ──────────────────────────────────────────────────────────────

mod draw_tests {
    use super::*;

    #[test]
    fn draw_to_image_correct_dimensions() {
        let stack = PostFxStack::new(800, 600);
        let img = stack.draw_to_image(320, 240);
        assert_eq!(img.width(), 320);
        assert_eq!(img.height(), 240);
    }

    #[test]
    fn draw_to_image_empty_stack_is_dark() {
        let stack = PostFxStack::new(800, 600);
        let img = stack.draw_to_image(16, 16);
        if let Some((r, g, b, _)) = img.get_pixel(0, 0) {
            assert!(r < 30 && g < 30 && b < 30, "empty stack should be dark");
        }
    }

    #[test]
    fn draw_to_image_enabled_stack_is_tinted() {
        let mut stack = PostFxStack::new(800, 600);
        stack.add(0);
        let img = stack.draw_to_image(16, 16);
        if let Some((_, _, b, _)) = img.get_pixel(0, 0) {
            assert!(b > 30, "enabled stack should have visible violet tint");
        }
    }
}

// ── effect tests ────────────────────────────────────────────────────────────

mod effect_tests {
    use super::*;

    #[test]
    fn new_bloom_has_default_params() {
        let e = PostFxEffect::new(PostFxEffectType::Bloom);
        assert!(e.enabled);
        assert!(e.has_parameter("threshold"));
        assert!(e.has_parameter("intensity"));
        assert!(e.shader_id.is_none());
    }

    #[test]
    fn new_custom_has_shader_id() {
        let e = PostFxEffect::new_custom(42);
        assert_eq!(e.shader_id, Some(42));
        assert_eq!(e.effect_type, PostFxEffectType::Custom);
        assert!(e.params.is_empty());
    }

    #[test]
    fn set_parameter_inserts_and_overwrites() {
        let mut e = PostFxEffect::new(PostFxEffectType::Blur);
        e.set_parameter("radius", 5.0);
        assert!((e.get_parameter("radius", 0.0) - 5.0).abs() < 1e-6);
    }

    #[test]
    fn get_parameter_returns_default_when_missing() {
        let e = PostFxEffect::new(PostFxEffectType::Bloom);
        assert!((e.get_parameter("nonexistent", 99.0) - 99.0).abs() < 1e-6);
    }

    #[test]
    fn get_type_name_matches_effect() {
        let e = PostFxEffect::new(PostFxEffectType::Crt);
        assert_eq!(e.get_type_name(), "crt");
    }

    #[test]
    fn is_built_in_true_for_named_types() {
        let e = PostFxEffect::new(PostFxEffectType::Sepia);
        assert!(e.is_built_in());
    }

    #[test]
    fn is_built_in_false_for_custom() {
        let e = PostFxEffect::new_custom(0);
        assert!(!e.is_built_in());
    }

    #[test]
    fn new_disabled_starts_off() {
        let e = PostFxEffect::new_disabled(PostFxEffectType::Bloom);
        assert!(!e.enabled);
    }

    #[test]
    fn get_parameter_names_sorted() {
        let e = PostFxEffect::new(PostFxEffectType::ColourGrade);
        let names = e.get_parameter_names();
        let mut sorted = names.clone();
        sorted.sort();
        assert_eq!(names, sorted);
    }
}

// ── effect_type tests ───────────────────────────────────────────────────────

mod effect_type_tests {
    use super::*;

    #[test]
    fn from_name_round_trips_all_built_ins() {
        let names = [
            "bloom",
            "blur",
            "crt",
            "godrays",
            "vignette",
            "colourgrade",
            "chromatic",
            "pixelate",
            "sepia",
            "grayscale",
            "invert",
            "scanlines",
            "edgedetect",
            "hueshift",
            "noise",
            "depthoffield",
            "motionblur",
            "paletteswap",
            "colorlut",
            "waterdistort",
            "sharpen",
            "dither",
            "outline",
        ];
        for n in names {
            let t = PostFxEffectType::from_name(n);
            assert!(t.is_some(), "from_name({}) returned None", n);
            assert_eq!(t.unwrap().name(), n);
        }
    }

    #[test]
    fn from_name_returns_none_for_unknown() {
        assert!(PostFxEffectType::from_name("foobar").is_none());
    }

    #[test]
    fn default_params_bloom_has_threshold_and_intensity() {
        let p = PostFxEffectType::Bloom.default_params();
        assert!(p.contains_key("threshold"));
        assert!(p.contains_key("intensity"));
    }

    #[test]
    fn default_params_custom_is_empty() {
        let p = PostFxEffectType::Custom.default_params();
        assert!(p.is_empty());
    }
}

// ── overlay tests ───────────────────────────────────────────────────────────

mod overlay_tests {
    use super::*;

    #[test]
    fn new_overlay_is_inactive() {
        let o = Overlay::new(800, 600);
        assert!(!o.is_active());
        assert_eq!(o.get_dimensions(), (800, 600));
    }

    #[test]
    fn trigger_flash_activates() {
        let mut o = Overlay::new(800, 600);
        o.trigger_flash(1.0, 0.0, 0.0, 1.0, 0.5);
        assert!(o.flash.active);
        assert!(o.get_flash_alpha() > 0.0);
    }

    #[test]
    fn flash_decays_over_time() {
        let mut o = Overlay::new(800, 600);
        o.trigger_flash(1.0, 1.0, 1.0, 1.0, 1.0);
        let a0 = o.get_flash_alpha();
        o.update(0.5);
        let a1 = o.get_flash_alpha();
        assert!(a1 < a0, "flash alpha should decay");
    }

    #[test]
    fn trigger_shake_produces_offset() {
        let mut o = Overlay::new(800, 600);
        o.trigger_shake(10.0, 0.5);
        o.update(0.1);
        let (x, y) = o.get_shake_offset();
        assert!(x.abs() > 0.0 || y.abs() > 0.0);
    }

    #[test]
    fn shake_zeros_out_after_duration() {
        let mut o = Overlay::new(800, 600);
        o.trigger_shake(10.0, 0.2);
        o.update(0.3);
        assert!(!o.shake.active);
        assert!((o.shake.offset_x).abs() < 1e-6);
        assert!((o.shake.offset_y).abs() < 1e-6);
    }

    #[test]
    fn trigger_fade_activates() {
        let mut o = Overlay::new(800, 600);
        o.trigger_fade(0.0, 0.0, 0.0, 1.0, 1.0);
        assert!(o.fade.active);
    }

    #[test]
    fn fade_completes_at_target_alpha() {
        let mut o = Overlay::new(800, 600);
        o.trigger_fade(0.0, 0.0, 0.0, 0.8, 0.5);
        o.update(0.6);
        assert!(!o.fade.active);
        assert!((o.fade.color[3] - 0.8).abs() < 1e-4);
    }

    #[test]
    fn trigger_lightning_activates() {
        let mut o = Overlay::new(800, 600);
        o.trigger_lightning();
        assert!(o.lightning.active);
        assert!(o.get_lightning_alpha() > 0.0);
    }

    #[test]
    fn clear_resets_all_subsystems() {
        let mut o = Overlay::new(800, 600);
        o.trigger_flash(1.0, 0.0, 0.0, 1.0, 0.5);
        o.trigger_shake(10.0, 0.5);
        o.trigger_lightning();
        o.clear();
        assert!(!o.is_active());
    }

    #[test]
    fn resize_updates_dimensions() {
        let mut o = Overlay::new(800, 600);
        o.resize(1920, 1080);
        assert_eq!(o.get_dimensions(), (1920, 1080));
    }

    #[test]
    fn is_active_reflects_subsystems() {
        let mut o = Overlay::new(800, 600);
        assert!(!o.is_active());
        o.ambient.enabled = true;
        assert!(o.is_active());
    }

    #[test]
    fn ambient_color_auto_updates_when_enabled() {
        let mut o = Overlay::new(800, 600);
        o.ambient.enabled = true;
        o.ambient.time_of_day = 2.0;
        o.update(0.0);
        assert!(o.ambient.color[0] < 0.2);
    }
}

// ── presets tests ───────────────────────────────────────────────────────────

mod presets_tests {
    use super::*;

    #[test]
    fn preset_names_are_non_empty() {
        let names = preset_names();
        assert!(!names.is_empty());
        assert!(names.contains(&"retro_tv"));
        assert!(names.contains(&"horror"));
    }

    #[test]
    fn build_preset_returns_none_for_unknown() {
        assert!(build_preset("nonexistent", 800, 600).is_none());
    }

    #[test]
    fn build_preset_retro_tv_has_effects() {
        let p = build_preset("retro_tv", 800, 600).unwrap();
        assert!(!p.effects.is_empty());
        assert_eq!(p.name, "retro_tv");
        assert_eq!(p.stack.get_effect_count(), p.effects.len());
    }

    #[test]
    fn all_named_presets_build_successfully() {
        for name in preset_names() {
            let p = build_preset(name, 640, 480);
            assert!(p.is_some(), "preset '{}' should build", name);
        }
    }
}

// ── render tests ────────────────────────────────────────────────────────────

mod render_tests {
    use super::*;

    #[test]
    fn empty_stack_produces_no_commands() {
        let stack = PostFxStack::new(800, 600);
        let cmds = stack.generate_render_commands(1);
        assert!(cmds.is_empty());
    }

    #[test]
    fn stack_with_disabled_effects_produces_no_commands() {
        let mut stack = PostFxStack::new(800, 600);
        stack.add(0);
        stack.set_enabled(0, false);
        let cmds = stack.generate_render_commands(1);
        assert!(cmds.is_empty());
    }

    #[test]
    fn stack_with_enabled_effects_produces_three_commands() {
        let mut stack = PostFxStack::new(800, 600);
        stack.add(0);
        stack.add(1);
        let cmds = stack.generate_render_commands(1);
        assert_eq!(cmds.len(), 3);
        assert!(matches!(cmds[0], RenderCommand::BeginPostFx { .. }));
        assert!(matches!(cmds[1], RenderCommand::EndPostFx { .. }));
        assert!(matches!(cmds[2], RenderCommand::ApplyPostFx { .. }));
    }

    #[test]
    fn begin_capture_uses_stack_id() {
        let stack = PostFxStack::new(800, 600);
        let cmd = stack.begin_capture_command(42);
        if let RenderCommand::BeginPostFx { stack_id } = cmd {
            assert_eq!(stack_id, 42);
        } else {
            panic!("Expected BeginPostFx");
        }
    }
}

// ── screen_effects tests ────────────────────────────────────────────────────

mod screen_effects_tests {
    use super::*;

    #[test]
    fn flash_default_is_inactive() {
        let f = FlashState::default();
        assert!(!f.active);
        assert!((f.duration - 0.2).abs() < 1e-6);
    }

    #[test]
    fn shake_default_is_inactive() {
        let s = ShakeState::default();
        assert!(!s.active);
        assert!((s.offset_x).abs() < 1e-6);
        assert!((s.offset_y).abs() < 1e-6);
    }

    #[test]
    fn shake_produces_non_zero_offset() {
        // ShakeState::next_random() is internal; test via observable Overlay API
        let mut o = Overlay::new(800, 600);
        o.trigger_shake(10.0, 0.5);
        o.update(0.1);
        let (x, y) = o.get_shake_offset();
        assert!(
            x.abs() > 0.0 || y.abs() > 0.0,
            "shake should produce offset"
        );
    }

    #[test]
    fn fade_default_is_inactive() {
        let f = FadeState::default();
        assert!(!f.active);
        assert!((f.color[3]).abs() < 1e-6);
    }
}

// ── stack tests ─────────────────────────────────────────────────────────────

mod stack_tests {
    use super::*;

    #[test]
    fn new_stack_is_empty() {
        let s = PostFxStack::new(800, 600);
        assert!(s.is_empty());
        assert_eq!(s.len(), 0);
        assert!(!s.capturing);
    }

    #[test]
    fn add_and_len() {
        let mut s = PostFxStack::new(800, 600);
        s.add(0);
        s.add(1);
        assert_eq!(s.len(), 2);
        assert!(!s.is_empty());
    }

    #[test]
    fn remove_returns_true_when_present() {
        let mut s = PostFxStack::new(800, 600);
        s.add(5);
        assert!(s.remove(5));
        assert!(s.is_empty());
    }

    #[test]
    fn remove_returns_false_when_absent() {
        let mut s = PostFxStack::new(800, 600);
        assert!(!s.remove(99));
    }

    #[test]
    fn insert_at_front() {
        let mut s = PostFxStack::new(800, 600);
        s.add(10);
        s.insert(1, 20);
        assert_eq!(s.get_effect(1), Some(20));
        assert_eq!(s.get_effect(2), Some(10));
    }

    #[test]
    fn set_enabled_toggles() {
        let mut s = PostFxStack::new(800, 600);
        s.add(0);
        assert!(s.is_enabled(0));
        s.set_enabled(0, false);
        assert!(!s.is_enabled(0));
    }

    #[test]
    fn enabled_effects_filters_disabled() {
        let mut s = PostFxStack::new(800, 600);
        s.add(0);
        s.add(1);
        s.set_enabled(0, false);
        let enabled = s.enabled_effects();
        assert_eq!(enabled, vec![1]);
    }

    #[test]
    fn resize_updates_dimensions() {
        let mut s = PostFxStack::new(800, 600);
        s.resize(1920, 1080);
        assert_eq!(s.get_dimensions(), (1920, 1080));
    }

    #[test]
    fn clear_empties_chain() {
        let mut s = PostFxStack::new(800, 600);
        s.add(0);
        s.add(1);
        s.clear();
        assert!(s.is_empty());
    }

    #[test]
    fn dedup_indices_removes_duplicates() {
        let mut s = PostFxStack::new(800, 600);
        s.add(0);
        s.add(1);
        s.add(0);
        let removed = s.dedup_indices();
        assert_eq!(removed, 1);
        assert_eq!(s.len(), 2);
    }

    #[test]
    fn get_effect_is_one_based() {
        let mut s = PostFxStack::new(800, 600);
        s.add(42);
        assert_eq!(s.get_effect(1), Some(42));
        assert_eq!(s.get_effect(0), None);
    }
}

// ── transition tests ────────────────────────────────────────────────────────

mod transition_tests {
    use super::*;

    #[test]
    fn transition_kind_from_str_defaults_to_fade() {
        assert_eq!(TransitionKind::from_str("unknown"), TransitionKind::Fade);
        assert_eq!(TransitionKind::from_str("fade"), TransitionKind::Fade);
    }

    #[test]
    fn transition_kind_round_trips() {
        for kind in [
            TransitionKind::Fade,
            TransitionKind::Wipe,
            TransitionKind::IrisWipe,
            TransitionKind::Dissolve,
        ] {
            let name = kind.name();
            let parsed = TransitionKind::from_str(name);
            assert_eq!(parsed, kind);
        }
    }

    #[test]
    fn screen_transition_starts_inactive() {
        let t = ScreenTransition::new(TransitionKind::Fade, 1.0, [0.0; 4]);
        assert!(!t.active);
        assert!(!t.is_done());
    }

    #[test]
    fn play_activates_and_progress_advances() {
        let mut t = ScreenTransition::new(TransitionKind::Wipe, 2.0, [0.0, 0.0, 0.0, 1.0]);
        t.play();
        assert!(t.is_active());
        assert!((t.progress()).abs() < 1e-6);
        t.update(1.0);
        assert!((t.progress() - 0.5).abs() < 1e-4);
    }

    #[test]
    fn reverse_flips_progress() {
        let mut t = ScreenTransition::new(TransitionKind::Fade, 2.0, [0.0; 4]);
        t.reverse();
        t.update(1.0);
        assert!((t.progress() - 0.5).abs() < 1e-4);
    }

    #[test]
    fn completes_after_duration() {
        let mut t = ScreenTransition::new(TransitionKind::Dissolve, 0.5, [0.0; 4]);
        t.play();
        t.update(0.6);
        assert!(!t.is_active());
        assert!(t.is_done());
    }
}

// ── water_overlay tests ─────────────────────────────────────────────────────

mod water_overlay_tests {
    use super::*;

    #[test]
    fn default_is_disabled() {
        let w = WaterOverlayState::default();
        assert!(!w.enabled);
        assert!((w.time).abs() < 1e-6);
    }

    #[test]
    fn update_advances_time_when_enabled() {
        let mut w = WaterOverlayState::new();
        w.enabled = true;
        w.speed = 2.0;
        w.update(0.5);
        assert!((w.time - 1.0).abs() < 1e-6);
    }

    #[test]
    fn update_does_nothing_when_disabled() {
        let mut w = WaterOverlayState::new();
        w.update(1.0);
        assert!((w.time).abs() < 1e-6);
    }

    #[test]
    fn reset_clears_all_state() {
        let mut w = WaterOverlayState::new();
        w.enabled = true;
        w.time = 42.0;
        w.amplitude = 0.1;
        w.reset();
        assert!(!w.enabled);
        assert!((w.time).abs() < 1e-6);
    }
}

// ── weather tests ───────────────────────────────────────────────────────────

mod weather_tests {
    use super::*;

    #[test]
    fn weather_type_from_name_round_trips() {
        for name in [
            "none", "rain", "snow", "hail", "dust", "leaves", "ash", "pollen",
        ] {
            let wt = WeatherType::from_name(name).unwrap();
            assert_eq!(wt.name(), name);
        }
    }

    #[test]
    fn weather_type_from_name_returns_none_for_unknown() {
        assert!(WeatherType::from_name("tornado").is_none());
    }

    #[test]
    fn weather_state_default_is_disabled() {
        let ws = WeatherState::default();
        assert!(!ws.enabled);
        assert_eq!(ws.weather_type, WeatherType::None);
        assert!(ws.particles.is_empty());
    }

    #[test]
    fn weather_particle_fields_accessible() {
        let p = WeatherParticle {
            x: 10.0,
            y: 20.0,
            vx: 1.0,
            vy: 5.0,
            size: 2.0,
            alpha: 0.8,
        };
        assert!((p.alpha - 0.8).abs() < 1e-6);
    }
}

// ── auto_uniforms tests ─────────────────────────────────────────────────────

mod auto_uniforms_tests {
    use super::*;

    #[test]
    fn post_fx_effect_auto_uniforms_default_false() {
        let fx = PostFxEffect::new(PostFxEffectType::Bloom);
        assert!(!fx.auto_uniforms);
    }

    #[test]
    fn post_fx_effect_new_custom_auto_uniforms_default_false() {
        let fx = PostFxEffect::new_custom(0);
        assert!(!fx.auto_uniforms);
    }

    #[test]
    fn post_fx_effect_auto_uniforms_set_true() {
        let mut fx = PostFxEffect::new_custom(0);
        fx.auto_uniforms = true;
        assert!(fx.auto_uniforms);
    }

    #[test]
    fn post_fx_effect_auto_uniforms_round_trip() {
        let mut fx = PostFxEffect::new_custom(42);
        fx.auto_uniforms = true;
        fx.auto_uniforms = false;
        assert!(!fx.auto_uniforms);
    }
}
