use super::image_data::ImageData;
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ResizeFilter {
    Bilinear,
    Lanczos3,
}
impl ResizeFilter {
    pub fn parse(value: &str) -> Option<Self> {
        match value.to_ascii_lowercase().as_str() {
            "bilinear" | "linear" => Some(Self::Bilinear),
            "lanczos3" => Some(Self::Lanczos3),
            _ => None,
        }
    }
}
fn sinc(x: f32) -> f32 {
    if x.abs() < f32::EPSILON {
        1.0
    } else {
        let px = std::f32::consts::PI * x;
        px.sin() / px
    }
}
fn lanczos_weight(x: f32, a: f32) -> f32 {
    let ax = x.abs();
    if ax >= a {
        0.0
    } else {
        sinc(x) * sinc(x / a)
    }
}
impl ImageData {
    pub fn brightness(&mut self, factor: f32) {
        self.map_pixel_par(|_, _, r, g, b, a| {
            let r = (r as f32 * factor).clamp(0.0, 255.0) as u8;
            let g = (g as f32 * factor).clamp(0.0, 255.0) as u8;
            let b = (b as f32 * factor).clamp(0.0, 255.0) as u8;
            (r, g, b, a)
        });
    }
    pub fn contrast(&mut self, factor: f32) {
        self.map_pixel_par(|_, _, r, g, b, a| {
            let apply = |ch: u8| ((ch as f32 - 128.0) * factor + 128.0).clamp(0.0, 255.0) as u8;
            (apply(r), apply(g), apply(b), a)
        });
    }
    pub fn saturation(&mut self, factor: f32) {
        self.map_pixel_par(|_, _, r, g, b, a| {
            let luma = 0.2126 * r as f32 + 0.7152 * g as f32 + 0.0722 * b as f32;
            let lerp = |ch: f32| (luma + (ch - luma) * factor).clamp(0.0, 255.0) as u8;
            (lerp(r as f32), lerp(g as f32), lerp(b as f32), a)
        });
    }
    pub fn gamma(&mut self, gamma: f32) {
        self.map_pixel_par(|_, _, r, g, b, a| {
            let apply =
                |ch: u8| ((ch as f32 / 255.0).powf(1.0 / gamma) * 255.0).clamp(0.0, 255.0) as u8;
            (apply(r), apply(g), apply(b), a)
        });
    }
    pub fn tint(&mut self, tr: u8, tg: u8, tb: u8, factor: f32) {
        self.map_pixel_par(move |_, _, r, g, b, a| {
            let lerp = |from: u8, to: u8| {
                (from as f32 + (to as f32 - from as f32) * factor).clamp(0.0, 255.0) as u8
            };
            (lerp(r, tr), lerp(g, tg), lerp(b, tb), a)
        });
    }
    pub fn grayscale(&mut self) {
        self.map_pixel_par(|_, _, r, g, b, a| {
            let luma = (0.2126 * r as f32 + 0.7152 * g as f32 + 0.0722 * b as f32).round() as u8;
            (luma, luma, luma, a)
        });
    }
    pub fn sepia(&mut self) {
        self.map_pixel_par(|_, _, r, g, b, a| {
            let rf = r as f32;
            let gf = g as f32;
            let bf = b as f32;
            let nr = (0.393 * rf + 0.769 * gf + 0.189 * bf).clamp(0.0, 255.0) as u8;
            let ng = (0.349 * rf + 0.686 * gf + 0.168 * bf).clamp(0.0, 255.0) as u8;
            let nb = (0.272 * rf + 0.534 * gf + 0.131 * bf).clamp(0.0, 255.0) as u8;
            (nr, ng, nb, a)
        });
    }
    pub fn invert(&mut self) {
        self.map_pixel_par(|_, _, r, g, b, a| (255 - r, 255 - g, 255 - b, a));
    }
    pub fn threshold(&mut self, value: u8) {
        self.map_pixel_par(move |_, _, r, g, b, a| {
            let luma = (0.2126 * r as f32 + 0.7152 * g as f32 + 0.0722 * b as f32).round() as u8;
            let v = if luma >= value { 255 } else { 0 };
            (v, v, v, a)
        });
    }
    pub fn posterize(&mut self, levels: u8) {
        let levels = levels.max(2);
        let l = levels as f32 - 1.0;
        self.map_pixel_par(move |_, _, r, g, b, a| {
            let apply = |ch: u8| ((ch as f32 / 255.0 * l).round() / l * 255.0).round() as u8;
            (apply(r), apply(g), apply(b), a)
        });
    }
    pub fn fill(&mut self, r: u8, g: u8, b: u8, a: u8) {
        self.map_pixel_par(move |_, _, _, _, _, _| (r, g, b, a));
    }
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
                    pixels[idx + ch] = (pixels[idx + ch] as i32 + offset).clamp(0, 255) as u8;
                }
            }
        }
    }
    pub fn alpha_mask(&mut self, factor: f32) {
        self.map_pixel(|_, _, r, g, b, a| {
            let na = (a as f32 * factor).clamp(0.0, 255.0) as u8;
            (r, g, b, na)
        });
    }
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
    #[allow(clippy::needless_range_loop)]
    pub fn blur(&self, radius: u32) -> ImageData {
        if radius == 0 {
            return self.clone();
        }
        let w = self.width as usize;
        let h = self.height as usize;
        let r = radius as usize;
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
    pub fn resize(&self, new_w: u32, new_h: u32) -> Option<ImageData> {
        self.resize_with_filter(new_w, new_h, ResizeFilter::Bilinear)
    }
    pub fn resize_with_filter(
        &self,
        new_w: u32,
        new_h: u32,
        filter: ResizeFilter,
    ) -> Option<ImageData> {
        if new_w == 0 || new_h == 0 {
            return None;
        }
        match filter {
            ResizeFilter::Bilinear => self.resize_bilinear(new_w, new_h),
            ResizeFilter::Lanczos3 => Some(self.resize_lanczos3(new_w, new_h)),
        }
    }
    fn resize_bilinear(&self, new_w: u32, new_h: u32) -> Option<ImageData> {
        let src_w = self.width as f32;
        let src_h = self.height as f32;
        let mut out = ImageData::new(new_w, new_h);
        for dy in 0..new_h {
            for dx in 0..new_w {
                let sx = (dx as f32 + 0.5) * src_w / new_w as f32 - 0.5;
                let sy = (dy as f32 + 0.5) * src_h / new_h as f32 - 0.5;
                let x0 = sx.floor() as i32;
                let y0 = sy.floor() as i32;
                let x1 = x0 + 1;
                let y1 = y0 + 1;
                let tx = sx - sx.floor();
                let ty = sy - sy.floor();
                let clamp_x = |x: i32| x.clamp(0, self.width as i32 - 1) as u32;
                let clamp_y = |y: i32| y.clamp(0, self.height as i32 - 1) as u32;
                let get = |px: u32, py: u32, c: usize| -> f32 {
                    self.pixels[((py * self.width + px) * 4) as usize + c] as f32
                };
                let cx0 = clamp_x(x0);
                let cx1 = clamp_x(x1);
                let cy0 = clamp_y(y0);
                let cy1 = clamp_y(y1);
                let dst_idx = ((dy * new_w + dx) * 4) as usize;
                for c in 0..4usize {
                    let top = get(cx0, cy0, c) * (1.0 - tx) + get(cx1, cy0, c) * tx;
                    let bot = get(cx0, cy1, c) * (1.0 - tx) + get(cx1, cy1, c) * tx;
                    out.pixels[dst_idx + c] = (top * (1.0 - ty) + bot * ty).round() as u8;
                }
            }
        }
        Some(out)
    }
    fn resize_lanczos3(&self, new_w: u32, new_h: u32) -> ImageData {
        let a = 3.0f32;
        let src_w = self.width as i32;
        let src_h = self.height as i32;
        let scale_x = self.width as f32 / new_w as f32;
        let scale_y = self.height as f32 / new_h as f32;
        let mut out = ImageData::new(new_w, new_h);
        for dy in 0..new_h {
            let sy = (dy as f32 + 0.5) * scale_y - 0.5;
            let y0 = sy.floor() as i32;
            for dx in 0..new_w {
                let sx = (dx as f32 + 0.5) * scale_x - 0.5;
                let x0 = sx.floor() as i32;
                let mut accum = [0.0f32; 4];
                let mut total_w = 0.0f32;
                for ky in (y0 - 2)..=(y0 + 3) {
                    let cy = ky.clamp(0, src_h - 1) as u32;
                    let wy = lanczos_weight(sy - ky as f32, a);
                    if wy.abs() < 1.0e-6 {
                        continue;
                    }
                    for kx in (x0 - 2)..=(x0 + 3) {
                        let cx = kx.clamp(0, src_w - 1) as u32;
                        let wx = lanczos_weight(sx - kx as f32, a);
                        let w = wx * wy;
                        if w.abs() < 1.0e-6 {
                            continue;
                        }
                        let si = ((cy * self.width + cx) * 4) as usize;
                        for (c, channel) in accum.iter_mut().enumerate() {
                            *channel += self.pixels[si + c] as f32 * w;
                        }
                        total_w += w;
                    }
                }
                let di = ((dy * new_w + dx) * 4) as usize;
                if total_w.abs() > 1.0e-6 {
                    for (c, channel) in accum.iter().enumerate() {
                        out.pixels[di + c] = (*channel / total_w).round().clamp(0.0, 255.0) as u8;
                    }
                } else {
                    let sxn = sx.round().clamp(0.0, self.width as f32 - 1.0) as u32;
                    let syn = sy.round().clamp(0.0, self.height as f32 - 1.0) as u32;
                    let si = ((syn * self.width + sxn) * 4) as usize;
                    out.pixels[di..di + 4].copy_from_slice(&self.pixels[si..si + 4]);
                }
            }
        }
        out
    }
    pub fn blit(&mut self, src: &ImageData, dst_x: i32, dst_y: i32) {
        let dw = self.width as i32;
        let dh = self.height as i32;
        let sw = src.width as i32;
        let sh = src.height as i32;
        let fully_opaque = src.pixels.chunks_exact(4).all(|px| px[3] == 255);
        if fully_opaque {
            for sy in 0..sh {
                let dy = dst_y + sy;
                if dy < 0 || dy >= dh {
                    continue;
                }
                let mut sx0 = 0;
                let mut dx0 = dst_x;
                if dx0 < 0 {
                    sx0 = -dx0;
                    dx0 = 0;
                }
                let row_len = (sw - sx0).min(dw - dx0);
                if row_len <= 0 {
                    continue;
                }
                let si = ((sy * sw + sx0) * 4) as usize;
                let di = ((dy * dw + dx0) * 4) as usize;
                let bytes = (row_len as usize) * 4;
                self.pixels[di..di + bytes].copy_from_slice(&src.pixels[si..si + bytes]);
            }
            return;
        }
        for sy in 0..sh {
            let dy = dst_y + sy;
            if dy < 0 || dy >= dh {
                continue;
            }
            for sx in 0..sw {
                let dx = dst_x + sx;
                if dx < 0 || dx >= dw {
                    continue;
                }
                let si = ((sy * sw + sx) * 4) as usize;
                let di = ((dy * dw + dx) * 4) as usize;
                let sa = src.pixels[si + 3] as f32 / 255.0;
                if sa <= 0.0 {
                    continue;
                }
                let da = self.pixels[di + 3] as f32 / 255.0;
                let out_a = sa + da * (1.0 - sa);
                if out_a <= 0.0 {
                    continue;
                }
                for c in 0..3usize {
                    let s = src.pixels[si + c] as f32 / 255.0;
                    let d = self.pixels[di + c] as f32 / 255.0;
                    let out_c = (s * sa + d * da * (1.0 - sa)) / out_a;
                    self.pixels[di + c] = (out_c * 255.0).round().clamp(0.0, 255.0) as u8;
                }
                self.pixels[di + 3] = (out_a * 255.0).round().clamp(0.0, 255.0) as u8;
            }
        }
    }
    #[allow(clippy::too_many_arguments)]
    pub fn draw_nine_slice(
        &mut self,
        src: &ImageData,
        src_x: u32,
        src_y: u32,
        src_w: u32,
        src_h: u32,
        dst_x: i32,
        dst_y: i32,
        dst_w: u32,
        dst_h: u32,
        inset_left: u32,
        inset_right: u32,
        inset_top: u32,
        inset_bottom: u32,
    ) -> Result<(), String> {
        if dst_w == 0 || dst_h == 0 {
            return Err("draw_nine_slice: destination width/height must be > 0".into());
        }
        if src_w == 0 || src_h == 0 {
            return Err("draw_nine_slice: source width/height must be > 0".into());
        }
        if src_x + src_w > src.width || src_y + src_h > src.height {
            return Err("draw_nine_slice: source rect out of bounds".into());
        }
        if inset_left + inset_right > src_w || inset_top + inset_bottom > src_h {
            return Err("draw_nine_slice: insets exceed source region size".into());
        }
        let src_center_w = src_w.saturating_sub(inset_left + inset_right);
        let src_center_h = src_h.saturating_sub(inset_top + inset_bottom);
        let dst_center_w = dst_w.saturating_sub(inset_left + inset_right);
        let dst_center_h = dst_h.saturating_sub(inset_top + inset_bottom);
        let draw_patch = |dst: &mut ImageData,
                          sx: u32,
                          sy: u32,
                          sw: u32,
                          sh: u32,
                          dx: i32,
                          dy: i32,
                          dw: u32,
                          dh: u32|
         -> Result<(), String> {
            if sw == 0 || sh == 0 || dw == 0 || dh == 0 {
                return Ok(());
            }
            let patch = src
                .get_region(sx, sy, sw, sh)
                .ok_or_else(|| "draw_nine_slice: failed to extract source patch".to_string())?;
            let patch = if sw == dw && sh == dh {
                patch
            } else {
                patch.resize_nearest(dw, dh)
            };
            dst.blit(&patch, dx, dy);
            Ok(())
        };
        let s_left = inset_left;
        let s_right = inset_right;
        let s_top = inset_top;
        let s_bottom = inset_bottom;
        let s_mid_x = src_x + s_left;
        let s_mid_y = src_y + s_top;
        let s_right_x = src_x + src_w - s_right;
        let s_bottom_y = src_y + src_h - s_bottom;
        let d_mid_x = dst_x + s_left as i32;
        let d_mid_y = dst_y + s_top as i32;
        let d_right_x = dst_x + (s_left + dst_center_w) as i32;
        let d_bottom_y = dst_y + (s_top + dst_center_h) as i32;
        draw_patch(
            self, src_x, src_y, s_left, s_top, dst_x, dst_y, s_left, s_top,
        )?;
        draw_patch(
            self,
            s_mid_x,
            src_y,
            src_center_w,
            s_top,
            d_mid_x,
            dst_y,
            dst_center_w,
            s_top,
        )?;
        draw_patch(
            self, s_right_x, src_y, s_right, s_top, d_right_x, dst_y, s_right, s_top,
        )?;
        draw_patch(
            self,
            src_x,
            s_mid_y,
            s_left,
            src_center_h,
            dst_x,
            d_mid_y,
            s_left,
            dst_center_h,
        )?;
        draw_patch(
            self,
            s_mid_x,
            s_mid_y,
            src_center_w,
            src_center_h,
            d_mid_x,
            d_mid_y,
            dst_center_w,
            dst_center_h,
        )?;
        draw_patch(
            self,
            s_right_x,
            s_mid_y,
            s_right,
            src_center_h,
            d_right_x,
            d_mid_y,
            s_right,
            dst_center_h,
        )?;
        draw_patch(
            self, src_x, s_bottom_y, s_left, s_bottom, dst_x, d_bottom_y, s_left, s_bottom,
        )?;
        draw_patch(
            self,
            s_mid_x,
            s_bottom_y,
            src_center_w,
            s_bottom,
            d_mid_x,
            d_bottom_y,
            dst_center_w,
            s_bottom,
        )?;
        draw_patch(
            self, s_right_x, s_bottom_y, s_right, s_bottom, d_right_x, d_bottom_y, s_right,
            s_bottom,
        )?;
        Ok(())
    }
    pub fn get_region(&self, x: u32, y: u32, w: u32, h: u32) -> Option<ImageData> {
        if w == 0 || h == 0 || x + w > self.width || y + h > self.height {
            return None;
        }
        let mut out = ImageData::new(w, h);
        for row in 0..h {
            let src_off = ((y + row) * self.width + x) as usize * 4;
            let dst_off = (row * w) as usize * 4;
            let len = w as usize * 4;
            out.pixels[dst_off..dst_off + len]
                .copy_from_slice(&self.pixels[src_off..src_off + len]);
        }
        Some(out)
    }
    pub fn diff(&self, other: &ImageData) -> u32 {
        let same_dims = self.width == other.width && self.height == other.height;
        if same_dims {
            self.pixels
                .iter()
                .zip(other.pixels.iter())
                .map(|(&a, &b)| (a as i32 - b as i32).unsigned_abs())
                .sum()
        } else {
            let shared_w = self.width.min(other.width);
            let shared_h = self.height.min(other.height);
            let mut total = 0u32;
            for row in 0..shared_h {
                for col in 0..shared_w {
                    let ai = ((row * self.width + col) * 4) as usize;
                    let bi = ((row * other.width + col) * 4) as usize;
                    for c in 0..4usize {
                        total += (self.pixels[ai + c] as i32 - other.pixels[bi + c] as i32)
                            .unsigned_abs();
                    }
                }
            }
            let extra_self = (self.width * self.height - shared_w * shared_h) * 4 * 255;
            let extra_other = (other.width * other.height - shared_w * shared_h) * 4 * 255;
            total + extra_self + extra_other
        }
    }
    #[allow(clippy::needless_range_loop)]
    pub fn convolve(&self, kernel: &[f64], ksize: usize) -> Result<ImageData, String> {
        if ksize == 0 {
            return Err("ksize must be >= 1".into());
        }
        if ksize.is_multiple_of(2) {
            return Err(format!("ksize must be odd, got {}", ksize));
        }
        if kernel.len() != ksize * ksize {
            return Err(format!(
                "kernel length {} does not match ksize*ksize ({})",
                kernel.len(),
                ksize * ksize
            ));
        }
        let w = self.width as i32;
        let h = self.height as i32;
        let half = (ksize / 2) as i32;
        let mut out = ImageData::new(self.width, self.height);
        let clamp_x = |x: i32| x.clamp(0, w - 1) as u32;
        let clamp_y = |y: i32| y.clamp(0, h - 1) as u32;
        let get = |px: u32, py: u32, c: usize| -> f64 {
            self.pixels[((py * self.width + px) * 4) as usize + c] as f64
        };
        for py in 0..h {
            for px in 0..w {
                let src_a = get(clamp_x(px), clamp_y(py), 3) as u8;
                let mut acc = [0.0f64; 3];
                for ky in 0..ksize {
                    for kx in 0..ksize {
                        let sx = px + kx as i32 - half;
                        let sy = py + ky as i32 - half;
                        let w_val = kernel[ky * ksize + kx];
                        for c in 0..3usize {
                            acc[c] += get(clamp_x(sx), clamp_y(sy), c) * w_val;
                        }
                    }
                }
                let idx = ((py * w) as usize + px as usize) * 4;
                for c in 0..3usize {
                    out.pixels[idx + c] = acc[c].clamp(0.0, 255.0).round() as u8;
                }
                out.pixels[idx + 3] = src_a;
            }
        }
        Ok(out)
    }
}
