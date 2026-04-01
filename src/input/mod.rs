/// Gamepad button and axis state for a single controller.
pub mod gamepad;
/// Keyboard state tracking pressed, held, and released keys.
pub mod keyboard;
/// Mouse position and button state management.
pub mod mouse;
/// Touch input state tracking for touchscreens.
pub mod touch;

pub use gamepad::gilrs_axis_to_string;
pub use gamepad::gilrs_button_to_string;
pub use gamepad::GamepadState;
pub use keyboard::winit_scancode_to_string;
pub use keyboard::KeyboardState;
pub use mouse::MouseState;
pub use mouse::SystemCursor;
pub use touch::{TouchPoint, TouchState};
