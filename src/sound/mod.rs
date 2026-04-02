//! Decoded audio sample manipulation and MIDI SoundFont state.
//!
//! This module re-exports from [`crate::audio`] for LÖVE 2D module-name
//! compatibility. All implementation lives in the `audio` module.

pub use crate::audio::midi::MidiState;
pub use crate::audio::sound_data::SoundData;
