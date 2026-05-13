//! `Decoder` — decodes an audio file (WAV/OGG/MP3/FLAC via rodio) into an i16 PCM buffer.
//! Provides seek, tell, and chunked-decode for streaming readback. Does not own a playback
//! sink; used by `SoundData::from_file` and direct Lua audio API calls.

use crate::log_msg;
use crate::runtime::log_messages::AD01_AUDIO_DECODED;
use crate::runtime::EngineError;
/// Decodes an audio file into an i16 PCM buffer and provides seekable chunk iteration.
pub struct Decoder {
    /// Filesystem path of the source audio file.
    pub path: String,
    /// Sample rate in Hz (e.g. 44100, 48000).
    pub sample_rate: u32,
    /// Channel count (1 = mono, 2 = stereo).
    pub channels: u16,
    /// Bit depth of the decoded PCM; always 16 for this decoder.
    pub bit_depth: u16,
    /// Number of i16 samples returned per `decode()` call; at least 1.
    pub buffer_size: usize,
    /// Current read position as a sample index into `pcm`.
    cursor: usize,
    /// Full decoded PCM sample buffer (interleaved channels, i16).
    pcm: Vec<i16>,
}
impl Decoder {
    /// Open and fully decode `path` using rodio; `buffer_size` sets the chunk size for `decode()`.
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
    /// Return the next `buffer_size` samples as a `Vec<i16>`, advancing the cursor; `None` at end.
    pub fn decode(&mut self) -> Option<Vec<i16>> {
        if self.cursor >= self.pcm.len() {
            return None;
        }
        let end = (self.cursor + self.buffer_size).min(self.pcm.len());
        let chunk = self.pcm[self.cursor..end].to_vec();
        self.cursor = end;
        Some(chunk)
    }
    /// Return total audio duration in seconds; 0.0 if sample rate or channel count is zero.
    pub fn get_duration(&self) -> f64 {
        if self.sample_rate == 0 || self.channels == 0 {
            return 0.0;
        }
        self.pcm.len() as f64 / (self.sample_rate as f64 * self.channels as f64)
    }
    /// Seek to `offset` seconds from the start, clamping to the end of the buffer.
    pub fn seek(&mut self, offset: f64) {
        let sample_pos = (offset * self.sample_rate as f64 * self.channels as f64) as usize;
        self.cursor = sample_pos.min(self.pcm.len());
    }
    /// Return the current playback position in seconds.
    pub fn tell(&self) -> f64 {
        if self.sample_rate == 0 || self.channels == 0 {
            return 0.0;
        }
        self.cursor as f64 / (self.sample_rate as f64 * self.channels as f64)
    }
    /// Return `true`; the PCM buffer always supports random-access seeking.
    pub fn is_seekable(&self) -> bool {
        true
    }
    /// Reset the read cursor to the start of the buffer.
    pub fn rewind(&mut self) {
        self.cursor = 0;
    }
}
