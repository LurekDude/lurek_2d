//! Audio subsystem: mixer, buses, playback state, DSP effects (via rodio).
//! lurek.audio Lua bindings delegate to Mixer + Bus in SharedState.

/// Named audio bus: shared volume/pitch/pause/effects.
pub mod bus;
/// Decoder: streaming audio reading via rodio.
pub mod decoder;
/// MIDI player: sine-additive synthesis (currently disabled - midly removed).
pub mod midi_player;
/// Mixer: sound loading, playback, volume, bus routing.
pub mod mixer;
/// AudioSource: handle with path, volume, looping state.
pub mod source;

/// Re-export from bus.
pub use bus::Bus;
/// Re-export from decoder.
pub use decoder::Decoder;
/// Re-export from midi_player.
pub use midi_player::MidiPlayer;
/// Re-export from mixer.
pub use mixer::Mixer;
/// Re-export from mixer.
pub use mixer::PlayState;
/// Re-export from mixer.
pub use mixer::QueueableSource;
/// Re-export from mixer.
pub use mixer::SourceType;
/// Re-export from source.
pub use source::AudioSource;
/// Re-export from source.
pub use source::SpatialState;
/// SoundData: f32 PCM buffer, procedural waveforms, DSP operations.
pub mod sound_data;
/// Re-export from sound_data.
pub use sound_data::SoundData;

/// MidiState: loaded SoundFont data and path.
pub mod midi;
/// Re-export from midi.
pub use midi::MidiState;

/// DSP effects: biquads, reverb, modulation, dynamics, lock-free parameters.
pub mod dsp;
/// Re-exports from dsp.
pub use dsp::{AtomicParam, DynamicEffectSource, EffectParams, EffectType};

/// SoundPool: round-robin voice cycling for polyphony.
pub mod pool;
/// Re-export from pool.
pub use pool::SoundPool;

/// Offline: decode, apply effects, normalize, write WAV.
pub mod offline;
/// Re-export from offline.
pub use offline::OfflineEffect;

/// Visualizer: waveform and spectrogram PNG rendering.
pub mod visualizer;

/// Facade: playback device enumeration (stub).
pub mod facade;
/// Re-exports from facade.
pub use facade::{get_playback_device, get_playback_devices, set_playback_device};
