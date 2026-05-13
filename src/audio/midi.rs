//! `MidiState` — holds the loaded SoundFont data and path for MIDI synthesis.
//! Validates SF2 RIFF headers on load and provides accessor methods used by `MidiPlayer`
//! and the Lua MIDI API. Does not own a playback engine or rodio resources.

#[derive(Debug, Clone, Default)]
/// Stores the loaded SoundFont binary data and its source path for MIDI synthesis.
pub struct MidiState {
    /// SF2-format SoundFont binary loaded from disk; validated on `set_soundfont`.
    soundfont_data: Option<Vec<u8>>,
    /// Source path of the loaded SoundFont file, if provided at load time.
    soundfont_path: Option<String>,
}
impl MidiState {
    /// Create a new `MidiState` with no SoundFont loaded.
    pub fn new() -> Self {
        Self {
            soundfont_data: None,
            soundfont_path: None,
        }
    }
    /// Load `data` as an SF2 SoundFont, validating the RIFF+sfbk header; error if invalid.
    pub fn set_soundfont(&mut self, data: Vec<u8>, path: Option<String>) -> Result<(), String> {
        if data.len() < 12 {
            return Err("SoundFont data too small (expected RIFF header)".to_string());
        }
        if &data[0..4] != b"RIFF" {
            return Err("Invalid SoundFont: missing RIFF header".to_string());
        }
        if &data[8..12] != b"sfbk" {
            return Err("Invalid SoundFont: not an SF2 file (missing sfbk chunk)".to_string());
        }
        self.soundfont_data = Some(data);
        self.soundfont_path = path;
        Ok(())
    }
    /// Return `true` when a SoundFont is loaded and ready for synthesis.
    pub fn has_soundfont(&self) -> bool {
        self.soundfont_data.is_some()
    }
    /// Unload the current SoundFont and clear its path.
    pub fn clear_soundfont(&mut self) {
        self.soundfont_data = None;
        self.soundfont_path = None;
    }
    /// Return the source path of the loaded SoundFont, or `None` if none was loaded or path was not provided.
    pub fn soundfont_path(&self) -> Option<&str> {
        self.soundfont_path.as_deref()
    }
    /// Return a byte slice of the loaded SoundFont binary, or `None` if not loaded.
    pub fn soundfont_data(&self) -> Option<&[u8]> {
        self.soundfont_data.as_deref()
    }
}
