//! Audio source type and playback state enums for the audio subsystem.
//!
//! The primary audio logic lives in `mixer::Mixer`. This module re-exports
//! the public enum types used by the Lua API and engine code.
//!
//! This module is part of Luna2D's `audio` subsystem and provides the implementation
//! details for source-related operations and data management.
//! Key types exported from this module: `AudioSource`.
//! Primary functions: `new()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// 3D spatial audio state for an audio source.
///
/// Used to compute panning relative to the listener position.
/// Luna2D uses 2D x/y primarily; z is accepted but ignored for panning calculation.
///
/// # Fields
/// - `position` — `[f32; 3]`. World-space position `[x, y, z]`.
/// - `velocity` — `[f32; 3]`. World-space velocity vector (for Doppler).
/// - `orientation` — `[f32; 6]`. Forward (xyz) + up (xyz) vectors.
#[derive(Debug, Clone, Copy)]
pub struct SpatialState {
    /// World-space position `[x, y, z]`.
    pub position: [f32; 3],
    /// World-space velocity vector (for Doppler effect calculation).
    pub velocity: [f32; 3],
    /// Forward direction followed by up direction (6 floats total).
    pub orientation: [f32; 6],
}

impl Default for SpatialState {
    fn default() -> Self {
        SpatialState {
            position: [0.0, 0.0, 0.0],
            velocity: [0.0, 0.0, 0.0],
            orientation: [0.0, 0.0, -1.0, 0.0, 1.0, 0.0],
        }
    }
}

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
