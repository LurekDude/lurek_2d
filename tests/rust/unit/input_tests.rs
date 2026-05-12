//! INTERNAL ONLY: Rust-only tests for input state helpers that are not directly
//! asserted through `lurek.input.*`.
//!
//! Public keyboard, mouse, gamepad, touch, combo, and recording behavior is
//! covered by `tests/lua/unit/test_input_unit.lua`.

use lurek2d::input::recorder::{InputEvent, InputRecorder, InputRecording, RecordedFrame};
use lurek2d::input::*;

// ── touch ─────────────────────────────────────────────────────────────────────

mod touch_tests {
    use super::*;

    #[test]
    fn touch_start_adds_point() {
        let mut ts = TouchState::new();
        ts.touch_start(1, 100.0, 200.0, 0.5);
        assert_eq!(ts.get_touch_count(), 1);
        let tp = ts.get_touch(1).unwrap();
        assert_eq!(tp.id, 1);
        assert_eq!(tp.x, 100.0);
        assert_eq!(tp.y, 200.0);
        assert_eq!(tp.pressure, 0.5);
    }

    #[test]
    fn touch_move_updates_position() {
        let mut ts = TouchState::new();
        ts.touch_start(1, 0.0, 0.0, 1.0);
        ts.touch_move(1, 50.0, 75.0, 0.8);
        let tp = ts.get_touch(1).unwrap();
        assert_eq!(tp.x, 50.0);
        assert_eq!(tp.y, 75.0);
        assert_eq!(tp.pressure, 0.8);
    }

    #[test]
    fn touch_end_removes_point() {
        let mut ts = TouchState::new();
        ts.touch_start(1, 0.0, 0.0, 1.0);
        ts.touch_end(1);
        assert_eq!(ts.get_touch_count(), 0);
        assert!(ts.get_touch(1).is_none());
    }

    #[test]
    fn touch_frame_transitions() {
        let mut ts = TouchState::new();
        ts.touch_start(1, 10.0, 20.0, 1.0);
        assert!(ts.was_pressed(1));
        ts.begin_frame();
        assert!(!ts.was_pressed(1));
        ts.touch_end(1);
        assert!(ts.was_released(1));
    }

    #[test]
    fn move_nonexistent_touch_is_noop() {
        let mut ts = TouchState::new();
        ts.touch_move(99, 10.0, 20.0, 1.0);
        assert_eq!(ts.get_touch_count(), 0);
    }
}

// ── recorder ──────────────────────────────────────────────────────────────────

mod recorder_tests {
    use super::*;

    #[test]
    fn recording_roundtrip() {
        let mut rec = InputRecorder::new();
        assert!(!rec.is_recording());
        rec.start_recording();
        assert!(rec.is_recording());

        rec.record_frame(
            vec![InputEvent {
                kind: "down".into(),
                name: "space".into(),
            }],
            Some(100.0),
            Some(200.0),
        );
        rec.record_frame(vec![], None, None); // empty frame skipped
        rec.record_frame(
            vec![InputEvent {
                kind: "up".into(),
                name: "space".into(),
            }],
            None,
            None,
        );

        let recording = rec.stop_recording().unwrap();
        assert!(!rec.is_recording());
        assert_eq!(recording.total_frames, 3);
        assert_eq!(recording.frames.len(), 2); // empty frame was sparse-skipped
    }

    #[test]
    fn json_serialization() {
        let recording = InputRecording {
            frames: vec![RecordedFrame {
                frame: 0,
                key_events: vec![InputEvent {
                    kind: "down".into(),
                    name: "a".into(),
                }],
                mouse_x: None,
                mouse_y: None,
            }],
            total_frames: 1,
        };
        let json = recording.to_json().unwrap();
        assert!(json.contains("\"version\":1"));
        let parsed = InputRecording::from_json(&json).unwrap();
        assert_eq!(parsed, recording);
    }

    #[test]
    fn json_backward_compatible_without_version() {
        let legacy = r#"{"frames":[{"frame":0,"key_events":[{"kind":"down","name":"a"}],"mouse_x":null,"mouse_y":null}],"total_frames":1}"#;
        let parsed = InputRecording::from_json(legacy).unwrap();
        assert_eq!(parsed.total_frames, 1);
        assert_eq!(parsed.frames.len(), 1);
    }
}

// ── mouse ─────────────────────────────────────────────────────────────────────

mod mouse_tests {
    use super::*;

    #[test]
    fn update_position() {
        let mut ms = MouseState::new();
        ms.update_position(100.0, 200.0);
        assert_eq!(ms.get_position(), (100.0, 200.0));
    }

    #[test]
    fn button_press_and_release() {
        let mut ms = MouseState::new();
        ms.set_button(0, true);
        assert!(ms.is_down(0));
        assert!(ms.buttons_pressed[0]);
        ms.set_button(0, false);
        assert!(!ms.is_down(0));
        assert!(ms.buttons_released[0]);
    }

    #[test]
    fn begin_frame_clears_transients() {
        let mut ms = MouseState::new();
        ms.set_button(0, true);
        ms.accumulate_scroll(1.0, 2.0);
        ms.begin_frame();
        assert!(!ms.buttons_pressed[0]);
        assert_eq!(ms.get_scroll(), (0.0, 0.0));
        // Button is still held
        assert!(ms.is_down(0));
    }

    #[test]
    fn scroll_accumulates() {
        let mut ms = MouseState::new();
        ms.accumulate_scroll(1.0, 2.0);
        ms.accumulate_scroll(0.5, -1.0);
        assert_eq!(ms.get_scroll(), (1.5, 1.0));
    }

    #[test]
    fn cursor_type_roundtrip() {
        let ms = SystemCursor::from_name("hand");
        assert_eq!(ms.as_str(), "hand");
    }

    #[test]
    fn unknown_cursor_defaults_to_arrow() {
        let ms = SystemCursor::from_name("nonexistent");
        assert_eq!(ms, SystemCursor::Arrow);
    }

    #[test]
    fn out_of_range_button_ignored() {
        let mut ms = MouseState::new();
        ms.set_button(5, true); // index 5 is out of range
        assert!(!ms.is_down(5));
    }

    #[test]
    #[ignore = "take_pending_position is pub(crate)"]
    fn request_position_sets_pending() {
        // Ignored: take_pending_position() is pub(crate)
    }

    #[test]
    fn visibility_and_grab() {
        let mut ms = MouseState::new();
        ms.set_visible(false);
        assert!(!ms.is_visible());
        ms.set_grabbed(true);
        assert!(ms.is_grabbed());
    }
}

// ── keyboard ──────────────────────────────────────────────────────────────────

mod keyboard_tests {
    use super::*;

    // ── Initial state ─────────────────────────────────────────────────────────

    #[test]
    fn new_state_all_empty() {
        let kb = KeyboardState::new();
        assert!(!kb.is_down("a"));
        assert!(kb.get_pressed().is_empty());
        assert!(kb.get_released().is_empty());
    }

    // ── Key down / up ────────────────────────────────────────────────────────

    #[test]
    fn set_key_down_reports_pressed() {
        let mut kb = KeyboardState::new();
        kb.set_key_down("space");
        assert!(kb.is_down("space"));
        assert_eq!(kb.get_pressed(), &["space"]);
    }

    #[test]
    fn set_key_down_twice_not_double_pressed() {
        let mut kb = KeyboardState::new();
        kb.set_key_down("a");
        kb.set_key_down("a");
        assert_eq!(kb.get_pressed().len(), 1);
    }

    #[test]
    fn set_key_up_clears_down() {
        let mut kb = KeyboardState::new();
        kb.set_key_down("enter");
        kb.set_key_up("enter");
        assert!(!kb.is_down("enter"));
        assert_eq!(kb.get_released(), &["enter"]);
    }

    // ── Frame boundary ───────────────────────────────────────────────────────

    #[test]
    fn begin_frame_clears_transient_state() {
        let mut kb = KeyboardState::new();
        kb.set_key_down("a");
        kb.set_key_up("a");
        kb.begin_frame();
        assert!(kb.get_pressed().is_empty());
        assert!(kb.get_released().is_empty());
    }

    // ── Any down ──────────────────────────────────────────────────────────────

    #[test]
    fn is_any_down_returns_true_if_one_matches() {
        let mut kb = KeyboardState::new();
        kb.set_key_down("left");
        let keys = vec!["left".to_string(), "right".to_string()];
        assert!(kb.is_any_down(&keys));
    }

    #[test]
    fn is_any_down_false_when_none_pressed() {
        let kb = KeyboardState::new();
        let keys = vec!["left".to_string(), "right".to_string()];
        assert!(!kb.is_any_down(&keys));
    }

    // ── Modifiers ─────────────────────────────────────────────────────────────

    #[test]
    fn set_shift_modifier_reports_active() {
        let mut kb = KeyboardState::new();
        kb.set_modifiers(true, false, false, false);
        assert!(kb.is_modifier_active("shift"));
        assert!(!kb.is_modifier_active("ctrl"));
    }

    #[test]
    fn all_modifiers_active() {
        let mut kb = KeyboardState::new();
        kb.set_modifiers(true, true, true, true);
        assert!(kb.is_modifier_active("shift"));
        assert!(kb.is_modifier_active("ctrl"));
        assert!(kb.is_modifier_active("alt"));
        assert!(kb.is_modifier_active("meta"));
        assert!(kb.is_modifier_active("super")); // alias for meta
    }

    // ── Scancode press / release ─────────────────────────────────────────────

    #[test]
    #[ignore = "press_scancode and release_scancode are pub(crate)"]
    fn scancode_press_and_release() {
        // Ignored: press_scancode() and release_scancode() are pub(crate)
    }

    #[test]
    #[ignore = "press_scancode is pub(crate)"]
    fn scancode_duplicate_press_ignored() {
        // Ignored: press_scancode() is pub(crate)
    }

    // ── Text input ────────────────────────────────────────────────────────────

    #[test]
    #[ignore = "set_text_input and push_text_input are pub(crate)"]
    fn text_input_buffer_collects_and_clears() {
        // Ignored: set_text_input() and push_text_input() are pub(crate)
    }

    // ── Key repeat ────────────────────────────────────────────────────────────

    #[test]
    #[ignore = "set_key_repeat is pub(crate)"]
    fn key_repeat_toggle() {
        // Ignored: set_key_repeat() is pub(crate)
    }

    // ── Clear ─────────────────────────────────────────────────────────────────

    #[test]
    #[ignore = "press_scancode and push_text_input are pub(crate)"]
    fn clear_resets_all_state() {
        // Ignored: press_scancode() and push_text_input() are pub(crate)
    }
}

// ── gamepad ───────────────────────────────────────────────────────────────────

mod gamepad_tests {
    use super::*;

    #[test]
    fn new_gamepad_defaults() {
        let gs = GamepadState::new(0);
        assert_eq!(gs.id, 0);
        assert_eq!(gs.get_name(), "Unknown Controller");
        assert!(!gs.is_connected());
        assert!(!gs.is_vibration_supported());
    }

    #[test]
    fn button_update_and_query() {
        let mut gs = GamepadState::new(1);
        gs.update_button(0, true);
        assert!(gs.is_button_pressed(0));
        assert!(gs.was_button_pressed(0));
        assert!(!gs.is_button_pressed(1));
        gs.update_button(0, false);
        assert!(!gs.is_button_pressed(0));
        assert!(gs.was_button_released(0));
    }

    #[test]
    fn begin_frame_clears_button_transitions() {
        let mut gs = GamepadState::new(1);
        gs.update_button(0, true);
        assert!(gs.was_button_pressed(0));
        gs.begin_frame();
        assert!(!gs.was_button_pressed(0));
        assert!(!gs.was_button_released(0));
    }

    #[test]
    fn connection_transitions_are_tracked() {
        let mut gs = GamepadState::new(2);
        gs.set_connected(true);
        assert!(gs.was_connected_this_frame());
        gs.begin_frame();
        gs.set_connected(false);
        assert!(gs.was_disconnected_this_frame());
    }

    #[test]
    fn axis_update_and_query() {
        let mut gs = GamepadState::new(1);
        gs.update_axis(0, 0.75);
        assert!((gs.get_axis_value(0) - 0.75).abs() < 0.001);
        assert_eq!(gs.get_axis_value(99), 0.0);
    }

    #[test]
    fn button_and_axis_counts() {
        let mut gs = GamepadState::new(1);
        gs.update_button(0, true);
        gs.update_button(1, false);
        gs.update_axis(0, 0.5);
        assert_eq!(gs.get_button_count(), 2);
        assert_eq!(gs.get_axis_count(), 1);
    }

    #[test]
    #[ignore = "set_guid is pub(crate)"]
    fn guid_roundtrip() {
        // Ignored: set_guid() is pub(crate)
    }

    #[test]
    fn hat_directions() {
        let mut gs = GamepadState::new(1);
        assert_eq!(gs.get_hat(0), "c"); // no buttons
        gs.update_button(10, true); // up
        assert_eq!(gs.get_hat(0), "u");
        gs.update_button(13, true); // right
        assert_eq!(gs.get_hat(0), "ru");
        assert_eq!(gs.get_hat(1), "c"); // non-zero hat index always "c"
    }

    #[test]
    fn mappings_store_and_retrieve() {
        let mut m = GamepadMappings::new();
        m.set_mapping("abc123", "abc123,Xbox,a:b0,b:b1");
        assert_eq!(
            m.get_mapping_string("abc123"),
            Some("abc123,Xbox,a:b0,b:b1")
        );
        assert!(m.get_mapping_string("unknown").is_none());
    }

    #[test]
    fn mappings_load_from_string_skips_comments() {
        let mut m = GamepadMappings::new();
        let count = m.load_from_string(
            "# comment\n\n03000000123456780000000000000000,PadA,a:b0\n04000000123456780000000000000000,PadB,a:b1\n",
        );
        assert_eq!(count, 2);
        assert!(m
            .get_mapping_string("03000000123456780000000000000000")
            .is_some());
    }

    #[test]
    fn mappings_load_from_string_handles_adversarial_lines() {
        let mut m = GamepadMappings::new();
        for _ in 0..512 {
            let len = fastrand::usize(0..128);
            let mut line = String::with_capacity(len);
            for _ in 0..len {
                let c = match fastrand::u8(0..12) {
                    0 => '#',
                    1 => ',',
                    2 => ':',
                    3 => ';',
                    4 => '\\',
                    5 => '/',
                    6 => '.',
                    7 => '_',
                    8 => '-',
                    _ => (b'a' + fastrand::u8(0..26)) as char,
                };
                line.push(c);
            }
            // Should never panic for malformed input lines.
            let _ = m.load_from_string(&line);
        }
    }

    #[test]
    fn virtual_dpad_direction_and_edges() {
        let (up, down, left, right, dir) = virtual_dpad(0.0, 0.0, 0.3);
        assert!(!up && !down && !left && !right);
        assert_eq!(dir, "c");

        let (up, down, left, right, dir) = virtual_dpad(0.8, -0.8, 0.3);
        assert!(up && !down && !left && right);
        assert_eq!(dir, "ru");

        let (up, down, left, right, dir) = virtual_dpad(-0.9, 0.9, 0.25);
        assert!(!up && down && left && !right);
        assert_eq!(dir, "ld");
    }

    #[test]
    fn gilrs_button_to_string_known() {
        assert_eq!(gilrs_button_to_string(gilrs::Button::South), "a");
        assert_eq!(gilrs_button_to_string(gilrs::Button::Start), "start");
    }

    #[test]
    fn gilrs_axis_to_string_known() {
        assert_eq!(gilrs_axis_to_string(gilrs::Axis::LeftStickX), "leftx");
    }
}

// ── combo ─────────────────────────────────────────────────────────────────────

mod combo_tests {
    use super::*;

    fn make_steps() -> Vec<ComboStep> {
        vec![
            ComboStep {
                key: "down".into(),
                max_gap_ms: 500,
            },
            ComboStep {
                key: "right".into(),
                max_gap_ms: 500,
            },
            ComboStep {
                key: "a".into(),
                max_gap_ms: 500,
            },
        ]
    }

    #[test]
    fn empty_combo_is_idle() {
        let mut d = ComboDetector::new(vec![], 1000);
        assert!(d.is_empty());
        assert_eq!(d.feed("a", 0), ComboProgress::Idle);
    }

    #[test]
    fn disabled_returns_idle() {
        let mut d = ComboDetector::new(make_steps(), 2000);
        d.enabled = false;
        assert_eq!(d.feed("down", 0), ComboProgress::Idle);
    }
}
