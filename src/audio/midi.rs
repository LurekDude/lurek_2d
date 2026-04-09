//! MIDI SoundFont state management.
//!
//! Provides `MidiState` for tracking whether a SoundFont (SF2) file has
//! been loaded for MIDI instrument rendering.
//!
//! This module is part of Lurek2D's `audio` subsystem and provides the implementation
//! details for midi-related operations and data management.
//! Key types exported from this module: `MidiState`.
//! Primary functions: `new()`, `set_soundfont()`, `has_soundfont()`, `clear_soundfont()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

/// MIDI SoundFont state.
///
/// Tracks whether a SoundFont (SF2) file has been loaded and stores its raw
/// bytes for future MIDI decoding. At most one SoundFont can be active at a
/// time; loading a new one replaces the previous. The data is validated for a
/// valid RIFF/sfbk header before being stored.
///
/// # Fields
/// - `soundfont_data` — `Option<Vec<u8>>`.
/// - `soundfont_path` — `Option<String>`.
#[derive(Debug, Clone, Default)]
pub struct MidiState {
    /// Raw SF2 SoundFont data, or `None` if no SoundFont is loaded.
    soundfont_data: Option<Vec<u8>>,
    /// Path of the loaded SoundFont file, if any.
    soundfont_path: Option<String>,
}

impl MidiState {
    /// Create a new empty MidiState with no SoundFont loaded.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            soundfont_data: None,
            soundfont_path: None,
        }
    }

    /// Load a SoundFont from raw SF2 data. Replaces the current soundfont value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `data` — `Vec<u8>`.
    /// - `path` — `Option<String>`.
    ///
    /// # Returns
    /// `Result<(), String>`.
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
    ///
    /// # Returns
    /// `bool`.
    pub fn has_soundfont(&self) -> bool {
        self.soundfont_data.is_some()
    }

    /// Clear the loaded SoundFont, freeing its memory.
    pub fn clear_soundfont(&mut self) {
        self.soundfont_data = None;
        self.soundfont_path = None;
    }

    /// Get the path of the loaded SoundFont, if any.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn soundfont_path(&self) -> Option<&str> {
        self.soundfont_path.as_deref()
    }

    /// Get a reference to the raw SoundFont data, if loaded.
    ///
    /// # Returns
    /// `Option<&[u8]>`.
    pub fn soundfont_data(&self) -> Option<&[u8]> {
        self.soundfont_data.as_deref()
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
