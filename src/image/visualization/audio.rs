use crate::image::ImageData;
/// Render a mono waveform preview into an image.
pub fn waveform_to_image(samples: &[f32], _sample_rate: u32, width: u32, height: u32) -> ImageData {
    let margin = 40u32;
    let plot_w = width - margin * 2;
    let plot_h = height - margin * 2;
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);
    for i in 0..=4 {
        let y = margin as i32 + (plot_h as i32 * i / 4);
        for x in margin..width - margin {
            img.set_pixel(x, y as u32, 35, 35, 50, 255);
        }
    }
    for i in 0..=8 {
        let x = margin as i32 + (plot_w as i32 * i / 8);
        for y in margin..height - margin {
            img.set_pixel(x as u32, y, 35, 35, 50, 255);
        }
    }
    let center_y = margin + plot_h / 2;
    for x in margin..width - margin {
        img.set_pixel(x, center_y, 60, 60, 80, 255);
    }
    let peak = samples
        .iter()
        .map(|s| s.abs())
        .fold(0.0f32, f32::max)
        .max(0.01);
    let scale = 0.9 / peak;
    let samples_per_pixel = samples.len().max(1) / plot_w as usize;
    if samples_per_pixel > 0 {
        for x in 0..plot_w {
            let start = x as usize * samples_per_pixel;
            let end = (start + samples_per_pixel).min(samples.len());
            let mut min_val = f32::MAX;
            let mut max_val = f32::MIN;
            for &s in &samples[start..end] {
                let scaled = (s * scale).clamp(-1.0, 1.0);
                min_val = min_val.min(scaled);
                max_val = max_val.max(scaled);
            }
            let y_top = (margin as f32 + (1.0 - max_val) * 0.5 * plot_h as f32) as i32;
            let y_bot = (margin as f32 + (1.0 - min_val) * 0.5 * plot_h as f32) as i32;
            let px = (margin + x) as i32;
            img.draw_line(
                px,
                y_top.max(margin as i32),
                px,
                y_bot.min((height - margin) as i32),
                80,
                180,
                255,
                255,
            );
        }
    }
    for x in margin..width - margin {
        img.set_pixel(x, margin, 60, 60, 80, 255);
        img.set_pixel(x, height - margin - 1, 60, 60, 80, 255);
    }
    for y in margin..height - margin {
        img.set_pixel(margin, y, 60, 60, 80, 255);
        img.set_pixel(width - margin - 1, y, 60, 60, 80, 255);
    }
    img
}
/// Render a stereo waveform preview into an image.
pub fn waveform_stereo_to_image(
    samples: &[f32],
    _sample_rate: u32,
    width: u32,
    height: u32,
) -> ImageData {
    let margin = 40u32;
    let plot_w = width - margin * 2;
    let ch_height = (height - margin * 2) / 2;
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);
    let left: Vec<f32> = samples.iter().step_by(2).copied().collect();
    let right: Vec<f32> = samples.iter().skip(1).step_by(2).copied().collect();
    let peak = samples
        .iter()
        .map(|s| s.abs())
        .fold(0.0f32, f32::max)
        .max(0.01);
    let scale = 0.85 / peak;
    let sep_y = margin + ch_height;
    for x in margin..width - margin {
        img.set_pixel(x, sep_y, 80, 80, 100, 255);
    }
    for ch in 0..2 {
        let base_y = margin + ch * ch_height;
        let center_y = base_y + ch_height / 2;
        for x in margin..width - margin {
            img.set_pixel(x, center_y, 40, 40, 55, 255);
        }
    }
    for (ch_idx, ch_samples) in [&left, &right].iter().enumerate() {
        let base_y = margin as f32 + ch_idx as f32 * ch_height as f32;
        let spp = ch_samples.len().max(1) / plot_w as usize;
        if spp == 0 {
            continue;
        }
        let (cr, cg, cb) = if ch_idx == 0 {
            (80, 200, 255)
        } else {
            (255, 160, 60)
        };
        for x in 0..plot_w {
            let start = x as usize * spp;
            let end = (start + spp).min(ch_samples.len());
            let mut min_val = f32::MAX;
            let mut max_val = f32::MIN;
            for &s in &ch_samples[start..end] {
                let sc = (s * scale).clamp(-1.0, 1.0);
                min_val = min_val.min(sc);
                max_val = max_val.max(sc);
            }
            let y_top = (base_y + (1.0 - max_val) * 0.5 * ch_height as f32) as i32;
            let y_bot = (base_y + (1.0 - min_val) * 0.5 * ch_height as f32) as i32;
            let px = (margin + x) as i32;
            let yt = y_top.max(margin as i32).min((height - margin) as i32);
            let yb = y_bot.max(margin as i32).min((height - margin) as i32);
            img.draw_line(px, yt, px, yb, cr, cg, cb, 255);
        }
    }
    img
}
/// Render a zoomed waveform preview into an image.
pub fn waveform_zoomed_to_image(
    samples: &[f32],
    max_samples: usize,
    width: u32,
    height: u32,
) -> ImageData {
    let zoomed: Vec<f32> = samples.iter().take(max_samples).copied().collect();
    let margin = 40u32;
    let plot_w = width - margin * 2;
    let plot_h = height - margin * 2;
    let mut img = ImageData::new(width, height);
    img.fill(15, 15, 25, 255);
    for i in 0..=4 {
        let y = margin as i32 + (plot_h as i32 * i / 4);
        for x in margin..width - margin {
            img.set_pixel(x, y as u32, 35, 35, 50, 255);
        }
    }
    for i in 0..=8 {
        let x = margin as i32 + (plot_w as i32 * i / 8);
        for y in margin..height - margin {
            img.set_pixel(x as u32, y, 35, 35, 50, 255);
        }
    }
    let center_y = margin + plot_h / 2;
    for x in margin..width - margin {
        img.set_pixel(x, center_y, 60, 60, 80, 255);
    }
    let peak = zoomed
        .iter()
        .map(|s| s.abs())
        .fold(0.0f32, f32::max)
        .max(0.01);
    let scale = 0.9 / peak;
    let n = zoomed.len();
    if n > 1 {
        for x in 0..plot_w {
            let sample_f = x as f32 / plot_w as f32 * (n - 1) as f32;
            let idx = sample_f as usize;
            let frac = sample_f - idx as f32;
            let s = if idx + 1 < n {
                zoomed[idx] * (1.0 - frac) + zoomed[idx + 1] * frac
            } else {
                zoomed[idx]
            };
            let scaled = (s * scale).clamp(-1.0, 1.0);
            let y = (margin as f32 + (1.0 - scaled) * 0.5 * plot_h as f32) as i32;
            let px = (margin + x) as i32;
            let cy = center_y as i32;
            let (y0, y1) = if y < cy { (y, cy) } else { (cy, y) };
            img.draw_line(
                px,
                y0.max(margin as i32),
                px,
                y1.min((height - margin) as i32),
                80,
                180,
                255,
                255,
            );
            if y >= margin as i32 && y < (height - margin) as i32 {
                img.set_pixel(px as u32, y as u32, 140, 220, 255, 255);
            }
        }
    }
    for x in margin..width - margin {
        img.set_pixel(x, margin, 60, 60, 80, 255);
        img.set_pixel(x, height - margin - 1, 60, 60, 80, 255);
    }
    for y in margin..height - margin {
        img.set_pixel(margin, y, 60, 60, 80, 255);
        img.set_pixel(width - margin - 1, y, 60, 60, 80, 255);
    }
    img
}
/// Render a labeled waveform strip with a custom color into an image.
pub fn draw_sound_waveform_to_image(
    samples: &[f32],
    label: &str,
    width: u32,
    height: u32,
    color: (u8, u8, u8),
) -> ImageData {
    let mut img = ImageData::new(width, height);
    img.fill(25, 25, 35, 255);
    let margin = 10u32;
    let plot_w = width.saturating_sub(margin * 2);
    let mid_y = (height / 2) as i32;
    img.draw_line(
        margin as i32,
        mid_y,
        (width - margin) as i32,
        mid_y,
        60,
        60,
        80,
        150,
    );
    let step = if plot_w == 0 {
        1
    } else {
        samples.len().max(1) / plot_w as usize
    };
    let step = step.max(1);
    let h_half = (height / 2) as f32 * 0.8;
    for x in 0..plot_w {
        let idx = x as usize * step;
        if idx < samples.len() {
            let val = samples[idx];
            let y = (mid_y as f32 - val * h_half) as i32;
            let y = y.clamp(0, height as i32 - 1);
            let t = x as f32 / plot_w as f32;
            let r = ((color.0 as f32) * (0.6 + t * 0.4)) as u8;
            let g = ((color.1 as f32) * (1.0 - t * 0.3)) as u8;
            let b = color.2;
            img.draw_circle((x + margin) as i32, y, 1, r, g, b, 255);
        }
    }
    img.draw_label(label, margin as i32, (height - 15) as i32, 100, 255, 100);
    img
}
