mod automation_tests {
    use std::fs;
    use std::path::PathBuf;
    use std::time::Instant;
    use std::time::{SystemTime, UNIX_EPOCH};

    use lurek2d::automation::simulator::StepEventSink;
    use lurek2d::automation::{Action, Script, Simulator, Step};
    use lurek2d::event::Event;

    struct MockSink {
        events: Vec<Event>,
    }

    impl MockSink {
        fn new() -> Self {
            Self { events: Vec::new() }
        }
    }

    impl StepEventSink for MockSink {
        fn push_event(&mut self, event: Event) {
            self.events.push(event);
        }
    }

    fn temp_file(name: &str) -> PathBuf {
        let mut path = std::env::temp_dir();
        let stamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("time went backwards")
            .as_nanos();
        path.push(format!("lurek_automation_{stamp}_{name}"));
        path
    }

    #[test]
    fn test_action_roundtrip_includes_extended_actions() {
        let names = [
            "keypress",
            "keyrelease",
            "mousemove",
            "mousepress",
            "mouserelease",
            "mousewheel",
            "textinput",
            "wait",
            "repeat",
            "callmacro",
            "assert",
            "visualassert",
        ];

        for name in names {
            let action = Action::parse_action(name).expect("action should parse");
            assert_eq!(action.as_str(), name);
        }
    }

    #[test]
    fn test_script_new_expands_repeat_steps() {
        let mut step = Step::new(0.5, Action::KeyPress);
        step.key = Some("a".to_string());
        step.repeat = Some(2);
        step.repeat_interval = Some(0.25);

        let script = Script::new("repeat", vec![step]);
        assert_eq!(script.steps.len(), 3);
        assert!((script.steps[0].time - 0.5).abs() < f32::EPSILON);
        assert!((script.steps[1].time - 0.75).abs() < f32::EPSILON);
        assert!((script.steps[2].time - 1.0).abs() < f32::EPSILON);
    }

    #[test]
    fn test_script_from_toml_parses_extended_fields() {
        let toml = r#"
[[steps]]
action = "visualassert"
time = 1.0
baseline = "tests/output/base.png"
actual = "tests/output/actual.png"
maxDiff = 10
when = "ready"
assert = "ready"
repeat = 1
repeatInterval = 0.5

[[steps]]
action = "callmacro"
time = 2.0
macro = "combo"
"#;

        let script = Script::from_toml("extended", toml).expect("toml should parse");
        assert_eq!(script.steps.len(), 3);

        let first = &script.steps[0];
        assert_eq!(first.action, Action::VisualAssert);
        assert_eq!(first.baseline.as_deref(), Some("tests/output/base.png"));
        assert_eq!(first.actual.as_deref(), Some("tests/output/actual.png"));
        assert_eq!(first.max_diff, Some(10));
        assert_eq!(first.when.as_deref(), Some("ready"));
        assert_eq!(first.assert.as_deref(), Some("ready"));

        let last = script.steps.last().expect("has step");
        assert_eq!(last.action, Action::CallMacro);
        assert_eq!(last.macro_name.as_deref(), Some("combo"));
    }

    #[test]
    fn test_script_from_toml_parses_all_step_fields() {
        let toml = r#"
[meta]
description = "all fields"

[[steps]]
action = "keypress"
time = 0.25
key = "space"
scancode = "Space"
x = 11.0
y = 22.0
dx = 1.5
dy = -2.5
button = 2
text = "hello"
isRepeat = true
clicks = 3
repeat = 2
repeatInterval = 0.5
macro = "macro_x"
when = "ready && !paused"
assert = "ready && has_focus"
baseline = "a.png"
actual = "b.png"
maxDiff = 99
"#;

        let script = Script::from_toml("all", toml).expect("toml should parse");
        assert_eq!(script.description.as_deref(), Some("all fields"));
        assert_eq!(script.steps.len(), 3);

        let first = &script.steps[0];
        assert_eq!(first.action, Action::KeyPress);
        assert_eq!(first.time, 0.25);
        assert_eq!(first.key.as_deref(), Some("space"));
        assert_eq!(first.scancode.as_deref(), Some("Space"));
        assert_eq!(first.x, Some(11.0));
        assert_eq!(first.y, Some(22.0));
        assert_eq!(first.dx, Some(1.5));
        assert_eq!(first.dy, Some(-2.5));
        assert_eq!(first.button, Some(2));
        assert_eq!(first.text.as_deref(), Some("hello"));
        assert!(first.is_repeat);
        assert_eq!(first.clicks, Some(3));
        assert_eq!(first.macro_name.as_deref(), Some("macro_x"));
        assert_eq!(first.when.as_deref(), Some("ready && !paused"));
        assert_eq!(first.assert.as_deref(), Some("ready && has_focus"));
        assert_eq!(first.baseline.as_deref(), Some("a.png"));
        assert_eq!(first.actual.as_deref(), Some("b.png"));
        assert_eq!(first.max_diff, Some(99));
    }

    #[test]
    fn test_update_with_sink_dispatches_events_without_event_queue() {
        let mut sim = Simulator::new();
        let mut step = Step::new(0.0, Action::KeyPress);
        step.key = Some("space".to_string());
        sim.load(Script::new("s", vec![step]));
        sim.start("s").expect("script starts");

        let mut sink = MockSink::new();
        sim.update_with_sink(0.016, &mut sink);

        assert_eq!(sink.events.len(), 1);
        assert_eq!(sink.events[0].name, "keypressed");
        assert!(sim.is_complete());
    }

    #[test]
    fn test_set_condition_and_assert_action_failure() {
        let mut sim = Simulator::new();
        let mut assert_step = Step::new(0.0, Action::Assert);
        assert_step.assert = Some("hp_ok".to_string());

        sim.load(Script::new("assert", vec![assert_step]));
        sim.start("assert").expect("script starts");

        let mut sink = MockSink::new();
        sim.update_with_sink(0.016, &mut sink);

        assert!(sim.is_failed());
        assert!(sim.last_error().expect("failure message").contains("hp_ok"));
    }

    #[test]
    fn test_when_expression_controls_step_execution() {
        let mut sim = Simulator::new();

        let mut step = Step::new(0.0, Action::TextInput);
        step.text = Some("expr".to_string());
        step.when = Some("ready && !paused".to_string());

        sim.load(Script::new("expr_when", vec![step]));
        sim.start("expr_when").expect("script starts");

        let mut sink = MockSink::new();
        sim.set_condition("ready".to_string(), true);
        sim.set_condition("paused".to_string(), true);
        sim.update_with_sink(0.016, &mut sink);
        assert_eq!(sink.events.len(), 0);

        sim.stop();
        sim.start("expr_when").expect("script restarts");
        sim.set_condition("ready".to_string(), true);
        sim.set_condition("paused".to_string(), false);
        sim.update_with_sink(0.016, &mut sink);
        assert_eq!(sink.events.len(), 1);
    }

    #[test]
    fn test_assert_expression_failure_sets_failed_state() {
        let mut sim = Simulator::new();

        let mut step = Step::new(0.0, Action::Assert);
        step.assert = Some("ready && (boss_dead || phase2)".to_string());
        sim.load(Script::new("expr_assert", vec![step]));
        sim.start("expr_assert").expect("script starts");

        sim.set_condition("ready".to_string(), true);
        sim.set_condition("boss_dead".to_string(), false);
        sim.set_condition("phase2".to_string(), false);

        let mut sink = MockSink::new();
        sim.update_with_sink(0.016, &mut sink);

        assert!(sim.is_failed());
        assert!(sim
            .last_error()
            .expect("failure message")
            .contains("ready && (boss_dead || phase2)"));
    }

    #[test]
    fn test_invalid_expression_sets_failure() {
        let mut sim = Simulator::new();
        let mut step = Step::new(0.0, Action::Assert);
        step.assert = Some("ready && (phase2".to_string());

        sim.load(Script::new("expr_invalid", vec![step]));
        sim.start("expr_invalid").expect("script starts");
        sim.set_condition("ready".to_string(), true);

        let mut sink = MockSink::new();
        sim.update_with_sink(0.016, &mut sink);

        assert!(sim.is_failed());
        assert!(sim
            .last_error()
            .expect("failure message")
            .contains("expected ')'"));
    }

    #[test]
    fn test_callmacro_expands_and_runs_macro_steps() {
        let mut sim = Simulator::new();

        let mut macro_step = Step::new(0.0, Action::TextInput);
        macro_step.text = Some("ok".to_string());
        sim.save_macro(
            "macro_ok".to_string(),
            Script::new("macro_script", vec![macro_step]),
        );

        let mut call = Step::new(0.0, Action::CallMacro);
        call.macro_name = Some("macro_ok".to_string());
        sim.load(Script::new("main", vec![call]));
        sim.start("main").expect("script starts");

        let mut sink = MockSink::new();
        sim.update_with_sink(0.016, &mut sink);
        sim.update_with_sink(0.016, &mut sink);

        assert_eq!(sink.events.len(), 1);
        assert_eq!(sink.events[0].name, "textinput");
    }

    #[test]
    fn test_visualassert_passes_on_identical_images() {
        let baseline_path = temp_file("baseline.png");
        let actual_path = temp_file("actual.png");

        let img = ::image::RgbaImage::from_pixel(2, 2, ::image::Rgba([255, 0, 0, 255]));
        img.save(&baseline_path).expect("save baseline");
        img.save(&actual_path).expect("save actual");

        let mut step = Step::new(0.0, Action::VisualAssert);
        step.baseline = Some(baseline_path.to_string_lossy().to_string());
        step.actual = Some(actual_path.to_string_lossy().to_string());
        step.max_diff = Some(0);

        let mut sim = Simulator::new();
        sim.load(Script::new("visual", vec![step]));
        sim.start("visual").expect("script starts");

        let mut sink = MockSink::new();
        sim.update_with_sink(0.016, &mut sink);

        assert!(sim.is_complete());
        assert!(!sim.is_failed());

        let _ = fs::remove_file(&baseline_path);
        let _ = fs::remove_file(&actual_path);
    }

    #[test]
    fn test_deterministic_time_accumulation_reaches_exact_second() {
        let mut sim = Simulator::new();
        sim.load(Script::new("timed", vec![Step::new(1.0, Action::Wait)]));
        sim.start("timed").expect("script starts");

        let mut sink = MockSink::new();
        for _ in 0..10 {
            sim.update_with_sink(0.1, &mut sink);
        }

        assert!(sim.is_complete());
        assert!((sim.elapsed_time() - 1.0).abs() < 0.000_1);
    }

    #[test]
    fn test_update_overhead_10000_steps_stays_sub_millisecond_average() {
        let mut steps = Vec::with_capacity(10_000);
        for i in 0..10_000 {
            steps.push(Step::new(i as f32 * 0.000_2, Action::Wait));
        }

        let mut sim = Simulator::new();
        sim.load(Script::new("perf_10k", steps));
        sim.start("perf_10k").expect("script starts");

        let mut sink = MockSink::new();
        let frames = 5_000;
        let start = Instant::now();
        for _ in 0..frames {
            sim.update_with_sink(0.000_2, &mut sink);
        }
        let elapsed = start.elapsed().as_secs_f64();
        let avg_ms = (elapsed * 1_000.0) / frames as f64;

        assert!(
            avg_ms < 1.0,
            "average update() cost expected < 1ms, got {:.6}ms",
            avg_ms
        );
    }

    #[test]
    fn test_from_toml_profile_1000_steps_completes_quickly() {
        let mut toml = String::from("[meta]\ndescription = \"profile\"\n");
        for i in 0..1_000 {
            toml.push_str("\n[[steps]]\n");
            toml.push_str("action = \"wait\"\n");
            toml.push_str(&format!("time = {}\n", i as f64 * 0.001));
        }

        let start = Instant::now();
        let script = Script::from_toml("profile_1000", &toml).expect("toml should parse");
        let elapsed_ms = start.elapsed().as_secs_f64() * 1_000.0;

        assert_eq!(script.steps.len(), 1_000);
        assert!(
            elapsed_ms < 500.0,
            "from_toml profile unexpectedly slow: {:.3}ms",
            elapsed_ms
        );
    }
}
