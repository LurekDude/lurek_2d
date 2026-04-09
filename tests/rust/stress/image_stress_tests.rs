//! Stress tests for the image module — large image buffers and operations.

use lurek2d::image::ImageData;

#[test]
fn stress_large_image_creation() {
    let img = ImageData::new(2048, 2048);
    assert_eq!(img.width(), 2048);
    assert_eq!(img.height(), 2048);
}

#[test]
fn stress_large_image_fill() {
    let mut img = ImageData::new(1024, 1024);
    for y in 0..1024 {
        for x in 0..1024 {
            img.set_pixel(x, y, 255, 128, 64, 255);
        }
    }
    // Spot-check
    assert_eq!(img.get_pixel(0, 0), Some((255, 128, 64, 255)));
    assert_eq!(img.get_pixel(1023, 1023), Some((255, 128, 64, 255)));
    assert_eq!(img.get_pixel(512, 512), Some((255, 128, 64, 255)));
}

#[test]
fn stress_image_gradient() {
    let mut img = ImageData::new(256, 256);
    for y in 0..256_u32 {
        for x in 0..256_u32 {
            img.set_pixel(x, y, x as u8, y as u8, 128, 255);
        }
    }
    assert_eq!(img.get_pixel(0, 0), Some((0, 0, 128, 255)));
    assert_eq!(img.get_pixel(255, 255), Some((255, 255, 128, 255)));
    assert_eq!(img.get_pixel(128, 64), Some((128, 64, 128, 255)));
}

#[test]
fn stress_image_map_pixel() {
    let mut img = ImageData::new(512, 512);
    for y in 0..512 {
        for x in 0..512 {
            img.set_pixel(x, y, 100, 100, 100, 255);
        }
    }
    // Invert all pixels
    img.map_pixel(|_x, _y, r, g, b, a| (255 - r, 255 - g, 255 - b, a));
    assert_eq!(img.get_pixel(0, 0), Some((155, 155, 155, 255)));
    assert_eq!(img.get_pixel(511, 511), Some((155, 155, 155, 255)));
}

#[test]
fn stress_image_paste() {
    let mut dest = ImageData::new(1024, 1024);
    let mut src = ImageData::new(128, 128);
    for y in 0..128 {
        for x in 0..128 {
            src.set_pixel(x, y, 255, 0, 0, 255);
        }
    }
    // Paste src at multiple positions
    for row in 0..8 {
        for col in 0..8 {
            dest.paste(&src, col * 128, row * 128);
        }
    }
    // Verify pasted areas
    assert_eq!(dest.get_pixel(0, 0), Some((255, 0, 0, 255)));
    assert_eq!(dest.get_pixel(127, 127), Some((255, 0, 0, 255)));
    assert_eq!(dest.get_pixel(128, 128), Some((255, 0, 0, 255)));
}

#[test]
fn stress_image_encode_png_large() {
    let mut img = ImageData::new(256, 256);
    for y in 0..256 {
        for x in 0..256 {
            img.set_pixel(x, y, (x % 256) as u8, (y % 256) as u8, 128, 255);
        }
    }
    let png = img.encode_png().unwrap();
    // PNG signature check
    assert_eq!(&png[..4], &[137, 80, 78, 71]);
    // Should produce a reasonable number of bytes
    assert!(png.len() > 100, "PNG should not be trivially small");
    assert!(
        png.len() < 256 * 256 * 4 + 1024,
        "PNG should be smaller than raw bitmap"
    );
}

#[test]
fn stress_image_from_bytes() {
    let w = 512_u32;
    let h = 512_u32;
    let mut bytes = vec![0u8; (w * h * 4) as usize];
    // Fill with checkerboard pattern
    for y in 0..h {
        for x in 0..w {
            let idx = ((y * w + x) * 4) as usize;
            if (x + y) % 2 == 0 {
                bytes[idx] = 255;
                bytes[idx + 1] = 255;
                bytes[idx + 2] = 255;
                bytes[idx + 3] = 255;
            } else {
                bytes[idx + 3] = 255;
            }
        }
    }
    let img = ImageData::from_bytes(w, h, bytes).unwrap();
    assert_eq!(img.get_pixel(0, 0), Some((255, 255, 255, 255)));
    assert_eq!(img.get_pixel(1, 0), Some((0, 0, 0, 255)));
}
