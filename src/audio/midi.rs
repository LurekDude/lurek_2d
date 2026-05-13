//! MIDI SoundFont state tracking (SF2 format).
//! MidiState: stores validated SF2 data; MIDI player currently disabled.

/// MIDI SoundFont state: loaded SF2 data and path.
#[derive(Debug, Clone, Default)]
pub struct MidiState {
    /// Raw SF2 data.
    soundfont_data: Option<Vec<u8>>,
    /// Path to loaded SF2.
    soundfont_path: Option<String>,
}

impl MidiState {
    /// Create new empty state.
    pub fn new() -> Self {
        Self {
            soundfont_data: None,
            soundfont_path: None,
        }
    }

    /// Load SF2 data and validate RIFF/sfbk header; return error on invalid format.
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

    /// Return true if a SoundFont is loaded.
    pub fn has_soundfont(&self) -> bool {
        self.soundfont_data.is_some()
    }

    /// Clear the loaded SoundFont.
    pub fn clear_soundfont(&mut self) {
        self.soundfont_data = None;
        self.soundfont_path = None;
    }

    /// Returns the SoundFont path, if any.
    pub fn soundfont_path(&self) -> Option<&str> {
        self.soundfont_path.as_deref()
    }

    /// Returns a reference to the raw SoundFont data, if loaded.
    pub fn soundfont_data(&self) -> Option<&[u8]> {
        self.soundfont_data.as_deref()
    }
}

