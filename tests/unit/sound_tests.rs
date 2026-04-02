//! Integration tests for the sound data module.

use luna2d::audio::SoundData;

#[test]
fn sound_data_new_silent() {
    let sd = SoundData::new(100, 44100, 1);
    assert_eq!(sd.sample_count(), 100);
    assert_eq!(sd.sample_rate(), 44100);
    assert_eq!(sd.channel_count(), 1);
    assert_eq!(sd.get_sample(0), Some(0.0));
}

#[test]
fn sound_data_set_get_sample() {
    let mut sd = SoundData::new(10, 44100, 1);
    assert!(sd.set_sample(5, 0.75));
    assert_eq!(sd.get_sample(5), Some(0.75));
}

#[test]
fn sound_data_clamp_sample() {
    let mut sd = SoundData::new(10, 44100, 1);
    sd.set_sample(0, 2.0);
    assert_eq!(sd.get_sample(0), Some(1.0)); // clamped
    sd.set_sample(0, -2.0);
    assert_eq!(sd.get_sample(0), Some(-1.0)); // clamped
}

#[test]
fn sound_data_duration() {
    let sd = SoundData::new(44100, 44100, 1);
    assert!((sd.duration() - 1.0).abs() < 1e-5);
}

#[test]
fn sound_data_stereo() {
    let sd = SoundData::new(100, 44100, 2);
    assert_eq!(sd.sample_count(), 100); // 100 samples per channel
    assert_eq!(sd.channel_count(), 2);
}

#[test]
fn sound_data_out_of_bounds() {
    let sd = SoundData::new(10, 44100, 1);
    assert_eq!(sd.get_sample(100), None);
}

// ── Phase 32 — MIDI SoundFont state ────────────────────────────────────

use luna2d::audio::MidiState;

#[test]
fn midi_state_default_empty() {
    let state = MidiState::new();
    assert!(!state.has_soundfont());
    assert!(state.soundfont_path().is_none());
}

#[test]
fn midi_state_load_and_clear() {
    let mut state = MidiState::new();
    let mut sf2 = vec![0u8; 64];
    sf2[0..4].copy_from_slice(b"RIFF");
    sf2[8..12].copy_from_slice(b"sfbk");
    state
        .set_soundfont(sf2, Some("test.sf2".to_string()))
        .unwrap();
    assert!(state.has_soundfont());
    assert_eq!(state.soundfont_path(), Some("test.sf2"));
    state.clear_soundfont();
    assert!(!state.has_soundfont());
}

#[test]
fn midi_state_reject_invalid() {
    let mut state = MidiState::new();
    let result = state.set_soundfont(vec![0u8; 4], None);
    assert!(result.is_err());
}

// ── Lua integration tests for MIDI API ─────────────────────────────────

use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

use luna2d::lua_api::{create_lua_vm, SharedState};

fn make_vm() -> (Rc<RefCell<SharedState>>, mlua::Lua) {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "test",
        PathBuf::from("."),
    )));
    let lua = create_lua_vm(state.clone()).unwrap();
    (state, lua)
}

#[test]
fn test_lua_has_midi_soundfont_false() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        assert(luna.sound.hasMidiSoundFont() == false)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_clear_midi_soundfont() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        luna.sound.clearMidiSoundFont()
        assert(luna.sound.hasMidiSoundFont() == false)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_set_midi_soundfont_missing_file() {
    let (_state, lua) = make_vm();
    let result = lua
        .load(
            r#"
            luna.sound.setMidiSoundFont("nonexistent.sf2")
            "#,
        )
        .exec();
    assert!(result.is_err());
}
