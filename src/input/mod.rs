//! Mod implementation for the `input` subsystem.
//!
//! This module is part of Luna2D's `input` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.
//!
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
