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
