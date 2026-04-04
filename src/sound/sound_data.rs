//! Decoded PCM audio sample buffer.

use mlua::prelude::*;
use rodio::Source;

/// Decoded audio samples in f32 PCM format.
///
/// Stores interleaved samples (for stereo: L, R, L, R, ...).
#[derive(Debug, Clone)]
pub struct SoundData {
    samples: Vec<f32>,
    sample_rate: u32,
    channels: u16,
    bit_depth: u16,
}

impl SoundData {
    /// Create a silent buffer with the given number of samples.
    pub fn new(sample_count: usize, sample_rate: u32, channels: u16) -> Self {
        Self {
            samples: vec![0.0; sample_count * channels as usize],
            sample_rate,
            channels,
            bit_depth: 32,
        }
    }

    /// Decode an audio file to SoundData.
    pub fn from_file(path: &str) -> Result<Self, String> {
        use std::io::BufReader;
        let file = std::fs::File::open(path)
            .map_err(|e| format!("Failed to open audio file '{}': {}", path, e))?;
        let reader = BufReader::new(file);
        let source = rodio::Decoder::new(reader)
            .map_err(|e| format!("Failed to decode audio file '{}': {}", path, e))?;

        let channels = source.channels();
        let sample_rate = source.sample_rate();

        // Collect all samples as f32
        let samples: Vec<f32> = source.convert_samples::<f32>().collect();

        Ok(Self {
            samples,
            sample_rate,
            channels,
            bit_depth: 32,
        })
    }

    /// Get a sample at the given index (interleaved).
    pub fn get_sample(&self, index: usize) -> Option<f32> {
        self.samples.get(index).copied()
    }

    /// Set a sample at the given index (clamped to [-1.0, 1.0]).
    pub fn set_sample(&mut self, index: usize, value: f32) -> bool {
        if index < self.samples.len() {
            self.samples[index] = value.clamp(-1.0, 1.0);
            true
        } else {
            false
        }
    }

    /// Get the number of samples per channel.
    pub fn sample_count(&self) -> usize {
        if self.channels == 0 {
            return 0;
        }
        self.samples.len() / self.channels as usize
    }

    /// Get the sample rate in Hz.
    pub fn sample_rate(&self) -> u32 {
        self.sample_rate
    }

    /// Get the number of audio channels.
    pub fn channel_count(&self) -> u16 {
        self.channels
    }

    /// Get the bit depth.
    pub fn bit_depth(&self) -> u16 {
        self.bit_depth
    }

    /// Get the duration in seconds.
    pub fn duration(&self) -> f64 {
        if self.sample_rate == 0 {
            return 0.0;
        }
        self.sample_count() as f64 / self.sample_rate as f64
    }

    /// Get a reference to the raw samples.
    pub fn as_samples(&self) -> &[f32] {
        &self.samples
    }
}

impl mlua::UserData for SoundData {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getSampleCount", |_, this, ()| Ok(this.sample_count()));
        methods.add_method("getSampleRate", |_, this, ()| Ok(this.sample_rate()));
        methods.add_method("getChannelCount", |_, this, ()| Ok(this.channel_count()));
        methods.add_method("getDuration", |_, this, ()| Ok(this.duration()));
        methods.add_method("getBitDepth", |_, this, ()| Ok(this.bit_depth()));
        methods.add_method("getSample", |_, this, index: usize| {
            this.get_sample(index).ok_or_else(|| {
                LuaError::RuntimeError(format!("Sample index {} out of bounds", index))
            })
        });
        methods.add_method_mut("setSample", |_, this, (index, value): (usize, f32)| {
            if this.set_sample(index, value) {
                Ok(())
            } else {
                Err(LuaError::RuntimeError(format!(
                    "Sample index {} out of bounds",
                    index
                )))
            }
        });
    }
}
