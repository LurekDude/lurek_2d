//! INTERNAL ONLY: Rust-only tests for audio helpers and data structures that are not directly
//! asserted through `lurek.audio.*`.
//!
//! Public playback, mixer, bus, MIDI-player, pool, and sound-data behaviour is
//! covered by the Lua-first suite in `tests/lua/unit/test_audio_unit.lua`.
//! The remaining Rust coverage keeps low-level DSP/state helpers and offline
//! struct invariants.

use lurek2d::audio::dsp::{AtomicParam, EffectParams, EffectType};
use lurek2d::audio::offline::OfflineEffect;
use lurek2d::audio::*;

// ── dsp tests ────────────────────────────────────────────────────────────────

mod dsp_tests {
    use super::*;

    #[test]
    fn atomic_param_get_set() {
        let p = AtomicParam::new(3.14);
        assert!((p.get() - 3.14).abs() < 0.001);
        p.set(2.0);
        assert!((p.get() - 2.0).abs() < 0.001);
    }

    #[test]
    fn effect_params_set_param_lowpass() {
        let ep = EffectParams::new(1, EffectType::Lowpass);
        assert!(ep.set_param("cutoff", 1000.0).is_ok());
        assert!((ep.p1.get() - 1000.0).abs() < 0.001);
        assert!(ep.set_param("q", 0.707).is_ok());
        assert!((ep.p2.get() - 0.707).abs() < 0.001);
        assert!(ep.set_param("invalid", 0.0).is_err());
    }

    #[test]
    fn effect_params_set_param_reverb() {
        let ep = EffectParams::new(2, EffectType::Reverb);
        assert!(ep.set_param("room_size", 0.8).is_ok());
        assert!(ep.set_param("damping", 0.4).is_ok());
        assert!(ep.set_param("mix", 0.3).is_ok());
        assert!((ep.p3.get() - 0.3).abs() < 0.001);
    }

    #[test]
    fn effect_params_set_param_compressor() {
        let ep = EffectParams::new(3, EffectType::Compressor);
        assert!(ep.set_param("threshold", -12.0).is_ok());
        assert!(ep.set_param("ratio", 4.0).is_ok());
        assert!(ep.set_param("makeup_gain", 6.0).is_ok());
        assert!(ep.set_param("unknown", 0.0).is_err());
    }

    #[test]
    fn effect_type_variants_distinct() {
        assert_ne!(EffectType::Lowpass, EffectType::Highpass);
        assert_eq!(EffectType::Lowpass, EffectType::Lowpass);
    }
}

// ── midi tests ───────────────────────────────────────────────────────────────

mod midi_tests {
    use super::*;

    fn make_fake_sf2(size: usize) -> Vec<u8> {
        let mut data = vec![0u8; size.max(12)];
        data[0..4].copy_from_slice(b"RIFF");
        data[8..12].copy_from_slice(b"sfbk");
        data
    }

    #[test]
    fn new_state_has_no_soundfont() {
        let state = MidiState::new();
        assert!(!state.has_soundfont());
        assert!(state.soundfont_path().is_none());
        assert!(state.soundfont_data().is_none());
    }

    #[test]
    fn set_and_check_soundfont() {
        let mut state = MidiState::new();
        let sf2 = make_fake_sf2(64);
        state
            .set_soundfont(sf2, Some("test.sf2".to_string()))
            .unwrap();
        assert!(state.has_soundfont());
        assert_eq!(state.soundfont_path(), Some("test.sf2"));
        assert!(state.soundfont_data().unwrap().len() >= 12);
    }

    #[test]
    fn clear_soundfont() {
        let mut state = MidiState::new();
        state.set_soundfont(make_fake_sf2(64), None).unwrap();
        assert!(state.has_soundfont());
        state.clear_soundfont();
        assert!(!state.has_soundfont());
        assert!(state.soundfont_path().is_none());
    }

    #[test]
    fn reject_too_small() {
        let mut state = MidiState::new();
        let result = state.set_soundfont(vec![0u8; 4], None);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("too small"));
    }

    #[test]
    fn reject_invalid_header() {
        let mut state = MidiState::new();
        let result = state.set_soundfont(vec![0u8; 16], None);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("RIFF"));
    }

    #[test]
    fn reject_non_sf2_riff() {
        let mut state = MidiState::new();
        let mut data = vec![0u8; 16];
        data[0..4].copy_from_slice(b"RIFF");
        data[8..12].copy_from_slice(b"WAVE"); // not sfbk
        let result = state.set_soundfont(data, None);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("sfbk"));
    }

    #[test]
    fn default_is_empty() {
        let state = MidiState::default();
        assert!(!state.has_soundfont());
    }
}

// ── offline tests (Rust-only struct coverage) ───────────────────────────────

mod offline_tests {
    use super::*;

    #[test]
    fn offline_effect_struct_fields() {
        let effect = OfflineEffect {
            typ: EffectType::Lowpass,
            p1: 1000.0,
            p2: 0.707,
            p3: 0.5,
        };
        assert_eq!(effect.typ, EffectType::Lowpass);
        assert_eq!(effect.p1, 1000.0);
    }
}

// ── pool tests ───────────────────────────────────────────────────────────────

// ── source tests ─────────────────────────────────────────────────────────────

mod source_tests {
    use super::*;

    #[test]
    fn audio_source_defaults() {
        let src = AudioSource::new(42, "sfx/boom.ogg");
        assert_eq!(src.id, 42);
        assert_eq!(src.file_path, "sfx/boom.ogg");
        assert_eq!(src.volume, 1.0);
        assert!(!src.looping);
    }

    #[test]
    fn spatial_state_default() {
        let s = SpatialState::default();
        assert_eq!(s.position, [0.0, 0.0, 0.0]);
        assert_eq!(s.velocity, [0.0, 0.0, 0.0]);
        // Default orientation: forward = (0,0,-1), up = (0,1,0)
        assert_eq!(s.orientation[2], -1.0);
        assert_eq!(s.orientation[4], 1.0);
    }
}

// ── sound_data tests ─────────────────────────────────────────────────────────
