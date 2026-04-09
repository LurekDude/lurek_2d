# audio — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/audio.md`
**Files**: Large module — Mixer, Bus, SoundData, DSP, Spatial, MIDI, Streaming

## Purpose

Audio playback and mixing via rodio: sound loading, multi-bus mixing, DSP effects, spatial audio, streaming, and MIDI synthesis.

## Current Feature Summary

- `Mixer` manages playback of all sources with master volume
- `Bus` system: named audio buses (music, sfx, ambient) with independent volume
- `SoundData`: in-memory audio data, supports WAV/OGG/FLAC/MP3
- DSP effects: low-pass, high-pass, reverb, echo, chorus, ringmod, distortion, flanger, bitcrush
- Spatial audio: 3D panning based on listener/source positions
- Streaming: large audio file playback without full memory load
- QueueableSource: sequential audio buffer playback
- MIDI player (disabled in current build but architected)
- Volume, pitch, pan, looping per source
- Source groups for batch volume control

## Feature Gaps

1. **No audio analysis/FFT**: No spectrum analysis, beat detection, or frequency data. Essential for music visualizers, rhythm games, and audio-reactive gameplay.
2. **No audio recording/capture**: Can't record microphone input. Less critical for most games but needed for voice chat or music creation tools.
3. **No envelope/ADSR for synthesis**: MIDI player exists but no general-purpose audio synthesis with attack/decay/sustain/release.
4. **No audio graph/routing**: DSP effects are per-source. Can't create complex routing (source → reverb → EQ → bus → master). Modern audio engines use node-based routing.
5. **No crossfade between sources**: Must manually fade out one source and fade in another. A `crossfade(from, to, duration)` would be very common.
6. **No metering**: Volume/peak metering exists as stubs but not implemented.
7. **No audio ducking**: No automatic volume reduction of one bus when another plays (e.g., quiet music during dialogue).
8. **No sound pooling**: Playing the same sound effect 100 times creates 100 sources. A sound pool would reuse/limit concurrent instances.
9. **No random pitch variation**: Common pattern for sound effects — play with ±10% pitch variation each time. Must be done manually.

## Structural Issues

- **Module is very large**: Mixer, Bus, DSP, Spatial, MIDI, Streaming, QueueableSource — many concerns in one module. Consider sub-modules:
  - `audio/core` — mixer, playback, buses
  - `audio/dsp` — effects, filters
  - `audio/spatial` — 3D panning
  - `audio/midi` — MIDI synthesis (currently disabled)
- **Sound module confusion**: `src/sound/` exists as a separate module for raw PCM/SoundData. This should be merged into `audio` — having both `lurek.audio` and `lurek.sound` is confusing for users.
- **MIDI is disabled**: Commented out / gated. Either fully implement or remove to reduce dead code.

## Suggestions

1. **Merge `sound` into `audio`**: SoundData is conceptually part of the audio system. Having `lurek.sound.newSound()` vs `lurek.audio.newSource()` is confusing. Merge both under `lurek.audio`.
2. **Add sound pooling**: `lurek.audio.newPool(sound, maxInstances)` — limits concurrent instances, reuses sources. Extremely common need for rapid-fire SFX.
3. **Add crossfade**: `lurek.audio.crossfade(from, to, duration)` — one-liner for music transitions.
4. **Add random pitch variation**: `source:setRandomPitch(min, max)` — plays back with random pitch within range each time. Ubiquitous in game audio.
5. **Add FFT/spectrum**: `source:getSpectrum(bands)` → returns frequency magnitudes. Unlocks music visualization and rhythm games entirely.
6. **Add audio ducking**: `bus:setDuckTarget(otherBus, duckVolume, fadeTime)` — automatic duck when bus has active sources.

## Competitor Comparison

| Feature | Lurek2D | Engine A | Engine B | FMOD (ref) |
|---|---|---|---|---|
| Multi-bus mixing | ✅ | ❌ (manual) | ❌ | ✅ |
| DSP effects | ✅ (9 types) | ✅ (QueueableSource) | ❌ | ✅ |
| Spatial audio | ✅ | ❌ | ❌ | ✅ |
| FFT/spectrum | ❌ | ❌ | ❌ | ✅ |
| Streaming | ✅ | ✅ | ✅ | ✅ |
| MIDI | ✅ (disabled) | ❌ | ❌ | ❌ |
| Sound pooling | ❌ | ✅ | ❌ | ✅ |
| Crossfade | ❌ | ❌ | ✅ | ✅ |

## Priority

**MEDIUM** — Audio is already very capable. Sound pooling and crossfade have the highest practical impact. FFT unlocks new game genres (rhythm). Merging `sound` module is a structural improvement.
