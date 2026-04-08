//! Integration tests for the automation simulation module.

use luna2d::automation::{Action, Script, Simulator, Step};
use luna2d::event::EventQueue;

// ── Action tests ──────────────────────────────────────────────────────

#[test]
fn action_from_str_keypress() {
    assert_eq!(Action::parse_action("keypress"), Some(Action::KeyPress));
}

#[test]
fn action_from_str_keyrelease() {
    assert_eq!(Action::parse_action("keyrelease"), Some(Action::KeyRelease));
}

#[test]
fn action_from_str_mousemove() {
    assert_eq!(Action::parse_action("mousemove"), Some(Action::MouseMove));
}

#[test]
fn action_from_str_mousepress() {
    assert_eq!(Action::parse_action("mousepress"), Some(Action::MousePress));
}

#[test]
fn action_from_str_mouserelease() {
    assert_eq!(
        Action::parse_action("mouserelease"),
        Some(Action::MouseRelease)
    );
}

#[test]
fn action_from_str_mousewheel() {
    assert_eq!(Action::parse_action("mousewheel"), Some(Action::MouseWheel));
}

#[test]
fn action_from_str_textinput() {
    assert_eq!(Action::parse_action("textinput"), Some(Action::TextInput));
}

#[test]
fn action_from_str_wait() {
    assert_eq!(Action::parse_action("wait"), Some(Action::Wait));
}

#[test]
fn action_from_str_unknown_returns_none() {
    assert_eq!(Action::parse_action("invalid"), None);
    assert_eq!(Action::parse_action(""), None);
    assert_eq!(Action::parse_action("KEYPRESS"), None);
}

#[test]
fn action_as_str_roundtrip() {
    let actions = [
        Action::KeyPress,
        Action::KeyRelease,
        Action::MouseMove,
        Action::MousePress,
        Action::MouseRelease,
        Action::MouseWheel,
        Action::TextInput,
        Action::Wait,
    ];
    for action in &actions {
        let s = action.as_str();
        let parsed = Action::parse_action(s).unwrap();
        assert_eq!(&parsed, action);
    }
}

// ── Step tests ────────────────────────────────────────────────────────

#[test]
fn step_new_defaults() {
    let step = Step::new(1.5, Action::KeyPress);
    assert!((step.time - 1.5).abs() < 1e-5);
    assert_eq!(step.action, Action::KeyPress);
    assert!(step.key.is_none());
    assert!(step.scancode.is_none());
    assert!(step.x.is_none());
    assert!(step.y.is_none());
    assert!(step.dx.is_none());
    assert!(step.dy.is_none());
    assert!(step.button.is_none());
    assert!(step.text.is_none());
    assert!(!step.is_repeat);
    assert!(step.clicks.is_none());
}

#[test]
fn step_effective_scancode_uses_scancode() {
    let mut step = Step::new(0.0, Action::KeyPress);
    step.key = Some("a".to_string());
    step.scancode = Some("sc_a".to_string());
    assert_eq!(step.effective_scancode(), Some("sc_a"));
}

#[test]
fn step_effective_scancode_falls_back_to_key() {
    let mut step = Step::new(0.0, Action::KeyPress);
    step.key = Some("space".to_string());
    assert_eq!(step.effective_scancode(), Some("space"));
}

#[test]
fn step_effective_scancode_none_when_both_unset() {
    let step = Step::new(0.0, Action::KeyPress);
    assert_eq!(step.effective_scancode(), None);
}

// ── Script tests ──────────────────────────────────────────────────────

#[test]
fn script_new_sorts_by_time() {
    let steps = vec![
        Step::new(2.0, Action::Wait),
        Step::new(0.5, Action::KeyPress),
        Step::new(1.0, Action::MouseMove),
    ];
    let script = Script::new("test", steps);
    assert!((script.steps[0].time - 0.5).abs() < 1e-5);
    assert!((script.steps[1].time - 1.0).abs() < 1e-5);
    assert!((script.steps[2].time - 2.0).abs() < 1e-5);
}

#[test]
fn script_step_count() {
    let steps = vec![Step::new(0.0, Action::Wait), Step::new(1.0, Action::Wait)];
    let script = Script::new("test", steps);
    assert_eq!(script.step_count(), 2);
}

#[test]
fn script_empty_steps() {
    let script = Script::new("empty", vec![]);
    assert_eq!(script.step_count(), 0);
    assert_eq!(script.name, "empty");
}

#[test]
fn script_with_description() {
    let script = Script::with_description("test", "A test script", vec![]);
    assert_eq!(script.description, Some("A test script".to_string()));
}

#[test]
fn script_new_has_no_description() {
    let script = Script::new("test", vec![]);
    assert!(script.description.is_none());
}

// ── Simulator creation ───────────────────────────────────────────────

#[test]
fn simulator_new_is_idle() {
    let sim = Simulator::new();
    assert!(!sim.is_running());
    assert!(!sim.is_paused());
    assert!(!sim.is_complete());
    assert_eq!(sim.current_step(), 0);
    assert_eq!(sim.step_count(), 0);
    assert!(sim.current_script().is_none());
    assert!((sim.elapsed_time()).abs() < 1e-5);
}

// ── Script management ────────────────────────────────────────────────

#[test]
fn simulator_load_and_has_script() {
    let mut sim = Simulator::new();
    let script = Script::new("test", vec![Step::new(0.0, Action::Wait)]);
    sim.load(script);
    assert!(sim.has_script("test"));
    assert!(!sim.has_script("other"));
}

#[test]
fn simulator_load_replaces_existing() {
    let mut sim = Simulator::new();
    let script1 = Script::new("test", vec![Step::new(0.0, Action::Wait)]);
    let script2 = Script::new(
        "test",
        vec![Step::new(0.0, Action::Wait), Step::new(1.0, Action::Wait)],
    );
    sim.load(script1);
    sim.load(script2);
    assert!(sim.has_script("test"));
    // Start to check the new step count
    sim.start("test").unwrap();
    assert_eq!(sim.step_count(), 2);
}

#[test]
fn simulator_unload_returns_true() {
    let mut sim = Simulator::new();
    sim.load(Script::new("test", vec![]));
    assert!(sim.unload("test"));
    assert!(!sim.has_script("test"));
}

#[test]
fn simulator_unload_nonexistent_returns_false() {
    let mut sim = Simulator::new();
    assert!(!sim.unload("nonexistent"));
}

#[test]
fn simulator_unload_active_stops_playback() {
    let mut sim = Simulator::new();
    sim.load(Script::new("test", vec![Step::new(1.0, Action::Wait)]));
    sim.start("test").unwrap();
    assert!(sim.is_running());
    sim.unload("test");
    assert!(!sim.is_running());
}

#[test]
fn simulator_get_scripts_empty() {
    let sim = Simulator::new();
    assert!(sim.get_scripts().is_empty());
}

#[test]
fn simulator_get_scripts_returns_names() {
    let mut sim = Simulator::new();
    sim.load(Script::new("alpha", vec![]));
    sim.load(Script::new("beta", vec![]));
    let mut names = sim.get_scripts();
    names.sort();
    assert_eq!(names, vec!["alpha", "beta"]);
}

// ── Playback control ─────────────────────────────────────────────────

#[test]
fn simulator_start_running() {
    let mut sim = Simulator::new();
    sim.load(Script::new("test", vec![Step::new(0.0, Action::Wait)]));
    sim.start("test").unwrap();
    assert!(sim.is_running());
    assert_eq!(sim.current_script(), Some("test"));
}

#[test]
fn simulator_start_nonexistent_errors() {
    let mut sim = Simulator::new();
    assert!(sim.start("nonexistent").is_err());
}

#[test]
fn simulator_stop_resets() {
    let mut sim = Simulator::new();
    sim.load(Script::new("test", vec![Step::new(1.0, Action::Wait)]));
    sim.start("test").unwrap();
    sim.stop();
    assert!(!sim.is_running());
    assert!(sim.current_script().is_none());
    assert_eq!(sim.current_step(), 0);
    assert!((sim.elapsed_time()).abs() < 1e-5);
}

#[test]
fn simulator_pause_resume() {
    let mut sim = Simulator::new();
    sim.load(Script::new("test", vec![Step::new(1.0, Action::Wait)]));
    sim.start("test").unwrap();

    sim.pause();
    assert!(sim.is_paused());
    assert!(!sim.is_running());

    sim.resume();
    assert!(sim.is_running());
    assert!(!sim.is_paused());
}

#[test]
fn simulator_pause_when_idle_noop() {
    let mut sim = Simulator::new();
    sim.pause();
    assert!(!sim.is_paused());
}

#[test]
fn simulator_resume_when_not_paused_noop() {
    let mut sim = Simulator::new();
    sim.load(Script::new("test", vec![Step::new(1.0, Action::Wait)]));
    sim.start("test").unwrap();
    sim.resume(); // already running
    assert!(sim.is_running());
}

// ── Update and event dispatch ────────────────────────────────────────

#[test]
fn simulator_update_dispatches_keypress() {
    let mut sim = Simulator::new();
    let mut step = Step::new(0.0, Action::KeyPress);
    step.key = Some("space".to_string());
    sim.load(Script::new("test", vec![step]));
    sim.start("test").unwrap();

    let mut eq = EventQueue::new();
    sim.update(0.1, &mut eq);

    let event = eq.poll().unwrap();
    assert_eq!(event.name, "keypressed");
    assert_eq!(event.args.len(), 3);
}

#[test]
fn simulator_update_dispatches_keyrelease() {
    let mut sim = Simulator::new();
    let mut step = Step::new(0.0, Action::KeyRelease);
    step.key = Some("escape".to_string());
    sim.load(Script::new("test", vec![step]));
    sim.start("test").unwrap();

    let mut eq = EventQueue::new();
    sim.update(0.1, &mut eq);

    let event = eq.poll().unwrap();
    assert_eq!(event.name, "keyreleased");
    assert_eq!(event.args.len(), 2);
}

#[test]
fn simulator_update_dispatches_mousemove() {
    let mut sim = Simulator::new();
    let mut step = Step::new(0.0, Action::MouseMove);
    step.x = Some(100.0);
    step.y = Some(200.0);
    step.dx = Some(5.0);
    step.dy = Some(-3.0);
    sim.load(Script::new("test", vec![step]));
    sim.start("test").unwrap();

    let mut eq = EventQueue::new();
    sim.update(0.1, &mut eq);

    let event = eq.poll().unwrap();
    assert_eq!(event.name, "mousemoved");
    assert_eq!(event.args.len(), 4);
}

#[test]
fn simulator_update_dispatches_mousepress() {
    let mut sim = Simulator::new();
    let mut step = Step::new(0.0, Action::MousePress);
    step.x = Some(50.0);
    step.y = Some(75.0);
    step.button = Some(1);
    step.clicks = Some(2);
    sim.load(Script::new("test", vec![step]));
    sim.start("test").unwrap();

    let mut eq = EventQueue::new();
    sim.update(0.1, &mut eq);

    let event = eq.poll().unwrap();
    assert_eq!(event.name, "mousepressed");
    assert_eq!(event.args.len(), 5);
}

#[test]
fn simulator_update_dispatches_mouserelease() {
    let mut sim = Simulator::new();
    let mut step = Step::new(0.0, Action::MouseRelease);
    step.x = Some(50.0);
    step.y = Some(75.0);
    step.button = Some(2);
    sim.load(Script::new("test", vec![step]));
    sim.start("test").unwrap();

    let mut eq = EventQueue::new();
    sim.update(0.1, &mut eq);

    let event = eq.poll().unwrap();
    assert_eq!(event.name, "mousereleased");
    assert_eq!(event.args.len(), 3);
}

#[test]
fn simulator_update_dispatches_mousewheel() {
    let mut sim = Simulator::new();
    let mut step = Step::new(0.0, Action::MouseWheel);
    step.x = Some(0.0);
    step.y = Some(3.0);
    sim.load(Script::new("test", vec![step]));
    sim.start("test").unwrap();

    let mut eq = EventQueue::new();
    sim.update(0.1, &mut eq);

    let event = eq.poll().unwrap();
    assert_eq!(event.name, "wheelmoved");
    assert_eq!(event.args.len(), 2);
}

#[test]
fn simulator_update_dispatches_textinput() {
    let mut sim = Simulator::new();
    let mut step = Step::new(0.0, Action::TextInput);
    step.text = Some("hello".to_string());
    sim.load(Script::new("test", vec![step]));
    sim.start("test").unwrap();

    let mut eq = EventQueue::new();
    sim.update(0.1, &mut eq);

    let event = eq.poll().unwrap();
    assert_eq!(event.name, "textinput");
    assert_eq!(event.args.len(), 1);
}

#[test]
fn simulator_update_wait_no_event() {
    let mut sim = Simulator::new();
    sim.load(Script::new("test", vec![Step::new(0.0, Action::Wait)]));
    sim.start("test").unwrap();

    let mut eq = EventQueue::new();
    sim.update(0.1, &mut eq);

    assert!(eq.poll().is_none());
}

#[test]
fn simulator_update_respects_timing() {
    let mut sim = Simulator::new();
    let mut step1 = Step::new(0.5, Action::KeyPress);
    step1.key = Some("a".to_string());
    let mut step2 = Step::new(1.5, Action::KeyPress);
    step2.key = Some("b".to_string());
    sim.load(Script::new("test", vec![step1, step2]));
    sim.start("test").unwrap();

    let mut eq = EventQueue::new();

    // At t=0.3, no steps should fire
    sim.update(0.3, &mut eq);
    assert!(eq.poll().is_none());
    assert_eq!(sim.current_step(), 0);

    // At t=0.8, step1 (t=0.5) should fire
    sim.update(0.5, &mut eq);
    let event = eq.poll().unwrap();
    assert_eq!(event.name, "keypressed");
    assert!(eq.poll().is_none());
    assert_eq!(sim.current_step(), 1);

    // At t=1.8, step2 (t=1.5) should fire
    sim.update(1.0, &mut eq);
    let event = eq.poll().unwrap();
    assert_eq!(event.name, "keypressed");
    assert!(eq.poll().is_none());
    assert!(sim.is_complete());
}

#[test]
fn simulator_update_does_nothing_when_idle() {
    let mut sim = Simulator::new();
    let mut eq = EventQueue::new();
    sim.update(1.0, &mut eq);
    assert!(eq.is_empty());
}

#[test]
fn simulator_update_does_nothing_when_paused() {
    let mut sim = Simulator::new();
    let mut step = Step::new(0.0, Action::KeyPress);
    step.key = Some("a".to_string());
    sim.load(Script::new("test", vec![step]));
    sim.start("test").unwrap();
    sim.pause();

    let mut eq = EventQueue::new();
    sim.update(1.0, &mut eq);
    assert!(eq.is_empty());
}

#[test]
fn simulator_update_does_nothing_when_complete() {
    let mut sim = Simulator::new();
    sim.load(Script::new("test", vec![Step::new(0.0, Action::Wait)]));
    sim.start("test").unwrap();

    let mut eq = EventQueue::new();
    sim.update(0.1, &mut eq);
    assert!(sim.is_complete());

    // Further updates should not dispatch anything
    sim.update(0.1, &mut eq);
    assert!(eq.is_empty());
}

#[test]
fn simulator_multiple_steps_same_frame() {
    let mut sim = Simulator::new();
    let mut step1 = Step::new(0.1, Action::KeyPress);
    step1.key = Some("a".to_string());
    let mut step2 = Step::new(0.2, Action::KeyPress);
    step2.key = Some("b".to_string());
    let mut step3 = Step::new(0.3, Action::KeyPress);
    step3.key = Some("c".to_string());
    sim.load(Script::new("test", vec![step1, step2, step3]));
    sim.start("test").unwrap();

    let mut eq = EventQueue::new();
    // One big update that covers all steps
    sim.update(1.0, &mut eq);

    // All 3 events should be dispatched
    assert_eq!(eq.len(), 3);
    assert!(sim.is_complete());
}

#[test]
fn simulator_elapsed_time_accumulates() {
    let mut sim = Simulator::new();
    sim.load(Script::new("test", vec![Step::new(10.0, Action::Wait)]));
    sim.start("test").unwrap();

    let mut eq = EventQueue::new();
    sim.update(0.5, &mut eq);
    assert!((sim.elapsed_time() - 0.5).abs() < 1e-5);

    sim.update(0.3, &mut eq);
    assert!((sim.elapsed_time() - 0.8).abs() < 1e-5);
}

#[test]
fn simulator_step_count_reflects_active_script() {
    let mut sim = Simulator::new();
    sim.load(Script::new(
        "test",
        vec![
            Step::new(0.0, Action::Wait),
            Step::new(1.0, Action::Wait),
            Step::new(2.0, Action::Wait),
        ],
    ));

    // No active script
    assert_eq!(sim.step_count(), 0);

    sim.start("test").unwrap();
    assert_eq!(sim.step_count(), 3);
}

#[test]
fn simulator_default_trait() {
    let sim = Simulator::default();
    assert!(!sim.is_running());
}

// ── Script::from_toml tests ───────────────────────────────────────────

#[test]
fn script_from_toml_minimal_steps() {
    let toml = r#"
        [[steps]]
        action = "keypress"
        time = 0.1
    "#;
    let script = Script::from_toml("test", toml).unwrap();
    assert_eq!(script.name, "test");
    assert_eq!(script.step_count(), 1);
    assert!(script.description.is_none());
}

#[test]
fn script_from_toml_with_meta() {
    let toml = r#"
        [meta]
        description = "My script"
        [[steps]]
        action = "mousemove"
        x = 1.0
        y = 2.0
    "#;
    let script = Script::from_toml("s", toml).unwrap();
    assert_eq!(script.description, Some("My script".to_string()));
    assert_eq!(script.step_count(), 1);
}

#[test]
fn script_from_toml_invalid_toml_returns_error() {
    let result = Script::from_toml("x", "not { valid toml ===");
    assert!(result.is_err());
}

#[test]
fn script_from_toml_unknown_action_returns_error() {
    let toml = "[[steps]]\naction = \"notanaction\"\n";
    let result = Script::from_toml("x", toml);
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("unknown action"));
}

#[test]
fn script_from_toml_missing_action_returns_error() {
    let toml = "[[steps]]\ntime = 0.5\n";
    let result = Script::from_toml("x", toml);
    assert!(result.is_err());
}

#[test]
fn script_from_toml_empty_steps_creates_empty_script() {
    let toml = "[meta]\ndescription = \"empty\"\n";
    let script = Script::from_toml("empty", toml).unwrap();
    assert_eq!(script.step_count(), 0);
}
