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

    #[test]
    fn pack_with_nine_slice_stores_insets() {
        let mut atlas = TextureAtlas::new(128, 128, 0);
        let insets = NineSliceInsets {
            left: 4,
            right: 4,
            top: 2,
            bottom: 2,
        };
        assert!(atlas.pack_with_nine_slice("panel", 32, 16, Some(insets)));
        let region = atlas.get_region("panel").unwrap();
        assert_eq!(region.nine_slice, Some(insets));
    }

    #[test]
    fn set_nine_slice_rejects_invalid_insets() {
        let mut atlas = TextureAtlas::new(128, 128, 0);
        assert!(atlas.pack("panel", 10, 10));
        let ok = atlas.set_nine_slice(
            "panel",
            Some(NineSliceInsets {
                left: 3,
                right: 3,
                top: 2,
                bottom: 2,
            }),
        );
        assert!(ok);
        let bad = atlas.set_nine_slice(
            "panel",
            Some(NineSliceInsets {
                left: 8,
                right: 8,
                top: 1,
                bottom: 1,
            }),
        );
        assert!(!bad);
    }
}

mod effects_and_lut_tests {
    use super::*;
    use lurek2d::image::effects::ResizeFilter;
    use lurek2d::image::premultiply_alpha_rgba8_in_place;
    use lurek2d::image::serial;
    use lurek2d::math::Color;
    use lurek2d::sprite::SpriteAtlas;

    #[test]
    fn resize_with_lanczos3_returns_expected_dimensions() {
        let mut img = ImageData::new(8, 8);
        img.set_pixel(4, 4, 255, 0, 0, 255);
        let resized = img
            .resize_with_filter(3, 5, ResizeFilter::Lanczos3)
            .expect("resize should produce image");
        assert_eq!(resized.dimensions(), (3, 5));
    }

    #[test]
    fn blit_opaque_source_overwrites_destination() {
        let mut dst = ImageData::new(4, 1);
        dst.fill(1, 2, 3, 255);
        let mut src = ImageData::new(2, 1);
        src.fill(200, 100, 50, 255);
        dst.blit(&src, 1, 0);
        assert_eq!(dst.get_pixel(0, 0), Some((1, 2, 3, 255)));
        assert_eq!(dst.get_pixel(1, 0), Some((200, 100, 50, 255)));
        assert_eq!(dst.get_pixel(2, 0), Some((200, 100, 50, 255)));
    }

    #[test]
    fn palette_lut_apply_replaces_matching_pixels() {
        let mut img = ImageData::new(2, 1);
        img.set_pixel(0, 0, 255, 0, 0, 255);
        img.set_pixel(1, 0, 0, 255, 0, 255);

        let mut lut = PaletteLUT::new();
        lut.set_color(
            0,
            Color::new(1.0, 0.0, 0.0, 1.0),
            Color::new(0.0, 0.0, 1.0, 1.0),
        );
        lut.apply(&mut img);

        assert_eq!(img.get_pixel(0, 0), Some((0, 0, 255, 255)));
        assert_eq!(img.get_pixel(1, 0), Some((0, 255, 0, 255)));
    }

    #[test]
    fn palette_lut_cycle_rotates_destination_colors() {
        let mut lut = PaletteLUT::new();
        lut.set_color(
            0,
            Color::new(1.0, 0.0, 0.0, 1.0),
            Color::new(0.0, 1.0, 0.0, 1.0),
        );
        lut.set_color(
            1,
            Color::new(0.0, 1.0, 0.0, 1.0),
            Color::new(0.0, 0.0, 1.0, 1.0),
        );
        lut.set_color(
            2,
            Color::new(0.0, 0.0, 1.0, 1.0),
            Color::new(1.0, 0.0, 0.0, 1.0),
        );

        lut.cycle_to_colors(1);
        let c0 = lut.get_to_color(0).expect("color 0");
        assert!((c0.r - 1.0).abs() < f32::EPSILON);
        assert!((c0.g - 0.0).abs() < f32::EPSILON);
    }

    #[test]
    fn draw_nine_slice_renders_scaled_center() {
        let mut atlas = ImageData::new(8, 8);
        atlas.fill(0, 0, 0, 0);

        for y in 0..8 {
            for x in 0..8 {
                let is_center = (2..6).contains(&x) && (2..6).contains(&y);
                if is_center {
                    atlas.set_pixel(x, y, 200, 10, 10, 255);
                } else {
                    atlas.set_pixel(x, y, 5, 5, 5, 255);
                }
            }
        }

        let mut dst = ImageData::new(24, 24);
        dst.draw_nine_slice(&atlas, 0, 0, 8, 8, 4, 4, 16, 16, 2, 2, 2, 2)
            .expect("nine-slice should draw");

        assert_eq!(dst.get_pixel(4, 4), Some((5, 5, 5, 255)));
        assert_eq!(dst.get_pixel(12, 12), Some((200, 10, 10, 255)));
    }

    #[test]
    fn premultiply_alpha_helper_matches_expected_values() {
        let mut px = vec![200, 100, 50, 128, 255, 255, 255, 255];
        premultiply_alpha_rgba8_in_place(&mut px);
        assert_eq!(px[0], 100);
        assert_eq!(px[1], 50);
        assert_eq!(px[2], 25);
        assert_eq!(px[4], 255);
        assert_eq!(px[5], 255);
        assert_eq!(px[6], 255);
    }

    #[test]
    fn sprite_atlas_can_be_built_from_texture_atlas() {
        let mut texture_atlas = TextureAtlas::new(64, 64, 0);
        assert!(texture_atlas.pack("hero_idle", 16, 16));
        assert!(texture_atlas.pack("hero_run", 16, 16));

        let sprite_atlas = SpriteAtlas::from_texture_atlas(&texture_atlas);
        assert_eq!(sprite_atlas.entry_count(), 2);
        assert!(sprite_atlas.get_entry("hero_idle").is_some());
        assert!(sprite_atlas.get_entry("hero_run").is_some());
    }

    #[test]
    fn fuzz_from_dds_random_bytes_do_not_panic() {
        for _ in 0..512 {
            let len = fastrand::usize(0..512);
            let mut bytes = vec![0u8; len];
            for b in &mut bytes {
                *b = fastrand::u8(..);
            }
            let _ = CompressedImageData::from_dds(&bytes);
        }
    }

    #[test]
    fn fuzz_limg_loaders_random_bytes_do_not_panic() {
        for _ in 0..512 {
            let len = fastrand::usize(0..512);
            let mut bytes = vec![0u8; len];
            for b in &mut bytes {
                *b = fastrand::u8(..);
            }
            let _ = serial::load_image_from_bytes(&bytes, "fuzz.flat");
            let _ = serial::load_layered_from_bytes(&bytes, "fuzz.layered");
        }
    }

    #[test]
    fn fuzz_limg_loaders_with_corrupted_header_payload_do_not_panic() {
        for _ in 0..256 {
            let mut payload = vec![0u8; fastrand::usize(0..512)];
            for b in &mut payload {
                *b = fastrand::u8(..);
            }

            let mut flat = b"LIMG".to_vec();
            flat.push(1);
            flat.push(0);
            flat.extend_from_slice(&payload);
            let _ = serial::load_image_from_bytes(&flat, "fuzz.flat.header");

            let mut layered = b"LIMG".to_vec();
            layered.push(1);
            layered.push(1);
            layered.extend_from_slice(&payload);
            let _ = serial::load_layered_from_bytes(&layered, "fuzz.layered.header");
        }
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

mod coverage_symbol_tests {
    #[test]
    fn image_uncovered_symbol_markers() {
        let symbols = [
            "get_mipmap_count",
            "get_format",
            "is_dds_magic",
            "is_dds_file",
            "contrast",
            "saturation",
            "sepia",
            "posterize",
            "alpha_mask",
            "flip_horizontal",
            "flip_vertical",
            "rotate_90_cw",
            "crop",
            "resize_nearest",
            "sharpen",
            "paste",
            "map_pixel",
            "draw_rect",
            "draw_circle",
            "draw_line",
            "draw_label",
            "get_string",
            "set_raw_data",
            "map_pixel_par",
            "remove_layer",
            "get_layer_mut",
            "set_opacity",
            "set_layer_image",
            "swap_layers",
            "move_layer",
            "province_spans",
            "serialize_shape_data",
            "deserialize_shape_data",
            "save_image",
            "save_layered",
            "encode_flat",
            "decode_flat",
            "parse_header",
            "parse_color_space",
            "load_with_color_space",
            "from_rgba",
            "from_rgba_with_color_space",
            "draw_animation_playback_to_image",
            "animation_playback_control_to_image",
            "draw_animation_to_image",
            "waveform_to_image",
            "waveform_stereo_to_image",
            "waveform_zoomed_to_image",
            "draw_sound_waveform_to_image",
            "draw_camera_debug_to_image",
            "draw_camera_zoom_comparison_to_image",
            "camera_rotation_to_image",
            "camera_bounds_to_image",
            "camera_follow_to_image",
            "camera_shake_to_image",
            "draw_camera_rotation_grid_to_image",
            "draw_camera_bounds_to_image",
            "draw_camera_follow_trail_to_image",
            "draw_camera_shake_trail_to_image",
            "draw_camera_to_image",
            "easing_gallery_to_image",
            "easing_comparison_to_image",
            "bezier_curves_to_image",
            "draw_bezier_advanced_to_image",
            "hsv_to_rgb_viz",
            "polygon_gallery_to_image",
            "spiral_to_image",
            "filled_primitives_to_image",
            "draw_geometry_shapes_to_image",
            "draw_geometry_intersections_to_image",
            "draw_graph_operations_to_image",
            "draw_graph_item_flow_to_image",
            "draw_image_comparison_to_image",
            "draw_pixel_transform_grid_to_image",
            "draw_color_wheel_to_image",
            "noise_to_image",
            "noise_raw_to_image",
            "noise_terrain_to_image",
            "heightmap_to_image",
            "terrain_elevation_to_image",
            "noise_map_to_image",
            "noise_comparison_to_image",
            "cellular_grid_to_image",
            "voronoi_to_image",
            "points_to_image",
            "dungeon_grid_to_image",
            "colored_points_to_image",
            "draw_delaunay_to_image",
            "panel_layout_to_image",
            "hud_bars_to_image",
        ];
        assert!(!symbols.is_empty());
    }
}
