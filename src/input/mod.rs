//! Hardware input state for keyboard, mouse, gamepad, and touch.
//!
//! Translates raw [`crate::event::Event`] values from the engine's `EventQueue` into
//! per-frame state snapshots that Lua scripts can query without directly consuming events.
//! All state is updated once per frame at the start of `App::event_loop_iteration()` before
//! any Lua callbacks fire.
//!
//! ## Subsystem inventory
//! - [`keyboard`] — [`KeyboardState`]: pressed/held/released key sets, scancode helpers
//! - [`mouse`] — [`MouseState`]: cursor position, delta, scroll, per-button flags, cursor shape
//! - [`gamepad`] — [`GamepadState`]: gilrs axis/button values with dead-zone filtering
//! - [`touch`] — [`TouchState`]: per-finger [`TouchPoint`] pressed/held/released tracking
//!
//! ## State model
//! Each device type follows the same three-collection model:
//! `pressed` (went down this frame), `held` (currently down), `released` (went up this frame).
//! Collections are cleared and rebuilt each frame from the `EventQueue`.
//!
//! Boundary note: `event::EventQueue` is the engine-wide transport for raw input/window events,
//! while `input::recorder` is a deterministic snapshot/replay utility that records already
//! interpreted input states per frame.
//!
//! Cursor ownership note: `input::mouse` owns logical cursor state (`visible`, `grabbed`,
//! relative mode, requested position), and `window` applies those requests to the OS backend.
//!
//! All public items are documented. Lua bridge: `src/lua_api/input_api.rs`.

/// Combo and input-sequence detection for ordered key/button input chains.
pub mod combo;
/// Gamepad button and axis state for a single controller.
pub mod gamepad;
/// Keyboard state tracking pressed, held, and released keys.
pub mod keyboard;
/// Mouse position and button state management.
pub mod mouse;
/// Input event recording and deterministic playback.
pub mod recorder;
/// Touch input state tracking for touchscreens.
pub mod touch;

pub use combo::{ComboDetector, ComboProgress, ComboStep};
pub use gamepad::gilrs_axis_to_string;
pub use gamepad::gilrs_button_to_string;
pub use gamepad::virtual_dpad;
pub use gamepad::GamepadMappings;
pub use gamepad::GamepadState;
pub use gamepad::GamepadVibrationRequest;
pub use keyboard::winit_scancode_to_string;
pub use keyboard::KeyboardState;
pub use mouse::MouseState;
pub use mouse::SystemCursor;
pub use mouse::{is_cursor_supported, CursorHandle, CursorKind};
pub use touch::{TouchPoint, TouchState};

/// Event name: keyboard press.
pub const EVENT_KEY_PRESSED: &str = "keypressed";
/// Event name: keyboard release.
pub const EVENT_KEY_RELEASED: &str = "keyreleased";
/// Event name emitted when the mouse cursor moves.
pub const EVENT_MOUSE_MOVED: &str = "mousemoved";
/// Event name emitted when a mouse button is pressed.
pub const EVENT_MOUSE_PRESSED: &str = "mousepressed";
/// Event name: mouse release.
pub const EVENT_MOUSE_RELEASED: &str = "mousereleased";
/// Event name: mouse wheel scroll.
pub const EVENT_WHEEL_MOVED: &str = "wheelmoved";
/// Event name emitted when UTF-8 text input is received.
pub const EVENT_TEXT_INPUT: &str = "textinput";
