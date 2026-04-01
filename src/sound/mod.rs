//! Decoded audio sample manipulation and MIDI SoundFont state.
//!
//! Provides `SoundData` for reading and writing decoded PCM audio samples,
//! and `MidiState` for managing MIDI SoundFont (SF2) loading.

/// Decoded PCM sample buffer with per-sample read/write access.
pub mod sound_data;
pub use sound_data::SoundData;

/// MIDI SoundFont state management.
pub mod midi;
pub use midi::MidiState;
