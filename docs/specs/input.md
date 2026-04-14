# input

## General Info

- Module group: `Platform Services`
- Source path: `src/input/`
- Lua API path(s): `src/lua_api/input_api.rs`
- Primary Lua namespace: `lurek.keyboard`
- Rust test path(s): tests/rust/unit/input_tests.rs
- Lua test path(s): tests/lua/unit/test_input.lua, tests/lua/integration/test_input_camera.lua

## Summary

The `input` module is Lurek2D's hardware input abstraction layer. It owns the per-frame state snapshots for keyboard, mouse, gamepad, and touch input, translating raw `Event` values — received from winit via the engine's `EventQueue` — into structured, query-friendly state objects that Lua scripts poll each frame.

`KeyboardState` maintains three collections updated at frame start from the `EventQueue`: `pressed` (keys that went down this frame), `released` (keys that went up this frame), and `held` (keys currently down). Physical scancode-based variants are available for hardware-position-independent queries (e.g. game remapping). `winit_scancode_to_string` converts raw scancodes to stable string names.

`MouseState` tracks cursor position (window-relative and world-relative via the active camera transform), delta movement since last frame, scroll wheel delta, and per-button pressed/held/released flags. `SystemCursor` and `CursorHandle` provide cursor shape management (default, hand, crosshair, etc.) through `CursorKind`.

`GamepadState` wraps gilrs gamepad state: per-axis float values with dead-zone filtering applied, per-button flags following the same pressed/held/released model, and a device ID for multi-controller support. `GamepadMappings` provides stable string names for axes and buttons. `TouchState` tracks per-finger `TouchPoint` records (ID, position, phase) using the same pressed/held/released flag model.

**Scope boundary**: Platform Services tier. Depends on `event`, `runtime`, `math`. Lua bridge in `src/lua_api/input_api.rs`.

## Files

- `gamepad.rs`: Gamepad implementation for the `input` subsystem.
- `keyboard.rs`: Keyboard implementation for the `input` subsystem.
- `mod.rs`: Mod implementation for the `input` subsystem.
- `mouse.rs`: Mouse implementation for the `input` subsystem.
- `touch.rs`: Touch input state tracking for Lurek2D.

## Types

- `GamepadState` (`struct`, `gamepad.rs`): Holds the current button and axis state for a single gamepad identified by its id.
- `GamepadMappings` (`struct`, `gamepad.rs`): Stores SDL2 GameControllerDB-format mapping strings keyed by GUID.
- `KeyboardState` (`struct`, `keyboard.rs`): Tracks which keyboard keys are currently down, just pressed, or just released.
- `SystemCursor` (`enum`, `mouse.rs`): Standard OS cursor icon variants supported by the window backend.
- `MouseState` (`struct`, `mouse.rs`): Tracks mouse cursor position and per-button pressed/down/released state.
- `CursorKind` (`enum`, `mouse.rs`): The cursor type — either a named system icon or user-supplied pixel data.
- `CursorHandle` (`struct`, `mouse.rs`): A held cursor — either a system cursor icon or custom pixel-data cursor.
- `TouchPoint` (`struct`, `touch.rs`): Snapshot of one active touch point with its screen-space position and pressure.
- `TouchState` (`struct`, `touch.rs`): Tracks all active touch points by their winit-assigned finger ID.

## Functions

- `GamepadState::new` (`gamepad.rs`): Creates a new, empty `GamepadState` for the gamepad with the given `id`.
- `GamepadState::update_button` (`gamepad.rs`): Updates the pressed state for a specific button.
- `GamepadState::update_axis` (`gamepad.rs`): Updates the value for a specific analog axis.
- `GamepadState::is_button_pressed` (`gamepad.rs`): Returns `true` if the button at `button` index is currently pressed.
- `GamepadState::get_axis_value` (`gamepad.rs`): Returns the current value of the analog axis at `axis` index.
- `GamepadState::get_name` (`gamepad.rs`): Returns the human-readable name of this gamepad.
- `GamepadState::is_connected` (`gamepad.rs`): Returns whether this gamepad is currently connected.
- `GamepadState::get_button_count` (`gamepad.rs`): Returns the number of distinct buttons that have been reported.
- `GamepadState::get_axis_count` (`gamepad.rs`): Returns the number of distinct axes that have been reported.
- `GamepadState::set_guid` (`gamepad.rs`): Sets the platform GUID/UUID string for this gamepad.
- `GamepadState::get_guid` (`gamepad.rs`): Returns the platform GUID/UUID string for this gamepad.
- `GamepadState::get_hat` (`gamepad.rs`): Returns the d-pad hat direction string for the requested hat index.
- `gilrs_button_to_string` (`gamepad.rs`): Converts a `gilrs::Button` to a engine-compatible string name.
- `gilrs_axis_to_string` (`gamepad.rs`): Converts a `gilrs::Axis` to a engine-compatible string name.
- `GamepadMappings::new` (`gamepad.rs`): Creates an empty `GamepadMappings` store.
- `GamepadMappings::set_mapping` (`gamepad.rs`): Inserts or replaces the mapping string for the given GUID.
- `GamepadMappings::get_mapping_string` (`gamepad.rs`): Returns the mapping string for `guid`, or `None` if unknown.
- `GamepadMappings::load_from_file` (`gamepad.rs`): Parses a plain-text GameControllerDB file and merges entries into this store.
- `GamepadMappings::save_to_file` (`gamepad.rs`): Writes all stored mappings to a plain-text file, one per line.
- `KeyboardState::new` (`keyboard.rs`): Creates a new, empty `KeyboardState` with no keys recorded.
- `KeyboardState::begin_frame` (`keyboard.rs`): Clears per-frame transient state (pressed, released, scancode, and text input lists).
- `KeyboardState::press_scancode` (`keyboard.rs`): Records that a physical scancode is now held down.
- `KeyboardState::release_scancode` (`keyboard.rs`): Records that a physical scancode was released.
- `KeyboardState::is_scancode_down` (`keyboard.rs`): Returns `true` if the given physical scancode is currently held down.
- `KeyboardState::set_key_repeat` (`keyboard.rs`): Enables or disables key repeat event delivery.
- `KeyboardState::has_key_repeat` (`keyboard.rs`): Returns `true` if key repeat event delivery is enabled.
- `KeyboardState::set_text_input` (`keyboard.rs`): Enables or disables text input (IME) event delivery.
- `KeyboardState::has_text_input` (`keyboard.rs`): Returns `true` if text input (IME) event delivery is enabled.
- `KeyboardState::push_text_input` (`keyboard.rs`): Pushes a committed text input string into the per-frame buffer.
- `KeyboardState::get_text_input` (`keyboard.rs`): Returns the text input strings committed this frame.
- `KeyboardState::set_key_down` (`keyboard.rs`): Records that `key` is now held down, adding it to the pressed list if newly down.
- `KeyboardState::set_key_up` (`keyboard.rs`): Records that `key` was released, adding it to the released list if it was down.
- `KeyboardState::is_down` (`keyboard.rs`): Returns `true` if `key` is currently held down.
- `KeyboardState::is_any_down` (`keyboard.rs`): Returns `true` if any of the given keys is currently held down.
- `KeyboardState::get_pressed` (`keyboard.rs`): Returns the list of keys that became pressed this frame.
- `KeyboardState::get_released` (`keyboard.rs`): Returns the list of keys that were released this frame.
- `KeyboardState::clear` (`keyboard.rs`): Clears all keyboard state: held keys, pressed, and released lists.
- `KeyboardState::is_modifier_active` (`keyboard.rs`): Returns `true` if the named modifier key is currently held.
- `KeyboardState::set_modifiers` (`keyboard.rs`): Sets the modifier bitmask when modifiers change.
- `get_scancode_from_key` (`keyboard.rs`): Resolves a logical Luna key name to the closest physical scancode string.
- `get_key_from_scancode` (`keyboard.rs`): Resolves a physical scancode string to the closest logical Luna key name.
- `winit_key_to_string` (`keyboard.rs`): Converts a `winit 0.30` logical `Key` to the lowercase string name used by the `lurek.*` API.
- `winit_scancode_to_string` (`keyboard.rs`): Converts a `winit 0.30` physical `KeyCode` to a engine-compatible scancode string.
- `SystemCursor::from_name` (`mouse.rs`): Parses a cursor name string into a `SystemCursor` variant.
- `SystemCursor::as_str` (`mouse.rs`): Returns the lowercase string name for this cursor variant.
- `MouseState::new` (`mouse.rs`): Creates a new `MouseState` with cursor at `(0, 0)` and all buttons up.
- `MouseState::begin_frame` (`mouse.rs`): Resets per-frame transient state (pressed, released, and scroll deltas).
- `MouseState::update_position` (`mouse.rs`): Records the latest cursor position reported by the OS move event.
- `MouseState::request_position` (`mouse.rs`): Requests that the backend cursor move to a new position.
- `MouseState::set_button` (`mouse.rs`): Records a button press or release event, updating the transient pressed/released flags.
- `MouseState::is_down` (`mouse.rs`): Returns `true` if the button at `button` index is currently held down.
- `MouseState::get_position` (`mouse.rs`): Returns the current cursor position as `(x, y)`.
- `MouseState::set_visible` (`mouse.rs`): Sets cursor visibility.
- `MouseState::is_visible` (`mouse.rs`): Returns whether the cursor is visible.
- `MouseState::set_grabbed` (`mouse.rs`): Sets whether the cursor is confined to the window.
- `MouseState::is_grabbed` (`mouse.rs`): Returns whether the cursor is confined to the window.
- `MouseState::set_relative_mode` (`mouse.rs`): Sets relative (FPS) mouse mode.
- `MouseState::get_relative_mode` (`mouse.rs`): Returns whether relative mouse mode is active.
- `MouseState::accumulate_scroll` (`mouse.rs`): Accumulates scroll delta for the current frame.
- `MouseState::get_scroll` (`mouse.rs`): Returns the accumulated scroll delta for the current frame.
- `MouseState::set_cursor` (`mouse.rs`): Sets the system cursor shape.
- `MouseState::get_cursor` (`mouse.rs`): Returns the current system cursor shape.
- `MouseState::take_pending_position` (`mouse.rs`): Returns and clears the next backend cursor-position request.
- `is_cursor_supported` (`mouse.rs`): Returns whether cursor customisation is supported on this platform.
- `TouchState::new` (`touch.rs`): Creates a new empty touch state.
- `TouchState::touch_start` (`touch.rs`): Inserts a new touch start or updates the position and pressure of an ongoing touch.
- `TouchState::touch_move` (`touch.rs`): Updates the position of an existing touch point.
- `TouchState::touch_end` (`touch.rs`): Removes a touch point when the finger is lifted (touch-end event).
- `TouchState::get_touches` (`touch.rs`): Returns all active touch points.
- `TouchState::get_touch` (`touch.rs`): Returns a specific touch point by ID.
- `TouchState::get_touch_count` (`touch.rs`): Returns the number of active touches.

## Lua API Reference

- Binding path(s): `src/lua_api/input_api.rs`
- Namespace: `lurek.keyboard`

### Module Functions
- `lurek.input.isDown`: Returns true if any of the given keys is currently held down.
- `lurek.input.isScancodeDown`: Returns whether the key with the given scancode is held.
- `lurek.input.setKeyRepeat`: Enables or disables key-repeat events.
- `lurek.input.hasKeyRepeat`: Returns whether key-repeat is currently enabled.
- `lurek.input.setTextInput`: Enables or disables Unicode text input mode.
- `lurek.input.hasTextInput`: Returns whether text input mode is currently active.
- `lurek.input.getScancodeFromKey`: Returns the hardware scancode for the given key name.
- `lurek.input.getKeyFromScancode`: Returns the key name for the given hardware scancode.
- `lurek.input.isModifierActive`: Returns whether the named modifier key is currently held.
- `lurek.input.getPosition`: Returns the current cursor position as (x, y).
- `lurek.input.getX`: Returns the current mouse X position in window coordinates.
- `lurek.input.getY`: Returns the current mouse Y position in window coordinates.
- `lurek.input.isDown`: Returns whether the given mouse button is currently held down.
- `lurek.input.setVisible`: Shows or hides the operating-system mouse cursor.
- `lurek.input.isVisible`: Returns whether the mouse cursor is currently visible.
- `lurek.input.setGrabbed`: Locks or unlocks the mouse cursor to the window.
- `lurek.input.isGrabbed`: Returns whether the mouse cursor is locked to the window.
- `lurek.input.setRelativeMode`: Enables or disables raw relative mouse motion mode.
- `lurek.input.getRelativeMode`: Returns whether relative mouse mode is active.
- `lurek.input.setPosition`: Moves the mouse cursor to the given window-space position.
- `lurek.input.setCursor`: Sets the active mouse cursor from a Cursor handle, name string, or nil to reset.
- `lurek.input.newCursor`: Creates a custom mouse cursor from RGBA pixel data.
- `lurek.input.getSystemCursor`: Returns a system cursor object for the named cursor shape.
- `lurek.input.isCursorSupported`: Returns whether cursor customisation is supported on this platform.
- `lurek.input.getCursor`: Returns the name of the currently active system cursor.
- `lurek.input.getWheelDelta`: Returns the mouse scroll wheel delta (dx, dy) since last frame.
- `lurek.input.getCount`: Returns the number of connected gamepads.
- `lurek.input.getJoystickCount`: Returns the number of tracked gamepad slots.
- `lurek.input.getJoysticks`: Returns a list of connected gamepad IDs.
- `lurek.input.isConnected`: Returns whether the gamepad with the given ID is connected.
- `lurek.input.getName`: Returns the human-readable name of a gamepad.
- `lurek.input.isGamepad`: Returns whether the joystick at the given slot is a recognized gamepad.
- `lurek.input.getButtonCount`: Returns the total number of buttons on the gamepad.
- `lurek.input.getAxisCount`: Returns the total number of analog axes on the gamepad.
- `lurek.input.isDown`: Returns whether the given button on the gamepad is currently held.
- `lurek.input.getAxis`: Returns the current value (-1 to 1) of a gamepad analog axis.
- `lurek.input.isVibrationSupported`: Returns whether the gamepad supports haptic vibration.
- `lurek.input.getGUID`: Returns the hardware GUID string of the gamepad.
- `lurek.input.getHat`: Returns the direction string of a hat switch on the gamepad.
- `lurek.input.setVibration`: Triggers haptic rumble (currently a no-op stub).
- `lurek.input.setBackgroundEvents`: Enable or disable receiving gamepad events when the window is not focused.
- `lurek.input.getBackgroundEvents`: Returns whether background gamepad events are enabled.
- `lurek.input.setGamepadMapping`: Stores or replaces the SDL2 GameControllerDB mapping string for the given GUID.
- `lurek.input.getGamepadMappingString`: Returns the stored mapping string for the given GUID, or nil.
- `lurek.input.loadGamepadMappings`: Loads SDL2 GameControllerDB-format mappings from a file.
- `lurek.input.saveGamepadMappings`: Saves all stored gamepad mappings to a plain-text file.
- `lurek.input.getTouches`: Returns a table of active touch points with id, x, y, and pressure fields.
- `lurek.input.getPosition`: Returns the position (x, y) of the touch with the given ID.
- `lurek.input.getPressure`: Returns the pressure (0-1) of the touch with the given ID.
- `lurek.input.getTouchCount`: Returns the number of currently active touch points.

### `Cursor` Methods
- `Cursor:release`: Releases the cursor resource (no-op on desktop).
- `Cursor:getType`: Returns the cursor type as "system" or "custom".

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/input/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
