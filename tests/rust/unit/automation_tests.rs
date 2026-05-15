//! INTERNAL ONLY: public `lurek.automation.*` behavior is covered by the Lua-first suite in
//! `tests/lua/unit/test_automation_core_unit.lua`.
//!
//! The remaining Rust coverage keeps exact enum/parser mappings, direct `StepEventSink`
//! dispatch without the engine `EventQueue`, and performance-oriented checks that are not
//! precise or stable enough to own from the Lua layer.

mod automation_tests {
    use std::time::Instant;

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
