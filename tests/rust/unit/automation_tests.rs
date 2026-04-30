//! Smoke tests for the automation module against the current public API.

use lurek2d::automation::{Action, Script, Step};

mod step_tests {
    use super::*;

    #[test]
    fn parse_action_known_variants() {
        assert_eq!(Action::parse_action("keypress"), Some(Action::KeyPress));
        assert_eq!(Action::parse_action("keyrelease"), Some(Action::KeyRelease));
        assert_eq!(Action::parse_action("mousemove"), Some(Action::MouseMove));
        assert_eq!(Action::parse_action("mousepress"), Some(Action::MousePress));
        assert_eq!(
            Action::parse_action("mouserelease"),
            Some(Action::MouseRelease)
        );
        assert_eq!(Action::parse_action("mousewheel"), Some(Action::MouseWheel));
        assert_eq!(Action::parse_action("textinput"), Some(Action::TextInput));
        assert_eq!(Action::parse_action("wait"), Some(Action::Wait));
    }

    #[test]
    fn step_new_defaults() {
        let s = Step::new(1.5, Action::Wait);
        assert!((s.time - 1.5).abs() < f32::EPSILON);
        assert_eq!(s.action, Action::Wait);
        assert!(s.key.is_none());
        assert!(!s.is_repeat);
    }

    #[test]
    fn effective_scancode_prefers_scancode() {
        let mut s = Step::new(0.0, Action::KeyPress);
        s.key = Some("a".into());
        s.scancode = Some("KeyA".into());
        assert_eq!(s.effective_scancode(), Some("KeyA"));
    }
}

mod script_tests {
    use super::*;

    fn make_steps(n: usize) -> Vec<Step> {
        (0..n)
            .map(|i| Step::new(i as f32 * 0.1, Action::Wait))
            .collect()
    }

    #[test]
    fn new_script_properties() {
        let s = Script::new("demo", make_steps(3));
        assert_eq!(s.name, "demo");
        assert_eq!(s.step_count(), 3);
        assert!(s.description.is_none());
    }

    #[test]
    fn with_description() {
        let s = Script::with_description("d", "A demo", make_steps(1));
        assert_eq!(s.description.as_deref(), Some("A demo"));
    }
}
