//! Integration tests for the Luna2D audio system.

use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

use luna2d::audio::Bus;
use luna2d::audio::MidiPlayer;
use luna2d::audio::Mixer;
use luna2d::audio::PlayState;
use luna2d::audio::SourceType;
use luna2d::lua_api::{create_lua_vm, SharedState};

fn make_audio_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "Test",
        PathBuf::from("."),
    )));
    create_lua_vm(state).expect("Failed to create Lua VM")
}

fn assert_lua_error_contains(result: mlua::Result<()>, expected: &str) {
    let err = result.expect_err("expected Lua script to fail");
    let message = err.to_string();
    assert!(
        message.contains(expected),
        "expected Lua error to contain '{expected}', got '{message}'"
    );
}

#[test]
fn phase01_released_audio_handle_reuse_reports_invalid_source() {
    let lua = make_audio_vm();
    let result = lua
        .load(
            r#"
            local released = luna.audio.newSource("phase01-a.ogg", "static")
            assert(type(released) == "userdata")
            assert(luna.audio.release(released) == true)

            local replacement = luna.audio.newSource("phase01-b.ogg", "stream")
            assert(type(replacement) == "userdata")

            luna.audio.setVolume(released, 0.5)
            "#,
        )
        .exec();

    assert_lua_error_contains(
        result,
        "luna.audio.setVolume: invalid or already-released audio source handle",
    );
}

#[test]
fn mixer_load_source() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    let id2 = mixer.load_source("test2.ogg", SourceType::Stream);
    // Two distinct sources must get distinct keys.
    assert_ne!(id, id2);
}

#[test]
fn mixer_load_source_static() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    assert_eq!(mixer.get_source_type(id), Some(SourceType::Static));
}

#[test]
fn mixer_load_source_stream() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    assert_eq!(mixer.get_source_type(id), Some(SourceType::Stream));
}

#[test]
fn source_type_enum_values() {
    assert_ne!(SourceType::Static, SourceType::Stream);
    assert_eq!(SourceType::Static, SourceType::Static);
    assert_eq!(SourceType::Stream, SourceType::Stream);
}

#[test]
fn play_state_enum_values() {
    assert_ne!(PlayState::Stopped, PlayState::Playing);
    assert_ne!(PlayState::Playing, PlayState::Paused);
    assert_ne!(PlayState::Stopped, PlayState::Paused);
    assert_eq!(PlayState::Stopped, PlayState::Stopped);
}

#[test]
fn mixer_default_master_volume() {
    let mixer = Mixer::new();
    assert!((mixer.get_master_volume() - 1.0).abs() < 1e-5);
}

#[test]
fn mixer_set_master_volume() {
    let mut mixer = Mixer::new();
    mixer.set_master_volume(0.5);
    assert!((mixer.get_master_volume() - 0.5).abs() < 1e-5);
}

#[test]
fn mixer_master_volume_clamped() {
    let mut mixer = Mixer::new();
    mixer.set_master_volume(2.0);
    assert!((mixer.get_master_volume() - 1.0).abs() < 1e-5);
    mixer.set_master_volume(-0.5);
    assert!((mixer.get_master_volume() - 0.0).abs() < 1e-5);
}

#[test]
fn mixer_default_volume() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    assert!((mixer.get_volume(id) - 1.0).abs() < 1e-5);
}

#[test]
fn mixer_set_volume() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    mixer.set_volume(id, 0.5);
    assert!((mixer.get_volume(id) - 0.5).abs() < 1e-5);
}

#[test]
fn mixer_default_pitch() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    assert!((mixer.get_pitch(id) - 1.0).abs() < 1e-5);
}

#[test]
fn mixer_set_pitch() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    mixer.set_pitch(id, 2.0);
    assert!((mixer.get_pitch(id) - 2.0).abs() < 1e-5);
}

#[test]
fn mixer_pitch_clamped() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    mixer.set_pitch(id, 10.0);
    assert!((mixer.get_pitch(id) - 4.0).abs() < 1e-5);
    mixer.set_pitch(id, 0.01);
    assert!((mixer.get_pitch(id) - 0.1).abs() < 1e-5);
}

#[test]
fn mixer_default_pan() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    assert!((mixer.get_pan(id) - 0.0).abs() < 1e-5);
}

#[test]
fn mixer_set_pan() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    mixer.set_pan(id, -0.5);
    assert!((mixer.get_pan(id) - (-0.5)).abs() < 1e-5);
    mixer.set_pan(id, 0.8);
    assert!((mixer.get_pan(id) - 0.8).abs() < 1e-5);
}

#[test]
fn mixer_pan_clamped() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    mixer.set_pan(id, -2.0);
    assert!((mixer.get_pan(id) - (-1.0)).abs() < 1e-5);
    mixer.set_pan(id, 5.0);
    assert!((mixer.get_pan(id) - 1.0).abs() < 1e-5);
}

#[test]
fn mixer_looping_default_false() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    assert!(!mixer.is_looping(id));
}

#[test]
fn mixer_set_looping() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    mixer.set_looping(id, true);
    assert!(mixer.is_looping(id));
    mixer.set_looping(id, false);
    assert!(!mixer.is_looping(id));
}

#[test]
fn mixer_source_count() {
    let mut mixer = Mixer::new();
    assert_eq!(mixer.get_source_count(), 0);
    let id1 = mixer.load_source("a.wav", SourceType::Stream);
    assert_eq!(mixer.get_source_count(), 1);
    let _id2 = mixer.load_source("b.wav", SourceType::Static);
    assert_eq!(mixer.get_source_count(), 2);
    mixer.release(id1);
    assert_eq!(mixer.get_source_count(), 1);
}

#[test]
fn mixer_active_source_count_no_playback() {
    let mut mixer = Mixer::new();
    let _id = mixer.load_source("test.wav", SourceType::Stream);
    // No playback started, active count should be 0
    assert_eq!(mixer.get_active_source_count(), 0);
}

#[test]
fn mixer_clone_source() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    mixer.set_volume(id, 0.7);
    mixer.set_pitch(id, 1.5);
    mixer.set_pan(id, -0.3);
    mixer.set_looping(id, true);

    let cloned = mixer.clone_source(id).expect("clone should succeed");
    assert_ne!(id, cloned);
    assert!((mixer.get_volume(cloned) - 0.7).abs() < 1e-5);
    assert!((mixer.get_pitch(cloned) - 1.5).abs() < 1e-5);
    assert!((mixer.get_pan(cloned) - (-0.3)).abs() < 1e-5);
    assert!(mixer.is_looping(cloned));
    assert_eq!(mixer.get_source_type(cloned), Some(SourceType::Static));
    // Clone should be stopped
    assert!(mixer.is_stopped(cloned));
}

#[test]
fn mixer_clone_invalid_key() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    mixer.release(id);
    assert!(mixer.clone_source(id).is_none());
}

#[test]
fn mixer_default_play_state_stopped() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    assert_eq!(mixer.get_play_state(id), PlayState::Stopped);
    assert!(mixer.is_stopped(id));
    assert!(!mixer.is_playing(id));
    assert!(!mixer.is_paused(id));
}

#[test]
fn mixer_release_returns_false_for_invalid() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    assert!(mixer.release(id));
    assert!(!mixer.release(id));
}

#[test]
fn mixer_stop_all_no_sources() {
    let mut mixer = Mixer::new();
    // Should not panic with no sources
    mixer.stop_all();
}

#[test]
fn mixer_pause_all_no_sources() {
    let mut mixer = Mixer::new();
    // Should not panic with no sources
    mixer.pause_all();
}

#[test]
fn mixer_resume_all_no_sources() {
    let mut mixer = Mixer::new();
    // Should not panic with no sources
    mixer.resume_all();
}

#[test]
fn mixer_set_speed_alias() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    mixer.set_speed(id, 2.0);
    assert!((mixer.get_pitch(id) - 2.0).abs() < 1e-5);
}

#[test]
fn mixer_source_type_none_for_invalid() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    mixer.release(id);
    assert_eq!(mixer.get_source_type(id), None);
}

// ===========================================================================
// Bus Tests
// ===========================================================================

#[test]
fn bus_default_values() {
    let bus = Bus::new("music");
    assert_eq!(bus.name(), "music");
    assert!((bus.volume() - 1.0).abs() < 1e-5);
    assert!((bus.pitch() - 1.0).abs() < 1e-5);
    assert!(!bus.is_paused());
}

#[test]
fn bus_volume_clamp() {
    let mut bus = Bus::new("test");
    bus.set_volume(-1.0);
    assert!((bus.volume() - 0.0).abs() < 1e-5);
    bus.set_volume(0.5);
    assert!((bus.volume() - 0.5).abs() < 1e-5);
    bus.set_volume(2.0);
    assert!((bus.volume() - 2.0).abs() < 1e-5); // No upper clamp
}

#[test]
fn bus_pitch_clamp() {
    let mut bus = Bus::new("test");
    bus.set_pitch(-0.5);
    assert!((bus.pitch() - 0.0).abs() < 1e-5);
    bus.set_pitch(1.5);
    assert!((bus.pitch() - 1.5).abs() < 1e-5);
}

#[test]
fn bus_pause_resume() {
    let mut bus = Bus::new("test");
    assert!(!bus.is_paused());
    bus.pause();
    assert!(bus.is_paused());
    bus.resume();
    assert!(!bus.is_paused());
}

#[test]
fn mixer_new_bus() {
    let mut mixer = Mixer::new();
    let key = mixer.new_bus("music");
    let bus = mixer.get_bus(key).unwrap();
    assert_eq!(bus.name(), "music");
    assert!((bus.volume() - 1.0).abs() < 1e-5);
}

#[test]
fn mixer_get_bus_mut() {
    let mut mixer = Mixer::new();
    let key = mixer.new_bus("sfx");
    mixer.get_bus_mut(key).unwrap().set_volume(0.5);
    assert!((mixer.get_bus(key).unwrap().volume() - 0.5).abs() < 1e-5);
}

#[test]
fn mixer_set_source_bus() {
    let mut mixer = Mixer::new();
    let src = mixer.load_source("test.wav", SourceType::Stream);
    let bus = mixer.new_bus("music");

    assert!(mixer.get_source_bus(src).is_none());
    mixer.set_source_bus(src, Some(bus));
    assert_eq!(mixer.get_source_bus(src), Some(bus));
    mixer.set_source_bus(src, None);
    assert!(mixer.get_source_bus(src).is_none());
}

#[test]
fn mixer_clone_preserves_bus() {
    let mut mixer = Mixer::new();
    let src = mixer.load_source("test.wav", SourceType::Stream);
    let bus = mixer.new_bus("music");
    mixer.set_source_bus(src, Some(bus));

    let cloned = mixer.clone_source(src).unwrap();
    assert_eq!(mixer.get_source_bus(cloned), Some(bus));
}

// ===========================================================================
// MidiPlayer Tests
// ===========================================================================

#[test]
fn midi_player_default_values() {
    let mp = MidiPlayer::new();
    assert!(!mp.is_loaded());
    assert!(!mp.is_playing());
    assert!(!mp.is_paused());
    assert!((mp.volume() - 1.0).abs() < 1e-5);
    assert!((mp.tempo_scale() - 1.0).abs() < 1e-5);
    assert!(!mp.is_looping());
    assert_eq!(mp.track_count(), 0);
    assert_eq!(mp.note_count(), 0);
    assert_eq!(mp.channel_count(), 0);
    assert!((mp.duration() - 0.0).abs() < 1e-5);
    assert!((mp.tell() - 0.0).abs() < 1e-5);
    assert!(mp.file_path().is_none());
    assert!(mp.bus_key().is_none());
}

#[test]
fn midi_player_volume() {
    let mut mp = MidiPlayer::new();
    mp.set_volume(0.7);
    assert!((mp.volume() - 0.7).abs() < 1e-5);
    mp.set_volume(-1.0);
    assert!((mp.volume() - 0.0).abs() < 1e-5);
}

#[test]
fn midi_player_tempo_scale() {
    let mut mp = MidiPlayer::new();
    mp.set_tempo_scale(2.0);
    assert!((mp.tempo_scale() - 2.0).abs() < 1e-5);
    mp.set_tempo_scale(0.001);
    assert!(mp.tempo_scale() >= 0.01);
}

#[test]
fn midi_player_looping() {
    let mut mp = MidiPlayer::new();
    assert!(!mp.is_looping());
    mp.set_looping(true);
    assert!(mp.is_looping());
    mp.set_looping(false);
    assert!(!mp.is_looping());
}

#[test]
fn midi_player_channel_mute() {
    let mut mp = MidiPlayer::new();
    assert!(!mp.is_channel_muted(0));
    mp.set_channel_muted(0, true);
    assert!(mp.is_channel_muted(0));
    mp.set_channel_muted(0, false);
    assert!(!mp.is_channel_muted(0));
}

#[test]
fn midi_player_channel_volume() {
    let mut mp = MidiPlayer::new();
    assert!((mp.channel_volume(0) - 1.0).abs() < 1e-5);
    mp.set_channel_volume(0, 0.5);
    assert!((mp.channel_volume(0) - 0.5).abs() < 1e-5);
}

#[test]
fn midi_player_channel_instrument() {
    let mut mp = MidiPlayer::new();
    assert_eq!(mp.channel_instrument(0), 0);
    mp.set_channel_instrument(0, 42);
    assert_eq!(mp.channel_instrument(0), 42);
}

#[test]
fn midi_player_solo_channel() {
    let mut mp = MidiPlayer::new();
    mp.solo_channel(5);
    for i in 0..16 {
        if i == 5 {
            assert!(!mp.is_channel_muted(i));
        } else {
            assert!(mp.is_channel_muted(i));
        }
    }
    mp.unsolo_all();
    for i in 0..16 {
        assert!(!mp.is_channel_muted(i));
    }
}

#[test]
fn midi_player_out_of_range_channel() {
    let mut mp = MidiPlayer::new();
    // Out of range operations should not panic
    mp.set_channel_volume(16, 0.5);
    assert!((mp.channel_volume(16) - 0.0).abs() < 1e-5);
    mp.set_channel_muted(16, true);
    assert!(!mp.is_channel_muted(16));
    mp.set_channel_instrument(16, 42);
    assert_eq!(mp.channel_instrument(16), 0);
}

#[test]
fn midi_player_seek() {
    let mut mp = MidiPlayer::new();
    mp.seek(5.0);
    assert!((mp.tell() - 5.0).abs() < 1e-5);
    mp.seek(-1.0);
    assert!((mp.tell() - 0.0).abs() < 1e-5);
}

#[test]
fn midi_player_stop_resets_position() {
    let mut mp = MidiPlayer::new();
    mp.seek(10.0);
    mp.stop();
    assert!((mp.tell() - 0.0).abs() < 1e-5);
    assert_eq!(mp.play_state(), PlayState::Stopped);
}

#[test]
fn midi_player_load_nonexistent() {
    let mut mp = MidiPlayer::new();
    let result = mp.load(std::path::Path::new("nonexistent.mid"));
    assert!(!result);
    assert!(!mp.is_loaded());
}

#[test]
fn midi_player_load_invalid_data() {
    let mut mp = MidiPlayer::new();
    let result = mp.load_data(vec![0, 1, 2, 3]);
    assert!(!result);
    assert!(!mp.is_loaded());
}

#[test]
fn midi_player_default_impl() {
    let mp = MidiPlayer::default();
    assert!(!mp.is_loaded());
    assert!((mp.volume() - 1.0).abs() < 1e-5);
}

// ===========================================================================
// T03: getDuration Tests
// ===========================================================================

#[test]
fn mixer_get_duration_none_before_play() {
    // A freshly loaded source has no cached duration (file not yet opened).
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    assert!(
        mixer.get_duration(id).is_none(),
        "duration should be None before first play"
    );
}

#[test]
fn mixer_get_duration_none_for_invalid_key() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    mixer.release(id);
    // Released key returns None from get_duration
    assert!(mixer.get_duration(id).is_none());
}

#[test]
fn mixer_get_duration_stream_none_before_play() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("nonexistent_stream.ogg", SourceType::Stream);
    assert!(mixer.get_duration(id).is_none());
}

// ===========================================================================
// T04: tell Tests
// ===========================================================================

#[test]
fn mixer_tell_stopped_is_zero() {
    // A loaded-but-never-played source has tell == 0.0.
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    assert!(
        (mixer.get_tell(id) - 0.0).abs() < 1e-5,
        "tell should be 0.0 for stopped source"
    );
}

#[test]
fn mixer_tell_invalid_key_is_zero() {
    // get_tell on an invalid/released key returns 0.0 without panicking.
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    mixer.release(id);
    assert!((mixer.get_tell(id) - 0.0).abs() < 1e-5);
}

#[test]
fn mixer_tell_paused_returns_accumulated() {
    // After stop(), accumulated resets to 0.
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    // Without an audio device, play() is a no-op, but stop() should reset timing.
    mixer.stop(id);
    assert!((mixer.get_tell(id) - 0.0).abs() < 1e-5);
}

#[test]
fn mixer_tell_after_stop_is_zero() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    // stop() always resets accumulated_secs.
    mixer.stop(id);
    assert!((mixer.get_tell(id) - 0.0).abs() < 1e-5);
}

// ===========================================================================
// T05: seek Tests
// ===========================================================================

#[test]
fn audio_seek_invalid_id_is_noop_via_lua() {
    // seek on a non-existent source should return a runtime error, not panic.
    use luna2d::lua_api::{create_lua_vm, SharedState};
    use std::cell::RefCell;
    use std::path::PathBuf;
    use std::rc::Rc;

    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "Test",
        PathBuf::from("."),
    )));
    let lua = create_lua_vm(state).expect("Lua VM");

    // seek on handle 0 (invalid) should produce a runtime error, not a panic.
    let _ = lua.load(r#"luna.audio.seek(0, 0.0)"#).exec();
}

// ===========================================================================
// T06: Pan Tests
// ===========================================================================

#[test]
fn mixer_pan_default_center() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    assert!((mixer.get_pan(id) - 0.0).abs() < 1e-5);
}

#[test]
fn mixer_pan_stored_and_retrieved_positive() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    mixer.set_pan(id, 0.75);
    assert!((mixer.get_pan(id) - 0.75).abs() < 1e-5);
}

#[test]
fn mixer_pan_stored_and_retrieved_negative() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    mixer.set_pan(id, -0.5);
    assert!((mixer.get_pan(id) - (-0.5)).abs() < 1e-5);
}

#[test]
fn mixer_pan_clamped_max() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    mixer.set_pan(id, 2.0);
    assert!((mixer.get_pan(id) - 1.0).abs() < 1e-5);
}

#[test]
fn mixer_pan_clamped_min() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    mixer.set_pan(id, -2.0);
    assert!((mixer.get_pan(id) - (-1.0)).abs() < 1e-5);
}

// ===========================================================================
// T07: seek
// ===========================================================================

#[test]
fn mixer_seek_noop_on_missing_key() {
    // seek on a released key should be a no-op (no panic).
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Stream);
    mixer.release(id);
    mixer.seek(id, 5.0, std::path::Path::new("."));
}

#[test]
fn mixer_seek_stopped_tell_unchanged() {
    // seek on a stopped source (no audio device) keeps tell() at 0.0.
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    // No audio device — play() is a no-op; source stays Stopped.
    // Seek on Stopped with no device: accumulated_secs set but play_state stays Stopped.
    mixer.seek(id, 3.5, std::path::Path::new("."));
    // get_tell returns 0.0 for Stopped state.
    assert!((mixer.get_tell(id) - 0.0).abs() < 1e-5);
}

// ===========================================================================
// T08: Lowpass
// ===========================================================================

#[test]
fn mixer_lowpass_none_by_default() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    assert!(mixer.get_lowpass(id).is_none());
}

#[test]
fn mixer_lowpass_stored_and_retrieved() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    mixer.set_lowpass(id, 4000);
    assert_eq!(mixer.get_lowpass(id), Some(4000));
}

#[test]
fn mixer_clear_lowpass() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    mixer.set_lowpass(id, 4000);
    mixer.clear_lowpass(id);
    assert!(mixer.get_lowpass(id).is_none());
}

// ===========================================================================
// T09: Highpass
// ===========================================================================

#[test]
fn mixer_highpass_none_by_default() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    assert!(mixer.get_highpass(id).is_none());
}

#[test]
fn mixer_highpass_stored_and_retrieved() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    mixer.set_highpass(id, 800);
    assert_eq!(mixer.get_highpass(id), Some(800));
}

#[test]
fn mixer_clear_highpass() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    mixer.set_highpass(id, 800);
    mixer.clear_highpass(id);
    assert!(mixer.get_highpass(id).is_none());
}

// ===========================================================================
// T10: clearFilter
// ===========================================================================

#[test]
fn mixer_clear_filter_clears_both() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    mixer.set_lowpass(id, 4000);
    mixer.set_highpass(id, 800);
    mixer.clear_filter(id);
    assert!(mixer.get_lowpass(id).is_none());
    assert!(mixer.get_highpass(id).is_none());
}

// ===========================================================================
// T11: Fade-In
// ===========================================================================

#[test]
fn mixer_fade_in_none_by_default() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    assert!(mixer.get_fade_in(id).is_none());
}

#[test]
fn mixer_fade_in_stored_and_retrieved() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    mixer.set_fade_in(id, 2.5);
    let dur = mixer.get_fade_in(id).expect("fade_in should be Some");
    assert!((dur - 2.5).abs() < 1e-5);
}

#[test]
fn mixer_clear_fade_in() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    mixer.set_fade_in(id, 1.0);
    mixer.clear_fade_in(id);
    assert!(mixer.get_fade_in(id).is_none());
}

#[test]
fn mixer_fade_in_clamped_to_zero() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    mixer.set_fade_in(id, -3.0);
    let dur = mixer.get_fade_in(id).expect("fade_in should be Some");
    assert!((dur - 0.0).abs() < 1e-5);
}

// ===========================================================================
// T12: clone_source copies effect fields
// ===========================================================================

#[test]
fn mixer_clone_copies_effect_fields() {
    let mut mixer = Mixer::new();
    let id = mixer.load_source("test.wav", SourceType::Static);
    mixer.set_lowpass(id, 3000);
    mixer.set_highpass(id, 500);
    mixer.set_fade_in(id, 1.5);
    let clone_id = mixer.clone_source(id).expect("clone should succeed");
    assert_eq!(mixer.get_lowpass(clone_id), Some(3000));
    assert_eq!(mixer.get_highpass(clone_id), Some(500));
    let fade = mixer
        .get_fade_in(clone_id)
        .expect("clone fade_in should be Some");
    assert!((fade - 1.5).abs() < 1e-5);
}

#[test]
fn audio_listener_position_defaults_to_origin() {
    let mixer = Mixer::new();
    let pos = mixer.get_listener_position();
    assert!((pos[0]).abs() < 1e-5);
    assert!((pos[1]).abs() < 1e-5);
    assert!((pos[2]).abs() < 1e-5);
}

#[test]
fn audio_set_listener_position_round_trips() {
    let mut mixer = Mixer::new();
    mixer.set_listener_position(10.0, 20.0, 5.0);
    let pos = mixer.get_listener_position();
    assert!((pos[0] - 10.0).abs() < 1e-5);
    assert!((pos[1] - 20.0).abs() < 1e-5);
    assert!((pos[2] - 5.0).abs() < 1e-5);
}

#[test]
fn audio_doppler_scale_defaults_to_one() {
    let mixer = Mixer::new();
    assert!((mixer.get_doppler_scale() - 1.0).abs() < 1e-5);
}

#[test]
fn audio_set_doppler_scale_round_trips() {
    let mut mixer = Mixer::new();
    mixer.set_doppler_scale(2.5);
    assert!((mixer.get_doppler_scale() - 2.5).abs() < 1e-5);
}

#[test]
fn audio_doppler_scale_clamped_to_zero() {
    let mut mixer = Mixer::new();
    mixer.set_doppler_scale(-1.0);
    assert!((mixer.get_doppler_scale() - 0.0).abs() < 1e-5);
}

#[test]
fn audio_distance_model_default_is_inverse_clamped() {
    let mixer = Mixer::new();
    assert_eq!(mixer.get_distance_model(), "inverse_clamped");
}

#[test]
fn audio_set_distance_model_round_trips() {
    let mut mixer = Mixer::new();
    mixer.set_distance_model("linear");
    assert_eq!(mixer.get_distance_model(), "linear");
}

#[test]
fn audio_source_position_defaults_to_origin() {
    let mut mixer = Mixer::new();
    let key = mixer.load_source("test.wav", SourceType::Static);
    let pos = mixer.get_source_position(key);
    assert!((pos[0]).abs() < 1e-5);
    assert!((pos[1]).abs() < 1e-5);
    assert!((pos[2]).abs() < 1e-5);
}

#[test]
fn audio_set_source_position_round_trips() {
    let mut mixer = Mixer::new();
    let key = mixer.load_source("test.wav", SourceType::Static);
    mixer.set_source_position(key, 100.0, 50.0, 0.0);
    let pos = mixer.get_source_position(key);
    assert!((pos[0] - 100.0).abs() < 1e-5);
    assert!((pos[1] - 50.0).abs() < 1e-5);
}

#[test]
fn audio_set_source_velocity_round_trips() {
    let mut mixer = Mixer::new();
    let key = mixer.load_source("test.wav", SourceType::Static);
    mixer.set_source_velocity(key, 3.0, 4.0, 0.0);
    let vel = mixer.get_source_velocity(key);
    assert!((vel[0] - 3.0).abs() < 1e-5);
    assert!((vel[1] - 4.0).abs() < 1e-5);
}

#[test]
fn audio_set_source_orientation_round_trips() {
    let mut mixer = Mixer::new();
    let key = mixer.load_source("test.wav", SourceType::Static);
    mixer.set_source_orientation(key, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0);
    let o = mixer.get_source_orientation(key);
    assert!((o[0] - 1.0).abs() < 1e-5);
    assert!((o[3]).abs() < 1e-5);
    assert!((o[4] - 1.0).abs() < 1e-5);
}

#[test]
fn decoder_loads_wav_fixture() {
    let d = luna2d::audio::Decoder::from_file(
        "tests/fixtures/sine_mono_44100.wav",
        1024,
    )
    .unwrap();
    assert_eq!(d.sample_rate, 44100);
    assert_eq!(d.channels, 1);
}

#[test]
fn decoder_decode_returns_chunk() {
    let mut d = luna2d::audio::Decoder::from_file(
        "tests/fixtures/sine_mono_44100.wav",
        512,
    )
    .unwrap();
    let chunk = d.decode();
    assert!(chunk.is_some());
    let c = chunk.unwrap();
    assert!(c.len() <= 512);
}

#[test]
fn decoder_decode_returns_none_at_eof() {
    let mut d = luna2d::audio::Decoder::from_file(
        "tests/fixtures/sine_mono_44100.wav",
        100_000,
    )
    .unwrap();
    let _ = d.decode(); // consume all
    let eof = d.decode();
    assert!(eof.is_none());
}

#[test]
fn decoder_rewind_resets_position() {
    let mut d = luna2d::audio::Decoder::from_file(
        "tests/fixtures/sine_mono_44100.wav",
        100_000,
    )
    .unwrap();
    let _ = d.decode();
    d.rewind();
    let after_rewind = d.decode();
    assert!(after_rewind.is_some());
}

#[test]
fn decoder_get_duration_positive() {
    let d = luna2d::audio::Decoder::from_file(
        "tests/fixtures/sine_mono_44100.wav",
        1024,
    )
    .unwrap();
    assert!(d.get_duration() > 0.0);
}

#[test]
fn decoder_channel_count_mono_is_1() {
    let d = luna2d::audio::Decoder::from_file(
        "tests/fixtures/sine_mono_44100.wav",
        1024,
    )
    .unwrap();
    assert_eq!(d.channels, 1);
}

#[test]
fn decoder_sample_rate_returns_positive() {
    let d = luna2d::audio::Decoder::from_file(
        "tests/fixtures/sine_mono_44100.wav",
        1024,
    )
    .unwrap();
    assert!(d.sample_rate > 0);
}

#[test]
fn decoder_bit_depth_returns_positive() {
    let d = luna2d::audio::Decoder::from_file(
        "tests/fixtures/sine_mono_44100.wav",
        1024,
    )
    .unwrap();
    assert!(d.bit_depth > 0);
}

#[test]
fn decoder_tell_starts_at_zero() {
    let d = luna2d::audio::Decoder::from_file(
        "tests/fixtures/sine_mono_44100.wav",
        1024,
    )
    .unwrap();
    assert!((d.tell() - 0.0).abs() < 1e-6);
}

#[test]
fn decoder_tell_advances_after_decode() {
    let mut d = luna2d::audio::Decoder::from_file(
        "tests/fixtures/sine_mono_44100.wav",
        1024,
    )
    .unwrap();
    let _ = d.decode();
    assert!(d.tell() > 0.0);
}

#[test]
fn decoder_is_seekable_always_true() {
    let d = luna2d::audio::Decoder::from_file(
        "tests/fixtures/sine_mono_44100.wav",
        1024,
    )
    .unwrap();
    assert!(d.is_seekable());
}

#[test]
fn decoder_seek_then_tell_round_trips() {
    let mut d = luna2d::audio::Decoder::from_file(
        "tests/fixtures/sine_mono_44100.wav",
        1024,
    )
    .unwrap();
    let target = 0.01;
    d.seek(target);
    assert!((d.tell() - target).abs() < 0.001);
}

// ── Phase 15 — QueueableSource ────────────────────────────────────────────────

#[test]
fn queueable_source_new_has_full_free_buffers() {
    let mut mixer = Mixer::new();
    let key = mixer.new_queueable(44100, 16, 1, 4);
    assert_eq!(mixer.queueable_free_buffer_count(key), 4);
}

#[test]
fn queueable_source_queue_reduces_free_count() {
    let mut mixer = Mixer::new();
    let key = mixer.new_queueable(44100, 16, 1, 4);
    let pcm = vec![0.0f32; 128];
    mixer.queue_buffer(key, &pcm).expect("queue_buffer should succeed");
    assert_eq!(mixer.queueable_free_buffer_count(key), 3);
}

#[test]
fn queueable_source_free_buffer_count_max() {
    let mut mixer = Mixer::new();
    let key = mixer.new_queueable(44100, 16, 2, 8);
    assert_eq!(mixer.queueable_free_buffer_count(key), 8);
}

#[test]
fn queueable_source_queue_full_returns_error() {
    let mut mixer = Mixer::new();
    let key = mixer.new_queueable(44100, 16, 1, 2);
    let pcm = vec![0.0f32; 64];
    mixer.queue_buffer(key, &pcm).expect("first queue should succeed");
    mixer.queue_buffer(key, &pcm).expect("second queue should succeed");
    let err = mixer.queue_buffer(key, &pcm);
    assert!(err.is_err(), "queueing beyond capacity must return an error");
}

#[test]
fn queueable_source_stop_drains_buffers() {
    let mut mixer = Mixer::new();
    let key = mixer.new_queueable(44100, 16, 1, 4);
    let pcm = vec![0.0f32; 16];
    mixer.queue_buffer(key, &pcm).unwrap();
    mixer.queue_buffer(key, &pcm).unwrap();
    mixer.stop_queueable(key);
    assert_eq!(mixer.queueable_free_buffer_count(key), 4);
}

// ── Phase 18 — Playback Device Selection ─────────────────────────────────────

#[test]
fn audio_get_playback_devices_returns_at_least_one() {
    let devs = luna2d::audio::get_playback_devices();
    assert!(!devs.is_empty(), "must return at least one device");
}

#[test]
fn audio_get_playback_device_returns_string() {
    let name = luna2d::audio::get_playback_device();
    assert!(!name.is_empty(), "device name must not be empty");
}

#[test]
fn audio_set_playback_device_default_ok() {
    luna2d::audio::set_playback_device("Default").expect("setting Default device should succeed");
}

#[test]
fn audio_set_playback_device_unknown_errors() {
    let result = luna2d::audio::set_playback_device("NonExistentDevice___XYZ");
    assert!(result.is_err(), "unknown device name should return an error");
}
