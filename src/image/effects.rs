//! CPU-side image-processing effects for `ImageData`.
//!
//! Provides 20 pixel-manipulation effects grouped into four categories:
//!
//! - **Color / Tone** — brightness, contrast, saturation, gamma, tint
//! - **Filters** — grayscale, sepia, invert, threshold, posterize, fill, noise, alpha_mask
//! - **Geometric (in-place)** — flip_horizontal, flip_vertical
//! - **Geometric (new image)** — rotate_90_cw, crop, resize_nearest
//! - **Convolution** — blur, sharpen
//!
//! All effects are CPU-only; no GPU dependency is required or used.
//! Effects that work in-place take `&mut self`; effects that produce a new image take `&self`
//! and return a new `ImageData`.  Apply effects after loading an image and before uploading
//! to the GPU via `lurek.img.*`.

use super::image_data::ImageData;

impl ImageData {
    // ── Color / Tone ────────────────────────────────────────────────────────

    /// Multiply every RGB channel by `factor`, leaving alpha unchanged.
    ///
    /// Values are clamped to the range \[0, 255\] after multiplication.
    /// `factor` values above 1.0 brighten the image; values below 1.0 darken it.
    /// A `factor` of 0.0 produces a fully black image (with original alpha).
    ///
    /// # Parameters
    /// - `factor` — `f32`. Multiplier applied to each R, G, B channel.
    pub fn brightness(&mut self, factor: f32) {
        self.map_pixel(|_, _, r, g, b, a| {
            let r = (r as f32 * factor).clamp(0.0, 255.0) as u8;
            let g = (g as f32 * factor).clamp(0.0, 255.0) as u8;
            let b = (b as f32 * factor).clamp(0.0, 255.0) as u8;
            (r, g, b, a)
        });
    }

    /// Adjust the contrast of every RGB channel, leaving alpha unchanged.
    ///
    /// For each channel the new value is computed as
    /// `((ch - 128) * factor + 128).clamp(0, 255)`.
    /// `factor` = 1.0 leaves the image unchanged; values above 1.0 increase contrast
    /// (pushing pixels away from mid-grey); values below 1.0 reduce contrast.
    ///
    /// # Parameters
    /// - `factor` — `f32`. Contrast multiplier around the mid-point 128.
    pub fn contrast(&mut self, factor: f32) {
        self.map_pixel(|_, _, r, g, b, a| {
            let apply = |ch: u8| ((ch as f32 - 128.0) * factor + 128.0).clamp(0.0, 255.0) as u8;
            (apply(r), apply(g), apply(b), a)
        });
    }

    /// Scale the colour saturation of every pixel, leaving alpha unchanged.
    ///
    /// Luminance is computed as `0.2126*R + 0.7152*G + 0.0722*B`.  Each channel is
    /// linearly interpolated from `luma` (fully desaturated) toward its original value
    /// by `factor`.  `factor` = 1.0 → unchanged, 0.0 → greyscale, > 1.0 → boosted
    /// saturation (channels may clip at 0 or 255).
    ///
    /// # Parameters
    /// - `factor` — `f32`. Saturation scale: 0.0 = greyscale, 1.0 = original, > 1.0 = boosted.
    pub fn saturation(&mut self, factor: f32) {
        self.map_pixel(|_, _, r, g, b, a| {
            let luma = 0.2126 * r as f32 + 0.7152 * g as f32 + 0.0722 * b as f32;
            let lerp = |ch: f32| (luma + (ch - luma) * factor).clamp(0.0, 255.0) as u8;
            (lerp(r as f32), lerp(g as f32), lerp(b as f32), a)
        });
    }

    /// Apply gamma correction to every RGB channel, leaving alpha unchanged.
    ///
    /// For each channel the transformation is `(ch / 255) ^ (1 / gamma) * 255`.
    /// `gamma` > 1.0 brightens mid-tones; `gamma` < 1.0 darkens them (equivalent to
    /// standard monitor gamma encoding).  `gamma` must be a positive non-zero value;
    /// passing 0.0 produces undefined results due to division by zero.
    ///
    /// # Parameters
    /// - `gamma` — `f32`. Gamma exponent denominator (typically 0.4–2.2).
    pub fn gamma(&mut self, gamma: f32) {
        self.map_pixel(|_, _, r, g, b, a| {
            let apply =
                |ch: u8| ((ch as f32 / 255.0).powf(1.0 / gamma) * 255.0).clamp(0.0, 255.0) as u8;
            (apply(r), apply(g), apply(b), a)
        });
    }

    /// Blend every RGB pixel toward a target tint colour, leaving alpha unchanged.
    ///
    /// Each channel is linearly interpolated: `new = lerp(original, tint, factor)`.
    /// `factor` = 0.0 leaves the image unchanged; `factor` = 1.0 fills all pixels with the
    /// tint colour; intermediate values produce a colour cast.
    ///
    /// # Parameters
    /// - `tr` — `u8`. Red component of the tint colour (0–255).
    /// - `tg` — `u8`. Green component of the tint colour (0–255).
    /// - `tb` — `u8`. Blue component of the tint colour (0–255).
    /// - `factor` — `f32`. Blend weight from 0.0 (no tint) to 1.0 (full tint colour).
    pub fn tint(&mut self, tr: u8, tg: u8, tb: u8, factor: f32) {
        let lerp = |a: u8, b: u8| (a as f32 + (b as f32 - a as f32) * factor).clamp(0.0, 255.0) as u8;
        self.map_pixel(|_, _, r, g, b, a| (lerp(r, tr), lerp(g, tg), lerp(b, tb), a));
    }

    // ── Filters ─────────────────────────────────────────────────────────────

    /// Convert every pixel to greyscale using perceptual luminance weights, leaving alpha unchanged.
    ///
    /// Luminance is `round(0.2126*R + 0.7152*G + 0.0722*B)` and is written to all three
    /// colour channels, producing a greyscale image in RGB space.
    pub fn grayscale(&mut self) {
        self.map_pixel(|_, _, r, g, b, a| {
            let luma = (0.2126 * r as f32 + 0.7152 * g as f32 + 0.0722 * b as f32).round() as u8;
            (luma, luma, luma, a)
        });
    }

    /// Apply a classic sepia-tone filter to every pixel, leaving alpha unchanged.
    ///
    /// Uses the standard sepia matrix:
    /// - `new_R = 0.393*R + 0.769*G + 0.189*B`
    /// - `new_G = 0.349*R + 0.686*G + 0.168*B`
    /// - `new_B = 0.272*R + 0.534*G + 0.131*B`
    ///
    /// All output channels are clamped to \[0, 255\].
    pub fn sepia(&mut self) {
        self.map_pixel(|_, _, r, g, b, a| {
            let rf = r as f32;
            let gf = g as f32;
            let bf = b as f32;
            let nr = (0.393 * rf + 0.769 * gf + 0.189 * bf).clamp(0.0, 255.0) as u8;
            let ng = (0.349 * rf + 0.686 * gf + 0.168 * bf).clamp(0.0, 255.0) as u8;
            let nb = (0.272 * rf + 0.534 * gf + 0.131 * bf).clamp(0.0, 255.0) as u8;
            (nr, ng, nb, a)
        });
    }

    /// Invert every RGB channel (`new = 255 - ch`), leaving alpha unchanged.
    pub fn invert(&mut self) {
        self.map_pixel(|_, _, r, g, b, a| (255 - r, 255 - g, 255 - b, a));
    }

    /// Convert each pixel to black or white based on its luminance, leaving alpha unchanged.
    ///
    /// Luminance is computed with the same perceptual weights as `grayscale`.
    /// If `luma >= value` the pixel becomes white (255, 255, 255); otherwise black (0, 0, 0).
    ///
    /// # Parameters
    /// - `value` — `u8`. Luminance threshold (0–255). 128 is a typical midpoint.
    pub fn threshold(&mut self, value: u8) {
        self.map_pixel(|_, _, r, g, b, a| {
            let luma = (0.2126 * r as f32 + 0.7152 * g as f32 + 0.0722 * b as f32).round() as u8;
            let v = if luma >= value { 255 } else { 0 };
            (v, v, v, a)
        });
    }

    /// Reduce the number of distinct colour levels per channel, leaving alpha unchanged.
    ///
    /// `levels` is clamped to a minimum of 2.  Each channel is quantised so that the output
    /// only contains `levels` evenly-spaced values in \[0, 255\].
    ///
    /// # Parameters
    /// - `levels` — `u8`. Number of distinct levels per channel (minimum 2, maximum 255).
    pub fn posterize(&mut self, levels: u8) {
        let levels = levels.max(2);
        let l = levels as f32 - 1.0;
        self.map_pixel(|_, _, r, g, b, a| {
            let apply = |ch: u8| ((ch as f32 / 255.0 * l).round() / l * 255.0).round() as u8;
            (apply(r), apply(g), apply(b), a)
        });
    }

    /// Fill the entire image with a single solid colour.
    ///
    /// Every pixel, including alpha, is overwritten with the supplied RGBA value.
    ///
    /// # Parameters
    /// - `r` — `u8`. Red component (0–255).
    /// - `g` — `u8`. Green component (0–255).
    /// - `b` — `u8`. Blue component (0–255).
    /// - `a` — `u8`. Alpha component (0–255).
    pub fn fill(&mut self, r: u8, g: u8, b: u8, a: u8) {
        self.map_pixel(|_, _, _, _, _, _| (r, g, b, a));
    }

    /// Add pseudo-random noise to every RGB channel, leaving alpha unchanged.
    ///
    /// For each pixel a value in `[-amount, +amount]` is sampled from an LCG (linear
    /// congruential generator) seeded from the image dimensions, advanced once per pixel.
    /// The result is clamped to \[0, 255\].  `amount` = 0 produces no change.
    ///
    /// # Parameters
    /// - `amount` — `u8`. Maximum noise magnitude per channel (0 = no noise, 255 = maximum).
    pub fn noise(&mut self, amount: u8) {
        if amount == 0 {
            return;
        }
        let w = self.width;
        let h = self.height;
        let mut seed = (w as u64)
            .wrapping_mul(6_364_136_223_846_793_005)
            .wrapping_add(1_442_695_040_888_963_407);
        let range = amount as i32 * 2 + 1;
        let pixels = self.pixels.as_mut_slice();
        for _y in 0..h {
            for _x in 0..w {
                let idx = ((_y * w + _x) * 4) as usize;
                for ch in 0..3usize {
                    seed = seed
                        .wrapping_mul(6_364_136_223_846_793_005)
                        .wrapping_add(1_442_695_040_888_963_407);
                    let offset = ((seed >> 33) as i32 % range) - amount as i32;
                    pixels[idx + ch] =
                        (pixels[idx + ch] as i32 + offset).clamp(0, 255) as u8;
                }
            }
        }
    }

    /// Multiply the alpha channel of every pixel by `factor`, leaving RGB unchanged.
    ///
    /// `factor` = 1.0 leaves alpha unchanged; 0.0 makes the image fully transparent;
    /// intermediate values reduce opacity proportionally.  The result is clamped to \[0, 255\].
    ///
    /// # Parameters
    /// - `factor` — `f32`. Alpha multiplier (0.0 = fully transparent, 1.0 = unchanged).
    pub fn alpha_mask(&mut self, factor: f32) {
        self.map_pixel(|_, _, r, g, b, a| {
            let na = (a as f32 * factor).clamp(0.0, 255.0) as u8;
            (r, g, b, na)
        });
    }

    // ── Geometric (in-place) ────────────────────────────────────────────────

    /// Flip the image horizontally in-place (left ↔ right mirror).
    ///
    /// Each row's pixels are reversed so that the left edge becomes the right edge.
    /// The image dimensions are unchanged.
    pub fn flip_horizontal(&mut self) {
        let w = self.width as usize;
        let h = self.height as usize;
        for y in 0..h {
            let row_start = y * w * 4;
            let row = &mut self.pixels[row_start..row_start + w * 4];
            for x in 0..w / 2 {
                let left = x * 4;
                let right = (w - 1 - x) * 4;
                for i in 0..4 {
                    row.swap(left + i, right + i);
                }
            }
        }
    }

    /// Flip the image vertically in-place (top ↔ bottom mirror).
    ///
    /// Rows are swapped symmetrically so that the top row becomes the bottom row.
    /// The image dimensions are unchanged.
    pub fn flip_vertical(&mut self) {
        let w = self.width as usize;
        let h = self.height as usize;
        for y in 0..h / 2 {
            let top = y * w * 4;
            let bottom = (h - 1 - y) * w * 4;
            for i in 0..w * 4 {
                self.pixels.swap(top + i, bottom + i);
            }
        }
    }

    // ── Geometric (new image) ───────────────────────────────────────────────

    /// Rotate the image 90° clockwise and return the result as a new `ImageData`.
    ///
    /// The output dimensions are swapped: `new_width = old_height`, `new_height = old_width`.
    /// The mapping from old pixel `(x, y)` to new pixel `(old_h - 1 - y, x)` is applied.
    ///
    /// # Returns
    /// `ImageData`. A new image rotated 90° clockwise.
    pub fn rotate_90_cw(&self) -> ImageData {
        let old_w = self.width;
        let old_h = self.height;
        let new_w = old_h;
        let new_h = old_w;
        let mut out = ImageData::new(new_w, new_h);
        for y in 0..old_h {
            for x in 0..old_w {
                if let Some((r, g, b, a)) = self.get_pixel(x, y) {
                    let nx = old_h - 1 - y;
                    let ny = x;
                    out.set_pixel(nx, ny, r, g, b, a);
                }
            }
        }
        out
    }

    /// Extract a rectangular sub-region and return it as a new `ImageData`.
    ///
    /// Returns `None` if any part of the requested rectangle lies outside the image bounds.
    /// The output image has dimensions `(w, h)` and contains exactly the pixels at
    /// `(x..x+w, y..y+h)` in the source.
    ///
    /// # Parameters
    /// - `x` — `u32`. Left edge of the crop rectangle (inclusive).
    /// - `y` — `u32`. Top edge of the crop rectangle (inclusive).
    /// - `w` — `u32`. Width of the crop rectangle in pixels (must be at least 1).
    /// - `h` — `u32`. Height of the crop rectangle in pixels (must be at least 1).
    ///
    /// # Returns
    /// `Option<ImageData>`. `Some(image)` on success, `None` if out of bounds.
    pub fn crop(&self, x: u32, y: u32, w: u32, h: u32) -> Option<ImageData> {
        if w == 0 || h == 0 || x + w > self.width || y + h > self.height {
            return None;
        }
        let mut out = ImageData::new(w, h);
        for row in 0..h {
            let src_start = ((y + row) * self.width + x) as usize * 4;
            let dst_start = (row * w) as usize * 4;
            out.pixels[dst_start..dst_start + w as usize * 4]
                .copy_from_slice(&self.pixels[src_start..src_start + w as usize * 4]);
        }
        Some(out)
    }

    /// Scale the image to new dimensions using nearest-neighbour interpolation.
    ///
    /// Each pixel in the output is sampled from the closest pixel in the source image.
    /// No blending is performed; the result may appear blocky for large upscales.
    /// Zero-size dimensions produce an empty image with no pixels.
    ///
    /// # Parameters
    /// - `new_w` — `u32`. Target width in pixels.
    /// - `new_h` — `u32`. Target height in pixels.
    ///
    /// # Returns
    /// `ImageData`. A new image scaled to `(new_w, new_h)`.
    pub fn resize_nearest(&self, new_w: u32, new_h: u32) -> ImageData {
        let mut out = ImageData::new(new_w, new_h);
        if new_w == 0 || new_h == 0 || self.width == 0 || self.height == 0 {
            return out;
        }
        for ny in 0..new_h {
            for nx in 0..new_w {
                let src_x = (nx * self.width / new_w).min(self.width - 1);
                let src_y = (ny * self.height / new_h).min(self.height - 1);
                if let Some((r, g, b, a)) = self.get_pixel(src_x, src_y) {
                    out.set_pixel(nx, ny, r, g, b, a);
                }
            }
        }
        out
    }

    // ── Convolution ─────────────────────────────────────────────────────────

    /// Apply a box blur with the given radius and return the result as a new `ImageData`.
    ///
    /// Uses a two-pass (horizontal then vertical) separated box filter for efficiency.
    /// Each output pixel is the arithmetic mean of all source pixels within a
    /// `(2*radius+1) × (2*radius+1)` window, clamped to image edges.
    /// All four channels (including alpha) are blurred.
    /// `radius` = 0 returns a copy of the original image.
    ///
    /// # Parameters
    /// - `radius` — `u32`. Half-size of the box filter kernel.
    ///
    /// # Returns
    /// `ImageData`. A new blurred image with the same dimensions.
    pub fn blur(&self, radius: u32) -> ImageData {
        if radius == 0 {
            return self.clone();
        }
        let w = self.width as usize;
        let h = self.height as usize;
        let r = radius as usize;

        // Horizontal pass → tmp
        let mut tmp_pixels = vec![0u8; w * h * 4];
        for y in 0..h {
            for x in 0..w {
                let x_min = x.saturating_sub(r);
                let x_max = (x + r).min(w - 1);
                let count = (x_max - x_min + 1) as u32;
                let mut sums = [0u32; 4];
                for sx in x_min..=x_max {
                    let idx = (y * w + sx) * 4;
                    for c in 0..4 {
                        sums[c] += self.pixels[idx + c] as u32;
                    }
                }
                let dst = (y * w + x) * 4;
                for c in 0..4 {
                    tmp_pixels[dst + c] = (sums[c] / count) as u8;
                }
            }
        }

        // Vertical pass → out
        let mut out = ImageData::new(self.width, self.height);
        for y in 0..h {
            for x in 0..w {
                let y_min = y.saturating_sub(r);
                let y_max = (y + r).min(h - 1);
                let count = (y_max - y_min + 1) as u32;
                let mut sums = [0u32; 4];
                for sy in y_min..=y_max {
                    let idx = (sy * w + x) * 4;
                    for c in 0..4 {
                        sums[c] += tmp_pixels[idx + c] as u32;
                    }
                }
                let dst = (y * w + x) * 4;
                for c in 0..4 {
                    out.pixels[dst + c] = (sums[c] / count) as u8;
                }
            }
        }
        out
    }

    /// Apply a 3×3 sharpen kernel and return the result as a new `ImageData`.
    ///
    /// The kernel has centre weight 5 and direct-neighbour weights -1 (corners are 0):
    /// `result = 5*C - top - bottom - left - right`. RGB channels are sharpened and clamped
    /// to \[0, 255\]; alpha is copied unchanged from the source pixel.
    /// Edge pixels use edge-clamping (the nearest in-bounds pixel is repeated).
    ///
    /// # Returns
    /// `ImageData`. A new sharpened image with the same dimensions.
    pub fn sharpen(&self) -> ImageData {
        let w = self.width as i32;
        let h = self.height as i32;
        let mut out = ImageData::new(self.width, self.height);

        let clamp_coord = |v: i32, max: i32| v.clamp(0, max - 1) as u32;
        let get = |px: i32, py: i32, c: usize| {
            let x = clamp_coord(px, w);
            let y = clamp_coord(py, h);
            self.pixels[((y * self.width + x) * 4) as usize + c]
        };

        for y in 0..h {
            for x in 0..w {
                let src_a = get(x, y, 3);
                for c in 0..3usize {
                    let center = get(x, y, c) as i32;
                    let top = get(x, y - 1, c) as i32;
                    let bottom = get(x, y + 1, c) as i32;
                    let left = get(x - 1, y, c) as i32;
                    let right = get(x + 1, y, c) as i32;
                    let v = (5 * center - top - bottom - left - right).clamp(0, 255) as u8;
                    out.pixels[((y * w + x) * 4) as usize + c] = v;
                }
                out.pixels[((y * w + x) * 4) as usize + 3] = src_a;
            }
        }
        out
    }
}
