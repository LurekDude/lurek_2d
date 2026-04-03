//! Streaming audio decoder for chunked PCM reading.
//!
//! `Decoder` reads an audio file and returns PCM data in fixed-size buffer
//! chunks, enabling streaming playback without loading the entire file into
//! memory.

use crate::engine::EngineError;

/// Streaming audio decoder that reads PCM in fixed-size chunks.
///
/// The decoder eagerly reads the full file on construction (using rodio's
/// decoder), then serves chunks of `buffer_size` samples on each call to
/// `decode()`. This provides a chunk-at-a-time API while keeping file I/O
/// simple and reliable across platforms.
///
/// # Fields
/// - `path` — `String`.
/// - `sample_rate` — `u32`.
/// - `channels` — `u16`.
/// - `bit_depth` — `u16`.
/// - `buffer_size` — `usize`.
pub struct Decoder {
    /// Source file path.
    pub path: String,
    /// Sample rate in Hz.
    pub sample_rate: u32,
    /// Number of audio channels.
    pub channels: u16,
    /// Bit depth of the PCM data.
    pub bit_depth: u16,
    /// Number of samples returned per `decode()` call.
    pub buffer_size: usize,
    cursor: usize,
    pcm: Vec<i16>,
}

impl Decoder {
    /// Load an audio file and prepare it for chunked decoding.
    ///
    /// # Parameters
    /// - `path` — `&str`.
    /// - `buffer_size` — `usize`. Number of samples per chunk.
    ///
    /// # Returns
    /// `Result<Self, EngineError>`.
    pub fn from_file(path: &str, buffer_size: usize) -> Result<Self, EngineError> {
        use rodio::Source;
        use std::fs::File;
        use std::io::BufReader;

        let file = File::open(path)
            .map_err(|e| EngineError::FileSystemError(format!("{}: {}", path, e)))?;
        let decoder = rodio::Decoder::new(BufReader::new(file))
            .map_err(|e| EngineError::AudioError(format!("Decoder error: {}", e)))?;
        let sample_rate = decoder.sample_rate();
        let channels = decoder.channels();
        let pcm: Vec<i16> = decoder.collect();

        Ok(Self {
            path: path.to_string(),
            sample_rate,
            channels,
            bit_depth: 16,
            buffer_size: buffer_size.max(1),
            cursor: 0,
            pcm,
        })
    }

    /// Return the next chunk of samples, or `None` at EOF.
    ///
    /// # Returns
    /// `Option<Vec<i16>>`.
    pub fn decode(&mut self) -> Option<Vec<i16>> {
        if self.cursor >= self.pcm.len() {
            return None;
        }
        let end = (self.cursor + self.buffer_size).min(self.pcm.len());
        let chunk = self.pcm[self.cursor..end].to_vec();
        self.cursor = end;
        Some(chunk)
    }

    /// Return the total duration in seconds.
    ///
    /// # Returns
    /// `f64`.
    pub fn get_duration(&self) -> f64 {
        if self.sample_rate == 0 || self.channels == 0 {
            return 0.0;
        }
        self.pcm.len() as f64 / (self.sample_rate as f64 * self.channels as f64)
    }

    /// Seek to a time offset in seconds.
    ///
    /// # Parameters
    /// - `offset` — `f64`.
    pub fn seek(&mut self, offset: f64) {
        let sample_pos =
            (offset * self.sample_rate as f64 * self.channels as f64) as usize;
        self.cursor = sample_pos.min(self.pcm.len());
    }

    /// Return the current playback position in seconds.
    ///
    /// # Returns
    /// `f64`.
    pub fn tell(&self) -> f64 {
        if self.sample_rate == 0 || self.channels == 0 {
            return 0.0;
        }
        self.cursor as f64 / (self.sample_rate as f64 * self.channels as f64)
    }

    /// Returns whether this decoder supports seeking.
    ///
    /// Always `true` because PCM data is fully buffered in memory.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_seekable(&self) -> bool {
        true
    }

    /// Reset playback to the beginning.
    pub fn rewind(&mut self) {
        self.cursor = 0;
    }
}
