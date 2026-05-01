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
