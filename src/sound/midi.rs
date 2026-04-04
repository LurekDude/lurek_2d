//! MIDI SoundFont state management.
//!
//! Provides `MidiState` for tracking whether a SoundFont (SF2) file has
//! been loaded for MIDI instrument rendering, and `render_midi` for
//! offline synthesis of MIDI files to PCM audio.

use std::io::Cursor;
use std::sync::Arc;

/// MIDI SoundFont state.
///
/// Tracks whether a SoundFont (SF2) file has been loaded and stores its
/// raw bytes for future MIDI decoding.
#[derive(Debug, Clone, Default)]
pub struct MidiState {
    /// Raw SF2 SoundFont data, or `None` if no SoundFont is loaded.
    soundfont_data: Option<Vec<u8>>,
    /// Path of the loaded SoundFont file, if any.
    soundfont_path: Option<String>,
}

impl MidiState {
    /// Create a new empty MidiState with no SoundFont loaded.
    pub fn new() -> Self {
        Self {
            soundfont_data: None,
            soundfont_path: None,
        }
    }

    /// Load a SoundFont from raw SF2 data.
    ///
    /// Validates the RIFF header before storing. Returns an error if
    /// the data is too small or has an invalid header.
    pub fn set_soundfont(&mut self, data: Vec<u8>, path: Option<String>) -> Result<(), String> {
        // Minimal SF2 header validation: must start with RIFF
        if data.len() < 12 {
            return Err("SoundFont data too small (expected RIFF header)".to_string());
        }
        if &data[0..4] != b"RIFF" {
            return Err("Invalid SoundFont: missing RIFF header".to_string());
        }
        // Bytes 8..12 should be "sfbk" for SF2 files
        if &data[8..12] != b"sfbk" {
            return Err("Invalid SoundFont: not an SF2 file (missing sfbk chunk)".to_string());
        }
        self.soundfont_data = Some(data);
        self.soundfont_path = path;
        Ok(())
    }

    /// Check whether a SoundFont is currently loaded.
    pub fn has_soundfont(&self) -> bool {
        self.soundfont_data.is_some()
    }

    /// Clear the loaded SoundFont, freeing its memory.
    pub fn clear_soundfont(&mut self) {
        self.soundfont_data = None;
        self.soundfont_path = None;
    }

    /// Get the path of the loaded SoundFont, if any.
    pub fn soundfont_path(&self) -> Option<&str> {
        self.soundfont_path.as_deref()
    }

    /// Get a reference to the raw SoundFont data, if loaded.
    pub fn soundfont_data(&self) -> Option<&[u8]> {
        self.soundfont_data.as_deref()
    }

    /// Render a MIDI file to interleaved stereo PCM samples at 44100 Hz.
    ///
    /// Requires a SoundFont to be loaded. The `midi_bytes` parameter is
    /// the raw content of a `.mid` file. Returns interleaved stereo `f32`
    /// samples (left, right, left, right, ...) at 44100 Hz sample rate.
    pub fn render_midi(&self, midi_bytes: &[u8]) -> Result<Vec<f32>, String> {
        let sf_data = self
            .soundfont_data
            .as_ref()
            .ok_or_else(|| "No SoundFont loaded — call setMidiSoundFont first".to_string())?;

        // Parse the SoundFont
        let mut sf_cursor = Cursor::new(sf_data.as_slice());
        let sound_font = Arc::new(
            rustysynth::SoundFont::new(&mut sf_cursor)
                .map_err(|e| format!("Failed to parse SoundFont: {}", e))?,
        );

        // Parse the MIDI file
        let mut mid_cursor = Cursor::new(midi_bytes);
        let midi_file = Arc::new(
            rustysynth::MidiFile::new(&mut mid_cursor)
                .map_err(|e| format!("Failed to parse MIDI file: {}", e))?,
        );

        // Create synthesizer and sequencer
        let settings = rustysynth::SynthesizerSettings::new(44100);
        let synthesizer = rustysynth::Synthesizer::new(&sound_font, &settings)
            .map_err(|e| format!("Failed to create synthesizer: {}", e))?;
        let mut sequencer = rustysynth::MidiFileSequencer::new(synthesizer);

        // Render the entire MIDI file
        let sample_count = (settings.sample_rate as f64 * midi_file.get_length()) as usize;
        if sample_count == 0 {
            return Ok(Vec::new());
        }

        let mut left = vec![0.0f32; sample_count];
        let mut right = vec![0.0f32; sample_count];

        sequencer.play(&midi_file, false);
        sequencer.render(&mut left, &mut right);

        // Interleave L/R for standard audio pipeline
        let mut interleaved = Vec::with_capacity(sample_count * 2);
        for i in 0..sample_count {
            interleaved.push(left[i]);
            interleaved.push(right[i]);
        }

        Ok(interleaved)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_fake_sf2(size: usize) -> Vec<u8> {
        let mut data = vec![0u8; size.max(12)];
        data[0..4].copy_from_slice(b"RIFF");
        // bytes 4..8 = file size - 8 (little-endian), not validated
        data[8..12].copy_from_slice(b"sfbk");
        data
    }

    #[test]
    fn new_state_has_no_soundfont() {
        let state = MidiState::new();
        assert!(!state.has_soundfont());
        assert!(state.soundfont_path().is_none());
        assert!(state.soundfont_data().is_none());
    }

    #[test]
    fn set_and_check_soundfont() {
        let mut state = MidiState::new();
        let sf2 = make_fake_sf2(64);
        state
            .set_soundfont(sf2, Some("test.sf2".to_string()))
            .unwrap();
        assert!(state.has_soundfont());
        assert_eq!(state.soundfont_path(), Some("test.sf2"));
        assert!(state.soundfont_data().unwrap().len() >= 12);
    }

    #[test]
    fn clear_soundfont() {
        let mut state = MidiState::new();
        state.set_soundfont(make_fake_sf2(64), None).unwrap();
        assert!(state.has_soundfont());
        state.clear_soundfont();
        assert!(!state.has_soundfont());
        assert!(state.soundfont_path().is_none());
    }

    #[test]
    fn reject_too_small() {
        let mut state = MidiState::new();
        let result = state.set_soundfont(vec![0u8; 4], None);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("too small"));
    }

    #[test]
    fn reject_invalid_header() {
        let mut state = MidiState::new();
        let result = state.set_soundfont(vec![0u8; 16], None);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("RIFF"));
    }

    #[test]
    fn reject_non_sf2_riff() {
        let mut state = MidiState::new();
        let mut data = vec![0u8; 16];
        data[0..4].copy_from_slice(b"RIFF");
        data[8..12].copy_from_slice(b"WAVE"); // not sfbk
        let result = state.set_soundfont(data, None);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("sfbk"));
    }

    #[test]
    fn default_is_empty() {
        let state = MidiState::default();
        assert!(!state.has_soundfont());
    }
}
