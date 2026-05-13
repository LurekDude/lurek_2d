//! Streaming PCM chunk decoding from audio files.

use crate::log_msg;
use crate::runtime::log_messages::AD01_AUDIO_DECODED;
use crate::runtime::EngineError;

/// Streaming audio decoder that loads a file to memory and serves fixed-size chunks.
pub struct Decoder {
    /// Source file path.
    pub path: String,
    /// Sample rate in Hz.
    pub sample_rate: u32,
    /// Channel count.
    pub channels: u16,
    /// Output bit depth.
    pub bit_depth: u16,
    /// Max samples per `decode()` call.
    pub buffer_size: usize,
    /// Cursor in interleaved sample units.
    cursor: usize,
    /// Fully decoded interleaved PCM buffer.
    pcm: Vec<i16>,
}

impl Decoder {
    /// Loads an audio file into memory and creates a chunk decoder.
    ///
    /// # Arguments
    /// * `path` - Input audio file path.
    /// * `buffer_size` - Max samples returned by one `decode()` call.
    ///
    /// # Errors
    /// Returns `EngineError::FileSystemError` when opening the file fails.
    /// Returns `EngineError::AudioError` when decoding fails.
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

        log_msg!(debug, AD01_AUDIO_DECODED, "{}", path);
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

    /// Returns the next fixed-size chunk, or `None` at end of stream.
    pub fn decode(&mut self) -> Option<Vec<i16>> {
        if self.cursor >= self.pcm.len() {
            return None;
        }
        let end = (self.cursor + self.buffer_size).min(self.pcm.len());
        let chunk = self.pcm[self.cursor..end].to_vec();
        self.cursor = end;
        Some(chunk)
    }

    /// Returns total decoded duration in seconds.
    pub fn get_duration(&self) -> f64 {
        if self.sample_rate == 0 || self.channels == 0 {
            return 0.0;
        }
        self.pcm.len() as f64 / (self.sample_rate as f64 * self.channels as f64)
    }

    /// Seeks to position in seconds.
    ///
    /// # Arguments
    /// * `offset` - Target time in seconds.
    pub fn seek(&mut self, offset: f64) {
        let sample_pos = (offset * self.sample_rate as f64 * self.channels as f64) as usize;
        self.cursor = sample_pos.min(self.pcm.len());
    }

    /// Returns current playback position in seconds.
    pub fn tell(&self) -> f64 {
        if self.sample_rate == 0 || self.channels == 0 {
            return 0.0;
        }
        self.cursor as f64 / (self.sample_rate as f64 * self.channels as f64)
    }

    /// Returns whether this decoder supports seeking.
    pub fn is_seekable(&self) -> bool {
        true
    }

    /// Rewinds playback to the beginning.
    pub fn rewind(&mut self) {
        self.cursor = 0;
    }
}
