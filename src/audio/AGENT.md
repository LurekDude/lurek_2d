# `audio` — Agent Reference

| Property       | Value                                                                    |
|----------------|--------------------------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                                          |
| **Status**     | Implemented — Full                                                       |
| **Lua API**    | `lurek.audio`                                                             |
| **Source**     | `src/audio/`                                                             |
| **Rust Tests** | `tests/rust/unit/audio_tests.rs`, `tests/rust/unit/audio_sound_tests.rs` |
| **Lua Tests**  | `tests/lua/unit/test_audio.lua`, `tests/lua/unit/test_audio_dsp.lua`, `tests/lua/unit/test_audio_bus.lua` |
| **Architecture** | —                                                                      |

## Purpose

The audio module wraps the `rodio` cross-platform audio library into a game-oriented mixing layer, handling every stage of game audio from file loading to final output. It decodes sound files (WAV, OGG Vorbis, FLAC, MP3) into static in-memory sources or streaming sources, controls per-source playback state (volume, pitch, looping, fade in/out, seek), routes sources through named audio buses for grouped volume and pitch control, and applies real-time DSP effects (lowpass, highpass, bandpass biquad filters, comb-filter reverb, and chorus) via a lock-free `DynamicEffectSource` wrapper that chains effects on the audio thread without blocking the main engine loop.

## Source Files

| File             | Purpose                                                                              |
|------------------|--------------------------------------------------------------------------------------|
| `mod.rs`         | Module root — declares submodules and re-exports Mixer, Bus, AudioSource, SoundData, MidiPlayer, MidiState, Decoder, DSP types |
| `bus.rs`         | Named audio bus with shared volume, pitch, pause, and DSP effect chain               |
| `decoder.rs`     | Streaming audio decoder for chunked PCM reading from disk                            |
| `dsp.rs`         | DSP effect chain: AtomicParam, EffectType, EffectParams, ActiveEffect, DynamicEffectSource |
| `midi.rs`        | MIDI SoundFont state management (SF2 validation and storage)                         |
| `midi_player.rs` | Software MIDI synthesizer with sine-additive PCM rendering via rodio Sink            |
| `mixer.rs`       | Core audio mixer: source loading, playback control, bus routing, spatial audio, queueable sources |
| `sound_data.rs`  | Decoded PCM sample buffer with per-sample read/write access (Lua UserData)           |
| `source.rs`      | AudioSource handle (legacy shim) and SpatialState for 3D positioning                 |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/audio.md`](../../docs/specs/audio.md)

_Update both this file **and** `docs/specs/audio.md` whenever source files, public types, or Lua bindings change._
