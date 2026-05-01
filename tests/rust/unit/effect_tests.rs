//! INTERNAL ONLY: Rust-only tests for effect helpers that are not directly asserted through
//! `lurek.effect.*`.
//!
//! Public post-processing and effect control behaviour is covered by
//! `tests/lua/unit/test_effect_unit.lua`. The remaining Rust tests keep image
//! draw helpers, render-command generation, and lightweight weather structs.

use lurek2d::effect::stack::PostFxStack;
use lurek2d::effect::weather::WeatherParticle;
use lurek2d::render::renderer::RenderCommand;

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

// ── weather tests ───────────────────────────────────────────────────────────

mod weather_tests {
    use super::*;

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
