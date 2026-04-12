//! Integration tests for the image data module.

use lurek2d::image::{CompressedImageData, ImageData, LayeredImage, PaletteLUT};
use lurek2d::math::Color;

#[test]
fn image_data_new_blank() {
    let img = ImageData::new(10, 20);
    assert_eq!(img.width(), 10);
    assert_eq!(img.height(), 20);
    assert_eq!(img.get_pixel(0, 0), Some((0, 0, 0, 0)));
}

#[test]
fn image_data_set_get_pixel() {
    let mut img = ImageData::new(5, 5);
    assert!(img.set_pixel(2, 3, 255, 128, 64, 200));
    assert_eq!(img.get_pixel(2, 3), Some((255, 128, 64, 200)));
}

#[test]
fn image_data_out_of_bounds() {
    let img = ImageData::new(5, 5);
    assert_eq!(img.get_pixel(5, 0), None);
    assert_eq!(img.get_pixel(0, 5), None);
}

#[test]
fn image_data_paste() {
    let mut dest = ImageData::new(10, 10);
    let mut src = ImageData::new(3, 3);
    src.set_pixel(0, 0, 255, 0, 0, 255);
    src.set_pixel(1, 1, 0, 255, 0, 255);
    dest.paste(&src, 2, 2);
    assert_eq!(dest.get_pixel(2, 2), Some((255, 0, 0, 255)));
    assert_eq!(dest.get_pixel(3, 3), Some((0, 255, 0, 255)));
}

#[test]
fn image_data_from_bytes() {
    let bytes = vec![255, 0, 0, 255, 0, 255, 0, 255]; // 2 pixels
    let img = ImageData::from_bytes(2, 1, bytes).unwrap();
    assert_eq!(img.get_pixel(0, 0), Some((255, 0, 0, 255)));
    assert_eq!(img.get_pixel(1, 0), Some((0, 255, 0, 255)));
}

#[test]
fn image_data_from_bytes_wrong_size() {
    let bytes = vec![0; 10]; // wrong size for 2x2
    assert!(ImageData::from_bytes(2, 2, bytes).is_err());
}

#[test]
fn image_data_map_pixel() {
    let mut img = ImageData::new(2, 2);
    img.set_pixel(0, 0, 100, 50, 25, 255);
    img.set_pixel(1, 0, 200, 100, 50, 128);
    img.map_pixel(|_x, _y, r, g, b, a| (255 - r, 255 - g, 255 - b, a));
    assert_eq!(img.get_pixel(0, 0), Some((155, 205, 230, 255)));
    assert_eq!(img.get_pixel(1, 0), Some((55, 155, 205, 128)));
}

#[test]
fn image_compressed_dxt1_loads_from_dds() {
    let bytes = std::fs::read("tests/fixtures/test_dxt1.dds").unwrap();
    let cid = CompressedImageData::from_dds(&bytes).unwrap();
    assert_eq!(cid.get_dimensions(), (1, 1));
    assert_eq!(cid.get_format(), "dxt1");
}

#[test]
fn image_compressed_mipmap_count_is_at_least_one() {
    let bytes = std::fs::read("tests/fixtures/test_dxt1.dds").unwrap();
    let cid = CompressedImageData::from_dds(&bytes).unwrap();
    assert!(cid.get_mipmap_count() >= 1);
}

#[test]
fn image_compressed_rejects_invalid_bytes() {
    let result = CompressedImageData::from_dds(b"not a dds file at all");
    assert!(result.is_err());
}

#[test]
fn image_data_encode_png() {
    let mut img = ImageData::new(2, 2);
    img.set_pixel(0, 0, 255, 0, 0, 255);
    let png_bytes = img.encode_png().unwrap();
    // PNG files start with the PNG signature
    assert_eq!(&png_bytes[..4], &[137, 80, 78, 71]);
}

// ===========================================================================
// Phase 13: CompressedImageData named tests
// ===========================================================================

#[test]
fn compressed_image_data_format_string() {
    // Verify get_format() returns a non-empty string for a valid DDS file.
    let bytes = std::fs::read("tests/fixtures/test_dxt1.dds").unwrap();
    let cid = CompressedImageData::from_dds(&bytes).unwrap();
    let fmt = cid.get_format();
    assert!(!fmt.is_empty(), "format string must not be empty");
    assert_eq!(fmt, "dxt1", "DXT1 fixture must report 'dxt1' format");
}

#[test]
fn compressed_image_data_dimensions_nonzero_for_valid_file() {
    // Verify width and height are positive for a valid DDS file.
    let bytes = std::fs::read("tests/fixtures/test_dxt1.dds").unwrap();
    let cid = CompressedImageData::from_dds(&bytes).unwrap();
    let (w, h) = cid.get_dimensions();
    assert!(w > 0, "width must be > 0 for a valid DDS file");
    assert!(h > 0, "height must be > 0 for a valid DDS file");
}

// ── PaletteLUT ─────────────────────────────────────────────────────────────

#[test]
fn palette_lut_new_is_empty() {
    let lut = PaletteLUT::new();
    assert_eq!(lut.get_color_count(), 0);
}

#[test]
fn palette_lut_set_color_increments_count() {
    let mut lut = PaletteLUT::new();
    lut.set_color(
        0,
        Color::new(1.0, 0.0, 0.0, 1.0),
        Color::new(0.0, 1.0, 0.0, 1.0),
    );
    assert_eq!(lut.get_color_count(), 1);
}

#[test]
fn palette_lut_get_from_and_to_color() {
    let mut lut = PaletteLUT::new();
    let from = Color::new(1.0, 0.0, 0.0, 1.0);
    let to = Color::new(0.0, 0.0, 1.0, 1.0);
    lut.set_color(0, from, to);
    let got_from = lut
        .get_from_color(0)
        .expect("expected a from color at index 0");
    let got_to = lut.get_to_color(0).expect("expected a to color at index 0");
    assert!((got_from.r - 1.0).abs() < 1e-5);
    assert!((got_to.b - 1.0).abs() < 1e-5);
}

#[test]
fn palette_lut_get_out_of_bounds_returns_none() {
    let lut = PaletteLUT::new();
    assert!(lut.get_from_color(0).is_none());
    assert!(lut.get_to_color(99).is_none());
}

#[test]
fn palette_lut_set_color_extends_to_index() {
    let mut lut = PaletteLUT::new();
    // Setting index 2 should extend both vectors to length 3
    lut.set_color(
        2,
        Color::new(0.5, 0.5, 0.5, 1.0),
        Color::new(0.0, 0.0, 0.0, 1.0),
    );
    assert_eq!(lut.get_color_count(), 3);
    // Entries at 0 and 1 are filled with WHITE defaults
    let c0 = lut.get_from_color(0).unwrap();
    assert!((c0.r - 1.0).abs() < 1e-5);
}

#[test]
fn palette_lut_clear_resets_to_empty() {
    let mut lut = PaletteLUT::new();
    lut.set_color(0, Color::WHITE, Color::WHITE);
    lut.set_color(1, Color::WHITE, Color::WHITE);
    assert_eq!(lut.get_color_count(), 2);
    lut.clear();
    assert_eq!(lut.get_color_count(), 0);
}

#[test]
fn palette_lut_default_equals_new() {
    let lut: PaletteLUT = Default::default();
    assert_eq!(lut.get_color_count(), 0);
}

// ===========================================================================
// Effects: Color / Tone
// ===========================================================================

#[test]
fn brightness_factor2_doubles_mid_grey_channels() {
    let mut img = ImageData::new(1, 1);
    img.set_pixel(0, 0, 100, 100, 100, 200);
    img.brightness(2.0);
    let (r, g, b, a) = img.get_pixel(0, 0).unwrap();
    assert!((r as i32 - 200).abs() <= 1, "R expected ~200 got {r}");
    assert!((g as i32 - 200).abs() <= 1, "G expected ~200 got {g}");
    assert!((b as i32 - 200).abs() <= 1, "B expected ~200 got {b}");
    assert_eq!(a, 200); // alpha unchanged
}

#[test]
fn contrast_factor2_pushes_channels_away_from_midpoint() {
    let mut img = ImageData::new(1, 1);
    // R=200 → (200-128)*2+128 = 272 → 255 (clamped)
    // G=50  → (50-128)*2+128  = -28 → 0   (clamped)
    // B=128 → (128-128)*2+128 = 128 (unchanged)
    img.set_pixel(0, 0, 200, 50, 128, 255);
    img.contrast(2.0);
    let (r, g, b, a) = img.get_pixel(0, 0).unwrap();
    assert_eq!(r, 255);
    assert_eq!(g, 0);
    assert!((b as i32 - 128).abs() <= 1, "B expected ~128 got {b}");
    assert_eq!(a, 255);
}

#[test]
fn saturation_factor0_produces_greyscale() {
    let mut img = ImageData::new(1, 1);
    img.set_pixel(0, 0, 200, 100, 50, 255);
    img.saturation(0.0);
    let (r, g, b, a) = img.get_pixel(0, 0).unwrap();
    // All channels converge to luma = 0.2126*200 + 0.7152*100 + 0.0722*50 ≈ 117
    assert_eq!(r, g, "R and G must be equal after full desaturation");
    assert_eq!(g, b, "G and B must be equal after full desaturation");
    assert!((r as i32 - 117).abs() <= 1, "luma expected ~117 got {r}");
    assert_eq!(a, 255);
}

#[test]
fn gamma_1_leaves_pixel_unchanged() {
    let mut img = ImageData::new(1, 1);
    img.set_pixel(0, 0, 100, 150, 200, 128);
    img.gamma(1.0);
    let (r, g, b, a) = img.get_pixel(0, 0).unwrap();
    assert!((r as i32 - 100).abs() <= 1, "R expected ~100 got {r}");
    assert!((g as i32 - 150).abs() <= 1, "G expected ~150 got {g}");
    assert!((b as i32 - 200).abs() <= 1, "B expected ~200 got {b}");
    assert_eq!(a, 128);
}

#[test]
fn tint_factor1_replaces_pixel_with_tint_colour() {
    let mut img = ImageData::new(1, 1);
    img.set_pixel(0, 0, 50, 100, 150, 200);
    img.tint(255, 0, 0, 1.0);
    let (r, g, b, a) = img.get_pixel(0, 0).unwrap();
    assert_eq!(r, 255);
    assert_eq!(g, 0);
    assert_eq!(b, 0);
    assert_eq!(a, 200); // alpha unchanged
}

// ===========================================================================
// Effects: Filters
// ===========================================================================

#[test]
fn grayscale_pure_red_becomes_perceptual_grey() {
    let mut img = ImageData::new(1, 1);
    img.set_pixel(0, 0, 255, 0, 0, 255);
    img.grayscale();
    let (r, g, b, a) = img.get_pixel(0, 0).unwrap();
    // luma = round(0.2126 * 255) = round(54.213) = 54
    assert_eq!(r, g, "R and G must be equal after greyscale");
    assert_eq!(g, b, "G and B must be equal after greyscale");
    assert!((r as i32 - 54).abs() <= 1, "perceptual luma expected ~54, got {r}");
    assert_eq!(a, 255);
}

#[test]
fn sepia_white_pixel_produces_expected_values() {
    let mut img = ImageData::new(1, 1);
    img.set_pixel(0, 0, 255, 255, 255, 255);
    img.sepia();
    let (r, g, b, a) = img.get_pixel(0, 0).unwrap();
    // Row sums: R-row = 1.351 > 1, G-row = 1.203 > 1 → both saturate to 255.
    // B = 0.937 * 255 = 238.9 → 238.
    assert_eq!(r, 255, "R expected 255 (saturated), got {r}");
    assert_eq!(g, 255, "G expected 255 (saturated), got {g}");
    assert!((b as i32 - 238).abs() <= 1, "B expected ~238, got {b}");
    assert_eq!(a, 255);
}

#[test]
fn invert_produces_complement_values() {
    let mut img = ImageData::new(1, 1);
    img.set_pixel(0, 0, 100, 150, 200, 255);
    img.invert();
    // 255-100=155, 255-150=105, 255-200=55, alpha unchanged
    assert_eq!(img.get_pixel(0, 0), Some((155, 105, 55, 255)));
}

#[test]
fn threshold_above_produces_white_below_produces_black() {
    let mut img = ImageData::new(1, 2);
    img.set_pixel(0, 0, 200, 200, 200, 255); // luma ≈ 200 ≥ 128 → white
    img.set_pixel(0, 1, 10, 10, 10, 255);   // luma ≈ 10 < 128 → black
    img.threshold(128);
    assert_eq!(img.get_pixel(0, 0), Some((255, 255, 255, 255)));
    assert_eq!(img.get_pixel(0, 1), Some((0, 0, 0, 255)));
}

#[test]
fn posterize_levels2_quantises_to_black_or_white() {
    let mut img = ImageData::new(1, 2);
    img.set_pixel(0, 0, 64, 64, 64, 255);   // round(64/255) = 0 → 0*255 = 0
    img.set_pixel(0, 1, 200, 200, 200, 255); // round(200/255) = 1 → 1*255 = 255
    img.posterize(2);
    assert_eq!(img.get_pixel(0, 0), Some((0, 0, 0, 255)));
    assert_eq!(img.get_pixel(0, 1), Some((255, 255, 255, 255)));
}

#[test]
fn fill_overwrites_all_pixels_with_solid_colour() {
    let mut img = ImageData::new(3, 3);
    img.set_pixel(1, 1, 10, 20, 30, 40);
    img.fill(255, 0, 0, 255);
    assert_eq!(img.get_pixel(0, 0), Some((255, 0, 0, 255)));
    assert_eq!(img.get_pixel(1, 1), Some((255, 0, 0, 255)));
    assert_eq!(img.get_pixel(2, 2), Some((255, 0, 0, 255)));
}

#[test]
fn noise_amount0_leaves_pixel_unchanged() {
    let mut img = ImageData::new(1, 1);
    img.set_pixel(0, 0, 128, 128, 128, 200);
    img.noise(0);
    assert_eq!(img.get_pixel(0, 0), Some((128, 128, 128, 200)));
}

#[test]
fn noise_amount255_preserves_alpha_channel() {
    let mut img = ImageData::new(2, 2);
    img.set_pixel(0, 0, 128, 128, 128, 200);
    img.set_pixel(1, 0, 128, 128, 128, 200);
    img.noise(255);
    // Noise only modifies RGB channels (0..3 exclusive of alpha index 3)
    let (_, _, _, a0) = img.get_pixel(0, 0).unwrap();
    let (_, _, _, a1) = img.get_pixel(1, 0).unwrap();
    assert_eq!(a0, 200);
    assert_eq!(a1, 200);
}

#[test]
fn alpha_mask_factor_half_halves_alpha() {
    let mut img = ImageData::new(1, 1);
    img.set_pixel(0, 0, 100, 150, 200, 200);
    img.alpha_mask(0.5);
    let (r, g, b, a) = img.get_pixel(0, 0).unwrap();
    assert_eq!(r, 100);
    assert_eq!(g, 150);
    assert_eq!(b, 200);
    assert!((a as i32 - 100).abs() <= 1, "alpha expected ~100, got {a}");
}

// ===========================================================================
// Effects: Geometric (in-place)
// ===========================================================================

#[test]
fn flip_horizontal_moves_left_pixel_to_right_edge() {
    let mut img = ImageData::new(3, 1);
    img.set_pixel(0, 0, 255, 0, 0, 255); // red at left
    img.set_pixel(2, 0, 0, 0, 255, 255); // blue at right
    img.flip_horizontal();
    // Left (0,0) becomes right (2,0) and vice-versa
    assert_eq!(img.get_pixel(0, 0), Some((0, 0, 255, 255)));
    assert_eq!(img.get_pixel(2, 0), Some((255, 0, 0, 255)));
}

#[test]
fn flip_vertical_moves_top_pixel_to_bottom_edge() {
    let mut img = ImageData::new(1, 3);
    img.set_pixel(0, 0, 255, 0, 0, 255); // red at top
    img.set_pixel(0, 2, 0, 0, 255, 255); // blue at bottom
    img.flip_vertical();
    assert_eq!(img.get_pixel(0, 0), Some((0, 0, 255, 255)));
    assert_eq!(img.get_pixel(0, 2), Some((255, 0, 0, 255)));
}

// ===========================================================================
// Effects: Geometric (new image)
// ===========================================================================

#[test]
fn rotate_90_cw_swaps_dimensions_and_maps_pixels() {
    // Source: width=3, height=2
    let mut img = ImageData::new(3, 2);
    img.set_pixel(0, 0, 255, 0, 0, 255); // red at top-left
    let rotated = img.rotate_90_cw();
    // new_w = old_h = 2, new_h = old_w = 3
    assert_eq!(rotated.width(), 2);
    assert_eq!(rotated.height(), 3);
    // Pixel (x=0, y=0) → nx = old_h-1-0 = 1, ny = x = 0 → new position (1, 0)
    assert_eq!(rotated.get_pixel(1, 0), Some((255, 0, 0, 255)));
}

#[test]
fn crop_returns_correct_dimensions_and_pixels() {
    let mut img = ImageData::new(4, 4);
    img.set_pixel(1, 1, 255, 0, 0, 255);
    let cropped = img.crop(1, 1, 2, 2).expect("in-bounds crop should succeed");
    assert_eq!(cropped.width(), 2);
    assert_eq!(cropped.height(), 2);
    // Source (1,1) becomes (0,0) in the cropped image
    assert_eq!(cropped.get_pixel(0, 0), Some((255, 0, 0, 255)));
}

#[test]
fn crop_out_of_bounds_returns_none() {
    let img = ImageData::new(4, 4);
    // x=3 + w=2 = 5 > 4: rect exceeds image boundary
    assert!(img.crop(3, 3, 2, 2).is_none());
}

#[test]
fn resize_nearest_4x4_to_2x2_has_correct_dimensions() {
    let img = ImageData::new(4, 4);
    let resized = img.resize_nearest(2, 2);
    assert_eq!(resized.width(), 2);
    assert_eq!(resized.height(), 2);
}

// ===========================================================================
// Effects: Convolution
// ===========================================================================

#[test]
fn blur_radius0_returns_copy_with_same_pixels() {
    let mut img = ImageData::new(2, 2);
    img.set_pixel(0, 0, 100, 150, 200, 255);
    img.set_pixel(1, 1, 50, 75, 100, 128);
    let blurred = img.blur(0);
    assert_eq!(blurred.get_pixel(0, 0), Some((100, 150, 200, 255)));
    assert_eq!(blurred.get_pixel(1, 1), Some((50, 75, 100, 128)));
}

#[test]
fn blur_radius1_solid_colour_image_is_unchanged() {
    let mut img = ImageData::new(4, 4);
    img.fill(100, 150, 200, 255);
    let blurred = img.blur(1);
    // Every neighbour has the same value; box average equals the original.
    assert_eq!(blurred.get_pixel(0, 0), Some((100, 150, 200, 255)));
    assert_eq!(blurred.get_pixel(2, 2), Some((100, 150, 200, 255)));
}

#[test]
fn sharpen_flat_colour_image_is_unchanged() {
    let mut img = ImageData::new(4, 4);
    img.fill(100, 150, 200, 255);
    let sharpened = img.sharpen();
    // 5*c - top - bottom - left - right = 5*c - 4*c = c
    assert_eq!(sharpened.get_pixel(0, 0), Some((100, 150, 200, 255)));
    assert_eq!(sharpened.get_pixel(2, 2), Some((100, 150, 200, 255)));
}

// -----------------------------------------------------------------------
// LayeredImage tests
// -----------------------------------------------------------------------

#[test]
fn layered_image_new_is_empty() {
    let stack = LayeredImage::new(64, 64);
    assert_eq!(stack.layer_count(), 0);
    assert_eq!(stack.width(), 64);
    assert_eq!(stack.height(), 64);
}

#[test]
fn layered_image_add_layer_increments_count() {
    let mut stack = LayeredImage::new(8, 8);
    let idx0 = stack.add_layer("bg");
    let idx1 = stack.add_layer("fg");
    assert_eq!(idx0, 0);
    assert_eq!(idx1, 1);
    assert_eq!(stack.layer_count(), 2);
}

#[test]
fn layered_image_remove_layer_decrements_count() {
    let mut stack = LayeredImage::new(8, 8);
    stack.add_layer("a");
    stack.add_layer("b");
    assert!(stack.remove_layer(0).is_some());
    assert_eq!(stack.layer_count(), 1);
    assert!(stack.remove_layer(99).is_none());
}

#[test]
fn layered_image_set_get_opacity() {
    let mut stack = LayeredImage::new(4, 4);
    stack.add_layer("x");
    assert!(stack.set_opacity(0, 0.5));
    assert!((stack.get_layer(0).unwrap().opacity - 0.5).abs() < 1e-5);
    // clamp above 1.0
    stack.set_opacity(0, 2.0);
    assert!((stack.get_layer(0).unwrap().opacity - 1.0).abs() < 1e-5);
    // invalid index
    assert!(!stack.set_opacity(99, 0.5));
}

#[test]
fn layered_image_set_visible() {
    let mut stack = LayeredImage::new(4, 4);
    stack.add_layer("x");
    assert!(stack.set_visible(0, false));
    assert!(!stack.get_layer(0).unwrap().visible);
    assert!(stack.set_visible(0, true));
    assert!(stack.get_layer(0).unwrap().visible);
}

#[test]
fn layered_image_set_name() {
    let mut stack = LayeredImage::new(4, 4);
    stack.add_layer("original");
    assert!(stack.set_name(0, "renamed"));
    assert_eq!(&stack.get_layer(0).unwrap().name, "renamed");
}

#[test]
fn layered_image_swap_layers() {
    let mut stack = LayeredImage::new(4, 4);
    stack.add_layer("first");
    stack.add_layer("second");
    assert!(stack.swap_layers(0, 1));
    assert_eq!(&stack.get_layer(0).unwrap().name, "second");
    assert_eq!(&stack.get_layer(1).unwrap().name, "first");
    // invalid index
    assert!(!stack.swap_layers(0, 99));
    // same index = no-op
    assert!(!stack.swap_layers(0, 0));
}

#[test]
fn layered_image_move_layer() {
    let mut stack = LayeredImage::new(4, 4);
    stack.add_layer("a");
    stack.add_layer("b");
    stack.add_layer("c");
    assert!(stack.move_layer(0, 2));
    // a was at 0, moved to 2 → order becomes b, c, a
    assert_eq!(&stack.get_layer(0).unwrap().name, "b");
    assert_eq!(&stack.get_layer(2).unwrap().name, "a");
}

#[test]
fn layered_image_set_layer_image() {
    let mut stack = LayeredImage::new(4, 4);
    stack.add_layer("x");
    let mut src = ImageData::new(4, 4);
    src.fill(255, 0, 0, 255);
    assert!(stack.set_layer_image(0, &src));
    assert_eq!(
        stack.get_layer(0).unwrap().data.get_pixel(0, 0),
        Some((255, 0, 0, 255))
    );
    // invalid index
    assert!(!stack.set_layer_image(99, &src));
}

#[test]
fn layered_image_merge_single_opaque_layer() {
    let mut stack = LayeredImage::new(4, 4);
    stack.add_layer("bg");
    stack.get_layer_mut(0).unwrap().data.fill(255, 0, 0, 255);
    let merged = stack.merge();
    assert_eq!(merged.get_pixel(0, 0), Some((255, 0, 0, 255)));
    assert_eq!(merged.get_pixel(3, 3), Some((255, 0, 0, 255)));
}

#[test]
fn layered_image_merge_hidden_layer_is_excluded() {
    let mut stack = LayeredImage::new(4, 4);
    stack.add_layer("bg");
    stack.get_layer_mut(0).unwrap().data.fill(255, 0, 0, 255);
    stack.add_layer("fg");
    stack.get_layer_mut(1).unwrap().data.fill(0, 0, 255, 255);
    stack.set_visible(1, false);
    let merged = stack.merge();
    // fg is hidden, so only red background visible
    assert_eq!(merged.get_pixel(0, 0), Some((255, 0, 0, 255)));
}

#[test]
fn layered_image_merge_zero_opacity_layer_is_transparent() {
    let mut stack = LayeredImage::new(4, 4);
    stack.add_layer("bg");
    stack.get_layer_mut(0).unwrap().data.fill(255, 0, 0, 255);
    stack.add_layer("fg");
    stack.get_layer_mut(1).unwrap().data.fill(0, 0, 255, 255);
    stack.set_opacity(1, 0.0);
    let merged = stack.merge();
    // fg is fully transparent, so only red background visible
    assert_eq!(merged.get_pixel(0, 0), Some((255, 0, 0, 255)));
}

#[test]
fn layered_image_merge_full_overlap_top_wins() {
    let mut stack = LayeredImage::new(4, 4);
    stack.add_layer("bg");
    stack.get_layer_mut(0).unwrap().data.fill(255, 0, 0, 255);
    stack.add_layer("fg");
    stack.get_layer_mut(1).unwrap().data.fill(0, 0, 255, 255);
    let merged = stack.merge();
    // fg at full opacity covers bg entirely
    assert_eq!(merged.get_pixel(0, 0), Some((0, 0, 255, 255)));
}

#[test]
fn layered_image_merge_empty_stack_is_transparent() {
    let stack = LayeredImage::new(4, 4);
    let merged = stack.merge();
    assert_eq!(merged.get_pixel(0, 0), Some((0, 0, 0, 0)));
}

// -----------------------------------------------------------------------
// LIMG binary serialization tests
// -----------------------------------------------------------------------

use lurek2d::image::serial;

#[test]
fn serial_flat_roundtrip() {
    let tmp = std::env::temp_dir().join("luna2d_test_flat.lim");
    let path = tmp.to_str().unwrap();
    let mut img = ImageData::new(4, 4);
    img.set_pixel(0, 0, 255, 128, 64, 200);
    img.set_pixel(3, 3, 10, 20, 30, 40);
    serial::save_image(&img, path).expect("save_image");
    let loaded = serial::load_image(path).expect("load_image");
    assert_eq!(loaded.width(), img.width());
    assert_eq!(loaded.height(), img.height());
    assert_eq!(loaded.get_pixel(0, 0), Some((255, 128, 64, 200)));
    assert_eq!(loaded.get_pixel(3, 3), Some((10, 20, 30, 40)));
    let _ = std::fs::remove_file(path);
}

#[test]
fn serial_load_image_wrong_type_returns_error() {
    let tmp = std::env::temp_dir().join("luna2d_test_wrongtype.lim");
    let path = tmp.to_str().unwrap();
    let stack = LayeredImage::new(4, 4);
    serial::save_layered(&stack, path).expect("save_layered");
    let result = serial::load_image(path);
    assert!(result.is_err(), "Loading layered file as flat should error");
    let _ = std::fs::remove_file(path);
}

#[test]
fn serial_layered_roundtrip_preserves_layers() {
    let tmp = std::env::temp_dir().join("luna2d_test_layered.lim");
    let path = tmp.to_str().unwrap();
    let mut stack = LayeredImage::new(8, 8);
    let idx = stack.add_layer("background");
    stack.get_layer_mut(idx).unwrap().data.fill(255, 0, 0, 255);
    stack.set_opacity(idx, 0.8);
    let idx2 = stack.add_layer("foreground");
    stack.set_visible(idx2, false);
    serial::save_layered(&stack, path).expect("save_layered");
    let loaded = serial::load_layered(path).expect("load_layered");
    assert_eq!(loaded.layer_count(), 2);
    assert_eq!(loaded.width(), 8);
    assert_eq!(loaded.height(), 8);
    let bg = loaded.get_layer(0).unwrap();
    assert_eq!(&bg.name, "background");
    assert!((bg.opacity - 0.8).abs() < 1e-4);
    assert!(bg.visible);
    assert_eq!(bg.data.get_pixel(0, 0), Some((255, 0, 0, 255)));
    let fg = loaded.get_layer(1).unwrap();
    assert_eq!(&fg.name, "foreground");
    assert!(!fg.visible);
    let _ = std::fs::remove_file(path);
}

#[test]
fn serial_bad_magic_returns_error() {
    let tmp = std::env::temp_dir().join("luna2d_test_badmagic.lim");
    let path = tmp.to_str().unwrap();
    std::fs::write(path, b"NOPE\x01\x00" as &[u8]).unwrap();
    assert!(serial::load_image(path).is_err());
    let _ = std::fs::remove_file(path);
}

#[test]
fn serial_load_nonexistent_file_returns_error() {
    assert!(serial::load_image("/nonexistent/path/test.lim").is_err());
    assert!(serial::load_layered("/nonexistent/path/test.lim").is_err());
}
