//! Audio visualisation helpers for exporting waveform and spectrogram PNG images.
//! Decodes audio to mono f32 samples, then rasterises either amplitude columns or
//! short-time spectrum heatmaps. Used by tooling and diagnostics, not real-time render paths.

use image::{ImageBuffer, Rgba};
use rodio::{Decoder, Source};
use std::{fs::File, io::BufReader};
/// Create parent directories for `path` when needed.
fn ensure_parent_dir(path: &str) -> Result<(), String> {
    if let Some(parent) = std::path::Path::new(path).parent() {
        if !parent.as_os_str().is_empty() && !parent.exists() {
            std::fs::create_dir_all(parent).map_err(|e| {
                format!(
                    "cannot create output directory '{}': {}",
                    parent.display(),
                    e
                )
            })?;
        }
    }
    Ok(())
}
/// Render waveform overview of `input_wav` to `output_png` with given image size.
pub fn waveform_to_png(
    input_wav: &str,
    output_png: &str,
    width: u32,
    height: u32,
) -> Result<(), String> {
    let samples = read_mono_f32(input_wav)?;
    let bg: Rgba<u8> = Rgba([12, 14, 28, 255]);
    let fg: Rgba<u8> = Rgba([0, 200, 220, 255]);
    let mut img: ImageBuffer<Rgba<u8>, Vec<u8>> = ImageBuffer::from_fn(width, height, |_, _| bg);
    let n = samples.len().max(1);
    let samples_per_col = n as f32 / width as f32;
    let half_h = height as f32 * 0.5;
    for x in 0..width {
        let start = ((x as f32 * samples_per_col) as usize).min(n - 1);
        let end = (((x + 1) as f32 * samples_per_col) as usize).min(n);
        let slice = &samples[start..end];
        let (mn, mx) = if slice.is_empty() {
            (0.0_f32, 0.0_f32)
        } else {
            let mn = slice.iter().cloned().fold(f32::INFINITY, f32::min);
            let mx = slice.iter().cloned().fold(f32::NEG_INFINITY, f32::max);
            (mn, mx)
        };
        let y_top = ((half_h - mx.clamp(-1.0, 1.0) * half_h) as u32).min(height - 1);
        let y_bot = ((half_h - mn.clamp(-1.0, 1.0) * half_h) as u32).min(height - 1);
        for y in y_top..=y_bot {
            img.put_pixel(x, y, fg);
        }
    }
    ensure_parent_dir(output_png)?;
    img.save(output_png)
        .map_err(|e| format!("cannot save PNG '{}': {}", output_png, e))
}
#[allow(clippy::needless_range_loop)]
/// Render a spectrogram heatmap of `input_wav` to `output_png` using a Hann-windowed DFT.
pub fn spectrogram_to_png(
    input_wav: &str,
    output_png: &str,
    width: u32,
    height: u32,
) -> Result<(), String> {
    let samples = read_mono_f32(input_wav)?;
    const WIN: usize = 512;
    let half_win = WIN / 2;
    let total_windows = (samples.len() as f32 / WIN as f32).ceil() as usize;
    let hop = if total_windows > 1 {
        (samples.len() - WIN) / (total_windows - 1).max(1)
    } else {
        samples.len().max(1)
    };
    let n_frames = if total_windows < 2 { 1 } else { total_windows };
    let mut spectra: Vec<Vec<f32>> = Vec::with_capacity(n_frames);
    for i in 0..n_frames {
        let start = (i * hop).min(samples.len().saturating_sub(WIN));
        let slice = &samples[start..(start + WIN).min(samples.len())];
        let mut window = vec![0.0_f32; WIN];
        window[..slice.len()].copy_from_slice(slice);
        for (k, s) in window.iter_mut().enumerate() {
            let hann =
                0.5 * (1.0 - (2.0 * std::f32::consts::PI * k as f32 / (WIN - 1) as f32).cos());
            *s *= hann;
        }
        let mut mags = vec![0.0_f32; half_win];
        for k in 0..half_win {
            let mut re = 0.0_f32;
            let mut im = 0.0_f32;
            let angle = -2.0 * std::f32::consts::PI * k as f32 / WIN as f32;
            for (n, &xn) in window.iter().enumerate() {
                re += xn * (angle * n as f32).cos();
                im += xn * (angle * n as f32).sin();
            }
            mags[k] = (re * re + im * im).sqrt();
        }
        spectra.push(mags);
    }
    let global_max = spectra
        .iter()
        .flat_map(|m| m.iter())
        .cloned()
        .fold(0.0_f32, f32::max)
        .max(1e-6);
    let bg: Rgba<u8> = Rgba([0, 0, 0, 255]);
    let mut img: ImageBuffer<Rgba<u8>, Vec<u8>> = ImageBuffer::from_fn(width, height, |_, _| bg);
    for px in 0..width {
        let frame_idx = ((px as f32 / width as f32) * n_frames as f32) as usize;
        let frame_idx = frame_idx.min(n_frames - 1);
        let mags = &spectra[frame_idx];
        for py in 0..height {
            let bin = (((height - 1 - py) as f32 / height as f32) * half_win as f32) as usize;
            let bin = bin.min(half_win - 1);
            let mag_norm = (mags[bin] / global_max).clamp(0.0, 1.0);
            let colour = heat_colour(mag_norm);
            img.put_pixel(px, py, colour);
        }
    }
    ensure_parent_dir(output_png)?;
    img.save(output_png)
        .map_err(|e| format!("cannot save PNG '{}': {}", output_png, e))
}
/// Decode an audio file and return mono f32 samples (stereo/multichannel is averaged).
fn read_mono_f32(path: &str) -> Result<Vec<f32>, String> {
    let file = File::open(path).map_err(|e| format!("file not found: {}: {}", path, e))?;
    let reader = BufReader::new(file);
    let decoder =
        Decoder::new(reader).map_err(|e| format!("failed to decode '{}': {}", path, e))?;
    let channels = decoder.channels() as usize;
    let raw: Vec<f32> = decoder.convert_samples::<f32>().collect();
    if channels <= 1 {
        return Ok(raw);
    }
    let inv = 1.0 / channels as f32;
    let mono: Vec<f32> = raw
        .chunks(channels)
        .map(|c| c.iter().sum::<f32>() * inv)
        .collect();
    Ok(mono)
}
/// Map normalized magnitude `t` in [0,1] to an RGB heatmap colour.
fn heat_colour(t: f32) -> Rgba<u8> {
    let (r, g, b) = if t < 0.25 {
        let u = t / 0.25;
        (0.0_f32, 0.0, u)
    } else if t < 0.5 {
        let u = (t - 0.25) / 0.25;
        (0.0, u, 1.0)
    } else if t < 0.75 {
        let u = (t - 0.5) / 0.25;
        (u, 1.0, 1.0 - u)
    } else {
        let u = (t - 0.75) / 0.25;
        (1.0, 1.0, u)
    };
    Rgba([(r * 255.0) as u8, (g * 255.0) as u8, (b * 255.0) as u8, 255])
}
