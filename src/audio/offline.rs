use crate::audio::dsp::{ActiveEffect, AtomicParam, EffectParams, EffectType};
use rodio::{Decoder, Source};
use std::{
    fs::File,
    io::{BufReader, BufWriter, Write},
    sync::Arc,
};
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
#[derive(Debug, Clone, Copy)]
/// Serializable DSP effect parameters for offline processing.
pub struct OfflineEffect {
    /// Effect algorithm to apply.
    pub typ: EffectType,
    /// Effect parameter slot 1.
    pub p1: f32,
    /// Effect parameter slot 2.
    pub p2: f32,
    /// Effect parameter slot 3.
    pub p3: f32,
}
/// Read `input_path`, apply `effects` sample-by-sample, and write 16-bit WAV to `output_path`.
pub fn process_offline(
    input_path: &str,
    output_path: &str,
    effects: &[OfflineEffect],
) -> Result<(), String> {
    let (mut samples, sample_rate, channels) = read_wav_f32(input_path)?;
    let mut active: Vec<ActiveEffect> = effects
        .iter()
        .map(|e| {
            let params = Arc::new(EffectParams {
                id: 0,
                typ: e.typ,
                p1: AtomicParam::new(e.p1),
                p2: AtomicParam::new(e.p2),
                p3: AtomicParam::new(e.p3),
            });
            ActiveEffect::new(params, sample_rate, channels)
        })
        .collect();
    for (i, s) in samples.iter_mut().enumerate() {
        let ch = (i % channels as usize) as u16;
        for fx in active.iter_mut() {
            *s = fx.process(*s, ch, sample_rate);
        }
    }
    write_wav_i16(output_path, &samples, sample_rate, channels)
}
/// Normalize peak amplitude of `input_path` to `target_level` and write result to `output_path`.
pub fn normalize_file(
    input_path: &str,
    output_path: &str,
    target_level: f32,
) -> Result<(), String> {
    if target_level <= 0.0 || target_level > 1.0 {
        return Err(format!(
            "target level must be in (0.0, 1.0], got {}",
            target_level
        ));
    }
    let (mut samples, sample_rate, channels) = read_wav_f32(input_path)?;
    let peak = samples.iter().map(|s| s.abs()).fold(0.0_f32, f32::max);
    if peak > 0.0 {
        let scale = target_level / peak;
        for s in samples.iter_mut() {
            *s *= scale;
        }
    }
    write_wav_i16(output_path, &samples, sample_rate, channels)
}
/// Decode an audio file and return interleaved f32 samples with sample-rate and channel count.
fn read_wav_f32(path: &str) -> Result<(Vec<f32>, u32, u16), String> {
    let file = File::open(path).map_err(|e| format!("file not found: {}: {}", path, e))?;
    let reader = BufReader::new(file);
    let decoder =
        Decoder::new(reader).map_err(|e| format!("failed to decode WAV '{}': {}", path, e))?;
    let sample_rate = decoder.sample_rate();
    let channels = decoder.channels();
    let samples: Vec<f32> = decoder.convert_samples::<f32>().collect();
    Ok((samples, sample_rate, channels))
}
/// Write interleaved f32 samples to a 16-bit PCM WAV file at `path`.
fn write_wav_i16(
    path: &str,
    samples: &[f32],
    sample_rate: u32,
    channels: u16,
) -> Result<(), String> {
    ensure_parent_dir(path)?;
    let pcm: Vec<i16> = samples
        .iter()
        .map(|s| (s.clamp(-1.0, 1.0) * i16::MAX as f32) as i16)
        .collect();
    let bits_per_sample: u16 = 16;
    let block_align = channels * (bits_per_sample / 8);
    let byte_rate = sample_rate * block_align as u32;
    let data_size = (pcm.len() * 2) as u32;
    let file_size = 36 + data_size;
    let file = File::create(path).map_err(|e| format!("cannot create '{}': {}", path, e))?;
    let mut w = BufWriter::new(file);
    w.write_all(b"RIFF").map_err(|e| e.to_string())?;
    w.write_all(&file_size.to_le_bytes())
        .map_err(|e| e.to_string())?;
    w.write_all(b"WAVE").map_err(|e| e.to_string())?;
    w.write_all(b"fmt ").map_err(|e| e.to_string())?;
    w.write_all(&16u32.to_le_bytes())
        .map_err(|e| e.to_string())?;
    w.write_all(&1u16.to_le_bytes())
        .map_err(|e| e.to_string())?;
    w.write_all(&channels.to_le_bytes())
        .map_err(|e| e.to_string())?;
    w.write_all(&sample_rate.to_le_bytes())
        .map_err(|e| e.to_string())?;
    w.write_all(&byte_rate.to_le_bytes())
        .map_err(|e| e.to_string())?;
    w.write_all(&block_align.to_le_bytes())
        .map_err(|e| e.to_string())?;
    w.write_all(&bits_per_sample.to_le_bytes())
        .map_err(|e| e.to_string())?;
    w.write_all(b"data").map_err(|e| e.to_string())?;
    w.write_all(&data_size.to_le_bytes())
        .map_err(|e| e.to_string())?;
    for sample in &pcm {
        w.write_all(&sample.to_le_bytes())
            .map_err(|e| e.to_string())?;
    }
    w.flush().map_err(|e| e.to_string())
}
