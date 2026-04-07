//! Step definitions for the automation simulation module.
//!
//! This module provides the [`Action`] enum and [`Step`] struct that form the
//! building blocks of a simulation script. A `Step` pairs a wall-clock offset
//! (seconds from script start) with an action type and optional action-specific
//! parameters such as key name, mouse coordinates, button index, and text.
//!
//! Steps are created programmatically and collected into a [`Script`](super::Script)
//! to be played back by the [`Simulator`](super::Simulator).

use mlua::prelude::*;

/// The action type for a simulation step.
///
/// Each variant maps to a synthetic input event that the
/// [`Simulator`](super::Simulator) injects into the engine's
/// [`EventQueue`](crate::event::EventQueue) during playback. Injected events
/// are indistinguishable from real hardware input as far as the game is
/// concerned.
///
/// Use [`Action::parse_action`] to convert a Lua string such as `"keypress"`
/// into the corresponding variant, and [`Action::as_str`] for the reverse.
///
/// # Variants
/// - `KeyPress` — Simulate a key press event (`"keypressed"` dispatch).
/// - `KeyRelease` — Simulate a key release event (`"keyreleased"` dispatch).
/// - `MouseMove` — Simulate mouse movement (`"mousemoved"` dispatch).
/// - `MousePress` — Simulate a mouse button press (`"mousepressed"` dispatch).
/// - `MouseRelease` — Simulate a mouse button release (`"mousereleased"` dispatch).
/// - `MouseWheel` — Simulate a mouse wheel scroll (`"wheelmoved"` dispatch).
/// - `TextInput` — Simulate raw text input (`"textinput"` dispatch).
/// - `Wait` — No-op pause; just a timed delay with no event dispatched.
#[derive(Debug, Clone, PartialEq)]
pub enum Action {
    /// Simulate a key press event (`"keypressed"` dispatch).
    ///
    /// Requires a `key` field on the step. Uses `scancode` if set; otherwise
    /// falls back to `key`. The `is_repeat` flag controls the repeat argument.
    KeyPress,
    /// Simulate a key release event (`"keyreleased"` dispatch).
    ///
    /// Requires a `key` field on the step. Uses `scancode` if set; otherwise
    /// falls back to `key`.
    KeyRelease,
    /// Simulate mouse movement to an absolute position (`"mousemoved"` dispatch).
    ///
    /// Uses `x` and `y` for the new cursor position, `dx` and `dy` for the
    /// movement delta since the last event. All default to `0.0` if unset.
    MouseMove,
    /// Simulate a mouse button press (`"mousepressed"` dispatch).
    ///
    /// Uses `x`/`y` for position, `button` for the button index (1 = left,
    /// 2 = right, 3 = middle), and `clicks` for the click count. Defaults:
    /// position `(0, 0)`, button `1`, clicks `1`.
    MousePress,
    /// Simulate a mouse button release (`"mousereleased"` dispatch).
    ///
    /// Uses `x`/`y` for position and `button` for the button index. Defaults:
    /// position `(0, 0)`, button `1`.
    MouseRelease,
    /// Simulate a mouse wheel scroll event (`"wheelmoved"` dispatch).
    ///
    /// Uses `x` for horizontal scroll delta and `y` for vertical scroll delta.
    /// Both default to `0.0` if unset. Positive `y` conventionally scrolls up.
    MouseWheel,
    /// Simulate raw text input (`"textinput"` dispatch).
    ///
    /// Uses the `text` field as the input string. May contain any Unicode
    /// text. Dispatches an empty string if `text` is `None`.
    TextInput,
    /// No-op timed delay.
    ///
    /// No event is dispatched. A `Wait` step exists only to introduce a pause
    /// in the playback sequence — useful for ensuring a specific elapsed-time
    /// gap between surrounding steps.
    Wait,
}

impl Action {
    /// Parse an action string into the corresponding variant.
    ///
    /// Accepts lowercase strings matching the Lua API convention:
    /// `"keypress"`, `"keyrelease"`, `"mousemove"`, `"mousepress"`,
    /// `"mouserelease"`, `"mousewheel"`, `"textinput"`, `"wait"`.
    ///
    /// Returns `None` for any unrecognised string. The match is case-sensitive;
    /// `"KeyPress"` and `"KEYPRESS"` are not accepted.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Option<Action>`.
    pub fn parse_action(s: &str) -> Option<Action> {
        match s {
            "keypress" => Some(Action::KeyPress),
            "keyrelease" => Some(Action::KeyRelease),
            "mousemove" => Some(Action::MouseMove),
            "mousepress" => Some(Action::MousePress),
            "mouserelease" => Some(Action::MouseRelease),
            "mousewheel" => Some(Action::MouseWheel),
            "textinput" => Some(Action::TextInput),
            "wait" => Some(Action::Wait),
            _ => None,
        }
    }

    /// Return the canonical lowercase string representation of this action.
    ///
    /// The returned value is always a valid input to [`Action::parse_action`],
    /// making round-trips lossless. This is the string that appears in TOML
    /// script files and Lua step tables.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn as_str(&self) -> &'static str {
        match self {
            Action::KeyPress => "keypress",
            Action::KeyRelease => "keyrelease",
            Action::MouseMove => "mousemove",
            Action::MousePress => "mousepress",
            Action::MouseRelease => "mouserelease",
            Action::MouseWheel => "mousewheel",
            Action::TextInput => "textinput",
            Action::Wait => "wait",
        }
    }
}

/// A single timed step in a simulation script.
///
/// Each step records a wall-clock offset from script start (`time`) and an
/// [`Action`] to perform, along with action-specific optional fields. Only
/// `time` and `action` are required; all other fields default to `None` and
/// are read only when relevant to the chosen action type.
///
/// Steps are ordinarily declared in Lua via `luna.simulator.load`, but can
/// also be constructed in Rust integration tests using [`Step::new`] plus
/// direct field assignment.
///
/// ## Field usage by action
///
/// | Action | Used fields | Defaults when `None` |
/// |---|---|---|
/// | `keypress` / `keyrelease` | `key`, `scancode`, `is_repeat` | scancode = key, is_repeat = false |
/// | `mousemove` | `x`, `y`, `dx`, `dy` | all `0.0` |
/// | `mousepress` | `x`, `y`, `button`, `clicks` | pos `(0,0)`, btn `1`, clicks `1` |
/// | `mouserelease` | `x`, `y`, `button` | pos `(0,0)`, btn `1` |
/// | `mousewheel` | `x`, `y` (scroll deltas) | both `0.0` |
/// | `textinput` | `text` | `""` |
/// | `wait` | — | — |
///
/// # Fields
/// - `time` — `f32`.
/// - `action` — `Action`.
/// - `key` — `Option<String>`.
/// - `scancode` — `Option<String>`.
/// - `x` — `Option<f64>`.
/// - `y` — `Option<f64>`.
/// - `dx` — `Option<f64>`.
/// - `dy` — `Option<f64>`.
/// - `button` — `Option<u32>`.
/// - `text` — `Option<String>`.
/// - `is_repeat` — `bool`.
/// - `clicks` — `Option<u32>`.
#[derive(Debug, Clone)]
pub struct Step {
    /// Seconds from script start when this step fires.
    ///
    /// The [`Simulator`](super::Simulator) dispatches this step on the first
    /// `update(dt)` call where `elapsed >= time`. Multiple steps at the same
    /// time value are all dispatched in the same `update` call, in ascending
    /// index order.
    pub time: f32,
    /// The action type to perform.
    ///
    /// Determines which synthetic event is dispatched and which optional
    /// fields are read. See the field-usage table on [`Step`] for the mapping.
    pub action: Action,
    /// Key name for key actions (e.g., `"space"`, `"escape"`, `"a"`).
    ///
    /// Used by [`Action::KeyPress`] and [`Action::KeyRelease`]. When
    /// `scancode` is also `None`, the key name is used as the scancode via
    /// [`Step::effective_scancode`].
    pub key: Option<String>,
    /// Scancode string override for key events.
    ///
    /// When set, this value is sent as the scancode in key-press and
    /// key-release events instead of `key`. When `None`,
    /// [`Step::effective_scancode`] returns `key`.
    pub scancode: Option<String>,
    /// Mouse X position in screen coordinates.
    ///
    /// Used by `mousemove`, `mousepress`, and `mouserelease`. Dispatched
    /// event receives `0.0` when this is `None`.
    pub x: Option<f64>,
    /// Mouse Y position in screen coordinates.
    ///
    /// Used by `mousemove`, `mousepress`, and `mouserelease`. Dispatched
    /// event receives `0.0` when this is `None`.
    pub y: Option<f64>,
    /// Mouse X movement delta since the previous mouse event.
    ///
    /// Used by `mousemove`. Dispatched event receives `0.0` when this
    /// is `None`.
    pub dx: Option<f64>,
    /// Mouse Y movement delta since the previous mouse event.
    ///
    /// Used by `mousemove`. Dispatched event receives `0.0` when this
    /// is `None`.
    pub dy: Option<f64>,
    /// Mouse button index (1 = left, 2 = right, 3 = middle).
    ///
    /// Used by `mousepress` and `mouserelease`. Dispatched event receives
    /// button index `1` when this is `None`.
    pub button: Option<u32>,
    /// Text string payload for text-input actions.
    ///
    /// Used exclusively by [`Action::TextInput`]. May contain any Unicode
    /// text. Dispatched `textinput` event receives `""` when this is `None`.
    pub text: Option<String>,
    /// Whether this is a key-repeat event.
    ///
    /// Used by [`Action::KeyPress`]. When `true`, the dispatched `keypressed`
    /// event carries `true` in its `is_repeat` argument — matching what the
    /// OS reports for physically held-down keys. Defaults to `false`.
    pub is_repeat: bool,
    /// Click count for a mouse press event.
    ///
    /// Used by [`Action::MousePress`]. Indicates how many consecutive clicks
    /// occurred (e.g., `2` for a double-click). Dispatched event receives
    /// count `1` when this is `None`.
    pub clicks: Option<u32>,
}

impl Step {
    /// Create a new Step with required fields set and all optional fields at defaults.
    ///
    /// All optional fields (`key`, `scancode`, `x`, `y`, `dx`, `dy`,
    /// `button`, `text`, `clicks`) are initialised to `None`. The `is_repeat`
    /// flag defaults to `false`. Set fields directly after construction for
    /// action-specific parameters.
    ///
    /// # Parameters
    /// - `time` — `f32`.
    /// - `action` — `Action`.
    ///
    /// # Returns
    /// `Step`.
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
        }
    }

    /// Return the effective scancode for a key event.
    ///
    /// Returns `scancode` if it is `Some`; otherwise falls back to `key`.
    /// Returns `None` only when both fields are `None`. Well-formed key
    /// steps should always have at least one of these set.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn effective_scancode(&self) -> Option<&str> {
        self.scancode.as_deref().or(self.key.as_deref())
    }

    /// Parses a Lua step-array table into a `Vec<Step>`.
    ///
    /// # Parameters
    /// - `t` — `&LuaTable`.
    ///
    /// # Returns
    /// `LuaResult<Vec<Self>>`.
    pub fn vec_from_lua_table(t: &LuaTable) -> LuaResult<Vec<Self>> {
        let len = t.len()? as usize;
        let mut steps = Vec::with_capacity(len);
        for i in 1..=len {
            let entry: LuaTable = t.get(i)?;
            let action_str: String = entry.get::<_, String>("action").map_err(|_| {
                LuaError::external("simulator.load: each step must have an 'action' field")
            })?;
            let action = Action::parse_action(&action_str).ok_or_else(|| {
                LuaError::external(format!(
                    "simulator.load: unknown action '{}' \u{2014} expected one of: keypress, keyrelease, mousemove, mousepress, mouserelease, mousewheel, textinput, wait",
                    action_str
                ))
            })?;
            let time: f32 = entry.get::<_, Option<f32>>("time")?.unwrap_or(0.0);
            let mut step = Self::new(time, action);
            step.key = entry.get::<_, Option<String>>("key")?;
            step.scancode = entry.get::<_, Option<String>>("scancode")?;
            step.x = entry.get::<_, Option<f64>>("x")?;
            step.y = entry.get::<_, Option<f64>>("y")?;
            step.dx = entry.get::<_, Option<f64>>("dx")?;
            step.dy = entry.get::<_, Option<f64>>("dy")?;
            step.button = entry.get::<_, Option<u32>>("button")?;
            step.text = entry.get::<_, Option<String>>("text")?;
            step.is_repeat = entry.get::<_, Option<bool>>("isRepeat")?.unwrap_or(false);
            step.clicks = entry.get::<_, Option<u32>>("clicks")?;
            steps.push(step);
        }
        Ok(steps)
    }
}
