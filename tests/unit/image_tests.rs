//! Integration tests for the image data module.

use luna2d::image::{CompressedImageData, ImageData};

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
