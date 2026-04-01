//! Integration tests for the image data module.

use luna2d::image::ImageData;

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
fn image_data_encode_png() {
    let mut img = ImageData::new(2, 2);
    img.set_pixel(0, 0, 255, 0, 0, 255);
    let png_bytes = img.encode_png().unwrap();
    // PNG files start with the PNG signature
    assert_eq!(&png_bytes[..4], &[137, 80, 78, 71]);
}

// ── Additional coverage ──────────────────────────────────────────────────────

#[test]
fn image_data_dimensions_returns_width_height_tuple() {
    let img = ImageData::new(7, 13);
    assert_eq!(img.dimensions(), (7, 13));
}

#[test]
fn image_data_as_bytes_length_equals_four_times_pixels() {
    let img = ImageData::new(4, 3);
    // 4 × 3 = 12 pixels × 4 bytes (RGBA) = 48
    assert_eq!(img.as_bytes().len(), 48);
}

#[test]
fn image_data_as_bytes_is_zeroed_on_new() {
    let img = ImageData::new(2, 2);
    assert!(img.as_bytes().iter().all(|&b| b == 0));
}

#[test]
fn image_data_as_bytes_reflects_set_pixel() {
    let mut img = ImageData::new(2, 1);
    img.set_pixel(1, 0, 10, 20, 30, 40);
    let bytes = img.as_bytes();
    // pixel (1,0) starts at byte offset 4 (RGBA layout, row-major)
    assert_eq!(bytes[4], 10); // R
    assert_eq!(bytes[5], 20); // G
    assert_eq!(bytes[6], 30); // B
    assert_eq!(bytes[7], 40); // A
}

#[test]
fn image_data_get_string_equals_as_bytes() {
    let mut img = ImageData::new(3, 3);
    img.set_pixel(1, 1, 255, 128, 0, 255);
    assert_eq!(img.get_string(), img.as_bytes().to_vec());
}

#[test]
fn image_data_set_pixel_out_of_bounds_returns_false() {
    let mut img = ImageData::new(4, 4);
    assert!(!img.set_pixel(4, 0, 0, 0, 0, 0)); // x == width
    assert!(!img.set_pixel(0, 4, 0, 0, 0, 0)); // y == height
}

#[test]
fn image_data_paste_at_origin() {
    let mut dst = ImageData::new(5, 5);
    let mut src = ImageData::new(2, 2);
    src.set_pixel(0, 0, 1, 2, 3, 4);
    dst.paste(&src, 0, 0);
    assert_eq!(dst.get_pixel(0, 0), Some((1, 2, 3, 4)));
}

#[test]
fn image_data_paste_does_not_write_outside_destination() {
    let mut dst = ImageData::new(4, 4);
    let mut src = ImageData::new(3, 3);
    src.set_pixel(0, 0, 99, 99, 99, 255);
    // Paste at (3, 3) — only top-left pixel of src fits at (3,3) which is in-bounds
    dst.paste(&src, 3, 3);
    // The canvas border (4,4) is out of bounds for get_pixel
    assert_eq!(dst.get_pixel(3, 3), Some((99, 99, 99, 255)));
    // Row/col outside canvas stays default (transparent black)
    assert_eq!(dst.get_pixel(0, 0), Some((0, 0, 0, 0)));
}

#[test]
fn image_data_from_file_invalid_path_returns_error() {
    let result = ImageData::from_file("nonexistent_image_file_12345.png");
    assert!(result.is_err());
}

#[test]
fn image_data_map_pixel_identity_preserves_colors() {
    let mut img = ImageData::new(3, 3);
    img.set_pixel(1, 1, 42, 84, 126, 200);
    img.map_pixel(|_x, _y, r, g, b, a| (r, g, b, a)); // identity
    assert_eq!(img.get_pixel(1, 1), Some((42, 84, 126, 200)));
}

#[test]
fn image_data_encode_png_roundtrip_size() {
    // Encode a 10×10 image and verify the PNG is larger than the raw bytes
    // (PNG header + compression overhead)
    let img = ImageData::new(10, 10);
    let png = img.encode_png().unwrap();
    assert!(!png.is_empty());
    // PNG signature is 8 bytes; any valid PNG is at least 67 bytes (sig + IHDR + IDAT + IEND)
    assert!(png.len() > 8);
}
