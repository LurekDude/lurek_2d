
//! - Audio subsystem module: mixer, buses, DSP effects, decoders, MIDI, pools, and visualisation.
//! - Re-exports primary types: `Mixer`, `Bus`, `Decoder`, `SoundData`, `MidiPlayer`, `SoundPool`.
//! - Submodule organisation separating playback, offline processing, and device enumeration.

/// `Bus` struct: named per-channel volume/pitch routing with effect chain and duck target.
pub mod bus;
/// `Decoder` struct: seeks and decodes audio files (WAV/OGG/MP3/FLAC) into PCM samples.
pub mod decoder;
/// `MidiPlayer`: loads and plays MIDI files with SoundFont synthesis, per-channel controls.
pub mod midi_player;
/// `Mixer`: rodio-backed slot-map of sources and buses; owns playback, spatial, and peak state.
pub mod mixer;
/// `AudioSource` and `SpatialState`: per-source identity and spatial position/velocity/orientation.
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
/// `SoundData`: in-memory PCM sample buffer with WAV encode, sine-wave generation, and Lua interop.
pub mod sound_data;
pub use sound_data::SoundData;
/// `MidiState`: SoundFont loading and path/data storage for MIDI synthesis.
pub mod midi;
pub use midi::MidiState;
/// DSP effect chain: `EffectType`, `EffectParams`, `AtomicParam`, `ActiveEffect`, `DynamicEffectSource`.
pub mod dsp;
pub use dsp::{AtomicParam, DynamicEffectSource, EffectParams, EffectType};
/// `SoundPool`: polyphonic round-robin voice pool for one-shot sound playback.
pub mod pool;
pub use pool::SoundPool;
/// Offline audio processing: `OfflineEffect`, normalisation, WAV read/write helpers.
pub mod offline;
pub use offline::OfflineEffect;
/// Device enumeration and selection stubs: `get_playback_devices`, `get_playback_device`, `set_playback_device`.
pub mod facade;
/// Audio visualisation: waveform-to-PNG and spectrogram-to-PNG rendering.
pub mod visualizer;
pub use facade::{get_playback_device, get_playback_devices, set_playback_device};
