#[derive(Debug, Clone, Copy, PartialEq, Eq)]
/// Input event kind dispatched by a `Step` during automation playback.
pub enum Action {
    /// Fires a key-pressed event with key name and scancode.
    KeyPress,
    /// Fires a key-released event with key name and scancode.
    KeyRelease,
    /// Fires a mouse-moved event with absolute position and delta.
    MouseMove,
    /// Fires a mouse-button-pressed event at the given position.
    MousePress,
    /// Fires a mouse-button-released event at the given position.
    MouseRelease,
    /// Fires a mouse-wheel-moved event with scroll delta x/y.
    MouseWheel,
    /// Fires a text-input event carrying a UTF-8 string payload.
    TextInput,
    /// No-op; holds the time cursor until the next step fires.
    Wait,
    /// Sentinel produced by `expand_repeats`; not dispatched as an event.
    Repeat,
    /// Inlines a named macro `Script` at the current step position.
    CallMacro,
    /// Evaluates a condition expression; fails the script if false.
    Assert,
    /// Compares two image files pixel-by-pixel within `max_diff` tolerance.
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
impl Action {
    /// Parse a lowercase action string (e.g. "keypress") and return the matching `Action`, or `None`.
    pub fn parse_action(s: &str) -> Option<Action> {
        ACTION_MAPPINGS
            .iter()
            .find_map(|(name, action)| (*name == s).then_some(*action))
    }
    /// Return the canonical lowercase string key for this variant; defaults to "wait" if not found.
    pub fn as_str(&self) -> &'static str {
        ACTION_MAPPINGS
            .iter()
            .find_map(|(name, action)| (*action == *self).then_some(*name))
            .unwrap_or("wait")
    }
}
#[derive(Debug, Clone)]
/// One timed input event in an automation `Script`; carries all optional field payloads.
pub struct Step {
    /// Playback timestamp in seconds at which this step fires.
    pub time: f32,
    /// Input event kind dispatched when this step fires.
    pub action: Action,
    /// Key name string (e.g. "a", "space") for `KeyPress`/`KeyRelease` steps.
    pub key: Option<String>,
    /// Scancode string; `effective_scancode` falls back to `key` when absent.
    pub scancode: Option<String>,
    /// Cursor or wheel absolute X coordinate in game-space pixels.
    pub x: Option<f64>,
    /// Cursor or wheel absolute Y coordinate in game-space pixels.
    pub y: Option<f64>,
    /// Mouse-move delta X since the previous position.
    pub dx: Option<f64>,
    /// Mouse-move delta Y since the previous position.
    pub dy: Option<f64>,
    /// Mouse button index (1 = left, 2 = right, 3 = middle) for press/release steps.
    pub button: Option<u32>,
    /// UTF-8 text payload for `TextInput` steps.
    pub text: Option<String>,
    /// True when the key event is a keyboard auto-repeat hold.
    pub is_repeat: bool,
    /// Click count for `MousePress` (e.g. 2 for a double-click).
    pub clicks: Option<u32>,
    /// How many additional clones `expand_repeats` generates from this step.
    pub repeat: Option<u32>,
    /// Seconds between each repeated clone inserted by `expand_repeats`.
    pub repeat_interval: Option<f32>,
    /// Macro name to inline for `CallMacro` steps.
    pub macro_name: Option<String>,
    /// Condition expression; the step is skipped if it evaluates to false.
    pub when: Option<String>,
    /// Condition expression; the script fails with an error if it evaluates to false.
    pub assert: Option<String>,
    /// Path to the baseline reference image for `VisualAssert` steps.
    pub baseline: Option<String>,
    /// Path to the actual rendered image compared against `baseline` in `VisualAssert`.
    pub actual: Option<String>,
    /// Maximum allowed total pixel-channel difference for `VisualAssert` to pass.
    pub max_diff: Option<u32>,
}
impl Step {
    /// Create a `Step` at `time` seconds with the given `action`; all optional fields default to `None`.
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
    /// Return `scancode` if set, otherwise fall back to `key`; `None` when both are absent.
    pub fn effective_scancode(&self) -> Option<&str> {
        self.scancode.as_deref().or(self.key.as_deref())
    }
}
