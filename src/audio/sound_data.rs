//! Decoded PCM audio sample buffer with per-sample read/write access.
//!
//! `SoundData` stores fully decoded f32 PCM samples in interleaved channel
//! order (for stereo: L, R, L, R, ...). It can be created as a silent buffer
//! or decoded from an audio file via rodio. Lua code can read and write
//! individual samples for procedural audio and DSP effects.

use mlua::prelude::*;
use rodio::Source;

/// Decoded audio samples in f32 PCM format.
///
/// Stores interleaved samples (for stereo: L, R, L, R, ...). Samples are
/// always clamped to `[-1.0, 1.0]` on write. Can be constructed as a
/// silent buffer or decoded from a file. Exposes per-sample access for
/// procedural audio, oscillators, and effect processing from Lua.
///
/// # Fields
/// - `samples` — `Vec<f32>`.
/// - `sample_rate` — `u32`.
/// - `channels` — `u16`.
/// - `bit_depth` — `u16`.
#[derive(Debug, Clone)]
pub struct SoundData {
    samples: Vec<f32>,
    sample_rate: u32,
    channels: u16,
    bit_depth: u16,
}

impl SoundData {
    /// Create a silent buffer with the given number of samples.
    ///
    /// # Parameters
    /// - `sample_count` — `usize`.
    /// - `sample_rate` — `u32`.
    /// - `channels` — `u16`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(sample_count: usize, sample_rate: u32, channels: u16) -> Self {
        Self {
            samples: vec![0.0; sample_count * channels as usize],
            sample_rate,
            channels,
            bit_depth: 32,
        }
    }

    /// Create a `SoundData` from an existing f32 sample buffer.
    ///
    /// # Parameters
    /// - `samples` — `Vec<f32>`.
    /// - `sample_rate` — `u32`.
    /// - `channels` — `u16`.
    ///
    /// # Returns
    /// `Self`.
    pub fn from_samples(samples: Vec<f32>, sample_rate: u32, channels: u16) -> Self {
        Self {
            samples,
            sample_rate,
            channels,
            bit_depth: 16,
        }
    }

    /// Creates `SoundData` from Lua-originated arguments, supporting both file loading and silent buffer creation.
    ///
    /// When `path` is `Some`, the audio file at that path is decoded into PCM samples via
    /// [`SoundData::from_file`].  When `path` is `None`, a zero-filled silent buffer of
    /// `count` samples is created with [`SoundData::new`].
    ///
    /// # Parameters
    /// - `path` — `Option<&str>`. Full resolved file path for file loading; `None` for a silent buffer.
    /// - `count` — `usize`. Sample count for a silent buffer; ignored when `path` is `Some`.
    /// - `sample_rate` — `u32`. Sample rate in Hz (e.g. `44100`).
    /// - `channels` — `u16`. Channel count (e.g. `1` for mono, `2` for stereo).
    ///
    /// # Returns
    /// `Result<Self, String>`.
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

    /// Decode an audio file to SoundData. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `path` — `&str`.
    ///
    /// # Returns
    /// `Result<Self, String>`.
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
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<f32>`.
    pub fn get_sample(&self, index: usize) -> Option<f32> {
        self.samples.get(index).copied()
    }

    /// Returns the full interleaved f32 sample buffer as a slice.
    ///
    /// # Returns
    /// `&[f32]`.
    pub fn samples(&self) -> &[f32] {
        &self.samples
    }

    /// Set a sample at the given index (clamped to [-1.0, 1.0]).
    ///
    /// # Parameters
    /// - `index` — `usize`.
    /// - `value` — `f32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn set_sample(&mut self, index: usize, value: f32) -> bool {
        if index < self.samples.len() {
            self.samples[index] = value.clamp(-1.0, 1.0);
            true
        } else {
            false
        }
    }

    /// Get the number of samples per channel. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `usize`.
    pub fn sample_count(&self) -> usize {
        if self.channels == 0 {
            return 0;
        }
        self.samples.len() / self.channels as usize
    }

    /// Get the sample rate in Hz. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `u32`.
    pub fn sample_rate(&self) -> u32 {
        self.sample_rate
    }

    /// Get the number of audio channels. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `u16`.
    pub fn channel_count(&self) -> u16 {
        self.channels
    }

    /// Get the bit depth. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `u16`.
    pub fn bit_depth(&self) -> u16 {
        self.bit_depth
    }

    /// Get the duration in seconds. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `f64`.
    pub fn duration(&self) -> f64 {
        if self.sample_rate == 0 {
            return 0.0;
        }
        self.sample_count() as f64 / self.sample_rate as f64
    }

    /// Get a reference to the raw samples. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&[f32]`.
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
