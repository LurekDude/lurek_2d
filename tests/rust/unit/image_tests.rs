//! INTERNAL ONLY: Rust-only tests for image internals that are not exposed as `lurek.image.*`.

use lurek2d::image::*;
use lurek2d::render::renderer::RenderCommand;
use lurek2d::runtime::resource_keys::TextureKey;
use slotmap::KeyData;

// These tests stay in Rust because they cover render-only helpers and atlas
// internals that are not exposed as equivalent lurek.image.* assertions.

mod render_tests {
    use super::*;

    fn dummy_key() -> TextureKey {
        TextureKey::from(KeyData::from_ffi(1))
    }

    #[test]
    fn generate_render_commands_returns_one_draw_image() {
        let img = ImageData::new(64, 64);
        let cmds = img.generate_render_commands(dummy_key(), 0.0, 0.0);
        assert_eq!(cmds.len(), 1);
        assert!(matches!(cmds[0], RenderCommand::DrawImage { .. }));
    }

    #[test]
    fn generate_render_commands_position_embedded() {
        let img = ImageData::new(32, 32);
        let cmds = img.generate_render_commands(dummy_key(), 10.0, 20.0);
        if let RenderCommand::DrawImage { x, y, .. } = &cmds[0] {
            assert!((x - 10.0).abs() < f32::EPSILON);
            assert!((y - 20.0).abs() < f32::EPSILON);
        } else {
            panic!("expected DrawImage command");
        }
    }

    #[test]
    fn draw_to_image_preserves_dimensions() {
        let img = ImageData::new(128, 64);
        let copy = img.draw_to_image();
        assert_eq!(copy.width(), 128);
        assert_eq!(copy.height(), 64);
    }

    #[test]
    fn draw_to_image_preserves_pixels() {
        let mut img = ImageData::new(4, 4);
        img.set_pixel(2, 3, 255, 0, 128, 255);
        let copy = img.draw_to_image();
        assert_eq!(copy.get_pixel(2, 3), Some((255, 0, 128, 255)));
    }
}

mod texture_atlas_tests {
    use super::*;

    #[test]
    fn new_atlas_is_empty() {
        let atlas = TextureAtlas::new(256, 256, 1);
        assert_eq!(atlas.get_region_count(), 0);
        assert_eq!(atlas.get_dimensions(), (256, 256));
    }

    #[test]
    fn pack_single_region() {
        let mut atlas = TextureAtlas::new(128, 128, 0);
        assert!(atlas.pack("hero", 32, 32));
        assert_eq!(atlas.get_region_count(), 1);
        let region = atlas.get_region("hero").unwrap();
        assert_eq!(region.w, 32);
        assert_eq!(region.h, 32);
    }

    #[test]
    fn pack_multiple_regions_same_shelf() {
        let mut atlas = TextureAtlas::new(128, 128, 0);
        assert!(atlas.pack("a", 32, 32));
        assert!(atlas.pack("b", 32, 32));
        assert!(atlas.pack("c", 32, 32));
        assert_eq!(atlas.get_region_count(), 3);
    }

    #[test]
    fn pack_fails_when_full() {
        let mut atlas = TextureAtlas::new(32, 32, 0);
        assert!(atlas.pack("fits", 32, 32));
        assert!(!atlas.pack("nope", 32, 32));
    }

    #[test]
    fn pack_with_padding() {
        let mut atlas = TextureAtlas::new(128, 128, 2);
        assert!(atlas.pack("padded", 16, 16));
        let region = atlas.get_region("padded").unwrap();
        assert!(region.x >= 2);
        assert!(region.y >= 2);
    }

    #[test]
    fn get_region_returns_none_for_unknown() {
        let atlas = TextureAtlas::new(64, 64, 0);
        assert!(atlas.get_region("missing").is_none());
    }

    #[test]
    fn clear_resets_atlas() {
        let mut atlas = TextureAtlas::new(128, 128, 0);
        atlas.pack("x", 32, 32);
        atlas.pack("y", 32, 32);
        atlas.clear();
        assert_eq!(atlas.get_region_count(), 0);
        assert!(atlas.get_region("x").is_none());
    }

    #[test]
    fn pack_region_wider_than_atlas_fails() {
        let mut atlas = TextureAtlas::new(64, 64, 0);
        assert!(!atlas.pack("too_wide", 128, 16));
    }

    #[test]
    fn get_regions_returns_all() {
        let mut atlas = TextureAtlas::new(256, 256, 0);
        atlas.pack("a", 16, 16);
        atlas.pack("b", 16, 16);
        let all = atlas.get_regions();
        assert_eq!(all.len(), 2);
    }
}

mod visualization_tests {
    use lurek2d::animation::Animation;
    use lurek2d::image::visualization::draw_animation_frame_grid_to_image;
    use lurek2d::math::Rect;

    fn make_anim_with_frames(count: usize) -> Animation {
        let mut anim = Animation::new();
        for _ in 0..count {
            anim.add_frame(Rect::new(0.0, 0.0, 16.0, 16.0));
        }
        anim
    }

    #[test]
    fn draw_animation_frame_grid_produces_correct_dimensions() {
        let anim = make_anim_with_frames(3);
        let img = draw_animation_frame_grid_to_image(&anim, 4, 4);
        assert_eq!(img.width(), 12);
        assert_eq!(img.height(), 4);
    }

    #[test]
    fn draw_animation_frame_grid_zero_frames_uses_one_cell() {
        let anim = make_anim_with_frames(0);
        let img = draw_animation_frame_grid_to_image(&anim, 8, 8);
        assert_eq!(img.width(), 8);
        assert_eq!(img.height(), 8);
    }
}
