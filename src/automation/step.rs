//! Action enum and Step record for automation script events.
//! Defines 12 Action variants with string-to-variant conversion and Step with 20 optional fields.
//! Consumed by Script (storage) and Simulator (event dispatch).

// ---- Type: Action ----

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
/// Synthetic input event kind injected into EventQueue by Simulator.
pub enum Action {
    /// Inject a keypressed event with key name and optional scancode.
    KeyPress,
    /// Inject a keyreleased event with key name and optional scancode.
    KeyRelease,
    /// Inject a mousemoved event with absolute position and movement delta.
    MouseMove,
    /// Inject a mousepressed event with position, button index, and click count.
    MousePress,
    /// Inject a mousereleased event with position and button index.
    MouseRelease,
    /// Inject a wheelmoved event with horizontal and vertical scroll deltas.
    MouseWheel,
    /// Inject a textinput event with a Unicode string payload.
    TextInput,
    /// Timed delay; no event is dispatched.
    Wait,
    /// Script-authoring marker for repeat expansion; no event dispatched.
    Repeat,
    /// Expand a named macro script's steps into the active timeline at this time offset.
    CallMacro,
    /// Fail playback when the step's assert expression evaluates to false.
    Assert,
    /// Fail playback when pixel diff between baseline and actual images exceeds max_diff.
    VisualAssert,
}

const ACTION_MAPPINGS: [(&str, Action); 12] = [
    ("keypress", Action::KeyPress),
    ("keyrelease", Action::KeyRelease),
    ("mousemove", Action::MouseMove),
    ("mousepress", Action::MousePress),
    ("mouserelease", Action::MouseRelease),
    ("mousewheel", Action::MouseWheel),
    ("textinput", Action::TextInput),
    ("wait", Action::Wait),
    ("repeat", Action::Repeat),
    ("callmacro", Action::CallMacro),
    ("assert", Action::Assert),
    ("visualassert", Action::VisualAssert),
];

// ---- Implementation: Action ----

impl Action {
    /// Parse a lowercase action string into the matching variant; return None for unrecognised input.
    pub fn parse_action(s: &str) -> Option<Action> {
        ACTION_MAPPINGS
            .iter()
            .find_map(|(name, action)| (*name == s).then_some(*action))
    }

    /// Return the canonical lowercase string for this variant; valid input to `parse_action`.
    pub fn as_str(&self) -> &'static str {
        ACTION_MAPPINGS
            .iter()
            .find_map(|(name, action)| (*action == *self).then_some(*name))
            .unwrap_or("wait")
    }
}

// ---- Type: Step ----

#[derive(Debug, Clone)]
/// Single timed event record in an automation Script with action-specific optional fields.
pub struct Step {
    /// Seconds from script start when Simulator dispatches this step; equal-time steps all fire in one update.
    pub time: f32,
    /// Action variant that determines which event is dispatched and which optional fields are read.
    pub action: Action,
    /// Key name for KeyPress/KeyRelease (e.g. `"space"`); used as scancode fallback when scancode is None.
    pub key: Option<String>,
    /// Scancode override for key events; supersedes key in `effective_scancode` when set.
    pub scancode: Option<String>,
    /// Mouse X screen coordinate for move/press/release; defaults to 0.0 when None.
    pub x: Option<f64>,
    /// Mouse Y screen coordinate for move/press/release; defaults to 0.0 when None.
    pub y: Option<f64>,
    /// Mouse X movement delta for mousemove; defaults to 0.0 when None.
    pub dx: Option<f64>,
    /// Mouse Y movement delta for mousemove; defaults to 0.0 when None.
    pub dy: Option<f64>,
    /// Mouse button index (1=left, 2=right, 3=middle) for press/release; defaults to 1 when None.
    pub button: Option<u32>,
    /// Unicode text payload for TextInput; dispatched event receives "" when None.
    pub text: Option<String>,
    /// Whether the keypressed event is a key-repeat; defaults to false.
    pub is_repeat: bool,
    /// Consecutive click count for MousePress; defaults to 1 when None.
    pub clicks: Option<u32>,
    /// Extra copies of this step generated during Script construction; 3 means 1 original + 3 copies.
    pub repeat: Option<u32>,
    /// Seconds between generated repeat copies; defaults to 0.0 when None.
    pub repeat_interval: Option<f32>,
    /// Macro name referenced by CallMacro steps.
    pub macro_name: Option<String>,
    /// Boolean expression gate; step is skipped when present and evaluates to false.
    pub when: Option<String>,
    /// Boolean expression assertion; playback fails when present and evaluates to false.
    pub assert: Option<String>,
    /// Baseline image path for VisualAssert.
    pub baseline: Option<String>,
    /// Actual image path for VisualAssert.
    pub actual: Option<String>,
    /// Maximum allowed pixel diff for VisualAssert.
    pub max_diff: Option<u32>,
}

// ---- Implementation: Step ----

impl Step {
    /// Create a Step with time and action set; all optional fields default to None, is_repeat to false.
    pub fn new(time: f32, action: Action) -> Self {
        Self {
            time,
            action,
            key: None,
            scancode: None,
            x: None,
            y: None,
            dx: None,
            dy: None,
            button: None,
            text: None,
            is_repeat: false,
            clicks: None,
            repeat: None,
            repeat_interval: None,
            macro_name: None,
            when: None,
            assert: None,
            baseline: None,
            actual: None,
            max_diff: None,
        }
    }

    /// Return scancode if set, else key; None only when both fields are None.
    pub fn effective_scancode(&self) -> Option<&str> {
        self.scancode.as_deref().or(self.key.as_deref())
    }
}

// Tests migrated to tests/rust/unit/automation_tests.rs
