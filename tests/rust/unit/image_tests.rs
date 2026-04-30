//! Tests for the image module.

use lurek2d::image::*;
use lurek2d::image::image_data::ImageData;
use lurek2d::image::compressed::{CompressedFormat, CompressedImageData};
use lurek2d::image::palette_lut::PaletteLUT;
use lurek2d::image::layers::{ImageLayer, LayeredImage};
use lurek2d::image::province_grid::ProvinceGrid;
use lurek2d::math::Color;
use lurek2d::render::renderer::RenderCommand;
use lurek2d::runtime::resource_keys::TextureKey;
use slotmap::KeyData;

// ── compressed tests ─────────────────────────────────────────────────────────

mod compressed_tests {
    use super::*;

    #[test]
    fn format_as_str_roundtrip() {
        assert_eq!(CompressedFormat::Dxt1.as_str(), "dxt1");
        assert_eq!(CompressedFormat::Dxt3.as_str(), "dxt3");
        assert_eq!(CompressedFormat::Dxt5.as_str(), "dxt5");
        assert_eq!(CompressedFormat::Bc7.as_str(), "bc7");
        assert_eq!(CompressedFormat::Etc1.as_str(), "etc1");
        assert_eq!(CompressedFormat::Etc2Rgb.as_str(), "etc2_rgb");
        assert_eq!(CompressedFormat::Etc2Rgba.as_str(), "etc2_rgba");
        assert_eq!(CompressedFormat::Unknown.as_str(), "unknown");
    }

    #[test]
    fn is_dds_magic_valid() {
        assert!(CompressedImageData::is_dds_magic(&[0x44, 0x44, 0x53, 0x20]));
        assert!(CompressedImageData::is_dds_magic(&[0x44, 0x44, 0x53, 0x20, 0xFF]));
    }

    #[test]
    fn is_dds_magic_too_short() {
        assert!(!CompressedImageData::is_dds_magic(&[0x44, 0x44, 0x53]));
        assert!(!CompressedImageData::is_dds_magic(&[]));
    }

    #[test]
    fn is_dds_magic_wrong_bytes() {
        assert!(!CompressedImageData::is_dds_magic(&[0x89, 0x50, 0x4E, 0x47])); // PNG
    }

    #[test]
    fn from_dds_rejects_garbage() {
        let garbage = vec![0u8; 64];
        assert!(CompressedImageData::from_dds(&garbage).is_err());
    }

    #[test]
    fn from_file_rejects_missing_path() {
        assert!(CompressedImageData::from_file("__nonexistent__.dds").is_err());
    }

    #[test]
    fn is_dds_file_returns_false_for_missing() {
        assert!(!CompressedImageData::is_dds_file("__nonexistent__.dds"));
    }

    #[test]
    fn format_equality() {
        assert_eq!(CompressedFormat::Bc7, CompressedFormat::Bc7);
        assert_ne!(CompressedFormat::Dxt1, CompressedFormat::Dxt5);
    }

    #[test]
    fn get_format_delegates_to_as_str() {
        let data = CompressedImageData {
            format: CompressedFormat::Dxt5,
            width: 64,
            height: 64,
            mipmaps: vec![vec![0; 32]],
        };
        assert_eq!(data.get_format(), "dxt5");
        assert_eq!(data.get_dimensions(), (64, 64));
        assert_eq!(data.get_mipmap_count(), 1);
    }
}

// ── effects tests ────────────────────────────────────────────────────────────

mod effects_tests {
    use super::*;

    fn gradient_4x4() -> ImageData {
        let mut img = ImageData::new(4, 4);
        for y in 0..4u32 {
            for x in 0..4u32 {
                let v = (x * 30 + y * 60) as u8;
                img.set_pixel(x, y, v, v, v, 255);
            }
        }
        img
    }

    #[test]
    fn brightness_zero_produces_black() {
        let mut img = gradient_4x4();
        img.brightness(0.0);
        for y in 0..4 {
            for x in 0..4 {
                let (r, g, b, a) = img.get_pixel(x, y).unwrap();
                assert_eq!((r, g, b), (0, 0, 0));
                assert_eq!(a, 255);
            }
        }
    }

    #[test]
    fn brightness_one_is_identity() {
        let orig = gradient_4x4();
        let mut img = orig.clone();
        img.brightness(1.0);
        assert_eq!(img.as_bytes(), orig.as_bytes());
    }

    #[test]
    fn contrast_one_is_identity() {
        let orig = gradient_4x4();
        let mut img = orig.clone();
        img.contrast(1.0);
        assert_eq!(img.as_bytes(), orig.as_bytes());
    }

    #[test]
    fn saturation_zero_produces_grayscale() {
        let mut img = ImageData::new(1, 1);
        img.set_pixel(0, 0, 200, 100, 50, 255);
        img.saturation(0.0);
        let (r, g, b, _) = img.get_pixel(0, 0).unwrap();
        assert_eq!(r, g);
        assert_eq!(g, b);
    }

    #[test]
    fn gamma_one_is_identity() {
        let orig = gradient_4x4();
        let mut img = orig.clone();
        img.gamma(1.0);
        for (a, b) in img.as_bytes().iter().zip(orig.as_bytes().iter()) {
            assert!((*a as i32 - *b as i32).abs() <= 1);
        }
    }

    #[test]
    fn tint_zero_is_identity() {
        let orig = gradient_4x4();
        let mut img = orig.clone();
        img.tint(255, 0, 0, 0.0);
        assert_eq!(img.as_bytes(), orig.as_bytes());
    }

    #[test]
    fn grayscale_makes_channels_equal() {
        let mut img = ImageData::new(2, 2);
        img.set_pixel(0, 0, 200, 100, 50, 255);
        img.grayscale();
        let (r, g, b, _) = img.get_pixel(0, 0).unwrap();
        assert_eq!(r, g);
        assert_eq!(g, b);
    }

    #[test]
    fn invert_double_is_identity() {
        let orig = gradient_4x4();
        let mut img = orig.clone();
        img.invert();
        img.invert();
        assert_eq!(img.as_bytes(), orig.as_bytes());
    }

    #[test]
    fn threshold_128_binarises() {
        let mut img = ImageData::new(2, 1);
        img.set_pixel(0, 0, 200, 200, 200, 255);
        img.set_pixel(1, 0, 20, 20, 20, 255);
        img.threshold(128);
        assert_eq!(img.get_pixel(0, 0), Some((255, 255, 255, 255)));
        assert_eq!(img.get_pixel(1, 0), Some((0, 0, 0, 255)));
    }

    #[test]
    fn posterize_2_levels() {
        let mut img = ImageData::new(1, 1);
        img.set_pixel(0, 0, 100, 100, 100, 255);
        img.posterize(2);
        let (r, _, _, _) = img.get_pixel(0, 0).unwrap();
        assert!(r == 0 || r == 255);
    }

    #[test]
    fn fill_overwrites_all_pixels() {
        let mut img = gradient_4x4();
        img.fill(42, 84, 126, 200);
        for y in 0..4 {
            for x in 0..4 {
                assert_eq!(img.get_pixel(x, y), Some((42, 84, 126, 200)));
            }
        }
    }

    #[test]
    fn noise_zero_is_identity() {
        let orig = gradient_4x4();
        let mut img = orig.clone();
        img.noise(0);
        assert_eq!(img.as_bytes(), orig.as_bytes());
    }

    #[test]
    fn alpha_mask_zero_makes_transparent() {
        let mut img = ImageData::new(2, 2);
        img.set_pixel(0, 0, 100, 100, 100, 255);
        img.alpha_mask(0.0);
        let (_, _, _, a) = img.get_pixel(0, 0).unwrap();
        assert_eq!(a, 0);
    }

    #[test]
    fn flip_horizontal_swaps_left_right() {
        let mut img = ImageData::new(4, 1);
        img.set_pixel(0, 0, 10, 0, 0, 255);
        img.set_pixel(3, 0, 90, 0, 0, 255);
        img.flip_horizontal();
        assert_eq!(img.get_pixel(0, 0).unwrap().0, 90);
        assert_eq!(img.get_pixel(3, 0).unwrap().0, 10);
    }

    #[test]
    fn flip_vertical_swaps_top_bottom() {
        let mut img = ImageData::new(1, 4);
        img.set_pixel(0, 0, 10, 0, 0, 255);
        img.set_pixel(0, 3, 90, 0, 0, 255);
        img.flip_vertical();
        assert_eq!(img.get_pixel(0, 0).unwrap().0, 90);
        assert_eq!(img.get_pixel(0, 3).unwrap().0, 10);
    }

    #[test]
    fn rotate_90_cw_swaps_dimensions() {
        let img = ImageData::new(8, 4);
        let rotated = img.rotate_90_cw();
        assert_eq!(rotated.width(), 4);
        assert_eq!(rotated.height(), 8);
    }

    #[test]
    fn crop_returns_subregion() {
        let mut img = ImageData::new(8, 8);
        img.set_pixel(2, 3, 42, 0, 0, 255);
        let cropped = img.crop(2, 3, 2, 2).unwrap();
        assert_eq!(cropped.width(), 2);
        assert_eq!(cropped.height(), 2);
        assert_eq!(cropped.get_pixel(0, 0), Some((42, 0, 0, 255)));
    }

    #[test]
    fn crop_out_of_bounds_returns_none() {
        let img = ImageData::new(4, 4);
        assert!(img.crop(3, 3, 2, 2).is_none());
    }

    #[test]
    fn resize_nearest_scales() {
        let mut img = ImageData::new(2, 2);
        img.set_pixel(0, 0, 255, 0, 0, 255);
        let scaled = img.resize_nearest(4, 4);
        assert_eq!(scaled.width(), 4);
        assert_eq!(scaled.height(), 4);
        assert_eq!(scaled.get_pixel(0, 0).unwrap().0, 255);
    }

    #[test]
    fn blur_zero_is_clone() {
        let img = gradient_4x4();
        let blurred = img.blur(0);
        assert_eq!(blurred.as_bytes(), img.as_bytes());
    }

    #[test]
    fn blur_produces_same_dimensions() {
        let img = gradient_4x4();
        let blurred = img.blur(2);
        assert_eq!(blurred.dimensions(), img.dimensions());
    }

    #[test]
    fn sharpen_preserves_dimensions() {
        let img = gradient_4x4();
        let sharpened = img.sharpen();
        assert_eq!(sharpened.dimensions(), img.dimensions());
    }

    #[test]
    fn resize_bilinear_returns_correct_dims() {
        let img = gradient_4x4();
        let resized = img.resize(8, 8).unwrap();
        assert_eq!(resized.dimensions(), (8, 8));
    }

    #[test]
    fn resize_zero_returns_none() {
        let img = gradient_4x4();
        assert!(img.resize(0, 8).is_none());
    }

    #[test]
    fn blit_composites_over() {
        let mut dst = ImageData::new(4, 4);
        dst.fill(0, 0, 0, 255);
        let mut src = ImageData::new(2, 2);
        src.fill(255, 0, 0, 128);
        dst.blit(&src, 1, 1);
        let (r, _, _, _) = dst.get_pixel(1, 1).unwrap();
        assert!(r > 0);
    }

    #[test]
    fn get_region_matches_crop() {
        let mut img = ImageData::new(8, 8);
        img.set_pixel(2, 2, 42, 84, 126, 255);
        let a = img.crop(2, 2, 3, 3).unwrap();
        let b = img.get_region(2, 2, 3, 3).unwrap();
        assert_eq!(a.as_bytes(), b.as_bytes());
    }

    #[test]
    fn diff_identical_is_zero() {
        let img = gradient_4x4();
        assert_eq!(img.diff(&img), 0);
    }

    #[test]
    fn diff_different_is_nonzero() {
        let a = gradient_4x4();
        let mut b = gradient_4x4();
        b.invert();
        assert!(a.diff(&b) > 0);
    }

    #[test]
    fn convolve_identity_kernel() {
        let img = gradient_4x4();
        let kernel = [0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0];
        let result = img.convolve(&kernel, 3).unwrap();
        assert_eq!(result.dimensions(), img.dimensions());
    }

    #[test]
    fn convolve_rejects_even_ksize() {
        let img = ImageData::new(4, 4);
        let kernel = [1.0; 4];
        assert!(img.convolve(&kernel, 2).is_err());
    }

    #[test]
    fn convolve_rejects_mismatched_len() {
        let img = ImageData::new(4, 4);
        let kernel = [1.0; 5];
        assert!(img.convolve(&kernel, 3).is_err());
    }
}

// ── image_data tests ─────────────────────────────────────────────────────────

mod image_data_tests {
    use super::*;

    #[test]
    fn new_creates_zeroed_image() {
        let img = ImageData::new(4, 4);
        assert_eq!(img.width(), 4);
        assert_eq!(img.height(), 4);
        assert_eq!(img.as_bytes().len(), 4 * 4 * 4);
        assert!(img.as_bytes().iter().all(|&b| b == 0));
    }

    #[test]
    fn from_bytes_accepts_correct_size() {
        let bytes = vec![0u8; 2 * 2 * 4];
        let img = ImageData::from_bytes(2, 2, bytes).unwrap();
        assert_eq!(img.dimensions(), (2, 2));
    }

    #[test]
    fn from_bytes_rejects_wrong_size() {
        let bytes = vec![0u8; 10];
        assert!(ImageData::from_bytes(2, 2, bytes).is_err());
    }

    #[test]
    fn get_set_pixel_roundtrip() {
        let mut img = ImageData::new(8, 8);
        assert!(img.set_pixel(3, 5, 100, 200, 50, 255));
        assert_eq!(img.get_pixel(3, 5), Some((100, 200, 50, 255)));
    }

    #[test]
    fn get_pixel_out_of_bounds_returns_none() {
        let img = ImageData::new(4, 4);
        assert_eq!(img.get_pixel(4, 0), None);
        assert_eq!(img.get_pixel(0, 4), None);
    }

    #[test]
    fn set_pixel_out_of_bounds_returns_false() {
        let mut img = ImageData::new(4, 4);
        assert!(!img.set_pixel(4, 0, 0, 0, 0, 0));
        assert!(!img.set_pixel(0, 4, 0, 0, 0, 0));
    }

    #[test]
    fn paste_copies_pixels() {
        let mut dst = ImageData::new(8, 8);
        let mut src = ImageData::new(2, 2);
        src.set_pixel(0, 0, 255, 0, 0, 255);
        src.set_pixel(1, 1, 0, 255, 0, 255);
        dst.paste(&src, 3, 3);
        assert_eq!(dst.get_pixel(3, 3), Some((255, 0, 0, 255)));
        assert_eq!(dst.get_pixel(4, 4), Some((0, 255, 0, 255)));
    }

    #[test]
    fn map_pixel_transforms_all_pixels() {
        let mut img = ImageData::new(2, 2);
        img.set_pixel(0, 0, 10, 20, 30, 255);
        img.set_pixel(1, 0, 40, 50, 60, 255);
        img.map_pixel(|_, _, r, g, b, a| (255 - r, 255 - g, 255 - b, a));
        assert_eq!(img.get_pixel(0, 0), Some((245, 235, 225, 255)));
        assert_eq!(img.get_pixel(1, 0), Some((215, 205, 195, 255)));
    }

    #[test]
    fn draw_rect_clips_at_edges() {
        let mut img = ImageData::new(4, 4);
        img.draw_rect(-1, -1, 3, 3, 200, 100, 50, 255);
        assert_eq!(img.get_pixel(0, 0), Some((200, 100, 50, 255)));
        assert_eq!(img.get_pixel(1, 1), Some((200, 100, 50, 255)));
        assert_eq!(img.get_pixel(2, 0), Some((0, 0, 0, 0)));
    }

    #[test]
    fn draw_line_bresenham_horizontal() {
        let mut img = ImageData::new(8, 4);
        img.draw_line(1, 2, 6, 2, 255, 255, 255, 255);
        for x in 1..=6 {
            assert_eq!(img.get_pixel(x, 2), Some((255, 255, 255, 255)));
        }
    }

    #[test]
    fn draw_circle_sets_center_pixel() {
        let mut img = ImageData::new(16, 16);
        img.draw_circle(8, 8, 3, 128, 64, 32, 255);
        assert_eq!(img.get_pixel(8, 8), Some((128, 64, 32, 255)));
    }

    #[test]
    fn encode_png_produces_valid_png() {
        let img = ImageData::new(4, 4);
        let bytes = img.encode_png().unwrap();
        assert_eq!(&bytes[0..4], &[0x89, 0x50, 0x4E, 0x47]);
    }

    #[test]
    fn as_bytes_returns_full_buffer() {
        let img = ImageData::new(3, 3);
        assert_eq!(img.as_bytes().len(), 3 * 3 * 4);
    }

    #[test]
    fn get_string_returns_clone() {
        let mut img = ImageData::new(2, 2);
        img.set_pixel(0, 0, 42, 0, 0, 255);
        let s = img.get_string();
        assert_eq!(s.len(), 2 * 2 * 4);
        assert_eq!(s[0], 42);
    }

    #[test]
    fn map_pixel_par_matches_map_pixel() {
        let mut a = ImageData::new(4, 4);
        let mut b = ImageData::new(4, 4);
        for y in 0..4u32 {
            for x in 0..4u32 {
                let v = (x * 16 + y * 64) as u8;
                a.set_pixel(x, y, v, v, v, 255);
                b.set_pixel(x, y, v, v, v, 255);
            }
        }
        a.map_pixel(|_, _, r, g, b, a| (255 - r, g, b, a));
        b.map_pixel_par(|_, _, r, g, b, a| (255 - r, g, b, a));
        assert_eq!(a.as_bytes(), b.as_bytes());
    }
}

// ── layers tests ─────────────────────────────────────────────────────────────

mod layers_tests {
    use super::*;

    #[test]
    fn new_layer_is_transparent() {
        let layer = ImageLayer::new("bg", 4, 4);
        assert_eq!(layer.name, "bg");
        assert_eq!(layer.opacity, 1.0);
        assert!(layer.visible);
        assert!(layer.data.as_bytes().iter().all(|&b| b == 0));
    }

    #[test]
    fn new_layered_image_has_zero_layers() {
        let li = LayeredImage::new(32, 32);
        assert_eq!(li.width(), 32);
        assert_eq!(li.height(), 32);
        assert_eq!(li.layer_count(), 0);
    }

    #[test]
    fn add_and_remove_layer() {
        let mut li = LayeredImage::new(8, 8);
        let idx = li.add_layer("first");
        assert_eq!(idx, 0);
        assert_eq!(li.layer_count(), 1);
        let removed = li.remove_layer(0);
        assert!(removed.is_some());
        assert_eq!(li.layer_count(), 0);
    }

    #[test]
    fn remove_out_of_bounds_returns_none() {
        let mut li = LayeredImage::new(4, 4);
        assert!(li.remove_layer(0).is_none());
    }

    #[test]
    fn get_layer_by_index() {
        let mut li = LayeredImage::new(4, 4);
        li.add_layer("a");
        li.add_layer("b");
        assert_eq!(li.get_layer(0).unwrap().name, "a");
        assert_eq!(li.get_layer(1).unwrap().name, "b");
        assert!(li.get_layer(2).is_none());
    }

    #[test]
    fn set_opacity_clamps() {
        let mut li = LayeredImage::new(4, 4);
        li.add_layer("x");
        assert!(li.set_opacity(0, 1.5));
        assert_eq!(li.get_layer(0).unwrap().opacity, 1.0);
        assert!(li.set_opacity(0, -0.5));
        assert_eq!(li.get_layer(0).unwrap().opacity, 0.0);
        assert!(!li.set_opacity(5, 0.5));
    }

    #[test]
    fn set_visible_toggles() {
        let mut li = LayeredImage::new(4, 4);
        li.add_layer("x");
        assert!(li.set_visible(0, false));
        assert!(!li.get_layer(0).unwrap().visible);
    }

    #[test]
    fn set_name_renames() {
        let mut li = LayeredImage::new(4, 4);
        li.add_layer("old");
        assert!(li.set_name(0, "new"));
        assert_eq!(li.get_layer(0).unwrap().name, "new");
    }

    #[test]
    fn swap_layers_changes_order() {
        let mut li = LayeredImage::new(4, 4);
        li.add_layer("bottom");
        li.add_layer("top");
        assert!(li.swap_layers(0, 1));
        assert_eq!(li.get_layer(0).unwrap().name, "top");
        assert_eq!(li.get_layer(1).unwrap().name, "bottom");
    }

    #[test]
    fn swap_same_index_returns_false() {
        let mut li = LayeredImage::new(4, 4);
        li.add_layer("a");
        assert!(!li.swap_layers(0, 0));
    }

    #[test]
    fn move_layer_reorders() {
        let mut li = LayeredImage::new(4, 4);
        li.add_layer("a");
        li.add_layer("b");
        li.add_layer("c");
        assert!(li.move_layer(2, 0));
        assert_eq!(li.get_layer(0).unwrap().name, "c");
    }

    #[test]
    fn merge_empty_stack_returns_blank() {
        let li = LayeredImage::new(4, 4);
        let merged = li.merge();
        assert_eq!(merged.width(), 4);
        assert_eq!(merged.height(), 4);
        assert!(merged.as_bytes().iter().all(|&b| b == 0));
    }

    #[test]
    fn merge_single_opaque_layer() {
        let mut li = LayeredImage::new(2, 2);
        li.add_layer("bg");
        if let Some(layer) = li.get_layer_mut(0) {
            layer.data.set_pixel(0, 0, 255, 0, 0, 255);
        }
        let merged = li.merge();
        assert_eq!(merged.get_pixel(0, 0), Some((255, 0, 0, 255)));
    }

    #[test]
    fn merge_skips_invisible_layers() {
        let mut li = LayeredImage::new(2, 2);
        li.add_layer("bg");
        if let Some(layer) = li.get_layer_mut(0) {
            layer.data.set_pixel(0, 0, 255, 0, 0, 255);
            layer.visible = false;
        }
        let merged = li.merge();
        assert_eq!(merged.get_pixel(0, 0), Some((0, 0, 0, 0)));
    }

    #[test]
    fn merge_respects_opacity() {
        let mut li = LayeredImage::new(1, 1);
        li.add_layer("half");
        li.set_opacity(0, 0.5);
        if let Some(layer) = li.get_layer_mut(0) {
            layer.data.set_pixel(0, 0, 200, 100, 50, 255);
        }
        let merged = li.merge();
        let (_, _, _, a) = merged.get_pixel(0, 0).unwrap();
        assert!((a as i32 - 128).abs() <= 1);
    }

    #[test]
    fn set_layer_image_replaces_data() {
        let mut li = LayeredImage::new(4, 4);
        li.add_layer("target");
        let mut src = ImageData::new(4, 4);
        src.set_pixel(1, 1, 42, 84, 126, 200);
        assert!(li.set_layer_image(0, &src));
        assert_eq!(
            li.get_layer(0).unwrap().data.get_pixel(1, 1),
            Some((42, 84, 126, 200))
        );
    }
}

// ── palette_lut tests ────────────────────────────────────────────────────────

mod palette_lut_tests {
    use super::*;

    #[test]
    fn default_is_same_as_new() {
        let p = PaletteLUT::default();
        assert_eq!(p.get_color_count(), 0);
    }

    #[test]
    fn set_color_appends_and_pads() {
        let mut p = PaletteLUT::new();
        let from = Color { r: 1.0, g: 0.0, b: 0.0, a: 1.0 };
        let to = Color { r: 0.0, g: 1.0, b: 0.0, a: 1.0 };
        p.set_color(2, from, to);
        assert_eq!(p.get_color_count(), 3);
        assert_eq!(p.get_from_color(2).unwrap().r, 1.0);
        assert_eq!(p.get_to_color(2).unwrap().g, 1.0);
    }

    #[test]
    fn get_from_color_out_of_bounds() {
        let p = PaletteLUT::new();
        assert!(p.get_from_color(0).is_none());
        assert!(p.get_to_color(5).is_none());
    }

    #[test]
    fn clear_empties_palette() {
        let mut p = PaletteLUT::new();
        let c = Color::WHITE;
        p.set_color(0, c, c);
        p.set_color(1, c, c);
        assert_eq!(p.get_color_count(), 2);
        p.clear();
        assert_eq!(p.get_color_count(), 0);
    }

    #[test]
    fn apply_with_empty_palette_is_noop() {
        let mut img = ImageData::new(2, 2);
        img.set_pixel(0, 0, 42, 84, 126, 200);
        let p = PaletteLUT::new();
        p.apply(&mut img);
        assert_eq!(img.get_pixel(0, 0), Some((42, 84, 126, 200)));
    }
}

// ── province_grid tests ──────────────────────────────────────────────────────

mod province_grid_tests {
    use super::*;

    fn make_test_image() -> ImageData {
        let mut img = ImageData::new(4, 4);
        for y in 0..2 {
            for x in 0..2 {
                img.set_pixel(x, y, 255, 0, 0, 255);
            }
        }
        for y in 0..2 {
            for x in 2..4 {
                img.set_pixel(x, y, 0, 255, 0, 255);
            }
        }
        for x in 0..4 {
            img.set_pixel(x, 2, 0, 0, 255, 255);
        }
        img
    }

    #[test]
    fn get_at_returns_zero_for_out_of_bounds() {
        let img = make_test_image();
        let grid = ProvinceGrid::from_image(&img);
        assert_eq!(grid.get_at(10, 10), 0);
        assert_eq!(grid.get_at(4, 0), 0);
    }

    #[test]
    fn from_file_rejects_missing_path() {
        assert!(ProvinceGrid::from_file("__nonexistent_province_map__.png").is_err());
    }
}

// ── render tests ─────────────────────────────────────────────────────────────

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

// ── texture_atlas tests ──────────────────────────────────────────────────────

mod texture_atlas_tests {
    use super::*;

    #[test]
    fn new_atlas_is_empty() {
        let a = TextureAtlas::new(256, 256, 1);
        assert_eq!(a.get_region_count(), 0);
        assert_eq!(a.get_dimensions(), (256, 256));
    }

    #[test]
    fn pack_single_region() {
        let mut a = TextureAtlas::new(128, 128, 0);
        assert!(a.pack("hero", 32, 32));
        assert_eq!(a.get_region_count(), 1);
        let r = a.get_region("hero").unwrap();
        assert_eq!(r.w, 32);
        assert_eq!(r.h, 32);
    }

    #[test]
    fn pack_multiple_regions_same_shelf() {
        let mut a = TextureAtlas::new(128, 128, 0);
        assert!(a.pack("a", 32, 32));
        assert!(a.pack("b", 32, 32));
        assert!(a.pack("c", 32, 32));
        assert_eq!(a.get_region_count(), 3);
    }

    #[test]
    fn pack_fails_when_full() {
        let mut a = TextureAtlas::new(32, 32, 0);
        assert!(a.pack("fits", 32, 32));
        assert!(!a.pack("nope", 32, 32));
    }

    #[test]
    fn pack_with_padding() {
        let mut a = TextureAtlas::new(128, 128, 2);
        assert!(a.pack("padded", 16, 16));
        let r = a.get_region("padded").unwrap();
        assert!(r.x >= 2);
        assert!(r.y >= 2);
    }

    #[test]
    fn get_region_returns_none_for_unknown() {
        let a = TextureAtlas::new(64, 64, 0);
        assert!(a.get_region("missing").is_none());
    }

    #[test]
    fn clear_resets_atlas() {
        let mut a = TextureAtlas::new(128, 128, 0);
        a.pack("x", 32, 32);
        a.pack("y", 32, 32);
        a.clear();
        assert_eq!(a.get_region_count(), 0);
        assert!(a.get_region("x").is_none());
    }

    #[test]
    fn pack_region_wider_than_atlas_fails() {
        let mut a = TextureAtlas::new(64, 64, 0);
        assert!(!a.pack("too_wide", 128, 16));
    }

    #[test]
    fn get_regions_returns_all() {
        let mut a = TextureAtlas::new(256, 256, 0);
        a.pack("a", 16, 16);
        a.pack("b", 16, 16);
        let all = a.get_regions();
        assert_eq!(all.len(), 2);
    }
}

// ── visualization tests ──────────────────────────────────────────────────────

mod visualization_tests {
    use lurek2d::image::visualization::draw_animation_frame_grid_to_image;
    use lurek2d::animation::Animation;
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
