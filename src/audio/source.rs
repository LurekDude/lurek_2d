//! Audio source type and playback state enums for the audio subsystem.
//!
//! The primary audio logic lives in `mixer::Mixer`. This module re-exports
//! the public enum types used by the Lua API and engine code.

/// Handle for a loaded audio asset (legacy compatibility shim).
///
/// # Fields
/// - `id` — `usize`.
/// - `file_path` — `String`.
/// - `volume` — `f32`.
/// - `looping` — `bool`.
///
/// Superseded by `Mixer`'s `SlotMap<SoundKey, AudioEntry>`. Kept for API
/// compatibility but not used in the active code path.
pub struct AudioSource {
    /// Numeric index (legacy, unused by SlotMap-based mixer).
    pub id: usize,
    /// Path to the audio file, relative to the game directory.
    pub file_path: String,
    /// Playback volume in `[0.0, 2.0]`; defaults to `1.0`.
    pub volume: f32,
    /// Whether the source should loop on completion; defaults to `false`.
    pub looping: bool,
}

impl AudioSource {
    /// Creates a new `AudioSource` with default volume (1.0) and looping disabled.
    ///
    /// # Parameters
    /// - `id` — `usize`.
    /// - `file_path` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(id: usize, file_path: &str) -> Self {
        AudioSource {
            id,
            file_path: file_path.to_string(),
            volume: 1.0,
            looping: false,
        }
    }
}
