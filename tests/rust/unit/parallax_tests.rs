//! INTERNAL ONLY: Rust-only tests for parallax render helpers that are not directly asserted
//! through `lurek.parallax.*`.
//!
//! Public parallax-layer behaviour is covered by `tests/lua/unit/test_parallax_unit.lua`.
//! The remaining Rust tests keep draw-batch to render-command translation and
//! image helper invariants.

use lurek2d::parallax::layer::ParallaxDrawBatch;
use lurek2d::parallax::render::batch_to_render_commands;
use lurek2d::parallax::ParallaxLayer;
use lurek2d::render::renderer::RenderCommand;
use lurek2d::render::BlendMode;
use lurek2d::render::ShaderPassDescriptor;
use lurek2d::runtime::resource_keys::TextureKey;
use slotmap::KeyData;

fn dummy_key() -> TextureKey {
    TextureKey::from(KeyData::from_ffi(1))
}

// ── render ────────────────────────────────────────────────────────────────────

mod render_tests {
    use super::*;

    #[test]
    fn invisible_layer_produces_empty_commands() {
        let mut layer = ParallaxLayer::new(dummy_key(), 256.0, 256.0);
        layer.visible = false;
        let cmds = layer.generate_render_commands(0.0, 0.0, 800.0, 600.0);
        assert!(cmds.is_empty());
    }

    #[test]
    fn visible_layer_produces_draw_image_ex_commands() {
        let layer = ParallaxLayer::new(dummy_key(), 256.0, 256.0);
        let cmds = layer.generate_render_commands(0.0, 0.0, 800.0, 600.0);
        // Should have: SetColor + SetBlendMode + N DrawImageEx tiles
        assert!(
            cmds.len() >= 3,
            "Expected at least 3 commands, got {}",
            cmds.len()
        );
        // First is SetColor
        assert!(matches!(cmds[0], RenderCommand::SetColor(..)));
        // Second is SetBlendMode
        assert!(matches!(cmds[1], RenderCommand::SetBlendMode(_)));
        // Rest are DrawImageEx
        for cmd in &cmds[2..] {
            assert!(matches!(cmd, RenderCommand::DrawImageEx { .. }));
        }
    }

    #[test]
    fn batch_to_commands_preserves_tile_positions() {
        let batch = ParallaxDrawBatch {
            texture_key: dummy_key(),
            tiles: vec![(10.0, 20.0), (266.0, 20.0)],
            sx: 1.0,
            sy: 1.0,
            color: [1.0, 1.0, 1.0, 1.0],
            blend_mode: BlendMode::Alpha,
            effect: None,
        };
        let cmds = batch_to_render_commands(&batch);
        assert_eq!(cmds.len(), 4); // SetColor + SetBlendMode + 2 tiles
        if let RenderCommand::DrawImageEx { x, y, .. } = &cmds[2] {
            assert!((*x - 10.0).abs() < 1e-5);
            assert!((*y - 20.0).abs() < 1e-5);
        } else {
            panic!("Expected DrawImageEx");
        }
    }
}

// ── draw ──────────────────────────────────────────────────────────────────────

mod draw_tests {
    use super::*;

    #[test]
    fn draw_to_image_correct_dimensions() {
        let layer = ParallaxLayer::new(dummy_key(), 256.0, 256.0);
        let img = layer.draw_to_image(320, 240);
        assert_eq!(img.width(), 320);
        assert_eq!(img.height(), 240);
    }

    #[test]
    fn draw_to_image_invisible_layer_is_transparent() {
        let mut layer = ParallaxLayer::new(dummy_key(), 256.0, 256.0);
        layer.visible = false;
        let img = layer.draw_to_image(16, 16);
        if let Some((_, _, _, a)) = img.get_pixel(0, 0) {
            assert_eq!(a, 0, "invisible layer should be fully transparent");
        }
    }

    #[test]
    fn draw_to_image_uses_layer_tint() {
        let mut layer = ParallaxLayer::new(dummy_key(), 256.0, 256.0);
        layer.tint = [1.0, 0.0, 0.5, 1.0];
        layer.opacity = 1.0;
        let img = layer.draw_to_image(16, 16);
        if let Some((r, g, _, _)) = img.get_pixel(0, 0) {
            assert!(r > 200, "expected high red channel from tint");
            assert!(g < 10, "expected zero green channel from tint");
        }
    }
}

// ── layer ─────────────────────────────────────────────────────────────────────

mod layer_tests {
    use super::*;

    #[test]
    fn build_draw_calls_respects_custom_tile_size() {
        let mut layer = ParallaxLayer::new(dummy_key(), 100.0, 50.0);
        layer.repeat_x = true;
        layer.repeat_y = false;
        layer.set_tile_size(200.0, 120.0);

        let batch = layer
            .build_draw_calls(0.0, 0.0, 450.0, 200.0)
            .expect("batch should exist for visible layer");

        assert!(
            (batch.sx - 2.0).abs() < 1e-5,
            "expected sx=2.0, got {}",
            batch.sx
        );
        assert!(
            (batch.sy - 2.4).abs() < 1e-5,
            "expected sy=2.4, got {}",
            batch.sy
        );
        assert!(
            batch.tiles.len() >= 3,
            "expected at least three horizontal tiles"
        );

        let has_0 = batch.tiles.iter().any(|(x, _)| (*x - 0.0).abs() < 1e-5);
        let has_200 = batch.tiles.iter().any(|(x, _)| (*x - 200.0).abs() < 1e-5);
        let has_400 = batch.tiles.iter().any(|(x, _)| (*x - 400.0).abs() < 1e-5);
        assert!(has_0, "expected a tile at x=0");
        assert!(has_200, "expected a tile at x=200");
        assert!(has_400, "expected a tile at x=400");
    }

    #[test]
    fn build_draw_calls_tiling_overrides_repeat_flags_in_both_axes() {
        let mut layer = ParallaxLayer::new(dummy_key(), 64.0, 64.0);
        layer.repeat_x = false;
        layer.repeat_y = false;
        layer.set_tiling(true);

        let batch = layer
            .build_draw_calls(0.0, 0.0, 128.0, 128.0)
            .expect("batch should exist for visible layer");

        assert!(batch.tiles.len() >= 4, "expected 2D tiling coverage");

        let mut has_second_x = false;
        let mut has_second_y = false;
        for &(x, y) in &batch.tiles {
            if (x - 64.0).abs() < 1e-5 {
                has_second_x = true;
            }
            if (y - 64.0).abs() < 1e-5 {
                has_second_y = true;
            }
        }

        assert!(has_second_x, "expected at least one tile at x=64");
        assert!(has_second_y, "expected at least one tile at y=64");
    }

    #[test]
    fn build_draw_calls_applies_motion_stretch_from_autoscroll_speed() {
        let mut layer = ParallaxLayer::new(dummy_key(), 64.0, 64.0);
        layer.repeat_x = false;
        layer.repeat_y = false;
        layer.autoscroll = [500.0, 0.0];
        layer.set_motion_stretch(true, 0.001, 1.8);

        let batch = layer
            .build_draw_calls(0.0, 0.0, 128.0, 128.0)
            .expect("batch should exist");

        assert!(batch.sx > 1.0, "sx should be stretched by velocity");
        assert!(batch.sy >= 1.0, "sy should remain valid");
    }

    #[test]
    fn build_draw_calls_keeps_effect_chain() {
        let mut layer = ParallaxLayer::new(dummy_key(), 64.0, 64.0);
        layer.set_effect_chain(vec![ShaderPassDescriptor::new("blur")]);

        let batch = layer
            .build_draw_calls(0.0, 0.0, 128.0, 128.0)
            .expect("batch should exist");

        let effect = batch.effect.expect("effect chain should exist");
        assert_eq!(effect.len(), 1);
        assert_eq!(effect[0].effect_name, "blur");
    }
}
