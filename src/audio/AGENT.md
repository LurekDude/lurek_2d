# audio

## Module Info
- Module name: `audio`
- Module group: `Platform Services`
- Spec path: `docs/specs/audio.md`
- Lua API path(s): `src/lua_api/audio_api.rs`
- Rust test path(s): `tests/rust/unit/audio_tests.rs`, `tests/rust/unit/audio_sound_tests.rs`
- Lua test path(s): `tests/lua/unit/test_audio.lua`, `tests/lua/unit/test_audio_bus.lua`, `tests/lua/unit/test_audio_dsp.lua`, `tests/lua/integration/test_audio_timer.lua`, `tests/lua/integration/test_audio_event.lua`, `tests/lua/evidence/test_evidence_audio.lua`, `tests/lua/evidence/test_evidence_audio_bus.lua`

## Module Purpose

The audio module is Lurek2D's playback and mixing backend. It owns sound loading and decoding, per-source playback state, bus routing, master volume, spatial audio state, queueable PCM playback, and the DSP chain used to apply filters and other real-time effects to audio sources and buses.

This module exists so gameplay code can treat sound as engine-managed resources instead of juggling raw backend handles. `Mixer` is the operational center, `Bus` provides grouped control over multiple sources, `SoundData` exposes editable PCM data to Lua, and the DSP types make effect updates safe to push from the main thread while playback continues on the audio thread.

It intentionally does not own filesystem sandboxing, frame timing, or scripting registration. Audio files still come through `filesystem`, the app loop decides when scripts call playback functions, and `src/lua_api/audio_api.rs` decides how the audio surface is exposed to Lua. It also does not currently provide a full multi-device backend or a finished MIDI pipeline; MIDI support is partially present in code but currently constrained by missing parsing dependencies.

## Files
- `mod.rs` is the audio module root and re-export surface. It gathers the mixer, buses, source handles, sound buffers, MIDI helpers, decoder, and DSP types into one import point.
- `mixer.rs` is the core runtime engine for audio. It owns loaded sources, active playback state, bus routing, queueable sources, listener state, and the main control methods used by the Lua API.
- `bus.rs` defines named buses for grouped control over volume, pitch, pause state, and shared effect chains. It is the right place for audio-group semantics.
- `source.rs` defines the legacy `AudioSource` handle and the current `SpatialState` data used for positional playback. It matters mostly for compatibility and spatial-audio bookkeeping.
- `sound_data.rs` defines the editable PCM sample buffer exposed to Lua. This is the right file when work involves raw sample access rather than ordinary playback.
- `decoder.rs` implements the chunked decoder used for streamed audio reads. It is the module's lower-level decode helper rather than the main playback API.
- `midi.rs` stores and validates SoundFont state. It is the small state-management half of MIDI support.
- `midi_player.rs` contains the software MIDI player and synthesis path. It is important for module coverage, but parts of this path are currently constrained by disabled parsing support.
- `dsp.rs` implements the lock-free effect system. It owns atomic effect parameters, active effect instances, and the rodio source wrapper that applies DSP processing during playback.

## Key Types
- `Mixer` is the central ownership object for this module. It manages sound resources, active playback, buses, queueable sources, listener state, and the rodio output handle.
- `Bus` is the grouped-control object for audio routing. It lets multiple sources share volume, pitch, pause state, and a DSP effect chain.
- `SoundData` is the owned PCM sample buffer exposed to Lua for procedural or editable audio data. It is the bridge between raw samples and higher-level playback features.
- `AudioSource` is the legacy source-handle object retained for compatibility. It is less central than `Mixer`, but it still matters when tracing older code paths.
- `SpatialState` stores position, velocity, and orientation for positional audio. It is the per-source or listener-side state used by the mixer's spatial calculations.
- `Decoder` is the chunked decode helper for streaming-oriented use cases. It separates decoding concerns from the mixer's playback-control logic.
- `QueueableSource` is the queue-backed source for manually fed PCM buffers. It is the main object to inspect when audio is generated or streamed incrementally by game code.
- `PlayState` describes whether a source is stopped, playing, or paused. It is the core playback lifecycle enum for mixer-managed entries.
- `SourceType` distinguishes static and streamed sources. That distinction drives memory and playback behavior across the module.
- `AtomicParam` is the lock-free parameter container used by the DSP system. It is important because effect tuning happens across thread boundaries.
- `EffectType` names the DSP effect categories the engine supports. It is the public vocabulary for audio filtering and effect routing.
- `EffectParams` is the shared configuration record for one effect slot. It keeps effect tuning separate from the per-stream processing state.
- `ActiveEffect` is the per-stream DSP state object used while samples are actually being processed. It is where effect history and delay buffers live.
- `DynamicEffectSource` is the audio-thread wrapper that applies the current DSP chain to an inner rodio source. It is the crucial object that makes dynamic effects work during playback.
- `MidiState` stores the currently loaded SoundFont and validates that the data looks like a SoundFont file. It is the minimal persistent MIDI state for the module.
- `MidiPlayer` is the software MIDI playback object. It owns synthesis-side playback behavior even though parts of the full pipeline are currently constrained.
- `MidiData` is the parsed metadata snapshot used by the MIDI path. It matters when reasoning about track counts, tempo, note counts, and duration.