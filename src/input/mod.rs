
/// Combo gesture detection and multi-step input sequences.
pub mod combo;
/// Gamepad device state, axis/button mapping, and vibration requests via gilrs.
pub mod gamepad;
/// Keyboard scan-code state and winit key translation.
pub mod keyboard;
/// Mouse position, button state, cursor kind, and cursor handle management.
pub mod mouse;
/// Input event recorder for replays and automated testing.
pub mod recorder;
/// Touch-point state tracking for multi-touch surfaces.
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

/// Lua event name emitted when a keyboard key transitions to pressed.
pub const EVENT_KEY_PRESSED: &str = "keypressed";
/// Lua event name emitted when a keyboard key transitions to released.
pub const EVENT_KEY_RELEASED: &str = "keyreleased";
/// Lua event name emitted on cursor position change.
pub const EVENT_MOUSE_MOVED: &str = "mousemoved";
/// Lua event name emitted when a mouse button transitions to pressed.
pub const EVENT_MOUSE_PRESSED: &str = "mousepressed";
/// Lua event name emitted when a mouse button transitions to released.
pub const EVENT_MOUSE_RELEASED: &str = "mousereleased";
/// Lua event name emitted on scroll-wheel movement.
pub const EVENT_WHEEL_MOVED: &str = "wheelmoved";
/// Lua event name emitted when the OS delivers a text-input character.
pub const EVENT_TEXT_INPUT: &str = "textinput";
