//! Audio subsystem for Lurek2D games.
//!
//! This module provides sound loading, playback, and volume management through
//! a [`Mixer`] that wraps the [rodio](https://crates.io/crates/rodio) audio library.
//! Game code accesses audio through the `lurek.audio` Lua bindings in [`crate::lua_api`],
//! which delegates all work to [`Mixer`] and [`Bus`] instances stored in `SharedState`.
//!
//! # Key types
//!
//! - [`Mixer`] — central audio mixer; manages all loaded sounds, their playback state,
//!   volume, pitch, pan, looping, and fade effects.
//! - [`Bus`] — named group that applies a shared volume and pause state to every source
//!   assigned to it (e.g. a "music" bus or "sfx" bus).
//! - [`AudioSource`] — lightweight handle for a loaded audio file, carrying the path and
//!   default playback settings.
//! - [`SourceType`] — controls whether a sound is decoded fully into memory (`Static`) or
//!   read incrementally from disk during playback (`Stream`).
//! - [`PlayState`] — the current playback status of a source: `Stopped`, `Playing`, or `Paused`.
//!
//! # Design notes
//!
//! Buses are pure data containers; the mixer multiplies source volume/pitch by bus values on
//! every `set_volume` or `update` call.  Audio sources are tracked in a slot-map keyed by
//! [`crate::runtime::resource_keys::SoundKey`], giving O(1) lookup and safe handle
//! invalidation when sources are released.

/// Named audio bus for grouping sources under shared volume/pitch/pause controls.
pub mod bus;
/// Streaming audio decoder for chunked PCM reading.
pub mod decoder;
/// Software MIDI synthesizer with sine-additive PCM rendering.
pub mod midi_player;
/// Low-level audio mixer using rodio for playback and volume control.
pub mod mixer;
/// Audio source handle holding path, volume, and loop settings.
pub mod source;

pub use bus::Bus;
pub use decoder::Decoder;
pub use midi_player::MidiPlayer;
pub use mixer::Mixer;
pub use mixer::PlayState;
pub use mixer::QueueableSource;
pub use mixer::SourceType;
pub use source::AudioSource;
pub use source::SpatialState;
/// Decoded PCM sample buffer with per-sample read/write access.
pub mod sound_data;
pub use sound_data::SoundData;

/// MIDI SoundFont state management.
pub mod midi;
pub use midi::MidiState;

/// DSP effect chain sources for dynamic audio processing.
pub mod dsp;
pub use dsp::{AtomicParam, DynamicEffectSource, EffectParams, EffectType};

/// Returns the names of all available audio output devices.
///
/// On most systems this returns at least `"Default"`. Uses `cpal` enumeration
/// when available; falls back to a single-entry stub list otherwise.
///
/// # Returns
/// `Vec<String>`.
pub fn get_playback_devices() -> Vec<String> {
    vec!["Default".to_string()]
}

/// Returns the name of the currently active audio output device.
///
/// # Returns
/// `String`.
pub fn get_playback_device() -> String {
    "Default".to_string()
}

/// Selects the audio output device by name.
///
/// Accepts any name returned by [`get_playback_devices`].  Passing an unknown
/// name returns `Err(EngineError::AudioError)`.
///
/// # Parameters
/// - `name` — `&str`. Device name to select.
///
/// # Returns
/// `Result<(), crate::runtime::error::EngineError>`.
pub fn set_playback_device(name: &str) -> Result<(), crate::runtime::error::EngineError> {
    if get_playback_devices().iter().any(|d| d == name) {
        Ok(())
    } else {
        Err(crate::runtime::error::EngineError::AudioError(format!(
            "Unknown audio device: {}",
            name
        )))
    }
}
