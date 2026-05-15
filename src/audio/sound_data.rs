
//! - `SoundData` in-memory interleaved f32 PCM buffer with per-sample get/set and metadata.
//! - File decode via rodio, silent-buffer allocation, and Lua argument factory.
//! - WAV encoding to byte vector for save/export.
//! - Waveform generators: sine, square, sawtooth, triangle, and deterministic white noise.
//! - In-place DSP transforms: low-pass, high-pass, band-pass, gain, and mix-into.
//! - Waveform drawing into `ImageData` for visual feedback.
//! - Duration, sample count, and channel count queries.

use rodio::Source;
#[derive(Debug, Clone)]
/// In-memory interleaved f32 PCM data with metadata and utility transforms.
pub struct SoundData {
    /// Interleaved audio samples in the range [-1.0, 1.0].
    samples: Vec<f32>,
    /// Sample rate in Hz.
    sample_rate: u32,
    /// Channel count (1=mono, 2=stereo).
    channels: u16,
    /// Logical bit depth used by import/export paths.
    bit_depth: u16,
}
impl SoundData {
    /// Allocate silent audio buffer with `sample_count` frames and `channels` interleaved channels.
    pub fn new(sample_count: usize, sample_rate: u32, channels: u16) -> Self {
        Self {
            samples: vec![0.0; sample_count * channels as usize],
            sample_rate,
            channels,
            bit_depth: 32,
        }
    }
    /// Construct from an existing interleaved sample vector.
    pub fn from_samples(samples: Vec<f32>, sample_rate: u32, channels: u16) -> Self {
        Self {
            samples,
            sample_rate,
            channels,
            bit_depth: 16,
        }
    }
    /// Build `SoundData` from Lua arguments: load file when `path` is set, otherwise allocate silent buffer.
    pub fn from_lua_args(
        path: Option<&str>,
        count: usize,
        sample_rate: u32,
        channels: u16,
    ) -> Result<Self, String> {
        match path {
            Some(p) => Self::from_file(p),
            None => Ok(Self::new(count, sample_rate, channels)),
        }
    }
    /// Decode audio file at `path` into f32 interleaved samples.
    pub fn from_file(path: &str) -> Result<Self, String> {
        use std::io::BufReader;
        let file = std::fs::File::open(path)
            .map_err(|e| format!("Failed to open audio file '{}': {}", path, e))?;
        let reader = BufReader::new(file);
        let source = rodio::Decoder::new(reader)
            .map_err(|e| format!("Failed to decode audio file '{}': {}", path, e))?;
        let channels = source.channels();
        let sample_rate = source.sample_rate();
        let samples: Vec<f32> = source.convert_samples::<f32>().collect();
        Ok(Self {
            samples,
            sample_rate,
            channels,
            bit_depth: 32,
        })
    }
    /// Return sample value at `index`, or `None` when out of bounds.
    pub fn get_sample(&self, index: usize) -> Option<f32> {
        self.samples.get(index).copied()
    }
    /// Return all interleaved samples as a shared slice.
    pub fn samples(&self) -> &[f32] {
        &self.samples
    }
    /// Set sample at `index` to `value` (clamped to [-1,1]); return `false` if index is invalid.
    pub fn set_sample(&mut self, index: usize, value: f32) -> bool {
        if index < self.samples.len() {
            self.samples[index] = value.clamp(-1.0, 1.0);
            true
        } else {
            false
        }
    }
    /// Return number of frames (samples per channel), not raw interleaved element count.
    pub fn sample_count(&self) -> usize {
        if self.channels == 0 {
            return 0;
        }
        self.samples.len() / self.channels as usize
    }
    /// Return sample rate in Hz. This function is part of the public API.
    pub fn sample_rate(&self) -> u32 {
        self.sample_rate
    }
    /// Return channel count. This function is part of the public API.
    pub fn channel_count(&self) -> u16 {
        self.channels
    }
    /// Return logical bit depth metadata.
    pub fn bit_depth(&self) -> u16 {
        self.bit_depth
    }
    /// Return duration in seconds. This function is part of the public API.
    pub fn duration(&self) -> f64 {
        if self.sample_rate == 0 {
            return 0.0;
        }
        self.sample_count() as f64 / self.sample_rate as f64
    }
    /// Return interleaved sample slice.
    pub fn as_samples(&self) -> &[f32] {
        &self.samples
    }
    /// Encode current samples as an in-memory 16-bit PCM WAV byte vector.
    pub fn encode_wav(&self) -> Vec<u8> {
        let num_samples = self.samples.len();
        let bytes_per_sample: u16 = 2;
        let block_align = self.channels * bytes_per_sample;
        let byte_rate = self.sample_rate * block_align as u32;
        let data_size = (num_samples * bytes_per_sample as usize) as u32;
        let file_size = 36 + data_size;
        let mut buf = Vec::with_capacity(44 + data_size as usize);
        buf.extend_from_slice(b"RIFF");
        buf.extend_from_slice(&file_size.to_le_bytes());
        buf.extend_from_slice(b"WAVE");
        buf.extend_from_slice(b"fmt ");
        buf.extend_from_slice(&16u32.to_le_bytes());
        buf.extend_from_slice(&1u16.to_le_bytes());
        buf.extend_from_slice(&self.channels.to_le_bytes());
        buf.extend_from_slice(&self.sample_rate.to_le_bytes());
        buf.extend_from_slice(&byte_rate.to_le_bytes());
        buf.extend_from_slice(&block_align.to_le_bytes());
        buf.extend_from_slice(&(bytes_per_sample * 8).to_le_bytes());
        buf.extend_from_slice(b"data");
        buf.extend_from_slice(&data_size.to_le_bytes());
        for &sample in &self.samples {
            let clamped = sample.clamp(-1.0, 1.0);
            let val = (clamped * 32767.0) as i16;
            buf.extend_from_slice(&val.to_le_bytes());
        }
        buf
    }
    /// Generate mono sine-wave `SoundData` at `freq` Hz for `duration` seconds.
    pub fn sine_wave(freq: f32, duration: f32, sample_rate: u32, amplitude: f32) -> Self {
        let n = (sample_rate as f32 * duration) as usize;
        let samples = (0..n)
            .map(|i| {
                let t = i as f32 / sample_rate as f32;
                (t * freq * 2.0 * std::f32::consts::PI).sin() * amplitude.clamp(0.0, 1.0)
            })
            .collect();
        Self::from_samples(samples, sample_rate, 1)
    }
    /// Generate mono square-wave `SoundData` at `freq` Hz for `duration` seconds.
    pub fn square_wave(freq: f32, duration: f32, sample_rate: u32, amplitude: f32) -> Self {
        let n = (sample_rate as f32 * duration) as usize;
        let amp = amplitude.clamp(0.0, 1.0);
        let samples = (0..n)
            .map(|i| {
                let phase = (i as f32 / sample_rate as f32 * freq) % 1.0;
                if phase < 0.5 {
                    amp
                } else {
                    -amp
                }
            })
            .collect();
        Self::from_samples(samples, sample_rate, 1)
    }
    /// Generate mono sawtooth-wave `SoundData` at `freq` Hz for `duration` seconds.
    pub fn sawtooth_wave(freq: f32, duration: f32, sample_rate: u32, amplitude: f32) -> Self {
        let n = (sample_rate as f32 * duration) as usize;
        let amp = amplitude.clamp(0.0, 1.0);
        let samples = (0..n)
            .map(|i| {
                let phase = (i as f32 / sample_rate as f32 * freq) % 1.0;
                (phase * 2.0 - 1.0) * amp
            })
            .collect();
        Self::from_samples(samples, sample_rate, 1)
    }
    /// Generate mono triangle-wave `SoundData` at `freq` Hz for `duration` seconds.
    pub fn triangle_wave(freq: f32, duration: f32, sample_rate: u32, amplitude: f32) -> Self {
        let n = (sample_rate as f32 * duration) as usize;
        let amp = amplitude.clamp(0.0, 1.0);
        let samples = (0..n)
            .map(|i| {
                let phase = (i as f32 / sample_rate as f32 * freq) % 1.0;
                (2.0 * (2.0 * phase - 1.0).abs() - 1.0) * amp
            })
            .collect();
        Self::from_samples(samples, sample_rate, 1)
    }
    /// Generate mono white-noise `SoundData` using deterministic LCG seeded by `seed`.
    pub fn white_noise(duration: f32, sample_rate: u32, amplitude: f32, seed: u32) -> Self {
        let n = (sample_rate as f32 * duration) as usize;
        let amp = amplitude.clamp(0.0, 1.0);
        let mut state: u32 = seed.max(1);
        let samples = (0..n)
            .map(|_| {
                state = state.wrapping_mul(1_103_515_245).wrapping_add(12_345);
                ((state >> 16) as f32 / 32_768.0 - 1.0) * amp
            })
            .collect();
        Self::from_samples(samples, sample_rate, 1)
    }
    #[allow(clippy::too_many_arguments)]
    /// Draw waveform envelope into `img` as vertical min/max bars in RGBA colour `(r,g,b,a)`.
    pub fn draw_waveform(
        &self,
        img: &mut crate::image::ImageData,
        x: i32,
        y: i32,
        w: u32,
        h: u32,
        r: u8,
        g: u8,
        b: u8,
        a: u8,
    ) {
        if w == 0 || h == 0 || self.samples.is_empty() {
            return;
        }
        let num_frames = self.sample_count();
        if num_frames == 0 {
            return;
        }
        let channels = self.channels as usize;
        let img_w = img.width() as i32;
        let img_h = img.height() as i32;
        let half_h = h as f32 / 2.0;
        for px in 0..w {
            let start_frame = (px as usize * num_frames) / w as usize;
            let end_frame = ((px + 1) as usize * num_frames) / w as usize;
            let mut min_val = 0.0f32;
            let mut max_val = 0.0f32;
            if start_frame < end_frame {
                for frame in start_frame..end_frame {
                    let mut sum = 0.0;
                    for ch in 0..channels {
                        let idx = frame * channels + ch;
                        if idx < self.samples.len() {
                            sum += self.samples[idx];
                        }
                    }
                    let avg = sum / channels as f32;
                    if avg < min_val {
                        min_val = avg;
                    }
                    if avg > max_val {
                        max_val = avg;
                    }
                }
            } else if start_frame < num_frames {
                let mut sum = 0.0;
                for ch in 0..channels {
                    let idx = start_frame * channels + ch;
                    if idx < self.samples.len() {
                        sum += self.samples[idx];
                    }
                }
                let avg = sum / channels as f32;
                min_val = avg;
                max_val = avg;
            }
            let mut y1 = ((y as f32 + half_h) - max_val * half_h).round() as i32;
            let mut y2 = ((y as f32 + half_h) - min_val * half_h).round() as i32;
            if y1 > y2 {
                std::mem::swap(&mut y1, &mut y2);
            }
            let draw_x = x + px as i32;
            if draw_x >= 0 && draw_x < img_w {
                for draw_y in y1..=y2 {
                    if draw_y >= 0 && draw_y < img_h {
                        img.set_pixel(draw_x as u32, draw_y as u32, r, g, b, a);
                    }
                }
            }
        }
    }
    /// Apply one-pole low-pass filter in place with cutoff `cutoff_hz`.
    pub fn apply_lowpass(&mut self, cutoff_hz: f32) {
        if self.samples.is_empty() || cutoff_hz <= 0.0 {
            return;
        }
        let dt = 1.0 / self.sample_rate as f32;
        let rc = 1.0 / (2.0 * std::f32::consts::PI * cutoff_hz);
        let alpha = dt / (rc + dt);
        let mut prev_output = 0.0f32;
        for s in self.samples.iter_mut() {
            prev_output = alpha * *s + (1.0 - alpha) * prev_output;
            *s = prev_output;
        }
    }
    /// Apply one-pole high-pass filter in place with cutoff `cutoff_hz`.
    pub fn apply_highpass(&mut self, cutoff_hz: f32) {
        if self.samples.is_empty() || cutoff_hz <= 0.0 {
            return;
        }
        let dt = 1.0 / self.sample_rate as f32;
        let rc = 1.0 / (2.0 * std::f32::consts::PI * cutoff_hz);
        let alpha = rc / (rc + dt);
        let mut prev_input = 0.0f32;
        let mut prev_output = 0.0f32;
        for s in self.samples.iter_mut() {
            let inp = *s;
            prev_output = alpha * (prev_output + inp - prev_input);
            prev_input = inp;
            *s = prev_output;
        }
    }
    /// Apply simple band-pass by chaining `apply_highpass(low_hz)` then `apply_lowpass(high_hz)`.
    pub fn apply_bandpass(&mut self, low_hz: f32, high_hz: f32) {
        self.apply_highpass(low_hz);
        self.apply_lowpass(high_hz);
    }
    /// Multiply all samples by `gain` and clamp to [-1.0, 1.0].
    pub fn apply_gain(&mut self, gain: f32) {
        for s in self.samples.iter_mut() {
            *s = (*s * gain).clamp(-1.0, 1.0);
        }
    }
    /// Mix `other` into `self` sample-by-sample, extending length if needed and clamping output to [-1,1].
    pub fn mix_into(&mut self, other: &SoundData) {
        let len = self.samples.len().max(other.samples.len());
        self.samples.resize(len, 0.0);
        for (i, s) in self.samples.iter_mut().enumerate() {
            let o = other.samples.get(i).copied().unwrap_or(0.0);
            *s = (*s + o).clamp(-1.0, 1.0);
        }
    }
}
